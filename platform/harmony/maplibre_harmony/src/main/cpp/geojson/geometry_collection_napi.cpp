#include "geometry_collection_napi.hpp"
#include "geometry_napi.hpp"
#include "util.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;
using namespace mbgl::harmony::napi;
using namespace maplibre::harmony::geojson;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_ref GeometryCollectionNAPI::constructor = nullptr;

GeometryCollectionNAPI::GeometryCollectionNAPI() : geometries_() {}

GeometryCollectionNAPI::GeometryCollectionNAPI(const mapbox::geometry::geometry_collection<double>& collection)
    : geometries_(collection) {}

GeometryCollectionNAPI::~GeometryCollectionNAPI() {}

void GeometryCollectionNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<GeometryCollectionNAPI*>(nativeObject);
}

napi_value GeometryCollectionNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("GeometryCollectionNAPI", "Initializing GeometryCollection NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getGeometries", nullptr, GetGeometries, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "toJSON", nullptr, ToJSON, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "GeometryCollection", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("GeometryCollectionNAPI", "Failed to define GeometryCollection class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("GeometryCollectionNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "GeometryCollection", cons);
    if (status != napi_ok) {
        Logger::error("GeometryCollectionNAPI", "Failed to set GeometryCollection property");
        return nullptr;
    }
    
    Logger::info("GeometryCollectionNAPI", "GeometryCollection NAPI class initialized successfully");
    return exports;
}

napi_value GeometryCollectionNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    GeometryCollectionNAPI* geometryCollection = nullptr;
    
    try {
        geometryCollection = new GeometryCollectionNAPI();
        
        napi_status status = napi_wrap(env, jsThis, geometryCollection, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete geometryCollection;
            napi_throw_error(env, nullptr, "Failed to wrap GeometryCollection object");
            return nullptr;
        }
        
        return jsThis;
    } catch (const std::exception& e) {
        if (geometryCollection) delete geometryCollection;
        Logger::error("GeometryCollectionNAPI", "Failed to create GeometryCollection: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

// 工厂方法：从 geometry_collection 创建 NAPI 实例
napi_value GeometryCollectionNAPI::New(napi_env env, const mapbox::geometry::geometry_collection<double>& collection) {
    return FromMbglGeometryCollection(env, collection);
}

napi_value GeometryCollectionNAPI::GetGeometries(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    GeometryCollectionNAPI* geometryCollection = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&geometryCollection));
    
    if (status != napi_ok || !geometryCollection) {
        napi_throw_error(env, nullptr, "Failed to unwrap GeometryCollection object");
        return nullptr;
    }
    
    napi_value array;
    napi_create_array_with_length(env, geometryCollection->geometries_.size(), &array);
    
    for (size_t i = 0; i < geometryCollection->geometries_.size(); i++) {
        napi_value geom = GeometryNAPI::New(env, geometryCollection->geometries_[i]);
        napi_set_element(env, array, i, geom);
    }
    
    return array;
}

napi_value GeometryCollectionNAPI::ToJSON(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    GeometryCollectionNAPI* geometryCollection = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&geometryCollection));
    
    if (status != napi_ok || !geometryCollection) {
        napi_throw_error(env, nullptr, "Failed to unwrap GeometryCollection object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    napi_value geometries;
    napi_create_array_with_length(env, geometryCollection->geometries_.size(), &geometries);
    
    for (size_t i = 0; i < geometryCollection->geometries_.size(); i++) {
        napi_value geom = GeometryNAPI::New(env, geometryCollection->geometries_[i]);
        napi_set_element(env, geometries, i, geom);
    }
    napi_set_named_property(env, result, "geometries", geometries);
    
    return result;
}

napi_value GeometryCollectionNAPI::FromMbglGeometryCollection(napi_env env, const mapbox::geometry::geometry_collection<double>& collection) {
    if (constructor == nullptr) {
        Logger::error("GeometryCollectionNAPI", "GeometryCollection constructor not initialized");
        return nullptr;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("GeometryCollectionNAPI", "Failed to get GeometryCollection constructor");
        return nullptr;
    }
    
    napi_value instance;
    status = napi_new_instance(env, cons, 0, nullptr, &instance);
    if (status != napi_ok) {
        Logger::error("GeometryCollectionNAPI", "Failed to create GeometryCollection instance");
        return nullptr;
    }
    
    // 设置几何体
    GeometryCollectionNAPI* geometryCollection = nullptr;
    status = napi_unwrap(env, instance, reinterpret_cast<void**>(&geometryCollection));
    if (status == napi_ok && geometryCollection) {
        geometryCollection->geometries_ = collection;
    }
    
    return instance;
}

mapbox::geometry::geometry_collection<double> GeometryCollectionNAPI::convert(napi_env env, napi_value value) {
    // 首先尝试从 NAPI 类实例获取
    GeometryCollectionNAPI* geometryCollection = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&geometryCollection));
    
    if (status == napi_ok && geometryCollection) {
        return geometryCollection->toMbglGeometryCollection();
    }
    
    // 如果不是 NAPI 实例，尝试从普通对象解析
    if (!IsObject(env, value)) {
        throw std::runtime_error("GeometryCollection must be an object");
    }
    
    // 获取 geometries
    napi_value geometries = GetObjectProperty(env, value, "geometries");
    
    if (!IsArray(env, geometries)) {
        throw std::runtime_error("GeometryCollection geometries must be an array");
    }
    
    uint32_t length;
    napi_get_array_length(env, geometries, &length);
    
    mapbox::geometry::geometry_collection<double> result;
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, geometries, i, &element);
        
        // 使用 GeometryNAPI::convert 转换每个几何体
        result.push_back(GeometryNAPI::convert(env, element));
    }
    
    return result;
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre
