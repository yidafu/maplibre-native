#pragma once

#include <node_api.h>
#include "napi_utils.hpp"

#include <mbgl/storage/file_source.hpp>
#include <mbgl/storage/resource.hpp>
#include <mbgl/util/async_request.hpp>

namespace node_mbgl {

class NodeRequest;

struct NodeAsyncRequest : public mbgl::AsyncRequest {
    NodeAsyncRequest();
    ~NodeAsyncRequest() override;
    NodeRequest* request = nullptr;
};

class NodeRequest {
public:
    NodeRequest(mbgl::FileSource::Callback, NodeAsyncRequest*);
    ~NodeRequest();

    static napi_ref constructor;

    static napi_value Init(napi_env, napi_value);
    static napi_value New(napi_env, napi_callback_info);
    static napi_value HandleCallback(napi_env, napi_callback_info);

    void unrefRequest();

    mbgl::FileSource::Callback callback;
    NodeAsyncRequest* asyncRequest;
    napi_env env;
    napi_ref wrapperRef;
    napi_async_context asyncContext;
};

} // namespace node_mbgl
