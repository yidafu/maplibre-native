#ifndef MAPLIBRE_HARMONY_QUERY_SOURCE_FEATURES_HPP
#define MAPLIBRE_HARMONY_QUERY_SOURCE_FEATURES_HPP

// Shared body of querySourceFeatures for the GeoJSON and CustomGeometry
// source wrappers. The two implementations used to be line-for-line copies;
// only the log tag and two message details differed, so they are parameters.

#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

#include "geojson/geojson_converter.hpp"
#include "style/filter_conversion.hpp"

#include <mln/renderer/query.hpp>
#include <mln/util/geojson.hpp>

#include <string>
#include <vector>

namespace mln {
namespace harmony {

/**
 * Run a renderer-side querySourceFeatures for `source` and return the features
 * as a JS array. `queryFn` is the renderer hook (may be null while the
 * renderer is not ready). `tag`, `notReadyReason` and `filterFailReason` keep
 * each wrapper's historical log wording. Always returns a JS array.
 */
template <typename HookFn>
napi_value QuerySourceFeaturesImpl(napi_env env, napi_callback_info info,
                                   mln::style::Source* source,
                                   HookFn queryFn,
                                   const char* tag,
                                   const char* notReadyReason,
                                   const char* filterFailReason) {
    napi::NapiArgs args(env, info);

    try {
        if (!queryFn) {
            Logger::warn(tag, "QuerySourceFeatures: %s", notReadyReason);
            return CreateEmptyArray(env);
        }

        // Build query options from the optional filter argument.
        // The ArkTS layer passes `undefined` when no filter is given, so
        // skip undefined/null values before parsing the expression array.
        mln::SourceQueryOptions options;
        if (args.Count() >= 1) {
            napi_value filterValue = args.GetValue(0);
            napi_valuetype type = napi_undefined;
            napi_typeof(env, filterValue, &type);
            if (type == napi_object) {
                bool isArray = false;
                napi_is_array(env, filterValue, &isArray);
                if (isArray) {
                    auto filter = mln::harmony::napiArrayToFilter(env, filterValue);
                    if (filter.has_value()) {
                        options.filter = std::move(*filter);
                    } else {
                        Logger::warn(tag, "QuerySourceFeatures: %s", filterFailReason);
                    }
                }
            }
        }

        // Query the features through the renderer (same path as the Map-level query)
        std::vector<mln::Feature> features = queryFn(source->getID(), options);

        Logger::info(tag, "QuerySourceFeatures: %zu features from source '%s'",
                     features.size(), source->getID().c_str());

        // Convert the results into a NAPI array
        return geojson::GeoJsonConverter::FeatureArrayToJsArray(env, features);
    } catch (const std::exception& e) {
        Logger::error(tag, "QuerySourceFeatures failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return CreateEmptyArray(env);
    }
}

} // namespace harmony
} // namespace mln

#endif // MAPLIBRE_HARMONY_QUERY_SOURCE_FEATURES_HPP
