#pragma once

#include <mbgl/util/feature.hpp>

#include <node_api.h>
#include "napi_utils.hpp"

namespace node_mbgl {

napi_value toJS(napi_env env, const mbgl::Value&);
napi_value toJS(napi_env env, const mbgl::Feature&);
napi_value toJS(napi_env env, const mbgl::Feature::geometry_type&);
napi_value toJS(napi_env env, const mbgl::PropertyMap&);

} // namespace node_mbgl
