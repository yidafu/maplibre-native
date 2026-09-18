#ifndef MAPLIBRE_HARMONY_IMAGE_PAYLOAD_NAPI_HPP
#define MAPLIBRE_HARMONY_IMAGE_PAYLOAD_NAPI_HPP

// Shared ingestion of an Image or Bitmap NAPI object: ImageSource::setImage
// and VideoSource::updateImage used to hand-duplicate the
// IsImageObject/IsBitmapObject -> Unwrap -> clone dispatch.

#include "napi/bindings/image/image_napi.hpp"
#include "bitmap/bitmap_napi.hpp"

#include <mbgl/util/image.hpp>

#include <optional>
#include <string>
#include <utility>

namespace mbgl {
namespace harmony {

/** Cloned pixels plus the kind of NAPI object that produced them
 *  (callers use this for their success logs). `imageObjectName` is the
 *  ImageNAPI name, empty for a Bitmap. */
struct DecodedImagePayload {
    mbgl::PremultipliedImage image;
    bool fromImageObject = false;
    std::string imageObjectName;
};

/**
 * Decode an Image or Bitmap NAPI object into cloned pixels. On failure a JS
 * exception is left pending and nullopt is returned; the caller only has to
 * bail out. `invalidMessage` preserves each caller's historical wording.
 */
inline std::optional<DecodedImagePayload> DecodeImageOrBitmap(napi_env env, napi_value value,
                                                              const char* invalidMessage) {
    if (ImageNAPI::IsImageObject(env, value)) {
        // Unwrap ImageNAPI and get the image data
        ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, value);
        if (!imageNapi) {
            napi_throw_error(env, nullptr, "Failed to unwrap Image object");
            return std::nullopt;
        }

        // Convert to style::Image and clone the PremultipliedImage
        auto styleImage = imageNapi->toStyleImage();

        DecodedImagePayload payload;
        payload.image = styleImage->getImage().clone();
        payload.fromImageObject = true;
        payload.imageObjectName = imageNapi->getName();
        return payload;
    }

    if (mbgl::harmony::BitmapNAPI::IsBitmapObject(env, value)) {
        // Get Bitmap data
        mbgl::harmony::BitmapNAPI* bitmapNapi = mbgl::harmony::BitmapNAPI::Unwrap(env, value);
        if (!bitmapNapi) {
            napi_throw_error(env, nullptr, "Failed to unwrap Bitmap object");
            return std::nullopt;
        }

        auto image = bitmapNapi->getImage();
        if (!image) {
            napi_throw_error(env, nullptr, "Bitmap has no image data");
            return std::nullopt;
        }

        DecodedImagePayload payload;
        payload.image = image->clone();
        return payload;
    }

    napi_throw_error(env, nullptr, invalidMessage);
    return std::nullopt;
}

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBRE_HARMONY_IMAGE_PAYLOAD_NAPI_HPP
