/**
 * MapSnapshot NAPI Bindings for HarmonyOS - Implementation
 */

#include "map_snapshot_napi.hpp"
#include "../utils/logger.h"
#include "../geometry/lat_lng_harmony.hpp"
#include "../geometry/point_harmony.hpp"
#include "../napi/core/napi_args.hpp"

#include <mbgl/util/geo.hpp>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

// ==================== MapSnapshotInstance implementation ====================

MapSnapshotInstance::MapSnapshotInstance(
    napi_env env,
    mbgl::PremultipliedImage&& image,
    const std::vector<std::string>& attributions,
    float pixelRatio,
    mbgl::MapSnapshotter::PointForFn pointForFn,
    mbgl::MapSnapshotter::LatLngForFn latLngForFn
) : env_(env),
    image_(std::move(image)),
    attributions_(attributions),
    pixelRatio_(pixelRatio),
    pointForFn_(pointForFn),
    latLngForFn_(latLngForFn) {
    
    Logger::info("MapSnapshotInstance", "Created: %dx%d, pixelRatio=%.2f, %zu attributions",
                 image_.size.width, image_.size.height, pixelRatio_, attributions_.size());
}

MapSnapshotInstance::~MapSnapshotInstance() {
    Logger::info("MapSnapshotInstance", "Destroyed");
}

mbgl::ScreenCoordinate MapSnapshotInstance::pixelForLatLng(const mbgl::LatLng& latLng) const {
    if (!pointForFn_) {
        Logger::error("MapSnapshotInstance", "pointForFn is null");
        return mbgl::ScreenCoordinate{0, 0};
    }
    
    // Call the conversion function and apply the pixel ratio
    mbgl::ScreenCoordinate point = pointForFn_(latLng);
    return mbgl::ScreenCoordinate{point.x * pixelRatio_, point.y * pixelRatio_};
}

mbgl::LatLng MapSnapshotInstance::latLngForPixel(const mbgl::ScreenCoordinate& point) const {
    if (!latLngForFn_) {
        Logger::error("MapSnapshotInstance", "latLngForFn is null");
        return mbgl::LatLng{0, 0};
    }
    
    // Divide by the pixel ratio before converting back
    mbgl::ScreenCoordinate adjustedPoint{point.x / pixelRatio_, point.y / pixelRatio_};
    return latLngForFn_(adjustedPoint);
}

// ==================== NAPI object creation ====================

napi_value CreateMapSnapshotObject(
    napi_env env,
    mbgl::PremultipliedImage&& image,
    const std::vector<std::string>& attributions,
    float pixelRatio,
    mbgl::MapSnapshotter::PointForFn pointForFn,
    mbgl::MapSnapshotter::LatLngForFn latLngForFn
) {
    // Allocate the MapSnapshotInstance
    auto* snapshotInstance = new MapSnapshotInstance(
        env,
        std::move(image),
        attributions,
        pixelRatio,
        pointForFn,
        latLngForFn
    );

    // Create an ArrayBuffer for the image data
    void* data;
    napi_value arrayBuffer;
    size_t byteLength = snapshotInstance->getImage().bytes();
    napi_create_arraybuffer(env, byteLength, &data, &arrayBuffer);
    std::memcpy(data, snapshotInstance->getImage().data.get(), byteLength);

    // Create the JavaScript object
    napi_value jsSnapshot;
    napi_create_object(env, &jsSnapshot);

    // Wrap the native pointer
    napi_wrap(env, jsSnapshot, snapshotInstance,
              [](napi_env env, void* data, void* hint) {
                  delete static_cast<MapSnapshotInstance*>(data);
              },
              nullptr, nullptr);

    // Set object properties
    napi_value widthVal, heightVal, pixelRatioVal;
    napi_create_uint32(env, snapshotInstance->getWidth(), &widthVal);
    napi_create_uint32(env, snapshotInstance->getHeight(), &heightVal);
    napi_create_double(env, pixelRatio, &pixelRatioVal);

    napi_set_named_property(env, jsSnapshot, "data", arrayBuffer);
    napi_set_named_property(env, jsSnapshot, "width", widthVal);
    napi_set_named_property(env, jsSnapshot, "height", heightVal);
    napi_set_named_property(env, jsSnapshot, "pixelRatio", pixelRatioVal);

    // Add the attributions array
    if (!attributions.empty()) {
        napi_value attributionsArray;
        napi_create_array_with_length(env, attributions.size(), &attributionsArray);
        
        for (size_t i = 0; i < attributions.size(); i++) {
            napi_value attrValue;
            napi_create_string_utf8(env, attributions[i].c_str(), NAPI_AUTO_LENGTH, &attrValue);
            napi_set_element(env, attributionsArray, i, attrValue);
        }
        
        napi_set_named_property(env, jsSnapshot, "attributions", attributionsArray);
    }

    // Bind methods
    napi_property_descriptor methods[] = {
        {"pixelForLatLng", nullptr, MapSnapshot_pixelForLatLng, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"latLngForPixel", nullptr, MapSnapshot_latLngForPixel, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    napi_define_properties(env, jsSnapshot, sizeof(methods) / sizeof(methods[0]), methods);

    Logger::info("MapSnapshotNAPI", "MapSnapshot object created with coordinate conversion methods");

    return jsSnapshot;
}

// ==================== NAPI method implementations ====================

/**
 * MapSnapshot.pixelForLatLng(latitude, longitude)
 * 
 * Mirrors Android: MapSnapshot.pixelForLatLng(LatLng)
 */
napi_value MapSnapshot_pixelForLatLng(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return args.Undefined();

    // Retrieve the MapSnapshotInstance
    MapSnapshotInstance* snapshotInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotInstance)) != napi_ok ||
        !snapshotInstance) {
        Logger::error("MapSnapshot", "pixelForLatLng: Failed to unwrap instance");
        return args.Undefined();
    }

    // Parse arguments
    double latitude = args.GetDouble(0, "latitude");
    double longitude = args.GetDouble(1, "longitude");
    if (args.HasError()) return args.Undefined();

    try {
        // Perform coordinate conversion
        mbgl::LatLng latLng(latitude, longitude);
        mbgl::ScreenCoordinate pixel = snapshotInstance->pixelForLatLng(latLng);

        // Create the return object {x, y}
        napi_value result = PointHarmony::CreatePointObject(env, pixel);
        return result;
        
    } catch (const std::exception& e) {
        Logger::error("MapSnapshot", "pixelForLatLng: Failed - %s", e.what());
        return args.Undefined();
    }
}

/**
 * MapSnapshot.latLngForPixel(x, y)
 * 
 * Mirrors Android: MapSnapshot.latLngForPixel(PointF)
 */
napi_value MapSnapshot_latLngForPixel(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return args.Undefined();

    // Retrieve the MapSnapshotInstance
    MapSnapshotInstance* snapshotInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotInstance)) != napi_ok ||
        !snapshotInstance) {
        Logger::error("MapSnapshot", "latLngForPixel: Failed to unwrap instance");
        return args.Undefined();
    }

    // Parse arguments
    double x = args.GetDouble(0, "x");
    double y = args.GetDouble(1, "y");
    if (args.HasError()) return args.Undefined();

    try {
        // Perform coordinate conversion
        mbgl::ScreenCoordinate point(x, y);
        mbgl::LatLng latLng = snapshotInstance->latLngForPixel(point);

        // Create the return object {latitude, longitude}
        napi_value result = LatLngHarmony::CreateLatLngObject(env, latLng);
        return result;
        
    } catch (const std::exception& e) {
        Logger::error("MapSnapshot", "latLngForPixel: Failed - %s", e.what());
        return args.Undefined();
    }
}

} // namespace harmony
} // namespace mbgl

