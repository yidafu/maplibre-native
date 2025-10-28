#pragma once

#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/util.hpp>

#include <uv.h>
#include <memory>
#include <functional>
#include <unordered_map>

namespace mbgl {
namespace util {

// Forward declaration
struct Watch;
class AsyncTask;

class RunLoop::Impl {
public:
    Impl(RunLoop*, RunLoop::Type);
    ~Impl();

    void closeHolder();  // 实现在 run_loop.cpp 中

    uv_handle_t* holderHandle() { 
        // ✅ 如果已关闭，返回 nullptr 防止访问悬空指针
        return holderClosed ? nullptr : reinterpret_cast<uv_handle_t*>(holder); 
    }
    
    bool isHolderClosed() const { return holderClosed; }

    uv_loop_t* loop = nullptr;
    uv_async_t* holder = new uv_async_t;

    RunLoop::Type type;
    std::unique_ptr<AsyncTask> async;

    std::unordered_map<int, std::unique_ptr<Watch>> watchPoll;

private:
    bool holderClosed = false;  // ✅ 修复退出崩溃：防止 holder 被重复删除
};

} // namespace util
} // namespace mbgl
