#include "style_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include <mbgl/style/style.hpp>
#include <mbgl/style/source.hpp>
#include <mbgl/style/layer.hpp>
// Source NAPI classes
#include "sources/geojson_source_napi.hpp"
#include "sources/vector_source_napi.hpp"
#include "sources/raster_source_napi.hpp"
#include "sources/raster_dem_source_napi.hpp"
#include "sources/image_source_napi.hpp"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

// Static member initialization
napi_ref StyleNAPI::constructor = nullptr;

StyleNAPI::StyleNAPI(mbgl::Map *map) : map(map), fullyLoaded(false) {
    Logger::info("StyleNAPI", "StyleNAPI instance created");
}

StyleNAPI::~StyleNAPI() { Logger::info("StyleNAPI", "StyleNAPI instance destroyed"); }

void StyleNAPI::Destructor(napi_env env, void *nativeObject, void *finalize_hint) {
    StyleNAPI *style = static_cast<StyleNAPI *>(nativeObject);
    delete style;
}

napi_value StyleNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("StyleNAPI", "========== Initializing Style NAPI class ==========");

    napi_property_descriptor properties[] = {
        // Getters
        {"getUri", nullptr, GetUri, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getJson", nullptr, GetJson, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isFullyLoaded", nullptr, IsFullyLoaded, nullptr, nullptr, nullptr, napi_default, nullptr},

        // Source management
        {"addSource", nullptr, AddSource, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeSource", nullptr, RemoveSource, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getSource", nullptr, GetSource, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getSources", nullptr, GetSources, nullptr, nullptr, nullptr, napi_default, nullptr},

        // Layer management
        {"addLayer", nullptr, AddLayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addLayerBelow", nullptr, AddLayerBelow, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addLayerAbove", nullptr, AddLayerAbove, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addLayerAt", nullptr, AddLayerAt, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeLayer", nullptr, RemoveLayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeLayerAt", nullptr, RemoveLayerAt, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLayer", nullptr, GetLayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLayers", nullptr, GetLayers, nullptr, nullptr, nullptr, napi_default, nullptr},

        // Image management
        {"addImage", nullptr, AddImage, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addImageAsync", nullptr, AddImageAsync, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addImagesAsync", nullptr, AddImagesAsync, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeImage", nullptr, RemoveImage, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getImage", nullptr, GetImage, nullptr, nullptr, nullptr, napi_default, nullptr},

        // Light & Transition
        {"getLight", nullptr, GetLight, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setLight", nullptr, SetLight, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getTransition", nullptr, GetTransition, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTransition", nullptr, SetTransition, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    Logger::info("StyleNAPI", "Defining Style class with %zu methods", sizeof(properties) / sizeof(properties[0]));

    napi_value cons;
    napi_status status = napi_define_class(env, "Style", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);

    if (status != napi_ok) {
        Logger::error("StyleNAPI", "Failed to define Style class, status=%d", status);
        return nullptr;
    }
    Logger::info("StyleNAPI", "Style class defined successfully");

    // Create the constructor reference
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("StyleNAPI", "Failed to create constructor reference, status=%d", status);
        return nullptr;
    }
    Logger::info("StyleNAPI", "Constructor reference created: %p", constructor);

    // Add the constructor to exports
    status = napi_set_named_property(env, exports, "Style", cons);
    if (status != napi_ok) {
        Logger::error("StyleNAPI", "Failed to set Style property, status=%d", status);
        return nullptr;
    }

    Logger::info("StyleNAPI", "========== Style NAPI class initialized successfully ==========");
    return exports;
}

napi_value StyleNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();

    napi_value mapPtrValue = napiArgs.GetValue(0);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    int64_t mapPtr = 0;
    napi_status status = napi_ok;
    napi_valuetype valueType;
    napi_typeof(env, mapPtrValue, &valueType);

    if (valueType == napi_number) {
        status = napi_get_value_int64(env, mapPtrValue, &mapPtr);
    } else if (valueType == napi_bigint) {
        bool lossless = true;
        status = napi_get_value_bigint_int64(env, mapPtrValue, &mapPtr, &lossless);
        if (status == napi_ok && !lossless) {
            Logger::warn("StyleNAPI", "mapPtr bigint conversion was not lossless");
        }
    } else {
        napi_throw_type_error(env, nullptr, "mapPtr must be a number or BigInt");
        return nullptr;
    }

    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to parse mapPtr argument");
        return nullptr;
    }

    mbgl::Map *map = reinterpret_cast<mbgl::Map *>(mapPtr);
    if (!map) {
        napi_throw_error(env, nullptr, "Invalid mapPtr");
        return nullptr;
    }

    // Create the C++ object
    StyleNAPI *style = new StyleNAPI(map);

    // Wrap into the JS object
    status = napi_wrap(env, jsThis, style, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete style;
        napi_throw_error(env, nullptr, "Failed to wrap StyleNAPI object");
        return nullptr;
    }

    return jsThis;
}

// ==================== Getters ====================

napi_value StyleNAPI::GetUri(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->map) {
        return CreateStringValue(env, "");
    }

    try {
        std::string uri = style->map->getStyle().getURL();
        return CreateStringValue(env, uri);
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "GetUri failed: %s", e.what());
        return CreateStringValue(env, "");
    }
}

napi_value StyleNAPI::GetJson(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->map) {
        return CreateStringValue(env, "");
    }

    try {
        std::string json = style->map->getStyle().getJSON();
        return CreateStringValue(env, json);
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "GetJson failed: %s", e.what());
        return CreateStringValue(env, "");
    }
}

napi_value StyleNAPI::IsFullyLoaded(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style) {
        return CreateBoolValue(env, false);
    }

    return CreateBoolValue(env, style->fullyLoaded);
}

// ==================== Source management ====================

napi_value StyleNAPI::AddSource(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->map) {
        Logger::error("StyleNAPI", "AddSource: Invalid style or map");
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    napi_value sourceValue = napiArgs.GetObject(0, "source");
    if (napiArgs.HasError()) {
        return nullptr;
    }

    std::string sourceId;
    bool sourceAdded = false;
    napi_status status;

    // First check the _TYPE_ property to determine the actual type
    napi_value typeValue;
    std::string sourceType;
    status = napi_get_named_property(env, sourceValue, "_TYPE_", &typeValue);
    if (status == napi_ok) {
        size_t typeLen;
        napi_get_value_string_utf8(env, typeValue, nullptr, 0, &typeLen);
        if (typeLen > 0) {
            char *typeBuffer = new char[typeLen + 1];
            napi_get_value_string_utf8(env, typeValue, typeBuffer, typeLen + 1, nullptr);
            sourceType = std::string(typeBuffer);
            delete[] typeBuffer;
            Logger::info("StyleNAPI", "AddSource: Detected type = %s", sourceType.c_str());
        }
    }

    // 1. Try GeoJsonSource
    if (sourceType == "GeoJsonSource" || sourceType.empty()) {
        GeoJsonSourceNAPI *geoJsonSource = nullptr;
        status = napi_unwrap(env, sourceValue, reinterpret_cast<void **>(&geoJsonSource));
        if (status == napi_ok && geoJsonSource) {
            try {
                sourceId = geoJsonSource->getId();
                auto source = geoJsonSource->releaseSource();
                if (!source) {
                    napi_throw_error(env, nullptr, "Source already added to style");
                    return nullptr;
                }
                style->map->getStyle().addSource(std::move(source));
                style->sources[sourceId] = true;
                sourceAdded = true;

                // Important: after adding to the style, allow GeoJsonSourceNAPI to store the source pointer retrieved from the style
                auto *styleSource = style->map->getStyle().getSource(sourceId);
                if (styleSource && styleSource->getType() == mbgl::style::SourceType::GeoJSON) {
                    geoJsonSource->attachToStyle(static_cast<mbgl::style::GeoJSONSource *>(styleSource));
                }

                Logger::info("StyleNAPI", "AddSource (GeoJsonSource): %s", sourceId.c_str());
                return napiArgs.Undefined();
            } catch (const std::exception &e) {
                Logger::error("StyleNAPI", "AddSource (GeoJsonSource) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }

    // 2. Try VectorSource
    if (!sourceAdded && (sourceType == "VectorSource" || sourceType.empty())) {
        VectorSourceNAPI *vectorSource = nullptr;
        status = napi_unwrap(env, sourceValue, reinterpret_cast<void **>(&vectorSource));
        if (status == napi_ok && vectorSource) {
            try {
                sourceId = vectorSource->getId();
                auto source = vectorSource->releaseSource();
                if (!source) {
                    napi_throw_error(env, nullptr, "Source already added to style");
                    return nullptr;
                }
                style->map->getStyle().addSource(std::move(source));
                style->sources[sourceId] = true;
                sourceAdded = true;

                // Create a WeakPtr
                auto *styleSource = style->map->getStyle().getSource(sourceId);
                if (styleSource && styleSource->getType() == mbgl::style::SourceType::Vector) {
                    vectorSource->attachToStyle(static_cast<mbgl::style::VectorSource *>(styleSource));
                }

                Logger::info("StyleNAPI", "AddSource (VectorSource): %s", sourceId.c_str());
                return napiArgs.Undefined();
            } catch (const std::exception &e) {
                Logger::error("StyleNAPI", "AddSource (VectorSource) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }

    // 3. RasterSource
    if (!sourceAdded && (sourceType == "RasterSource" || sourceType.empty())) {
        RasterSourceNAPI *rasterSource = nullptr;
        status = napi_unwrap(env, sourceValue, reinterpret_cast<void **>(&rasterSource));
        if (status == napi_ok && rasterSource) {
            try {
                sourceId = rasterSource->getId();
                auto source = rasterSource->releaseSource();
                if (!source) {
                    napi_throw_error(env, nullptr, "Source already added to style");
                    return nullptr;
                }
                style->map->getStyle().addSource(std::move(source));
                style->sources[sourceId] = true;
                sourceAdded = true;

                // Create a WeakPtr
                auto *styleSource = style->map->getStyle().getSource(sourceId);
                if (styleSource && styleSource->getType() == mbgl::style::SourceType::Raster) {
                    rasterSource->attachToStyle(static_cast<mbgl::style::RasterSource *>(styleSource));
                }

                Logger::info("StyleNAPI", "AddSource (RasterSource): %s", sourceId.c_str());
                return napiArgs.Undefined();
            } catch (const std::exception &e) {
                Logger::error("StyleNAPI", "AddSource (RasterSource) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }

    // 4. RasterDemSource
    if (!sourceAdded && (sourceType == "RasterDemSource" || sourceType.empty())) {
        RasterDemSourceNAPI *rasterDemSource = nullptr;
        status = napi_unwrap(env, sourceValue, reinterpret_cast<void **>(&rasterDemSource));
        if (status == napi_ok && rasterDemSource) {
            try {
                sourceId = rasterDemSource->getId();
                auto source = rasterDemSource->releaseSource();
                if (!source) {
                    napi_throw_error(env, nullptr, "Source already added to style");
                    return nullptr;
                }
                style->map->getStyle().addSource(std::move(source));
                style->sources[sourceId] = true;
                sourceAdded = true;

                // Create a WeakPtr
                auto *styleSource = style->map->getStyle().getSource(sourceId);
                if (styleSource && styleSource->getType() == mbgl::style::SourceType::RasterDEM) {
                    rasterDemSource->attachToStyle(static_cast<mbgl::style::RasterDEMSource *>(styleSource));
                }

                Logger::info("StyleNAPI", "AddSource (RasterDemSource): %s", sourceId.c_str());
                return napiArgs.Undefined();
            } catch (const std::exception &e) {
                Logger::error("StyleNAPI", "AddSource (RasterDemSource) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }

    // 5. ImageSource
    if (!sourceAdded) {
        ImageSourceNAPI *imageSource = nullptr;
        status = napi_unwrap(env, sourceValue, reinterpret_cast<void **>(&imageSource));
        if (status == napi_ok && imageSource) {
            try {
                sourceId = imageSource->getId();
                auto source = imageSource->releaseSource();
                if (!source) {
                    napi_throw_error(env, nullptr, "Source already added to style");
                    return nullptr;
                }
                style->map->getStyle().addSource(std::move(source));
                style->sources[sourceId] = true;
                sourceAdded = true;

                // Create a WeakPtr
                auto *styleSource = style->map->getStyle().getSource(sourceId);
                if (styleSource && styleSource->getType() == mbgl::style::SourceType::Image) {
                    imageSource->attachToStyle(static_cast<mbgl::style::ImageSource *>(styleSource));
                }

                Logger::info("StyleNAPI", "AddSource (ImageSource): %s", sourceId.c_str());
                return napiArgs.Undefined();
            } catch (const std::exception &e) {
                Logger::error("StyleNAPI", "AddSource (ImageSource) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }

    // If no source type succeeded in being added
    if (!sourceAdded) {
        Logger::error("StyleNAPI", "AddSource: Unknown source type or source is null");
        napi_throw_error(env, nullptr, "Unknown source type or source object");
        return nullptr;
    }

    return napiArgs.Undefined();
}

} // namespace harmony
} // namespace maplibre
