#include "napi/native_api.h"
#include "core/native_map_view/native_map_view_harmony.hpp"
#include "napi/bindings/marker/marker_napi.hpp"
// Geometry types
#include "geometry/lat_lng_harmony.hpp"
// Style API bindings (NAPI 对象)
#include "napi/bindings/style/style_napi.hpp"
#include "napi/bindings/style_builder_napi.hpp"
// Source NAPI 类
#include "sources/geojson_source_napi.hpp"
#include "sources/vector_source_napi.hpp"
#include "sources/raster_source_napi.hpp"
#include "sources/raster_dem_source_napi.hpp"
#include "sources/image_source_napi.hpp"
// Layer bindings
#include "style/layers/fill_layer_harmony.hpp"
#include "style/layers/line_layer_harmony.hpp"
#include "style/layers/circle_layer_harmony.hpp"
#include "style/layers/background_layer_harmony.hpp"
#include "style/layers/raster_layer_harmony.hpp"
#include "style/layers/symbol_layer_harmony.hpp"

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    // 初始化 Geometry 类
    mbgl::harmony::LatLngNapi::Init(env, exports);
    
    // 初始化 NativeMapView 类
    mbgl::harmony::NativeMapView::Init(env, exports);
    
    // 初始化 Marker 类
    maplibre::harmony::MarkerNAPI::Init(env, exports);
    
    // 初始化 Style API 绑定 (NAPI 对象)
    maplibre::harmony::StyleNAPI::Init(env, exports);
    maplibre::harmony::StyleBuilderNAPI::Init(env, exports);
    
    // 数据源 NAPI 类
    maplibre::harmony::GeoJsonSourceNAPI::Init(env, exports);
    maplibre::harmony::VectorSourceNAPI::Init(env, exports);
    maplibre::harmony::RasterSourceNAPI::Init(env, exports);
    maplibre::harmony::RasterDemSourceNAPI::Init(env, exports);
    maplibre::harmony::ImageSourceNAPI::Init(env, exports);
    
    // 图层绑定
    mbgl::harmony::FillLayerNAPI::Init(env, exports);
    mbgl::harmony::LineLayerNAPI::Init(env, exports);
    mbgl::harmony::CircleLayerNAPI::Init(env, exports);
    mbgl::harmony::BackgroundLayerNAPI::Init(env, exports);
    mbgl::harmony::RasterLayerNAPI::Init(env, exports);
    // TODO: SymbolLayerNAPI has compilation errors, temporarily disabled
    // maplibre::harmony::SymbolLayerNAPI::Init(env, exports);
    // TODO: HeatmapLayerHarmony::Init(env, exports);
    // TODO: HillshadeLayerHarmony::Init(env, exports);
    // TODO: FillExtrusionLayerHarmony::Init(env, exports);
    
    return exports;
}
EXTERN_C_END

static napi_module maplibreModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "maplibre_native",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterMaplibre_harmonyModule(void) { napi_module_register(&maplibreModule); }
