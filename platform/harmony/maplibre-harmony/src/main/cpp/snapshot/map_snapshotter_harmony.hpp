/**
 * MapSnapshotter for HarmonyOS
 * 
 * Wraps mln::MapSnapshotter to provide snapshot functionality on HarmonyOS.
 */

#pragma once

#include <mln/map/camera.hpp>
#include <mln/map/map_snapshotter.hpp>
#include <mln/util/geo.hpp>
#include <mln/util/image.hpp>
#include <mln/storage/resource_options.hpp>
#include <mln/util/client_options.hpp>
#include <napi/native_api.h>

#include <memory>
#include <string>
#include <functional>
#include <optional>

namespace mln {
namespace harmony {

/**
 * MapSnapshotterHarmony - Harmony platform snapshotter
 *
 * Matches Android's MapSnapshotter and iOS's MLNMapSnapshotter.
 */
class MapSnapshotterHarmony final : public mln::MapSnapshotterObserver {
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
        std::optional<mln::CameraOptions> camera;
        std::optional<mln::LatLngBounds> region;
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
        mln::PremultipliedImage,
        std::vector<std::string>,
        mln::MapSnapshotter::PointForFn,
        mln::MapSnapshotter::LatLngForFn
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
        const mln::ResourceOptions& resourceOptions,
        const mln::ClientOptions& clientOptions = mln::ClientOptions()
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
    void setSize(const mln::Size& size);
    
    /**
     * Get the snapshot size.
     */
    mln::Size getSize() const;

    /**
     * Get the pixel ratio configured for this snapshotter.
     */
    float getPixelRatio() const;

    /**
     * Set camera options.
     */
    void setCameraOptions(const mln::CameraOptions& camera);
    
    /**
     * Get camera options.
     */
    mln::CameraOptions getCameraOptions() const;

    /**
     * Set the geographic bounds.
     */
    void setRegion(const mln::LatLngBounds& bounds);
    
    /**
     * Get the geographic bounds.
     */
    mln::LatLngBounds getRegion() const;

    /**
     * Access the underlying style object.
     */
    mln::style::Style& getStyle();
    const mln::style::Style& getStyle() const;

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
    std::unique_ptr<mln::MapSnapshotter> snapshotter_;
    float pixelRatio_;
    bool showLogo_;
    SnapshotOptions options_;
    ObserverCallback observerCallback_;
};

} // namespace harmony
} // namespace mln

