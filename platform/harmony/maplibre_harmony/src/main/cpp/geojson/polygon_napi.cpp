#include "polygon_napi.hpp"
#include "util.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;
using namespace mbgl::harmony::napi;

namespace maplibre {
namespace harmony {
namespace geojson {

// Static member initialization
napi_ref PolygonNAPI::constructor = nullptr;

PolygonNAPI::PolygonNAPI() noexcept : rings_() {
}

PolygonNAPI::PolygonNAPI(const mbgl::Polygon<double>& polygon)
    : rings_(polygon) {
}

PolygonNAPI::PolygonNAPI(const std::vector<mbgl::LinearRing<double>>& rings)
    : rings_(rings) {
}

PolygonNAPI::~PolygonNAPI() {
}

void PolygonNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    PolygonNAPI* polygon = static_cast<PolygonNAPI*>(nativeObject);
    delete polygon;
}

napi_value PolygonNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("PolygonNAPI", "Initializing Polygon NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getCoordinates", nullptr, GetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCoordinates", nullptr, SetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "toJSON", nullptr, ToJSON, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Polygon", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("PolygonNAPI", "Failed to define Polygon class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("PolygonNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Polygon", cons);
    if (status != napi_ok) {
        Logger::error("PolygonNAPI", "Failed to set Polygon property");
        return nullptr;
    }
    
    Logger::info("PolygonNAPI", "Polygon NAPI class initialized successfully");
    return exports;
}

napi_value PolygonNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Polygon 构造函数: new Polygon(coordinates)
    // coordinates: [[[lng, lat], [lng, lat], ...], ...]  (外环 + 可选内环)
    
    PolygonNAPI* polygon = nullptr;
    
    try {
        if (args.Count() == 0) {
            polygon = new PolygonNAPI();
        } else {
            napi_value coordsArray = args.GetArray(0, "coordinates");
            if (args.HasError()) return nullptr;
            
            auto rings = NapiArrayToLinearRingVector(env, coordsArray);
            polygon = new PolygonNAPI(rings);
        }
        
        napi_status status = napi_wrap(env, args.This(), polygon, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete polygon;
            napi_throw_error(env, nullptr, "Failed to wrap Polygon object");
            return nullptr;
        }
        
        return args.This();
    } catch (const std::exception& e) {
        if (polygon) delete polygon;
        Logger::error("PolygonNAPI", "Failed to create Polygon: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value PolygonNAPI::New(napi_env env, const mbgl::Polygon<double>& polygon) {
    if (constructor == nullptr) {
        Logger::error("PolygonNAPI", "Polygon constructor not initialized");
        return nullptr;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("PolygonNAPI", "Failed to get Polygon constructor");
        return nullptr;
    }
    
    // 创建坐标数组
    napi_value coordsArray = LinearRingVectorToNapiArray(env, polygon);
    
    napi_value argv[1] = { coordsArray };
    napi_value instance;
    status = napi_new_instance(env, cons, 1, argv, &instance);
    if (status != napi_ok) {
        Logger::error("PolygonNAPI", "Failed to create Polygon instance");
        return nullptr;
    }
    
    return instance;
}

napi_value PolygonNAPI::GetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    PolygonNAPI* polygon = nullptr;
    napi_status status = napi_unwrap(env, args.This(), reinterpret_cast<void**>(&polygon));
    
    if (status != napi_ok || !polygon) {
        napi_throw_error(env, nullptr, "Failed to unwrap Polygon object");
        return nullptr;
    }
    
    return LinearRingVectorToNapiArray(env, polygon->rings_);
}

napi_value PolygonNAPI::SetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    PolygonNAPI* polygon = nullptr;
    napi_status status = napi_unwrap(env, args.This(), reinterpret_cast<void**>(&polygon));
    
    if (status != napi_ok || !polygon) {
        napi_throw_error(env, nullptr, "Failed to unwrap Polygon object");
        return nullptr;
    }
    
    try {
        napi_value coordsArray = args.GetArray(0, "coordinates");
        if (args.HasError()) return nullptr;
        
        polygon->rings_ = NapiArrayToLinearRingVector(env, coordsArray);
        return args.This();
    } catch (const std::exception& e) {
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value PolygonNAPI::ToJSON(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    PolygonNAPI* polygon = nullptr;
    napi_status status = napi_unwrap(env, args.This(), reinterpret_cast<void**>(&polygon));
    
    if (status != napi_ok || !polygon) {
        napi_throw_error(env, nullptr, "Failed to unwrap Polygon object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_object(env, &result);
    
    // type: "Polygon"
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    // coordinates
    napi_value coordinates = LinearRingVectorToNapiArray(env, polygon->rings_);
    napi_set_named_property(env, result, "coordinates", coordinates);
    
    return result;
}

mbgl::Polygon<double> PolygonNAPI::convert(napi_env env, napi_value value) {
    // 首先尝试从 NAPI 类实例获取
    PolygonNAPI* polygon = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&polygon));
    
    if (status == napi_ok && polygon) {
        return polygon->rings_;
    }
    
    // 如果不是 NAPI 实例，尝试从普通对象解析
    if (!IsObject(env, value)) {
        throw std::runtime_error("Polygon must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("Polygon coordinates must be an array");
    }
    
    // Polygon is a vector<LinearRing>, so use NapiArrayToLinearRingVector
    return NapiArrayToLinearRingVector(env, coordinates);
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre
