target_compile_definitions(
    mbgl-core
    PUBLIC
        MBGL_USE_BUILTIN_ICU
        MLN_RENDER_BACKEND_OPENGL=1
)

# Enable RTTI for Harmony platform (needed for OpenGL renderer backend)
set(MLN_WITH_RTTI ON)

# Override the RTTI flag for this target - remove -fno-rtti and add -frtti
target_compile_options(mbgl-core PRIVATE -frtti)
target_compile_options(mbgl-core PRIVATE $<$<CONFIG:Debug>:-frtti>)
target_compile_options(mbgl-core PRIVATE $<$<CONFIG:Release>:-frtti>)
target_compile_options(mbgl-core PRIVATE $<$<CONFIG:RelWithDebInfo>:-frtti>)
target_compile_options(mbgl-core PRIVATE $<$<CONFIG:MinSizeRel>:-frtti>)

include(${PROJECT_SOURCE_DIR}/vendor/icu.cmake)
include(${PROJECT_SOURCE_DIR}/vendor/sqlite.cmake)
include(${PROJECT_SOURCE_DIR}/vendor/nunicode.cmake)

# cmake-format: off
target_compile_options(mbgl-vendor-csscolorparser PRIVATE $<$<CONFIG:Release>:-Oz> $<$<CONFIG:Release>:-Qunused-arguments> $<$<CONFIG:Release>:-flto>)
target_compile_options(mbgl-vendor-icu PRIVATE $<$<CONFIG:Release>:-Oz> $<$<CONFIG:Release>:-Qunused-arguments> $<$<CONFIG:Release>:-flto>)
target_compile_options(mbgl-vendor-parsedate PRIVATE $<$<CONFIG:Release>:-Oz> $<$<CONFIG:Release>:-Qunused-arguments> $<$<CONFIG:Release>:-flto>)
target_compile_options(mbgl-vendor-sqlite PRIVATE $<$<CONFIG:Release>:-Oz> $<$<CONFIG:Release>:-Qunused-arguments> $<$<CONFIG:Release>:-flto>)
target_compile_options(mbgl-compiler-options INTERFACE $<$<CONFIG:Release>:-Oz> $<$<CONFIG:Release>:-Qunused-arguments> $<$<CONFIG:Release>:-flto>)
# cmake-format: on

target_link_libraries(
    mbgl-compiler-options
    INTERFACE
        $<$<CONFIG:Release>:-O2>
        $<$<CONFIG:Release>:-Wl,--icf=all>
        $<$<CONFIG:Release>:-flto>
        $<$<CONFIG:Release>:-fuse-ld=gold>
)


target_sources(
    mbgl-core
    PRIVATE
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/thread.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/async_task.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/attach_env.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/attach_env.hpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/bitmap.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/bitmap.hpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/bitmap_factory.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/bitmap_factory.hpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/gl_functions.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/image.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/run_loop.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/run_loop_impl.hpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/string_util.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/timer.cpp
        ${PROJECT_SOURCE_DIR}/platform/harmony/src/logging.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/http_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/text/local_glyph_rasterizer.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/i18n/number_format.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/gfx/headless_backend.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/gfx/headless_frontend.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/map/map_snapshotter.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/platform/time.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/asset_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/database_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/file_source_manager.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/file_source_request.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/local_file_request.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/local_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/mbtiles_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/main_resource_loader.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/offline.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/offline_database.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/offline_download.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/online_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/$<IF:$<BOOL:${MLN_WITH_PMTILES}>,pmtiles_file_source.cpp,pmtiles_file_source_stub.cpp>
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/sqlite3.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/text/bidi.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/compression.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/filesystem.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/monotonic_timer.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/png_writer.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/thread_local.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/utf.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/layermanager/layer_manager.cpp
)

# Add OpenGL renderer backend sources
target_sources(
    mbgl-core
    PRIVATE
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/attribute.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/command_encoder.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/context.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/fence.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/debugging_extension.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/enum.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/index_buffer_resource.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/object.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/offscreen_texture.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/render_pass.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/renderbuffer_resource.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/renderer_backend.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/resource_pool.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/timestamp_query_extension.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/uniform.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/upload_pass.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/value.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/vertex_array.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/vertex_buffer_resource.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/buffer_allocator.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/drawable_gl.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/drawable_gl_builder.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/layer_group_gl.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/texture2d.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/uniform_buffer_gl.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/gl/vertex_attribute_gl.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/shaders/gl/shader_info.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/shaders/gl/shader_program_gl.cpp
        ${PROJECT_SOURCE_DIR}/src/mbgl/shaders/gl/legacy/programs.cpp
)

if(MLN_WITH_OPENGL)
    target_sources(
        mbgl-core
        PRIVATE
            ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/gl/headless_backend.cpp
            ${PROJECT_SOURCE_DIR}/platform/linux/src/headless_backend_egl.cpp
    )
endif()

if(MLN_WITH_VULKAN)
    target_sources(
        mbgl-core
        PRIVATE
            ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/vulkan/headless_backend.cpp
    )
endif()

target_include_directories(
    mbgl-core
    PRIVATE ${PROJECT_SOURCE_DIR}/platform/default/include
)

# Add curl include directory for HTTPFileSource
if(EXISTS "${PROJECT_SOURCE_DIR}/platform/harmony/maplibre_harmony/src/main/cpp/thirdparty/curl/${OHOS_ARCH}/include")
    target_include_directories(
        mbgl-core
        PRIVATE ${PROJECT_SOURCE_DIR}/platform/harmony/maplibre_harmony/src/main/cpp/thirdparty/curl/${OHOS_ARCH}/include
    )
endif()

# Add curl library path
if(EXISTS "${PROJECT_SOURCE_DIR}/platform/harmony/maplibre_harmony/src/main/cpp/thirdparty/curl/${OHOS_ARCH}/lib/libcurl.so")
    target_link_libraries(
        mbgl-core
        PRIVATE
            EGL
            GLESv3
            mbgl-vendor-icu
            mbgl-vendor-sqlite
            mbgl-vendor-nunicode
            z
            hilog_ndk.z
            uv
            ace_ndk.z
            native_window
            vulkan
            ${PROJECT_SOURCE_DIR}/platform/harmony/maplibre_harmony/src/main/cpp/thirdparty/curl/${OHOS_ARCH}/lib/libcurl.so
    )
else()
    target_link_libraries(
        mbgl-core
        PRIVATE
            EGL
            GLESv3
            mbgl-vendor-icu
            mbgl-vendor-sqlite
            mbgl-vendor-nunicode
            z
            hilog_ndk.z
            uv
            ace_ndk.z
            native_window
            vulkan
    )
endif()

# this is needed because Android is not officially supported
# https://discourse.cmake.org/t/error-when-crosscompiling-with-whole-archive-target-link/9394
# https://cmake.org/cmake/help/latest/release/3.24.html#generator-expressions
set(CMAKE_LINK_LIBRARY_USING_WHOLE_ARCHIVE
"-Wl,--whole-archive <LIBRARY>-Wl,--no-whole-archive"
)
set(CMAKE_LINK_LIBRARY_USING_WHOLE_ARCHIVE_SUPPORTED True)

find_package(curl CONFIG)


install(TARGETS  LIBRARY DESTINATION lib)

