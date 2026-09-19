#include "style_napi.hpp"
#include <chrono>
#include <future>
#include <functional>
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "napi/bindings/image/image_napi.hpp"
#include "utils/logger.h"
#include <mln/style/style.hpp>
#include <mln/style/image.hpp>
#include <mln/style/light.hpp>
#include <mln/style/transition_options.hpp>
#include <mln/util/image.hpp>
#include <mln/util/color.hpp>
#include <vector>
#include "style/light_harmony.hpp"
#include "style/transition_options_harmony.hpp"
#include <functional>
#include <array>

using namespace mln::harmony::napi;
using mln::harmony::Logger;

namespace mln {
namespace harmony {

// ==================== Shared image-argument helpers ====================

// Extract raw bytes from a TypedArray or ArrayBuffer JS value (typed array is
// tried first, then plain array buffer). Throws and returns false when the
// value is neither.
bool ExtractBufferData(napi_env env, napi_value dataValue, void** data, size_t* byteLength) {
    napi_valuetype valueType;
    napi_typeof(env, dataValue, &valueType);

    if (valueType == napi_object) {
        napi_value arrayBuffer;
        size_t byteOffset;
        napi_status status = napi_get_typedarray_info(env, dataValue, nullptr, byteLength, data, &arrayBuffer, &byteOffset);
        if (status != napi_ok) {
            status = napi_get_arraybuffer_info(env, dataValue, data, byteLength);
            if (status != napi_ok) {
                napi_throw_error(env, nullptr, "Second argument must be ArrayBuffer or TypedArray");
                return false;
            }
        }
    } else {
        napi_throw_error(env, nullptr, "Second argument must be ArrayBuffer or TypedArray");
        return false;
    }
    return true;
}

// Trailing addImage/addImageAsync arguments: numbers fill pixelRatio
// (default 1.0), booleans set `sdf`, everything else is ignored.
struct ImageTailOptions {
    double pixelRatio = 1.0;
    bool sdf = false;
};

// Leniently parses the trailing (fromIndex..argc) arguments of the addImage /
// addImageAsync forms into pixelRatio/sdf.
ImageTailOptions ParseImageTailArgs(napi_env env, NapiArgs& napiArgs, size_t fromIndex, size_t argc) {
    ImageTailOptions tail;
    for (size_t i = fromIndex; i < argc; ++i) {
        napi_valuetype argType;
        if (napi_typeof(env, napiArgs.GetValue(i), &argType) != napi_ok) {
            continue;
        }
        if (argType == napi_number) {
            tail.pixelRatio = napiArgs.GetDouble(i, "pixelRatio");
        } else if (argType == napi_boolean) {
            tail.sdf = napiArgs.GetBool(i, "sdf");
        }
    }
    return tail;
}

// ==================== Image management ====================

napi_value StyleNAPI::AddImage(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    size_t argc = napiArgs.Count();
    napi_value jsThis = napiArgs.This();

    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->acquireMap()) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    napi_value firstArg = napiArgs.GetValue(0);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    // Check if first argument is an Image object
    if (ImageNAPI::IsImageObject(env, firstArg)) {
        ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, firstArg);
        if (!imageNapi) {
            napi_throw_error(env, nullptr, "Failed to unwrap Image object");
            return nullptr;
        }

        try {
            auto styleImage = imageNapi->toStyleImage();
            std::string imageName = styleImage->getID();

            style->runOnMap([&](mln::Map& m) {
                m.getStyle().addImage(std::move(styleImage));
            });
            style->images[imageName] = true;

            Logger::info("StyleNAPI", "AddImage from Image object: %s (%dx%d)",
                         imageName.c_str(), imageNapi->getWidth(), imageNapi->getHeight());
        } catch (const std::exception& e) {
            Logger::error("StyleNAPI", "AddImage from Image object failed: %s", e.what());
            napi_throw_error(env, nullptr, e.what());
            return nullptr;
        }

        return napiArgs.Undefined();
    }

    if (argc < 5) {
        napi_throw_error(env, nullptr, "AddImage requires at least 5 arguments: name, buffer, width, height, pixelRatio");
        return nullptr;
    }

    std::string imageName = GetStringFromValue(env, firstArg);

    napi_value dataValue = napiArgs.GetValue(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    void* data = nullptr;
    size_t byteLength = 0;
    if (!ExtractBufferData(env, dataValue, &data, &byteLength)) {
        return nullptr;
    }

    uint32_t width = napiArgs.GetUint32(2, "width");
    uint32_t height = napiArgs.GetUint32(3, "height");
    if (napiArgs.HasError()) {
        return nullptr;
    }

    if (width == 0 || height == 0) {
        napi_throw_error(env, nullptr, "Width and height must be greater than 0");
        return nullptr;
    }

    // Trailing arguments accept either form:
    // - addImage(name, buffer, width, height, sdf?)
    // - addImage(name, buffer, width, height, pixelRatio?, sdf?)
    // Numbers fill pixelRatio (default 1.0), booleans set `sdf`.
    const ImageTailOptions tail = ParseImageTailArgs(env, napiArgs, 4, argc);
    if (napiArgs.HasError()) {
        return nullptr;
    }
    double pixelRatio = tail.pixelRatio;
    bool sdf = tail.sdf;

    if (byteLength != width * height * 4) {
        Logger::error("StyleNAPI", "AddImage: data size mismatch (expected: %d, got: %zu)", width * height * 4, byteLength);
        napi_throw_error(env, nullptr, "Image data size does not match width * height * 4");
        return nullptr;
    }

    try {
        mln::PremultipliedImage premultipliedImage({width, height});
        std::memcpy(premultipliedImage.data.get(), data, byteLength);

        auto image = std::make_unique<mln::style::Image>(
            imageName,
            std::move(premultipliedImage),
            static_cast<float>(pixelRatio),
            sdf
        );

        style->runOnMap([&](mln::Map& m) {
            m.getStyle().addImage(std::move(image));
        });
        style->images[imageName] = true;

        Logger::info("StyleNAPI", "AddImage: %s (%dx%d, ratio: %.2f, sdf: %s)",
                     imageName.c_str(), width, height, pixelRatio, sdf ? "true" : "false");
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "AddImage failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }

    return napiArgs.Undefined();
}

napi_value StyleNAPI::RemoveImage(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return CreateBoolValue(env, false);
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->acquireMap()) {
        return CreateBoolValue(env, false);
    }

    std::string imageName = GetStringFromValue(env, napiArgs.GetValue(0));
    if (napiArgs.HasError()) {
        return CreateBoolValue(env, false);
    }

    try {
        style->runOnMap([&](mln::Map& m) {
            m.getStyle().removeImage(imageName);
        });
        style->images.erase(imageName);
        Logger::info("StyleNAPI", "RemoveImage: %s", imageName.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "RemoveImage failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleNAPI::GetImage(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return napiArgs.Null();
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->acquireMap()) {
        return napiArgs.Null();
    }

    std::string imageName = GetStringFromValue(env, napiArgs.GetValue(0));
    if (napiArgs.HasError()) {
        return napiArgs.Null();
    }

    try {
        // Fetch a value copy on the render thread; the copy keeps the image
        // data alive no matter what the style does afterwards.
        std::optional<mln::style::Image> imageOpt;
        style->runOnMap([&](mln::Map& m) {
            imageOpt = m.getStyle().getImage(imageName);
        });
        if (!imageOpt) {
            return napiArgs.Null();
        }

        const mln::style::Image& image = *imageOpt;
        const mln::PremultipliedImage& premultipliedImage = image.getImage();
        uint32_t width = premultipliedImage.size.width;
        uint32_t height = premultipliedImage.size.height;
        size_t dataSize = width * height * 4;

        void* data = nullptr;
        napi_value arrayBuffer;
        napi_create_arraybuffer(env, dataSize, &data, &arrayBuffer);
        std::memcpy(data, premultipliedImage.data.get(), dataSize);

        napi_value result;
        napi_create_object(env, &result);

        napi_value nameValue;
        napi_create_string_utf8(env, imageName.c_str(), NAPI_AUTO_LENGTH, &nameValue);
        napi_set_named_property(env, result, "name", nameValue);

        napi_value widthValue;
        napi_create_uint32(env, width, &widthValue);
        napi_set_named_property(env, result, "width", widthValue);

        napi_value heightValue;
        napi_create_uint32(env, height, &heightValue);
        napi_set_named_property(env, result, "height", heightValue);

        napi_value pixelRatioValue;
        napi_create_double(env, image.getPixelRatio(), &pixelRatioValue);
        napi_set_named_property(env, result, "pixelRatio", pixelRatioValue);

        napi_value sdfValue;
        napi_get_boolean(env, image.isSdf(), &sdfValue);
        napi_set_named_property(env, result, "sdf", sdfValue);

        napi_set_named_property(env, result, "data", arrayBuffer);

        Logger::info("StyleNAPI", "GetImage: %s (%dx%d)", imageName.c_str(), width, height);
        return result;
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetImage failed: %s", e.what());
        return napiArgs.Null();
    }
}

// ==================== Async Image Loading ====================

// JS-side bookkeeping shared by the async image payloads.
struct AsyncImageWorkBase {
    napi_env env = nullptr;
    napi_ref thisRef = nullptr;
    napi_deferred deferred = nullptr;
    std::string errorMessage;
    bool success = false;
};

// Deletes the async payload and its JS reference on any error path; nulls the
// pointer so a following catch handler cannot double-free after ownership
// moved to the async work.
template <typename PayloadT>
void FailCleanupImageWork(napi_env env, PayloadT*& data) {
    if (data) {
        if (data->thisRef) {
            napi_delete_reference(env, data->thisRef);
            data->thisRef = nullptr;
        }
        delete data;
        data = nullptr;
    }
}

// Creates and queues the async work for `data`. On failure the payload is
// cleaned up, the matching error is thrown, and false is returned.
template <typename PayloadT>
bool QueueImageAsyncWork(napi_env env, PayloadT*& data, const char* resourceName,
                         napi_async_execute_callback execute, napi_async_complete_callback complete) {
    napi_value resourceNameValue;
    napi_create_string_utf8(env, resourceName, NAPI_AUTO_LENGTH, &resourceNameValue);

    napi_async_work work;
    napi_status status = napi_create_async_work(env, nullptr, resourceNameValue, execute, complete, data, &work);
    if (status != napi_ok) {
        FailCleanupImageWork(env, data);
        napi_throw_error(env, nullptr, "Failed to create async work");
        return false;
    }

    status = napi_queue_async_work(env, work);
    if (status != napi_ok) {
        napi_delete_async_work(env, work);
        FailCleanupImageWork(env, data);
        napi_throw_error(env, nullptr, "Failed to queue async work");
        return false;
    }
    return true;
}

void ResolveAsyncUndefined(napi_env env, napi_deferred deferred) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    napi_resolve_deferred(env, deferred, undefined);
}

void RejectAsyncWithError(napi_env env, napi_deferred deferred, const char* message) {
    napi_value errorMsg;
    napi_create_string_utf8(env, message, NAPI_AUTO_LENGTH, &errorMsg);
    napi_reject_deferred(env, deferred, errorMsg);
}

// Shared completion scaffold for the async image flows: unwrap the style from
// the payload's `this` reference, run `commit` when the work succeeded and the
// style/map is still alive (then resolve the deferred), otherwise reject with
// the payload error message. Always releases the payload.
template <typename PayloadT, typename IsAlive, typename Commit>
void CompleteImageAsyncWork(napi_env env, napi_status status, void* data, IsAlive isAlive,
                            const char* logTag, const char* fallbackError, Commit commit) {
    PayloadT* asyncData = static_cast<PayloadT*>(data);

    napi_value jsThis;
    napi_get_reference_value(env, asyncData->thisRef, &jsThis);
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (status == napi_ok && asyncData->success && style && isAlive(style)) {
        try {
            commit(style, *asyncData);
            ResolveAsyncUndefined(env, asyncData->deferred);
        } catch (const std::exception& e) {
            Logger::error("StyleNAPI", "%s failed: %s", logTag, e.what());
            RejectAsyncWithError(env, asyncData->deferred, e.what());
        }
    } else {
        RejectAsyncWithError(env, asyncData->deferred,
                             asyncData->errorMessage.empty() ? fallbackError : asyncData->errorMessage.c_str());
    }

    // Cleanup
    napi_delete_reference(env, asyncData->thisRef);
    delete asyncData;
}

// Struct to hold async work data
struct AsyncImageData : AsyncImageWorkBase {
    // Image data
    std::string imageName;
    uint32_t width;
    uint32_t height;
    float pixelRatio;
    bool sdf;
    std::shared_ptr<std::vector<uint8_t>> imageData;
    std::optional<std::vector<mln::style::ImageStretches::value_type>> stretchX;
    std::optional<std::vector<mln::style::ImageStretches::value_type>> stretchY;
    std::optional<mln::style::ImageContent> content;
};

// Async execute callback - runs in worker thread
void AddImageAsyncExecute(napi_env env, void* data) {
    AsyncImageData* asyncData = static_cast<AsyncImageData*>(data);
    
    // Image data is already prepared, just mark as success
    // Actual processing happens in the complete callback
    asyncData->success = true;
}

// Async complete callback - runs in main thread
void AddImageAsyncComplete(napi_env env, napi_status status, void* data) {
    CompleteImageAsyncWork<AsyncImageData>(
        env, status, data,
        [](StyleNAPI* style) { return style->getMap() != nullptr; },
        "AddImageAsync", "Failed to add image asynchronously",
        [](StyleNAPI* style, AsyncImageData& asyncData) {
            // Create PremultipliedImage
            mln::PremultipliedImage premultipliedImage({asyncData.width, asyncData.height});
            std::memcpy(premultipliedImage.data.get(), asyncData.imageData->data(), asyncData.imageData->size());

            // Convert stretchX and stretchY
            mln::style::ImageStretches imageStretchesX;
            if (asyncData.stretchX) {
                imageStretchesX = asyncData.stretchX.value();
            }

            mln::style::ImageStretches imageStretchesY;
            if (asyncData.stretchY) {
                imageStretchesY = asyncData.stretchY.value();
            }

            // Create style::Image
            std::unique_ptr<mln::style::Image> image;
            if (asyncData.content) {
                image = std::make_unique<mln::style::Image>(
                    asyncData.imageName,
                    std::move(premultipliedImage),
                    asyncData.pixelRatio,
                    asyncData.sdf,
                    imageStretchesX,
                    imageStretchesY,
                    asyncData.content.value()
                );
            } else {
                image = std::make_unique<mln::style::Image>(
                    asyncData.imageName,
                    std::move(premultipliedImage),
                    asyncData.pixelRatio,
                    asyncData.sdf,
                    imageStretchesX,
                    imageStretchesY
                );
            }

            // Add to style (serialized with the render thread)
            style->runOnMap([&](mln::Map& m) {
                m.getStyle().addImage(std::move(image));
            });
            style->images[asyncData.imageName] = true;

            Logger::info("StyleNAPI", "AddImageAsync completed: %s (%dx%d)",
                        asyncData.imageName.c_str(), asyncData.width, asyncData.height);
        });
}

napi_value StyleNAPI::AddImageAsync(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    size_t argc = napiArgs.Count();
    std::vector<napi_value> argsVec(argc);
    for (size_t i = 0; i < argc; ++i) {
        argsVec[i] = napiArgs.GetValue(i);
        if (napiArgs.HasError()) {
            return nullptr;
        }
    }
    napi_value* args = argsVec.data();

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->getMap()) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    // Create promise
    napi_value promise;
    napi_deferred deferred;
    napi_create_promise(env, &deferred, &promise);

    AsyncImageData* asyncData = nullptr;

    try {
        // Prepare async data
        asyncData = new AsyncImageData();
        asyncData->env = env;
        asyncData->deferred = deferred;
        asyncData->success = false;

        // Create reference to this
        if (napi_create_reference(env, jsThis, 1, &asyncData->thisRef) != napi_ok) {
            asyncData->thisRef = nullptr;
            FailCleanupImageWork(env, asyncData);
            napi_throw_error(env, nullptr, "Failed to create style reference");
            return nullptr;
        }

        // Check if first argument is an Image object
        if (ImageNAPI::IsImageObject(env, args[0])) {
            // New way: Accept Image NAPI object
            ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, args[0]);
            if (!imageNapi) {
                FailCleanupImageWork(env, asyncData);
                napi_throw_error(env, nullptr, "Failed to unwrap Image object");
                return nullptr;
            }

            asyncData->imageName = imageNapi->getName();
            asyncData->width = imageNapi->getWidth();
            asyncData->height = imageNapi->getHeight();
            asyncData->pixelRatio = imageNapi->getPixelRatio();
            asyncData->sdf = imageNapi->isSdf();
            // Get image data from ImageNAPI (need to expose this)
            auto styleImage = imageNapi->toStyleImage();

            // Copy data
            const auto& srcImage = styleImage->getImage();
            asyncData->imageData = std::make_shared<std::vector<uint8_t>>(
                srcImage.data.get(),
                srcImage.data.get() + srcImage.bytes()
            );

        } else {
            // Old way: Accept raw parameters
            if (argc < 5) {
                FailCleanupImageWork(env, asyncData);
                napi_throw_error(env, nullptr, "AddImageAsync requires at least 5 arguments");
                return nullptr;
            }

            // Parse arguments (same as AddImage)
            asyncData->imageName = GetStringFromValue(env, args[0]);

            // Get image data
            void* data = nullptr;
            size_t byteLength = 0;
            if (!ExtractBufferData(env, args[1], &data, &byteLength)) {
                FailCleanupImageWork(env, asyncData);
                return nullptr;
            }

            napi_get_value_uint32(env, args[2], &asyncData->width);
            napi_get_value_uint32(env, args[3], &asyncData->height);

            // Trailing arguments accept either form:
            // - addImageAsync(name, buffer, width, height, sdf?)
            // - addImageAsync(name, buffer, width, height, pixelRatio?, sdf?)
            ImageTailOptions tail = ParseImageTailArgs(env, napiArgs, 4, argc);
            asyncData->pixelRatio = static_cast<float>(tail.pixelRatio);
            asyncData->sdf = tail.sdf;

            // Verify data size (64-bit multiply: width/height are uint32_t)
            const uint64_t expectedBytes =
                static_cast<uint64_t>(asyncData->width) * static_cast<uint64_t>(asyncData->height) * 4ull;
            if (expectedBytes == 0 || expectedBytes > (512ull << 20) ||
                byteLength != expectedBytes) {
                FailCleanupImageWork(env, asyncData);
                napi_throw_error(env, nullptr, "Image data size does not match width * height * 4");
                return nullptr;
            }

            // Copy data
            asyncData->imageData = std::make_shared<std::vector<uint8_t>>(
                static_cast<uint8_t*>(data),
                static_cast<uint8_t*>(data) + byteLength
            );
        }

        if (!QueueImageAsyncWork(env, asyncData, "AddImageAsync", AddImageAsyncExecute, AddImageAsyncComplete)) {
            return nullptr;
        }

        // Ownership moved to the async work
        asyncData = nullptr;
        return promise;

    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "AddImageAsync setup failed: %s", e.what());
        FailCleanupImageWork(env, asyncData);
        napi_value errorMsg;
        napi_create_string_utf8(env, e.what(), NAPI_AUTO_LENGTH, &errorMsg);
        napi_reject_deferred(env, deferred, errorMsg);
        return promise;
    }
}

// Struct for batch async images
struct AsyncImagesData : AsyncImageWorkBase {
    // Multiple images
    std::vector<std::unique_ptr<mln::style::Image>> images;
    std::vector<std::string> imageNames;
};

void AddImagesAsyncExecute(napi_env env, void* data) {
    AsyncImagesData* asyncData = static_cast<AsyncImagesData*>(data);
    asyncData->success = true;
}

void AddImagesAsyncComplete(napi_env env, napi_status status, void* data) {
    CompleteImageAsyncWork<AsyncImagesData>(
        env, status, data,
        [](StyleNAPI* style) { return style->acquireMap() != nullptr; },
        "AddImagesAsync", "Failed to add images asynchronously",
        [](StyleNAPI* style, AsyncImagesData& asyncData) {
            // Add all images to style in a single render-thread dispatch
            style->runOnMap([&](mln::Map& m) {
                for (size_t i = 0; i < asyncData.images.size(); ++i) {
                    m.getStyle().addImage(std::move(asyncData.images[i]));
                }
            });
            for (size_t i = 0; i < asyncData.imageNames.size(); ++i) {
                style->images[asyncData.imageNames[i]] = true;
            }

            Logger::info("StyleNAPI", "AddImagesAsync completed: %zu images", asyncData.images.size());
        });
}

napi_value StyleNAPI::AddImagesAsync(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->getMap()) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    napi_value imagesArray = napiArgs.GetArray(0, "images");
    if (napiArgs.HasError()) {
        return nullptr;
    }

    // Create promise
    napi_value promise;
    napi_deferred deferred;
    napi_create_promise(env, &deferred, &promise);

    AsyncImagesData* asyncData = nullptr;

    try {
        uint32_t arrayLength = 0;
        napi_get_array_length(env, imagesArray, &arrayLength);

        if (arrayLength == 0) {
            // Empty array, resolve immediately
            ResolveAsyncUndefined(env, deferred);
            return promise;
        }

        // Prepare async data
        asyncData = new AsyncImagesData();
        asyncData->env = env;
        asyncData->deferred = deferred;
        asyncData->success = false;

        if (napi_create_reference(env, jsThis, 1, &asyncData->thisRef) != napi_ok) {
            asyncData->thisRef = nullptr;
            FailCleanupImageWork(env, asyncData);
            napi_throw_error(env, nullptr, "Failed to create style reference");
            return nullptr;
        }

        // Parse all images
        for (uint32_t i = 0; i < arrayLength; ++i) {
            napi_value imageValue;
            napi_get_element(env, imagesArray, i, &imageValue);

            if (!ImageNAPI::IsImageObject(env, imageValue)) {
                FailCleanupImageWork(env, asyncData);
                napi_throw_error(env, nullptr, "All array elements must be Image objects");
                return nullptr;
            }

            ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, imageValue);
            if (!imageNapi) {
                FailCleanupImageWork(env, asyncData);
                napi_throw_error(env, nullptr, "Failed to unwrap Image object");
                return nullptr;
            }

            // Convert to style::Image
            auto styleImage = imageNapi->toStyleImage();
            std::string imageName = styleImage->getID();

            asyncData->images.push_back(std::move(styleImage));
            asyncData->imageNames.push_back(imageName);
        }

        if (!QueueImageAsyncWork(env, asyncData, "AddImagesAsync", AddImagesAsyncExecute, AddImagesAsyncComplete)) {
            return nullptr;
        }

        // Ownership moved to the async work
        asyncData = nullptr;
        return promise;

    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "AddImagesAsync setup failed: %s", e.what());
        FailCleanupImageWork(env, asyncData);
        napi_value errorMsg;
        napi_create_string_utf8(env, e.what(), NAPI_AUTO_LENGTH, &errorMsg);
        napi_reject_deferred(env, deferred, errorMsg);
        return promise;
    }
}

// ==================== Light & Transition ====================

napi_value StyleNAPI::GetLight(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->acquireMap()) {
        return napiArgs.Null();
    }
    
    try {
        mln::style::Light* light = nullptr;
        style->runOnMap([&](mln::Map& m) {
            light = m.getStyle().getLight();
        });
        if (!light) {
            Logger::warn("StyleNAPI", "GetLight: Style has no light definition");
            return napiArgs.Null();
        }

        mln::Map* map = style->acquireMap();
        if (!map) {
            return napiArgs.Null();
        }
        return mln::harmony::LightHarmony::CreateLightPeer(env, *map);
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetLight failed: %s", e.what());
        return napiArgs.Null();
    }
}

napi_value StyleNAPI::GetTransition(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->acquireMap()) {
        return napiArgs.Null();
    }

    mln::style::TransitionOptions options;
    try {
        style->runOnMap([&](mln::Map& m) {
            options = m.getStyle().getTransitionOptions();
        });
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetTransition failed: %s", e.what());
        return napiArgs.Null();
    }

    // 300ms keeps the historical default shown when no duration was set.
    return TransitionOptionsHarmony::CreateTransitionOptionsObject(env, options, 300.0);
}

napi_value StyleNAPI::SetTransition(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->acquireMap()) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    napi_value transitionOptions = napiArgs.GetObject(0, "transition");
    if (napiArgs.HasError()) {
        return nullptr;
    }

    mln::style::TransitionOptions options;
    TransitionOptionsHarmony::ParseTransitionOptions(env, transitionOptions, options);

    try {
        style->runOnMap([&](mln::Map& m) {
            m.getStyle().setTransitionOptions(options);
        });
        Logger::info("StyleNAPI", "SetTransition applied");
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "SetTransition failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }

    return napiArgs.Undefined();
}

} // namespace harmony
} // namespace mln

