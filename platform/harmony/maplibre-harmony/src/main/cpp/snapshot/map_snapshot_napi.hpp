/**
 * MapSnapshot NAPI Bindings for HarmonyOS
 * 
 * Wraps MapSnapshot objects and exposes coordinate conversion helpers.
 * Reference: platform/android/MapLibreAndroid/src/cpp/snapshotter/map_snapshot.hpp
 */

#pragma once

#include <mln/map/map_snapshotter.hpp>
#include <mln/util/image.hpp>
#include <mln/util/geo.hpp>
#include <napi/native_api.h>

#include <memory>
#include <vector>
#include <string>
#include <functional>

namespace mln {
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
        mln::PremultipliedImage&& image,
        const std::vector<std::string>& attributions,
        float pixelRatio,
        mln::MapSnapshotter::PointForFn pointForFn,
        mln::MapSnapshotter::LatLngForFn latLngForFn
    );

    ~MapSnapshotInstance();

    /**
     * Retrieve the image data.
     */
    const mln::PremultipliedImage& getImage() const { return image_; }

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
    mln::ScreenCoordinate pixelForLatLng(const mln::LatLng& latLng) const;

    /**
     * Convert image pixel coordinates to geographic coordinates.
     */
    mln::LatLng latLngForPixel(const mln::ScreenCoordinate& point) const;

private:
    napi_env env_;
    mln::PremultipliedImage image_;
    std::vector<std::string> attributions_;
    float pixelRatio_;
    mln::MapSnapshotter::PointForFn pointForFn_;
    mln::MapSnapshotter::LatLngForFn latLngForFn_;
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
    mln::PremultipliedImage&& image,
    const std::vector<std::string>& attributions,
    float pixelRatio,
    mln::MapSnapshotter::PointForFn pointForFn,
    mln::MapSnapshotter::LatLngForFn latLngForFn
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
} // namespace mln

