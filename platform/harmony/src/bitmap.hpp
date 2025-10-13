#pragma once

#include <mbgl/util/image.hpp>

namespace mbgl {
namespace harmony {

// 在harmony平台上，我们简化位图处理
// 这里提供一个基本的框架，实际实现可能需要根据harmony平台特性调整

class Bitmap {
public:
    Bitmap(int width, int height, mbgl::PremultipliedImage&& image);
    ~Bitmap();

    int getWidth() const { return width; }
    int getHeight() const { return height; }
    const mbgl::PremultipliedImage& getImage() const { return image; }

private:
    int width = 0;
    int height = 0;
    mbgl::PremultipliedImage image;
};

} // namespace harmony
} // namespace mbgl