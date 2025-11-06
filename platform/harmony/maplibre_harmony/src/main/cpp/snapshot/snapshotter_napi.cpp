/**
 * MapSnapshotter NAPI Bindings for HarmonyOS
 */

#include "snapshotter_napi.hpp"
#include "map_snapshotter_harmony.hpp"
#include "map_snapshot_napi.hpp"
#include "../utils/logger.h"
#include "../camera/camera_position_harmony.hpp"
#include "../geometry/lat_lng_bounds_harmony.hpp"
#include "../core/thread_safe_callback.hpp"
#include "../napi/core/napi_args.hpp"

#include <mbgl/map/camera.hpp>
#include <napi/native_api.h>
#include <string>
#include <memory>

using mbgl::harmony::ThreadSafeCallback;
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

using mbgl::harmony::napi::NapiArgs;

// 前向声明
napi_value SnapshotterStart(napi_env env, napi_callback_info info);
napi_value SnapshotterCancel(napi_env env, napi_callback_info info);
napi_value SnapshotterSetStyleUrl(napi_env env, napi_callback_info info);
napi_value SnapshotterSetStyleJson(napi_env env, napi_callback_info info);
napi_value SnapshotterSetCameraPosition(napi_env env, napi_callback_info info);
napi_value SnapshotterSetRegion(napi_env env, napi_callback_info info);
napi_value SnapshotterSetSize(napi_env env, napi_callback_info info);
napi_value SnapshotterSetObserver(napi_env env, napi_callback_info info);
napi_value SnapshotterGetLayer(napi_env env, napi_callback_info info);
napi_value SnapshotterGetSource(napi_env env, napi_callback_info info);
napi_value SnapshotterAddImage(napi_env env, napi_callback_info info);

/**
 * MapSnapshotter 内部实例类
 */
class MapSnapshotterInstance {
public:
    std::unique_ptr<MapSnapshotterHarmony> snapshotter;
    napi_env env;
    napi_ref callbackRef = nullptr;
    napi_ref errorCallbackRef = nullptr;
    
    // 使用 ThreadSafeCallback 替代 observerRef
    std::unique_ptr<ThreadSafeCallback> onDidFinishLoadingStyleCallback;
    std::unique_ptr<ThreadSafeCallback> onStyleImageMissingCallback;

    MapSnapshotterInstance(napi_env e) : env(e) {}

    ~MapSnapshotterInstance() {
        if (callbackRef) {
            napi_delete_reference(env, callbackRef);
        }
        if (errorCallbackRef) {
            napi_delete_reference(env, errorCallbackRef);
        }
        // ThreadSafeCallback 会在析构时自动释放
    }
    
    /**
     * 触发 onDidFinishLoadingStyle 回调（线程安全）
     */
    void triggerOnDidFinishLoadingStyle() {
        if (onDidFinishLoadingStyleCallback && onDidFinishLoadingStyleCallback->IsValid()) {
            onDidFinishLoadingStyleCallback->CallEmpty();
        }
    }
    
    /**
     * 触发 onStyleImageMissing 回调（线程安全）
     */
    void triggerOnStyleImageMissing(const std::string& imageName) {
        if (onStyleImageMissingCallback && onStyleImageMissingCallback->IsValid()) {
            onStyleImageMissingCallback->CallWithString(imageName);
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
    
    // 设置 observer 回调，使 C++ 层能够触发 TypeScript 的 observer
    snapshotterInstance->snapshotter->setObserverCallback(
        [snapshotterInstance](const std::string& event, const std::string& data) {
            if (event == "onDidFinishLoadingStyle") {
                snapshotterInstance->triggerOnDidFinishLoadingStyle();
            } else if (event == "onStyleImageMissing") {
                snapshotterInstance->triggerOnStyleImageMissing(data);
            }
        }
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
    
    // 为对象绑定方法
    napi_property_descriptor methods[] = {
        {"start", nullptr, SnapshotterStart, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"cancel", nullptr, SnapshotterCancel, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setStyleUrl", nullptr, SnapshotterSetStyleUrl, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setStyleJson", nullptr, SnapshotterSetStyleJson, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setCameraPosition", nullptr, SnapshotterSetCameraPosition, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setRegion", nullptr, SnapshotterSetRegion, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setSize", nullptr, SnapshotterSetSize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setObserver", nullptr, SnapshotterSetObserver, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLayer", nullptr, SnapshotterGetLayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getSource", nullptr, SnapshotterGetSource, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addImage", nullptr, SnapshotterAddImage, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    napi_define_properties(env, jsSnapshotter, sizeof(methods) / sizeof(methods[0]), methods);
    
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

    // 创建线程安全回调
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return args.Undefined();
    
    auto threadSafeCallback = ThreadSafeCallback::Create(env, callback, "SnapshotterCallback");
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }

    Logger::info("SnapshotterNAPI", "Starting snapshot");

    // 使用 shared_ptr 确保回调在异步操作完成前不被释放
    auto sharedCallback = std::shared_ptr<ThreadSafeCallback>(std::move(threadSafeCallback));

    // 获取 pixelRatio（从 snapshotter 的选项中）
    float pixelRatio = 1.0f; // 默认值，实际应该从 snapshotter 获取
    // TODO: 从 snapshotterInstance 的选项中获取 pixelRatio
    
    // 调用 C++ snapshot 方法
    snapshotterInstance->snapshotter->snapshot(
        [sharedCallback, pixelRatio](
            std::exception_ptr err,
            mbgl::PremultipliedImage image,
            std::vector<std::string> attributions,
            mbgl::MapSnapshotter::PointForFn pointForFn,
            mbgl::MapSnapshotter::LatLngForFn latLngForFn
        ) {
            // 使用 ThreadSafeCallback 安全地调用到主线程
            Logger::info("SnapshotterNAPI", "Snapshot callback triggered");
            
            if (err) {
                // 发生错误
                try {
                    std::rethrow_exception(err);
                } catch (const std::exception& e) {
                    Logger::error("SnapshotterNAPI", "Snapshot error: %s", e.what());
                    
                    std::string errorMsg = e.what();
                    // 使用 ThreadSafeCallback，在 lambda 中获取实际回调并调用
                    // ThreadSafeCallback 只是用来调度到主线程，实际调用由我们控制
                    sharedCallback->CallWithString(errorMsg);
                }
            } else {
                // 成功 - 移动数据到堆上以便在线程安全回调中使用
                Logger::info("SnapshotterNAPI", "Snapshot success: %dx%d, %zu bytes",
                             image.size.width, image.size.height, image.bytes());
                
                // 移动所有数据到 shared_ptr（自动管理内存）
                auto imageData = std::make_shared<mbgl::PremultipliedImage>(std::move(image));
                auto attrs = std::make_shared<std::vector<std::string>>(std::move(attributions));
                
                // 使用 ThreadSafeCallback 在主线程创建 MapSnapshot 对象
                sharedCallback->Call([imageData, attrs, pixelRatio, pointForFn, latLngForFn](napi_env env) -> napi_value {
                    // 使用新的 CreateMapSnapshotObject 函数创建完整的 MapSnapshot 对象
                    // 注意：需要移动 imageData 的数据
                    mbgl::PremultipliedImage imageCopy = std::move(*imageData);
                    napi_value mapSnapshotObj = CreateMapSnapshotObject(
                        env,
                        std::move(imageCopy),
                        *attrs,
                        pixelRatio,
                        pointForFn,
                        latLngForFn
                    );
                    
                    // 返回 MapSnapshot 对象（会作为回调的单个参数传入）
                    return mapSnapshotObj;
                });
            }
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

/**
 * 设置样式 JSON
 */
napi_value SnapshotterSetStyleJson(napi_env env, napi_callback_info info) {
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

    // 解析 styleJson
    std::string styleJson = args.GetString(0, "styleJson");
    if (args.HasError()) return args.Undefined();
    
    snapshotterInstance->snapshotter->setStyleJSON(styleJson);
    Logger::info("SnapshotterNAPI", "Style JSON set");

    return nullptr;
}

/**
 * 设置区域边界
 */
napi_value SnapshotterSetRegion(napi_env env, napi_callback_info info) {
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

    // 解析 LatLngBounds
    napi_value regionObj = args.GetObject(0, "region");
    if (args.HasError()) return args.Undefined();
    
    double north = args.GetDoubleProperty(regionObj, "north", 0.0);
    double south = args.GetDoubleProperty(regionObj, "south", 0.0);
    double east = args.GetDoubleProperty(regionObj, "east", 0.0);
    double west = args.GetDoubleProperty(regionObj, "west", 0.0);
    
    mbgl::LatLngBounds bounds = mbgl::LatLngBounds::hull(
        mbgl::LatLng(north, east),
        mbgl::LatLng(south, west)
    );
    
    snapshotterInstance->snapshotter->setRegion(bounds);
    Logger::info("SnapshotterNAPI", "Region set");

    return nullptr;
}

/**
 * 设置快照尺寸
 */
napi_value SnapshotterSetSize(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return args.Undefined();

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // 解析 width 和 height
    uint32_t width = static_cast<uint32_t>(args.GetInt64(0, "width"));
    uint32_t height = static_cast<uint32_t>(args.GetInt64(1, "height"));
    if (args.HasError()) return args.Undefined();
    
    snapshotterInstance->snapshotter->setSize({width, height});
    Logger::info("SnapshotterNAPI", "Size set to %ux%u", width, height);

    return nullptr;
}

/**
 * 设置观察者
 */
napi_value SnapshotterSetObserver(napi_env env, napi_callback_info info) {
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

    // 清除旧的 callbacks
    snapshotterInstance->onDidFinishLoadingStyleCallback.reset();
    snapshotterInstance->onStyleImageMissingCallback.reset();

    // 获取 observer 对象
    napi_value argv[1];
    size_t argc = 1;
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    napi_value observer = argv[0];
    
    // 检查是否为 null（允许传 null 来清除 observer）
    napi_valuetype valueType;
    napi_typeof(env, observer, &valueType);
    
    if (valueType != napi_null && valueType != napi_undefined) {
        // 从 observer 对象中提取两个方法
        napi_value onDidFinishLoadingStyleMethod;
        napi_value onStyleImageMissingMethod;
        
        if (napi_get_named_property(env, observer, "onDidFinishLoadingStyle", &onDidFinishLoadingStyleMethod) == napi_ok) {
            snapshotterInstance->onDidFinishLoadingStyleCallback = 
                ThreadSafeCallback::Create(env, onDidFinishLoadingStyleMethod, "SnapshotterOnDidFinishLoadingStyle");
        }
        
        if (napi_get_named_property(env, observer, "onStyleImageMissing", &onStyleImageMissingMethod) == napi_ok) {
            snapshotterInstance->onStyleImageMissingCallback = 
                ThreadSafeCallback::Create(env, onStyleImageMissingMethod, "SnapshotterOnStyleImageMissing");
        }
        
        Logger::info("SnapshotterNAPI", "Observer set with ThreadSafeCallback");
    } else {
        Logger::info("SnapshotterNAPI", "Observer cleared");
    }

    return nullptr;
}

/**
 * 获取图层
 * 
 * JavaScript 调用：
 * const layer = snapshotter.getLayer(layerId);
 */
napi_value SnapshotterGetLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        Logger::warn("SnapshotterNAPI", "getLayer: Snapshotter not initialized");
        return args.Undefined();
    }

    // 解析 layerId
    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) return args.Undefined();

    // TODO: 实现图层获取
    // 需要访问 snapshotter->getStyle().getLayer(layerId)
    // 并将结果转换为 NAPI Layer 对象
    Logger::warn("SnapshotterNAPI", "getLayer: Not fully implemented yet");
    
    return args.Undefined();
}

/**
 * 获取数据源
 * 
 * JavaScript 调用：
 * const source = snapshotter.getSource(sourceId);
 */
napi_value SnapshotterGetSource(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        Logger::warn("SnapshotterNAPI", "getSource: Snapshotter not initialized");
        return args.Undefined();
    }

    // 解析 sourceId
    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) return args.Undefined();

    // TODO: 实现数据源获取
    // 需要访问 snapshotter->getStyle().getSource(sourceId)
    // 并将结果转换为 NAPI Source 对象
    Logger::warn("SnapshotterNAPI", "getSource: Not fully implemented yet");
    
    return args.Undefined();
}

/**
 * 添加图片
 * 
 * JavaScript 调用：
 * snapshotter.addImage(name, imageData, sdf);
 */
napi_value SnapshotterAddImage(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(3);
    if (args.HasError()) return args.Undefined();

    // 获取 native 实例
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        Logger::warn("SnapshotterNAPI", "addImage: Snapshotter not initialized");
        return args.Undefined();
    }

    // 解析参数
    std::string name = args.GetString(0, "name");
    // napi_value imageData = args.GetValue(1); // ImageBitmap 或 ArrayBuffer
    bool sdf = args.GetBool(2, "sdf");
    
    if (args.HasError()) return args.Undefined();

    // TODO: 实现图片添加
    // 需要：
    // 1. 解析 ImageBitmap/ArrayBuffer 为 mbgl::PremultipliedImage
    // 2. 调用 snapshotter->getStyle().addImage(name, std::move(image), sdf)
    Logger::warn("SnapshotterNAPI", "addImage: Not fully implemented yet - name=%s, sdf=%d", 
                 name.c_str(), sdf);
    
    return args.Undefined();
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

