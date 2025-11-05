#pragma once

#include <mbgl/storage/resource.hpp>
#include <string>
#include <functional>
#include <mutex>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * URLTransformManager - 管理URL转换回调的全局管理器
 * 
 * 提供线程安全的URL转换功能，允许开发者在运行时拦截和修改资源请求的URL。
 * 
 * 设计说明：
 * - 单例模式：确保全局只有一个管理器实例
 * - 线程安全：使用mutex保护回调访问
 * - 同步回调：URL转换在请求线程中同步执行
 * 
 * 参考实现：
 * - Android: FileSource.setResourceTransform()
 * - iOS: MLNOfflineStorageDelegate.offlineStorage:URLForResourceOfKind:withURL:
 * 
 * 使用场景：
 * - CDN切换：将请求重定向到不同的服务器
 * - 离线资源映射：将在线URL映射到本地文件
 * - URL参数添加：动态添加认证token等参数
 * - 资源路由：根据资源类型使用不同的服务
 */
class URLTransformManager {
public:
    /**
     * URL转换回调函数类型
     * 
     * @param kind 资源类型（Style, Tile, Glyphs等）
     * @param url 原始URL
     * @return 转换后的URL，如果返回空字符串则使用原URL
     */
    using TransformCallback = std::function<std::string(mbgl::Resource::Kind kind, const std::string& url)>;

    /**
     * 获取单例实例
     */
    static URLTransformManager& getInstance();

    /**
     * 设置URL转换回调
     * 
     * 该回调将在每次发起资源请求前被调用，允许修改请求的URL。
     * 
     * @param callback URL转换回调函数
     * 
     * @note 回调应尽快返回，避免阻塞请求线程
     * @note 如果回调抛出异常，将被捕获并记录，使用原URL继续请求
     */
    void setTransformCallback(TransformCallback callback);

    /**
     * 清除URL转换回调
     * 
     * 清除后，所有资源请求将使用原始URL，不进行转换。
     */
    void clearTransformCallback();

    /**
     * 检查是否设置了转换回调
     * 
     * @return 如果设置了回调返回true，否则返回false
     */
    bool hasCallback() const;

    /**
     * 执行URL转换
     * 
     * 如果设置了回调，调用回调转换URL；否则返回原URL。
     * 
     * @param kind 资源类型
     * @param url 原始URL
     * @return 转换后的URL
     * 
     * @note 线程安全，可在任意线程调用
     * @note 如果回调返回空字符串或抛出异常，返回原URL
     */
    std::string transform(mbgl::Resource::Kind kind, const std::string& url);

    // 禁止复制和赋值
    URLTransformManager(const URLTransformManager&) = delete;
    URLTransformManager& operator=(const URLTransformManager&) = delete;

private:
    URLTransformManager() = default;
    ~URLTransformManager() = default;

    mutable std::mutex mutex_;
    TransformCallback callback_;
};

} // namespace harmony
} // namespace mbgl

