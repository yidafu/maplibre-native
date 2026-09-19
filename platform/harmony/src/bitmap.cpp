#include "bitmap.hpp"

namespace mln {
namespace harmony {

Bitmap::Bitmap(int width_, int height_, mln::PremultipliedImage&& image_) 
    : width(width_), height(height_), image(std::move(image_)) {
}

Bitmap::~Bitmap() {
}

} // namespace harmony
} // namespace mln