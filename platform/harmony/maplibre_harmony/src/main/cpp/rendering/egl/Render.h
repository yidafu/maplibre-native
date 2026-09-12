//
// Created on 2025/9/28.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MAPLIBREHARMONY_RENDER_H
#define MAPLIBREHARMONY_RENDER_H

#include "EGLCore.h"
#include <ace/xcomponent/native_interface_xcomponent.h>
#include <native_window/external_window.h>

class Render {
public:
    explicit Render(int64_t& id);
    ~Render()
    {
        if (eglCore_ != nullptr) {
            eglCore_->Release();
            delete eglCore_;
            eglCore_ = nullptr;
        }
    }
    void ChangeColor();
    void DrawPattern();
    int32_t HasDraw();
    int32_t HasChangedColor();
    void InitNativeWindow(OHNativeWindow* window);
    void UpdateNativeWindowSize(int width, int height);
private:
    EGLCore* eglCore_;
    int64_t id_;
    int32_t hasDraw_;
    int32_t hasChangeColor_;
};

#endif //MAPLIBREHARMONY_RENDER_H
