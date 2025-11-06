/**
 * MapSnapshot NAPI Bindings for HarmonyOS
 * 
 * 封装 MapSnapshot 对象并提供坐标转换功能
 * 参考 Android: platform/android/MapLibreAndroid/src/cpp/snapshotter/map_snapshot.hpp
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
 * MapSnapshotInstance - MapSnapshot 的 NAPI 实例
 * 
 * 保存快照图像数据和坐标转换函数
 */
class MapSnapshotInstance {
public:
    /**
     * 构造函数
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
     * 获取图像数据
     */
    const mbgl::PremultipliedImage& getImage() const { return image_; }

    /**
     * 获取图像宽度
     */
    uint32_t getWidth() const { return image_.size.width; }

    /**
     * 获取图像高度
     */
    uint32_t getHeight() const { return image_.size.height; }

    /**
     * 获取归属信息
     */
    const std::vector<std::string>& getAttributions() const { return attributions_; }

    /**
     * 获取像素比
     */
    float getPixelRatio() const { return pixelRatio_; }

    /**
     * 地理坐标转换为图像像素坐标
     */
    mbgl::ScreenCoordinate pixelForLatLng(const mbgl::LatLng& latLng) const;

    /**
     * 图像像素坐标转换为地理坐标
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
 * 创建 MapSnapshot NAPI 对象
 * 
 * @param env NAPI 环境
 * @param image 图像数据
 * @param attributions 归属信息
 * @param pixelRatio 像素比
 * @param pointForFn 坐标转换函数（地理→屏幕）
 * @param latLngForFn 坐标转换函数（屏幕→地理）
 * @return NAPI 对象
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
 * MapSnapshot NAPI 方法：地理坐标→图像像素坐标
 */
napi_value MapSnapshot_pixelForLatLng(napi_env env, napi_callback_info info);

/**
 * MapSnapshot NAPI 方法：图像像素坐标→地理坐标
 */
napi_value MapSnapshot_latLngForPixel(napi_env env, napi_callback_info info);

} // namespace harmony
} // namespace mbgl

