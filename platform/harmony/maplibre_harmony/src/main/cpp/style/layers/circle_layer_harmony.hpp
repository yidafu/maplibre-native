#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/circle_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * CircleLayerNAPI - NAPI wrapper for CircleLayer
 * 
 * This class wraps a CircleLayer object and exposes it to ETS/TypeScript via NAPI.
 * It manages the layer's state and properties in C++ layer.
 */
class CircleLayerNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    // Construct from an existing layer (uses WeakPtr, does not take ownership)
    CircleLayerNAPI(mbgl::style::CircleLayer* layerPtr);

    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::CircleLayer* layerPtr);

    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property setter methods
    static napi_value SetCircleRadius(napi_env env, napi_callback_info info);
    static napi_value SetCircleColor(napi_env env, napi_callback_info info);
    static napi_value SetCircleOpacity(napi_env env, napi_callback_info info);
    static napi_value SetCircleBlur(napi_env env, napi_callback_info info);
    static napi_value SetCircleStrokeWidth(napi_env env, napi_callback_info info);
    static napi_value SetCircleStrokeColor(napi_env env, napi_callback_info info);
    static napi_value SetCircleStrokeOpacity(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetCircleRadius(napi_env env, napi_callback_info info);
    static napi_value GetCircleColor(napi_env env, napi_callback_info info);
    static napi_value GetCircleOpacity(napi_env env, napi_callback_info info);
    
    // Layer base methods
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    static napi_value GetSourceId(napi_env env, napi_callback_info info);
    
    // Visibility control
    static napi_value SetVisibility(napi_env env, napi_callback_info info);
    static napi_value GetVisibility(napi_env env, napi_callback_info info);
    
    // Zoom range control
    static napi_value SetMinZoom(napi_env env, napi_callback_info info);
    static napi_value GetMinZoom(napi_env env, napi_callback_info info);
    static napi_value SetMaxZoom(napi_env env, napi_callback_info info);
    static napi_value GetMaxZoom(napi_env env, napi_callback_info info);
    
    // Source layer
    static napi_value SetSourceLayer(napi_env env, napi_callback_info info);
    static napi_value GetSourceLayer(napi_env env, napi_callback_info info);
    
    // Filter
    static napi_value SetFilter(napi_env env, napi_callback_info info);
    static napi_value GetFilter(napi_env env, napi_callback_info info);
    
    // New properties
    static napi_value SetCircleTranslate(napi_env env, napi_callback_info info);
    static napi_value GetCircleTranslate(napi_env env, napi_callback_info info);
    static napi_value SetCircleTranslateAnchor(napi_env env, napi_callback_info info);
    static napi_value GetCircleTranslateAnchor(napi_env env, napi_callback_info info);
    static napi_value SetCirclePitchScale(napi_env env, napi_callback_info info);
    static napi_value GetCirclePitchScale(napi_env env, napi_callback_info info);
    static napi_value SetCirclePitchAlignment(napi_env env, napi_callback_info info);
    static napi_value GetCirclePitchAlignment(napi_env env, napi_callback_info info);
    static napi_value SetCircleSortKey(napi_env env, napi_callback_info info);
    static napi_value GetCircleSortKey(napi_env env, napi_callback_info info);
    
    // Generic property methods (Android-compatible API)
    static napi_value SetProperty(napi_env env, napi_callback_info info);
    static napi_value SetProperties(napi_env env, napi_callback_info info);
    
    // Internal methods for Style API
    std::string getId() const { return layer ? layer->getID() : ""; }
    
    // Release layer ownership (for Style.addLayer)
    std::unique_ptr<mbgl::style::Layer> releaseLayer() {
        if (!layer) {
            throw std::runtime_error("Layer already added to style");
        }
        return std::move(layer);
    }
    
    // Get native layer pointer (for property access after adding)
    mbgl::style::CircleLayer* getLayer() { 
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::CircleLayer*>(weakLayer.get());
        }
        return layer.get(); 
    }
    
    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::CircleLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit CircleLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~CircleLayerNAPI();
    
    static napi_ref constructor;
    static napi_env constructorEnv;
    std::unique_ptr<mbgl::style::CircleLayer> layer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
};

} // namespace harmony
} // namespace mbgl

