#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/line_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * LineLayerNAPI - NAPI wrapper for LineLayer
 * 
 * This class wraps a LineLayer object and exposes it to ETS/TypeScript via NAPI.
 * It manages the layer's state and properties in C++ layer.
 */
class LineLayerNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    // 从现有 Layer 创建（使用 WeakPtr，不拥有所有权）
    LineLayerNAPI(mbgl::style::LineLayer* layerPtr);

    // 从现有 native 对象创建 NAPI 实例
    static napi_value CreateInstance(napi_env env, mbgl::style::LineLayer* layerPtr);

    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property setter methods
    static napi_value SetLineColor(napi_env env, napi_callback_info info);
    static napi_value SetLineWidth(napi_env env, napi_callback_info info);
    static napi_value SetLineOpacity(napi_env env, napi_callback_info info);
    static napi_value SetLinePattern(napi_env env, napi_callback_info info);
    static napi_value SetLineGapWidth(napi_env env, napi_callback_info info);
    static napi_value SetLineDasharray(napi_env env, napi_callback_info info);
    static napi_value SetLineBlur(napi_env env, napi_callback_info info);
    static napi_value SetLineOffset(napi_env env, napi_callback_info info);
    static napi_value SetLineCap(napi_env env, napi_callback_info info);
    static napi_value SetLineJoin(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetLineColor(napi_env env, napi_callback_info info);
    static napi_value GetLineWidth(napi_env env, napi_callback_info info);
    static napi_value GetLineOpacity(napi_env env, napi_callback_info info);
    
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
    static napi_value SetLineTranslate(napi_env env, napi_callback_info info);
    static napi_value GetLineTranslate(napi_env env, napi_callback_info info);
    static napi_value SetLineTranslateAnchor(napi_env env, napi_callback_info info);
    static napi_value GetLineTranslateAnchor(napi_env env, napi_callback_info info);
    static napi_value SetLineMiterLimit(napi_env env, napi_callback_info info);
    static napi_value GetLineMiterLimit(napi_env env, napi_callback_info info);
    static napi_value SetLineRoundLimit(napi_env env, napi_callback_info info);
    static napi_value GetLineRoundLimit(napi_env env, napi_callback_info info);
    static napi_value SetLineGradient(napi_env env, napi_callback_info info);
    static napi_value GetLineGradient(napi_env env, napi_callback_info info);
    static napi_value SetLineSortKey(napi_env env, napi_callback_info info);
    static napi_value GetLineSortKey(napi_env env, napi_callback_info info);
    
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
    mbgl::style::LineLayer* getLayer() { 
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::LineLayer*>(weakLayer.get());
        }
        return layer.get(); 
    }
    
    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::LineLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit LineLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~LineLayerNAPI();
    
    static napi_ref constructor;
    std::unique_ptr<mbgl::style::LineLayer> layer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
};

} // namespace harmony
} // namespace mbgl
