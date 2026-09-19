#include "polyline_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "utils/logger.h"
#include "napi/bindings/annotation_napi_accessors.hpp"
#include "geometry/lat_lng_harmony.hpp"
#include "napi/bindings/annotation_napi_common.hpp"

namespace mln {
namespace harmony {

// Use Logger from mln::harmony namespace
using mln::harmony::Logger;
using mln::harmony::napi::NapiArgs;
using mln::harmony::annotation_napi::JsBool;
using mln::harmony::annotation_napi::JsHexColor;
using mln::harmony::annotation_napi::JsInt32;
using mln::harmony::annotation_napi::JsInt64;
using mln::harmony::annotation_napi::JsNumber;
using mln::harmony::annotation_napi::JsString;

// Static member initialization
napi_ref PolylineNAPI::constructor = nullptr;
napi_env PolylineNAPI::constructorEnv = nullptr;

PolylineNAPI::PolylineNAPI()
    : annotationId(-1),
      color(mln::Color::black()),
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
    
    napi_value cons = RegisterNapiClass(env, exports, "Polyline", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "PolylineNAPI");
    return cons ? exports : nullptr;
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
            polyline->points = ParseLatLngArrayToPoints(env, pointsValue);
        }
        
        // Parse color (optional)
        std::string colorStr = args.GetStringProperty(optionsObj, "color", "#000000");
        if (!colorStr.empty() && colorStr[0] == '#') {
            if (!ParseHexColor(colorStr, polyline->color)) {
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
    
    // Wrap native object to NAPI object
    napi_status status = napi_wrap(env, thisVar, polyline, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        Logger::error("PolylineNAPI", "Failed to wrap PolylineNAPI instance");
        delete polyline;
        return nullptr;
    }
    
    return thisVar;
}

// Convert to mln::LineAnnotation
mln::LineAnnotation PolylineNAPI::toAnnotation() const {
    mln::LineString<double> lineString;
    for (const auto& point : points) {
        lineString.push_back(point);
    }
    
    mln::LineAnnotation annotation(lineString);
    annotation.opacity = alpha;
    annotation.color = color;
    annotation.width = width;
    
    return annotation;
}

// ============================================================================
// 访问器实现
//
// 通用骨架（this 解包 / 空检查 / 返回语义）见 annotation_napi_accessors.hpp；
// 这里只保留每个属性「取哪个成员、走哪条转换路径」的差异。
// ============================================================================

// ----- 读访问器 -----

DEFINE_ANNOTATION_GETTER(PolylineNAPI, GetPoints, PointArrayToJs(env, self->points))
DEFINE_ANNOTATION_GETTER(PolylineNAPI, GetColor, JsHexColor(env, self->color))
DEFINE_ANNOTATION_GETTER(PolylineNAPI, GetWidth, JsNumber(env, self->width))
DEFINE_ANNOTATION_GETTER(PolylineNAPI, GetAlpha, JsNumber(env, self->alpha))
DEFINE_ANNOTATION_GETTER(PolylineNAPI, GetVisible, JsBool(env, self->visible))
DEFINE_ANNOTATION_GETTER(PolylineNAPI, GetZIndex, JsInt32(env, self->zIndex))
DEFINE_ANNOTATION_GETTER(PolylineNAPI, GetJointType, JsString(env, self->jointType))
DEFINE_ANNOTATION_GETTER(PolylineNAPI, GetCapType, JsString(env, self->capType))
DEFINE_ANNOTATION_GETTER(PolylineNAPI, GetId, JsInt64(env, static_cast<int64_t>(self->annotationId)))

// getPattern 在空样式时返回 null（而非空数组），保留显式实现。
napi_value PolylineNAPI::GetPattern(napi_env env, napi_callback_info info) {
    ANN_NAPI_THIS(PolylineNAPI, self);
    if (!self || self->pattern.empty()) {
        return mln::harmony::annotation_napi::JsNull(env);
    }

    napi_value result = nullptr;
    napi_create_array_with_length(env, self->pattern.size(), &result);

    for (size_t i = 0; i < self->pattern.size(); i++) {
        napi_set_element(env, result, static_cast<uint32_t>(i),
                         JsNumber(env, self->pattern[i]));
    }

    return result;
}

// ----- 写访问器 -----

DEFINE_ANNOTATION_POINTS_SETTER(PolylineNAPI, SetPoints, points)
DEFINE_ANNOTATION_COLOR_SETTER(PolylineNAPI, SetColor, color, "color")

DEFINE_ANNOTATION_SETTER(PolylineNAPI, SetWidth,
    args.RequireMinArgs(1);
    self->width = static_cast<float>(args.GetDouble(0)))

DEFINE_ANNOTATION_SETTER(PolylineNAPI, SetAlpha,
    args.RequireMinArgs(1);
    self->alpha = static_cast<float>(args.GetDouble(0)))

DEFINE_ANNOTATION_SETTER(PolylineNAPI, SetVisible,
    args.RequireMinArgs(1);
    self->visible = args.GetBool(0))

DEFINE_ANNOTATION_SETTER(PolylineNAPI, SetZIndex,
    args.RequireMinArgs(1);
    self->zIndex = args.GetInt32(0))

DEFINE_ANNOTATION_SETTER(PolylineNAPI, SetJointType,
    args.RequireMinArgs(1);
    self->jointType = args.GetString(0, "jointType"))

DEFINE_ANNOTATION_SETTER(PolylineNAPI, SetCapType,
    args.RequireMinArgs(1);
    self->capType = args.GetString(0, "capType"))

DEFINE_ANNOTATION_SETTER(PolylineNAPI, SetId,
    args.RequireMinArgs(1);
    self->annotationId = static_cast<mln::AnnotationID>(args.GetInt64(0)))

// setPattern：无参 / null / undefined 视为清空；数组则整体替换。
// 元素通过 args.GetArrayElementDouble 读取——取元素失败时回退 0.0，
// 不再直接读未初始化的 double（原实现存在该未定义行为）。
DEFINE_ANNOTATION_SETTER(PolylineNAPI, SetPattern,
    napi_valuetype patternType = napi_undefined;
    if (args.Count() > 0 && napi_typeof(env, args.Get(0), &patternType) != napi_ok) {
        patternType = napi_undefined;
    }

    if (args.Count() == 0 || patternType == napi_null || patternType == napi_undefined) {
        self->pattern.clear();
    } else {
        napi_value patternValue = args.Get(0);
        bool isArray = false;
        napi_is_array(env, patternValue, &isArray);
        if (isArray) {
            self->pattern.clear();
            const uint32_t length = args.GetArrayLength(patternValue);
            for (uint32_t i = 0; i < length; i++) {
                self->pattern.push_back(
                    static_cast<float>(args.GetArrayElementDouble(patternValue, i, 0.0)));
            }
        }
    })

DEFINE_ANNOTATION_MAP_REF_SETTER(PolylineNAPI, SetMapLibreMap)

// addPoint / insertPoint / removePoint 与 Polygon 完全同构，直接用共享宏。
DEFINE_ANNOTATION_ADD_POINT(PolylineNAPI, points)
DEFINE_ANNOTATION_INSERT_POINT(PolylineNAPI, points)
DEFINE_ANNOTATION_REMOVE_POINT(PolylineNAPI, points)

} // namespace harmony
} // namespace mln
