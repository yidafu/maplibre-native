#include "line_string_napi.hpp"
#include "util.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;
using namespace mbgl::harmony::napi;

namespace maplibre {
namespace harmony {
namespace geojson {

// Static member initialization
napi_ref LineStringNAPI::constructor = nullptr;

LineStringNAPI::LineStringNAPI() : points_() {
}

LineStringNAPI::LineStringNAPI(const mbgl::LineString<double>& lineString)
    : points_(lineString) {
}

LineStringNAPI::LineStringNAPI(const std::vector<mbgl::Point<double>>& points)
    : points_(points) {
}

LineStringNAPI::~LineStringNAPI() {
}

void LineStringNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    LineStringNAPI* lineString = static_cast<LineStringNAPI*>(nativeObject);
    delete lineString;
}

napi_value LineStringNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("LineStringNAPI", "Initializing LineString NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getCoordinates", nullptr, GetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCoordinates", nullptr, SetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addPoint", nullptr, AddPoint, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getPointCount", nullptr, GetPointCount, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "toJSON", nullptr, ToJSON, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "LineString", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("LineStringNAPI", "Failed to define LineString class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("LineStringNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "LineString", cons);
    if (status != napi_ok) {
        Logger::error("LineStringNAPI", "Failed to set LineString property");
        return nullptr;
    }
    
    Logger::info("LineStringNAPI", "LineString NAPI class initialized successfully");
    return exports;
}

napi_value LineStringNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // LineString 构造函数: new LineString(coordinates)
    // coordinates: [[lng, lat], [lng, lat], ...]
    
    LineStringNAPI* lineString = nullptr;
    
    try {
        if (args.Count() == 0) {
            // 创建空 LineString
            lineString = new LineStringNAPI();
        } else {
            napi_value coordsArray = args.GetArray(0, "coordinates");
            if (args.HasError()) return nullptr;
            
            auto points = NapiArrayToPointVector(env, coordsArray);
            lineString = new LineStringNAPI(points);
        }
        
        napi_status status = napi_wrap(env, args.This(), lineString, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete lineString;
            napi_throw_error(env, nullptr, "Failed to wrap LineString object");
            return nullptr;
        }
        
        return args.This();
    } catch (const std::exception& e) {
        if (lineString) delete lineString;
        Logger::error("LineStringNAPI", "Failed to create LineString: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

// 工厂方法：从 mbgl::LineString 创建 NAPI 实例
napi_value LineStringNAPI::New(napi_env env, const mbgl::LineString<double>& lineString) {
    if (constructor == nullptr) {
        Logger::error("LineStringNAPI", "LineString constructor not initialized");
        return nullptr;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("LineStringNAPI", "Failed to get LineString constructor");
        return nullptr;
    }
    
    // 创建坐标数组
    napi_value coordsArray = PointVectorToNapiArray(env, lineString);
    
    napi_value argv[1] = { coordsArray };
    napi_value instance;
    status = napi_new_instance(env, cons, 1, argv, &instance);
    if (status != napi_ok) {
        Logger::error("LineStringNAPI", "Failed to create LineString instance");
        return nullptr;
    }
    
    return instance;
}

napi_value LineStringNAPI::GetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    LineStringNAPI* lineString = nullptr;
    napi_status status = napi_unwrap(env, args.This(), reinterpret_cast<void**>(&lineString));
    
    if (status != napi_ok || !lineString) {
        napi_throw_error(env, nullptr, "Failed to unwrap LineString object");
        return nullptr;
    }
    
    return PointVectorToNapiArray(env, lineString->points_);
}

napi_value LineStringNAPI::SetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    LineStringNAPI* lineString = nullptr;
    napi_status status = napi_unwrap(env, args.This(), reinterpret_cast<void**>(&lineString));
    
    if (status != napi_ok || !lineString) {
        napi_throw_error(env, nullptr, "Failed to unwrap LineString object");
        return nullptr;
    }
    
    try {
        napi_value coordsArray = args.GetArray(0, "coordinates");
        if (args.HasError()) return nullptr;
        
        lineString->points_ = NapiArrayToPointVector(env, coordsArray);
        return args.Undefined();
    } catch (const std::exception& e) {
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value LineStringNAPI::AddPoint(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    LineStringNAPI* lineString = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lineString));
    
    if (status != napi_ok || !lineString) {
        napi_throw_error(env, nullptr, "Failed to unwrap LineString object");
        return nullptr;
    }
    
    double lng = args.GetDouble(0, "longitude");
    double lat = args.GetDouble(1, "latitude");
    if (args.HasError()) return nullptr;
    
    lineString->points_.push_back(mbgl::Point<double>(lng, lat));
    return jsThis;
}

napi_value LineStringNAPI::GetPointCount(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    LineStringNAPI* lineString = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lineString));
    
    if (status != napi_ok || !lineString) {
        napi_throw_error(env, nullptr, "Failed to unwrap LineString object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_uint32(env, lineString->points_.size(), &result);
    return result;
}

napi_value LineStringNAPI::ToJSON(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    LineStringNAPI* lineString = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lineString));
    
    if (status != napi_ok || !lineString) {
        napi_throw_error(env, nullptr, "Failed to unwrap LineString object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_object(env, &result);
    
    // type: "LineString"
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    // coordinates
    napi_value coordinates = PointVectorToNapiArray(env, lineString->points_);
    napi_set_named_property(env, result, "coordinates", coordinates);
    
    return result;
}

// 转换方法：从 NAPI 对象转换为 mbgl::LineString
mbgl::LineString<double> LineStringNAPI::convert(napi_env env, napi_value value) {
    // 首先尝试从 NAPI 类实例获取
    LineStringNAPI* lineString = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&lineString));
    
    if (status == napi_ok && lineString) {
        return lineString->toMbglLineString();
    }
    
    // 如果不是 NAPI 实例，尝试从普通对象解析
    if (!IsObject(env, value)) {
        throw std::runtime_error("LineString must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("LineString coordinates must be an array");
    }
    
    return NapiArrayToPointVector(env, coordinates);
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre
