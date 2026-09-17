/**
 * MapSnapshotter for HarmonyOS
 * 
 * Wraps mbgl::MapSnapshotter to provide snapshot functionality on HarmonyOS.
 */

#pragma once

#include <mbgl/map/camera.hpp>
#include <mbgl/map/map_snapshotter.hpp>
#include <mbgl/util/geo.hpp>
#include <mbgl/util/image.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/util/client_options.hpp>
#include <napi/native_api.h>

#include <memory>
#include <string>
#include <functional>
#include <optional>

namespace mbgl {
namespace harmony {

/**
 * MapSnapshotterHarmony - Harmony platform snapshotter
 *
 * Matches Android's MapSnapshotter and iOS's MLNMapSnapshotter.
 */
class MapSnapshotterHarmony final : public mbgl::MapSnapshotterObserver {
public:
    /**
     * Snapshot options.
     */
    struct SnapshotOptions {
        uint32_t width;
        uint32_t height;
        float pixelRatio;
        std::string styleURL;
        std::optional<std::string> styleJSON;
        std::optional<mbgl::CameraOptions> camera;
        std::optional<mbgl::LatLngBounds> region;
        bool showLogo;
        std::string localFontFamily;
    };

    /**
     * Snapshot callback signature.
     *
     * Parameters:
     * - exception_ptr: error information (if any)
     * - PremultipliedImage: image data
     * - vector<string>: attribution strings
     * - PointForFn: geographic → screen coordinate conversion
     * - LatLngForFn: screen → geographic coordinate conversion
     */
    using SnapshotCallback = std::function<void(
        std::exception_ptr,
        mbgl::PremultipliedImage,
        std::vector<std::string>,
        mbgl::MapSnapshotter::PointForFn,
        mbgl::MapSnapshotter::LatLngForFn
    )>;

    /**
     * Constructor.
     *
     * @param options Snapshot options
     * @param resourceOptions Resource options
     * @param clientOptions Client options
     */
    MapSnapshotterHarmony(
        const SnapshotOptions& options,
        const mbgl::ResourceOptions& resourceOptions,
        const mbgl::ClientOptions& clientOptions = mbgl::ClientOptions()
    );

    ~MapSnapshotterHarmony();

    /**
     * Set the style URL.
     */
    void setStyleURL(const std::string& styleURL);
    
    /**
     * Get the style URL.
     */
    std::string getStyleURL() const;

    /**
     * Set the style JSON.
     */
    void setStyleJSON(const std::string& styleJSON);
    
    /**
     * Get the style JSON.
     */
    std::string getStyleJSON() const;

    /**
     * Set the snapshot size.
     */
    void setSize(const mbgl::Size& size);
    
    /**
     * Get the snapshot size.
     */
    mbgl::Size getSize() const;

    /**
     * Get the pixel ratio configured for this snapshotter.
     */
    float getPixelRatio() const;

    /**
     * Set camera options.
     */
    void setCameraOptions(const mbgl::CameraOptions& camera);
    
    /**
     * Get camera options.
     */
    mbgl::CameraOptions getCameraOptions() const;

    /**
     * Set the geographic bounds.
     */
    void setRegion(const mbgl::LatLngBounds& bounds);
    
    /**
     * Get the geographic bounds.
     */
    mbgl::LatLngBounds getRegion() const;

    /**
     * Access the underlying style object.
     */
    mbgl::style::Style& getStyle();
    const mbgl::style::Style& getStyle() const;

    /**
     * Start snapshot generation.
     *
     * @param callback Completion callback
     */
    void snapshot(SnapshotCallback callback);

    /**
     * Cancel snapshot generation.
     */
    void cancel();

    // MapSnapshotterObserver implementation
    void onDidFailLoadingStyle(const std::string& error) override;
    void onDidFinishLoadingStyle() override;
    void onStyleImageMissing(const std::string& imageName) override;

    /**
     * Set the observer callback.
     */
    using ObserverCallback = std::function<void(const std::string& event, const std::string& data)>;
    void setObserverCallback(ObserverCallback callback);

private:
    std::unique_ptr<mbgl::MapSnapshotter> snapshotter_;
    float pixelRatio_;
    bool showLogo_;
    SnapshotOptions options_;
    ObserverCallback observerCallback_;
};

} // namespace harmony
} // namespace mbgl

