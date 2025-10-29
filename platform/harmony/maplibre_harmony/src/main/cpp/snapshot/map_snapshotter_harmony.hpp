/**
 * MapSnapshotter for HarmonyOS
 * 
 * 封装 mbgl::MapSnapshotter 为 Harmony 平台提供地图快照功能
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
 * MapSnapshotterHarmony - Harmony 平台的地图快照器
 * 
 * 对应 Android 的 MapSnapshotter 和 iOS 的 MLNMapSnapshotter
 */
class MapSnapshotterHarmony final : public mbgl::MapSnapshotterObserver {
public:
    /**
     * 快照选项
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
     * 快照回调类型
     * 
     * 参数：
     * - exception_ptr: 错误（如果有）
     * - PremultipliedImage: 图像数据
     * - vector<string>: 归属信息
     */
    using SnapshotCallback = std::function<void(
        std::exception_ptr,
        mbgl::PremultipliedImage,
        std::vector<std::string>
    )>;

    /**
     * 构造函数
     * 
     * @param options 快照选项
     * @param resourceOptions 资源选项
     * @param clientOptions 客户端选项
     */
    MapSnapshotterHarmony(
        const SnapshotOptions& options,
        const mbgl::ResourceOptions& resourceOptions,
        const mbgl::ClientOptions& clientOptions = mbgl::ClientOptions()
    );

    ~MapSnapshotterHarmony();

    /**
     * 设置样式 URL
     */
    void setStyleURL(const std::string& styleURL);
    
    /**
     * 获取样式 URL
     */
    std::string getStyleURL() const;

    /**
     * 设置样式 JSON
     */
    void setStyleJSON(const std::string& styleJSON);
    
    /**
     * 获取样式 JSON
     */
    std::string getStyleJSON() const;

    /**
     * 设置尺寸
     */
    void setSize(const mbgl::Size& size);
    
    /**
     * 获取尺寸
     */
    mbgl::Size getSize() const;

    /**
     * 设置相机选项
     */
    void setCameraOptions(const mbgl::CameraOptions& camera);
    
    /**
     * 获取相机选项
     */
    mbgl::CameraOptions getCameraOptions() const;

    /**
     * 设置区域边界
     */
    void setRegion(const mbgl::LatLngBounds& bounds);
    
    /**
     * 获取区域边界
     */
    mbgl::LatLngBounds getRegion() const;

    /**
     * 获取样式对象
     */
    mbgl::style::Style& getStyle();
    const mbgl::style::Style& getStyle() const;

    /**
     * 开始生成快照
     * 
     * @param callback 完成回调
     */
    void snapshot(SnapshotCallback callback);

    /**
     * 取消快照生成
     */
    void cancel();

    // MapSnapshotterObserver 接口实现
    void onDidFailLoadingStyle(const std::string& error) override;
    void onDidFinishLoadingStyle() override;
    void onStyleImageMissing(const std::string& imageName) override;

private:
    std::unique_ptr<mbgl::MapSnapshotter> snapshotter_;
    float pixelRatio_;
    bool showLogo_;
    SnapshotOptions options_;
};

} // namespace harmony
} // namespace mbgl

