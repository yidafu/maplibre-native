/**
 * MapSnapshot NAPI Bindings for HarmonyOS
 * 
 * Wraps MapSnapshot objects and exposes coordinate conversion helpers.
 * Reference: platform/android/MapLibreAndroid/src/cpp/snapshotter/map_snapshot.hpp
 */

#pragma once

#include <mbgl/map/map_snapshotter.hpp>
#include <mbgl/util/image.hpp>
#include <mbgl/util/geo.hpp>
#include <napi/native_api.h>

#include <memory>
#include <vector>
#include <string>
#include <functional>

namespace mbgl {
namespace harmony {

/**
 * MapSnapshotInstance - NAPI wrapper around MapSnapshot
 *
 * Stores snapshot image data and coordinate conversion helpers.
 */
class MapSnapshotInstance {
public:
    /**
     * Constructor.
     */
    MapSnapshotInstance(
        napi_env env,
        mbgl::PremultipliedImage&& image,
        const std::vector<std::string>& attributions,
        float pixelRatio,
        mbgl::MapSnapshotter::PointForFn pointForFn,
        mbgl::MapSnapshotter::LatLngForFn latLngForFn
    );

    ~MapSnapshotInstance();

    /**
     * Retrieve the image data.
     */
    const mbgl::PremultipliedImage& getImage() const { return image_; }

    /**
     * Retrieve the image width.
     */
    uint32_t getWidth() const { return image_.size.width; }

    /**
     * Retrieve the image height.
     */
    uint32_t getHeight() const { return image_.size.height; }

    /**
     * Retrieve attribution strings.
     */
    const std::vector<std::string>& getAttributions() const { return attributions_; }

    /**
     * Retrieve the pixel ratio.
     */
    float getPixelRatio() const { return pixelRatio_; }

    /**
     * Convert geographic coordinates to image pixel coordinates.
     */
    mbgl::ScreenCoordinate pixelForLatLng(const mbgl::LatLng& latLng) const;

    /**
     * Convert image pixel coordinates to geographic coordinates.
     */
    mbgl::LatLng latLngForPixel(const mbgl::ScreenCoordinate& point) const;

private:
    napi_env env_;
    mbgl::PremultipliedImage image_;
    std::vector<std::string> attributions_;
    float pixelRatio_;
    mbgl::MapSnapshotter::PointForFn pointForFn_;
    mbgl::MapSnapshotter::LatLngForFn latLngForFn_;
};

/**
 * Create a MapSnapshot NAPI object.
 *
 * @param env NAPI environment
 * @param image Snapshot image data
 * @param attributions Attribution strings
 * @param pixelRatio Image pixel ratio
 * @param pointForFn Coordinate conversion function (geographic → screen)
 * @param latLngForFn Coordinate conversion function (screen → geographic)
 * @return Created NAPI object
 */
napi_value CreateMapSnapshotObject(
    napi_env env,
    mbgl::PremultipliedImage&& image,
    const std::vector<std::string>& attributions,
    float pixelRatio,
    mbgl::MapSnapshotter::PointForFn pointForFn,
    mbgl::MapSnapshotter::LatLngForFn latLngForFn
);

/**
 * MapSnapshot NAPI helper: geographic coordinates → image pixels.
 */
napi_value MapSnapshot_pixelForLatLng(napi_env env, napi_callback_info info);

/**
 * MapSnapshot NAPI helper: image pixels → geographic coordinates.
 */
napi_value MapSnapshot_latLngForPixel(napi_env env, napi_callback_info info);

} // namespace harmony
} // namespace mbgl

