# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(harmony)

ADD_DEFINITIONS(-DVK_USE_PLATFORM_OHOS=1)
ADD_DEFINITIONS(-DOHOS_PLATFORM)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
set(MBGL_SOURCE_DIR "/Users/yidafu/github/maplibre-native")

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

#add_library(maplibre_harmony_loop STATIC)
#
#target_sources(
#    maplibre_harmony_loop
#    PRIVATE
#        ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/util/async_task.cpp
#        ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/util/run_loop.cpp
#        ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/util/timer.cpp
#)
#
#target_include_directories(
#    maplibre_harmony_loop
#    PUBLIC
#        ${MBGL_SOURCE_DIR}/include
#        ${MBGL_SOURCE_DIR}/platform/default/include
#        ${MBGL_SOURCE_DIR}/src
#    PRIVATE ${LIBUV_INCLUDE_DIRS}
#)

#target_link_libraries(
#    maplibre_harmony_loop
#    PUBLIC
#        MapLibreNative::Base
#)
add_library(maplibre_harmony
    SHARED
    #map_napi.cpp
    napi_init.cpp
    PluginManager.h
    PluginManager.cpp
    Render.h
    Render.cpp
    EGLCore.h
    EGLCore.cpp
    common.h)

find_library(
    # Sets the name of the path variable.
    hilog-lib
    # Specifies the name of the NDK library that
    # you want CMake to locate.
    hilog_ndk.z
)

target_link_libraries(maplibre_harmony
#    INTERFACE maplibre_harmony_loop
#    INTERFACE Mapbox::Map
PUBLIC libace_napi.z.so
    ${hilog-lib}
    libuv.so
    libace_ndk.z.so
    libace_napi.z.so
    libGLESv3.so
    libEGL.so
    libnative_window.so
    libvulkan.so)