# MapLibre Harmony Debug Tools CMake Configuration

set(DEBUG_SOURCES
    style_loading_debugger.cpp
    resource_monitor.cpp
)

set(DEBUG_HEADERS
    style_loading_debugger.hpp
    resource_monitor.hpp
)

# Create debug tools library
add_library(maplibre_harmony_debug STATIC
    ${DEBUG_SOURCES}
)

target_include_directories(maplibre_harmony_debug
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/..
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/src
)

target_compile_features(maplibre_harmony_debug
    PUBLIC
        cxx_std_17
)

target_compile_options(maplibre_harmony_debug
    PRIVATE
        -Wall
        -Wextra
        $<$<CONFIG:Debug>:-DMAPLIBRE_DEBUG=1>
)

# Link with mbgl utilities
target_link_libraries(maplibre_harmony_debug
    PUBLIC
        mbgl-core
)

# Install headers
install(FILES ${DEBUG_HEADERS}
    DESTINATION include/maplibre/harmony/debug
)

# For Debug builds only
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "MapLibre Debug Tools enabled")
    add_compile_definitions(MAPLIBRE_DEBUG=1)
else()
    message(STATUS "MapLibre Debug Tools disabled (Release build)")
endif()

