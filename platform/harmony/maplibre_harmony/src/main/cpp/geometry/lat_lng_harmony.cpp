#include "lat_lng_harmony.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include <cmath>

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// ==================== LatLngNapi 类实现 ====================

napi_ref LatLngNapi::constructor_ = nullptr;

LatLngNapi::LatLngNapi(double latitude, double longitude)
    : latLng_(latitude, longitude) {
}

LatLngNapi::LatLngNapi(const mbgl::LatLng& latLng)
    : latLng_(latLng) {
}

napi_value LatLngNapi::Init(napi_env env, napi_value exports) {
    napi_property_descriptor properties[] = {
        { "latitude", nullptr, nullptr, GetLatitudeProperty, nullptr, nullptr, napi_default, nullptr },
        { "longitude", nullptr, nullptr, GetLongitudeProperty, nullptr, nullptr, napi_default, nullptr }
    };
    
    napi_value cons;
    napi_status status = napi_define_class(
        env,
        "LatLng",
        NAPI_AUTO_LENGTH,
        Constructor,
        nullptr,
        sizeof(properties) / sizeof(properties[0]),
        properties,
        &cons
    );
    
    if (status != napi_ok) {
        Logger::error("LatLngNapi", "Failed to define LatLng class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor_);
    if (status != napi_ok) {
        Logger::error("LatLngNapi", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "LatLng", cons);
    if (status != napi_ok) {
        Logger::error("LatLngNapi", "Failed to set LatLng property");
        return nullptr;
    }
    
    Logger::info("LatLngNapi", "LatLng class registered successfully");
    return exports;
}

void LatLngNapi::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    LatLngNapi* obj = static_cast<LatLngNapi*>(nativeObject);
    delete obj;
}

napi_value LatLngNapi::Constructor(napi_env env, napi_callback_info info) {
    napi_status status;
    napi_value target;
    status = napi_get_cb_info(env, info, nullptr, nullptr, &target, nullptr);
    if (status != napi_ok) {
        Logger::error("LatLngNapi", "Failed to get callback info");
        return nullptr;
    }
    
    // 获取参数
    size_t argc = 2;
    napi_value args[2];
    napi_value jsthis;
    status = napi_get_cb_info(env, info, &argc, args, &jsthis, nullptr);
    if (status != napi_ok || argc < 2) {
        napi_throw_error(env, nullptr, "LatLng constructor requires 2 arguments: latitude, longitude");
        return nullptr;
    }
    
    // 解析参数
    double latitude, longitude;
    status = napi_get_value_double(env, args[0], &latitude);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Invalid latitude argument");
        return nullptr;
    }
    
    status = napi_get_value_double(env, args[1], &longitude);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Invalid longitude argument");
        return nullptr;
    }
    
    // 创建 C++ 对象
    LatLngNapi* obj = new LatLngNapi(latitude, longitude);
    
    // 包装为 NAPI 对象
    status = napi_wrap(env, jsthis, obj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete obj;
        Logger::error("LatLngNapi", "Failed to wrap native object");
        return nullptr;
    }
    
    return jsthis;
}

napi_value LatLngNapi::CreateInstance(napi_env env, const mbgl::LatLng& latLng) {
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor_, &cons);
    if (status != napi_ok) {
        Logger::error("LatLngNapi", "Failed to get constructor reference");
        return nullptr;
    }
    
    // 创建参数
    napi_value args[2];
    napi_create_double(env, latLng.latitude(), &args[0]);
    napi_create_double(env, latLng.longitude(), &args[1]);
    
    // 创建实例
    napi_value instance;
    status = napi_new_instance(env, cons, 2, args, &instance);
    if (status != napi_ok) {
        Logger::error("LatLngNapi", "Failed to create LatLng instance");
        return nullptr;
    }
    
    return instance;
}

napi_value LatLngNapi::GetLatitudeProperty(napi_env env, napi_callback_info info) {
    napi_status status;
    napi_value jsthis;
    status = napi_get_cb_info(env, info, nullptr, nullptr, &jsthis, nullptr);
    if (status != napi_ok) {
        return nullptr;
    }
    
    LatLngNapi* obj;
    status = napi_unwrap(env, jsthis, reinterpret_cast<void**>(&obj));
    if (status != napi_ok || obj == nullptr) {
        Logger::error("LatLngNapi", "Failed to unwrap LatLng object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_double(env, obj->GetLatitude(), &result);
    return result;
}

napi_value LatLngNapi::GetLongitudeProperty(napi_env env, napi_callback_info info) {
    napi_status status;
    napi_value jsthis;
    status = napi_get_cb_info(env, info, nullptr, nullptr, &jsthis, nullptr);
    if (status != napi_ok) {
        return nullptr;
    }
    
    LatLngNapi* obj;
    status = napi_unwrap(env, jsthis, reinterpret_cast<void**>(&obj));
    if (status != napi_ok || obj == nullptr) {
        Logger::error("LatLngNapi", "Failed to unwrap LatLng object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_double(env, obj->GetLongitude(), &result);
    return result;
}

bool LatLngNapi::ParseLatLng(napi_env env, napi_value value, mbgl::LatLng& outLatLng) {
    // 只支持 LatLngNapi 类实例解析
    LatLngNapi* obj;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&obj));
    if (status == napi_ok && obj != nullptr) {
        outLatLng = obj->GetLatLng();
        return true;
    }
    
    // 不再支持普通对象解析
    Logger::error("LatLngNapi", "ParseLatLng failed: value is not a LatLng NAPI instance");
    return false;
}

// ==================== LatLngHarmony 辅助类实现 ====================

napi_value LatLngHarmony::CreateLatLngObject(napi_env env, const mbgl::LatLng& latLng) {
    // 使用新的 LatLngNapi 类创建实例
    return LatLngNapi::CreateInstance(env, latLng);
}

bool LatLngHarmony::ParseLatLng(napi_env env, napi_value value, mbgl::LatLng& outLatLng) {
    // 检查是否为对象
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("LatLngHarmony", "Value is not an object");
        return false;
    }
    
    // 获取 latitude 属性
    napi_value latValue;
    status = napi_get_named_property(env, value, "latitude", &latValue);
    if (status != napi_ok) {
        Logger::error("LatLngHarmony", "Failed to get latitude property");
        return false;
    }
    
    double latitude;
    status = napi_get_value_double(env, latValue, &latitude);
    if (status != napi_ok) {
        Logger::error("LatLngHarmony", "Failed to parse latitude as double");
        return false;
    }
    
    // 获取 longitude 属性
    napi_value lngValue;
    status = napi_get_named_property(env, value, "longitude", &lngValue);
    if (status != napi_ok) {
        Logger::error("LatLngHarmony", "Failed to get longitude property");
        return false;
    }
    
    double longitude;
    status = napi_get_value_double(env, lngValue, &longitude);
    if (status != napi_ok) {
        Logger::error("LatLngHarmony", "Failed to parse longitude as double");
        return false;
    }
    
    // 验证范围
    if (latitude < -90.0 || latitude > 90.0) {
        Logger::error("LatLngHarmony", "Latitude out of range: %f", latitude);
        return false;
    }
    if (longitude < -180.0 || longitude > 180.0) {
        Logger::error("LatLngHarmony", "Longitude out of range: %f", longitude);
        return false;
    }
    
    outLatLng = mbgl::LatLng(latitude, longitude);
    return true;
}

bool LatLngHarmony::ParseLatLngWithArgs(mbgl::harmony::napi::NapiArgs& args, napi_value obj, mbgl::LatLng& outLatLng) {
    // 使用 NapiArgs 的辅助方法解析对象属性
    double latitude = args.GetDoubleProperty(obj, "latitude", 0.0);
    double longitude = args.GetDoubleProperty(obj, "longitude", 0.0);
    
    if (args.HasError()) {
        Logger::error("LatLngHarmony", "Failed to parse LatLng properties: %s", args.GetError().c_str());
        return false;
    }
    
    // 验证范围
    if (latitude < -90.0 || latitude > 90.0) {
        Logger::error("LatLngHarmony", "Latitude out of range: %f", latitude);
        return false;
    }
    if (longitude < -180.0 || longitude > 180.0) {
        Logger::error("LatLngHarmony", "Longitude out of range: %f", longitude);
        return false;
    }
    
    outLatLng = mbgl::LatLng(latitude, longitude);
    return true;
}

mbgl::LatLng LatLngHarmony::ParseLatLngOr(napi_env env, napi_value value, const mbgl::LatLng& defaultValue) {
    mbgl::LatLng result;
    if (ParseLatLng(env, value, result)) {
        return result;
    }
    return defaultValue;
}

} // namespace harmony
} // namespace mbgl

