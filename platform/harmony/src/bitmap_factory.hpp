#pragma once

#include "bitmap.hpp"
#include <mbgl/util/image.hpp>

namespace mbgl {
namespace harmony {

// Provide a simplified bitmap factory for Harmony.
// This is a minimal framework; adjust the implementation for Harmony specifics if needed.

class BitmapFactory {
public:
    static std::unique_ptr<Bitmap> createBitmap(const mbgl::PremultipliedImage& image);
    static mbgl::PremultipliedImage convertToPremultipliedImage(const Bitmap& bitmap);
};

} // namespace harmony
} // namespace mbgl