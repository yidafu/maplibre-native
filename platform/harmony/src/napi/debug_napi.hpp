#pragma once

#include <napi/native_api.h>

namespace mbgl {
namespace harmony {

// Enable/Disable style loading debugger
napi_value EnableStyleDebugger(napi_env env, napi_callback_info info);
napi_value DisableStyleDebugger(napi_env env, napi_callback_info info);

// Get style loading stats
napi_value GetStyleStats(napi_env env, napi_callback_info info);
napi_value GetResources(napi_env env, napi_callback_info info);
napi_value GetSources(napi_env env, napi_callback_info info);
napi_value GetLayers(napi_env env, napi_callback_info info);

// Enable/Disable resource monitor
napi_value EnableResourceMonitor(napi_env env, napi_callback_info info);
napi_value DisableResourceMonitor(napi_env env, napi_callback_info info);

// Get resource monitoring stats
napi_value GetHttpStats(napi_env env, napi_callback_info info);
napi_value GetCacheStats(napi_env env, napi_callback_info info);
napi_value GetAlerts(napi_env env, napi_callback_info info);

// Export complete debug report
napi_value ExportDebugReport(napi_env env, napi_callback_info info);

// Register all debug NAPI functions
void RegisterDebugNAPI(napi_env env, napi_value exports);

} // namespace harmony
} // namespace mbgl

