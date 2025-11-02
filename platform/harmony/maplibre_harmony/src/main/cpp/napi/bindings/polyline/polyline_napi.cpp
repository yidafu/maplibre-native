#include "polyline_napi.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include "geometry/lat_lng_harmony.hpp"

namespace maplibre {
namespace harmony {

// Use Logger from mbgl::harmony namespace
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// Static member initialization
napi_ref PolylineNAPI::constructor = nullptr;

PolylineNAPI::PolylineNAPI()
    : annotationId(-1),
      color(mbgl::Color::black()),
      width(10.0f),
      alpha(1.0f),
      visible(true),
      zIndex(0),
      jointType("round"),
      capType("round"),
      mapLibreMapRef(nullptr) {
}

PolylineNAPI::~PolylineNAPI() {
}

void PolylineNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    PolylineNAPI* polyline = static_cast<PolylineNAPI*>(nativeObject);
    
    // Clear MapLibreMap reference
    if (polyline->mapLibreMapRef) {
        napi_delete_reference(env, polyline->mapLibreMapRef);
        polyline->mapLibreMapRef = nullptr;
    }
    
    delete polyline;
}

napi_value PolylineNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("PolylineNAPI", "Initializing Polyline NAPI class");
    
    napi_property_descriptor properties[] = {
        // Getter methods
        { "getPoints", nullptr, GetPoints, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getColor", nullptr, GetColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getWidth", nullptr, GetWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getAlpha", nullptr, GetAlpha, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisible", nullptr, GetVisible, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getZIndex", nullptr, GetZIndex, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getPattern", nullptr, GetPattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getJointType", nullptr, GetJointType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCapType", nullptr, GetCapType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Setter methods
        { "setPoints", nullptr, SetPoints, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setColor", nullptr, SetColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setWidth", nullptr, SetWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setAlpha", nullptr, SetAlpha, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setVisible", nullptr, SetVisible, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setZIndex", nullptr, SetZIndex, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setPattern", nullptr, SetPattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setJointType", nullptr, SetJointType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCapType", nullptr, SetCapType, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Helper methods
        { "addPoint", nullptr, AddPoint, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "insertPoint", nullptr, InsertPoint, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removePoint", nullptr, RemovePoint, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setId", nullptr, SetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMapLibreMap", nullptr, SetMapLibreMap, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Polyline", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("PolylineNAPI", "Failed to define Polyline class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("PolylineNAPI", "Failed to create reference to Polyline constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Polyline", cons);
    if (status != napi_ok) {
        Logger::error("PolylineNAPI", "Failed to export Polyline class");
        return nullptr;
    }
    
    Logger::info("PolylineNAPI", "Polyline NAPI class registered successfully");
    return exports;
}

napi_value PolylineNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    // Create PolylineNAPI instance
    PolylineNAPI* polyline = new PolylineNAPI();
    
    // Parse options object if provided
    if (args.Count() > 0) {
        napi_value optionsObj = args.GetObject(0, "options");
        if (args.HasError()) {
            delete polyline;
            return nullptr;
        }
        
        // Parse points (required)
        napi_value pointsValue;
        if (napi_get_named_property(env, optionsObj, "points", &pointsValue) == napi_ok) {
            bool isArray = false;
            napi_is_array(env, pointsValue, &isArray);
            if (isArray) {
                uint32_t length = 0;
                napi_get_array_length(env, pointsValue, &length);
                
                for (uint32_t i = 0; i < length; i++) {
                    napi_value pointValue;
                    napi_get_element(env, pointsValue, i, &pointValue);
                    
                    mbgl::LatLng latLng;
                    if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
                        polyline->points.push_back(mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
                    }
                }
            }
        }
        
        // Parse color (optional)
        std::string colorStr = args.GetStringProperty(optionsObj, "color", "#000000");
        if (!colorStr.empty() && colorStr[0] == '#') {
            try {
                unsigned int colorValue = std::stoul(colorStr.substr(1), nullptr, 16);
                float r = ((colorValue >> 16) & 0xFF) / 255.0f;
                float g = ((colorValue >> 8) & 0xFF) / 255.0f;
                float b = (colorValue & 0xFF) / 255.0f;
                polyline->color = mbgl::Color(r, g, b, 1.0f);
            } catch (...) {
                Logger::error("PolylineNAPI", "Failed to parse color: %s", colorStr.c_str());
            }
        }
        
        // Parse width (optional)
        polyline->width = static_cast<float>(args.GetDoubleProperty(optionsObj, "width", 10.0));
        
        // Parse alpha (optional)
        polyline->alpha = static_cast<float>(args.GetDoubleProperty(optionsObj, "alpha", 1.0));
        
        // Parse visible (optional)
        polyline->visible = args.GetBoolProperty(optionsObj, "visible", true);
        
        // Parse zIndex (optional)
        polyline->zIndex = static_cast<int>(args.GetInt64Property(optionsObj, "zIndex", 0));
        
        // Parse pattern (optional)
        napi_value patternValue;
        if (napi_get_named_property(env, optionsObj, "pattern", &patternValue) == napi_ok) {
            bool isArray = false;
            napi_is_array(env, patternValue, &isArray);
            if (isArray) {
                uint32_t length = 0;
                napi_get_array_length(env, patternValue, &length);
                
                for (uint32_t i = 0; i < length; i++) {
                    napi_value val;
                    napi_get_element(env, patternValue, i, &val);
                    double num;
                    napi_get_value_double(env, val, &num);
                    polyline->pattern.push_back(static_cast<float>(num));
                }
            }
        }
        
        // Parse jointType (optional)
        polyline->jointType = args.GetStringProperty(optionsObj, "jointType", "round");
        
        // Parse capType (optional)
        polyline->capType = args.GetStringProperty(optionsObj, "capType", "round");
    }
    
    Logger::info("PolylineNAPI", "Polyline created with %zu points, color=rgba(%f,%f,%f,%f), width=%f",
                 polyline->points.size(), 
                 polyline->color.r, polyline->color.g, polyline->color.b, polyline->alpha,
                 polyline->width);
    
    // Wrap native object to NAPI object
    napi_status status = napi_wrap(env, thisVar, polyline, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        Logger::error("PolylineNAPI", "Failed to wrap PolylineNAPI instance");
        delete polyline;
        return nullptr;
    }
    
    return thisVar;
}

// Convert to mbgl::LineAnnotation
mbgl::LineAnnotation PolylineNAPI::toAnnotation() const {
    mbgl::LineString<double> lineString;
    for (const auto& point : points) {
        lineString.push_back(point);
    }
    
    mbgl::LineAnnotation annotation(lineString);
    annotation.opacity = alpha;
    annotation.color = color;
    annotation.width = width;
    
    return annotation;
}

// Getter implementations
napi_value PolylineNAPI::GetPoints(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return nullptr;
    
    napi_value result;
    napi_create_array_with_length(env, polyline->points.size(), &result);
    
    for (size_t i = 0; i < polyline->points.size(); i++) {
        napi_value point;
        napi_create_object(env, &point);
        
        napi_value lat, lng;
        napi_create_double(env, polyline->points[i].y, &lat);
        napi_create_double(env, polyline->points[i].x, &lng);
        
        napi_set_named_property(env, point, "latitude", lat);
        napi_set_named_property(env, point, "longitude", lng);
        
        napi_set_element(env, result, i, point);
    }
    
    return result;
}

napi_value PolylineNAPI::GetColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return nullptr;
    
    // Convert color to hex string
    char colorStr[8];
    snprintf(colorStr, sizeof(colorStr), "#%02X%02X%02X",
             static_cast<int>(polyline->color.r * 255),
             static_cast<int>(polyline->color.g * 255),
             static_cast<int>(polyline->color.b * 255));
    
    napi_value result;
    napi_create_string_utf8(env, colorStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value PolylineNAPI::GetWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return nullptr;
    
    napi_value result;
    napi_create_double(env, polyline->width, &result);
    return result;
}

napi_value PolylineNAPI::GetAlpha(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return nullptr;
    
    napi_value result;
    napi_create_double(env, polyline->alpha, &result);
    return result;
}

napi_value PolylineNAPI::GetVisible(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return nullptr;
    
    napi_value result;
    napi_get_boolean(env, polyline->visible, &result);
    return result;
}

napi_value PolylineNAPI::GetZIndex(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return nullptr;
    
    napi_value result;
    napi_create_int32(env, polyline->zIndex, &result);
    return result;
}

napi_value PolylineNAPI::GetPattern(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline || polyline->pattern.empty()) {
        napi_value null;
        napi_get_null(env, &null);
        return null;
    }
    
    napi_value result;
    napi_create_array_with_length(env, polyline->pattern.size(), &result);
    
    for (size_t i = 0; i < polyline->pattern.size(); i++) {
        napi_value val;
        napi_create_double(env, polyline->pattern[i], &val);
        napi_set_element(env, result, i, val);
    }
    
    return result;
}

napi_value PolylineNAPI::GetJointType(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return nullptr;
    
    napi_value result;
    napi_create_string_utf8(env, polyline->jointType.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value PolylineNAPI::GetCapType(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return nullptr;
    
    napi_value result;
    napi_create_string_utf8(env, polyline->capType.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value PolylineNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return nullptr;
    
    napi_value result;
    napi_create_int64(env, static_cast<int64_t>(polyline->annotationId), &result);
    return result;
}

// Setter implementations
napi_value PolylineNAPI::SetPoints(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    napi_value pointsValue = args.Get(0);
    bool isArray = false;
    napi_is_array(env, pointsValue, &isArray);
    
    if (isArray) {
        polyline->points.clear();
        uint32_t length = 0;
        napi_get_array_length(env, pointsValue, &length);
        
        for (uint32_t i = 0; i < length; i++) {
            napi_value pointValue;
            napi_get_element(env, pointsValue, i, &pointValue);
            
            mbgl::LatLng latLng;
            if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
                polyline->points.push_back(mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
            }
        }
    }
    
    return thisVar;
}

napi_value PolylineNAPI::SetColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    std::string colorStr = args.GetString(0, "color");
    if (!colorStr.empty() && colorStr[0] == '#') {
        try {
            unsigned int colorValue = std::stoul(colorStr.substr(1), nullptr, 16);
            float r = ((colorValue >> 16) & 0xFF) / 255.0f;
            float g = ((colorValue >> 8) & 0xFF) / 255.0f;
            float b = (colorValue & 0xFF) / 255.0f;
            polyline->color = mbgl::Color(r, g, b, 1.0f);
        } catch (...) {
            Logger::error("PolylineNAPI", "Failed to parse color: %s", colorStr.c_str());
        }
    }
    
    return thisVar;
}

napi_value PolylineNAPI::SetWidth(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    polyline->width = static_cast<float>(args.GetDouble(0));
    return thisVar;
}

napi_value PolylineNAPI::SetAlpha(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    polyline->alpha = static_cast<float>(args.GetDouble(0));
    return thisVar;
}

napi_value PolylineNAPI::SetVisible(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    polyline->visible = args.GetBool(0);
    return thisVar;
}

napi_value PolylineNAPI::SetZIndex(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    polyline->zIndex = args.GetInt32(0);
    return thisVar;
}

napi_value PolylineNAPI::SetPattern(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    if (args.Count() == 0) {
        polyline->pattern.clear();
        return thisVar;
    }
    
    napi_value patternValue = args.Get(0);
    napi_valuetype type;
    napi_typeof(env, patternValue, &type);
    
    if (type == napi_null || type == napi_undefined) {
        polyline->pattern.clear();
    } else {
        bool isArray = false;
        napi_is_array(env, patternValue, &isArray);
        if (isArray) {
            polyline->pattern.clear();
            uint32_t length = 0;
            napi_get_array_length(env, patternValue, &length);
            
            for (uint32_t i = 0; i < length; i++) {
                napi_value val;
                napi_get_element(env, patternValue, i, &val);
                double num;
                napi_get_value_double(env, val, &num);
                polyline->pattern.push_back(static_cast<float>(num));
            }
        }
    }
    
    return thisVar;
}

napi_value PolylineNAPI::SetJointType(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    polyline->jointType = args.GetString(0, "jointType");
    return thisVar;
}

napi_value PolylineNAPI::SetCapType(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    polyline->capType = args.GetString(0, "capType");
    return thisVar;
}

// Helper methods
napi_value PolylineNAPI::AddPoint(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value pointValue = args.GetObject(0, "point");
    if (!args.HasError()) {
        mbgl::LatLng latLng;
        if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
            polyline->points.push_back(mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
        }
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value PolylineNAPI::InsertPoint(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    int32_t index = args.GetInt32(0);
    napi_value pointValue = args.GetObject(1, "point");
    
    if (!args.HasError() && index >= 0 && static_cast<size_t>(index) <= polyline->points.size()) {
        mbgl::LatLng latLng;
        if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
            polyline->points.insert(polyline->points.begin() + index, 
                                   mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
        }
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value PolylineNAPI::RemovePoint(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) {
        napi_value null;
        napi_get_null(env, &null);
        return null;
    }
    
    int32_t index = args.GetInt32(0);
    
    if (index >= 0 && static_cast<size_t>(index) < polyline->points.size()) {
        auto removedPoint = polyline->points[index];
        polyline->points.erase(polyline->points.begin() + index);
        
        // Return the removed point
        napi_value result;
        napi_create_object(env, &result);
        
        napi_value lat, lng;
        napi_create_double(env, removedPoint.y, &lat);
        napi_create_double(env, removedPoint.x, &lng);
        
        napi_set_named_property(env, result, "latitude", lat);
        napi_set_named_property(env, result, "longitude", lng);
        
        return result;
    }
    
    napi_value null;
    napi_get_null(env, &null);
    return null;
}

napi_value PolylineNAPI::SetId(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    polyline->annotationId = static_cast<mbgl::AnnotationID>(args.GetInt64(0));
    return thisVar;
}

napi_value PolylineNAPI::SetMapLibreMap(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolylineNAPI* polyline = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polyline));
    
    if (!polyline) return thisVar;
    
    // Clear old reference
    if (polyline->mapLibreMapRef) {
        napi_delete_reference(env, polyline->mapLibreMapRef);
        polyline->mapLibreMapRef = nullptr;
    }
    
    // Create new reference if argument provided
    if (args.Count() > 0) {
        napi_value mapObj = args.Get(0);
        napi_create_reference(env, mapObj, 1, &polyline->mapLibreMapRef);
    }
    
    return thisVar;
}

} // namespace harmony
} // namespace maplibre
