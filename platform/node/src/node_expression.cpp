#include "node_conversion.hpp"
#include "node_expression.hpp"
#include "node_feature.hpp"

#include <mbgl/style/expression/parsing_context.hpp>
#include <mbgl/style/expression/is_constant.hpp>
#include <mbgl/style/conversion/function.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mbgl/util/geojson.hpp>

using namespace mbgl::style;
using namespace mbgl::style::expression;

namespace node_mbgl {

napi_ref NodeExpression::constructor = nullptr;

napi_value NodeExpression::Init(napi_env env, napi_value exports) {
    napi_status status;
    
    // Define constructor properties
    napi_property_descriptor properties[] = {
        {"parse", nullptr, Parse, nullptr, nullptr, nullptr, napi_static_method, nullptr}
    };
    
    // Create the class
    status = node_mbgl::napi_utils::defineClass(
        env,
        "Expression",
        New,
        nullptr,
        1,
        properties,
        nullptr,
        &constructor
    );
    
    if (status != napi_ok) return nullptr;
    
    // Create prototype properties
    napi_property_descriptor protoProperties[] = {
        {"evaluate", nullptr, Evaluate, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isFeatureConstant", nullptr, IsFeatureConstant, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isZoomConstant", nullptr, IsZoomConstant, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"serialize", nullptr, Serialize, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    napi_value cons = nullptr;
    status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) return nullptr;
    
    napi_value prototype = nullptr;
    status = napi_get_prototype(env, cons, &prototype);
    if (status != napi_ok) return nullptr;
    
    status = napi_define_properties(env, prototype, 5, protoProperties);
    if (status != napi_ok) return nullptr;
    
    // Set the constructor on exports
    status = napi_set_named_property(env, exports, "Expression", cons);
    if (status != napi_ok) return nullptr;
    
    return exports;
}

type::Type parseType(napi_env env, napi_value type) {
    static std::unordered_map<std::string, type::Type> types = {
        {"string", type::String},
        {"number", type::Number},
        {"boolean", type::Boolean},
        {"object", type::Object},
        {"color", type::Color},
        {"padding", type::Padding},
        {"value", type::Value},
        {"formatted", type::Formatted},
        {"number-format", type::String},
        {"resolvedImage", type::Image},
        {"variableAnchorOffsetCollection", type::VariableAnchorOffsetCollection}};

    napi_value kindValue = nullptr;
    if (!node_mbgl::napi_utils::getProperty(env, type, "kind", kindValue)) {
        return type::Value; // default type
    }
    
    std::string kind = node_mbgl::napi_utils::toString(env, kindValue);

    if (kind == "array") {
        napi_value itemTypeValue = nullptr;
        if (!node_mbgl::napi_utils::getProperty(env, type, "itemType", itemTypeValue)) {
            return type::Value; // default type
        }
        
        type::Type itemType = parseType(env, itemTypeValue);
        std::optional<std::size_t> N;

        napi_value nValue = nullptr;
        if (node_mbgl::napi_utils::hasProperty(env, type, "N")) {
            if (node_mbgl::napi_utils::getProperty(env, type, "N", nValue)) {
                N = static_cast<std::size_t>(node_mbgl::napi_utils::toInt32(env, nValue));
            }
        }
        return type::Array(itemType, N);
    }

    auto it = types.find(kind);
    if (it != types.end()) {
        return it->second;
    }
    return type::Value; // default type
}

napi_value NodeExpression::Parse(napi_env env, napi_callback_info info) {
    napi_status status;
    
    // Get this and arguments
    size_t argc = 2;
    napi_value args[2] = { nullptr, nullptr };
    napi_value thisArg = nullptr;
    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok) return nullptr;
    
    if (argc < 1) {
        node_mbgl::napi_utils::throwError(env, "Requires a JSON style expression argument.");
        return nullptr;
    }
    
    std::optional<type::Type> expected;
    if (argc > 1 && node_mbgl::napi_utils::isObject(env, args[1])) {
        expected = parseType(env, args[1]);
    }
    
    auto expr = args[0];
    
    try {
        mbgl::style::conversion::Convertible convertible(expr);
        
        if (node_mbgl::napi_utils::isObject(env, expr) && !node_mbgl::napi_utils::isArray(env, expr) && expected) {
            mbgl::style::conversion::Error error;
            auto func = convertFunctionToExpression(*expected, convertible, error, false);
            if (func) {
                napi_value instance = node_mbgl::napi_utils::createInstance(env, constructor, 0, nullptr);
                if (instance == nullptr) {
                    node_mbgl::napi_utils::throwError(env, "Failed to create Expression instance");
                    return nullptr;
                }
                
                NodeExpression* nodeExpr = new NodeExpression(std::move(*func));
                node_mbgl::napi_utils::wrapObject(env, instance, nodeExpr);
                return instance;
            }
            
            napi_value result = node_mbgl::napi_utils::createArray(env);
            napi_value err = node_mbgl::napi_utils::createObject(env);
            node_mbgl::napi_utils::setProperty(env, err, "key", node_mbgl::napi_utils::createString(env, ""));
            node_mbgl::napi_utils::setProperty(env, err, "error", node_mbgl::napi_utils::createString(env, error.message));
            node_mbgl::napi_utils::setArrayElement(env, result, 0, err);
            return result;
        }
        
        ParsingContext ctx = expected ? ParsingContext(*expected) : ParsingContext();
        ParseResult parsed = ctx.parseLayerPropertyExpression(mbgl::style::conversion::Convertible(expr));
        
        if (parsed) {
            assert(ctx.getErrors().empty());
            
            napi_value instance = node_mbgl::napi_utils::createInstance(env, constructor, 0, nullptr);
            if (instance == nullptr) {
                node_mbgl::napi_utils::throwError(env, "Failed to create Expression instance");
                return nullptr;
            }
            
            NodeExpression* nodeExpr = new NodeExpression(std::move(*parsed));
            node_mbgl::napi_utils::wrapObject(env, instance, nodeExpr);
            return instance;
        }
        
        const auto& errors = ctx.getErrors();
        napi_value result = node_mbgl::napi_utils::createArray(env);
        for (std::size_t i = 0; i < errors.size(); ++i) {
            const auto& error = errors[i];
            napi_value err = node_mbgl::napi_utils::createObject(env);
            node_mbgl::napi_utils::setProperty(env, err, "key", node_mbgl::napi_utils::createString(env, error.key.c_str()));
            node_mbgl::napi_utils::setProperty(env, err, "error", node_mbgl::napi_utils::createString(env, error.message.c_str()));
            node_mbgl::napi_utils::setArrayElement(env, result, static_cast<uint32_t>(i), err);
        }
        return result;
    } catch (std::exception& ex) {
        node_mbgl::napi_utils::throwError(env, ex.what());
        return nullptr;
    }
}

napi_value NodeExpression::New(napi_env env, napi_callback_info info) {
    napi_status status;
    
    // Get this and arguments
    size_t argc = 0;
    napi_value args[1] = { nullptr };
    napi_value thisArg = nullptr;
    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok) return nullptr;
    
    // Check if this is a constructor call
    napi_value newTarget = nullptr;
    status = napi_get_new_target(env, info, &newTarget);
    if (status != napi_ok) return nullptr;
    
    if (newTarget == nullptr) {
        node_mbgl::napi_utils::throwError(env, "Use the new operator to create new Expression objects");
        return nullptr;
    }
    
    // Create and wrap the object
    NodeExpression* instance = new NodeExpression(nullptr);
    node_mbgl::napi_utils::wrapObject(env, thisArg, instance);
    
    return thisArg;
}

struct ToValue {
    napi_env env;
    
    ToValue(napi_env e) : env(e) {}
    
    napi_value operator()(mbgl::NullValue) {
        return node_mbgl::napi_utils::createNull(env);
    }

    napi_value operator()(bool t) {
        return node_mbgl::napi_utils::createBoolean(env, t);
    }

    napi_value operator()(double t) {
        return node_mbgl::napi_utils::createNumber(env, t);
    }

    napi_value operator()(const std::string& t) {
        return node_mbgl::napi_utils::createString(env, t);
    }

    napi_value operator()(const std::vector<Value>& array) {
        napi_value result = node_mbgl::napi_utils::createArray(env);
        for (std::uint32_t i = 0; i < array.size(); i++) {
            node_mbgl::napi_utils::setArrayElement(env, result, i, toJS(env, array[i]));
        }
        return result;
    }

    napi_value operator()(const Collator&) {
        // Collators are excluded from constant folding and there's no Literal parser
        // for them so there shouldn't be any way to serialize this value.
        assert(false);
        return node_mbgl::napi_utils::createNull(env);
    }

    napi_value operator()(const Formatted& formatted) {
        // This mimics the internal structure of the Formatted class in formatted.js
        // A better approach might be to use the explicit serialized form
        // both here and on the JS side? e.g. toJS(fromExpressionValue<mbgl::Value>(formatted))
        std::unordered_map<std::string, mbgl::Value> serialized;
        std::vector<mbgl::Value> sections;
        for (const auto& section : formatted.sections) {
            std::unordered_map<std::string, mbgl::Value> serializedSection;
            serializedSection.emplace("text", section.text);
            if (section.fontScale) {
                serializedSection.emplace("scale", *section.fontScale);
            } else {
                serializedSection.emplace("scale", mbgl::NullValue());
            }
            if (section.fontStack) {
                std::string fontStackString;
                serializedSection.emplace("fontStack", mbgl::fontStackToString(*section.fontStack));
            } else {
                serializedSection.emplace("fontStack", mbgl::NullValue());
            }
            if (section.textColor) {
                serializedSection.emplace("textColor", section.textColor->toObject());
            } else {
                serializedSection.emplace("textColor", mbgl::NullValue());
            }
            sections.emplace_back(serializedSection);
        }
        serialized.emplace("sections", sections);

        return toJS(env, mbgl::Value(serialized));
    }

    napi_value operator()(const mbgl::Color& color) {
        return operator()(std::vector<Value>{static_cast<double>(color.r),
                                             static_cast<double>(color.g),
                                             static_cast<double>(color.b),
                                             static_cast<double>(color.a)});
    }

    napi_value operator()(const mbgl::Padding& padding) {
        return operator()(std::vector<Value>{static_cast<double>(padding.top),
                                             static_cast<double>(padding.right),
                                             static_cast<double>(padding.bottom),
                                             static_cast<double>(padding.left)});
    }

    napi_value operator()(const std::unordered_map<std::string, Value>& map) {
        napi_value result = node_mbgl::napi_utils::createObject(env);
        for (const auto& entry : map) {
            node_mbgl::napi_utils::setProperty(env, result, entry.first.c_str(), toJS(env, entry.second));
        }

        return result;
    }

    napi_value operator()(const Image& image) { return toJS(env, image.toValue()); }

    napi_value operator()(const mbgl::VariableAnchorOffsetCollection& variableAnchorOffsets) {
        std::vector<Value> components;
        components.reserve(variableAnchorOffsets.size() * 2);
        for (const auto& variableAnchorOffset : variableAnchorOffsets) {
            components.emplace_back(
                std::string(mbgl::Enum<mbgl::style::SymbolAnchorType>::toString(variableAnchorOffset.anchorType)));
            components.emplace_back(std::vector<Value>{static_cast<double>(variableAnchorOffset.offset[0]),
                                                       static_cast<double>(variableAnchorOffset.offset[1])});
        }
        return operator()(components);
    }
};

napi_value toJS(napi_env env, const Value& value) {
    return Value::visit(value, ToValue(env));
}

napi_value NodeExpression::Evaluate(napi_env env, napi_callback_info info) {
    napi_status status;
    
    // Get this and arguments
    size_t argc = 2;
    napi_value args[2] = { nullptr, nullptr };
    napi_value thisArg = nullptr;
    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok) return nullptr;
    
    if (argc < 2 || !node_mbgl::napi_utils::isObject(env, args[0])) {
        node_mbgl::napi_utils::throwError(env, "Requires globals and feature arguments.");
        return nullptr;
    }
    
    // Unwrap the instance
    NodeExpression* nodeExpr = node_mbgl::napi_utils::unwrapObject<NodeExpression>(env, thisArg);
    if (nodeExpr == nullptr || nodeExpr->expression == nullptr) {
        node_mbgl::napi_utils::throwError(env, "Invalid Expression instance");
        return nullptr;
    }
    
    const std::unique_ptr<Expression>& expression = nodeExpr->expression;
    
    // Get zoom value
    std::optional<float> zoom;
    napi_value zoomValue = nullptr;
    if (node_mbgl::napi_utils::getProperty(env, args[0], "zoom", zoomValue)) {
        if (node_mbgl::napi_utils::isNumber(env, zoomValue)) {
            zoom = static_cast<float>(node_mbgl::napi_utils::toNumber(env, zoomValue));
        }
    }
    
    // Get heatmapDensity value
    std::optional<double> heatmapDensity;
    napi_value heatmapDensityValue = nullptr;
    if (node_mbgl::napi_utils::getProperty(env, args[0], "heatmapDensity", heatmapDensityValue)) {
        if (node_mbgl::napi_utils::isNumber(env, heatmapDensityValue)) {
            heatmapDensity = node_mbgl::napi_utils::toNumber(env, heatmapDensityValue);
        }
    }
    
    // Convert feature to GeoJSON
    conversion::Error conversionError;
    std::optional<mbgl::GeoJSON> geoJSON = conversion::convert<mbgl::GeoJSON>(args[1], conversionError);
    if (!geoJSON) {
        node_mbgl::napi_utils::throwError(env, conversionError.message.c_str());
        return nullptr;
    }
    
    try {
        mapbox::geojson::feature feature = geoJSON->get<mapbox::geojson::feature>();
        auto result = expression->evaluate(zoom, feature, heatmapDensity);
        
        if (result) {
            return toJS(env, *result);
        } else {
            napi_value res = node_mbgl::napi_utils::createObject(env);
            node_mbgl::napi_utils::setProperty(env, res, "error", node_mbgl::napi_utils::createString(env, result.error().message.c_str()));
            return res;
        }
    } catch (std::exception& ex) {
        node_mbgl::napi_utils::throwError(env, ex.what());
        return nullptr;
    }
}

napi_value NodeExpression::GetType(napi_env env, napi_callback_info info) {
    napi_status status;
    
    // Get this
    size_t argc = 0;
    napi_value args[1] = { nullptr };
    napi_value thisArg = nullptr;
    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok) return nullptr;
    
    // Unwrap the instance
    NodeExpression* nodeExpr = node_mbgl::napi_utils::unwrapObject<NodeExpression>(env, thisArg);
    if (nodeExpr == nullptr || nodeExpr->expression == nullptr) {
        node_mbgl::napi_utils::throwError(env, "Invalid Expression instance");
        return nullptr;
    }
    
    const std::unique_ptr<Expression>& expression = nodeExpr->expression;
    
    const type::Type type = expression->getType();
    const std::string name = type.match([&](const auto& t) { return t.getName(); });
    
    return node_mbgl::napi_utils::createString(env, name.c_str());
}

napi_value NodeExpression::IsFeatureConstant(napi_env env, napi_callback_info info) {
    napi_status status;
    
    // Get this
    size_t argc = 0;
    napi_value args[1] = { nullptr };
    napi_value thisArg = nullptr;
    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok) return nullptr;
    
    // Unwrap the instance
    NodeExpression* nodeExpr = node_mbgl::napi_utils::unwrapObject<NodeExpression>(env, thisArg);
    if (nodeExpr == nullptr || nodeExpr->expression == nullptr) {
        node_mbgl::napi_utils::throwError(env, "Invalid Expression instance");
        return nullptr;
    }
    
    const std::unique_ptr<Expression>& expression = nodeExpr->expression;
    
    bool result = isFeatureConstant(*expression);
    return node_mbgl::napi_utils::createBoolean(env, result);
}

napi_value NodeExpression::IsZoomConstant(napi_env env, napi_callback_info info) {
    napi_status status;
    
    // Get this
    size_t argc = 0;
    napi_value args[1] = { nullptr };
    napi_value thisArg = nullptr;
    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok) return nullptr;
    
    // Unwrap the instance
    NodeExpression* nodeExpr = node_mbgl::napi_utils::unwrapObject<NodeExpression>(env, thisArg);
    if (nodeExpr == nullptr || nodeExpr->expression == nullptr) {
        node_mbgl::napi_utils::throwError(env, "Invalid Expression instance");
        return nullptr;
    }
    
    const std::unique_ptr<Expression>& expression = nodeExpr->expression;
    
    bool result = isZoomConstant(*expression);
    return node_mbgl::napi_utils::createBoolean(env, result);
}

napi_value NodeExpression::Serialize(napi_env env, napi_callback_info info) {
    napi_status status;
    
    // Get this
    size_t argc = 0;
    napi_value args[1] = { nullptr };
    napi_value thisArg = nullptr;
    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok) return nullptr;
    
    // Unwrap the instance
    NodeExpression* nodeExpr = node_mbgl::napi_utils::unwrapObject<NodeExpression>(env, thisArg);
    if (nodeExpr == nullptr || nodeExpr->expression == nullptr) {
        node_mbgl::napi_utils::throwError(env, "Invalid Expression instance");
        return nullptr;
    }
    
    const std::unique_ptr<Expression>& expression = nodeExpr->expression;
    
    const mbgl::Value serialized = expression->serialize();
    
    return toJS(env, serialized);
}

} // namespace node_mbgl
