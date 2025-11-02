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
    
    // Visibility control
    static napi_value SetVisibility(napi_env env, napi_callback_info info);
    static napi_value GetVisibility(napi_env env, napi_callback_info info);
    
    // Filter
    static napi_value SetFilter(napi_env env, napi_callback_info info);
    static napi_value GetFilter(napi_env env, napi_callback_info info);
    
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
    
    // New Icon layout properties
    static napi_value SetIconIgnorePlacement(napi_env env, napi_callback_info info);
    static napi_value GetIconIgnorePlacement(napi_env env, napi_callback_info info);
    static napi_value SetIconOptional(napi_env env, napi_callback_info info);
    static napi_value GetIconOptional(napi_env env, napi_callback_info info);
    static napi_value SetIconPadding(napi_env env, napi_callback_info info);
    static napi_value GetIconPadding(napi_env env, napi_callback_info info);
    static napi_value SetIconKeepUpright(napi_env env, napi_callback_info info);
    static napi_value GetIconKeepUpright(napi_env env, napi_callback_info info);
    static napi_value SetIconPitchAlignment(napi_env env, napi_callback_info info);
    static napi_value GetIconPitchAlignment(napi_env env, napi_callback_info info);
    static napi_value SetIconRotationAlignment(napi_env env, napi_callback_info info);
    static napi_value GetIconRotationAlignment(napi_env env, napi_callback_info info);
    static napi_value SetIconTextFit(napi_env env, napi_callback_info info);
    static napi_value GetIconTextFit(napi_env env, napi_callback_info info);
    static napi_value SetIconTextFitPadding(napi_env env, napi_callback_info info);
    static napi_value GetIconTextFitPadding(napi_env env, napi_callback_info info);
    
    // New Text layout properties
    static napi_value SetTextLetterSpacing(napi_env env, napi_callback_info info);
    static napi_value GetTextLetterSpacing(napi_env env, napi_callback_info info);
    static napi_value SetTextJustify(napi_env env, napi_callback_info info);
    static napi_value GetTextJustify(napi_env env, napi_callback_info info);
    static napi_value SetTextRadialOffset(napi_env env, napi_callback_info info);
    static napi_value GetTextRadialOffset(napi_env env, napi_callback_info info);
    static napi_value SetTextVariableAnchor(napi_env env, napi_callback_info info);
    static napi_value GetTextVariableAnchor(napi_env env, napi_callback_info info);
    static napi_value SetTextVariableAnchorOffset(napi_env env, napi_callback_info info);
    static napi_value GetTextVariableAnchorOffset(napi_env env, napi_callback_info info);
    static napi_value SetTextRotate(napi_env env, napi_callback_info info);
    static napi_value GetTextRotate(napi_env env, napi_callback_info info);
    static napi_value SetTextPadding(napi_env env, napi_callback_info info);
    static napi_value GetTextPadding(napi_env env, napi_callback_info info);
    static napi_value SetTextKeepUpright(napi_env env, napi_callback_info info);
    static napi_value GetTextKeepUpright(napi_env env, napi_callback_info info);
    static napi_value SetTextTransform(napi_env env, napi_callback_info info);
    static napi_value GetTextTransform(napi_env env, napi_callback_info info);
    static napi_value SetTextMaxAngle(napi_env env, napi_callback_info info);
    static napi_value GetTextMaxAngle(napi_env env, napi_callback_info info);
    static napi_value SetTextRotationAlignment(napi_env env, napi_callback_info info);
    static napi_value GetTextRotationAlignment(napi_env env, napi_callback_info info);
    static napi_value SetTextPitchAlignment(napi_env env, napi_callback_info info);
    static napi_value GetTextPitchAlignment(napi_env env, napi_callback_info info);
    static napi_value SetTextLineHeight(napi_env env, napi_callback_info info);
    static napi_value GetTextLineHeight(napi_env env, napi_callback_info info);
    static napi_value SetTextWritingMode(napi_env env, napi_callback_info info);
    static napi_value GetTextWritingMode(napi_env env, napi_callback_info info);
    static napi_value SetTextIgnorePlacement(napi_env env, napi_callback_info info);
    static napi_value GetTextIgnorePlacement(napi_env env, napi_callback_info info);
    static napi_value SetTextOptional(napi_env env, napi_callback_info info);
    static napi_value GetTextOptional(napi_env env, napi_callback_info info);
    
    // Symbol common layout properties
    static napi_value SetSymbolPlacement(napi_env env, napi_callback_info info);
    static napi_value GetSymbolPlacement(napi_env env, napi_callback_info info);
    static napi_value SetSymbolSpacing(napi_env env, napi_callback_info info);
    static napi_value GetSymbolSpacing(napi_env env, napi_callback_info info);
    static napi_value SetSymbolAvoidEdges(napi_env env, napi_callback_info info);
    static napi_value GetSymbolAvoidEdges(napi_env env, napi_callback_info info);
    static napi_value SetSymbolSortKey(napi_env env, napi_callback_info info);
    static napi_value GetSymbolSortKey(napi_env env, napi_callback_info info);
    static napi_value SetSymbolZOrder(napi_env env, napi_callback_info info);
    static napi_value GetSymbolZOrder(napi_env env, napi_callback_info info);
    
    // Paint properties
    static napi_value SetIconOpacity(napi_env env, napi_callback_info info);
    static napi_value GetIconOpacity(napi_env env, napi_callback_info info);
    static napi_value SetIconColor(napi_env env, napi_callback_info info);
    static napi_value GetIconColor(napi_env env, napi_callback_info info);
    static napi_value SetIconHaloColor(napi_env env, napi_callback_info info);
    static napi_value GetIconHaloColor(napi_env env, napi_callback_info info);
    static napi_value SetIconHaloWidth(napi_env env, napi_callback_info info);
    static napi_value GetIconHaloWidth(napi_env env, napi_callback_info info);
    static napi_value SetIconHaloBlur(napi_env env, napi_callback_info info);
    static napi_value GetIconHaloBlur(napi_env env, napi_callback_info info);
    static napi_value SetIconTranslate(napi_env env, napi_callback_info info);
    static napi_value GetIconTranslate(napi_env env, napi_callback_info info);
    static napi_value SetIconTranslateAnchor(napi_env env, napi_callback_info info);
    static napi_value GetIconTranslateAnchor(napi_env env, napi_callback_info info);
    
    static napi_value SetTextOpacity(napi_env env, napi_callback_info info);
    static napi_value GetTextOpacity(napi_env env, napi_callback_info info);
    static napi_value SetTextColor(napi_env env, napi_callback_info info);
    static napi_value GetTextColor(napi_env env, napi_callback_info info);
    static napi_value SetTextHaloColor(napi_env env, napi_callback_info info);
    static napi_value GetTextHaloColor(napi_env env, napi_callback_info info);
    static napi_value SetTextHaloWidth(napi_env env, napi_callback_info info);
    static napi_value GetTextHaloWidth(napi_env env, napi_callback_info info);
    static napi_value SetTextHaloBlur(napi_env env, napi_callback_info info);
    static napi_value GetTextHaloBlur(napi_env env, napi_callback_info info);
    static napi_value SetTextTranslate(napi_env env, napi_callback_info info);
    static napi_value GetTextTranslate(napi_env env, napi_callback_info info);
    static napi_value SetTextTranslateAnchor(napi_env env, napi_callback_info info);
    static napi_value GetTextTranslateAnchor(napi_env env, napi_callback_info info);
    
private:
    std::unique_ptr<mbgl::style::SymbolLayer> layer;
    bool ownsLayer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
    
    static napi_ref constructor;
};

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBREHARMONY_SYMBOL_LAYER_HARMONY_HPP

