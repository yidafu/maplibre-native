#include "bitmap.hpp"

namespace mbgl {
namespace harmony {

Bitmap::Bitmap(int width_, int height_, mbgl::PremultipliedImage&& image_) 
    : width(width_), height(height_), image(std::move(image_)) {
}

Bitmap::~Bitmap() {
}

} // namespace harmony
} // namespace mbgl