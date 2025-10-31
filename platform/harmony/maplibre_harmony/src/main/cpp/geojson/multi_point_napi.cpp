#include "multi_point_napi.hpp"
#include "util.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;
using namespace mbgl::harmony::napi;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_ref MultiPointNAPI::constructor = nullptr;

MultiPointNAPI::MultiPointNAPI() : points_() {}

MultiPointNAPI::MultiPointNAPI(const mbgl::MultiPoint<double>& multiPoint)
    : points_(multiPoint) {}

MultiPointNAPI::MultiPointNAPI(const std::vector<mbgl::Point<double>>& points)
    : points_(points) {}

MultiPointNAPI::~MultiPointNAPI() {}

void MultiPointNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<MultiPointNAPI*>(nativeObject);
}

napi_value MultiPointNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("MultiPointNAPI", "Initializing MultiPoint NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getCoordinates", nullptr, GetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCoordinates", nullptr, SetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "toJSON", nullptr, ToJSON, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "MultiPoint", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("MultiPointNAPI", "Failed to define MultiPoint class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("MultiPointNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "MultiPoint", cons);
    if (status != napi_ok) {
        Logger::error("MultiPointNAPI", "Failed to set MultiPoint property");
        return nullptr;
    }
    
    Logger::info("MultiPointNAPI", "MultiPoint NAPI class initialized successfully");
    return exports;
}

napi_value MultiPointNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    MultiPointNAPI* multiPoint = nullptr;
    
    try {
        if (args.Count() == 0) {
            multiPoint = new MultiPointNAPI();
        } else {
            napi_value coordsArray = args.GetArray(0, "coordinates");
            if (args.HasError()) return nullptr;
            
            auto points = NapiArrayToPointVector(env, coordsArray);
            multiPoint = new MultiPointNAPI(points);
        }
        
        napi_status status = napi_wrap(env, args.This(), multiPoint, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete multiPoint;
            napi_throw_error(env, nullptr, "Failed to wrap MultiPoint object");
            return nullptr;
        }
        
        return args.This();
    } catch (const std::exception& e) {
        if (multiPoint) delete multiPoint;
        Logger::error("MultiPointNAPI", "Failed to create MultiPoint: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

// 工厂方法：从 mbgl::MultiPoint 创建 NAPI 实例
napi_value MultiPointNAPI::New(napi_env env, const mbgl::MultiPoint<double>& multiPoint) {
    return FromMbglMultiPoint(env, multiPoint);
}

napi_value MultiPointNAPI::GetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    MultiPointNAPI* multiPoint = nullptr;
    napi_status status = napi_unwrap(env, args.This(), reinterpret_cast<void**>(&multiPoint));
    
    if (status != napi_ok || !multiPoint) {
        napi_throw_error(env, nullptr, "Failed to unwrap MultiPoint object");
        return nullptr;
    }
    
    return PointVectorToNapiArray(env, multiPoint->points_);
}

napi_value MultiPointNAPI::SetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    MultiPointNAPI* multiPoint = nullptr;
    napi_status status = napi_unwrap(env, args.This(), reinterpret_cast<void**>(&multiPoint));
    
    if (status != napi_ok || !multiPoint) {
        napi_throw_error(env, nullptr, "Failed to unwrap MultiPoint object");
        return nullptr;
    }
    
    try {
        napi_value coordsArray = args.GetArray(0, "coordinates");
        if (args.HasError()) return nullptr;
        
        multiPoint->points_ = NapiArrayToPointVector(env, coordsArray);
        return args.Undefined();
    } catch (const std::exception& e) {
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value MultiPointNAPI::ToJSON(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    MultiPointNAPI* multiPoint = nullptr;
    napi_status status = napi_unwrap(env, args.This(), reinterpret_cast<void**>(&multiPoint));
    
    if (status != napi_ok || !multiPoint) {
        napi_throw_error(env, nullptr, "Failed to unwrap MultiPoint object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    napi_value coordinates = PointVectorToNapiArray(env, multiPoint->points_);
    napi_set_named_property(env, result, "coordinates", coordinates);
    
    return result;
}

napi_value MultiPointNAPI::FromMbglMultiPoint(napi_env env, const mbgl::MultiPoint<double>& multiPoint) {
    if (constructor == nullptr) {
        Logger::error("MultiPointNAPI", "MultiPoint constructor not initialized");
        return nullptr;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("MultiPointNAPI", "Failed to get MultiPoint constructor");
        return nullptr;
    }
    
    napi_value coordsArray = PointVectorToNapiArray(env, multiPoint);
    napi_value argv[1] = { coordsArray };
    napi_value instance;
    status = napi_new_instance(env, cons, 1, argv, &instance);
    if (status != napi_ok) {
        Logger::error("MultiPointNAPI", "Failed to create MultiPoint instance");
        return nullptr;
    }
    
    return instance;
}

mbgl::MultiPoint<double> MultiPointNAPI::convert(napi_env env, napi_value value) {
    // 首先尝试从 NAPI 类实例获取
    MultiPointNAPI* multiPoint = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&multiPoint));
    
    if (status == napi_ok && multiPoint) {
        return multiPoint->toMbglMultiPoint();
    }
    
    // 如果不是 NAPI 实例，尝试从普通对象解析
    if (!IsObject(env, value)) {
        throw std::runtime_error("MultiPoint must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("MultiPoint coordinates must be an array");
    }
    
    return NapiArrayToPointVector(env, coordinates);
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre
