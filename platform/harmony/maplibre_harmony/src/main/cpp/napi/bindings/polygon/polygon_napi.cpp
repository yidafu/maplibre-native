#include "polygon_napi.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include "geometry/lat_lng_harmony.hpp"

namespace maplibre {
namespace harmony {

// Use Logger from mbgl::harmony namespace
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// Static member initialization
napi_ref PolygonNAPI::constructor = nullptr;

PolygonNAPI::PolygonNAPI()
    : annotationId(-1),
      fillColor(mbgl::Color::black()),
      strokeColor(mbgl::Color::black()),
      strokeWidth(1.0f),
      fillAlpha(0.5f),
      strokeAlpha(1.0f),
      visible(true),
      zIndex(0),
      mapLibreMapRef(nullptr) {
}

PolygonNAPI::~PolygonNAPI() {
}

void PolygonNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    PolygonNAPI* polygon = static_cast<PolygonNAPI*>(nativeObject);
    
    // Clear MapLibreMap reference
    if (polygon->mapLibreMapRef) {
        napi_delete_reference(env, polygon->mapLibreMapRef);
        polygon->mapLibreMapRef = nullptr;
    }
    
    delete polygon;
}

napi_value PolygonNAPI::Init(napi_env env, napi_value exports) {
    napi_property_descriptor properties[] = {
        // Getter methods
        { "getPoints", nullptr, GetPoints, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getHoles", nullptr, GetHoles, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillColor", nullptr, GetFillColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getStrokeColor", nullptr, GetStrokeColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getStrokeWidth", nullptr, GetStrokeWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillAlpha", nullptr, GetFillAlpha, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getStrokeAlpha", nullptr, GetStrokeAlpha, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisible", nullptr, GetVisible, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getZIndex", nullptr, GetZIndex, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Setter methods
        { "setPoints", nullptr, SetPoints, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHoles", nullptr, SetHoles, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillColor", nullptr, SetFillColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setStrokeColor", nullptr, SetStrokeColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setStrokeWidth", nullptr, SetStrokeWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillAlpha", nullptr, SetFillAlpha, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setStrokeAlpha", nullptr, SetStrokeAlpha, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setVisible", nullptr, SetVisible, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setZIndex", nullptr, SetZIndex, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Helper methods
        { "addPoint", nullptr, AddPoint, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "insertPoint", nullptr, InsertPoint, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removePoint", nullptr, RemovePoint, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addHole", nullptr, AddHole, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeHole", nullptr, RemoveHole, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setId", nullptr, SetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMapLibreMap", nullptr, SetMapLibreMap, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Polygon", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("PolygonNAPI", "Failed to define Polygon class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("PolygonNAPI", "Failed to create reference to Polygon constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Polygon", cons);
    if (status != napi_ok) {
        Logger::error("PolygonNAPI", "Failed to export Polygon class");
        return nullptr;
    }
    
    return exports;
}

napi_value PolygonNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    // Create PolygonNAPI instance
    PolygonNAPI* polygon = new PolygonNAPI();
    
    // Parse options object if provided
    if (args.Count() > 0) {
        napi_value optionsObj = args.GetObject(0, "options");
        if (args.HasError()) {
            delete polygon;
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
                        polygon->points.push_back(mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
                    }
                }
            }
        }
        
        // Parse holes (optional)
        napi_value holesValue;
        if (napi_get_named_property(env, optionsObj, "holes", &holesValue) == napi_ok) {
            bool isArray = false;
            napi_is_array(env, holesValue, &isArray);
            if (isArray) {
                uint32_t holesLength = 0;
                napi_get_array_length(env, holesValue, &holesLength);
                
                for (uint32_t i = 0; i < holesLength; i++) {
                    napi_value holeValue;
                    napi_get_element(env, holesValue, i, &holeValue);
                    
                    bool isHoleArray = false;
                    napi_is_array(env, holeValue, &isHoleArray);
                    if (isHoleArray) {
                        std::vector<mbgl::Point<double>> hole;
                        uint32_t holeLength = 0;
                        napi_get_array_length(env, holeValue, &holeLength);
                        
                        for (uint32_t j = 0; j < holeLength; j++) {
                            napi_value pointValue;
                            napi_get_element(env, holeValue, j, &pointValue);
                            
                            mbgl::LatLng latLng;
                            if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
                                hole.push_back(mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
                            }
                        }
                        
                        if (!hole.empty()) {
                            polygon->holes.push_back(hole);
                        }
                    }
                }
            }
        }
        
        // Parse fillColor (optional)
        std::string fillColorStr = args.GetStringProperty(optionsObj, "fillColor", "#000000");
        if (!fillColorStr.empty() && fillColorStr[0] == '#') {
            try {
                unsigned int colorValue = std::stoul(fillColorStr.substr(1), nullptr, 16);
                float r = ((colorValue >> 16) & 0xFF) / 255.0f;
                float g = ((colorValue >> 8) & 0xFF) / 255.0f;
                float b = (colorValue & 0xFF) / 255.0f;
                polygon->fillColor = mbgl::Color(r, g, b, 1.0f);
            } catch (...) {
                Logger::error("PolygonNAPI", "Failed to parse fillColor: %s", fillColorStr.c_str());
            }
        }
        
        // Parse strokeColor (optional)
        std::string strokeColorStr = args.GetStringProperty(optionsObj, "strokeColor", "#000000");
        if (!strokeColorStr.empty() && strokeColorStr[0] == '#') {
            try {
                unsigned int colorValue = std::stoul(strokeColorStr.substr(1), nullptr, 16);
                float r = ((colorValue >> 16) & 0xFF) / 255.0f;
                float g = ((colorValue >> 8) & 0xFF) / 255.0f;
                float b = (colorValue & 0xFF) / 255.0f;
                polygon->strokeColor = mbgl::Color(r, g, b, 1.0f);
            } catch (...) {
                Logger::error("PolygonNAPI", "Failed to parse strokeColor: %s", strokeColorStr.c_str());
            }
        }
        
        // Parse strokeWidth (optional)
        polygon->strokeWidth = static_cast<float>(args.GetDoubleProperty(optionsObj, "strokeWidth", 1.0));
        
        // Parse fillAlpha (optional)
        polygon->fillAlpha = static_cast<float>(args.GetDoubleProperty(optionsObj, "fillAlpha", 0.5));
        
        // Parse strokeAlpha (optional)
        polygon->strokeAlpha = static_cast<float>(args.GetDoubleProperty(optionsObj, "strokeAlpha", 1.0));
        
        // Parse visible (optional)
        polygon->visible = args.GetBoolProperty(optionsObj, "visible", true);
        
        // Parse zIndex (optional)
        polygon->zIndex = static_cast<int>(args.GetInt64Property(optionsObj, "zIndex", 0));
    }
    
    // Wrap native object to NAPI object
    napi_status status = napi_wrap(env, thisVar, polygon, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        Logger::error("PolygonNAPI", "Failed to wrap PolygonNAPI instance");
        delete polygon;
        return nullptr;
    }
    
    return thisVar;
}

// Convert to mbgl::FillAnnotation
mbgl::FillAnnotation PolygonNAPI::toAnnotation() const {
    // Create the outer ring (LinearRing)
    mbgl::LinearRing<double> outerRing;
    for (const auto& point : points) {
        outerRing.push_back(point);
    }
    
    // Create the polygon with outer ring
    mbgl::Polygon<double> geometry;
    geometry.push_back(outerRing);
    
    // Add holes (inner rings)
    for (const auto& hole : holes) {
        mbgl::LinearRing<double> innerRing;
        for (const auto& point : hole) {
            innerRing.push_back(point);
        }
        geometry.push_back(innerRing);
    }
    
    mbgl::FillAnnotation annotation(geometry);
    annotation.opacity = fillAlpha;
    annotation.color = fillColor;
    annotation.outlineColor = strokeColor;
    // 注意：FillAnnotation 不支持 outlineWidth，strokeWidth 属性暂时无法在核心层使用
    
    return annotation;
}

// Getter implementations
napi_value PolygonNAPI::GetPoints(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    napi_value result;
    napi_create_array_with_length(env, polygon->points.size(), &result);
    
    for (size_t i = 0; i < polygon->points.size(); i++) {
        napi_value point;
        napi_create_object(env, &point);
        
        napi_value lat, lng;
        napi_create_double(env, polygon->points[i].y, &lat);
        napi_create_double(env, polygon->points[i].x, &lng);
        
        napi_set_named_property(env, point, "latitude", lat);
        napi_set_named_property(env, point, "longitude", lng);
        
        napi_set_element(env, result, i, point);
    }
    
    return result;
}

napi_value PolygonNAPI::GetHoles(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    napi_value result;
    napi_create_array_with_length(env, polygon->holes.size(), &result);
    
    for (size_t i = 0; i < polygon->holes.size(); i++) {
        napi_value hole;
        napi_create_array_with_length(env, polygon->holes[i].size(), &hole);
        
        for (size_t j = 0; j < polygon->holes[i].size(); j++) {
            napi_value point;
            napi_create_object(env, &point);
            
            napi_value lat, lng;
            napi_create_double(env, polygon->holes[i][j].y, &lat);
            napi_create_double(env, polygon->holes[i][j].x, &lng);
            
            napi_set_named_property(env, point, "latitude", lat);
            napi_set_named_property(env, point, "longitude", lng);
            
            napi_set_element(env, hole, j, point);
        }
        
        napi_set_element(env, result, i, hole);
    }
    
    return result;
}

napi_value PolygonNAPI::GetFillColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    // Convert color to hex string
    char colorStr[8];
    snprintf(colorStr, sizeof(colorStr), "#%02X%02X%02X",
             static_cast<int>(polygon->fillColor.r * 255),
             static_cast<int>(polygon->fillColor.g * 255),
             static_cast<int>(polygon->fillColor.b * 255));
    
    napi_value result;
    napi_create_string_utf8(env, colorStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value PolygonNAPI::GetStrokeColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    // Convert color to hex string
    char colorStr[8];
    snprintf(colorStr, sizeof(colorStr), "#%02X%02X%02X",
             static_cast<int>(polygon->strokeColor.r * 255),
             static_cast<int>(polygon->strokeColor.g * 255),
             static_cast<int>(polygon->strokeColor.b * 255));
    
    napi_value result;
    napi_create_string_utf8(env, colorStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value PolygonNAPI::GetStrokeWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    napi_value result;
    napi_create_double(env, polygon->strokeWidth, &result);
    return result;
}

napi_value PolygonNAPI::GetFillAlpha(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    napi_value result;
    napi_create_double(env, polygon->fillAlpha, &result);
    return result;
}

napi_value PolygonNAPI::GetStrokeAlpha(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    napi_value result;
    napi_create_double(env, polygon->strokeAlpha, &result);
    return result;
}

napi_value PolygonNAPI::GetVisible(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    napi_value result;
    napi_get_boolean(env, polygon->visible, &result);
    return result;
}

napi_value PolygonNAPI::GetZIndex(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    napi_value result;
    napi_create_int32(env, polygon->zIndex, &result);
    return result;
}

napi_value PolygonNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    napi_value result;
    napi_create_int64(env, static_cast<int64_t>(polygon->annotationId), &result);
    return result;
}

// Setter implementations
napi_value PolygonNAPI::SetPoints(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    napi_value pointsValue = args.Get(0);
    bool isArray = false;
    napi_is_array(env, pointsValue, &isArray);
    
    if (isArray) {
        polygon->points.clear();
        uint32_t length = 0;
        napi_get_array_length(env, pointsValue, &length);
        
        for (uint32_t i = 0; i < length; i++) {
            napi_value pointValue;
            napi_get_element(env, pointsValue, i, &pointValue);
            
            mbgl::LatLng latLng;
            if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
                polygon->points.push_back(mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
            }
        }
    }
    
    return thisVar;
}

napi_value PolygonNAPI::SetHoles(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    napi_value holesValue = args.Get(0);
    bool isArray = false;
    napi_is_array(env, holesValue, &isArray);
    
    if (isArray) {
        polygon->holes.clear();
        uint32_t holesLength = 0;
        napi_get_array_length(env, holesValue, &holesLength);
        
        for (uint32_t i = 0; i < holesLength; i++) {
            napi_value holeValue;
            napi_get_element(env, holesValue, i, &holeValue);
            
            bool isHoleArray = false;
            napi_is_array(env, holeValue, &isHoleArray);
            if (isHoleArray) {
                std::vector<mbgl::Point<double>> hole;
                uint32_t holeLength = 0;
                napi_get_array_length(env, holeValue, &holeLength);
                
                for (uint32_t j = 0; j < holeLength; j++) {
                    napi_value pointValue;
                    napi_get_element(env, holeValue, j, &pointValue);
                    
                    mbgl::LatLng latLng;
                    if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
                        hole.push_back(mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
                    }
                }
                
                if (!hole.empty()) {
                    polygon->holes.push_back(hole);
                }
            }
        }
    }
    
    return thisVar;
}

napi_value PolygonNAPI::SetFillColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    std::string colorStr = args.GetString(0, "fillColor");
    if (!colorStr.empty() && colorStr[0] == '#') {
        try {
            unsigned int colorValue = std::stoul(colorStr.substr(1), nullptr, 16);
            float r = ((colorValue >> 16) & 0xFF) / 255.0f;
            float g = ((colorValue >> 8) & 0xFF) / 255.0f;
            float b = (colorValue & 0xFF) / 255.0f;
            polygon->fillColor = mbgl::Color(r, g, b, 1.0f);
        } catch (...) {
            Logger::error("PolygonNAPI", "Failed to parse fillColor: %s", colorStr.c_str());
        }
    }
    
    return thisVar;
}

napi_value PolygonNAPI::SetStrokeColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    std::string colorStr = args.GetString(0, "strokeColor");
    if (!colorStr.empty() && colorStr[0] == '#') {
        try {
            unsigned int colorValue = std::stoul(colorStr.substr(1), nullptr, 16);
            float r = ((colorValue >> 16) & 0xFF) / 255.0f;
            float g = ((colorValue >> 8) & 0xFF) / 255.0f;
            float b = (colorValue & 0xFF) / 255.0f;
            polygon->strokeColor = mbgl::Color(r, g, b, 1.0f);
        } catch (...) {
            Logger::error("PolygonNAPI", "Failed to parse strokeColor: %s", colorStr.c_str());
        }
    }
    
    return thisVar;
}

napi_value PolygonNAPI::SetStrokeWidth(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    polygon->strokeWidth = static_cast<float>(args.GetDouble(0));
    return thisVar;
}

napi_value PolygonNAPI::SetFillAlpha(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    polygon->fillAlpha = static_cast<float>(args.GetDouble(0));
    return thisVar;
}

napi_value PolygonNAPI::SetStrokeAlpha(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    polygon->strokeAlpha = static_cast<float>(args.GetDouble(0));
    return thisVar;
}

napi_value PolygonNAPI::SetVisible(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    polygon->visible = args.GetBool(0);
    return thisVar;
}

napi_value PolygonNAPI::SetZIndex(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    polygon->zIndex = args.GetInt32(0);
    return thisVar;
}

// Helper methods
napi_value PolygonNAPI::AddPoint(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value pointValue = args.GetObject(0, "point");
    if (!args.HasError()) {
        mbgl::LatLng latLng;
        if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
            polygon->points.push_back(mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
        }
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value PolygonNAPI::InsertPoint(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    int32_t index = args.GetInt32(0);
    napi_value pointValue = args.GetObject(1, "point");
    
    if (!args.HasError() && index >= 0 && static_cast<size_t>(index) <= polygon->points.size()) {
        mbgl::LatLng latLng;
        if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
            polygon->points.insert(polygon->points.begin() + index, 
                                  mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
        }
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value PolygonNAPI::RemovePoint(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) {
        napi_value null;
        napi_get_null(env, &null);
        return null;
    }
    
    int32_t index = args.GetInt32(0);
    
    if (index >= 0 && static_cast<size_t>(index) < polygon->points.size()) {
        auto removedPoint = polygon->points[index];
        polygon->points.erase(polygon->points.begin() + index);
        
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

napi_value PolygonNAPI::AddHole(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value holeValue = args.Get(0);
    bool isArray = false;
    napi_is_array(env, holeValue, &isArray);
    
    if (isArray) {
        std::vector<mbgl::Point<double>> hole;
        uint32_t length = 0;
        napi_get_array_length(env, holeValue, &length);
        
        for (uint32_t i = 0; i < length; i++) {
            napi_value pointValue;
            napi_get_element(env, holeValue, i, &pointValue);
            
            mbgl::LatLng latLng;
            if (mbgl::harmony::LatLngHarmony::ParseLatLng(env, pointValue, latLng)) {
                hole.push_back(mbgl::Point<double>(latLng.longitude(), latLng.latitude()));
            }
        }
        
        if (!hole.empty()) {
            polygon->holes.push_back(hole);
        }
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value PolygonNAPI::RemoveHole(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) {
        napi_value null;
        napi_get_null(env, &null);
        return null;
    }
    
    int32_t index = args.GetInt32(0);
    
    if (index >= 0 && static_cast<size_t>(index) < polygon->holes.size()) {
        auto removedHole = polygon->holes[index];
        polygon->holes.erase(polygon->holes.begin() + index);
        
        // Return the removed hole as an array of points
        napi_value result;
        napi_create_array_with_length(env, removedHole.size(), &result);
        
        for (size_t i = 0; i < removedHole.size(); i++) {
            napi_value point;
            napi_create_object(env, &point);
            
            napi_value lat, lng;
            napi_create_double(env, removedHole[i].y, &lat);
            napi_create_double(env, removedHole[i].x, &lng);
            
            napi_set_named_property(env, point, "latitude", lat);
            napi_set_named_property(env, point, "longitude", lng);
            
            napi_set_element(env, result, i, point);
        }
        
        return result;
    }
    
    napi_value null;
    napi_get_null(env, &null);
    return null;
}

napi_value PolygonNAPI::SetId(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    polygon->annotationId = static_cast<mbgl::AnnotationID>(args.GetInt64(0));
    return thisVar;
}

napi_value PolygonNAPI::SetMapLibreMap(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return thisVar;
    
    // Clear old reference
    if (polygon->mapLibreMapRef) {
        napi_delete_reference(env, polygon->mapLibreMapRef);
        polygon->mapLibreMapRef = nullptr;
    }
    
    // Create new reference if argument provided
    if (args.Count() > 0) {
        napi_value mapObj = args.Get(0);
        napi_create_reference(env, mapObj, 1, &polygon->mapLibreMapRef);
    }
    
    return thisVar;
}

} // namespace harmony
} // namespace maplibre

