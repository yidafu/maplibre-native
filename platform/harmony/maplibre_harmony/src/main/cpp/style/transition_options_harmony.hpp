#pragma once

#include <napi/native_api.h>
#include <mbgl/style/transition_options.hpp>

namespace mbgl {
namespace harmony {

/**
 * TransitionOptions NAPI 转换辅助类
 * 
 * 用于在 mbgl::style::TransitionOptions (C++) 和 ETS TransitionOptions 对象之间进行转换
 * ETS 定义: { duration: number, delay: number }
 */
class TransitionOptionsHarmony {
public:
    /**
     * 创建 NAPI TransitionOptions 对象
     * @param env NAPI 环境
     * @param options mbgl::style::TransitionOptions C++ 对象
     * @return NAPI 对象 { duration: number, delay: number }
     */
    static napi_value CreateTransitionOptionsObject(napi_env env, const mbgl::style::TransitionOptions& options);
    
    /**
     * 从 NAPI 值解析 TransitionOptions
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param outOptions 输出的 mbgl::style::TransitionOptions
     * @return 解析是否成功
     */
    static bool ParseTransitionOptions(napi_env env, napi_value value, mbgl::style::TransitionOptions& outOptions);
};

} // namespace harmony
} // namespace mbgl

