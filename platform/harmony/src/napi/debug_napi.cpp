#include "debug_napi.hpp"
#include "../debug/style_loading_debugger.hpp"
#include "../debug/resource_monitor.hpp"
#include <mbgl/util/logging.hpp>
#include <napi/native_api.h>
#include <memory>

namespace mbgl {
namespace harmony {

namespace {
const char* TAG = "DebugNAPI";

// Helper function to create JS number
napi_value CreateNumber(napi_env env, double value) {
    napi_value result;
    napi_create_double(env, value, &result);
    return result;
}

// Helper function to create JS string
napi_value CreateString(napi_env env, const std::string& str) {
    napi_value result;
    napi_create_string_utf8(env, str.c_str(), str.length(), &result);
    return result;
}

// Helper function to create JS boolean
napi_value CreateBoolean(napi_env env, bool value) {
    napi_value result;
    napi_get_boolean(env, value, &result);
    return result;
}

// Convert ResourceLoadInfo to JS object
napi_value ResourceInfoToJS(napi_env env, const ResourceLoadInfo& info) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    napi_set_named_property(env, obj, "url", CreateString(env, info.url));
    napi_set_named_property(env, obj, "type", CreateString(env, info.type));
    napi_set_named_property(env, obj, "state", CreateNumber(env, static_cast<int>(info.state)));
    napi_set_named_property(env, obj, "dataSize", CreateNumber(env, info.dataSize));
    
    auto duration = std::chrono::duration<double, std::milli>(info.getDuration()).count();
    napi_set_named_property(env, obj, "duration", CreateNumber(env, duration));
    napi_set_named_property(env, obj, "error", CreateString(env, info.errorMessage));
    
    return obj;
}

// Convert SourceDebugInfo to JS object
napi_value SourceInfoToJS(napi_env env, const SourceDebugInfo& info) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    napi_set_named_property(env, obj, "id", CreateString(env, info.id));
    napi_set_named_property(env, obj, "type", CreateString(env, info.type));
    napi_set_named_property(env, obj, "initialized", CreateBoolean(env, info.initialized));
    napi_set_named_property(env, obj, "tileCount", CreateNumber(env, info.tileCount));
    napi_set_named_property(env, obj, "loadedTiles", CreateNumber(env, info.loadedTiles));
    
    return obj;
}

// Convert LayerDebugInfo to JS object
napi_value LayerInfoToJS(napi_env env, const LayerDebugInfo& info) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    napi_set_named_property(env, obj, "id", CreateString(env, info.id));
    napi_set_named_property(env, obj, "type", CreateString(env, info.type));
    napi_set_named_property(env, obj, "sourceId", CreateString(env, info.sourceId));
    napi_set_named_property(env, obj, "visible", CreateBoolean(env, info.visible));
    
    return obj;
}

// Convert StyleLoadingStats to JS object
napi_value StyleStatsToJS(napi_env env, const StyleLoadingStats& stats) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    napi_set_named_property(env, obj, "currentPhase", 
                           CreateNumber(env, static_cast<int>(stats.currentPhase)));
    napi_set_named_property(env, obj, "totalResources", 
                           CreateNumber(env, stats.totalResources));
    napi_set_named_property(env, obj, "loadedResources", 
                           CreateNumber(env, stats.loadedResources));
    napi_set_named_property(env, obj, "failedResources", 
                           CreateNumber(env, stats.failedResources));
    napi_set_named_property(env, obj, "progress", 
                           CreateNumber(env, stats.getProgress()));
    
    auto totalLoadTime = std::chrono::duration<double>(stats.totalLoadTime).count();
    napi_set_named_property(env, obj, "totalLoadTime", CreateNumber(env, totalLoadTime));
    
    auto avgLoadTime = std::chrono::duration<double>(stats.averageLoadTime).count();
    napi_set_named_property(env, obj, "averageLoadTime", CreateNumber(env, avgLoadTime));
    
    return obj;
}

// Convert HttpRequestStats to JS object
napi_value HttpStatsToJS(napi_env env, const HttpRequestStats& stats) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    napi_set_named_property(env, obj, "totalRequests", 
                           CreateNumber(env, stats.totalRequests));
    napi_set_named_property(env, obj, "successRequests", 
                           CreateNumber(env, stats.successRequests));
    napi_set_named_property(env, obj, "failedRequests", 
                           CreateNumber(env, stats.failedRequests));
    napi_set_named_property(env, obj, "pendingRequests", 
                           CreateNumber(env, stats.pendingRequests));
    napi_set_named_property(env, obj, "successRate", 
                           CreateNumber(env, stats.getSuccessRate()));
    napi_set_named_property(env, obj, "totalBytes", 
                           CreateNumber(env, stats.totalBytes));
    
    auto avgDuration = std::chrono::duration<double, std::milli>(stats.avgDuration).count();
    napi_set_named_property(env, obj, "avgDuration", CreateNumber(env, avgDuration));
    
    auto maxDuration = std::chrono::duration<double, std::milli>(stats.maxDuration).count();
    napi_set_named_property(env, obj, "maxDuration", CreateNumber(env, maxDuration));
    
    return obj;
}

// Convert CacheStats to JS object
napi_value CacheStatsToJS(napi_env env, const CacheStats& stats) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    napi_set_named_property(env, obj, "totalQueries", 
                           CreateNumber(env, stats.totalQueries));
    napi_set_named_property(env, obj, "cacheHits", 
                           CreateNumber(env, stats.cacheHits));
    napi_set_named_property(env, obj, "cacheMisses", 
                           CreateNumber(env, stats.cacheMisses));
    napi_set_named_property(env, obj, "hitRate", 
                           CreateNumber(env, stats.getHitRate()));
    napi_set_named_property(env, obj, "cacheSize", 
                           CreateNumber(env, stats.cacheSize));
    napi_set_named_property(env, obj, "maxCacheSize", 
                           CreateNumber(env, stats.maxCacheSize));
    
    return obj;
}

// Convert AlertInfo to JS object
napi_value AlertInfoToJS(napi_env env, const AlertInfo& alert) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // Type string conversion
    const char* typeStr = "Unknown";
    switch (alert.type) {
        case AlertType::HighFailureRate: typeStr = "HighFailureRate"; break;
        case AlertType::SlowResponse: typeStr = "SlowResponse"; break;
        case AlertType::LowCacheHitRate: typeStr = "LowCacheHitRate"; break;
        case AlertType::StyleLoadTimeout: typeStr = "StyleLoadTimeout"; break;
        case AlertType::NetworkError: typeStr = "NetworkError"; break;
    }
    
    napi_set_named_property(env, obj, "type", CreateString(env, typeStr));
    napi_set_named_property(env, obj, "message", CreateString(env, alert.message));
    
    auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        alert.timestamp.time_since_epoch()).count();
    napi_set_named_property(env, obj, "timestamp", CreateNumber(env, timestamp));
    
    // Details object
    napi_value detailsObj;
    napi_create_object(env, &detailsObj);
    for (const auto& pair : alert.details) {
        napi_set_named_property(env, detailsObj, pair.first.c_str(), 
                               CreateString(env, pair.second));
    }
    napi_set_named_property(env, obj, "details", detailsObj);
    
    return obj;
}

} // namespace

// Enable style loading debugger
napi_value EnableStyleDebugger(napi_env env, napi_callback_info info) {
    auto& debugger = StyleLoadingDebugger::getInstance();
    debugger.enable();
    
    Log::Info(Event::General, "%s: Style debugger enabled", TAG);
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

// Disable style loading debugger
napi_value DisableStyleDebugger(napi_env env, napi_callback_info info) {
    auto& debugger = StyleLoadingDebugger::getInstance();
    debugger.disable();
    
    Log::Info(Event::General, "%s: Style debugger disabled", TAG);
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

// Get style loading stats
napi_value GetStyleStats(napi_env env, napi_callback_info info) {
    auto& debugger = StyleLoadingDebugger::getInstance();
    
    if (!debugger.isEnabled()) {
        napi_value nullValue;
        napi_get_null(env, &nullValue);
        return nullValue;
    }
    
    auto stats = debugger.getStats();
    return StyleStatsToJS(env, stats);
}

// Get resources
napi_value GetResources(napi_env env, napi_callback_info info) {
    auto& debugger = StyleLoadingDebugger::getInstance();
    
    auto resources = debugger.getResources();
    
    napi_value array;
    napi_create_array_with_length(env, resources.size(), &array);
    
    for (size_t i = 0; i < resources.size(); i++) {
        napi_value item = ResourceInfoToJS(env, resources[i]);
        napi_set_element(env, array, i, item);
    }
    
    return array;
}

// Get sources
napi_value GetSources(napi_env env, napi_callback_info info) {
    auto& debugger = StyleLoadingDebugger::getInstance();
    
    auto sources = debugger.getSources();
    
    napi_value array;
    napi_create_array_with_length(env, sources.size(), &array);
    
    for (size_t i = 0; i < sources.size(); i++) {
        napi_value item = SourceInfoToJS(env, sources[i]);
        napi_set_element(env, array, i, item);
    }
    
    return array;
}

// Get layers
napi_value GetLayers(napi_env env, napi_callback_info info) {
    auto& debugger = StyleLoadingDebugger::getInstance();
    
    auto layers = debugger.getLayers();
    
    napi_value array;
    napi_create_array_with_length(env, layers.size(), &array);
    
    for (size_t i = 0; i < layers.size(); i++) {
        napi_value item = LayerInfoToJS(env, layers[i]);
        napi_set_element(env, array, i, item);
    }
    
    return array;
}

// Enable resource monitor
napi_value EnableResourceMonitor(napi_env env, napi_callback_info info) {
    auto& monitor = ResourceMonitor::getInstance();
    monitor.enable();
    
    Log::Info(Event::General, "%s: Resource monitor enabled", TAG);
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

// Disable resource monitor
napi_value DisableResourceMonitor(napi_env env, napi_callback_info info) {
    auto& monitor = ResourceMonitor::getInstance();
    monitor.disable();
    
    Log::Info(Event::General, "%s: Resource monitor disabled", TAG);
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

// Get HTTP stats
napi_value GetHttpStats(napi_env env, napi_callback_info info) {
    auto& monitor = ResourceMonitor::getInstance();
    
    if (!monitor.isEnabled()) {
        napi_value nullValue;
        napi_get_null(env, &nullValue);
        return nullValue;
    }
    
    auto stats = monitor.getHttpStats();
    return HttpStatsToJS(env, stats);
}

// Get cache stats
napi_value GetCacheStats(napi_env env, napi_callback_info info) {
    auto& monitor = ResourceMonitor::getInstance();
    
    if (!monitor.isEnabled()) {
        napi_value nullValue;
        napi_get_null(env, &nullValue);
        return nullValue;
    }
    
    auto stats = monitor.getCacheStats();
    return CacheStatsToJS(env, stats);
}

// Get alerts
napi_value GetAlerts(napi_env env, napi_callback_info info) {
    auto& monitor = ResourceMonitor::getInstance();
    
    auto alerts = monitor.getAlerts();
    
    napi_value array;
    napi_create_array_with_length(env, alerts.size(), &array);
    
    for (size_t i = 0; i < alerts.size(); i++) {
        napi_value item = AlertInfoToJS(env, alerts[i]);
        napi_set_element(env, array, i, item);
    }
    
    return array;
}

// Export debug report
napi_value ExportDebugReport(napi_env env, napi_callback_info info) {
    auto& styleDebugger = StyleLoadingDebugger::getInstance();
    auto& resourceMonitor = ResourceMonitor::getInstance();
    
    std::string report = "{\n";
    report += "  \"styleLoading\": " + styleDebugger.exportReport() + ",\n";
    report += "  \"resourceMonitoring\": " + resourceMonitor.exportReport() + "\n";
    report += "}\n";
    
    return CreateString(env, report);
}

// Register debug NAPI functions
void RegisterDebugNAPI(napi_env env, napi_value exports) {
    napi_property_descriptor descriptors[] = {
        {"enableStyleDebugger", nullptr, EnableStyleDebugger, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"disableStyleDebugger", nullptr, DisableStyleDebugger, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getStyleStats", nullptr, GetStyleStats, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getResources", nullptr, GetResources, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getSources", nullptr, GetSources, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLayers", nullptr, GetLayers, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"enableResourceMonitor", nullptr, EnableResourceMonitor, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"disableResourceMonitor", nullptr, DisableResourceMonitor, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getHttpStats", nullptr, GetHttpStats, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getCacheStats", nullptr, GetCacheStats, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getAlerts", nullptr, GetAlerts, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"exportDebugReport", nullptr, ExportDebugReport, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    
    Log::Info(Event::General, "%s: Debug NAPI functions registered", TAG);
}

} // namespace harmony
} // namespace mbgl

