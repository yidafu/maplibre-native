#include "marker/marker_napi.hpp"
#include "../../utils/logger.h"
#include "../../napi/core/napi_args.hpp"

namespace maplibre {
namespace harmony {

// Use Logger from mbgl::harmony namespace
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// Static member initialization
napi_ref MarkerNAPI::constructor = nullptr;

MarkerNAPI::MarkerNAPI()
    : annotationId(-1),
      position(0.0, 0.0),
      iconId(""),
      title(""),
      snippet(""),
      visible(true),
      alpha(1.0),
      rotation(0.0),
      draggable(false),
      zIndex(0),
      infoWindowShown(false),
      selected(false),
      dragState(0),
      mapLibreMapRef(nullptr),
      anchorU(0.5),  // 默认底部中心
      anchorV(1.0) {
    Logger::debug("MarkerNAPI", "MarkerNAPI instance created");
}

MarkerNAPI::~MarkerNAPI() {
    Logger::debug("MarkerNAPI", "MarkerNAPI instance destroyed, ID=%lld", annotationId);
}

void MarkerNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    Logger::debug("MarkerNAPI", "Destructor called");
    MarkerNAPI* marker = static_cast<MarkerNAPI*>(nativeObject);
    delete marker;
}

napi_value MarkerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("MarkerNAPI", "Initializing Marker NAPI class");
    
    napi_property_descriptor properties[] = {
        // Getter methods
        { "getPosition", nullptr, GetPosition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIcon", nullptr, GetIcon, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTitle", nullptr, GetTitle, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSnippet", nullptr, GetSnippet, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisible", nullptr, GetVisible, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getAlpha", nullptr, GetAlpha, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getRotation", nullptr, GetRotation, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getDraggable", nullptr, GetDraggable, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getZIndex", nullptr, GetZIndex, nullptr, nullptr, nullptr, napi_default, nullptr },
        
    
    marker->visible = args.GetBool(0, "visible");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetAlpha(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->alpha = args.GetDouble(0, "alpha");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetRotation(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->rotation = args.GetDouble(0, "rotation");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetDraggable(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->draggable = args.GetBool(0, "draggable");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetZIndex(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->zIndex = args.GetInt32(0, "zIndex");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::Remove(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) {
        Logger::error("MarkerNAPI", "Remove: Failed to unwrap marker");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 重置 annotation ID（标记为已移除）
    // 实际的移除操作由 MapLibreMap.removeMarker() 调用 removeAnnotations() 完成
    Logger::info("MarkerNAPI", "[MarkerDebug] Marker.remove() called for ID=%ld", marker->annotationId);
    marker->annotationId = -1;
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetId(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->annotationId = static_cast<mbgl::AnnotationID>(args.GetInt64(0, "id"));
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetMapLibreMap(napi_env env, napi_callback_info info) {
    // 占位实现 - 暂时不需要保存 MapLibreMap 引用
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// InfoWindow methods
napi_value MarkerNAPI::ShowInfoWindow(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->infoWindowShown = true;
    Logger::debug("MarkerNAPI", "showInfoWindow called for marker ID=%ld", marker->annotationId);
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::HideInfoWindow(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->infoWindowShown = false;
    Logger::debug("MarkerNAPI", "hideInfoWindow called for marker ID=%ld", marker->annotationId);
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::IsInfoWindowShown(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_get_boolean(env, marker->infoWindowShown, &result);
    return result;
}

// Selection methods
napi_value MarkerNAPI::IsSelected(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_get_boolean(env, marker->selected, &result);
    return result;
}

napi_value MarkerNAPI::SetSelected(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->selected = args.GetBool(0, "selected");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// Drag state methods
napi_value MarkerNAPI::GetDragState(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_create_int32(env, marker->dragState, &result);
    return result;
}

napi_value MarkerNAPI::SetDragState(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->dragState = args.GetInt32(0, "dragState");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// Animation methods - 在 ETS 层实现动画逻辑，这里只更新目标值
napi_value MarkerNAPI::AnimateToPosition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    // 解析目标位置
    napi_value targetPosValue = args.GetObject(0, "targetPosition");
    if (!args.HasError()) {
        double lat = args.GetDoubleProperty(targetPosValue, "latitude", 0.0);
        double lon = args.GetDoubleProperty(targetPosValue, "longitude", 0.0);
        marker->position = mbgl::Point<double>(lon, lat);
        
        Logger::info("MarkerNAPI", "[Animation] animateToPosition: target=(%f, %f)", lat, lon);
    }
    
    // duration 和 callback 由 ETS 层处理
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::AnimateAlpha(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->alpha = args.GetDouble(0, "targetAlpha");
    Logger::info("MarkerNAPI", "[Animation] animateAlpha: target=%f", marker->alpha);
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::AnimateRotation(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->rotation = args.GetDouble(0, "targetRotation");
    Logger::info("MarkerNAPI", "[Animation] animateRotation: target=%f", marker->rotation);
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// Anchor methods
napi_value MarkerNAPI::GetAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    // 创建 anchor 对象 { u: number, v: number }
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value u, v;
    napi_create_double(env, marker->anchorU, &u);
    napi_create_double(env, marker->anchorV, &v);
    
    napi_set_named_property(env, result, "u", u);
    napi_set_named_property(env, result, "v", v);
    
    return result;
}

napi_value MarkerNAPI::SetAnchor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->anchorU = args.GetDouble(0, "u");
    marker->anchorV = args.GetDouble(1, "v");
    Logger::debug("MarkerNAPI", "setAnchor: u=%f, v=%f", marker->anchorU, marker->anchorV);
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

} // namespace harmony
} // namespace maplibre

