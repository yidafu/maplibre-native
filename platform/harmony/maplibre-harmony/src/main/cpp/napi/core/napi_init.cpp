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
    mln::harmony::OfflineManagerNAPI::Init(env, exports);
    mln::harmony::OfflineRegionNAPI::Init(env, exports);
    
    // Initialize snapshot API
    mln::harmony::MapSnapshotterNAPI::Init(env, exports);
    
    // Initialize NativeMapView
    mln::harmony::NativeMapView::Init(env, exports);
    
    // Initialize Marker
    mln::harmony::MarkerNAPI::Init(env, exports);
    
    // Initialize Polyline
    mln::harmony::PolylineNAPI::Init(env, exports);
    
    // Initialize Polygon (annotations)
    mln::harmony::PolygonNAPI::Init(env, exports);
    
    // Initialize Icon
    mln::harmony::IconNAPI::Init(env, exports);
    
    // Initialize IconFactory
    mln::harmony::IconFactoryNAPI::Init(env, exports);
    
    // Initialize Image
    mln::harmony::ImageNAPI::Init(env, exports);
    
    // Initialize Bitmap
    mln::harmony::BitmapNAPI::Init(env, exports);
    
    // Initialize style API bindings (NAPI objects)
    mln::harmony::StyleNAPI::Init(env, exports);
    mln::harmony::StyleBuilderNAPI::Init(env, exports);
    
    // Initialize source NAPI classes
    mln::harmony::GeoJsonSourceNAPI::Init(env, exports);
    mln::harmony::VectorSourceNAPI::Init(env, exports);
    mln::harmony::RasterSourceNAPI::Init(env, exports);
    mln::harmony::RasterDemSourceNAPI::Init(env, exports);
    mln::harmony::ImageSourceNAPI::Init(env, exports);
    mln::harmony::CustomGeometrySourceNAPI::Init(env, exports);
    mln::harmony::VideoSourceNAPI::Init(env, exports);
    
    // Initialize layer bindings
    mln::harmony::FillLayerNAPI::Init(env, exports);
    mln::harmony::LineLayerNAPI::Init(env, exports);
    mln::harmony::CircleLayerNAPI::Init(env, exports);
    mln::harmony::BackgroundLayerNAPI::Init(env, exports);
    mln::harmony::RasterLayerNAPI::Init(env, exports);
    mln::harmony::SymbolLayerNAPI::Init(env, exports);
    mln::harmony::HeatmapLayerNAPI::Init(env, exports);
    mln::harmony::HillshadeLayerNAPI::Init(env, exports);
    mln::harmony::FillExtrusionLayerNAPI::Init(env, exports);
    mln::harmony::ColorReliefLayerNAPI::Init(env, exports);
    mln::harmony::LocationIndicatorLayerNAPI::Init(env, exports);
    mln::harmony::CustomLayerNAPI::Init(env, exports);
    mln::harmony::CustomDrawableLayerNAPI::Init(env, exports);
    
    // Style components
    mln::harmony::LightHarmony::Init(env, exports);
    
    // Network configuration
    mln::harmony::NetworkNAPI::Init(env, exports);
    mln::harmony::URLTransformNAPI::Init(env, exports);
    
    // Global configuration management
    mln::harmony::MapLibreSettingsNAPI::Init(env, exports);

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
