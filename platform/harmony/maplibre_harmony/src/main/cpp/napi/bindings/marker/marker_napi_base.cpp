#include "marker_napi.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include "geometry/lat_lng_harmony.hpp"

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
      iconRef(nullptr),
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
    
    // 清理 Icon 引用
    if (marker->iconRef) {
        napi_delete_reference(env, marker->iconRef);
        marker->iconRef = nullptr;
        Logger::debug("MarkerNAPI", "Cleaned up Icon reference in destructor");
    }
    
    // 清理 MapLibreMap 引用
    if (marker->mapLibreMapRef) {
        napi_delete_reference(env, marker->mapLibreMapRef);
        marker->mapLibreMapRef = nullptr;
        Logger::debug("MarkerNAPI", "Cleaned up MapLibreMap reference in destructor");
    }
    
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
        
        // Setter methods
        { "setPosition", nullptr, SetPosition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIcon", nullptr, SetIcon, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTitle", nullptr, SetTitle, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSnippet", nullptr, SetSnippet, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setVisible", nullptr, SetVisible, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setAlpha", nullptr, SetAlpha, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setRotation", nullptr, SetRotation, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setDraggable", nullptr, SetDraggable, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setZIndex", nullptr, SetZIndex, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // InfoWindow methods
        { "showInfoWindow", nullptr, ShowInfoWindow, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "hideInfoWindow", nullptr, HideInfoWindow, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isInfoWindowShown", nullptr, IsInfoWindowShown, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Selection methods
        { "isSelected", nullptr, IsSelected, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSelected", nullptr, SetSelected, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Drag state methods
        { "getDragState", nullptr, GetDragState, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setDragState", nullptr, SetDragState, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Animation methods
        { "animateToPosition", nullptr, AnimateToPosition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "animateAlpha", nullptr, AnimateAlpha, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "animateRotation", nullptr, AnimateRotation, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Anchor methods
        { "getAnchor", nullptr, GetAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setAnchor", nullptr, SetAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Helper methods
        { "remove", nullptr, Remove, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setId", nullptr, SetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMapLibreMap", nullptr, SetMapLibreMap, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Marker", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("MarkerNAPI", "Failed to define Marker class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("MarkerNAPI", "Failed to create reference to Marker constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Marker", cons);
    if (status != napi_ok) {
        Logger::error("MarkerNAPI", "Failed to export Marker class");
        return nullptr;
    }
    
    Logger::info("MarkerNAPI", "Marker NAPI class registered successfully");
    return exports;
}

napi_value MarkerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    // Create MarkerNAPI instance
    MarkerNAPI* marker = new MarkerNAPI();
    
    // Parse options object if provided
    if (args.Count() > 0) {
        napi_value optionsObj = args.GetObject(0, "options");
        if (args.HasError()) {
            delete marker;
            return nullptr;
        }
        
        // Parse position (required)
        napi_value posValue;
        if (napi_get_named_property(env, optionsObj, "position", &posValue) == napi_ok) {
            mbgl::LatLng latLng;
            if (mbgl::harmony::LatLngNapi::ParseLatLng(env, posValue, latLng)) {
                // LatLng解析成功，转换为Point (注意: Point是(x, y) = (lon, lat))
                marker->position = mbgl::Point<double>(latLng.longitude(), latLng.latitude());
            } else {
                Logger::error("MarkerNAPI", "[MarkerDebug] Failed to parse position from options");
            }
        }
        
        // Parse icon (optional)
        marker->iconId = args.GetStringProperty(optionsObj, "icon", "");
        
        // Parse title (optional)
        marker->title = args.GetStringProperty(optionsObj, "title", "");
        
        // Parse snippet (optional)
        marker->snippet = args.GetStringProperty(optionsObj, "snippet", "");
        
        // Parse visible (optional)
        marker->visible = args.GetBoolProperty(optionsObj, "visible", true);
        
        // Parse alpha (optional)
        marker->alpha = args.GetDoubleProperty(optionsObj, "alpha", 1.0);
        
        // Parse rotation (optional)
        marker->rotation = args.GetDoubleProperty(optionsObj, "rotation", 0.0);
        
        // Parse draggable (optional)
        marker->draggable = args.GetBoolProperty(optionsObj, "draggable", false);
        
        // Parse zIndex (optional)
        marker->zIndex = static_cast<int>(args.GetInt64Property(optionsObj, "zIndex", 0));
        
        // Parse anchor (optional)
        napi_value anchorValue;
        if (napi_get_named_property(env, optionsObj, "anchor", &anchorValue) == napi_ok) {
            marker->anchorU = args.GetDoubleProperty(anchorValue, "u", 0.5);
            marker->anchorV = args.GetDoubleProperty(anchorValue, "v", 1.0);
        }
    }
    
    Logger::info("MarkerNAPI", "[MarkerDebug] NAPI-Create: Marker created at position=(%f, %f), icon=\"%s\", visible=%d, alpha=%f",
                 marker->position.y, marker->position.x, 
                 marker->iconId.empty() ? "(empty)" : marker->iconId.c_str(),
                 marker->visible, marker->alpha);
    
    // Wrap native object to NAPI object
    napi_status status = napi_wrap(env, thisVar, marker, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        Logger::error("MarkerNAPI", "Failed to wrap MarkerNAPI instance");
        delete marker;
        return nullptr;
    }
    
    return thisVar;
}

// Getter implementations
napi_value MarkerNAPI::GetPosition(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) {
        Logger::error("MarkerNAPI", "Failed to unwrap marker in GetPosition");
        return nullptr;
    }
    
    // Create LatLng object
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value lat, lng;
    napi_create_double(env, marker->position.y, &lat);
    napi_create_double(env, marker->position.x, &lng);
    
    napi_set_named_property(env, result, "latitude", lat);
    napi_set_named_property(env, result, "longitude", lng);
    
    return result;
}

napi_value MarkerNAPI::GetIcon(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    if (marker->iconId.empty()) {
        napi_value null;
        napi_get_null(env, &null);
        return null;
    }
    
    napi_value result;
    napi_create_string_utf8(env, marker->iconId.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value MarkerNAPI::GetTitle(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_create_string_utf8(env, marker->title.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value MarkerNAPI::GetSnippet(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_create_string_utf8(env, marker->snippet.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value MarkerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_create_int64(env, static_cast<int64_t>(marker->annotationId), &result);
    return result;
}

napi_value MarkerNAPI::GetVisible(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_get_boolean(env, marker->visible, &result);
    return result;
}

napi_value MarkerNAPI::GetAlpha(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_create_double(env, marker->alpha, &result);
    return result;
}

napi_value MarkerNAPI::GetRotation(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_create_double(env, marker->rotation, &result);
    return result;
}

napi_value MarkerNAPI::GetDraggable(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_get_boolean(env, marker->draggable, &result);
    return result;
}

napi_value MarkerNAPI::GetZIndex(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    napi_value result;
    napi_create_int32(env, marker->zIndex, &result);
    return result;
}

// Setter implementations
napi_value MarkerNAPI::SetPosition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    // Parse LatLng object
    napi_value posValue = args.GetObject(0, "position");
    if (!args.HasError()) {
        mbgl::LatLng latLng;
        if (mbgl::harmony::LatLngNapi::ParseLatLng(env, posValue, latLng)) {
            marker->position = mbgl::Point<double>(latLng.longitude(), latLng.latitude());
        } else {
            Logger::error("MarkerNAPI", "SetPosition: Failed to parse LatLng");
        }
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetIcon(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    // Check argument type: string ID or Icon object
    napi_valuetype type;
    napi_value iconArg = args.Get(0);
    napi_typeof(env, iconArg, &type);
    
    // Clear old icon reference if exists
    if (marker->iconRef) {
        napi_delete_reference(env, marker->iconRef);
        marker->iconRef = nullptr;
    }
    
    if (type == napi_string) {
        // Backward compatibility: string icon ID
        marker->iconId = args.GetStringOr(0, "");
        Logger::debug("MarkerNAPI", "SetIcon: using string ID '%s'", marker->iconId.c_str());
    } else if (type == napi_object) {
        // New way: Icon object
        // Import IconNAPI to check if it's an Icon object
        // We'll use a simple check by trying to get the getId method
        napi_value getIdFunc;
        napi_status status = napi_get_named_property(env, iconArg, "getId", &getIdFunc);
        
        if (status == napi_ok) {
            // Call getId() to get the icon ID
            napi_value idValue;
            status = napi_call_function(env, iconArg, getIdFunc, 0, nullptr, &idValue);
            
            if (status == napi_ok) {
                size_t length;
                napi_get_value_string_utf8(env, idValue, nullptr, 0, &length);
                marker->iconId.resize(length);
                napi_get_value_string_utf8(env, idValue, &marker->iconId[0], length + 1, &length);
                
                // Keep a reference to the Icon object
                status = napi_create_reference(env, iconArg, 1, &marker->iconRef);
                if (status != napi_ok) {
                    Logger::error("MarkerNAPI", "SetIcon: Failed to create Icon reference");
                } else {
                    Logger::debug("MarkerNAPI", "SetIcon: using Icon object with ID '%s'", marker->iconId.c_str());
                }
            }
        }
    } else if (type == napi_null || type == napi_undefined) {
        // Clear icon
        marker->iconId = "";
        Logger::debug("MarkerNAPI", "SetIcon: cleared icon");
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetTitle(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->title = args.GetString(0, "title");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetSnippet(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->snippet = args.GetString(0, "snippet");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value MarkerNAPI::SetVisible(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    MarkerNAPI* marker = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&marker));
    
    if (!marker) return nullptr;
    
    marker->visible = args.GetBool(0);
    Logger::debug("MarkerNAPI", "Marker visible set to %d", marker->visible);
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

} // namespace harmony
} // namespace maplibre