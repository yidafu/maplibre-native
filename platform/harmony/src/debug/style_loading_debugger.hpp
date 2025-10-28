#pragma once

#include <mbgl/util/chrono.hpp>
#include <mbgl/util/noncopyable.hpp>
#include <string>
#include <vector>
#include <map>
#include <memory>
#include <mutex>
#include <functional>

namespace mbgl {
namespace harmony {

/**
 * @brief 资源加载状态
 */
enum class ResourceLoadState {
    Pending,    // 等待加载
    Loading,    // 加载中
    Success,    // 成功
    Failed      // 失败
};

/**
 * @brief 资源加载信息
 */
struct ResourceLoadInfo {
    std::string url;
    std::string type;  // style, tile, sprite, glyph, image
    ResourceLoadState state;
    TimePoint startTime;
    TimePoint endTime;
    size_t dataSize;
    std::string errorMessage;
    
    Duration getDuration() const {
        if (state == ResourceLoadState::Loading || state == ResourceLoadState::Pending) {
            return Clock::now() - startTime;
        }
        return endTime - startTime;
    }
};

/**
 * @brief Style加载阶段
 */
enum class StyleLoadingPhase {
    NotStarted,         // 未开始
    DownloadingStyle,   // 下载style.json
    ParsingStyle,       // 解析style
    LoadingSources,     // 加载sources
    LoadingLayers,      // 加载layers
    LoadingSprites,     // 加载sprites
    LoadingGlyphs,      // 加载glyphs
    LoadingTiles,       // 加载tiles
    Completed,          // 完成
    Failed              // 失败
};

/**
 * @brief Style加载统计信息
 */
struct StyleLoadingStats {
    TimePoint startTime;
    TimePoint endTime;
    StyleLoadingPhase currentPhase;
    
    // 资源统计
    size_t totalResources = 0;
    size_t loadedResources = 0;
    size_t failedResources = 0;
    
    // 按类型统计
    std::map<std::string, size_t> resourcesByType;
    std::map<std::string, size_t> failedByType;
    
    // 性能指标
    Duration totalLoadTime;
    Duration averageLoadTime;
    Duration maxLoadTime;
    
    float getProgress() const {
        if (totalResources == 0) return 0.0f;
        return static_cast<float>(loadedResources) / totalResources;
    }
    
    bool isCompleted() const {
        return currentPhase == StyleLoadingPhase::Completed;
    }
    
    bool hasFailed() const {
        return currentPhase == StyleLoadingPhase::Failed;
    }
};

/**
 * @brief Source信息
 */
struct SourceDebugInfo {
    std::string id;
    std::string type;  // vector, raster, geojson, image, etc.
    bool initialized;
    size_t tileCount;
    size_t loadedTiles;
    TimePoint createTime;
};

/**
 * @brief Layer信息
 */
struct LayerDebugInfo {
    std::string id;
    std::string type;  // fill, line, circle, symbol, etc.
    std::string sourceId;
    bool visible;
    TimePoint createTime;
};

/**
 * @brief 调试事件监听器
 */
class StyleLoadingDebuggerObserver {
public:
    virtual ~StyleLoadingDebuggerObserver() = default;
    
    virtual void onPhaseChanged(StyleLoadingPhase phase) = 0;
    virtual void onResourceLoading(const ResourceLoadInfo& info) = 0;
    virtual void onResourceLoaded(const ResourceLoadInfo& info) = 0;
    virtual void onResourceFailed(const ResourceLoadInfo& info) = 0;
    virtual void onSourceCreated(const SourceDebugInfo& info) = 0;
    virtual void onLayerCreated(const LayerDebugInfo& info) = 0;
    virtual void onStatsUpdated(const StyleLoadingStats& stats) = 0;
};

/**
 * @brief Style加载调试器
 * 
 * 用于追踪和记录style加载过程中的所有事件和性能数据
 * 仅在DEBUG模式下启用，生产版本开销为零
 */
class StyleLoadingDebugger : public util::noncopyable {
public:
    static StyleLoadingDebugger& getInstance();
    
    ~StyleLoadingDebugger();
    
    // 启用/禁用调试
    void enable();
    void disable();
    bool isEnabled() const { return enabled_; }
    
    // Phase tracking
    void setPhase(StyleLoadingPhase phase);
    StyleLoadingPhase getCurrentPhase() const;
    
    // 资源加载追踪
    void trackResourceStart(const std::string& url, const std::string& type);
    void trackResourceSuccess(const std::string& url, size_t dataSize);
    void trackResourceFailure(const std::string& url, const std::string& error);
    
    // Source/Layer追踪
    void trackSourceCreated(const std::string& id, const std::string& type);
    void trackLayerCreated(const std::string& id, const std::string& type, 
                          const std::string& sourceId);
    void updateSourceTileCount(const std::string& id, size_t total, size_t loaded);
    
    // 获取统计信息
    StyleLoadingStats getStats() const;
    std::vector<ResourceLoadInfo> getResources() const;
    std::vector<SourceDebugInfo> getSources() const;
    std::vector<LayerDebugInfo> getLayers() const;
    
    // 观察者模式
    void addObserver(std::shared_ptr<StyleLoadingDebuggerObserver> observer);
    void removeObserver(std::shared_ptr<StyleLoadingDebuggerObserver> observer);
    
    // 重置状态（新的style加载开始时调用）
    void reset();
    
    // 导出调试报告（JSON格式）
    std::string exportReport() const;
    
private:
    StyleLoadingDebugger();
    
    void updateStats();
    void notifyObservers();
    
    mutable std::mutex mutex_;
    bool enabled_;
    
    StyleLoadingStats stats_;
    StyleLoadingPhase currentPhase_;
    
    std::map<std::string, ResourceLoadInfo> resources_;
    std::map<std::string, SourceDebugInfo> sources_;
    std::map<std::string, LayerDebugInfo> layers_;
    
    std::vector<std::shared_ptr<StyleLoadingDebuggerObserver>> observers_;
};

} // namespace harmony
} // namespace mbgl

