#pragma once

#include <mbgl/util/image.hpp>

namespace mbgl {
namespace harmony {

// Provide a simplified bitmap abstraction for Harmony.
// Extend this skeleton as needed to match Harmony platform requirements.

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