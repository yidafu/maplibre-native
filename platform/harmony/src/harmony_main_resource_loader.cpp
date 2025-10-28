#include "harmony_main_resource_loader.hpp"

#include <mbgl/actor/actor.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/platform/settings.hpp>
#include <mbgl/storage/file_source_manager.hpp>
#include <mbgl/storage/file_source_request.hpp>
#include <mbgl/storage/resource.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/util/client_options.hpp>
#include <mbgl/util/thread.hpp>
#include <mbgl/util/logging.hpp>

#include <mapbox/std/weak.hpp>

#include <cassert>
#include <map>
#include <memory>
#include <sstream>
#include <thread>
#include <functional>

namespace mbgl {

/**
 * @brief Harmony 平台专用的 MainResourceLoaderThread 实现
 * 
 * 关键修复：使用 Scheduler 弱引用直接调度回调，而不是通过 ActorRef::invoke()
 */
class HarmonyMainResourceLoaderThread {
public:
    HarmonyMainResourceLoaderThread(std::shared_ptr<FileSource> assetFileSource_,
                                    std::shared_ptr<FileSource> databaseFileSource_,
                                    std::shared_ptr<FileSource> localFileSource_,
                                    std::shared_ptr<FileSource> onlineFileSource_,
                                    std::shared_ptr<FileSource> mbtilesFileSource_,
                                    std::shared_ptr<FileSource> pmtilesFileSource_)
        : assetFileSource(std::move(assetFileSource_)),
          databaseFileSource(std::move(databaseFileSource_)),
          localFileSource(std::move(localFileSource_)),
          onlineFileSource(std::move(onlineFileSource_)),
          mbtilesFileSource(std::move(mbtilesFileSource_)),
          pmtilesFileSource(std::move(pmtilesFileSource_)) {
        mbgl::Log::Info(mbgl::Event::General, "[Harmony] HarmonyMainResourceLoaderThread created");
    }

    /**
     * @brief 处理资源请求的核心方法
     * 
     * @param req 异步请求指针
     * @param resource 要请求的资源
     * @param targetScheduler 目标线程（渲染线程）的 Scheduler 弱引用
     * 
     * 关键修复：
     * 1. 接收 Scheduler 弱引用而不是 ActorRef
     * 2. 在 callback 中使用 Scheduler::schedule() 直接调度
     * 3. 绕过 Actor 消息传递机制的复杂性
     */
    void request(AsyncRequest* req, const Resource& resource, mapbox::base::WeakPtr<Scheduler> targetScheduler) {
        mbgl::Log::Info(mbgl::Event::HttpRequest, 
                       "[Harmony] MainResourceLoaderThread::request called: " + resource.url);
        
        // 🔧 FIX: 使用 Scheduler 直接调度，而不是通过 Actor 消息传递
        // 这避免了 Actor invoke 失败的问题
        auto callback = [targetScheduler, req](const Response& res) {
            mbgl::Log::Info(mbgl::Event::HttpRequest, 
                           "[Harmony] MainResourceLoader callback received");
            
            // 通过目标 Scheduler（渲染线程）调度回调执行
            if (auto guard = targetScheduler.lock(); targetScheduler) {
                mbgl::Log::Info(mbgl::Event::HttpRequest, 
                               "[Harmony] Scheduling setResponse on target thread");
                
                // 直接在目标线程上调度 lambda 执行
                targetScheduler->schedule([req, res]() {
                    mbgl::Log::Info(mbgl::Event::HttpRequest, 
                                   "[Harmony] Calling FileSourceRequest::setResponse directly");
                    
                    // 直接调用 setResponse，此时已经在正确的线程上
                    static_cast<FileSourceRequest*>(req)->setResponse(res);
                    
                    mbgl::Log::Info(mbgl::Event::HttpRequest, 
                                   "[Harmony] setResponse completed successfully");
                });
            } else {
                mbgl::Log::Warning(mbgl::Event::HttpRequest, 
                                  "[Harmony] Target scheduler is gone, cannot deliver response");
            }
        };

        auto requestFromNetwork = [=, this](const Resource& res,
                                            std::unique_ptr<AsyncRequest> parent) -> std::unique_ptr<AsyncRequest> {
            if (!onlineFileSource || !onlineFileSource->canRequest(resource)) {
                return parent;
            }

            // Keep parent request alive while chained request is being processed.
            std::shared_ptr<AsyncRequest> parentKeepAlive = std::move(parent);

            return onlineFileSource->request(res, [=, ptr = parentKeepAlive, this](const Response& response) {
                if (databaseFileSource) {
                    databaseFileSource->forward(res, response, nullptr);
                }
                callback(response);
            });
        };

        // Initial tasksSize is used to check whether any of
        // the sources were able to request a resource.
        const std::size_t tasksSize = tasks.size();

        // Waterfall resource request processing and return early once resource was requested.
        if (assetFileSource && assetFileSource->canRequest(resource)) {
            // Asset request
            tasks[req] = assetFileSource->request(resource, callback);
        } else if (mbtilesFileSource && mbtilesFileSource->canRequest(resource)) {
            // Local file request
            tasks[req] = mbtilesFileSource->request(resource, callback);
        } else if (pmtilesFileSource && pmtilesFileSource->canRequest(resource)) {
            // Local file request
            tasks[req] = pmtilesFileSource->request(resource, callback);
        } else if (localFileSource && localFileSource->canRequest(resource)) {
            // Local file request
            tasks[req] = localFileSource->request(resource, callback);
        } else if (databaseFileSource && databaseFileSource->canRequest(resource)) {
            // Try cache only request if needed.
            if (resource.loadingMethod == Resource::LoadingMethod::CacheOnly) {
                tasks[req] = databaseFileSource->request(resource, callback);
            } else {
                // Cache request with fallback to network with cache control
                tasks[req] = databaseFileSource->request(resource, [=, this](const Response& response) {
                    Resource res = resource;

                    // Resource is in the cache
                    if (!response.noContent) {
                        if (response.isUsable()) {
                            callback(response);
                            // Set the priority of existing resource to low if it's expired but usable.
                            res.setPriority(Resource::Priority::Low);
                        }
                        
                        // 🔧 FIX for HTTP 304: 无论是否可用，都设置 priorData
                        // 这样当服务器返回 304 Not Modified 时，可以使用缓存的数据
                        // 修复黑屏问题 - 2025-10-28
                        if (response.data && !response.data->empty()) {
                            res.priorData = response.data;
                            mbgl::Log::Info(mbgl::Event::HttpRequest, 
                                           "[Harmony] Set priorData for 304 handling: " + 
                                           std::to_string(response.data->size()) + " bytes, URL: " + 
                                           resource.url.substr(0, 80));
                        } else if (!response.isUsable()) {
                            // 如果不可用且没有数据，也设置（保持原有逻辑）
                            res.priorData = response.data;
                        }
                        
                        if (!res.priorData || (res.priorData && res.priorData->empty())) {
                            mbgl::Log::Warning(mbgl::Event::HttpRequest, 
                                              "[Harmony] ⚠️ priorData is empty for: " + 
                                              resource.url.substr(0, 80));
                        }

                        // Copy response fields for cache control request
                        res.priorModified = response.modified;
                        res.priorExpires = response.expires;
                        res.priorEtag = response.etag;
                    }

                    tasks[req] = requestFromNetwork(res, std::move(tasks[req]));
                });
            }
        } else if (auto networkReq = requestFromNetwork(resource, nullptr)) {
            // Get from the online file source
            tasks[req] = std::move(networkReq);
        }

        // If no new tasks were added, notify client that request cannot be processed.
        if (tasks.size() == tasksSize) {
            Response response;
            response.noContent = true;
            response.error = std::make_unique<Response::Error>(Response::Error::Reason::Other,
                                                               "Unsupported resource request.");
            callback(response);
        }
    }

    void cancel(AsyncRequest* req) {
        assert(req);
        tasks.erase(req);
    }

private:
    const std::shared_ptr<FileSource> assetFileSource;
    const std::shared_ptr<FileSource> databaseFileSource;
    const std::shared_ptr<FileSource> localFileSource;
    const std::shared_ptr<FileSource> onlineFileSource;
    const std::shared_ptr<FileSource> mbtilesFileSource;
    const std::shared_ptr<FileSource> pmtilesFileSource;
    std::map<AsyncRequest*, std::unique_ptr<AsyncRequest>> tasks;
};

class HarmonyMainResourceLoader::Impl {
public:
    Impl(const ResourceOptions& resourceOptions_,
         const ClientOptions& clientOptions_,
         std::shared_ptr<FileSource> assetFileSource_,
         std::shared_ptr<FileSource> databaseFileSource_,
         std::shared_ptr<FileSource> localFileSource_,
         std::shared_ptr<FileSource> onlineFileSource_,
         std::shared_ptr<FileSource> mbtilesFileSource_,
         std::shared_ptr<FileSource> pmtilesFileSource_)
        : assetFileSource(std::move(assetFileSource_)),
          databaseFileSource(std::move(databaseFileSource_)),
          localFileSource(std::move(localFileSource_)),
          onlineFileSource(std::move(onlineFileSource_)),
          mbtilesFileSource(std::move(mbtilesFileSource_)),
          pmtilesFileSource(std::move(pmtilesFileSource_)),
          supportsCacheOnlyRequests_(bool(databaseFileSource)),
          thread(std::make_shared<util::Thread<HarmonyMainResourceLoaderThread>>(
              util::makeThreadPrioritySetter(platform::EXPERIMENTAL_THREAD_PRIORITY_WORKER),
              "HarmonyResourceLoader",
              assetFileSource,
              databaseFileSource,
              localFileSource,
              onlineFileSource,
              mbtilesFileSource,
              pmtilesFileSource)),
          resourceOptions(resourceOptions_.clone()),
          clientOptions(clientOptions_.clone()) {
        mbgl::Log::Info(mbgl::Event::General, "[Harmony] HarmonyMainResourceLoader::Impl created");
    }

    /**
     * @brief 发起资源请求
     * 
     * 关键修复：
     * 1. 获取当前线程（渲染线程）的 Scheduler
     * 2. 创建 Scheduler 的弱引用
     * 3. 传递弱引用给 HarmonyMainResourceLoaderThread
     */
    std::unique_ptr<AsyncRequest> request(const Resource& resource, Callback callback) {
        std::ostringstream threadInfo;
        threadInfo << std::this_thread::get_id();
        mbgl::Log::Info(mbgl::Event::HttpRequest, 
                       "[Harmony] MainResourceLoader::request START on thread=" + threadInfo.str() + 
                       ": " + resource.url);
        
        auto* currentScheduler = mbgl::Scheduler::GetCurrent();
        mbgl::Log::Info(mbgl::Event::HttpRequest, 
                       "[Harmony] Current Scheduler: " + 
                       std::string(currentScheduler ? "exists" : "NULL"));
        
        if (!currentScheduler) {
            mbgl::Log::Error(mbgl::Event::HttpRequest, 
                            "[Harmony] CRITICAL: No current scheduler available!");
        }
        
        // 🔧 FIX: 创建 FileSourceRequest 并获取当前线程的 Scheduler 弱引用
        // FileSourceRequest 在调用线程（渲染线程）创建
        auto req = std::make_unique<FileSourceRequest>(std::move(callback));
        
        // 获取当前 Scheduler 的弱引用，传递给 HarmonyMainResourceLoaderThread
        mapbox::base::WeakPtr<Scheduler> targetScheduler = 
            currentScheduler ? currentScheduler->makeWeakPtr() : mapbox::base::WeakPtr<Scheduler>();

        req->onCancel([weak_thread = std::weak_ptr<util::Thread<HarmonyMainResourceLoaderThread>>(thread), req = req.get()]() {
            if (auto t = weak_thread.lock()) {
                t->actor().invoke(&HarmonyMainResourceLoaderThread::cancel, req);
            }
        });
        
        mbgl::Log::Info(mbgl::Event::HttpRequest, 
                       "[Harmony] Calling thread->actor().invoke() with Scheduler for: " + resource.url);
        
        // 🔧 FIX: 传递 Scheduler 弱引用而不是 ActorRef
        thread->actor().invoke(&HarmonyMainResourceLoaderThread::request, req.get(), resource, targetScheduler);
        
        mbgl::Log::Info(mbgl::Event::HttpRequest, 
                       "[Harmony] thread->actor().invoke() returned");
        
        return req;
    }

    bool canRequest(const Resource& resource) const {
        return (assetFileSource && assetFileSource->canRequest(resource)) ||
               (localFileSource && localFileSource->canRequest(resource)) ||
               (databaseFileSource && databaseFileSource->canRequest(resource)) ||
               (onlineFileSource && onlineFileSource->canRequest(resource)) ||
               (mbtilesFileSource && mbtilesFileSource->canRequest(resource)) ||
               (pmtilesFileSource && pmtilesFileSource->canRequest(resource));
    }

    bool supportsCacheOnlyRequests() const { return supportsCacheOnlyRequests_; }

    void pause() { thread->pause(); }

    void resume() { thread->resume(); }

    void setResourceOptions(ResourceOptions options) {
        std::lock_guard<std::mutex> lock(resourceOptionsMutex);
        resourceOptions = options;
        assetFileSource->setResourceOptions(options.clone());
        databaseFileSource->setResourceOptions(options.clone());
        localFileSource->setResourceOptions(options.clone());
        onlineFileSource->setResourceOptions(options.clone());
        mbtilesFileSource->setResourceOptions(options.clone());
        pmtilesFileSource->setResourceOptions(options.clone());
    }

    ResourceOptions getResourceOptions() {
        std::lock_guard<std::mutex> lock(resourceOptionsMutex);
        return resourceOptions.clone();
    }

    void setClientOptions(ClientOptions options) {
        std::lock_guard<std::mutex> lock(clientOptionsMutex);
        clientOptions = options;
        assetFileSource->setClientOptions(options.clone());
        databaseFileSource->setClientOptions(options.clone());
        localFileSource->setClientOptions(options.clone());
        onlineFileSource->setClientOptions(options.clone());
        mbtilesFileSource->setClientOptions(options.clone());
        pmtilesFileSource->setClientOptions(options.clone());
    }

    ClientOptions getClientOptions() {
        std::lock_guard<std::mutex> lock(clientOptionsMutex);
        return clientOptions.clone();
    }

private:
    const std::shared_ptr<FileSource> assetFileSource;
    const std::shared_ptr<FileSource> databaseFileSource;
    const std::shared_ptr<FileSource> localFileSource;
    const std::shared_ptr<FileSource> onlineFileSource;
    const std::shared_ptr<FileSource> mbtilesFileSource;
    const std::shared_ptr<FileSource> pmtilesFileSource;
    const bool supportsCacheOnlyRequests_;
    const std::shared_ptr<util::Thread<HarmonyMainResourceLoaderThread>> thread;
    mutable std::mutex resourceOptionsMutex;
    ResourceOptions resourceOptions;
    mutable std::mutex clientOptionsMutex;
    ClientOptions clientOptions;
};

HarmonyMainResourceLoader::HarmonyMainResourceLoader(const ResourceOptions& resourceOptions, 
                                                     const ClientOptions& clientOptions)
    : impl(std::make_unique<Impl>(
          resourceOptions.clone(),
          clientOptions.clone(),
          FileSourceManager::get()->getFileSource(FileSourceType::Asset, resourceOptions, clientOptions),
          FileSourceManager::get()->getFileSource(FileSourceType::Database, resourceOptions, clientOptions),
          FileSourceManager::get()->getFileSource(FileSourceType::FileSystem, resourceOptions, clientOptions),
          FileSourceManager::get()->getFileSource(FileSourceType::Network, resourceOptions, clientOptions),
          FileSourceManager::get()->getFileSource(FileSourceType::Mbtiles, resourceOptions, clientOptions),
          FileSourceManager::get()->getFileSource(FileSourceType::Pmtiles, resourceOptions, clientOptions))) {
    mbgl::Log::Info(mbgl::Event::General, "[Harmony] HarmonyMainResourceLoader constructed");
}

HarmonyMainResourceLoader::~HarmonyMainResourceLoader() {
    mbgl::Log::Info(mbgl::Event::General, "[Harmony] HarmonyMainResourceLoader destroyed");
}

bool HarmonyMainResourceLoader::supportsCacheOnlyRequests() const {
    return impl->supportsCacheOnlyRequests();
}

std::unique_ptr<AsyncRequest> HarmonyMainResourceLoader::request(const Resource& resource, Callback callback) {
    return impl->request(resource, std::move(callback));
}

bool HarmonyMainResourceLoader::canRequest(const Resource& resource) const {
    return impl->canRequest(resource);
}

void HarmonyMainResourceLoader::pause() {
    impl->pause();
}

void HarmonyMainResourceLoader::resume() {
    impl->resume();
}

void HarmonyMainResourceLoader::setResourceOptions(ResourceOptions options) {
    impl->setResourceOptions(options.clone());
}

ResourceOptions HarmonyMainResourceLoader::getResourceOptions() {
    return impl->getResourceOptions();
}

void HarmonyMainResourceLoader::setClientOptions(ClientOptions options) {
    impl->setClientOptions(options.clone());
}

ClientOptions HarmonyMainResourceLoader::getClientOptions() {
    return impl->getClientOptions();
}

} // namespace mbgl

