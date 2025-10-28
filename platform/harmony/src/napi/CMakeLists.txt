# MapLibre Harmony NAPI CMake Configuration

# Check if debug NAPI should be included
option(MAPLIBRE_DEBUG_NAPI "Include debug NAPI functions" ON)

set(NAPI_SOURCES
    # ... existing NAPI sources ...
)

set(NAPI_HEADERS
    # ... existing NAPI headers ...
)

# Add debug NAPI if enabled
if(MAPLIBRE_DEBUG_NAPI AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND NAPI_SOURCES debug_napi.cpp)
    list(APPEND NAPI_HEADERS debug_napi.hpp)
    message(STATUS "Debug NAPI functions enabled")
endif()

# Create NAPI library
add_library(maplibre_napi SHARED
    ${NAPI_SOURCES}
)

target_include_directories(maplibre_napi
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/..
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/src
        ${OHOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_libraries(maplibre_napi
    PRIVATE
        mbgl-core
        maplibre_harmony_core
)

# Link debug tools if enabled
if(MAPLIBRE_DEBUG_NAPI AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_link_libraries(maplibre_napi
        PRIVATE
            maplibre_harmony_debug
    )
endif()

# Set output name
set_target_properties(maplibre_napi PROPERTIES
    OUTPUT_NAME "maplibre_native"
    PREFIX ""
)

