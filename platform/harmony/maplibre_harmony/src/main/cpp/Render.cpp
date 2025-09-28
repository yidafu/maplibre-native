//
// Created on 2025/9/28.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "Render.h"
#include "EGLCore.h"

Render::Render(int64_t& id)
{
    this->id_ = id;
    this->eglCore_ = new EGLCore();
    hasDraw_ = 0;
    hasChangeColor_ = 0;
}

void Render::ChangeColor()
{
    eglCore_->ChangeColor(hasChangeColor_);
}

void Render::DrawPattern()
{
    eglCore_->Draw(hasDraw_);
}

void Render::InitNativeWindow(OHNativeWindow *window)
{
    eglCore_->EglContextInit(window);
}

void Render::UpdateNativeWindowSize(int width, int height)
{
    eglCore_->UpdateSize(width, height);
    if (!hasChangeColor_ && !hasDraw_) {
        eglCore_->Background();
    }
}

int32_t Render::HasDraw()
{
    return hasDraw_;
}

int32_t Render::HasChangedColor()
{
    return hasChangeColor_;
}
