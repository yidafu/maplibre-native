#include <mbgl/util/logging.hpp>
#include <mbgl/util/platform.hpp>
#include <mbgl/platform/thread.hpp>

#include <sys/prctl.h>
#include <sys/resource.h>

#include <cassert>

namespace mbgl {
namespace platform {

std::string getCurrentThreadName() {
    char name[32] = "unknown";

    if (prctl(PR_GET_NAME, name) == -1) {
        Log::Warning(Event::General, "Couldn't get thread name");
    }

    return name;
}

void setCurrentThreadName(const std::string& name) {
    if (prctl(PR_SET_NAME, name.c_str()) == -1) {
        Log::Warning(Event::General, "Couldn't set thread name");
    }
}

void makeThreadLowPriority() {
    // 设置为最低优先级
    setpriority(PRIO_PROCESS, 0, 19);
}

void setCurrentThreadPriority(double priority) {
    if (priority < -20 || priority > 19) {
        Log::Warning(Event::General, "Couldn't set thread priority");
        return;
    }
    setpriority(PRIO_PROCESS, 0, int(priority));
}

// 在harmony平台上，我们简化attachThread和detachThread的实现
void attachThread() {
    // harmony平台上不需要特殊的线程附加逻辑
    // 这里提供一个空实现以满足链接需求
}

void detachThread() {
    // harmony平台上不需要特殊的线程分离逻辑
    // 这里提供一个空实现以满足链接需求
}

} // namespace platform
} // namespace mbgl