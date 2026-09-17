#pragma once

#include <napi/native_api.h>
#include <mbgl/annotation/annotation.hpp>
#include <mbgl/util/geometry.hpp>
#include <mbgl/util/color.hpp>
#include <string>
#include <vector>

namespace mbgl {
namespace harmony {

/**
 * PolygonNAPI - NAPI wrapper for Polygon
 * 
 * This class wraps a Polygon object and exposes it to ETS/TypeScript via NAPI.
 * It manages the polygon's state (points, holes, colors, etc.) in C++ layer.
 * 
 * Similar to Android's Polygon with JNI binding.
 */
class PolygonNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetPoints(napi_env env, napi_callback_info info);
    static napi_value GetHoles(napi_env env, napi_callback_info info);
    static napi_value GetFillColor(napi_env env, napi_callback_info info);
    static napi_value GetStrokeColor(napi_env env, napi_callback_info info);
    static napi_value GetStrokeWidth(napi_env env, napi_callback_info info);
    static napi_value GetFillAlpha(napi_env env, napi_callback_info info);
    static napi_value GetStrokeAlpha(napi_env env, napi_callback_info info);
    static napi_value GetVisible(napi_env env, napi_callback_info info);
    static napi_value GetZIndex(napi_env env, napi_callback_info info);
    static napi_value GetId(napi_env env, napi_callback_info info);
    
    // Setter methods
    static napi_value SetPoints(napi_env env, napi_callback_info info);
    static napi_value SetHoles(napi_env env, napi_callback_info info);
    static napi_value SetFillColor(napi_env env, napi_callback_info info);
    static napi_value SetStrokeColor(napi_env env, napi_callback_info info);
    static napi_value SetStrokeWidth(napi_env env, napi_callback_info info);
    static napi_value SetFillAlpha(napi_env env, napi_callback_info info);
    static napi_value SetStrokeAlpha(napi_env env, napi_callback_info info);
    static napi_value SetVisible(napi_env env, napi_callback_info info);
    static napi_value SetZIndex(napi_env env, napi_callback_info info);
    
    // Helper methods
    static napi_value AddPoint(napi_env env, napi_callback_info info);
    static napi_value InsertPoint(napi_env env, napi_callback_info info);
    static napi_value RemovePoint(napi_env env, napi_callback_info info);
    static napi_value AddHole(napi_env env, napi_callback_info info);
    static napi_value RemoveHole(napi_env env, napi_callback_info info);
    static napi_value SetId(napi_env env, napi_callback_info info);
    static napi_value SetMapLibreMap(napi_env env, napi_callback_info info);
    
    // Convert to mbgl::FillAnnotation
    mbgl::FillAnnotation toAnnotation() const;
    
    // Data access methods (for C++ internal use)
    const std::vector<mbgl::Point<double>>& getPointsInternal() const { return points; }
    const std::vector<std::vector<mbgl::Point<double>>>& getHolesInternal() const { return holes; }
    mbgl::Color getFillColorValue() const { return fillColor; }
    mbgl::Color getStrokeColorValue() const { return strokeColor; }
    float getStrokeWidthValue() const { return strokeWidth; }
    float getFillAlphaValue() const { return fillAlpha; }
    float getStrokeAlphaValue() const { return strokeAlpha; }
    bool isVisible() const { return visible; }
    int getZIndex() const { return zIndex; }
    mbgl::AnnotationID getAnnotationId() const { return annotationId; }
    
    void setAnnotationId(mbgl::AnnotationID id) { annotationId = id; }
    
private:
    static napi_ref constructor;
    static napi_env constructorEnv;
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    explicit PolygonNAPI();
    ~PolygonNAPI();
    
    // Polygon state
    mbgl::AnnotationID annotationId;
    std::vector<mbgl::Point<double>> points;                        // Outer ring
    std::vector<std::vector<mbgl::Point<double>>> holes;           // Inner rings (holes)
    mbgl::Color fillColor;
    mbgl::Color strokeColor;
    float strokeWidth;
    float fillAlpha;
    float strokeAlpha;
    bool visible;
    int zIndex;
    
    // Reference to MapLibreMap (if needed)
    napi_ref mapLibreMapRef;
};

} // namespace harmony
} // namespace mbgl
