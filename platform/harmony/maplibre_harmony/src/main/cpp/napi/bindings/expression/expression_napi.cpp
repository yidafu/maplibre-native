#include "expression_napi.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "style/napi_value_wrapper.hpp"
#include "style/conversion/harmony_conversion.hpp"

#include <mbgl/style/expression/parsing_context.hpp>
#include <mbgl/style/expression/is_constant.hpp>
#include <mbgl/style/expression/value.hpp>
#include <mbgl/style/conversion.hpp>
#include <mbgl/util/geojson.hpp>
#include <mbgl/util/color.hpp>
#include <mbgl/style/expression/formatted.hpp>
#include <mbgl/style/expression/image.hpp>

namespace maplibre {
namespace harmony {

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using namespace mbgl::style;
using namespace mbgl::style::expression;

// Static member initialization
napi_ref ExpressionNAPI::constructor = nullptr;

ExpressionNAPI::ExpressionNAPI(std::unique_ptr<mbgl::style::expression::Expression> expr)
    : expression(std::move(expr)) {
}

ExpressionNAPI::~ExpressionNAPI() {
    expression.reset();
}

void ExpressionNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    ExpressionNAPI* obj = static_cast<ExpressionNAPI*>(nativeObject);
    delete obj;
}

// Helper: Convert mbgl::Value to napi_value (for serialize())
napi_value MbglValueToNapi(napi_env env, const mbgl::Value& value);

// Helper: Convert napi_value to mbgl::Value for parsing
mbgl::Value NapiToValue(napi_env env, napi_value value) {
    napi_valuetype type;
    napi_typeof(env, value, &type);
    
    switch (type) {
        case napi_null:
        case napi_undefined:
            return mbgl::NullValue{};
            
        case napi_boolean: {
            bool result;
            napi_get_value_bool(env, value, &result);
            return result;
        }
        
        case napi_number: {
            double result;
            napi_get_value_double(env, value, &result);
            return result;
        }
        
        case napi_string: {
            size_t length;
            napi_get_value_string_utf8(env, value, nullptr, 0, &length);
            std::string str(length, '\0');
            napi_get_value_string_utf8(env, value, &str[0], length + 1, &length);
            return str;
        }
        
        case napi_object: {
            bool isArray;
            napi_is_array(env, value, &isArray);
            
            if (isArray) {
                uint32_t arrayLength;
                napi_get_array_length(env, value, &arrayLength);
                std::vector<mbgl::Value> array;
                array.reserve(arrayLength);
                
                for (uint32_t i = 0; i < arrayLength; i++) {
                    napi_value element;
                    napi_get_element(env, value, i, &element);
                    array.push_back(NapiToValue(env, element));
                }
                return array;
            } else {
                // Object
                napi_value propertyNames;
                napi_get_property_names(env, value, &propertyNames);
                
                uint32_t propertyCount;
                napi_get_array_length(env, propertyNames, &propertyCount);
                
                std::unordered_map<std::string, mbgl::Value> map;
                for (uint32_t i = 0; i < propertyCount; i++) {
                    napi_value key;
                    napi_get_element(env, propertyNames, i, &key);
                    
                    size_t keyLength;
                    napi_get_value_string_utf8(env, key, nullptr, 0, &keyLength);
                    std::string keyStr(keyLength, '\0');
                    napi_get_value_string_utf8(env, key, &keyStr[0], keyLength + 1, &keyLength);
                    
                    napi_value propValue;
                    napi_get_property(env, value, key, &propValue);
                    
                    map[keyStr] = NapiToValue(env, propValue);
                }
                return map;
            }
        }
        
        default:
            return mbgl::NullValue{};
    }
}

// Helper: Convert mbgl::style::expression::Value to napi_value
napi_value ValueToNapi(napi_env env, const mbgl::style::expression::Value& value) {
    return value.match(
        [&](mbgl::NullValue) -> napi_value {
            napi_value result;
            napi_get_null(env, &result);
            return result;
        },
        [&](bool v) -> napi_value {
            napi_value result;
            napi_get_boolean(env, v, &result);
            return result;
        },
        [&](double v) -> napi_value {
            napi_value result;
            napi_create_double(env, v, &result);
            return result;
        },
        [&](const std::string& v) -> napi_value {
            napi_value result;
            napi_create_string_utf8(env, v.c_str(), v.length(), &result);
            return result;
        },
        [&](const std::vector<Value>& array) -> napi_value {
            napi_value result;
            napi_create_array_with_length(env, array.size(), &result);
            for (size_t i = 0; i < array.size(); i++) {
                napi_set_element(env, result, i, ValueToNapi(env, array[i]));
            }
            return result;
        },
        [&](const std::unordered_map<std::string, Value>& map) -> napi_value {
            napi_value result;
            napi_create_object(env, &result);
            for (const auto& entry : map) {
                napi_set_named_property(env, result, entry.first.c_str(), 
                                       ValueToNapi(env, entry.second));
            }
            return result;
        },
        [&](const mbgl::Color& color) -> napi_value {
            // Return as RGBA array
            napi_value result;
            napi_create_array_with_length(env, 4, &result);
            napi_value r, g, b, a;
            napi_create_double(env, color.r, &r);
            napi_create_double(env, color.g, &g);
            napi_create_double(env, color.b, &b);
            napi_create_double(env, color.a, &a);
            napi_set_element(env, result, 0, r);
            napi_set_element(env, result, 1, g);
            napi_set_element(env, result, 2, b);
            napi_set_element(env, result, 3, a);
            return result;
        },
        [&](const mbgl::Padding& padding) -> napi_value {
            // Return as [top, right, bottom, left] array
            napi_value result;
            napi_create_array_with_length(env, 4, &result);
            napi_value t, r, b, l;
            napi_create_double(env, padding.top, &t);
            napi_create_double(env, padding.right, &r);
            napi_create_double(env, padding.bottom, &b);
            napi_create_double(env, padding.left, &l);
            napi_set_element(env, result, 0, t);
            napi_set_element(env, result, 1, r);
            napi_set_element(env, result, 2, b);
            napi_set_element(env, result, 3, l);
            return result;
        },
        [&](const Collator&) -> napi_value {
            // Collators cannot be serialized
            napi_value result;
            napi_get_null(env, &result);
            return result;
        },
        [&](const Formatted& formatted) -> napi_value {
            // Serialize Formatted object
            napi_value result;
            napi_create_object(env, &result);
            
            napi_value sections;
            napi_create_array_with_length(env, formatted.sections.size(), &sections);
            
            for (size_t i = 0; i < formatted.sections.size(); i++) {
                const auto& section = formatted.sections[i];
                napi_value sectionObj;
                napi_create_object(env, &sectionObj);
                
                napi_value text;
                napi_create_string_utf8(env, section.text.c_str(), section.text.length(), &text);
                napi_set_named_property(env, sectionObj, "text", text);
                
                if (section.fontScale) {
                    napi_value scale;
                    napi_create_double(env, *section.fontScale, &scale);
                    napi_set_named_property(env, sectionObj, "scale", scale);
                } else {
                    napi_value nullValue;
                    napi_get_null(env, &nullValue);
                    napi_set_named_property(env, sectionObj, "scale", nullValue);
                }
                
                if (section.fontStack) {
                    std::string fontStackStr = mbgl::fontStackToString(*section.fontStack);
                    napi_value fontStack;
                    napi_create_string_utf8(env, fontStackStr.c_str(), fontStackStr.length(), &fontStack);
                    napi_set_named_property(env, sectionObj, "fontStack", fontStack);
                } else {
                    napi_value nullValue;
                    napi_get_null(env, &nullValue);
                    napi_set_named_property(env, sectionObj, "fontStack", nullValue);
                }
                
                if (section.textColor) {
                    // Convert Color to RGBA array
                    napi_value colorArray;
                    napi_create_array_with_length(env, 4, &colorArray);
                    napi_value r, g, b, a;
                    napi_create_double(env, section.textColor->r, &r);
                    napi_create_double(env, section.textColor->g, &g);
                    napi_create_double(env, section.textColor->b, &b);
                    napi_create_double(env, section.textColor->a, &a);
                    napi_set_element(env, colorArray, 0, r);
                    napi_set_element(env, colorArray, 1, g);
                    napi_set_element(env, colorArray, 2, b);
                    napi_set_element(env, colorArray, 3, a);
                    napi_set_named_property(env, sectionObj, "textColor", colorArray);
                } else {
                    napi_value nullValue;
                    napi_get_null(env, &nullValue);
                    napi_set_named_property(env, sectionObj, "textColor", nullValue);
                }
                
                napi_set_element(env, sections, i, sectionObj);
            }
            
            napi_set_named_property(env, result, "sections", sections);
            return result;
        },
        [&](const Image& image) -> napi_value {
            // Image serializes to a string (the image ID)
            napi_value result;
            const std::string& imageId = image.id();
            napi_create_string_utf8(env, imageId.c_str(), imageId.length(), &result);
            return result;
        },
        [&](const auto&) -> napi_value {
            // Fallback for other types
            napi_value result;
            napi_get_null(env, &result);
            return result;
        }
    );
}

napi_value ExpressionNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("ExpressionNAPI", "Initializing Expression NAPI class");
    
    napi_property_descriptor properties[] = {
        { "evaluate", nullptr, Evaluate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isFeatureConstant", nullptr, IsFeatureConstant, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isZoomConstant", nullptr, IsZoomConstant, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "serialize", nullptr, Serialize, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_property_descriptor staticProperties[] = {
        { "parse", nullptr, Parse, nullptr, nullptr, nullptr, napi_static, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(
        env, 
        "Expression", 
        NAPI_AUTO_LENGTH, 
        New, 
        nullptr,
        sizeof(properties) / sizeof(properties[0]), 
        properties, 
        &cons
    );
    
    if (status != napi_ok) {
        Logger::error("ExpressionNAPI", "Failed to define Expression class");
        return nullptr;
    }
    
    // Add static methods
    for (size_t i = 0; i < sizeof(staticProperties) / sizeof(staticProperties[0]); i++) {
        napi_set_named_property(env, cons, staticProperties[i].utf8name, cons);
        napi_define_properties(env, cons, 1, &staticProperties[i]);
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("ExpressionNAPI", "Failed to create reference to Expression constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Expression", cons);
    if (status != napi_ok) {
        Logger::error("ExpressionNAPI", "Failed to export Expression class");
        return nullptr;
    }
    
    Logger::info("ExpressionNAPI", "Expression NAPI class registered successfully");
    return exports;
}

napi_value ExpressionNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Constructor should only be called internally via Parse
    // Users should use Expression.parse() static method
    return args.This();
}

napi_value ExpressionNAPI::Parse(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }
    
    try {
        // Get JSON expression argument
        napi_value jsonArg = args.GetValue(0);
        if (!jsonArg) {
            napi_throw_error(env, nullptr, "Invalid JSON expression argument");
            return nullptr;
        }
        
        // Wrap in NapiValue for conversion system
        mbgl::harmony::NapiValue napiValue(env, jsonArg);
        
        // Create a Convertible wrapper  
        conversion::Convertible convertible(napiValue);
        
        // Parse expected type if provided
        std::optional<type::Type> expected;
        if (args.Has(1)) {
            napi_value typeArg = args.GetValue(1);
            if (args.IsType(1, napi_object)) {
                // Parse type object (e.g., {kind: "string"})
                // Full type parsing can be added later if needed
            }
        }
        
        // Create parsing context
        ParsingContext ctx = expected ? ParsingContext(*expected) : ParsingContext();
        
        // Parse the expression
        ParseResult parsed = ctx.parseLayerPropertyExpression(convertible);
        
        if (parsed) {
            // Success: create Expression NAPI object
            napi_value cons;
            napi_get_reference_value(env, constructor, &cons);
            
            napi_value instance;
            napi_new_instance(env, cons, 0, nullptr, &instance);
            
            auto* exprNapi = new ExpressionNAPI(std::move(*parsed));
            napi_wrap(env, instance, exprNapi, Destructor, nullptr, nullptr);
            
            return instance;
        } else {
            // Failure: return error array
            const auto& errors = ctx.getErrors();
            napi_value errorArray;
            napi_create_array_with_length(env, errors.size(), &errorArray);
            
            for (size_t i = 0; i < errors.size(); i++) {
                napi_value errorObj;
                napi_create_object(env, &errorObj);
                
                napi_value key;
                napi_create_string_utf8(env, errors[i].key.c_str(), errors[i].key.length(), &key);
                napi_set_named_property(env, errorObj, "key", key);
                
                napi_value message;
                napi_create_string_utf8(env, errors[i].message.c_str(), errors[i].message.length(), &message);
                napi_set_named_property(env, errorObj, "error", message);
                
                napi_set_element(env, errorArray, i, errorObj);
            }
            
            return errorArray;
        }
    } catch (const std::exception& ex) {
        napi_throw_error(env, nullptr, ex.what());
        return nullptr;
    }
}

napi_value ExpressionNAPI::Evaluate(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    ExpressionNAPI* obj;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->expression) {
        napi_throw_error(env, nullptr, "Invalid Expression object");
        return nullptr;
    }
    
    try {
        // Parse evaluation parameters
        std::optional<float> zoom;
        mapbox::geojson::feature feature{mapbox::geojson::point{0.0, 0.0}};
        
        // First argument: globals object with zoom, etc.
        if (args.Has(0)) {
            napi_value globalsObj = args.GetValue(0);
            if (args.IsType(0, napi_object)) {
                // Get zoom property from globals object
                double zoomValue = args.GetDoubleProperty(globalsObj, "zoom", -1.0);
                if (zoomValue >= 0.0) {
                    zoom = static_cast<float>(zoomValue);
                }
            }
        }
        
        // Second argument: feature object (GeoJSON feature)
        // For now, we use a simple default feature
        // Full feature conversion can be implemented later if needed
        if (args.Has(1)) {
            // TODO: Implement full GeoJSON feature conversion
            // napi_value featureArg = args.GetValue(1);
        }
        
        // Evaluate the expression
        auto result = obj->expression->evaluate(zoom, feature, std::nullopt);
        
        if (result) {
            return ValueToNapi(env, *result);
        } else {
            // Evaluation error
            napi_value errorObj;
            napi_create_object(env, &errorObj);
            
            napi_value errorMsg;
            napi_create_string_utf8(env, result.error().message.c_str(), 
                                   result.error().message.length(), &errorMsg);
            napi_set_named_property(env, errorObj, "error", errorMsg);
            
            return errorObj;
        }
    } catch (const std::exception& ex) {
        napi_throw_error(env, nullptr, ex.what());
        return nullptr;
    }
}

napi_value ExpressionNAPI::GetType(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    ExpressionNAPI* obj;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->expression) {
        napi_throw_error(env, nullptr, "Invalid Expression object");
        return nullptr;
    }
    
    const type::Type& type = obj->expression->getType();
    std::string typeName = type.match([](const auto& t) { return t.getName(); });
    
    napi_value result;
    napi_create_string_utf8(env, typeName.c_str(), typeName.length(), &result);
    return result;
}

napi_value ExpressionNAPI::IsFeatureConstant(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    ExpressionNAPI* obj;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->expression) {
        napi_throw_error(env, nullptr, "Invalid Expression object");
        return nullptr;
    }
    
    bool isConstant = isFeatureConstant(*obj->expression);
    
    napi_value result;
    napi_get_boolean(env, isConstant, &result);
    return result;
}

napi_value ExpressionNAPI::IsZoomConstant(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    ExpressionNAPI* obj;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->expression) {
        napi_throw_error(env, nullptr, "Invalid Expression object");
        return nullptr;
    }
    
    bool isConstant = isZoomConstant(*obj->expression);
    
    napi_value result;
    napi_get_boolean(env, isConstant, &result);
    return result;
}

napi_value ExpressionNAPI::Serialize(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    ExpressionNAPI* obj;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->expression) {
        napi_throw_error(env, nullptr, "Invalid Expression object");
        return nullptr;
    }
    
    mbgl::Value serialized = obj->expression->serialize();
    // serialized is already mbgl::Value, just convert to napi_value
    return MbglValueToNapi(env, serialized);
}

// Helper: Convert mbgl::Value to napi_value (for serialize())
napi_value MbglValueToNapi(napi_env env, const mbgl::Value& value) {
    return value.match(
        [&](mbgl::NullValue) -> napi_value {
            napi_value result;
            napi_get_null(env, &result);
            return result;
        },
        [&](bool v) -> napi_value {
            napi_value result;
            napi_get_boolean(env, v, &result);
            return result;
        },
        [&](uint64_t v) -> napi_value {
            napi_value result;
            napi_create_double(env, static_cast<double>(v), &result);
            return result;
        },
        [&](int64_t v) -> napi_value {
            napi_value result;
            napi_create_double(env, static_cast<double>(v), &result);
            return result;
        },
        [&](double v) -> napi_value {
            napi_value result;
            napi_create_double(env, v, &result);
            return result;
        },
        [&](const std::string& v) -> napi_value {
            napi_value result;
            napi_create_string_utf8(env, v.c_str(), v.length(), &result);
            return result;
        },
        [&](const std::vector<mbgl::Value>& array) -> napi_value {
            napi_value result;
            napi_create_array_with_length(env, array.size(), &result);
            for (size_t i = 0; i < array.size(); i++) {
                napi_set_element(env, result, i, MbglValueToNapi(env, array[i]));
            }
            return result;
        },
        [&](const std::unordered_map<std::string, mbgl::Value>& map) -> napi_value {
            napi_value result;
            napi_create_object(env, &result);
            for (const auto& entry : map) {
                napi_set_named_property(env, result, entry.first.c_str(), 
                                       MbglValueToNapi(env, entry.second));
            }
            return result;
        },
        [&](const auto&) -> napi_value {
            // Fallback for other types
            napi_value result;
            napi_get_null(env, &result);
            return result;
        }
    );
}

} // namespace harmony
} // namespace maplibre

