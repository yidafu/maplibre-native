#include "constant.hpp"
#include "utils/logger.h"
#include <mbgl/style/conversion/stringify.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/string.hpp>
#include <mbgl/util/enum.hpp>
#include <mbgl/util/font_stack.hpp>

namespace mbgl {
namespace harmony {
namespace conversion {

using Logger = mbgl::harmony::Logger;

Result<napi_value> convertToNapi(napi_env env, bool value) {
    napi_value result;
    napi_status status = napi_get_boolean(env, value, &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to convert bool to napi_value");
        return {};
    }
    return result;
}

Result<napi_value> convertToNapi(napi_env env, float value) {
    napi_value result;
    napi_status status = napi_create_double(env, static_cast<double>(value), &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to convert float to napi_value");
        return {};
    }
    return result;
}

Result<napi_value> convertToNapi(napi_env env, double value) {
    napi_value result;
    napi_status status = napi_create_double(env, value, &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to convert double to napi_value");
        return {};
    }
    return result;
}

template <typename T>
Result<napi_value> convertToNapi(napi_env env, T value, typename std::enable_if<std::is_integral<T>::value>::type*) {
    napi_value result;
    napi_status status = napi_create_int64(env, static_cast<int64_t>(value), &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to convert integer to napi_value");
        return {};
    }
    return result;
}

// Explicit instantiations for common integer types
template Result<napi_value> convertToNapi(napi_env, int, void*);
template Result<napi_value> convertToNapi(napi_env, int64_t, void*);
#if SIZE_MAX != UINT64_MAX
template Result<napi_value> convertToNapi(napi_env, uint64_t, void*);
template Result<napi_value> convertToNapi(napi_env, size_t, void*);
#else
template Result<napi_value> convertToNapi(napi_env, uint64_t, void*);
#endif

Result<napi_value> convertToNapi(napi_env env, const std::string& value) {
    napi_value result;
    napi_status status = napi_create_string_utf8(env, value.c_str(), NAPI_AUTO_LENGTH, &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to convert string to napi_value");
        return {};
    }
    return result;
}

Result<napi_value> convertToNapi(napi_env env, const Color& value) {
    // Convert color to string format (e.g., "rgba(255, 0, 0, 1.0)")
    std::string colorStr = value.stringify();
    napi_value result;
    napi_status status = napi_create_string_utf8(env, colorStr.c_str(), NAPI_AUTO_LENGTH, &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to convert Color to napi_value");
        return {};
    }
    return result;
}

Result<napi_value> convertToNapi(napi_env env, const Padding& value) {
    const auto values = value.toArray();
    napi_value result;
    napi_status status = napi_create_array_with_length(env, values.size(), &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to create array for Padding");
        return {};
    }
    
    for (size_t i = 0; i < values.size(); i++) {
        napi_value element;
        napi_create_double(env, static_cast<double>(values[i]), &element);
        napi_set_element(env, result, static_cast<uint32_t>(i), element);
    }
    
    return result;
}

Result<napi_value> convertToNapi(napi_env env, const VariableAnchorOffsetCollection& value) {
    napi_value result;
    napi_status status = napi_create_array_with_length(env, value.size() * 2, &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to create array for VariableAnchorOffsetCollection");
        return {};
    }
    
    for (std::size_t i = 0; i < value.size(); i++) {
        auto anchorOffsetPair = value[i];
        
        // Add anchor type as string
        std::string anchorStr = mbgl::Enum<style::SymbolAnchorType>::toString(anchorOffsetPair.anchorType);
        napi_value anchorValue;
        napi_create_string_utf8(env, anchorStr.c_str(), NAPI_AUTO_LENGTH, &anchorValue);
        napi_set_element(env, result, static_cast<uint32_t>(i * 2), anchorValue);
        
        // Add offset as array
        napi_value offsetArray;
        napi_create_array_with_length(env, anchorOffsetPair.offset.size(), &offsetArray);
        for (size_t j = 0; j < anchorOffsetPair.offset.size(); j++) {
            napi_value offsetValue;
            napi_create_double(env, static_cast<double>(anchorOffsetPair.offset[j]), &offsetValue);
            napi_set_element(env, offsetArray, static_cast<uint32_t>(j), offsetValue);
        }
        napi_set_element(env, result, static_cast<uint32_t>(i * 2 + 1), offsetArray);
    }
    
    return result;
}

Result<napi_value> convertToNapi(napi_env env, const style::expression::Formatted& value) {
    // Create a structured object with sections array, preserving formatting info.
    // Result: { sections: [{ text, fontStack, scale }, ...] }
    napi_value result;
    napi_status status = napi_create_object(env, &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to create Formatted object");
        return {};
    }

    // Create sections array
    napi_value sectionsArr;
    status = napi_create_array_with_length(env, value.sections.size(), &sectionsArr);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to create sections array");
        return {};
    }

    for (std::size_t i = 0; i < value.sections.size(); i++) {
        const auto& section = value.sections[i];
        napi_value sectionObj;
        napi_create_object(env, &sectionObj);

        // text (string)
        napi_value textVal;
        napi_create_string_utf8(env, section.text.c_str(), NAPI_AUTO_LENGTH, &textVal);
        napi_set_named_property(env, sectionObj, "text", textVal);

        // fontStack (optional FontStack=vector<string> -> string or null)
        if (section.fontStack && !section.fontStack->empty()) {
            std::string fontStackStr = mbgl::fontStackToString(*section.fontStack);
            napi_value fontVal;
            napi_create_string_utf8(env, fontStackStr.c_str(), NAPI_AUTO_LENGTH, &fontVal);
            napi_set_named_property(env, sectionObj, "fontStack", fontVal);
        } else {
            napi_value nullVal;
            napi_get_null(env, &nullVal);
            napi_set_named_property(env, sectionObj, "fontStack", nullVal);
        }

        // fontScale (optional double -> null on absent)
        if (section.fontScale) {
            napi_value scaleVal;
            napi_create_double(env, *section.fontScale, &scaleVal);
            napi_set_named_property(env, sectionObj, "fontScale", scaleVal);
        } else {
            napi_value nullVal;
            napi_get_null(env, &nullVal);
            napi_set_named_property(env, sectionObj, "fontScale", nullVal);
        }

        // textColor (optional Color -> string or null)
        if (section.textColor) {
            std::string colorStr = section.textColor->stringify();
            napi_value colorVal;
            napi_create_string_utf8(env, colorStr.c_str(), NAPI_AUTO_LENGTH, &colorVal);
            napi_set_named_property(env, sectionObj, "textColor", colorVal);
        } else {
            napi_value nullVal;
            napi_get_null(env, &nullVal);
            napi_set_named_property(env, sectionObj, "textColor", nullVal);
        }

        napi_set_element(env, sectionsArr, static_cast<uint32_t>(i), sectionObj);
    }

    napi_set_named_property(env, result, "sections", sectionsArr);
    return result;
}

Result<napi_value> convertToNapi(napi_env env, const style::expression::Image& value) {
    // Image is just an ID string
    napi_value result;
    napi_status status = napi_create_string_utf8(env, value.id().c_str(), NAPI_AUTO_LENGTH, &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to convert Image to napi_value");
        return {};
    }
    return result;
}

Result<napi_value> convertToNapi(napi_env env, const style::Rotation& value) {
    napi_value result;
    napi_status status = napi_create_double(env, value.getAngle(), &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to convert Rotation to napi_value");
        return {};
    }
    return result;
}

Result<napi_value> convertToNapi(napi_env env, const std::vector<std::string>& value) {
    napi_value result;
    napi_status status = napi_create_array_with_length(env, value.size(), &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to create array for vector<string>");
        return {};
    }
    
    for (std::size_t i = 0; i < value.size(); i++) {
        napi_value element;
        napi_create_string_utf8(env, value[i].c_str(), NAPI_AUTO_LENGTH, &element);
        napi_set_element(env, result, static_cast<uint32_t>(i), element);
    }
    
    return result;
}

Result<napi_value> convertToNapi(napi_env env, const std::vector<float>& value) {
    napi_value result;
    napi_status status = napi_create_array_with_length(env, value.size(), &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to create array for vector<float>");
        return {};
    }
    
    for (std::size_t i = 0; i < value.size(); i++) {
        napi_value element;
        napi_create_double(env, static_cast<double>(value[i]), &element);
        napi_set_element(env, result, static_cast<uint32_t>(i), element);
    }
    
    return result;
}

Result<napi_value> convertToNapi(napi_env env, const std::vector<double>& value) {
    napi_value result;
    napi_status status = napi_create_array_with_length(env, value.size(), &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to create array for vector<double>");
        return {};
    }
    
    for (std::size_t i = 0; i < value.size(); i++) {
        napi_value element;
        napi_create_double(env, value[i], &element);
        napi_set_element(env, result, static_cast<uint32_t>(i), element);
    }
    
    return result;
}

// Array converter implementation
template <typename T, size_t N>
Result<napi_value> convertToNapi(napi_env env, const std::array<T, N>& value) {
    napi_value result;
    napi_status status = napi_create_array_with_length(env, N, &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to create array");
        return {};
    }
    
    for (size_t i = 0; i < N; i++) {
        napi_value element;
        if constexpr (std::is_floating_point<T>::value) {
            napi_create_double(env, static_cast<double>(value[i]), &element);
        } else if constexpr (std::is_integral<T>::value) {
            napi_create_int64(env, static_cast<int64_t>(value[i]), &element);
        }
        napi_set_element(env, result, static_cast<uint32_t>(i), element);
    }
    
    return result;
}

// Explicit instantiations for common array types
template Result<napi_value> convertToNapi(napi_env, const std::array<float, 2>&);
template Result<napi_value> convertToNapi(napi_env, const std::array<float, 3>&);
template Result<napi_value> convertToNapi(napi_env, const std::array<float, 4>&);
template Result<napi_value> convertToNapi(napi_env, const std::array<double, 2>&);
template Result<napi_value> convertToNapi(napi_env, const std::array<double, 3>&);
template Result<napi_value> convertToNapi(napi_env, const std::array<double, 4>&);

// Enum template implementation and instantiations
template <typename T>
Result<napi_value> convertToNapi(napi_env env, T value, typename std::enable_if<std::is_enum<T>::value>::type*) {
    napi_value result;
    std::string str = mbgl::Enum<T>::toString(value);
    napi_status status = napi_create_string_utf8(env, str.c_str(), NAPI_AUTO_LENGTH, &result);
    if (status != napi_ok) {
        Logger::error("Converter", "Failed to convert enum to napi_value");
        return {};
    }
    return result;
}

// Explicit instantiations for common enum types
template Result<napi_value> convertToNapi(napi_env, mbgl::style::SymbolAnchorType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::LineCapType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::LineJoinType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::HillshadeIlluminationAnchorType, void*);

// Explicit instantiations for new enum types (Expression support)
template Result<napi_value> convertToNapi(napi_env, mbgl::style::TranslateAnchorType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::CirclePitchScaleType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::AlignmentType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::RasterResamplingType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::IconTextFitType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::TextJustifyType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::TextTransformType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::SymbolPlacementType, void*);
template Result<napi_value> convertToNapi(napi_env, mbgl::style::SymbolZOrderType, void*);

} // namespace conversion
} // namespace harmony
} // namespace mbgl

