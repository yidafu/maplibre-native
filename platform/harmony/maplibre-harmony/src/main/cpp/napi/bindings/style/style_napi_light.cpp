#include "style_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "style/transition_options_harmony.hpp"

#include <mln/map/map.hpp>
#include <mln/style/light.hpp>
#include <mln/style/types.hpp>
#include <mln/util/color.hpp>

#include <array>
#include <functional>
#include <optional>
#include <string>
#include <vector>

using mln::harmony::Logger;
using mln::harmony::napi::NapiArgs;
using mln::harmony::napi::GetStringFromValue;

namespace mln {
namespace harmony {

napi_value StyleNAPI::SetLight(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->acquireMap()) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    napi_value lightOptions = napiArgs.GetObject(0, "light");
    if (napiArgs.HasError()) {
        return nullptr;
    }
    
    // Applies are collected during parsing and committed to the light in one
    // render-thread dispatch at the end of this function.
    std::vector<std::function<void(mln::style::Light&)>> pendingApply;

    try {
        napi_valuetype valueType = napi_undefined;
        napi_typeof(env, lightOptions, &valueType);

        if (valueType == napi_string) {
            // Accept a JSON string via JSON.parse (avoids duplicating the
            // parser in C++); fall through with the parsed object.
            std::string json = GetStringFromValue(env, lightOptions);
            napi_value global, jsonObj, parseFn, parsed = nullptr;
            if (napi_get_global(env, &global) == napi_ok &&
                napi_get_named_property(env, global, "JSON", &jsonObj) == napi_ok &&
                napi_get_named_property(env, jsonObj, "parse", &parseFn) == napi_ok) {
                napi_value strValue;
                if (napi_create_string_utf8(env, json.c_str(), NAPI_AUTO_LENGTH, &strValue) == napi_ok &&
                    napi_call_function(env, jsonObj, parseFn, 1, &strValue, &parsed) == napi_ok) {
                    napi_valuetype parsedType = napi_undefined;
                    napi_typeof(env, parsed, &parsedType);
                    if (parsedType == napi_object) {
                        lightOptions = parsed;
                        valueType = napi_object;
                    }
                }
            }
            if (valueType != napi_object) {
                Logger::warn("StyleNAPI", "SetLight: Failed to parse JSON string input");
                return napiArgs.Undefined();
            }
        }

        if (valueType != napi_object) {
            Logger::warn("StyleNAPI", "SetLight: Expected object argument");
            return napiArgs.Undefined();
        }

        auto hasProperty = [&](napi_value object, const char* name, napi_value& out) -> bool {
            bool has = false;
            if (napi_has_named_property(env, object, name, &has) != napi_ok || !has) {
                return false;
            }
            if (napi_get_named_property(env, object, name, &out) != napi_ok) {
                return false;
            }
            return true;
        };

        // anchor
        {
            napi_value anchorValue;
            if (hasProperty(lightOptions, "anchor", anchorValue)) {
                std::string anchor = GetStringFromValue(env, anchorValue);
                if (anchor == "map" || anchor == "viewport") {
                    const mln::style::LightAnchorType anchorType = (anchor == "map")
                        ? mln::style::LightAnchorType::Map
                        : mln::style::LightAnchorType::Viewport;
                    pendingApply.push_back([anchorType](mln::style::Light& light) {
                        light.setAnchor(anchorType);
                    });
                } else {
                    Logger::warn("StyleNAPI", "SetLight: Unknown anchor '%s'", anchor.c_str());
                }
            }
        }

        // position
        {
            napi_value positionValue;
            if (hasProperty(lightOptions, "position", positionValue)) {
                std::array<float, 3> spherical = {1.15f, 210.0f, 30.0f};
                bool parsed = false;
                bool isArray = false;
                if (napi_is_array(env, positionValue, &isArray) == napi_ok && isArray) {
                    uint32_t length = 0;
                    napi_get_array_length(env, positionValue, &length);
                    if (length >= 2) {
                        double radial = 0.0;
                        double azimuthal = 0.0;
                        double polar = 0.0;
                        napi_value element;
                        napi_get_element(env, positionValue, 0, &element);
                        napi_get_value_double(env, element, &radial);
                        napi_get_element(env, positionValue, 1, &element);
                        napi_get_value_double(env, element, &azimuthal);
                        if (length >= 3) {
                            napi_get_element(env, positionValue, 2, &element);
                            napi_get_value_double(env, element, &polar);
                        }
                        spherical = {static_cast<float>(radial),
                                     static_cast<float>(azimuthal),
                                     static_cast<float>(polar)};
                        parsed = true;
                    }
                } else {
                    napi_value radialValue, azimuthalValue, polarValue;
                    double radial = 0.0, azimuthal = 0.0, polar = 0.0;
                    if (hasProperty(positionValue, "radial", radialValue) &&
                        hasProperty(positionValue, "azimuthal", azimuthalValue)) {
                        napi_get_value_double(env, radialValue, &radial);
                        napi_get_value_double(env, azimuthalValue, &azimuthal);
                        if (hasProperty(positionValue, "polar", polarValue)) {
                            napi_get_value_double(env, polarValue, &polar);
                        }
                        spherical = {static_cast<float>(radial),
                                     static_cast<float>(azimuthal),
                                     static_cast<float>(polar)};
                        parsed = true;
                    }
                }

                if (parsed) {
                    mln::style::Position position(spherical);
                    pendingApply.push_back([position](mln::style::Light& light) {
                        light.setPosition(position);
                    });
                } else {
                    Logger::warn("StyleNAPI", "SetLight: Failed to parse position");
                }
            }
        }

        // color
        {
            napi_value colorValue;
            if (hasProperty(lightOptions, "color", colorValue)) {
                std::string colorStr = GetStringFromValue(env, colorValue);
                auto parsedColor = mln::Color::parse(colorStr);
                if (parsedColor) {
                    const mln::Color color = *parsedColor;
                    pendingApply.push_back([color](mln::style::Light& light) {
                        light.setColor(color);
                    });
                } else {
                    Logger::warn("StyleNAPI", "SetLight: Invalid color '%s'", colorStr.c_str());
                }
            }
        }

        // intensity
        {
            napi_value intensityValue;
            if (hasProperty(lightOptions, "intensity", intensityValue)) {
                double intensity = 0.0;
                if (napi_get_value_double(env, intensityValue, &intensity) == napi_ok) {
                    const float intensityF = static_cast<float>(intensity);
                    pendingApply.push_back([intensityF](mln::style::Light& light) {
                        light.setIntensity(intensityF);
                    });
                } else {
                    Logger::warn("StyleNAPI", "SetLight: Failed to parse intensity");
                }
            }
        }

        auto applyTransition = [&](const char* propertyName,
                                   const std::function<void(const mln::style::TransitionOptions&)>& setter) {
            napi_value transitionValue;
            if (!hasProperty(lightOptions, propertyName, transitionValue)) {
                return;
            }

            napi_valuetype transitionType = napi_undefined;
            napi_typeof(env, transitionValue, &transitionType);
            if (transitionType != napi_object) {
                Logger::warn("StyleNAPI", "SetLight: Transition '%s' must be an object", propertyName);
                return;
            }

            mln::style::TransitionOptions options;
            TransitionOptionsHarmony::ParseTransitionOptions(env, transitionValue, options);
            setter(options);
        };

        applyTransition("positionTransition", [&](const mln::style::TransitionOptions& options) {
            pendingApply.push_back([options](mln::style::Light& light) {
                light.setPositionTransition(options);
            });
        });

        applyTransition("colorTransition", [&](const mln::style::TransitionOptions& options) {
            pendingApply.push_back([options](mln::style::Light& light) {
                light.setColorTransition(options);
            });
        });

        applyTransition("intensityTransition", [&](const mln::style::TransitionOptions& options) {
            pendingApply.push_back([options](mln::style::Light& light) {
                light.setIntensityTransition(options);
            });
        });

        if (!pendingApply.empty()) {
            style->runOnMap([&](mln::Map& m) {
                mln::style::Light* light = m.getStyle().getLight();
                if (!light) {
                    return;
                }
                for (auto& apply : pendingApply) {
                    apply(*light);
                }
            });
        }

        Logger::info("StyleNAPI", "SetLight applied light specification");

        return napiArgs.Undefined();
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "SetLight failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

} // namespace harmony
} // namespace mln
