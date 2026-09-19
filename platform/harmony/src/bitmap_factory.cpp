#include "bitmap_factory.hpp"
#include <memory>

namespace mln {
namespace harmony {

std::unique_ptr<Bitmap> BitmapFactory::createBitmap(const mln::PremultipliedImage& image) {
    // On Harmony we create Bitmap objects directly.
    return std::unique_ptr<Bitmap>(new Bitmap(image.size.width, image.size.height, image.clone()));
}

mln::PremultipliedImage BitmapFactory::convertToPremultipliedImage(const Bitmap& bitmap) {
    // On Harmony we return the image stored in the bitmap.
    return bitmap.getImage().clone();
}

} // namespace harmony
} // namespace mln