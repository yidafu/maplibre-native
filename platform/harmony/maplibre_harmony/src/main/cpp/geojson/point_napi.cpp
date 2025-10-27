#include "point_napi.hpp"
#include "util.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;
using namespace mbgl::harmony::napi;

namespace maplibre {
namespace harmony {
namespace geojson {

// Static member initialization
napi_ref PointNAPI::constructor = nullptr;

PointNAPI::PointNAPI(double lng, double lat, double altitude, bool hasAltitude)
    : lng_(lng), lat_(lat), altitude_(altitude), hasAltitude_(hasAltitude) {
}

PointNAPI::PointNAPI(const mbgl::Point<double>& point)
    : lng_(point.x), lat_(point.y), altitude_(0.0), hasAltitude_(false) {
}

PointNAPI::~PointNAPI() {
}

void PointNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    PointNAPI* point = static_cast<PointNAPI*>(nativeObject);
    delete point;
}

napi_value PointNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("PointNAPI", "Initializing Point NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getCoordinates", nullptr, GetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCoordinates", nullptr, SetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLongitude", nullptr, GetLongitude, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLatitude", nullptr, GetLatitude, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getAltitude", nullptr, GetAltitude, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLongitude", nullptr, SetLongitude, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLatitude", nullptr, SetLatitude, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setAltitude", nullptr, SetAltitude, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "toJSON", nullptr, ToJSON, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Point", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("PointNAPI", "Failed to define Point class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("PointNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Point", cons);
    if (status != napi_ok) {
        Logger::error("PointNAPI", "Failed to set Point property");
        return nullptr;
    }
    
    Logger::info("PointNAPI", "Point NAPI class initialized successfully");
    return exports;
}

napi_value PointNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    // Point 构造函数支持多种形式:
    // new Point(lng, lat)
    // new Point(lng, lat, altitude)
    // new Point([lng, lat])
    // new Point([lng, lat, altitude])
    
    PointNAPI* point = nullptr;
    
    try {
        if (args.Count() == 0) {
            napi_throw_error(env, nullptr, "Point requires at least 1 argument");
            return nullptr;
        }
        
        // 如果第一个参数是数组
        if (args.IsType(0, napi_object)) {
            bool isArray = false;
            napi_is_array(env, args.GetValue(0), &isArray);
            
            if (isArray) {
                // Point([lng, lat]) 或 Point([lng, lat, altitude])
                napi_value coordsArray = args.GetArray(0, "coordinates");
                if (args.HasError()) return nullptr;
                
                auto coords = NapiArrayToDoubleVector(env, coordsArray);
                
                if (coords.size() < 2) {
                    napi_throw_error(env, nullptr, "Point coordinates must have at least 2 elements [lng, lat]");
                    return nullptr;
                }
                
                if (coords.size() >= 3) {
                    point = new PointNAPI(coords[0], coords[1], coords[2], true);
                } else {
                    point = new PointNAPI(coords[0], coords[1]);
                }
            } else {
                napi_throw_error(env, nullptr, "Point constructor expects array or numbers");
                return nullptr;
            }
        } else if (args.IsType(0, napi_number)) {
            // Point(lng, lat) 或 Point(lng, lat, altitude)
            args.RequireMinArgs(2);
            if (args.HasError()) return nullptr;
            
            double lng = args.GetDouble(0, "longitude");
            double lat = args.GetDouble(1, "latitude");
            if (args.HasError()) return nullptr;
            
            if (args.Count() >= 3) {
                double altitude = args.GetDouble(2, "altitude");
                if (args.HasError()) return nullptr;
                point = new PointNAPI(lng, lat, altitude, true);
            } else {
                point = new PointNAPI(lng, lat);
            }
        } else {
            napi_throw_error(env, nullptr, "Point constructor expects array or numbers");
            return nullptr;
        }
        
        napi_status status = napi_wrap(env, jsThis, point, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete point;
            napi_throw_error(env, nullptr, "Failed to wrap Point object");
            return nullptr;
        }
        
        return jsThis;
    } catch (const std::exception& e) {
        if (point) delete point;
        Logger::error("PointNAPI", "Failed to create Point: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

// 工厂方法：从 mbgl::Point 创建 NAPI 实例
napi_value PointNAPI::New(napi_env env, const mbgl::Point<double>& point) {
    if (constructor == nullptr) {
        Logger::error("PointNAPI", "Point constructor not initialized");
        return nullptr;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("PointNAPI", "Failed to get Point constructor");
        return nullptr;
    }
    
    // 创建参数数组 [lng, lat]
    napi_value argv[2];
    napi_create_double(env, point.x, &argv[0]);
    napi_create_double(env, point.y, &argv[1]);
    
    napi_value instance;
    status = napi_new_instance(env, cons, 2, argv, &instance);
    if (status != napi_ok) {
        Logger::error("PointNAPI", "Failed to create Point instance");
        return nullptr;
    }
    
    return instance;
}

napi_value PointNAPI::GetCoordinates(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&point));
    
    if (status != napi_ok || !point) {
        napi_throw_error(env, nullptr, "Failed to unwrap Point object");
        return nullptr;
    }
    
    napi_value result;
    if (point->hasAltitude_) {
        napi_create_array_with_length(env, 3, &result);
        napi_value lng, lat, alt;
        napi_create_double(env, point->lng_, &lng);
        napi_create_double(env, point->lat_, &lat);
        napi_create_double(env, point->altitude_, &alt);
        napi_set_element(env, result, 0, lng);
        napi_set_element(env, result, 1, lat);
        napi_set_element(env, result, 2, alt);
    } else {
        napi_create_array_with_length(env, 2, &result);
        napi_value lng, lat;
        napi_create_double(env, point->lng_, &lng);
        napi_create_double(env, point->lat_, &lat);
        napi_set_element(env, result, 0, lng);
        napi_set_element(env, result, 1, lat);
    }
    
    return result;
}

napi_value PointNAPI::SetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&point));
    
    if (status != napi_ok || !point) {
        napi_throw_error(env, nullptr, "Failed to unwrap Point object");
        return nullptr;
    }
    
    try {
        napi_value coordsArray = args.GetArray(0, "coordinates");
        if (args.HasError()) return nullptr;
        
        auto coords = NapiArrayToDoubleVector(env, coordsArray);
        
        if (coords.size() < 2) {
            napi_throw_error(env, nullptr, "Point coordinates must have at least 2 elements [lng, lat]");
            return nullptr;
        }
        
        point->lng_ = coords[0];
        point->lat_ = coords[1];
        
        if (coords.size() >= 3) {
            point->altitude_ = coords[2];
            point->hasAltitude_ = true;
        } else {
            point->altitude_ = 0.0;
            point->hasAltitude_ = false;
        }
        
        return jsThis;
    } catch (const std::exception& e) {
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value PointNAPI::GetLongitude(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&point));
    
    if (status != napi_ok || !point) {
        napi_throw_error(env, nullptr, "Failed to unwrap Point object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_double(env, point->lng_, &result);
    return result;
}

napi_value PointNAPI::GetLatitude(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&point));
    
    if (status != napi_ok || !point) {
        napi_throw_error(env, nullptr, "Failed to unwrap Point object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_double(env, point->lat_, &result);
    return result;
}

napi_value PointNAPI::GetAltitude(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&point));
    
    if (status != napi_ok || !point) {
        napi_throw_error(env, nullptr, "Failed to unwrap Point object");
        return nullptr;
    }
    
    if (!point->hasAltitude_) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value result;
    napi_create_double(env, point->altitude_, &result);
    return result;
}

napi_value PointNAPI::SetLongitude(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&point));
    
    if (status != napi_ok || !point) {
        napi_throw_error(env, nullptr, "Failed to unwrap Point object");
        return nullptr;
    }
    
    double lng = args.GetDouble(0, "longitude");
    if (args.HasError()) return nullptr;
    
    point->lng_ = lng;
    return jsThis;
}

napi_value PointNAPI::SetLatitude(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&point));
    
    if (status != napi_ok || !point) {
        napi_throw_error(env, nullptr, "Failed to unwrap Point object");
        return nullptr;
    }
    
    double lat = args.GetDouble(0, "latitude");
    if (args.HasError()) return nullptr;
    
    point->lat_ = lat;
    return jsThis;
}

napi_value PointNAPI::SetAltitude(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&point));
    
    if (status != napi_ok || !point) {
        napi_throw_error(env, nullptr, "Failed to unwrap Point object");
        return nullptr;
    }
    
    double altitude = args.GetDouble(0, "altitude");
    if (args.HasError()) return nullptr;
    
    point->altitude_ = altitude;
    point->hasAltitude_ = true;
    return jsThis;
}

napi_value PointNAPI::ToJSON(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&point));
    
    if (status != napi_ok || !point) {
        napi_throw_error(env, nullptr, "Failed to unwrap Point object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_object(env, &result);
    
    // type: "Point"
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    // coordinates
    napi_value coordinates;
    if (point->hasAltitude_) {
        napi_create_array_with_length(env, 3, &coordinates);
        napi_value lng, lat, alt;
        napi_create_double(env, point->lng_, &lng);
        napi_create_double(env, point->lat_, &lat);
        napi_create_double(env, point->altitude_, &alt);
        napi_set_element(env, coordinates, 0, lng);
        napi_set_element(env, coordinates, 1, lat);
        napi_set_element(env, coordinates, 2, alt);
    } else {
        napi_create_array_with_length(env, 2, &coordinates);
        napi_value lng, lat;
        napi_create_double(env, point->lng_, &lng);
        napi_create_double(env, point->lat_, &lat);
        napi_set_element(env, coordinates, 0, lng);
        napi_set_element(env, coordinates, 1, lat);
    }
    napi_set_named_property(env, result, "coordinates", coordinates);
    
    return result;
}

// 转换方法：从 NAPI 对象转换为 mbgl::Point
mbgl::Point<double> PointNAPI::convert(napi_env env, napi_value value) {
    // 首先尝试从 NAPI 类实例获取
    PointNAPI* point = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&point));
    
    if (status == napi_ok && point) {
        return point->toMbglPoint();
    }
    
    // 如果不是 NAPI 实例，尝试从普通对象解析
    if (!IsObject(env, value)) {
        throw std::runtime_error("Point must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("Point coordinates must be an array");
    }
    
    auto coords = NapiArrayToDoubleVector(env, coordinates);
    
    if (coords.size() < 2) {
        throw std::runtime_error("Point coordinates must have at least 2 elements [lng, lat]");
    }
    
    return mbgl::Point<double>{coords[0], coords[1]};
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre
