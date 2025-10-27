#include "marker_napi.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include "geometry/lat_lng_harmony.hpp"

namespace maplibre {
namespace harmony {

// Use Logger from mbgl::harmony namespace
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// Note: Static member initialization, Constructor, Destructor, and Init function are defined in marker_napi_base.cpp

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
    
    Logger::info("MarkerNAPI", "[MarkerDebug] Marker.remove() called for ID=%ld", marker->annotationId);
    
    // 如果 Marker 已关联 MapLibreMap，调用其 removeMarker 方法
    if (marker->mapLibreMapRef) {
        napi_value mapLibreMapValue;
        napi_status status = napi_get_reference_value(env, marker->mapLibreMapRef, &mapLibreMapValue);
        
        if (status == napi_ok && mapLibreMapValue != nullptr) {
            // 获取 removeMarker 方法
            napi_value removeMarkerFunc;
            status = napi_get_named_property(env, mapLibreMapValue, "removeMarker", &removeMarkerFunc);
            
            if (status == napi_ok) {
                // 调用 mapLibreMap.removeMarker(this)
                napi_value argv[] = { thisVar };
                napi_value result;
                napi_call_function(env, mapLibreMapValue, removeMarkerFunc, 1, argv, &result);
                Logger::debug("MarkerNAPI", "Marker.remove() called mapLibreMap.removeMarker()");
            } else {
                Logger::warn("MarkerNAPI", "Remove: removeMarker method not found on MapLibreMap");
                // 如果方法不存在，至少重置 ID
                marker->annotationId = -1;
            }
        } else {
            Logger::warn("MarkerNAPI", "Remove: MapLibreMap reference is invalid");
            marker->annotationId = -1;
        }
    } else {
        Logger::warn("MarkerNAPI", "Remove: Marker not associated with MapLibreMap");
        marker->annotationId = -1;
    }
    
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
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) {
        Logger::error("MarkerNAPI", "SetMapLibreMap: Failed to unwrap marker");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取 MapLibreMap 对象
    napi_value mapLibreMapValue = args.GetObject(0, "mapLibreMap");
    if (args.HasError()) {
        Logger::error("MarkerNAPI", "SetMapLibreMap: Failed to get mapLibreMap argument");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 删除旧的引用（如果存在）
    if (marker->mapLibreMapRef) {
        napi_delete_reference(env, marker->mapLibreMapRef);
        marker->mapLibreMapRef = nullptr;
    }
    
    // 创建新的引用
    napi_status status = napi_create_reference(env, mapLibreMapValue, 1, &marker->mapLibreMapRef);
    if (status != napi_ok) {
        Logger::error("MarkerNAPI", "SetMapLibreMap: Failed to create reference");
    } else {
        Logger::debug("MarkerNAPI", "SetMapLibreMap: Successfully set MapLibreMap reference for marker ID=%ld", marker->annotationId);
    }
    
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
        mbgl::LatLng latLng;
        if (mbgl::harmony::LatLngNapi::ParseLatLng(env, targetPosValue, latLng)) {
            marker->position = mbgl::Point<double>(latLng.longitude(), latLng.latitude());
            Logger::info("MarkerNAPI", "[Animation] animateToPosition: target=(%f, %f)", latLng.latitude(), latLng.longitude());
        } else {
            Logger::error("MarkerNAPI", "AnimateToPosition: Failed to parse target LatLng");
        }
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
    
    // 获取目标透明度
    double targetAlpha = args.GetDouble(0, "targetAlpha");
    
    // duration 和 callback 参数被忽略
    // 动画逻辑应该在 ETS 层实现（使用 animateTo 或定时器）
    // NAPI 层只负责设置最终值
    
    marker->alpha = targetAlpha;
    Logger::info("MarkerNAPI", "[Animation] animateAlpha: set target=%f (animation should be handled in ETS layer)", 
                 marker->alpha);
    
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

