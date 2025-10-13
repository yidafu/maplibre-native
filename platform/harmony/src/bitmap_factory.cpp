#include "bitmap_factory.hpp"
#include <memory>

namespace mbgl {
namespace harmony {

std::unique_ptr<Bitmap> BitmapFactory::createBitmap(const mbgl::PremultipliedImage& image) {
    // 在harmony平台上，我们直接创建Bitmap对象
    return std::unique_ptr<Bitmap>(new Bitmap(image.size.width, image.size.height, image.clone()));
}

mbgl::PremultipliedImage BitmapFactory::convertToPremultipliedImage(const Bitmap& bitmap) {
    // 在harmony平台上，我们直接返回bitmap中的image
    return bitmap.getImage().clone();
}

} // namespace harmony
} // namespace mbgl