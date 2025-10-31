#pragma once

#include <napi/native_api.h>
#include <mbgl/annotation/annotation.hpp>
#include <mbgl/util/geometry.hpp>
#include <mbgl/util/color.hpp>
#include <string>
#include <vector>

namespace maplibre {
namespace harmony {

/**
 * PolylineNAPI - NAPI wrapper for Polyline
 * 
 * This class wraps a Polyline object and exposes it to ETS/TypeScript via NAPI.
 * It manages the polyline's state (points, color, width, etc.) in C++ layer.
 * 
 * Similar to Android's Polyline with JNI binding.
 */
class PolylineNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetPoints(napi_env env, napi_callback_info info);
    static napi_value GetColor(napi_env env, napi_callback_info info);
    static napi_value GetWidth(napi_env env, napi_callback_info info);
    static napi_value GetAlpha(napi_env env, napi_callback_info info);
    static napi_value GetVisible(napi_env env, napi_callback_info info);
    static napi_value GetZIndex(napi_env env, napi_callback_info info);
    static napi_value GetPattern(napi_env env, napi_callback_info info);
    static napi_value GetJointType(napi_env env, napi_callback_info info);
    static napi_value GetCapType(napi_env env, napi_callback_info info);
    static napi_value GetId(napi_env env, napi_callback_info info);
    
    // Setter methods
    static napi_value SetPoints(napi_env env, napi_callback_info info);
    static napi_value SetColor(napi_env env, napi_callback_info info);
    static napi_value SetWidth(napi_env env, napi_callback_info info);
    static napi_value SetAlpha(napi_env env, napi_callback_info info);
    static napi_value SetVisible(napi_env env, napi_callback_info info);
    static napi_value SetZIndex(napi_env env, napi_callback_info info);
    static napi_value SetPattern(napi_env env, napi_callback_info info);
    static napi_value SetJointType(napi_env env, napi_callback_info info);
    static napi_value SetCapType(napi_env env, napi_callback_info info);
    
    // Helper methods
    static napi_value AddPoint(napi_env env, napi_callback_info info);
    static napi_value InsertPoint(napi_env env, napi_callback_info info);
    static napi_value RemovePoint(napi_env env, napi_callback_info info);
    static napi_value SetId(napi_env env, napi_callback_info info);
    static napi_value SetMapLibreMap(napi_env env, napi_callback_info info);
    
    // Convert to mbgl::LineAnnotation
    mbgl::LineAnnotation toAnnotation() const;
    
    // Data access methods (for C++ internal use)
    const std::vector<mbgl::Point<double>>& getPointsInternal() const { return points; }
    mbgl::Color getColorValue() const { return color; }
    float getWidthValue() const { return width; }
    float getAlphaValue() const { return alpha; }
    bool isVisible() const { return visible; }
    int getZIndex() const { return zIndex; }
    mbgl::AnnotationID getAnnotationId() const { return annotationId; }
    
    void setAnnotationId(mbgl::AnnotationID id) { annotationId = id; }
    
private:
    static napi_ref constructor;
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    explicit PolylineNAPI();
    ~PolylineNAPI();
    
    // Polyline state
    mbgl::AnnotationID annotationId;
    std::vector<mbgl::Point<double>> points;  // List of (longitude, latitude)
    mbgl::Color color;
    float width;
    float alpha;
    bool visible;
    int zIndex;
    std::vector<float> pattern;  // Dash pattern
    std::string jointType;       // "round", "bevel", "miter"
    std::string capType;         // "round", "butt", "square"
    
    // Reference to MapLibreMap (if needed)
    napi_ref mapLibreMapRef;
};

} // namespace harmony
} // namespace maplibre
