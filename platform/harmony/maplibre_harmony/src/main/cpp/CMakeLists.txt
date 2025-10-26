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
    napi_init.cpp
    napi_utils.h
    napi_utils.cpp
    napi_utils_ext.cpp
    napi_args.hpp
    napi_args.cpp
    logger.h
    logger.cpp
    curl_event_loop.hpp
    curl_event_loop.cpp
    http_file_source_harmony.cpp
    harmony_renderer_backend.hpp
    harmony_renderer_backend.cpp
    harmony_renderer_frontend.hpp
    harmony_renderer_frontend.cpp
    harmony_vsync_manager.hpp
    harmony_vsync_manager.cpp
    harmony_renderer.hpp
    harmony_renderer.cpp
    Render.h
    Render.cpp
    EGLCore.h
    EGLCore.cpp
    common.h
    native_map_view_harmony.cpp
    native_map_view_harmony.hpp
    # Annotation API 绑定
    marker_napi.cpp
    marker_napi.hpp
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
    # Style API 绑定
    style/style_harmony.hpp
    style/style_harmony.cpp
    style/transition_options_harmony.hpp
    style/transition_options_harmony.cpp
    style/sources/geojson_source_harmony.hpp
    style/sources/geojson_source_harmony.cpp
    style/sources/vector_source_harmony.hpp
    style/sources/vector_source_harmony.cpp
    style/sources/raster_source_harmony.hpp
    style/sources/raster_source_harmony.cpp
    style/layers/fill_layer_harmony.hpp
    style/layers/fill_layer_harmony.cpp
    style/layers/line_layer_harmony.hpp
    style/layers/line_layer_harmony.cpp
    style/layers/circle_layer_harmony.hpp
    style/layers/circle_layer_harmony.cpp
    # HarmonyOS i18n files are in mbgl-core (harmony.cmake)
    # ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/i18n/collator.cpp
)

# Conditionally add rendering backend sources
if(MLN_WITH_VULKAN)
    target_sources(
        maplibre_native PRIVATE
            harmony_vulkan_renderer_backend.hpp
            harmony_vulkan_renderer_backend.cpp
    )
    message(STATUS "HarmonyOS: Adding Vulkan renderer backend sources")
endif()

if(MLN_WITH_OPENGL)
    target_sources(
        maplibre_native PRIVATE
            harmony_gl_renderer_backend.hpp
            harmony_gl_renderer_backend.cpp
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

