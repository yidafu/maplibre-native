# the minimum version of CMake.
cmake_minimum_required(VERSION 3.12)
project(harmony)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_SYSTEM_NAME STREQUAL "OHOS")
    # 鸿蒙系统特定的 C++20 设置
    # -Wall -Wextra：先观察告警不作为错误（-Wno-error），为后续开启
    #   -Werror 与恢复 .clang-tidy 的 NullDereference/UninitializedObject 检查铺路
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20 -fPIC -Wall -Wextra")
    # 忽略未使用的命令行参数警告
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error=unused-command-line-argument")
    # 启用 RTTI 支持
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -frtti")
    # 禁用 symbol guards（MUSL 不支持 std::source_location）
    add_definitions(-DMLN_SYMBOL_GUARDS=0)
endif()

add_subdirectory(
    ../../../../../../
    ${CMAKE_BINARY_DIR}/maplibre
)

ADD_DEFINITIONS(-DVK_USE_PLATFORM_OHOS=1)
ADD_DEFINITIONS(-DOHOS_PLATFORM)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
# MapLibre 仓库根目录：由本文件在仓库内的位置推导（cpp -> main -> src -> maplibre_harmony -> harmony -> platform -> 根）
get_filename_component(MBGL_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../" ABSOLUTE)

# 获取 DevEco Studio SDK 路径
if(DEFINED ENV{DEVECO_SDK_HOME})
    set(DEVECO_SDK_HOME $ENV{DEVECO_SDK_HOME})
else()
    # 如果没有设置环境变量，使用默认路径
    set(DEVECO_SDK_HOME "/Applications/DevEco-Studio.app/Contents/sdk")
    message(WARNING "DEVECO_SDK_HOME 环境变量未设置，使用默认路径: ${DEVECO_SDK_HOME}")
endif()

message(STATUS "DevEco SDK Home: ${DEVECO_SDK_HOME}")

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

message(STATUS "NATIVERENDER_ROOT_PATH\"${NATIVERENDER_ROOT_PATH}\"")

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

# 声明 curl 为 IMPORTED 库
add_library(curl SHARED IMPORTED)
set_target_properties(curl
    PROPERTIES
    IMPORTED_LOCATION
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/curl/${OHOS_ARCH}/lib/libcurl.so
)


# Note: maplibre_native_loop library removed
# Timer, AsyncTask, and RunLoop are now provided by mbgl-core
# via platform/harmony/harmony.cmake configuration

add_library(maplibre
    SHARED
    # Core module - MapView implementation
    core/thread_safe_callback.hpp
    core/thread_safe_callback.cpp
    core/map_registry.hpp
    core/map_registry.cpp
    core/callback_manager.hpp
    core/callback_manager.cpp
    core/native_map_view/native_map_view_harmony.hpp
    core/native_map_view/native_map_view_base.cpp
    core/native_map_view/native_map_view_camera.cpp
    core/native_map_view/native_map_view_style.cpp
    core/native_map_view/native_map_view_annotations.cpp
    core/native_map_view/native_map_view_query.cpp
    core/native_map_view/native_map_view_observers.cpp
    core/native_map_view/native_map_view_performance.cpp
    core/native_map_view/native_map_view_debug.cpp
    # Phase 3: Native gesture recognizers (replaces ArkTS MapGestureDetector)
    core/gesture/native_gesture_manager.hpp
    core/gesture/native_gesture_manager.cpp

    # Configuration management
    config/maplibre_settings.hpp
    config/maplibre_settings.cpp
    config/maplibre_settings_napi.hpp
    config/maplibre_settings_napi.cpp
    
    # Rendering system
    rendering/harmony_renderer.hpp
    rendering/harmony_renderer.cpp
    rendering/harmony_map_render_thread.hpp
    rendering/harmony_map_render_thread.cpp
    rendering/backends/harmony_renderer_backend.hpp
    rendering/backends/harmony_renderer_backend.cpp
    
    # Style conversion system
    style/napi_value_wrapper.hpp
    style/napi_value_wrapper.cpp
    style/conversion/harmony_conversion.hpp
    style/conversion/constant.hpp
    style/conversion/constant.cpp
    style/conversion/property_expression.hpp
    style/conversion/property_value.hpp
    style/layers/layer_property_utils.hpp
    style/layers/custom_layer_harmony.hpp
    style/layers/custom_layer_harmony.cpp
    napi/bindings/style/custom_drawable_layer_napi.hpp
    napi/bindings/style/custom_drawable_layer_napi.cpp
    
    # NAPI bindings
    napi/core/napi_init.cpp
    napi/core/napi_utils.h
    napi/core/napi_utils.cpp
    napi/core/napi_utils_ext.cpp
    napi/core/napi_args.hpp
    napi/core/napi_args.cpp
    napi/bindings/style_builder_napi.hpp
    napi/bindings/style_builder_napi.cpp
    napi/bindings/marker/marker_napi.hpp
    napi/bindings/marker/marker_napi_base.cpp
    napi/bindings/marker/marker_napi_options.cpp
    napi/bindings/polyline/polyline_napi.hpp
    napi/bindings/polyline/polyline_napi.cpp
    napi/bindings/polygon/polygon_napi.hpp
    napi/bindings/polygon/polygon_napi.cpp
    napi/bindings/icon/icon_napi.hpp
    napi/bindings/icon/icon_napi.cpp
    napi/bindings/icon_factory/icon_factory_napi.hpp
    napi/bindings/icon_factory/icon_factory_napi.cpp
    icon/icon_factory.hpp
    icon/icon_factory.cpp
    napi/bindings/image/image_napi.hpp
    napi/bindings/image/image_napi.cpp
    napi/bindings/style/style_napi.hpp
    napi/bindings/style/style_napi_base.cpp
    napi/bindings/style/style_napi_layers.cpp
    napi/bindings/style/style_napi_sources.cpp
    napi/bindings/style/style_napi_images.cpp
    napi/bindings/style/style_napi_light.cpp
    napi/bindings/style/custom_layer_napi.hpp
    napi/bindings/style/custom_layer_napi.cpp
    napi/bindings/network/network_napi.hpp
    napi/bindings/network/network_napi.cpp
    napi/bindings/network/url_transform_napi.hpp
    napi/bindings/network/url_transform_napi.cpp
    
    # Network module
    network/http_file_source_harmony.cpp
    network/curl_event_loop.hpp
    network/curl_event_loop.cpp
    network/http_request_config.hpp
    network/http_request_config.cpp
    network/url_transform_manager.hpp
    network/url_transform_manager.cpp
    
    # VSync management
    vsync/harmony_vsync_manager.hpp
    vsync/harmony_vsync_manager.cpp
    
    # Utils
    utils/logger.h
    utils/logger.cpp
    
    # Geometry API 绑定
    geometry/lat_lng_harmony.hpp
    geometry/lat_lng_harmony.cpp
    geometry/point_harmony.hpp
    geometry/point_harmony.cpp
    geometry/projected_meters_harmony.hpp
    geometry/projected_meters_harmony.cpp
    geometry/lat_lng_bounds_harmony.hpp
    geometry/lat_lng_bounds_harmony.cpp
    geometry/rect_harmony.hpp
    geometry/rect_harmony.cpp
    
    # Bitmap API 绑定
    bitmap/bitmap_harmony.hpp
    bitmap/bitmap_harmony.cpp
    bitmap/bitmap_napi.hpp
    bitmap/bitmap_napi.cpp
    
    # Camera API 绑定
    camera/camera_position_harmony.hpp
    camera/camera_position_harmony.cpp
    
    # Style API - value conversion
    style/transition_options_harmony.hpp
    style/transition_options_harmony.cpp
    style/filter_conversion.hpp
    style/filter_conversion.cpp
    style/value_conversion.hpp
    style/value_conversion.cpp
    
    # Style components - Light
    style/light_harmony.hpp
    style/light_harmony.cpp
    
    # Style factory for creating wrappers
    style/layer_source_factory_harmony.hpp
    style/layer_source_factory_harmony.cpp
    
    # GeoJSON 转换层
    geojson/util.hpp
    geojson/util.cpp
    geojson/geojson_converter.hpp
    geojson/geojson_converter.cpp
    
    # Offline API - 离线地图功能
    offline/offline_manager_napi.hpp
    offline/offline_manager_napi.cpp
    offline/offline_region_napi.hpp
    offline/offline_region_napi.cpp
    offline/offline_region_definition_napi.hpp
    offline/offline_region_definition_napi.cpp
    offline/offline_region_status_napi.hpp
    offline/offline_region_status_napi.cpp
    
    # Snapshot API - 地图快照功能
    snapshot/map_snapshotter_harmony.hpp
    snapshot/map_snapshotter_harmony.cpp
    snapshot/snapshotter_napi.hpp
    snapshot/snapshotter_napi.cpp
    snapshot/map_snapshot_napi.hpp
    snapshot/map_snapshot_napi.cpp
    
    # Source NAPI 类
    sources/geojson_source_napi.hpp
    sources/geojson_source_napi.cpp
    sources/vector_source_napi.hpp
    sources/vector_source_napi.cpp
    sources/raster_source_napi.hpp
    sources/raster_source_napi.cpp
    sources/raster_dem_source_napi.hpp
    sources/raster_dem_source_napi.cpp
    sources/image_source_napi.hpp
    sources/image_source_napi.cpp
    sources/custom_geometry_source_napi.hpp
    sources/custom_geometry_source_napi.cpp
    sources/video_source_napi.hpp
    sources/video_source_napi.cpp
    
    # Style layers
    style/layers/fill_layer_harmony.hpp
    style/layers/fill_layer_harmony.cpp
    style/layers/line_layer_harmony.hpp
    style/layers/line_layer_harmony.cpp
    style/layers/circle_layer_harmony.hpp
    style/layers/circle_layer_harmony.cpp
    style/layers/background_layer_harmony.hpp
    style/layers/background_layer_harmony.cpp
    style/layers/raster_layer_harmony.hpp
    style/layers/raster_layer_harmony.cpp
    style/layers/symbol_layer_harmony.hpp
    style/layers/symbol_layer_harmony.cpp
    
    # Additional layer types
    style/layers/heatmap_layer_harmony.hpp
    style/layers/heatmap_layer_harmony.cpp
    style/layers/hillshade_layer_harmony.hpp
    style/layers/hillshade_layer_harmony.cpp
    style/layers/fill_extrusion_layer_harmony.hpp
    style/layers/fill_extrusion_layer_harmony.cpp
    style/layers/color_relief_layer_harmony.hpp
    style/layers/color_relief_layer_harmony.cpp
    style/layers/location_indicator_layer_harmony.hpp
    style/layers/location_indicator_layer_harmony.cpp
    
    # HarmonyOS i18n files are in mbgl-core (harmony.cmake)
    # ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/i18n/collator.cpp
)

# Conditionally add rendering backend sources
if(MLN_WITH_VULKAN)
    target_sources(
        maplibre PRIVATE
            rendering/backends/harmony_vulkan_renderer_backend.hpp
            rendering/backends/harmony_vulkan_renderer_backend.cpp
    )
    message(STATUS "HarmonyOS: Adding Vulkan renderer backend sources")
endif()

if(MLN_WITH_OPENGL)
    target_sources(
        maplibre PRIVATE
            rendering/backends/egl_display_manager.hpp
            rendering/backends/egl_display_manager.cpp
            rendering/backends/harmony_gl_renderer_backend.hpp
            rendering/backends/harmony_gl_renderer_backend.cpp
    )
    message(STATUS "HarmonyOS: Adding OpenGL renderer backend sources (with EGL Display Manager)")
endif()


target_include_directories(
  maplibre
  PUBLIC ${PROJECT_SOURCE_DIR}
          ../../../../../../src
          ../../../../../../include
          ../../../src
          ../../../../../default/include
          ../../../../../../vendor/maplibre-native-base/include
          ../../../../../../vendor/nunicode/include
          ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/curl/${OHOS_ARCH}/include
          ${DEVECO_SDK_HOME}/default/openharmony/native/sysroot/usr/include
          ${MBGL_SOURCE_DIR}/platform/harmony/src)


target_link_libraries(maplibre
PUBLIC
    curl
    mbgl-core
    mbgl-vendor-unique_resource
    mbgl-vendor-nunicode
    ace_napi.z
    hilog_ndk.z
    uv
    ace_ndk.z
    GLESv3
    EGL
    native_window
    vulkan
    native_display_manager
    libnative_vsync.so
    pixelmap_ndk.z
    rawfile.z
    image_ndk.z
    image_source_ndk.z
    libnative_drawing.so
)

