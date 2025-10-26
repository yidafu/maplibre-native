#include "napi/native_api.h"
#include "native_map_view_harmony.hpp"
#include "marker_napi.hpp"
// Style API bindings
#include "style/style_harmony.hpp"
#include "style/sources/geojson_source_harmony.hpp"
#include "style/sources/vector_source_harmony.hpp"
#include "style/sources/raster_source_harmony.hpp"
#include "style/layers/fill_layer_harmony.hpp"
#include "style/layers/line_layer_harmony.hpp"
#include "style/layers/circle_layer_harmony.hpp"

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    // 初始化 NativeMapView 类
    mbgl::harmony::NativeMapView::Init(env, exports);
    
    // 初始化 Marker 类
    maplibre::harmony::MarkerNAPI::Init(env, exports);
    
    // 初始化 Style API 绑定
    mbgl::harmony::StyleHarmony::Init(env, exports);
    
    // 数据源绑定
    mbgl::harmony::GeoJsonSourceHarmony::Init(env, exports);
    mbgl::harmony::VectorSourceHarmony::Init(env, exports);
    mbgl::harmony::RasterSourceHarmony::Init(env, exports);
    // TODO: RasterDemSourceHarmony::Init(env, exports);
    // TODO: ImageSourceHarmony::Init(env, exports);
    
    // 图层绑定
    mbgl::harmony::FillLayerHarmony::Init(env, exports);
    mbgl::harmony::LineLayerHarmony::Init(env, exports);
    mbgl::harmony::CircleLayerHarmony::Init(env, exports);
    // TODO: SymbolLayerHarmony::Init(env, exports);
    // TODO: RasterLayerHarmony::Init(env, exports);
    // TODO: BackgroundLayerHarmony::Init(env, exports);
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
