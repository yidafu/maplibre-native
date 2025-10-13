#include <mbgl/util/logging.hpp>
#include <mbgl/util/string.hpp>
#include "attach_env.hpp"

namespace mbgl {
namespace platform {

std::string uppercase(const std::string& str) {
    auto env{harmony::AttachEnv()};
    
    // Harmony平台上的字符串大写转换实现
    // 这里使用简单的ASCII大写转换作为临时实现
    std::string result;
    result.reserve(str.size());
    
    for (char c : str) {
        if (c >= 'a' && c <= 'z') {
            result.push_back(c - 32);
        } else {
            result.push_back(c);
        }
    }
    
    return result;
}

std::string lowercase(const std::string& str) {
    auto env{harmony::AttachEnv()};
    
    // Harmony平台上的字符串小写转换实现
    // 这里使用简单的ASCII小写转换作为临时实现
    std::string result;
    result.reserve(str.size());
    
    for (char c : str) {
        if (c >= 'A' && c <= 'Z') {
            result.push_back(c + 32);
        } else {
            result.push_back(c);
        }
    }
    
    return result;
}

} // namespace platform
} // namespace mbgl