#include "style_loading_debugger.hpp"
#include <mbgl/util/logging.hpp>
#include <algorithm>
#include <sstream>
#include <iomanip>

namespace mbgl {
namespace harmony {

namespace {
const char* TAG = "StyleLoadingDebugger";

const char* phaseToString(StyleLoadingPhase phase) {
    switch (phase) {
        case StyleLoadingPhase::NotStarted: return "NotStarted";
        case StyleLoadingPhase::DownloadingStyle: return "DownloadingStyle";
        case StyleLoadingPhase::ParsingStyle: return "ParsingStyle";
        case StyleLoadingPhase::LoadingSources: return "LoadingSources";
        case StyleLoadingPhase::LoadingLayers: return "LoadingLayers";
        case StyleLoadingPhase::LoadingSprites: return "LoadingSprites";
        case StyleLoadingPhase::LoadingGlyphs: return "LoadingGlyphs";
        case StyleLoadingPhase::LoadingTiles: return "LoadingTiles";
        case StyleLoadingPhase::Completed: return "Completed";
        case StyleLoadingPhase::Failed: return "Failed";
    }
    return "Unknown";
}

const char* stateToString(ResourceLoadState state) {
    switch (state) {
        case ResourceLoadState::Pending: return "Pending";
        case ResourceLoadState::Loading: return "Loading";
        case ResourceLoadState::Success: return "Success";
        case ResourceLoadState::Failed: return "Failed";
    }
    return "Unknown";
}
} // namespace

StyleLoadingDebugger& StyleLoadingDebugger::getInstance() {
    static StyleLoadingDebugger instance;
    return instance;
}

StyleLoadingDebugger::StyleLoadingDebugger()
    : enabled_(false)
    , currentPhase_(StyleLoadingPhase::NotStarted) {
    stats_.startTime = Clock::now();
    stats_.currentPhase = currentPhase_;
}

StyleLoadingDebugger::~StyleLoadingDebugger() {
    observers_.clear();
}

void StyleLoadingDebugger::enable() {
    std::lock_guard<std::mutex> lock(mutex_);
    enabled_ = true;
    Log::Info(Event::General, "%s: Debugging enabled", TAG);
}

void StyleLoadingDebugger::disable() {
    std::lock_guard<std::mutex> lock(mutex_);
    enabled_ = false;
    Log::Info(Event::General, "%s: Debugging disabled", TAG);
}

void StyleLoadingDebugger::setPhase(StyleLoadingPhase phase) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    currentPhase_ = phase;
    stats_.currentPhase = phase;
    
    if (phase == StyleLoadingPhase::Completed) {
        stats_.endTime = Clock::now();
        stats_.totalLoadTime = stats_.endTime - stats_.startTime;
        Log::Info(Event::General, "%s: Style loading completed in %.2f seconds",
                  TAG, std::chrono::duration<double>(stats_.totalLoadTime).count());
    } else if (phase == StyleLoadingPhase::Failed) {
        stats_.endTime = Clock::now();
        Log::Warning(Event::General, "%s: Style loading failed", TAG);
    }
    
    Log::Info(Event::General, "%s: Phase changed to %s", TAG, phaseToString(phase));
    
    // 通知观察者
    for (auto& observer : observers_) {
        if (observer) {
            observer->onPhaseChanged(phase);
        }
    }
    
    updateStats();
    notifyObservers();
}

StyleLoadingPhase StyleLoadingDebugger::getCurrentPhase() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return currentPhase_;
}

void StyleLoadingDebugger::trackResourceStart(const std::string& url, const std::string& type) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    ResourceLoadInfo info;
    info.url = url;
    info.type = type;
    info.state = ResourceLoadState::Loading;
    info.startTime = Clock::now();
    info.dataSize = 0;
    
    resources_[url] = info;
    stats_.totalResources++;
    stats_.resourcesByType[type]++;
    
    Log::Info(Event::General, "%s: Started loading %s: %s", TAG, type.c_str(), url.c_str());
    
    // 通知观察者
    for (auto& observer : observers_) {
        if (observer) {
            observer->onResourceLoading(info);
        }
    }
}

void StyleLoadingDebugger::trackResourceSuccess(const std::string& url, size_t dataSize) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = resources_.find(url);
    if (it != resources_.end()) {
        it->second.state = ResourceLoadState::Success;
        it->second.endTime = Clock::now();
        it->second.dataSize = dataSize;
        
        stats_.loadedResources++;
        
        auto duration = it->second.getDuration();
        Log::Info(Event::General, "%s: Loaded %s (%.2f KB) in %.2f ms: %s",
                  TAG, it->second.type.c_str(),
                  dataSize / 1024.0,
                  std::chrono::duration<double, std::milli>(duration).count(),
                  url.c_str());
        
        // 通知观察者
        for (auto& observer : observers_) {
            if (observer) {
                observer->onResourceLoaded(it->second);
            }
        }
        
        updateStats();
        notifyObservers();
    }
}

void StyleLoadingDebugger::trackResourceFailure(const std::string& url, const std::string& error) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = resources_.find(url);
    if (it != resources_.end()) {
        it->second.state = ResourceLoadState::Failed;
        it->second.endTime = Clock::now();
        it->second.errorMessage = error;
        
        stats_.failedResources++;
        stats_.failedByType[it->second.type]++;
        
        Log::Warning(Event::General, "%s: Failed to load %s: %s (error: %s)",
                     TAG, it->second.type.c_str(), url.c_str(), error.c_str());
        
        // 通知观察者
        for (auto& observer : observers_) {
            if (observer) {
                observer->onResourceFailed(it->second);
            }
        }
        
        updateStats();
        notifyObservers();
    }
}

void StyleLoadingDebugger::trackSourceCreated(const std::string& id, const std::string& type) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    SourceDebugInfo info;
    info.id = id;
    info.type = type;
    info.initialized = false;
    info.tileCount = 0;
    info.loadedTiles = 0;
    info.createTime = Clock::now();
    
    sources_[id] = info;
    
    Log::Info(Event::General, "%s: Source created: %s (type: %s)", TAG, id.c_str(), type.c_str());
    
    // 通知观察者
    for (auto& observer : observers_) {
        if (observer) {
            observer->onSourceCreated(info);
        }
    }
}

void StyleLoadingDebugger::trackLayerCreated(const std::string& id, const std::string& type,
                                             const std::string& sourceId) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    LayerDebugInfo info;
    info.id = id;
    info.type = type;
    info.sourceId = sourceId;
    info.visible = true;
    info.createTime = Clock::now();
    
    layers_[id] = info;
    
    Log::Info(Event::General, "%s: Layer created: %s (type: %s, source: %s)",
              TAG, id.c_str(), type.c_str(), sourceId.c_str());
    
    // 通知观察者
    for (auto& observer : observers_) {
        if (observer) {
            observer->onLayerCreated(info);
        }
    }
}

void StyleLoadingDebugger::updateSourceTileCount(const std::string& id, size_t total, size_t loaded) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = sources_.find(id);
    if (it != sources_.end()) {
        it->second.tileCount = total;
        it->second.loadedTiles = loaded;
        it->second.initialized = true;
    }
}

StyleLoadingStats StyleLoadingDebugger::getStats() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return stats_;
}

std::vector<ResourceLoadInfo> StyleLoadingDebugger::getResources() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<ResourceLoadInfo> result;
    result.reserve(resources_.size());
    
    for (const auto& pair : resources_) {
        result.push_back(pair.second);
    }
    
    // 按开始时间排序
    std::sort(result.begin(), result.end(),
              [](const ResourceLoadInfo& a, const ResourceLoadInfo& b) {
                  return a.startTime < b.startTime;
              });
    
    return result;
}

std::vector<SourceDebugInfo> StyleLoadingDebugger::getSources() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<SourceDebugInfo> result;
    result.reserve(sources_.size());
    
    for (const auto& pair : sources_) {
        result.push_back(pair.second);
    }
    
    return result;
}

std::vector<LayerDebugInfo> StyleLoadingDebugger::getLayers() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<LayerDebugInfo> result;
    result.reserve(layers_.size());
    
    for (const auto& pair : layers_) {
        result.push_back(pair.second);
    }
    
    return result;
}

void StyleLoadingDebugger::addObserver(std::shared_ptr<StyleLoadingDebuggerObserver> observer) {
    if (!observer) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    observers_.push_back(observer);
    Log::Info(Event::General, "%s: Observer added (total: %zu)", TAG, observers_.size());
}

void StyleLoadingDebugger::removeObserver(std::shared_ptr<StyleLoadingDebuggerObserver> observer) {
    if (!observer) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    observers_.erase(
        std::remove(observers_.begin(), observers_.end(), observer),
        observers_.end()
    );
    Log::Info(Event::General, "%s: Observer removed (total: %zu)", TAG, observers_.size());
}

void StyleLoadingDebugger::reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    resources_.clear();
    sources_.clear();
    layers_.clear();
    
    stats_ = StyleLoadingStats();
    stats_.startTime = Clock::now();
    currentPhase_ = StyleLoadingPhase::NotStarted;
    stats_.currentPhase = currentPhase_;
    
    Log::Info(Event::General, "%s: State reset", TAG);
}

void StyleLoadingDebugger::updateStats() {
    // 计算平均加载时间
    Duration totalDuration = Duration::zero();
    Duration maxDuration = Duration::zero();
    size_t completedCount = 0;
    
    for (const auto& pair : resources_) {
        const auto& info = pair.second;
        if (info.state == ResourceLoadState::Success) {
            auto duration = info.getDuration();
            totalDuration += duration;
            maxDuration = std::max(maxDuration, duration);
            completedCount++;
        }
    }
    
    if (completedCount > 0) {
        stats_.averageLoadTime = totalDuration / completedCount;
        stats_.maxLoadTime = maxDuration;
    }
}

void StyleLoadingDebugger::notifyObservers() {
    for (auto& observer : observers_) {
        if (observer) {
            observer->onStatsUpdated(stats_);
        }
    }
}

std::string StyleLoadingDebugger::exportReport() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::ostringstream oss;
    oss << std::fixed << std::setprecision(2);
    
    oss << "{\n";
    oss << "  \"phase\": \"" << phaseToString(currentPhase_) << "\",\n";
    oss << "  \"stats\": {\n";
    oss << "    \"totalResources\": " << stats_.totalResources << ",\n";
    oss << "    \"loadedResources\": " << stats_.loadedResources << ",\n";
    oss << "    \"failedResources\": " << stats_.failedResources << ",\n";
    oss << "    \"progress\": " << (stats_.getProgress() * 100) << ",\n";
    oss << "    \"totalLoadTime\": " 
        << std::chrono::duration<double>(stats_.totalLoadTime).count() << ",\n";
    oss << "    \"averageLoadTime\": " 
        << std::chrono::duration<double>(stats_.averageLoadTime).count() << ",\n";
    oss << "    \"maxLoadTime\": " 
        << std::chrono::duration<double>(stats_.maxLoadTime).count() << "\n";
    oss << "  },\n";
    
    oss << "  \"sources\": [\n";
    bool first = true;
    for (const auto& pair : sources_) {
        if (!first) oss << ",\n";
        first = false;
        const auto& src = pair.second;
        oss << "    {\n";
        oss << "      \"id\": \"" << src.id << "\",\n";
        oss << "      \"type\": \"" << src.type << "\",\n";
        oss << "      \"initialized\": " << (src.initialized ? "true" : "false") << ",\n";
        oss << "      \"tileCount\": " << src.tileCount << ",\n";
        oss << "      \"loadedTiles\": " << src.loadedTiles << "\n";
        oss << "    }";
    }
    oss << "\n  ],\n";
    
    oss << "  \"layers\": [\n";
    first = true;
    for (const auto& pair : layers_) {
        if (!first) oss << ",\n";
        first = false;
        const auto& layer = pair.second;
        oss << "    {\n";
        oss << "      \"id\": \"" << layer.id << "\",\n";
        oss << "      \"type\": \"" << layer.type << "\",\n";
        oss << "      \"sourceId\": \"" << layer.sourceId << "\",\n";
        oss << "      \"visible\": " << (layer.visible ? "true" : "false") << "\n";
        oss << "    }";
    }
    oss << "\n  ],\n";
    
    oss << "  \"resources\": [\n";
    first = true;
    for (const auto& pair : resources_) {
        if (!first) oss << ",\n";
        first = false;
        const auto& res = pair.second;
        oss << "    {\n";
        oss << "      \"url\": \"" << res.url << "\",\n";
        oss << "      \"type\": \"" << res.type << "\",\n";
        oss << "      \"state\": \"" << stateToString(res.state) << "\",\n";
        oss << "      \"dataSize\": " << res.dataSize << ",\n";
        oss << "      \"duration\": " 
            << std::chrono::duration<double, std::milli>(res.getDuration()).count() << ",\n";
        oss << "      \"error\": \"" << res.errorMessage << "\"\n";
        oss << "    }";
    }
    oss << "\n  ]\n";
    oss << "}\n";
    
    return oss.str();
}

} // namespace harmony
} // namespace mbgl

