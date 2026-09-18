#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layer.hpp>
#include <mbgl/style/source.hpp>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * Behavior for layer/source types that have no full NAPI wrapper.
 */
enum class WrapperFallback {
    InfoObject, // plain descriptive object (id/type/...) for unhandled types
    Null,       // JS null for unhandled types (callers keep their own diagnostics)
};

/**
 * LayerSourceFactory - Helper class to create NAPI wrappers for layers and sources
 *
 * This is a simplified version compared to Android's LayerManager.
 * It creates the appropriate NAPI wrapper based on the layer/source type.
 */
class LayerSourceFactory {
public:
    /**
     * Create a NAPI wrapper for a layer based on its type
     * Returns a NAPI object representing the layer, or undefined if type is not supported
     */
    static napi_value createLayerWrapper(napi_env env, mbgl::style::Layer* layer,
                                         WrapperFallback fallback = WrapperFallback::InfoObject);

    /**
     * Create a NAPI wrapper for a source based on its type
     * Returns a NAPI object representing the source, or undefined if type is not supported
     */
    static napi_value createSourceWrapper(napi_env env, mbgl::style::Source* source,
                                          WrapperFallback fallback = WrapperFallback::InfoObject);

    /**
     * The single style-spec spelling of a source type ("vector", "raster-dem",
     * "custom-vector", ...). Shared by every caller that renders a source type
     * as a string.
     */
    static std::string SourceTypeToString(mbgl::style::SourceType type);

private:
    LayerSourceFactory() = delete;
};

} // namespace harmony
} // namespace mbgl

