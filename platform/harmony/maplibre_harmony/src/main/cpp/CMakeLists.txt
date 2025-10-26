# the minimum version of CMake.
cmake_minimum_required(VERSION 3.12)
project(harmony)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_SYSTEM_NAME STREQUAL "OHOS")
    # 鸿蒙系统特定的 C++20 设置
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20 -fPIC")
    # 忽略未使用的命令行参数警告
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error=unused-command-line-argument")
    # 启用 RTTI 支持
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -frtti")
endif()

link_directories(/opt/homebrew/opt)
add_subdirectory(
    ../../../../../../
    ${CMAKE_BINARY_DIR}/maplibre
)

ADD_DEFINITIONS(-DVK_USE_PLATFORM_OHOS=1)
ADD_DEFINITIONS(-DOHOS_PLATFORM)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
set(MBGL_SOURCE_DIR "/Users/yidafu/github/maplibre-native")

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


add_library(maplibre_native_loop STATIC)
target_sources(
    maplibre_native_loop
    PRIVATE
        ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/util/async_task.cpp
        ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/util/run_loop.cpp
        ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/util/timer.cpp
)

target_include_directories(
    maplibre_native_loop
    PUBLIC
        ${MBGL_SOURCE_DIR}/include
        ${MBGL_SOURCE_DIR}/platform/default/include
        ${MBGL_SOURCE_DIR}/src
        ${MBGL_SOURCE_DIR}/vendor/maplibre-native-base/include
    PRIVATE ${LIBUV_INCLUDE_DIRS}
)

add_library(maplibre_native
    SHARED
    # Core module - MapView implementation
    core/common.hpp
    core/camera_change_tracker.cpp
    core/camera_change_tracker.hpp
    core/native_map_view/native_map_view_harmony.hpp
    core/native_map_view/native_map_view_base.cpp
    core/native_map_view/native_map_view_camera.cpp
    core/native_map_view/native_map_view_style.cpp
    core/native_map_view/native_map_view_annotations.cpp
    core/native_map_view/native_map_view_query.cpp
    core/native_map_view/native_map_view_observers.cpp
    
    # Rendering system
    rendering/harmony_renderer.hpp
    rendering/harmony_renderer.cpp
    rendering/harmony_renderer_frontend.hpp
    rendering/harmony_renderer_frontend.cpp
    rendering/backends/harmony_renderer_backend.hpp
    rendering/backends/harmony_renderer_backend.cpp
    rendering/egl/Render.h
    rendering/egl/Render.cpp
    rendering/egl/EGLCore.h
    rendering/egl/EGLCore.cpp
    
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
    napi/bindings/style/style_napi.hpp
    napi/bindings/style/style_napi_base.cpp
    napi/bindings/style/style_napi_layers.cpp
    napi/bindings/style/style_napi_sources.cpp
    
    # Network module
    network/curl_event_loop.hpp
    network/curl_event_loop.cpp
    network/http_file_source_harmony.cpp
    
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
    
    # GeoJSON NAPI 转换层
    geojson/util.hpp
    geojson/util.cpp
    geojson/geometry_napi.hpp
    geojson/geometry_napi.cpp
    geojson/point_napi.hpp
    geojson/point_napi.cpp
    geojson/line_string_napi.hpp
    geojson/line_string_napi.cpp
    geojson/polygon_napi.hpp
    geojson/polygon_napi.cpp
    geojson/multi_point_napi.hpp
    geojson/multi_point_napi.cpp
    geojson/multi_line_string_napi.hpp
    geojson/multi_line_string_napi.cpp
    geojson/multi_polygon_napi.hpp
    geojson/multi_polygon_napi.cpp
    geojson/geometry_collection_napi.hpp
    geojson/geometry_collection_napi.cpp
    geojson/feature_napi.hpp
    geojson/feature_napi.cpp
    geojson/feature_collection_napi.hpp
    geojson/feature_collection_napi.cpp
    
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
    # HarmonyOS i18n files are in mbgl-core (harmony.cmake)
    # ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/i18n/collator.cpp
)

# Conditionally add rendering backend sources
if(MLN_WITH_VULKAN)
    target_sources(
        maplibre_native PRIVATE
            rendering/backends/harmony_vulkan_renderer_backend.hpp
            rendering/backends/harmony_vulkan_renderer_backend.cpp
    )
    message(STATUS "HarmonyOS: Adding Vulkan renderer backend sources")
endif()

if(MLN_WITH_OPENGL)
    target_sources(
        maplibre_native PRIVATE
            rendering/backends/harmony_gl_renderer_backend.hpp
            rendering/backends/harmony_gl_renderer_backend.cpp
    )
    message(STATUS "HarmonyOS: Adding OpenGL renderer backend sources")
endif()


target_include_directories(
  maplibre_native
  PUBLIC ${PROJECT_SOURCE_DIR}
          ../../../../../../src
          ../../../../../../include
          ../../../src
          ../../../../../default/include
          ../../../../../../vendor/maplibre-native-base/include
          ../../../../../../vendor/nunicode/include
          ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/curl/${OHOS_ARCH}/include
          /Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include)


target_link_libraries(maplibre_native
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
)

