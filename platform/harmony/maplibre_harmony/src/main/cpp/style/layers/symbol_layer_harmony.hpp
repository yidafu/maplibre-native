#ifndef MAPLIBREHARMONY_SYMBOL_LAYER_HARMONY_HPP
#define MAPLIBREHARMONY_SYMBOL_LAYER_HARMONY_HPP

#include <mbgl/style/layers/symbol_layer.hpp>
#include <string>
#include <memory>
#include <js_native_api.h>

namespace mbgl {
namespace harmony {

/**
 * SymbolLayerNAPI - Symbol Layer NAPI binding
 * 
 * Wraps mbgl::style::SymbolLayer for use in HarmonyOS
 */
class SymbolLayerNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    SymbolLayerNAPI(const std::string& layerId, const std::string& sourceId);
    SymbolLayerNAPI(std::unique_ptr<mbgl::style::SymbolLayer> layer);
    ~SymbolLayerNAPI();
    
    // Get native layer
    mbgl::style::SymbolLayer* getLayer() { 
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::SymbolLayer*>(weakLayer.get());
        }
        return layer.get(); 
    }
    
    // Internal methods for Style API
    std::string getId() const { return layer ? layer->getID() : ""; }
    
    // Release layer ownership (for Style.addLayer)
    std::unique_ptr<mbgl::style::Layer> releaseLayer() {
        if (!layer) {
            throw std::runtime_error("Layer already added to style");
        }
        ownsLayer = false;
        return std::move(layer);
    }
    
    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::SymbolLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }
    
private:
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Basic layer methods
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    static napi_value GetSourceId(napi_env env, napi_callback_info info);
    static napi_value SetSourceLayer(napi_env env, napi_callback_info info);
    static napi_value GetSourceLayer(napi_env env, napi_callback_info info);
    static napi_value SetMinZoom(napi_env env, napi_callback_info info);
    static napi_value GetMinZoom(napi_env env, napi_callback_info info);
    static napi_value SetMaxZoom(napi_env env, napi_callback_info info);
    static napi_value GetMaxZoom(napi_env env, napi_callback_info info);
    
    // Layout properties
    static napi_value SetIconImage(napi_env env, napi_callback_info info);
    static napi_value GetIconImage(napi_env env, napi_callback_info info);
    static napi_value SetIconSize(napi_env env, napi_callback_info info);
    static napi_value GetIconSize(napi_env env, napi_callback_info info);
    static napi_value SetIconRotate(napi_env env, napi_callback_info info);
    static napi_value GetIconRotate(napi_env env, napi_callback_info info);
    static napi_value SetIconOffset(napi_env env, napi_callback_info info);
    static napi_value GetIconOffset(napi_env env, napi_callback_info info);
    static napi_value SetIconAnchor(napi_env env, napi_callback_info info);
    static napi_value GetIconAnchor(napi_env env, napi_callback_info info);
    
    static napi_value SetTextField(napi_env env, napi_callback_info info);
    static napi_value GetTextField(napi_env env, napi_callback_info info);
    static napi_value SetTextFont(napi_env env, napi_callback_info info);
    static napi_value GetTextFont(napi_env env, napi_callback_info info);
    static napi_value SetTextSize(napi_env env, napi_callback_info info);
    static napi_value GetTextSize(napi_env env, napi_callback_info info);
    static napi_value SetTextMaxWidth(napi_env env, napi_callback_info info);
    static napi_value GetTextMaxWidth(napi_env env, napi_callback_info info);
    static napi_value SetTextOffset(napi_env env, napi_callback_info info);
    static napi_value GetTextOffset(napi_env env, napi_callback_info info);
    static napi_value SetTextAnchor(napi_env env, napi_callback_info info);
    static napi_value GetTextAnchor(napi_env env, napi_callback_info info);
    
    static napi_value SetIconAllowOverlap(napi_env env, napi_callback_info info);
    static napi_value GetIconAllowOverlap(napi_env env, napi_callback_info info);
    static napi_value SetTextAllowOverlap(napi_env env, napi_callback_info info);
    static napi_value GetTextAllowOverlap(napi_env env, napi_callback_info info);
    
    // Paint properties
    static napi_value SetIconOpacity(napi_env env, napi_callback_info info);
    static napi_value GetIconOpacity(napi_env env, napi_callback_info info);
    static napi_value SetIconColor(napi_env env, napi_callback_info info);
    static napi_value GetIconColor(napi_env env, napi_callback_info info);
    static napi_value SetIconHaloColor(napi_env env, napi_callback_info info);
    static napi_value GetIconHaloColor(napi_env env, napi_callback_info info);
    static napi_value SetIconHaloWidth(napi_env env, napi_callback_info info);
    static napi_value GetIconHaloWidth(napi_env env, napi_callback_info info);
    
    static napi_value SetTextOpacity(napi_env env, napi_callback_info info);
    static napi_value GetTextOpacity(napi_env env, napi_callback_info info);
    static napi_value SetTextColor(napi_env env, napi_callback_info info);
    static napi_value GetTextColor(napi_env env, napi_callback_info info);
    static napi_value SetTextHaloColor(napi_env env, napi_callback_info info);
    static napi_value GetTextHaloColor(napi_env env, napi_callback_info info);
    static napi_value SetTextHaloWidth(napi_env env, napi_callback_info info);
    static napi_value GetTextHaloWidth(napi_env env, napi_callback_info info);
    
private:
    std::unique_ptr<mbgl::style::SymbolLayer> layer;
    bool ownsLayer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
    
    static napi_ref constructor;
};

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBREHARMONY_SYMBOL_LAYER_HARMONY_HPP

