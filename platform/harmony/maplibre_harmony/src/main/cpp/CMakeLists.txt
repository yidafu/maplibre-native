# the minimum version of CMake.
cmake_minimum_required(VERSION 3.12)
project(harmony)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20")
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "OHOS")
    # 鸿蒙系统特定的 C++20 设置
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20 -fPIC")
    # 忽略未使用的命令行参数警告
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error=unused-command-line-argument")
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


add_library(maplibre_harmony_loop STATIC)
target_sources(
    maplibre_harmony_loop
    PRIVATE
        ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/util/async_task.cpp
        ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/util/run_loop.cpp
        ${MBGL_SOURCE_DIR}/platform/default/src/mbgl/util/timer.cpp
)

target_include_directories(
    maplibre_harmony_loop
    PUBLIC
        ${MBGL_SOURCE_DIR}/include
        ${MBGL_SOURCE_DIR}/platform/default/include
        ${MBGL_SOURCE_DIR}/src
        ${MBGL_SOURCE_DIR}/vendor/maplibre-native-base/include
    PRIVATE ${LIBUV_INCLUDE_DIRS}
)

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
    common.h
#    native_map_view_harmony.cpp
#    native_map_view_harmony.hpp
    )



target_include_directories(
  maplibre_harmony
  PRIVATE ${PROJECT_SOURCE_DIR}
          ../../../../../../src
          ../../../../../../include
          ../../../src
          ../../../../../default/include
          ../../../../../../vendor/maplibre-native-base/include)


target_link_libraries(maplibre_harmony
#    INTERFACE maplibre_harmony_loop
#    INTERFACE Mapbox::Map
PUBLIC
    mbgl-core
    mbgl-vendor-unique_resource
    ace_napi.z
    hilog_ndk.z
    uv
    ace_ndk.z
    GLESv3
    EGL
    native_window
    vulkan
)

install(TARGETS maplibre_harmony LIBRARY DESTINATION lib)
