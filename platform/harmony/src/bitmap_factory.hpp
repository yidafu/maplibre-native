#pragma once

#include "bitmap.hpp"
#include <mln/util/image.hpp>

namespace mln {
namespace harmony {

// Provide a simplified bitmap factory for Harmony.
// This is a minimal framework; adjust the implementation for Harmony specifics if needed.

class BitmapFactory {
public:
    static std::unique_ptr<Bitmap> createBitmap(const mln::PremultipliedImage& image);
    static mln::PremultipliedImage convertToPremultipliedImage(const Bitmap& bitmap);
};

} // namespace harmony
} // namespace mln