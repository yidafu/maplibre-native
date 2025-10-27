#include "multi_polygon_napi.hpp"
#include "util.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;
using namespace mbgl::harmony::napi;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_ref MultiPolygonNAPI::constructor = nullptr;

MultiPolygonNAPI::MultiPolygonNAPI() : polygons_() {}

MultiPolygonNAPI::MultiPolygonNAPI(const mbgl::MultiPolygon<double>& multiPolygon)
    : polygons_(multiPolygon) {}

MultiPolygonNAPI::MultiPolygonNAPI(const std::vector<mbgl::Polygon<double>>& polygons)
    : polygons_(polygons) {}

MultiPolygonNAPI::~MultiPolygonNAPI() {}

void MultiPolygonNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<MultiPolygonNAPI*>(nativeObject);
}

napi_value MultiPolygonNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("MultiPolygonNAPI", "Initializing MultiPolygon NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getCoordinates", nullptr, GetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCoordinates", nullptr, SetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "toJSON", nullptr, ToJSON, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "MultiPolygon", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("MultiPolygonNAPI", "Failed to define MultiPolygon class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("MultiPolygonNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "MultiPolygon", cons);
    if (status != napi_ok) {
        Logger::error("MultiPolygonNAPI", "Failed to set MultiPolygon property");
        return nullptr;
    }
    
    Logger::info("MultiPolygonNAPI", "MultiPolygon NAPI class initialized successfully");
    return exports;
}

napi_value MultiPolygonNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    MultiPolygonNAPI* multiPolygon = nullptr;
    
    try {
        if (args.Count() == 0) {
            multiPolygon = new MultiPolygonNAPI();
        } else {
            napi_value coordsArray = args.GetArray(0, "coordinates");
            if (args.HasError()) return nullptr;
            
            auto polygons = NapiArrayToPolygonVector(env, coordsArray);
            multiPolygon = new MultiPolygonNAPI(polygons);
        }
        
        napi_status status = napi_wrap(env, jsThis, multiPolygon, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete multiPolygon;
            napi_throw_error(env, nullptr, "Failed to wrap MultiPolygon object");
            return nullptr;
        }
        
        return jsThis;
    } catch (const std::exception& e) {
        if (multiPolygon) delete multiPolygon;
        Logger::error("MultiPolygonNAPI", "Failed to create MultiPolygon: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

// 工厂方法：从 mbgl::MultiPolygon 创建 NAPI 实例
napi_value MultiPolygonNAPI::New(napi_env env, const mbgl::MultiPolygon<double>& multiPolygon) {
    return FromMbglMultiPolygon(env, multiPolygon);
}

napi_value MultiPolygonNAPI::GetCoordinates(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    MultiPolygonNAPI* multiPolygon = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&multiPolygon));
    
    if (status != napi_ok || !multiPolygon) {
        napi_throw_error(env, nullptr, "Failed to unwrap MultiPolygon object");
        return nullptr;
    }
    
    return PolygonVectorToNapiArray(env, multiPolygon->polygons_);
}

napi_value MultiPolygonNAPI::SetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    MultiPolygonNAPI* multiPolygon = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&multiPolygon));
    
    if (status != napi_ok || !multiPolygon) {
        napi_throw_error(env, nullptr, "Failed to unwrap MultiPolygon object");
        return nullptr;
    }
    
    try {
        napi_value coordsArray = args.GetArray(0, "coordinates");
        if (args.HasError()) return nullptr;
        
        multiPolygon->polygons_ = NapiArrayToPolygonVector(env, coordsArray);
        return jsThis;
    } catch (const std::exception& e) {
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value MultiPolygonNAPI::ToJSON(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    MultiPolygonNAPI* multiPolygon = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&multiPolygon));
    
    if (status != napi_ok || !multiPolygon) {
        napi_throw_error(env, nullptr, "Failed to unwrap MultiPolygon object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    napi_value coordinates = PolygonVectorToNapiArray(env, multiPolygon->polygons_);
    napi_set_named_property(env, result, "coordinates", coordinates);
    
    return result;
}

napi_value MultiPolygonNAPI::FromMbglMultiPolygon(napi_env env, const mbgl::MultiPolygon<double>& multiPolygon) {
    if (constructor == nullptr) {
        Logger::error("MultiPolygonNAPI", "MultiPolygon constructor not initialized");
        return nullptr;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("MultiPolygonNAPI", "Failed to get MultiPolygon constructor");
        return nullptr;
    }
    
    napi_value coordsArray = PolygonVectorToNapiArray(env, multiPolygon);
    napi_value argv[1] = { coordsArray };
    napi_value instance;
    status = napi_new_instance(env, cons, 1, argv, &instance);
    if (status != napi_ok) {
        Logger::error("MultiPolygonNAPI", "Failed to create MultiPolygon instance");
        return nullptr;
    }
    
    return instance;
}

mbgl::MultiPolygon<double> MultiPolygonNAPI::convert(napi_env env, napi_value value) {
    // 首先尝试从 NAPI 类实例获取
    MultiPolygonNAPI* multiPolygon = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&multiPolygon));
    
    if (status == napi_ok && multiPolygon) {
        return multiPolygon->toMbglMultiPolygon();
    }
    
    // 如果不是 NAPI 实例，尝试从普通对象解析
    if (!IsObject(env, value)) {
        throw std::runtime_error("MultiPolygon must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("MultiPolygon coordinates must be an array");
    }
    
    return NapiArrayToPolygonVector(env, coordinates);
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre
