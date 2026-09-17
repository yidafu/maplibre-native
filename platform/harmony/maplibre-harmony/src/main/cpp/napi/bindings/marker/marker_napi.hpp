#pragma once

#include <napi/native_api.h>
#include <mbgl/annotation/annotation.hpp>
#include <mbgl/util/geometry.hpp>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * MarkerNAPI - NAPI wrapper for Marker
 * 
 * This class wraps a Marker object and exposes it to ETS/TypeScript via NAPI.
 * It manages the marker's state (position, icon, title, etc.) in C++ layer.
 * 
 * Similar to Android's Marker with JNI binding.
 */
class MarkerNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetPosition(napi_env env, napi_callback_info info);
    static napi_value GetIcon(napi_env env, napi_callback_info info);
    static napi_value GetTitle(napi_env env, napi_callback_info info);
    static napi_value GetSnippet(napi_env env, napi_callback_info info);
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetVisible(napi_env env, napi_callback_info info);
    static napi_value GetAlpha(napi_env env, napi_callback_info info);
    static napi_value GetRotation(napi_env env, napi_callback_info info);
    static napi_value GetDraggable(napi_env env, napi_callback_info info);
    static napi_value GetZIndex(napi_env env, napi_callback_info info);
    
    // Setter methods
    static napi_value SetPosition(napi_env env, napi_callback_info info);
    static napi_value SetIcon(napi_env env, napi_callback_info info);
    static napi_value SetTitle(napi_env env, napi_callback_info info);
    static napi_value SetSnippet(napi_env env, napi_callback_info info);
    static napi_value SetVisible(napi_env env, napi_callback_info info);
    static napi_value SetAlpha(napi_env env, napi_callback_info info);
    static napi_value SetRotation(napi_env env, napi_callback_info info);
    static napi_value SetDraggable(napi_env env, napi_callback_info info);
    static napi_value SetZIndex(napi_env env, napi_callback_info info);
    
    // InfoWindow methods
    static napi_value ShowInfoWindow(napi_env env, napi_callback_info info);
    static napi_value HideInfoWindow(napi_env env, napi_callback_info info);
    static napi_value IsInfoWindowShown(napi_env env, napi_callback_info info);
    
    // Selection methods
    static napi_value IsSelected(napi_env env, napi_callback_info info);
    static napi_value SetSelected(napi_env env, napi_callback_info info);
    
    // Drag state methods
    static napi_value GetDragState(napi_env env, napi_callback_info info);
    static napi_value SetDragState(napi_env env, napi_callback_info info);
    
    // Animation methods
    static napi_value AnimateToPosition(napi_env env, napi_callback_info info);
    static napi_value AnimateAlpha(napi_env env, napi_callback_info info);
    static napi_value AnimateRotation(napi_env env, napi_callback_info info);
    
    // Anchor methods
    static napi_value GetAnchor(napi_env env, napi_callback_info info);
    static napi_value SetAnchor(napi_env env, napi_callback_info info);
    
    // Helper methods
    static napi_value Remove(napi_env env, napi_callback_info info);
    static napi_value SetId(napi_env env, napi_callback_info info);
    static napi_value SetMapLibreMap(napi_env env, napi_callback_info info);
    
    // Data access methods (for C++ internal use)
    mbgl::Point<double> getPositionPoint() const { return position; }
    std::string getIconId() const { return iconId; }
    std::string getTitle() const { return title; }
    std::string getSnippet() const { return snippet; }
    mbgl::AnnotationID getAnnotationId() const { return annotationId; }
    bool isVisible() const { return visible; }
    double getAlpha() const { return alpha; }
    double getRotation() const { return rotation; }
    bool isDraggableInternal() const { return draggable; }
    int getZIndex() const { return zIndex; }
    
    void setAnnotationId(mbgl::AnnotationID id) { annotationId = id; }
    
private:
    static napi_ref constructor;
    static napi_env constructorEnv;
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    explicit MarkerNAPI();
    ~MarkerNAPI();
    
    // Marker state
    mbgl::AnnotationID annotationId;
    mbgl::Point<double> position;       // (longitude, latitude)
    std::string iconId;
    std::string title;
    std::string snippet;
    bool visible;
    double alpha;
    double rotation;
    bool draggable;
    int zIndex;
    napi_ref iconRef;  // Reference to Icon object (if using Icon object instead of string ID)
    
    // Extended state
    bool infoWindowShown;
    bool selected;
    int dragState;  // 0=None, 1=Start, 2=Drag, 3=End
    napi_ref mapLibreMapRef;  // Reference to MapLibreMap (if needed)
    
    // Anchor point (u, v) where (0.5, 1.0) = bottom center
    double anchorU;
    double anchorV;
};

} // namespace harmony
} // namespace mbgl

