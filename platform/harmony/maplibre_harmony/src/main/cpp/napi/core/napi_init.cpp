#include "napi/native_api.h"
#include "core/native_map_view/native_map_view_harmony.hpp"
#include "napi/bindings/marker/marker_napi.hpp"
#include "napi/bindings/polyline/polyline_napi.hpp"
#include "napi/bindings/polygon/polygon_napi.hpp"
#include "napi/bindings/icon/icon_napi.hpp"
#include "napi/bindings/icon_factory/icon_factory_napi.hpp"
#include "napi/bindings/image/image_napi.hpp"
// Bitmap
#include "bitmap/bitmap_napi.hpp"
// Geometry types
#include "geometry/lat_lng_harmony.hpp"
// Offline API
#include "offline/offline_manager_napi.hpp"
#include "offline/offline_region_napi.hpp"
// Snapshot API
#include "snapshot/snapshotter_napi.hpp"
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
#include "style/layers/heatmap_layer_harmony.hpp"
#include "style/layers/hillshade_layer_harmony.hpp"
#include "style/layers/fill_extrusion_layer_harmony.hpp"
#include "napi/bindings/style/custom_layer_napi.hpp"
// Style components
#include "style/light_harmony.hpp"
// Network configuration
#include "napi/bindings/network/network_napi.hpp"
#include "napi/bindings/network/url_transform_napi.hpp"

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    // 注意：LatLng 已改为 ETS 层实现，不再需要 NAPI 注册
    
    // 初始化离线地图 API
    maplibre::harmony::OfflineManagerNAPI::Init(env, exports);
    maplibre::harmony::OfflineRegionNAPI::Init(env, exports);
    
    // 初始化地图快照 API
    mbgl::harmony::MapSnapshotterNAPI::Init(env, exports);
    
    // 初始化 NativeMapView 类
    mbgl::harmony::NativeMapView::Init(env, exports);
    
    // 初始化 Marker 类
    maplibre::harmony::MarkerNAPI::Init(env, exports);
    
    // 初始化 Polyline 类
    maplibre::harmony::PolylineNAPI::Init(env, exports);
    
    // 初始化 Polygon 类 (annotations)
    maplibre::harmony::PolygonNAPI::Init(env, exports);
    
    // 初始化 Icon 类
    maplibre::harmony::IconNAPI::Init(env, exports);
    
    // 初始化 IconFactory 类
    maplibre::harmony::IconFactoryNAPI::Init(env, exports);
    
    // 初始化 Image 类
    maplibre::harmony::ImageNAPI::Init(env, exports);
    
    // 初始化 Bitmap 类
    mbgl::harmony::BitmapNAPI::Init(env, exports);
    
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
    mbgl::harmony::SymbolLayerNAPI::Init(env, exports);
    mbgl::harmony::HeatmapLayerNAPI::Init(env, exports);
    mbgl::harmony::HillshadeLayerNAPI::Init(env, exports);
    mbgl::harmony::FillExtrusionLayerNAPI::Init(env, exports);
    mbgl::harmony::CustomLayerNAPI::Init(env, exports);
    
    // 样式组件
    mbgl::harmony::LightHarmony::Init(env, exports);
    
    // 网络配置
    mbgl::harmony::NetworkNAPI::Init(env, exports);
    mbgl::harmony::URLTransformNAPI::Init(env, exports);

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
