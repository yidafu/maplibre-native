//
// 注解类 NAPI 访问器的共享骨架（宏 + 内联工具函数）
//
// 背景：Marker / Polygon / Polyline 的每个 Get*/Set* 都重复了同一套样板：
//   1. napi_get_cb_info 取 this
//   2. napi_unwrap 解包原生对象 + 空检查
//   3. 从 argv 或成员里取值 / 写值
// 三份文件里这类样板合计近千行，且彼此只差「成员名 + 取值函数」。
//
// 本头文件把这些骨架固化成宏，把取值差异交给内联的 Js* 构造器与
// NapiScalarTraits（napi_args 侧）描述。宏体展开后与手工代码逐字等价，
// 包括失败分支的返回值（getter 失败返回 nullptr，setter 失败返回 thisVar —
// 这是既有对外行为，ArkTS 侧依赖它判断 undefined）。
//
// 用法示例：
//   DEFINE_ANNOTATION_GETTER(PolygonNAPI, GetFillColor, JsHexColor(env, self->fillColor))
//   DEFINE_ANNOTATION_SETTER(PolygonNAPI, SetZIndex,
//       args.RequireMinArgs(1);
//       self->zIndex = args.GetInt32(0))
//

#ifndef MAPLIBREHARMONY_ANNOTATION_NAPI_ACCESSORS_HPP
#define MAPLIBREHARMONY_ANNOTATION_NAPI_ACCESSORS_HPP

#include <napi/native_api.h>
#include <string>

#include "geometry/lat_lng_harmony.hpp"
#include "napi/bindings/annotation_napi_common.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {
namespace annotation_napi {

// ============================================================================
// JS 值构造器
//
// 统一初始化返回值：napi_create_* / napi_get_* 失败时返回 nullptr，
// 而不是把未初始化的 napi_value 交回运行时（原实现存在读取未初始化
// 栈内存的风险）。成功路径与重构前逐字等价。
// ============================================================================

inline napi_value JsNumber(napi_env env, double value) {
    napi_value result = nullptr;
    napi_create_double(env, value, &result);
    return result;
}

inline napi_value JsInt32(napi_env env, int32_t value) {
    napi_value result = nullptr;
    napi_create_int32(env, value, &result);
    return result;
}

inline napi_value JsInt64(napi_env env, int64_t value) {
    napi_value result = nullptr;
    napi_create_int64(env, value, &result);
    return result;
}

inline napi_value JsBool(napi_env env, bool value) {
    napi_value result = nullptr;
    napi_get_boolean(env, value, &result);
    return result;
}

inline napi_value JsString(napi_env env, const std::string& value) {
    napi_value result = nullptr;
    napi_create_string_utf8(env, value.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

/** 颜色统一按 "#RRGGBB" 字符串暴露给 ArkTS 侧。 */
inline napi_value JsHexColor(napi_env env, const mbgl::Color& color) {
    return JsString(env, ColorToHex(color));
}

inline napi_value JsUndefined(napi_env env) {
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}

inline napi_value JsNull(napi_env env) {
    napi_value result = nullptr;
    napi_get_null(env, &result);
    return result;
}

} // namespace annotation_napi
} // namespace harmony
} // namespace mbgl

// ============================================================================
// 宏：把 this 解包成原生对象指针
//
// 展开后声明 thisVar（napi_value）与指定名字的原生指针；unwrap 失败时为
// nullptr —— 调用方必须立刻做空检查。
// ============================================================================
#define ANN_NAPI_THIS(Type, SelfName)                                            \
    napi_value thisVar = nullptr;                                                \
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);            \
    Type* SelfName = NapiArgs::Unwrap<Type>(env, thisVar)

/**
 * 只读访问器：解包失败返回 nullptr（保持既有语义）。
 *
 * @param Cls       NAPI 类
 * @param Fn        要定义的方法名
 * @param ValueExpr 返回 napi_value 的表达式，可用 env 与 self
 */
#define DEFINE_ANNOTATION_GETTER(Cls, Fn, ValueExpr)                             \
    napi_value Cls::Fn(napi_env env, napi_callback_info info) {                  \
        ANN_NAPI_THIS(Cls, self);                                                \
        if (!self) return nullptr;                                               \
        return (ValueExpr);                                                      \
    }

/**
 * 写访问器通用骨架：解包失败返回 thisVar（保持既有语义，支持链式调用）。
 *
 * @param Cls  NAPI 类
 * @param Fn   要定义的方法名
 * @param ...  方法体语句（可用 env / info / thisVar / args / self 及
 *             annotation_napi 命名空间的工具函数）
 */
#define DEFINE_ANNOTATION_SETTER(Cls, Fn, ...)                                   \
    napi_value Cls::Fn(napi_env env, napi_callback_info info) {                  \
        NapiArgs args(env, info);                                                \
        ANN_NAPI_THIS(Cls, self);                                                \
        if (!self) return thisVar;                                               \
        __VA_ARGS__;                                                             \
        return thisVar;                                                          \
    }

/**
 * "#RRGGBB" 颜色写访问器（ParseHexColor + 失败日志，行为与手写版一致）。
 *
 * @param Member  原生颜色成员名
 * @param PropKey NAPI 参数名，同时用于错误文案
 */
#define DEFINE_ANNOTATION_COLOR_SETTER(Cls, Fn, Member, PropKey)                 \
    DEFINE_ANNOTATION_SETTER(Cls, Fn,                                            \
        args.RequireMinArgs(1);                                                  \
        const std::string colorStr = args.GetString(0, PropKey);                 \
        if (!colorStr.empty() && colorStr[0] == '#') {                           \
            if (!ParseHexColor(colorStr, self->Member)) {                        \
                mbgl::harmony::Logger::error(#Cls, "Failed to parse " PropKey    \
                                             ": %s", colorStr.c_str());          \
            }                                                                    \
        })

/**
 * 顶点数组写访问器：把 JS 的 [{latitude, longitude}] 转成内部点向量。
 *
 * @param Member 原生点向量成员名
 */
#define DEFINE_ANNOTATION_POINTS_SETTER(Cls, Fn, Member)                         \
    DEFINE_ANNOTATION_SETTER(Cls, Fn,                                            \
        args.RequireMinArgs(1);                                                  \
        napi_value pointsValue = args.Get(0);                                    \
        bool isArray = false;                                                    \
        napi_is_array(env, pointsValue, &isArray);                               \
        if (isArray) {                                                           \
            self->Member = ParseLatLngArrayToPoints(env, pointsValue);           \
        })

/**
 * addPoint(point)：追加一个顶点，返回 undefined。
 */
#define DEFINE_ANNOTATION_ADD_POINT(Cls, Member)                                 \
    napi_value Cls::AddPoint(napi_env env, napi_callback_info info) {            \
        NapiArgs args(env, info);                                                \
        args.RequireMinArgs(1);                                                  \
        ANN_NAPI_THIS(Cls, self);                                                \
        if (!self) {                                                             \
            return mbgl::harmony::annotation_napi::JsUndefined(env);             \
        }                                                                        \
        napi_value pointValue = args.GetObject(0, "point");                      \
        if (!args.HasError()) {                                                  \
            mbgl::Point<double> point;                                           \
            if (ParseLatLngToPoint(env, pointValue, point)) {                    \
                self->Member.push_back(point);                                   \
            }                                                                    \
        }                                                                        \
        return mbgl::harmony::annotation_napi::JsUndefined(env);                 \
    }

/**
 * insertPoint(index, point)：在指定位置插入顶点，越界则静默忽略，返回 undefined。
 */
#define DEFINE_ANNOTATION_INSERT_POINT(Cls, Member)                              \
    napi_value Cls::InsertPoint(napi_env env, napi_callback_info info) {         \
        NapiArgs args(env, info);                                                \
        args.RequireMinArgs(2);                                                  \
        ANN_NAPI_THIS(Cls, self);                                                \
        if (!self) {                                                             \
            return mbgl::harmony::annotation_napi::JsUndefined(env);             \
        }                                                                        \
        const int32_t index = args.GetInt32(0);                                  \
        napi_value pointValue = args.GetObject(1, "point");                      \
        if (!args.HasError() && index >= 0 &&                                    \
            static_cast<size_t>(index) <= self->Member.size()) {                 \
            mbgl::Point<double> point;                                           \
            if (ParseLatLngToPoint(env, pointValue, point)) {                    \
                self->Member.insert(self->Member.begin() + index, point);         \
            }                                                                    \
        }                                                                        \
        return mbgl::harmony::annotation_napi::JsUndefined(env);                 \
    }

/**
 * removePoint(index)：删除顶点并返回被删顶点；越界返回 null。
 *
 * 注意：必须先按值拷贝出被删顶点再 erase，否则 erase 之后索引失效。
 */
#define DEFINE_ANNOTATION_REMOVE_POINT(Cls, Member)                              \
    napi_value Cls::RemovePoint(napi_env env, napi_callback_info info) {         \
        NapiArgs args(env, info);                                                \
        args.RequireMinArgs(1);                                                  \
        ANN_NAPI_THIS(Cls, self);                                                \
        if (!self) {                                                             \
            return mbgl::harmony::annotation_napi::JsNull(env);                  \
        }                                                                        \
        const int32_t index = args.GetInt32(0);                                  \
        if (index >= 0 && static_cast<size_t>(index) < self->Member.size()) {     \
            const auto removedPoint = self->Member[index];                       \
            self->Member.erase(self->Member.begin() + index);                     \
            return LatLngHarmony::CreateLatLngObject(                            \
                env, mbgl::LatLng(removedPoint.y, removedPoint.x));              \
        }                                                                        \
        return mbgl::harmony::annotation_napi::JsNull(env);                      \
    }

/**
 * setMapLibreMap(map)：持有 ArkTS 侧 map 对象的引用，重复设置会先释放旧引用。
 */
#define DEFINE_ANNOTATION_MAP_REF_SETTER(Cls, Fn)                                \
    DEFINE_ANNOTATION_SETTER(Cls, Fn,                                            \
        if (self->mapLibreMapRef) {                                              \
            napi_delete_reference(env, self->mapLibreMapRef);                    \
            self->mapLibreMapRef = nullptr;                                      \
        }                                                                        \
        if (args.Count() > 0) {                                                  \
            napi_create_reference(env, args.Get(0), 1, &self->mapLibreMapRef);   \
        })

#endif // MAPLIBREHARMONY_ANNOTATION_NAPI_ACCESSORS_HPP
