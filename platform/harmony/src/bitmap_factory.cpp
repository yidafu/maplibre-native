#include "bitmap_factory.hpp"
#include <memory>

namespace mbgl {
namespace harmony {

std::unique_ptr<Bitmap> BitmapFactory::createBitmap(const mbgl::PremultipliedImage& image) {
    // On Harmony we create Bitmap objects directly.
    return std::unique_ptr<Bitmap>(new Bitmap(image.size.width, image.size.height, image.clone()));
}

mbgl::PremultipliedImage BitmapFactory::convertToPremultipliedImage(const Bitmap& bitmap) {
    // On Harmony we return the image stored in the bitmap.
    return bitmap.getImage().clone();
}

} // namespace harmony
} // namespace mbgl