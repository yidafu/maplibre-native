#include "polygon_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "utils/logger.h"
#include "napi/bindings/annotation_napi_accessors.hpp"
#include "geometry/lat_lng_harmony.hpp"
#include "napi/bindings/annotation_napi_common.hpp"

namespace mbgl {
namespace harmony {

// Use Logger from mbgl::harmony namespace
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using mbgl::harmony::annotation_napi::JsBool;
using mbgl::harmony::annotation_napi::JsHexColor;
using mbgl::harmony::annotation_napi::JsInt32;
using mbgl::harmony::annotation_napi::JsInt64;
using mbgl::harmony::annotation_napi::JsNumber;
using mbgl::harmony::annotation_napi::JsString;

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

// ============================================================================
// 访问器实现
//
// 通用骨架（this 解包 / 空检查 / 返回语义）见 annotation_napi_accessors.hpp；
// 这里只保留每个属性「取哪个成员、走哪条转换路径」的差异。
// ============================================================================

// ----- 读访问器 -----

DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetPoints, PointArrayToJs(env, self->points))
DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetFillColor, JsHexColor(env, self->fillColor))
DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetStrokeColor, JsHexColor(env, self->strokeColor))
DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetStrokeWidth, JsNumber(env, self->strokeWidth))
DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetFillAlpha, JsNumber(env, self->fillAlpha))
DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetStrokeAlpha, JsNumber(env, self->strokeAlpha))
DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetVisible, JsBool(env, self->visible))
DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetZIndex, JsInt32(env, self->zIndex))
DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetId, JsInt64(env, static_cast<int64_t>(self->annotationId)))

// getHoles 暴露的是「洞数组的数组」，没有普适的标量形态，保留手写实现。
napi_value PolygonNAPI::GetHoles(napi_env env, napi_callback_info info) {
    ANN_NAPI_THIS(PolygonNAPI, self);
    if (!self) return nullptr;

    napi_value result = nullptr;
    napi_create_array_with_length(env, self->holes.size(), &result);

    for (size_t i = 0; i < self->holes.size(); i++) {
        napi_set_element(env, result, static_cast<uint32_t>(i),
                         PointArrayToJs(env, self->holes[i]));
    }

    return result;
}

// ----- 写访问器 -----

DEFINE_ANNOTATION_POINTS_SETTER(PolygonNAPI, SetPoints, points)

DEFINE_ANNOTATION_COLOR_SETTER(PolygonNAPI, SetFillColor, fillColor, "fillColor")
DEFINE_ANNOTATION_COLOR_SETTER(PolygonNAPI, SetStrokeColor, strokeColor, "strokeColor")

DEFINE_ANNOTATION_SETTER(PolygonNAPI, SetStrokeWidth,
    args.RequireMinArgs(1);
    self->strokeWidth = static_cast<float>(args.GetDouble(0)))

DEFINE_ANNOTATION_SETTER(PolygonNAPI, SetFillAlpha,
    args.RequireMinArgs(1);
    self->fillAlpha = static_cast<float>(args.GetDouble(0)))

DEFINE_ANNOTATION_SETTER(PolygonNAPI, SetStrokeAlpha,
    args.RequireMinArgs(1);
    self->strokeAlpha = static_cast<float>(args.GetDouble(0)))

DEFINE_ANNOTATION_SETTER(PolygonNAPI, SetVisible,
    args.RequireMinArgs(1);
    self->visible = args.GetBool(0))

DEFINE_ANNOTATION_SETTER(PolygonNAPI, SetZIndex,
    args.RequireMinArgs(1);
    self->zIndex = args.GetInt32(0))

DEFINE_ANNOTATION_SETTER(PolygonNAPI, SetId,
    args.RequireMinArgs(1);
    self->annotationId = static_cast<mbgl::AnnotationID>(args.GetInt64(0)))

DEFINE_ANNOTATION_MAP_REF_SETTER(PolygonNAPI, SetMapLibreMap)

// setHoles：整体替换洞集合，非数组入参静默忽略（与既有行为一致）。
DEFINE_ANNOTATION_SETTER(PolygonNAPI, SetHoles,
    args.RequireMinArgs(1);
    napi_value holesValue = args.Get(0);
    bool isArray = false;
    napi_is_array(env, holesValue, &isArray);
    if (isArray) {
        self->holes.clear();
        const uint32_t holesLength = args.GetArrayLength(holesValue);
        for (uint32_t i = 0; i < holesLength; i++) {
            napi_value holeValue = nullptr;
            if (napi_get_element(env, holesValue, i, &holeValue) != napi_ok) {
                continue;
            }
            std::vector<mbgl::Point<double>> hole = ParseLatLngArrayToPoints(env, holeValue);
            if (!hole.empty()) {
                self->holes.push_back(std::move(hole));
            }
        }
    })

// addPoint / insertPoint / removePoint 在两份注解实现里完全同构，直接用共享宏。
DEFINE_ANNOTATION_ADD_POINT(PolygonNAPI, points)
DEFINE_ANNOTATION_INSERT_POINT(PolygonNAPI, points)
DEFINE_ANNOTATION_REMOVE_POINT(PolygonNAPI, points)

// ----- 洞的增删 -----
// addHole 返回 undefined、removeHole 命中返回被删洞 / 未命中返回 null，
// 返回语义与 setter 骨架不同，故保留显式实现。

napi_value PolygonNAPI::AddHole(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    ANN_NAPI_THIS(PolygonNAPI, self);
    if (!self) {
        return mbgl::harmony::annotation_napi::JsUndefined(env);
    }

    napi_value holeValue = args.Get(0);
    bool isArray = false;
    napi_is_array(env, holeValue, &isArray);

    if (isArray) {
        std::vector<mbgl::Point<double>> hole = ParseLatLngArrayToPoints(env, holeValue);
        if (!hole.empty()) {
            self->holes.push_back(std::move(hole));
        }
    }

    return mbgl::harmony::annotation_napi::JsUndefined(env);
}

napi_value PolygonNAPI::RemoveHole(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    ANN_NAPI_THIS(PolygonNAPI, self);
    if (!self) {
        return mbgl::harmony::annotation_napi::JsNull(env);
    }

    const int32_t index = args.GetInt32(0);

    if (index >= 0 && static_cast<size_t>(index) < self->holes.size()) {
        // 先按值拷出被删的洞，再 erase，避免迭代器/索引失效
        const auto removedHole = self->holes[index];
        self->holes.erase(self->holes.begin() + index);
        return PointArrayToJs(env, removedHole);
    }

    return mbgl::harmony::annotation_napi::JsNull(env);
}

} // namespace harmony
} // namespace mbgl
