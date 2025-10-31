/**
 * MapSnapshotter NAPI Bindings for HarmonyOS
 */

#include "snapshotter_napi.hpp"
#include "map_snapshotter_harmony.hpp"
#include "../utils/logger.h"
#include "../camera/camera_position_harmony.hpp"
#include "../geometry/lat_lng_bounds_harmony.hpp"
#include "../core/thread_safe_callback.hpp"
#include "../napi/core/napi_args.hpp"

#include <mbgl/map/camera.hpp>
#include <napi/native_api.h>
#include <string>
#include <memory>

namespace mbgl {
namespace harmony {

using mbgl::harmony::napi::NapiArgs;

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
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // 解析选项对象
    napi_value optionsObj = args.GetObject(0, "options");
    if (args.HasError()) return args.Undefined();
    
    MapSnapshotterHarmony::SnapshotOptions options;
    
    // 解析必需的参数
    options.width = static_cast<uint32_t>(args.GetInt64Property(optionsObj, "width", 0));
    options.height = static_cast<uint32_t>(args.GetInt64Property(optionsObj, "height", 0));
    options.pixelRatio = static_cast<float>(args.GetDoubleProperty(optionsObj, "pixelRatio", 1.0));
    options.styleURL = args.GetStringProperty(optionsObj, "styleUrl", "");
    options.showLogo = args.GetBoolProperty(optionsObj, "showLogo", true);
    
    // 解析 styleJSON（可选）
    std::string styleJSON = args.GetStringProperty(optionsObj, "styleJSON", "");
    if (!styleJSON.empty()) {
        options.styleJSON = styleJSON;
        Logger::info("SnapshotterNAPI", "Using styleJSON: %zu bytes", styleJSON.size());
    }
    
    // 解析 camera（可选）
    napi_value cameraVal;
    napi_status status = napi_get_named_property(env, optionsObj, "camera", &cameraVal);
    if (status == napi_ok) {
        napi_valuetype cameraType;
        napi_typeof(env, cameraVal, &cameraType);
        if (cameraType == napi_object) {
            mbgl::CameraOptions camera;
            
            // 解析 target (LatLng)
            napi_value targetVal;
            if (napi_get_named_property(env, cameraVal, "target", &targetVal) == napi_ok) {
                double lat = args.GetDoubleProperty(targetVal, "latitude", 0.0);
                double lng = args.GetDoubleProperty(targetVal, "longitude", 0.0);
                camera.center = mbgl::LatLng(lat, lng);
            }
            
            // 解析 zoom, bearing, tilt
            camera.zoom = args.GetDoubleProperty(cameraVal, "zoom", 0.0);
            camera.bearing = args.GetDoubleProperty(cameraVal, "bearing", 0.0);
            camera.pitch = args.GetDoubleProperty(cameraVal, "tilt", 0.0);
            
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
            double north = args.GetDoubleProperty(regionVal, "north", 0.0);
            double south = args.GetDoubleProperty(regionVal, "south", 0.0);
            double east = args.GetDoubleProperty(regionVal, "east", 0.0);
            double west = args.GetDoubleProperty(regionVal, "west", 0.0);
            
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
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // 保存回调函数引用
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return args.Undefined();
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
    NapiArgs args(env, info);

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
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
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // 解析 styleUrl
    std::string styleUrl = args.GetString(0, "styleUrl");
    if (args.HasError()) return args.Undefined();
    
    snapshotterInstance->snapshotter->setStyleURL(styleUrl);

    return nullptr;
}

/**
 * 设置相机位置
 */
napi_value SnapshotterSetCameraPosition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // 解析 CameraPosition
    napi_value cameraObj = args.GetObject(0, "cameraPosition");
    if (args.HasError()) return args.Undefined();
    
    mbgl::CameraOptions camera;
    
    // 解析 target (LatLng)
    napi_value targetVal;
    if (napi_get_named_property(env, cameraObj, "target", &targetVal) == napi_ok) {
        double lat = args.GetDoubleProperty(targetVal, "latitude", 0.0);
        double lng = args.GetDoubleProperty(targetVal, "longitude", 0.0);
        camera.center = mbgl::LatLng(lat, lng);
    }
    
    // 解析 zoom, bearing, tilt
    camera.zoom = args.GetDoubleProperty(cameraObj, "zoom", 0.0);
    camera.bearing = args.GetDoubleProperty(cameraObj, "bearing", 0.0);
    camera.pitch = args.GetDoubleProperty(cameraObj, "tilt", 0.0);
    
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

