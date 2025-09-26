#pragma once

#include <node_api.h>
#include <mbgl/style/conversion_impl.hpp>
#include <mbgl/style/expression/expression.hpp>
#include <exception>
#include <memory>
#include "napi_utils.hpp"

namespace node_mbgl {

napi_value toJS(napi_env env, const mbgl::style::expression::Value&);

class NodeExpression {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    static napi_value Parse(napi_env env, napi_callback_info info);
    static napi_value Evaluate(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    static napi_value IsFeatureConstant(napi_env env, napi_callback_info info);
    static napi_value IsZoomConstant(napi_env env, napi_callback_info info);
    static napi_value Serialize(napi_env env, napi_callback_info info);

    NodeExpression(std::unique_ptr<mbgl::style::expression::Expression> expression_)
        : expression(std::move(expression_)) {};
    ~NodeExpression() = default;

private:
    static inline napi_ref constructor = nullptr;
    std::unique_ptr<mbgl::style::expression::Expression> expression;
};

} // namespace node_mbgl
