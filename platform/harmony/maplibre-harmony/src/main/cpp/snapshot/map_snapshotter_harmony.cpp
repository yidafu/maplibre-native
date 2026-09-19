/**
 * MapSnapshotter for HarmonyOS - Implementation
 */

#include "map_snapshotter_harmony.hpp"
#include "../utils/logger.h"

#include <mln/map/camera.hpp>
#include <mln/util/geo.hpp>
#include <mln/storage/resource_options.hpp>

namespace mln {
namespace harmony {

MapSnapshotterHarmony::MapSnapshotterHarmony(
    const SnapshotOptions& options,
    const mln::ResourceOptions& resourceOptions,
    const mln::ClientOptions& clientOptions
) : options_(options),
    pixelRatio_(options.pixelRatio),
    showLogo_(options.showLogo) {
    
    // Create the core MapSnapshotter
    mln::Size size{options.width, options.height};
    
    std::optional<std::string> localFont = options.localFontFamily.empty() 
        ? std::nullopt 
        : std::optional<std::string>(options.localFontFamily);
    
    snapshotter_ = std::make_unique<mln::MapSnapshotter>(
        size,
        pixelRatio_,
        resourceOptions,
        clientOptions,
        *this,  // observer
        localFont
    );

    Logger::info("MapSnapshotterHarmony", "Created with size: %dx%d, pixelRatio: %.2f",
                 options.width, options.height, pixelRatio_);

    // Configure the camera if provided
    if (options.camera) {
        snapshotter_->setCameraOptions(*options.camera);
    }

    // Configure the region if provided
    if (options.region) {
        snapshotter_->setRegion(*options.region);
    }

    // Configure the style
    if (options.styleJSON && !options.styleJSON->empty()) {
        snapshotter_->setStyleJSON(*options.styleJSON);
    } else if (!options.styleURL.empty()) {
        snapshotter_->setStyleURL(options.styleURL);
    }
}

MapSnapshotterHarmony::~MapSnapshotterHarmony() {
    Logger::info("MapSnapshotterHarmony", "Destructor");
    if (snapshotter_) {
        // cancel() may throw in rare shutdown races; a throwing destructor
        // would std::terminate — swallow and log instead.
        try {
            snapshotter_->cancel();
        } catch (const std::exception& e) {
            Logger::error("MapSnapshotterHarmony", "cancel() threw in destructor: %s", e.what());
        } catch (...) {
            Logger::error("MapSnapshotterHarmony", "cancel() threw unknown exception in destructor");
        }
    }
}

void MapSnapshotterHarmony::setStyleURL(const std::string& styleURL) {
    if (!snapshotter_) return;
    snapshotter_->setStyleURL(styleURL);
    Logger::info("MapSnapshotterHarmony", "Style URL set: %s", styleURL.c_str());
}

std::string MapSnapshotterHarmony::getStyleURL() const {
    if (!snapshotter_) return "";
    return snapshotter_->getStyleURL();
}

void MapSnapshotterHarmony::setStyleJSON(const std::string& styleJSON) {
    if (!snapshotter_) return;
    snapshotter_->setStyleJSON(styleJSON);
    Logger::info("MapSnapshotterHarmony", "Style JSON set");
}

std::string MapSnapshotterHarmony::getStyleJSON() const {
    if (!snapshotter_) return "";
    return snapshotter_->getStyleJSON();
}

void MapSnapshotterHarmony::setSize(const mln::Size& size) {
    if (!snapshotter_) return;
    snapshotter_->setSize(size);
    Logger::info("MapSnapshotterHarmony", "Size set: %dx%d", size.width, size.height);
}

mln::Size MapSnapshotterHarmony::getSize() const {
    if (!snapshotter_) return mln::Size{0, 0};
    return snapshotter_->getSize();
}

float MapSnapshotterHarmony::getPixelRatio() const {
    return pixelRatio_;
}

void MapSnapshotterHarmony::setCameraOptions(const mln::CameraOptions& camera) {
    if (!snapshotter_) return;
    snapshotter_->setCameraOptions(camera);
    Logger::info("MapSnapshotterHarmony", "Camera options set");
}

mln::CameraOptions MapSnapshotterHarmony::getCameraOptions() const {
    if (!snapshotter_) return mln::CameraOptions{};
    return snapshotter_->getCameraOptions();
}

void MapSnapshotterHarmony::setRegion(const mln::LatLngBounds& bounds) {
    if (!snapshotter_) return;
    snapshotter_->setRegion(bounds);
    Logger::info("MapSnapshotterHarmony", "Region set");
}

mln::LatLngBounds MapSnapshotterHarmony::getRegion() const {
    if (!snapshotter_) return mln::LatLngBounds::empty();
    return snapshotter_->getRegion();
}

mln::style::Style& MapSnapshotterHarmony::getStyle() {
    return snapshotter_->getStyle();
}

const mln::style::Style& MapSnapshotterHarmony::getStyle() const {
    return snapshotter_->getStyle();
}

void MapSnapshotterHarmony::snapshot(SnapshotCallback callback) {
    if (!snapshotter_) {
        Logger::error("MapSnapshotterHarmony", "Snapshotter not initialized");
        callback(std::make_exception_ptr(std::runtime_error("Snapshotter not initialized")),
                 mln::PremultipliedImage{}, {}, nullptr, nullptr);
        return;
    }

    Logger::info("MapSnapshotterHarmony", "Starting snapshot");

    snapshotter_->snapshot([callback](std::exception_ptr err,
                                     mln::PremultipliedImage image,
                                     std::vector<std::string> attributions,
                                     mln::MapSnapshotter::PointForFn pointForFn,
                                     mln::MapSnapshotter::LatLngForFn latLngForFn) {
        // Forward all callback arguments, including coordinate conversion functions
        callback(err, std::move(image), std::move(attributions), pointForFn, latLngForFn);
    });
}

void MapSnapshotterHarmony::cancel() {
    if (!snapshotter_) return;
    Logger::info("MapSnapshotterHarmony", "Cancelling snapshot");
    snapshotter_->cancel();
}

// MapSnapshotterObserver implementation

void MapSnapshotterHarmony::onDidFailLoadingStyle(const std::string& error) {
    Logger::error("MapSnapshotterHarmony", "Failed loading style: %s", error.c_str());
    if (observerCallback_) {
        observerCallback_("onDidFailLoadingStyle", error);
    }
}

void MapSnapshotterHarmony::onDidFinishLoadingStyle() {
    Logger::info("MapSnapshotterHarmony", "Finished loading style");
    if (observerCallback_) {
        observerCallback_("onDidFinishLoadingStyle", "");
    }
}

void MapSnapshotterHarmony::onStyleImageMissing(const std::string& imageName) {
    Logger::warn("MapSnapshotterHarmony", "Style image missing: %s", imageName.c_str());
    if (observerCallback_) {
        observerCallback_("onStyleImageMissing", imageName);
    }
}

void MapSnapshotterHarmony::setObserverCallback(ObserverCallback callback) {
    observerCallback_ = callback;
}

} // namespace harmony
} // namespace mln

