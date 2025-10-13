#pragma once

#include "bitmap.hpp"
#include <mbgl/util/image.hpp>

namespace mbgl {
namespace harmony {

// 在harmony平台上，我们简化位图工厂处理
// 这里提供一个基本的框架，实际实现可能需要根据harmony平台特性调整

class BitmapFactory {
public:
    static std::unique_ptr<Bitmap> createBitmap(const mbgl::PremultipliedImage& image);
    static mbgl::PremultipliedImage convertToPremultipliedImage(const Bitmap& bitmap);
};

} // namespace harmony
} // namespace mbgl