#include "style_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "style/layer_source_factory_harmony.hpp"
#include <mln/style/style.hpp>
#include <mln/style/source.hpp>

using namespace mln::harmony::napi;
using mln::harmony::Logger;

namespace mln {
namespace harmony {

// ==================== Source management ====================

napi_value StyleNAPI::RemoveSource(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->acquireMap()) {
        Logger::error("StyleNAPI", "RemoveSource: Invalid style or map");
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    std::string sourceId = GetStringFromValue(env, napiArgs.GetValue(0));
    if (napiArgs.HasError()) {
        return nullptr;
    }
    if (sourceId.empty()) {
        napi_throw_error(env, nullptr, "sourceId cannot be empty");
        return nullptr;
    }
    
    try {
        bool removed = false;
        style->runOnMap([&](mln::Map& m) {
            if (m.getStyle().getSource(sourceId)) {
                m.getStyle().removeSource(sourceId);
                removed = true;
            }
        });
        if (!removed) {
            Logger::error("StyleNAPI", "RemoveSource: Source not found: %s", sourceId.c_str());
            napi_throw_error(env, nullptr, "Source not found");
            return nullptr;
        }
        style->sources.erase(sourceId);

        Logger::info("StyleNAPI", "RemoveSource: %s", sourceId.c_str());

        return napiArgs.Undefined();
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "RemoveSource failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value StyleNAPI::GetSource(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->acquireMap()) {
        Logger::error("StyleNAPI", "GetSource: Invalid style or map");
        return napiArgs.Null();
    }
    
    std::string sourceId = GetStringFromValue(env, napiArgs.GetValue(0));
    if (napiArgs.HasError()) {
        return nullptr;
    }
    if (sourceId.empty()) {
        napi_throw_error(env, nullptr, "sourceId cannot be empty");
        return nullptr;
    }
    
    // Resolve the source on the render thread; the NAPI peer is built below.
    mln::style::Source* source = nullptr;
    try {
        style->runOnMap([&](mln::Map& m) {
            source = m.getStyle().getSource(sourceId);
        });
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetSource failed: %s", e.what());
        source = nullptr;
    }

    if (!source) {
        Logger::info("StyleNAPI", "GetSource: Source not found: %s", sourceId.c_str());
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    {
        Logger::info("StyleNAPI", "GetSource: %s (type: %d)", sourceId.c_str(), static_cast<int>(source->getType()));

        // Create the corresponding NAPI instance through the shared factory
        // (same per-type CreateInstance dispatch as before). Null fallback
        // keeps the historical "unknown source type" branch observable.
        napi_value wrapper = mln::harmony::LayerSourceFactory::createSourceWrapper(
            env, source, mln::harmony::WrapperFallback::Null);
        napi_valuetype wrapperType = napi_undefined;
        napi_typeof(env, wrapper, &wrapperType);
        if (wrapperType == napi_null) {
            Logger::warn("StyleNAPI", "GetSource: Unknown source type: %d", static_cast<int>(source->getType()));
            return napiArgs.Null();
        }
        return wrapper;
    }
}

napi_value StyleNAPI::GetSources(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->acquireMap()) {
        Logger::error("StyleNAPI", "GetSources: Invalid style or map");
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        // Snapshot the source list on the render thread
        std::vector<mln::style::Source*> sourceList;
        style->runOnMap([&](mln::Map& m) {
            const auto& sources = m.getStyle().getSources();
            sourceList.reserve(sources.size());
            for (const auto& source : sources) {
                sourceList.push_back(source);
            }
        });

        // Create the result array
        napi_value result;
        napi_create_array_with_length(env, sourceList.size(), &result);

        size_t index = 0;
        for (const auto& source : sourceList) {
            if (!source) continue;
            
            // Create the source info object
            napi_value sourceObj;
            napi_create_object(env, &sourceObj);
            
            napi_value idValue = CreateStringValue(env, source->getID());
            napi_set_named_property(env, sourceObj, "id", idValue);
            
            // Determine the source type (single shared spelling)
            const std::string typeStr = mln::harmony::LayerSourceFactory::SourceTypeToString(source->getType());

            napi_value typeValue = CreateStringValue(env, typeStr);
            napi_set_named_property(env, sourceObj, "type", typeValue);
            
            napi_set_element(env, result, index++, sourceObj);
        }
        
        return result;
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetSources failed: %s", e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

} // namespace harmony
} // namespace mln

