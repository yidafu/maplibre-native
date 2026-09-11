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
// Style API bindings (NAPI objects)
#include "napi/bindings/style/style_napi.hpp"
#include "napi/bindings/style_builder_napi.hpp"
// Source NAPI classes
#include "sources/geojson_source_napi.hpp"
#include "sources/vector_source_napi.hpp"
#include "sources/raster_source_napi.hpp"
#include "sources/raster_dem_source_napi.hpp"
#include "sources/image_source_napi.hpp"
#include "sources/custom_geometry_source_napi.hpp"
#include "sources/video_source_napi.hpp"
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
#include "style/layers/color_relief_layer_harmony.hpp"
#include "style/layers/location_indicator_layer_harmony.hpp"
#include "napi/bindings/style/custom_layer_napi.hpp"
#include "napi/bindings/style/custom_drawable_layer_napi.hpp"
// Style components
#include "style/light_harmony.hpp"
// Network configuration
#include "napi/bindings/network/network_napi.hpp"
#include "napi/bindings/network/url_transform_napi.hpp"
// Global settings
#include "config/maplibre_settings_napi.hpp"

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    // Note: LatLng now lives in the ETS layer and no longer requires NAPI registration
    
    // Initialize offline map APIs
    maplibre::harmony::OfflineManagerNAPI::Init(env, exports);
    maplibre::harmony::OfflineRegionNAPI::Init(env, exports);
    
    // Initialize snapshot API
    mbgl::harmony::MapSnapshotterNAPI::Init(env, exports);
    
    // Initialize NativeMapView
    mbgl::harmony::NativeMapView::Init(env, exports);
    
    // Initialize Marker
    maplibre::harmony::MarkerNAPI::Init(env, exports);
    
    // Initialize Polyline
    maplibre::harmony::PolylineNAPI::Init(env, exports);
    
    // Initialize Polygon (annotations)
    maplibre::harmony::PolygonNAPI::Init(env, exports);
    
    // Initialize Icon
    maplibre::harmony::IconNAPI::Init(env, exports);
    
    // Initialize IconFactory
    maplibre::harmony::IconFactoryNAPI::Init(env, exports);
    
    // Initialize Image
    maplibre::harmony::ImageNAPI::Init(env, exports);
    
    // Initialize Bitmap
    mbgl::harmony::BitmapNAPI::Init(env, exports);
    
    // Initialize style API bindings (NAPI objects)
    maplibre::harmony::StyleNAPI::Init(env, exports);
    maplibre::harmony::StyleBuilderNAPI::Init(env, exports);
    
    // Initialize source NAPI classes
    maplibre::harmony::GeoJsonSourceNAPI::Init(env, exports);
    maplibre::harmony::VectorSourceNAPI::Init(env, exports);
    maplibre::harmony::RasterSourceNAPI::Init(env, exports);
    maplibre::harmony::RasterDemSourceNAPI::Init(env, exports);
    maplibre::harmony::ImageSourceNAPI::Init(env, exports);
    maplibre::harmony::CustomGeometrySourceNAPI::Init(env, exports);
    maplibre::harmony::VideoSourceNAPI::Init(env, exports);
    
    // Initialize layer bindings
    mbgl::harmony::FillLayerNAPI::Init(env, exports);
    mbgl::harmony::LineLayerNAPI::Init(env, exports);
    mbgl::harmony::CircleLayerNAPI::Init(env, exports);
    mbgl::harmony::BackgroundLayerNAPI::Init(env, exports);
    mbgl::harmony::RasterLayerNAPI::Init(env, exports);
    mbgl::harmony::SymbolLayerNAPI::Init(env, exports);
    mbgl::harmony::HeatmapLayerNAPI::Init(env, exports);
    mbgl::harmony::HillshadeLayerNAPI::Init(env, exports);
    mbgl::harmony::FillExtrusionLayerNAPI::Init(env, exports);
    mbgl::harmony::ColorReliefLayerNAPI::Init(env, exports);
    mbgl::harmony::LocationIndicatorLayerNAPI::Init(env, exports);
    mbgl::harmony::CustomLayerNAPI::Init(env, exports);
    maplibre::harmony::CustomDrawableLayerNAPI::Init(env, exports);
    
    // Style components
    mbgl::harmony::LightHarmony::Init(env, exports);
    
    // Network configuration
    mbgl::harmony::NetworkNAPI::Init(env, exports);
    mbgl::harmony::URLTransformNAPI::Init(env, exports);
    
    // Global configuration management
    mbgl::harmony::MapLibreSettingsNAPI::Init(env, exports);

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
