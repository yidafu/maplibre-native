#pragma once

#include <node_api.h>
#include "napi_utils.hpp"
#include "util/async_queue.hpp"
#include <mbgl/util/logging.hpp>

namespace node_mbgl {

namespace util {
template <typename T>
class AsyncQueue;
}

class NodeLogObserver : public mbgl::Log::Observer {
public:
    NodeLogObserver(napi_env env, napi_value target);
    ~NodeLogObserver() override;

    // Log::Observer implementation
    bool onRecord(mbgl::EventSeverity severity, mbgl::Event event, int64_t code, const std::string& text) override;

private:
    napi_env env;
    napi_ref moduleRef;

    struct LogMessage;
    util::AsyncQueue<LogMessage>* queue;
};

} // namespace node_mbgl
