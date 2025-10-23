#include "napi/native_api.h"
#include "PluginManager.h"
#include "native_map_view_harmony.hpp"
// Style API bindings
#include "style/style_harmony.hpp"
#include "style/sources/geojson_source_harmony.hpp"
#include "style/sources/vector_source_harmony.hpp"
#include "style/sources/raster_source_harmony.hpp"
#include "style/layers/fill_layer_harmony.hpp"
#include "style/layers/line_layer_harmony.hpp"
#include "style/layers/circle_layer_harmony.hpp"
//#include "native_map_view_harmony.hpp"

static napi_value Add(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2] = {nullptr};

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_valuetype valuetype0;
    napi_typeof(env, args[0], &valuetype0);

    napi_valuetype valuetype1;
    napi_typeof(env, args[1], &valuetype1);

    double value0;
    napi_get_value_double(env, args[0], &value0);

    double value1;
    napi_get_value_double(env, args[1], &value1);

    napi_value sum;
    napi_create_double(env, value0 + value1, &sum);

    return sum;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"add", nullptr, Add, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"SetSurfaceId", nullptr, PluginManager::SetSurfaceId, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"ChangeSurface", nullptr, PluginManager::ChangeSurface, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"DestroySurface", nullptr, PluginManager::DestroySurface, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"DrawPattern", nullptr, PluginManager::DrawPattern, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"ChangeColor", nullptr, PluginManager::ChangeColor, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"GetXComponentStatus", nullptr, PluginManager::GetXComponentStatus, nullptr, nullptr, nullptr, napi_default,
         nullptr}};
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);

    // 初始化 NativeMapView 类
    mbgl::harmony::NativeMapView::Init(env, exports);
    
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
