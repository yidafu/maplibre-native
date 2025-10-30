/**
 * MapSnapshotter NAPI Bindings for HarmonyOS
 */

#include "snapshotter_napi.hpp"
#include "map_snapshotter_harmony.hpp"
#include "../utils/logger.h"
#include "../camera/camera_position_harmony.hpp"
#include "../geometry/lat_lng_bounds_harmony.hpp"
#include "../core/thread_safe_callback.hpp"

#include <mbgl/map/camera.hpp>
#include <napi/native_api.h>
#include <string>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * MapSnapshotter 内部实例类
 */
class MapSnapshotterInstance {
public:
    std::unique_ptr<MapSnapshotterHarmony> snapshotter;
    napi_env env;
    napi_ref callbackRef = nullptr;
    napi_ref errorCallbackRef = nullptr;

    MapSnapshotterInstance(napi_env e) : env(e) {}

    ~MapSnapshotterInstance() {
        if (callbackRef) {
            napi_delete_reference(env, callbackRef);
        }
        if (errorCallbackRef) {
            napi_delete_reference(env, errorCallbackRef);
        }
    }
};

/**
 * 创建 MapSnapshotter 实例
 * 
 * JavaScript 调用：
 * const snapshotter = maplibre.createMapSnapshotter(options);
 */
napi_value CreateMapSnapshotter(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    
    napi_status status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: options");
        return nullptr;
    }

    // 解析选项对象
    napi_value optionsObj = args[0];
    
    MapSnapshotterHarmony::SnapshotOptions options;
    
    // 解析 width
    napi_value widthVal;
    napi_get_named_property(env, optionsObj, "width", &widthVal);
    int32_t width;
    napi_get_value_int32(env, widthVal, &width);
    options.width = static_cast<uint32_t>(width);
    
    // 解析 height
    napi_value heightVal;
    napi_get_named_property(env, optionsObj, "height", &heightVal);
    int32_t height;
    napi_get_value_int32(env, heightVal, &height);
    options.height = static_cast<uint32_t>(height);
    
    // 解析 pixelRatio
    napi_value pixelRatioVal;
    napi_get_named_property(env, optionsObj, "pixelRatio", &pixelRatioVal);
    double pixelRatio;
    napi_get_value_double(env, pixelRatioVal, &pixelRatio);
    options.pixelRatio = static_cast<float>(pixelRatio);
    
    // 解析 styleUrl
    napi_value styleUrlVal;
    napi_get_named_property(env, optionsObj, "styleUrl", &styleUrlVal);
    size_t str_size;
    napi_get_value_string_utf8(env, styleUrlVal, nullptr, 0, &str_size);
    std::string styleUrl(str_size, '\0');
    napi_get_value_string_utf8(env, styleUrlVal, &styleUrl[0], str_size + 1, &str_size);
    options.styleURL = styleUrl;
    
    // 解析 showLogo（可选，默认 true）
    napi_value showLogoVal;
    napi_get_named_property(env, optionsObj, "showLogo", &showLogoVal);
    bool showLogo = true;
    if (showLogoVal != nullptr) {
        napi_get_value_bool(env, showLogoVal, &showLogo);
    }
    options.showLogo = showLogo;
    
    // 解析可选参数
    
    // 解析 styleJSON（可选）
    napi_value styleJSONVal;
    status = napi_get_named_property(env, optionsObj, "styleJSON", &styleJSONVal);
    if (status == napi_ok) {
        napi_valuetype styleJSONType;
        napi_typeof(env, styleJSONVal, &styleJSONType);
        if (styleJSONType == napi_string) {
            size_t jsonSize;
            napi_get_value_string_utf8(env, styleJSONVal, nullptr, 0, &jsonSize);
            if (jsonSize > 0) {
                std::string styleJSON(jsonSize, '\0');
                napi_get_value_string_utf8(env, styleJSONVal, &styleJSON[0], jsonSize + 1, &jsonSize);
                options.styleJSON = styleJSON;
                Logger::info("SnapshotterNAPI", "Using styleJSON: %zu bytes", jsonSize);
            }
        }
    }
    
    // 解析 camera（可选）
    napi_value cameraVal;
    status = napi_get_named_property(env, optionsObj, "camera", &cameraVal);
    if (status == napi_ok) {
        napi_valuetype cameraType;
        napi_typeof(env, cameraVal, &cameraType);
        if (cameraType == napi_object) {
            // 解析 camera position
            mbgl::CameraOptions camera;
            
            // 解析 target (LatLng)
            napi_value targetVal;
            if (napi_get_named_property(env, cameraVal, "target", &targetVal) == napi_ok) {
                napi_value latVal, lngVal;
                napi_get_named_property(env, targetVal, "latitude", &latVal);
                napi_get_named_property(env, targetVal, "longitude", &lngVal);
                double lat, lng;
                napi_get_value_double(env, latVal, &lat);
                napi_get_value_double(env, lngVal, &lng);
                camera.center = mbgl::LatLng(lat, lng);
            }
            
            // 解析 zoom
            napi_value zoomVal;
            if (napi_get_named_property(env, cameraVal, "zoom", &zoomVal) == napi_ok) {
                double zoom;
                napi_get_value_double(env, zoomVal, &zoom);
                camera.zoom = zoom;
            }
            
            // 解析 bearing
            napi_value bearingVal;
            if (napi_get_named_property(env, cameraVal, "bearing", &bearingVal) == napi_ok) {
                double bearing;
                napi_get_value_double(env, bearingVal, &bearing);
                camera.bearing = bearing;
            }
            
            // 解析 tilt (pitch)
            napi_value tiltVal;
            if (napi_get_named_property(env, cameraVal, "tilt", &tiltVal) == napi_ok) {
                double tilt;
                napi_get_value_double(env, tiltVal, &tilt);
                camera.pitch = tilt;
            }
            
            options.camera = camera;
        }
    }
    
    // 解析 region（LatLngBounds，可选）
    napi_value regionVal;
    status = napi_get_named_property(env, optionsObj, "region", &regionVal);
    if (status == napi_ok) {
        napi_valuetype regionType;
        napi_typeof(env, regionVal, &regionType);
        if (regionType == napi_object) {
            napi_value northVal, southVal, eastVal, westVal;
            napi_get_named_property(env, regionVal, "north", &northVal);
            napi_get_named_property(env, regionVal, "south", &southVal);
            napi_get_named_property(env, regionVal, "east", &eastVal);
            napi_get_named_property(env, regionVal, "west", &westVal);
            
            double north, south, east, west;
            napi_get_value_double(env, northVal, &north);
            napi_get_value_double(env, southVal, &south);
            napi_get_value_double(env, eastVal, &east);
            napi_get_value_double(env, westVal, &west);
            
            mbgl::LatLngBounds bounds = mbgl::LatLngBounds::hull(
                mbgl::LatLng(north, east),
                mbgl::LatLng(south, west)
            );
            options.region = bounds;
        }
    }
    
    // 创建资源选项
    // 注意：这里简化处理，实际应该从context获取正确的缓存路径
    mbgl::ResourceOptions resourceOptions;
    resourceOptions.withCachePath("/data/storage/el2/base/haps/entry/cache/maplibre");
    
    mbgl::ClientOptions clientOptions;
    
    // 创建 MapSnapshotterInstance 实例
    auto* snapshotterInstance = new MapSnapshotterInstance(env);
    snapshotterInstance->snapshotter = std::make_unique<MapSnapshotterHarmony>(
        options,
        resourceOptions,
        clientOptions
    );
    
    // 创建 JavaScript 对象并关联 native 指针
    napi_value jsSnapshotter;
    napi_create_object(env, &jsSnapshotter);
    
    // 将 native 指针包装到 JavaScript 对象
    napi_wrap(env, jsSnapshotter, snapshotterInstance,
              [](napi_env env, void* data, void* hint) {
                  delete static_cast<MapSnapshotterInstance*>(data);
              },
              nullptr, nullptr);
    
    Logger::info("SnapshotterNAPI", "MapSnapshotter created: %dx%d @ %.2fx",
                 options.width, options.height, options.pixelRatio);
    
    return jsSnapshotter;
}

/**
 * 开始生成快照
 * 
 * JavaScript 调用：
 * snapshotter.start((error, imageData) => { ... });
 */
napi_value SnapshotterStart(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    
    napi_status status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: callback");
        return nullptr;
    }

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // 保存回调函数引用
    napi_value callback = args[0];
    napi_create_reference(env, callback, 1, &snapshotterInstance->callbackRef);

    Logger::info("SnapshotterNAPI", "Starting snapshot");

    // 调用 C++ snapshot 方法
    snapshotterInstance->snapshotter->snapshot(
        [env, callbackRef = snapshotterInstance->callbackRef](
            std::exception_ptr err,
            mbgl::PremultipliedImage image,
            std::vector<std::string> attributions
        ) {
            // 在主线程上调用回调
            Logger::info("SnapshotterNAPI", "Snapshot callback triggered");
            
            napi_value callback;
            napi_get_reference_value(env, callbackRef, &callback);
            
            napi_value global;
            napi_get_global(env, &global);
            
            if (err) {
                // 发生错误
                try {
                    std::rethrow_exception(err);
                } catch (const std::exception& e) {
                    Logger::error("SnapshotterNAPI", "Snapshot error: %s", e.what());
                    
                    // 调用 callback(error, null)
                    napi_value argv[2];
                    napi_create_string_utf8(env, e.what(), NAPI_AUTO_LENGTH, &argv[0]);
                    napi_get_null(env, &argv[1]);
                    
                    napi_value result;
                    napi_call_function(env, global, callback, 2, argv, &result);
                }
            } else {
                // 成功
                Logger::info("SnapshotterNAPI", "Snapshot success: %dx%d, %d bytes",
                             image.size.width, image.size.height, image.bytes());
                
                // 创建 ArrayBuffer 包含图像数据
                void* data;
                napi_value arrayBuffer;
                size_t byteLength = image.bytes();
                napi_create_arraybuffer(env, byteLength, &data, &arrayBuffer);
                
                // 复制图像数据
                std::memcpy(data, image.data.get(), byteLength);
                
                // 创建结果对象
                napi_value resultObj;
                napi_create_object(env, &resultObj);
                
                // 设置属性
                napi_value widthVal, heightVal;
                napi_create_uint32(env, image.size.width, &widthVal);
                napi_create_uint32(env, image.size.height, &heightVal);
                
                napi_set_named_property(env, resultObj, "data", arrayBuffer);
                napi_set_named_property(env, resultObj, "width", widthVal);
                napi_set_named_property(env, resultObj, "height", heightVal);
                
                // 添加 attributions
                if (!attributions.empty()) {
                    napi_value attributionsArray;
                    napi_create_array_with_length(env, attributions.size(), &attributionsArray);
                    
                    for (size_t i = 0; i < attributions.size(); i++) {
                        napi_value attrValue;
                        napi_create_string_utf8(env, attributions[i].c_str(), NAPI_AUTO_LENGTH, &attrValue);
                        napi_set_element(env, attributionsArray, i, attrValue);
                    }
                    
                    napi_set_named_property(env, resultObj, "attributions", attributionsArray);
                }
                
                // 调用 callback(null, result)
                napi_value argv[2];
                napi_get_null(env, &argv[0]);
                argv[1] = resultObj;
                
                napi_value result;
                napi_call_function(env, global, callback, 2, argv, &result);
            }
            
            // 清理回调引用
            napi_delete_reference(env, callbackRef);
        }
    );

    return nullptr;
}

/**
 * 取消快照生成
 * 
 * JavaScript 调用：
 * snapshotter.cancel();
 */
napi_value SnapshotterCancel(napi_env env, napi_callback_info info) {
    napi_value thisArg;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisArg, nullptr);

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    Logger::info("SnapshotterNAPI", "Cancelling snapshot");
    snapshotterInstance->snapshotter->cancel();

    return nullptr;
}

/**
 * 设置样式 URL
 */
napi_value SnapshotterSetStyleUrl(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: styleUrl");
        return nullptr;
    }

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // 解析 styleUrl
    size_t str_size;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &str_size);
    std::string styleUrl(str_size, '\0');
    napi_get_value_string_utf8(env, args[0], &styleUrl[0], str_size + 1, &str_size);
    
    snapshotterInstance->snapshotter->setStyleURL(styleUrl);

    return nullptr;
}

/**
 * 设置相机位置
 */
napi_value SnapshotterSetCameraPosition(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisArg;
    
    napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Expected 1 argument: cameraPosition");
        return nullptr;
    }

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, thisArg, reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // 解析 CameraPosition
    napi_value cameraObj = args[0];
    mbgl::CameraOptions camera;
    
    // 解析 target (LatLng)
    napi_value targetVal;
    if (napi_get_named_property(env, cameraObj, "target", &targetVal) == napi_ok) {
        napi_value latVal, lngVal;
        napi_get_named_property(env, targetVal, "latitude", &latVal);
        napi_get_named_property(env, targetVal, "longitude", &lngVal);
        double lat, lng;
        napi_get_value_double(env, latVal, &lat);
        napi_get_value_double(env, lngVal, &lng);
        camera.center = mbgl::LatLng(lat, lng);
    }
    
    // 解析 zoom
    napi_value zoomVal;
    if (napi_get_named_property(env, cameraObj, "zoom", &zoomVal) == napi_ok) {
        double zoom;
        napi_get_value_double(env, zoomVal, &zoom);
        camera.zoom = zoom;
    }
    
    // 解析 bearing
    napi_value bearingVal;
    if (napi_get_named_property(env, cameraObj, "bearing", &bearingVal) == napi_ok) {
        double bearing;
        napi_get_value_double(env, bearingVal, &bearing);
        camera.bearing = bearing;
    }
    
    // 解析 tilt (pitch)
    napi_value tiltVal;
    if (napi_get_named_property(env, cameraObj, "tilt", &tiltVal) == napi_ok) {
        double tilt;
        napi_get_value_double(env, tiltVal, &tilt);
        camera.pitch = tilt;
    }
    
    snapshotterInstance->snapshotter->setCameraOptions(camera);
    Logger::info("SnapshotterNAPI", "Camera position set");

    return nullptr;
}

} // namespace harmony
} // namespace mbgl

/**
 * MapSnapshotterNAPI::Init 实现
 */
namespace mbgl {
namespace harmony {

void MapSnapshotterNAPI::Init(napi_env env, napi_value exports) {
    // 注册创建函数
    napi_property_descriptor descriptors[] = {
        {"createMapSnapshotter", nullptr, CreateMapSnapshotter, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    
    Logger::info("SnapshotterNAPI", "MapSnapshotter APIs registered");
}

} // namespace harmony
} // namespace mbgl

