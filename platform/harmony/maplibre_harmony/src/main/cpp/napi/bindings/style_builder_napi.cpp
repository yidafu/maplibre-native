#include "style_builder_napi.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

// Static member initialization
napi_ref StyleBuilderNAPI::constructor = nullptr;

StyleBuilderNAPI::StyleBuilderNAPI()
    : styleUri(""), styleJson("") {
    Logger::info("StyleBuilderNAPI", "StyleBuilder instance created");
}

StyleBuilderNAPI::~StyleBuilderNAPI() {
    Logger::info("StyleBuilderNAPI", "StyleBuilder instance destroyed");
}

void StyleBuilderNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    Logger::debug("StyleBuilderNAPI", "Destructor called");
    StyleBuilderNAPI* builder = static_cast<StyleBuilderNAPI*>(nativeObject);
    delete builder;
}

napi_value StyleBuilderNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("StyleBuilderNAPI", "Initializing StyleBuilder NAPI class");
    
    napi_property_descriptor properties[] = {
        // Builder 方法
        { "fromUri", nullptr, FromUri, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "fromJson", nullptr, FromJson, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "withSource", nullptr, WithSource, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "withLayer", nullptr, WithLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "withImage", nullptr, WithImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "withTransitionOptions", nullptr, WithTransitionOptions, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "StyleBuilder", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("StyleBuilderNAPI", "Failed to define StyleBuilder class");
        return nullptr;
    }
    
    // 创建构造函数引用
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("StyleBuilderNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    // 将构造函数添加到 exports
    status = napi_set_named_property(env, exports, "StyleBuilder", cons);
    if (status != napi_ok) {
        Logger::error("StyleBuilderNAPI", "Failed to set StyleBuilder property");
        return nullptr;
    }
    
    Logger::info("StyleBuilderNAPI", "StyleBuilder NAPI class initialized successfully");
    return exports;
}

napi_value StyleBuilderNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    // 创建 C++ 对象
    StyleBuilderNAPI* builder = new StyleBuilderNAPI();
    
    // Wrap 到 JS 对象
    napi_status status = napi_wrap(env, jsThis, builder, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete builder;
        napi_throw_error(env, nullptr, "Failed to wrap StyleBuilder object");
        return nullptr;
    }
    
    Logger::debug("StyleBuilderNAPI", "StyleBuilder instance created");
    return jsThis;
}

// ==================== Builder 方法 ====================

napi_value StyleBuilderNAPI::FromUri(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "fromUri requires uri argument");
        return nullptr;
    }
    
    builder->styleUri = GetStringFromValue(env, args[0]);
    Logger::info("StyleBuilderNAPI", "fromUri: %s", builder->styleUri.c_str());
    
    // 返回 this 支持链式调用
    return jsThis;
}

napi_value StyleBuilderNAPI::FromJson(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "fromJson requires json argument");
        return nullptr;
    }
    
    builder->styleJson = GetStringFromValue(env, args[0]);
    Logger::info("StyleBuilderNAPI", "fromJson: %zu bytes", builder->styleJson.length());
    
    // 返回 this 支持链式调用
    return jsThis;
}

napi_value StyleBuilderNAPI::WithSource(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    // TODO: 实现预加载 source
    Logger::warn("StyleBuilderNAPI", "withSource not fully implemented yet");
    
    // 返回 this 支持链式调用
    return jsThis;
}

napi_value StyleBuilderNAPI::WithLayer(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    // TODO: 实现预加载 layer
    Logger::warn("StyleBuilderNAPI", "withLayer not fully implemented yet");
    
    // 返回 this 支持链式调用
    return jsThis;
}

napi_value StyleBuilderNAPI::WithImage(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    // TODO: 实现预加载 image
    Logger::warn("StyleBuilderNAPI", "withImage not fully implemented yet");
    
    // 返回 this 支持链式调用
    return jsThis;
}

napi_value StyleBuilderNAPI::WithTransitionOptions(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    // TODO: 实现过渡选项
    Logger::warn("StyleBuilderNAPI", "withTransitionOptions not fully implemented yet");
    
    // 返回 this 支持链式调用
    return jsThis;
}

} // namespace harmony
} // namespace maplibre

