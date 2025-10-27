#include "multi_line_string_napi.hpp"
#include "util.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;
using namespace mbgl::harmony::napi;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_ref MultiLineStringNAPI::constructor = nullptr;

MultiLineStringNAPI::MultiLineStringNAPI() : lineStrings_() {}

MultiLineStringNAPI::MultiLineStringNAPI(const mbgl::MultiLineString<double>& multiLineString)
    : lineStrings_(multiLineString) {}

MultiLineStringNAPI::MultiLineStringNAPI(const std::vector<mbgl::LineString<double>>& lineStrings)
    : lineStrings_(lineStrings) {}

MultiLineStringNAPI::~MultiLineStringNAPI() {}

void MultiLineStringNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<MultiLineStringNAPI*>(nativeObject);
}

napi_value MultiLineStringNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("MultiLineStringNAPI", "Initializing MultiLineString NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getCoordinates", nullptr, GetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCoordinates", nullptr, SetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "toJSON", nullptr, ToJSON, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "MultiLineString", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("MultiLineStringNAPI", "Failed to define MultiLineString class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("MultiLineStringNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "MultiLineString", cons);
    if (status != napi_ok) {
        Logger::error("MultiLineStringNAPI", "Failed to set MultiLineString property");
        return nullptr;
    }
    
    Logger::info("MultiLineStringNAPI", "MultiLineString NAPI class initialized successfully");
    return exports;
}

napi_value MultiLineStringNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    MultiLineStringNAPI* multiLineString = nullptr;
    
    try {
        if (args.Count() == 0) {
            multiLineString = new MultiLineStringNAPI();
        } else {
            napi_value coordsArray = args.GetArray(0, "coordinates");
            if (args.HasError()) return nullptr;
            
            auto lineStrings = NapiArrayToLineStringVector(env, coordsArray);
            multiLineString = new MultiLineStringNAPI(lineStrings);
        }
        
        napi_status status = napi_wrap(env, jsThis, multiLineString, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete multiLineString;
            napi_throw_error(env, nullptr, "Failed to wrap MultiLineString object");
            return nullptr;
        }
        
        return jsThis;
    } catch (const std::exception& e) {
        if (multiLineString) delete multiLineString;
        Logger::error("MultiLineStringNAPI", "Failed to create MultiLineString: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

// 工厂方法：从 mbgl::MultiLineString 创建 NAPI 实例
napi_value MultiLineStringNAPI::New(napi_env env, const mbgl::MultiLineString<double>& multiLineString) {
    return FromMbglMultiLineString(env, multiLineString);
}

napi_value MultiLineStringNAPI::GetCoordinates(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    MultiLineStringNAPI* multiLineString = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&multiLineString));
    
    if (status != napi_ok || !multiLineString) {
        napi_throw_error(env, nullptr, "Failed to unwrap MultiLineString object");
        return nullptr;
    }
    
    return LineStringVectorToNapiArray(env, multiLineString->lineStrings_);
}

napi_value MultiLineStringNAPI::SetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    MultiLineStringNAPI* multiLineString = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&multiLineString));
    
    if (status != napi_ok || !multiLineString) {
        napi_throw_error(env, nullptr, "Failed to unwrap MultiLineString object");
        return nullptr;
    }
    
    try {
        napi_value coordsArray = args.GetArray(0, "coordinates");
        if (args.HasError()) return nullptr;
        
        multiLineString->lineStrings_ = NapiArrayToLineStringVector(env, coordsArray);
        return jsThis;
    } catch (const std::exception& e) {
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value MultiLineStringNAPI::ToJSON(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    MultiLineStringNAPI* multiLineString = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&multiLineString));
    
    if (status != napi_ok || !multiLineString) {
        napi_throw_error(env, nullptr, "Failed to unwrap MultiLineString object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    napi_value coordinates = LineStringVectorToNapiArray(env, multiLineString->lineStrings_);
    napi_set_named_property(env, result, "coordinates", coordinates);
    
    return result;
}

napi_value MultiLineStringNAPI::FromMbglMultiLineString(napi_env env, const mbgl::MultiLineString<double>& multiLineString) {
    if (constructor == nullptr) {
        Logger::error("MultiLineStringNAPI", "MultiLineString constructor not initialized");
        return nullptr;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("MultiLineStringNAPI", "Failed to get MultiLineString constructor");
        return nullptr;
    }
    
    napi_value coordsArray = LineStringVectorToNapiArray(env, multiLineString);
    napi_value argv[1] = { coordsArray };
    napi_value instance;
    status = napi_new_instance(env, cons, 1, argv, &instance);
    if (status != napi_ok) {
        Logger::error("MultiLineStringNAPI", "Failed to create MultiLineString instance");
        return nullptr;
    }
    
    return instance;
}

mbgl::MultiLineString<double> MultiLineStringNAPI::convert(napi_env env, napi_value value) {
    // 首先尝试从 NAPI 类实例获取
    MultiLineStringNAPI* multiLineString = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&multiLineString));
    
    if (status == napi_ok && multiLineString) {
        return multiLineString->toMbglMultiLineString();
    }
    
    // 如果不是 NAPI 实例，尝试从普通对象解析
    if (!IsObject(env, value)) {
        throw std::runtime_error("MultiLineString must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("MultiLineString coordinates must be an array");
    }
    
    return NapiArrayToLineStringVector(env, coordinates);
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre
