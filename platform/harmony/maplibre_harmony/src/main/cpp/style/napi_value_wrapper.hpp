#pragma once

#include <napi/native_api.h>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * NapiValue - Wrapper class for NAPI values
 * 
 * Provides a convenient interface for type checking and value extraction
 * from Node-API (NAPI) values. This class is designed to work with the
 * MapLibre conversion system.
 * 
 * Note: To fit in Convertible's storage, we store env in a thread_local variable
 * and only keep the napi_value itself.
 */
class NapiValue {
public:
    /**
     * Construct a NapiValue wrapper
     * @param env NAPI environment
     * @param value NAPI value to wrap
     */
    NapiValue(napi_env env, napi_value value);
    
    // Move semantics
    NapiValue(NapiValue&&) = default;
    NapiValue& operator=(NapiValue&&) = default;
    
    // Copy is allowed for Convertible
    NapiValue(const NapiValue&) = default;
    NapiValue& operator=(const NapiValue&) = default;
    
    // Type checking methods
    bool isNull() const;
    bool isUndefined() const;
    bool isArray() const;
    bool isObject() const;
    bool isString() const;
    bool isBool() const;
    bool isNumber() const;
    
    // Value extraction methods
    std::string toString() const;
    float toFloat() const;
    double toDouble() const;
    int64_t toLong() const;
    bool toBool() const;
    
    // Object/Array access methods
    NapiValue get(const char* key) const;
    NapiValue get(size_t index) const;
    NapiValue keyArray() const;
    size_t getLength() const;
    
    // Direct access to underlying NAPI types
    napi_env getEnv() const;
    napi_value getValue() const { return value; }
    
    // Set the thread-local environment
    static void setThreadLocalEnv(napi_env env);
    
private:
    napi_value value;
    
    // Thread-local storage for napi_env
    static thread_local napi_env tl_env;
};

} // namespace harmony
} // namespace mbgl

