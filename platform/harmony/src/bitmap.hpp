#pragma once

#include <mln/util/image.hpp>

namespace mln {
namespace harmony {

// Provide a simplified bitmap abstraction for Harmony.
// Extend this skeleton as needed to match Harmony platform requirements.

class Bitmap {
public:
    Bitmap(int width, int height, mln::PremultipliedImage&& image);
    ~Bitmap();

    int getWidth() const { return width; }
    int getHeight() const { return height; }
    const mln::PremultipliedImage& getImage() const { return image; }

private:
    int width = 0;
    int height = 0;
    mln::PremultipliedImage image;
};

} // namespace harmony
} // namespace mln