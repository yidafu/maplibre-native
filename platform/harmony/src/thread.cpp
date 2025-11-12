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
    // Set to the lowest priority.
    setpriority(PRIO_PROCESS, 0, 19);
}

void setCurrentThreadPriority(double priority) {
    if (priority < -20 || priority > 19) {
        Log::Warning(Event::General, "Couldn't set thread priority");
        return;
    }
    setpriority(PRIO_PROCESS, 0, int(priority));
}

// On Harmony we use simplified attachThread/detachThread implementations.
void attachThread() {
    // Harmony does not require special thread attachment logic.
    // Provide an empty implementation to satisfy the linker.
}

void detachThread() {
    // Harmony does not require special thread detachment logic.
    // Provide an empty implementation to satisfy the linker.
}

} // namespace platform
} // namespace mbgl