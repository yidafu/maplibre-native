#include "node_logging.hpp"
#include <mbgl/util/enum.hpp>

namespace node_mbgl {

struct NodeLogObserver::LogMessage {
    mbgl::EventSeverity severity;
    mbgl::Event event;
    int64_t code;
    std::string text;

    LogMessage(mbgl::EventSeverity severity_, mbgl::Event event_, int64_t code_, std::string text_)
        : severity(severity_),
          event(event_),
          code(code_),
          text(std::move(text_)) {};
};

NodeLogObserver::NodeLogObserver(napi_env env, napi_value target)
    : env(env),
      queue(new util::AsyncQueue<LogMessage>(uv_default_loop(), [this](LogMessage &message) {
          napi_value msg = node_mbgl::napi_utils::createObject(env);

          node_mbgl::napi_utils::setProperty(env, msg,
                                            "class",
                                            node_mbgl::napi_utils::createString(env, mbgl::Enum<mbgl::Event>::toString(message.event)));

          node_mbgl::napi_utils::setProperty(env, msg,
                                            "severity",
                                            node_mbgl::napi_utils::createString(env, mbgl::Enum<mbgl::EventSeverity>::toString(message.severity)));

          if (message.code != -1) {
              node_mbgl::napi_utils::setProperty(env, msg, "code", node_mbgl::napi_utils::createNumber(env, message.code));
          }

          if (!message.text.empty()) {
              node_mbgl::napi_utils::setProperty(env, msg, "text", node_mbgl::napi_utils::createString(env, message.text));
          }

          napi_value argv[2];
          argv[0] = node_mbgl::napi_utils::createString(env, "message");
          argv[1] = msg;
          
          napi_value handle;
          napi_get_reference_value(env, moduleRef, &handle);
          
          napi_value emit;
          node_mbgl::napi_utils::getProperty(env, handle, "emit", &emit);
          
          node_mbgl::napi_utils::callAsFunction(env, emit, handle, 2, argv, nullptr);
      })) {
    napi_create_reference(env, target, 1, &moduleRef);

    // Don't keep the event loop alive.
    queue->unref();
}

NodeLogObserver::~NodeLogObserver() {
    queue->stop();
}

bool NodeLogObserver::onRecord(mbgl::EventSeverity severity, mbgl::Event event, int64_t code, const std::string &text) {
    queue->send({severity, event, code, text});
    return true;
}

} // namespace node_mbgl
