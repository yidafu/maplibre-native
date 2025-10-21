#include <mbgl/i18n/number_format.hpp>

#include <string>

/*
    HarmonyOS implementation of number formatting.
    
    Since HarmonyOS uses MBGL_USE_BUILTIN_ICU, we use a simple
    implementation based on std::to_string.
    
    For more advanced formatting, this could be enhanced to use
    HarmonyOS native APIs in the future.
*/

namespace mbgl {
namespace platform {

std::string formatNumber(double number,
                         const std::string&,
                         const std::string&,
                         uint8_t,
                         uint8_t) {
    return std::to_string(number);
}

} // namespace platform
} // namespace mbgl

