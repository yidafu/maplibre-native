#pragma once

#include <napi/native_api.h>
#include <mln/style/transition_options.hpp>

namespace mln {
namespace harmony {

/**
 * TransitionOptions NAPI conversion helper
 *
 * Bridges mln::style::TransitionOptions (C++) with ETS TransitionOptions objects.
 * ETS definition: { duration: number, delay: number }
 */
class TransitionOptionsHarmony {
public:
    /**
     * Create a TransitionOptions NAPI object.
     * @param env NAPI environment
     * @param options mln::style::TransitionOptions C++ object
     * @param defaultDurationMs Duration (ms) reported when options.duration is
     *        unset; defaults to 0. GetTransition passes 300 to keep showing the
     *        historical default.
     * @return NAPI object { duration: number, delay: number }
     */
    static napi_value CreateTransitionOptionsObject(napi_env env, const mln::style::TransitionOptions& options,
                                                    double defaultDurationMs = 0.0);
    
    /**
     * Parse TransitionOptions from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param outOptions Output mln::style::TransitionOptions
     * @return Whether parsing succeeded
     */
    static bool ParseTransitionOptions(napi_env env, napi_value value, mln::style::TransitionOptions& outOptions);
};

} // namespace harmony
} // namespace mln

