#pragma once

#include <napi/native_api.h>
#include <mbgl/style/transition_options.hpp>

namespace mbgl {
namespace harmony {

/**
 * TransitionOptions NAPI conversion helper
 *
 * Bridges mbgl::style::TransitionOptions (C++) with ETS TransitionOptions objects.
 * ETS definition: { duration: number, delay: number }
 */
class TransitionOptionsHarmony {
public:
    /**
     * Create a TransitionOptions NAPI object.
     * @param env NAPI environment
     * @param options mbgl::style::TransitionOptions C++ object
     * @return NAPI object { duration: number, delay: number }
     */
    static napi_value CreateTransitionOptionsObject(napi_env env, const mbgl::style::TransitionOptions& options);
    
    /**
     * Parse TransitionOptions from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param outOptions Output mbgl::style::TransitionOptions
     * @return Whether parsing succeeded
     */
    static bool ParseTransitionOptions(napi_env env, napi_value value, mbgl::style::TransitionOptions& outOptions);
};

} // namespace harmony
} // namespace mbgl

