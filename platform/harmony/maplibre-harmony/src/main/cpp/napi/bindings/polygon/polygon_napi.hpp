#pragma once

#include <napi/native_api.h>
#include <mln/annotation/annotation.hpp>
#include <mln/util/geometry.hpp>
#include <mln/util/color.hpp>
#include <string>
#include <vector>

namespace mln {
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
    
    // Convert to mln::FillAnnotation
    mln::FillAnnotation toAnnotation() const;
    
    // Data access methods (for C++ internal use)
    const std::vector<mln::Point<double>>& getPointsInternal() const { return points; }
    const std::vector<std::vector<mln::Point<double>>>& getHolesInternal() const { return holes; }
    mln::Color getFillColorValue() const { return fillColor; }
    mln::Color getStrokeColorValue() const { return strokeColor; }
    float getStrokeWidthValue() const { return strokeWidth; }
    float getFillAlphaValue() const { return fillAlpha; }
    float getStrokeAlphaValue() const { return strokeAlpha; }
    bool isVisible() const { return visible; }
    int getZIndex() const { return zIndex; }
    mln::AnnotationID getAnnotationId() const { return annotationId; }
    
    void setAnnotationId(mln::AnnotationID id) { annotationId = id; }
    
private:
    static napi_ref constructor;
    static napi_env constructorEnv;
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    explicit PolygonNAPI();
    ~PolygonNAPI();
    
    // Polygon state
    mln::AnnotationID annotationId;
    std::vector<mln::Point<double>> points;                        // Outer ring
    std::vector<std::vector<mln::Point<double>>> holes;           // Inner rings (holes)
    mln::Color fillColor;
    mln::Color strokeColor;
    float strokeWidth;
    float fillAlpha;
    float strokeAlpha;
    bool visible;
    int zIndex;
    
    // Reference to MapLibreMap (if needed)
    napi_ref mapLibreMapRef;
};

} // namespace harmony
} // namespace mln
