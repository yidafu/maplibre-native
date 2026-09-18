#include "polygon_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include "geometry/lat_lng_harmony.hpp"
#include "napi/bindings/annotation_napi_common.hpp"

namespace mbgl {
namespace harmony {

// Use Logger from mbgl::harmony namespace
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// Static member initialization
napi_ref PolygonNAPI::constructor = nullptr;
napi_env PolygonNAPI::constructorEnv = nullptr;

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
    
    napi_value cons = RegisterNapiClass(env, exports, "Polygon", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "PolygonNAPI");
    return cons ? exports : nullptr;
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
            polygon->points = ParseLatLngArrayToPoints(env, pointsValue);
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
                    
                    std::vector<mbgl::Point<double>> hole = ParseLatLngArrayToPoints(env, holeValue);
                    if (!hole.empty()) {
                        polygon->holes.push_back(std::move(hole));
                    }
                }
            }
        }
        
        // Parse fillColor (optional)
        std::string fillColorStr = args.GetStringProperty(optionsObj, "fillColor", "#000000");
        if (!fillColorStr.empty() && fillColorStr[0] == '#') {
            if (!ParseHexColor(fillColorStr, polygon->fillColor)) {
                Logger::error("PolygonNAPI", "Failed to parse fillColor: %s", fillColorStr.c_str());
            }
        }
        
        // Parse strokeColor (optional)
        std::string strokeColorStr = args.GetStringProperty(optionsObj, "strokeColor", "#000000");
        if (!strokeColorStr.empty() && strokeColorStr[0] == '#') {
            if (!ParseHexColor(strokeColorStr, polygon->strokeColor)) {
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
    // Note: FillAnnotation does not support outlineWidth; strokeWidth is currently unavailable in core
    
    return annotation;
}

// Getter implementations
napi_value PolygonNAPI::GetPoints(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    return PointArrayToJs(env, polygon->points);
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
        napi_set_element(env, result, static_cast<uint32_t>(i), PointArrayToJs(env, polygon->holes[i]));
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
    const std::string colorStr = ColorToHex(polygon->fillColor);
    
    napi_value result;
    napi_create_string_utf8(env, colorStr.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value PolygonNAPI::GetStrokeColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    PolygonNAPI* polygon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&polygon));
    
    if (!polygon) return nullptr;
    
    // Convert color to hex string
    const std::string colorStr = ColorToHex(polygon->strokeColor);
    
    napi_value result;
    napi_create_string_utf8(env, colorStr.c_str(), NAPI_AUTO_LENGTH, &result);
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
        polygon->points = ParseLatLngArrayToPoints(env, pointsValue);
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
            
            std::vector<mbgl::Point<double>> hole = ParseLatLngArrayToPoints(env, holeValue);
            if (!hole.empty()) {
                polygon->holes.push_back(std::move(hole));
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
        if (!ParseHexColor(colorStr, polygon->fillColor)) {
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
        if (!ParseHexColor(colorStr, polygon->strokeColor)) {
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
        mbgl::Point<double> point;
        if (ParseLatLngToPoint(env, pointValue, point)) {
            polygon->points.push_back(point);
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
        mbgl::Point<double> point;
        if (ParseLatLngToPoint(env, pointValue, point)) {
            polygon->points.insert(polygon->points.begin() + index, point);
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
        return LatLngHarmony::CreateLatLngObject(env, mbgl::LatLng(removedPoint.y, removedPoint.x));
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
        std::vector<mbgl::Point<double>> hole = ParseLatLngArrayToPoints(env, holeValue);
        if (!hole.empty()) {
            polygon->holes.push_back(std::move(hole));
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
        return PointArrayToJs(env, removedHole);
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
} // namespace mbgl

