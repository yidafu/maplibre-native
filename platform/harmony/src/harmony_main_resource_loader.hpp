#pragma once

#include <mbgl/storage/file_source.hpp>
#include <memory>

namespace mbgl {

class ClientOptions;
class ResourceOptions;

/**
 * @brief Harmony 平台专用的 MainResourceLoader 实现
 * 
 * 这个类基于 src/mbgl/storage/main_resource_loader.hpp 创建，
 * 修复了 Actor invoke 失败的问题。
 * 
 * 关键改进：
 * - 使用 Scheduler 直接调度回调，而不是 Actor 消息传递
 * - 避免对象引用失效导致的消息传递失败
 * 
 * @see src/mbgl/storage/main_resource_loader.hpp - 原始实现
 * @see platform/harmony/ACTOR_INVOKE_FIX_HARMONY.md - 修复详情
 */
class HarmonyMainResourceLoader final : public FileSource {
public:
    explicit HarmonyMainResourceLoader(const ResourceOptions& resourceOptions, const ClientOptions& clientOptions);
    ~HarmonyMainResourceLoader() override;

    bool supportsCacheOnlyRequests() const override;
    std::unique_ptr<AsyncRequest> request(const Resource&, Callback) override;
    bool canRequest(const Resource&) const override;
    void pause() override;
    void resume() override;

    void setResourceOptions(ResourceOptions) override;
    ResourceOptions getResourceOptions() override;

    void setClientOptions(ClientOptions) override;
    ClientOptions getClientOptions() override;

private:
    class Impl;
    const std::unique_ptr<Impl> impl;
};

} // namespace mbgl

