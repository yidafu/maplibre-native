#pragma once

#include <napi/native_api.h>
#include <mbgl/style/expression/expression.hpp>
#include <mbgl/style/expression/value.hpp>
#include <memory>
#include <string>

namespace maplibre {
namespace harmony {

/**
 * ExpressionNAPI - NAPI wrapper for MapLibre Expression
 * 
 * This class wraps MapLibre's expression system and exposes it to ETS/TypeScript via NAPI.
 * It provides high-performance expression parsing, evaluation, and type checking.
 * 
 * Key features:
 * - Parse JSON expression arrays into compiled expression objects
 * - Evaluate expressions with feature data and zoom level
 * - Type checking and constant analysis
 * - Serialization back to JSON format
 * 
 * Based on Node.js implementation (platform/node/src/node_expression.hpp)
 */
class ExpressionNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Static method: parse JSON into Expression
    static napi_value Parse(napi_env env, napi_callback_info info);
    
    // Instance methods
    static napi_value Evaluate(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    static napi_value IsFeatureConstant(napi_env env, napi_callback_info info);
    static napi_value IsZoomConstant(napi_env env, napi_callback_info info);
    static napi_value Serialize(napi_env env, napi_callback_info info);
    
    // Internal access for C++ use
    std::unique_ptr<mbgl::style::expression::Expression>& getExpression() { return expression; }
    const std::unique_ptr<mbgl::style::expression::Expression>& getExpression() const { return expression; }
    
private:
    static napi_ref constructor;
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    explicit ExpressionNAPI(std::unique_ptr<mbgl::style::expression::Expression> expression);
    ~ExpressionNAPI();
    
    // The compiled expression object
    std::unique_ptr<mbgl::style::expression::Expression> expression;
};

/**
 * Helper function to convert mbgl::style::expression::Value to napi_value
 */
napi_value ValueToNapi(napi_env env, const mbgl::style::expression::Value& value);

/**
 * Helper function to convert napi_value to mbgl::Value for expression parsing
 */
mbgl::Value NapiToValue(napi_env env, napi_value value);

} // namespace harmony
} // namespace maplibre

