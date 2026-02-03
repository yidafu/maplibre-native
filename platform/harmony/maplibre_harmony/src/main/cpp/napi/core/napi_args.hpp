//
// Created for N-API parameter parsing utility
//

#ifndef MAPLIBREHARMONY_NAPI_ARGS_HPP
#define MAPLIBREHARMONY_NAPI_ARGS_HPP

#include <napi/native_api.h>
#include <string>
#include <vector>
#include <optional>

namespace mbgl {
namespace harmony {
namespace napi {

/**
 * NapiArgs - N-API argument parsing utility.
 *
 * Simplifies N-API parameter handling, offering type-safe accessors and automatic error propagation.
 *
 * Usage example:
 * ```cpp
 * napi_value MyFunction(napi_env env, napi_callback_info info) {
 *     NapiArgs args(env, info);
 *     args.RequireMinArgs(2);
 *     if (args.HasError()) return nullptr;
 *     
 *     std::string name = args.GetString(0, "name");
 *     int64_t value = args.GetInt64(1, "value");
 *     if (args.HasError()) return nullptr;
 *     
 *     // ... consume parameters
 * }
 * ```
 */
class NapiArgs {
public:
    /**
     * Constructor - automatically parses the N-API callback info.
     * @param env N-API environment
     * @param info N-API callback info
     * @param maxArgs Maximum number of parameters (default 16)
     */
    explicit NapiArgs(napi_env env, napi_callback_info info, size_t maxArgs = 16);
    
    // Disable copying
    NapiArgs(const NapiArgs&) = delete;
    NapiArgs& operator=(const NapiArgs&) = delete;
    
    // ========== Argument count and validation ==========
    
    /**
     * Retrieve the number of arguments actually passed.
     */
    size_t Count() const { return argc_; }
    
    /**
     * Check whether an argument exists at the given index.
     */
    bool Has(size_t index) const { return index < argc_; }
    
    /**
     * Enforce a minimum argument count.
     * Sets an error and throws a JS exception if insufficient.
     */
    void RequireMinArgs(size_t min);
    
    /**
     * Verify the argument type.
     */
    bool IsType(size_t index, napi_valuetype type);
    
    // ========== Error handling ==========
    
    /**
     * Determine whether an error has occurred.
     */
    bool HasError() const { return hasError_; }
    
    /**
     * Retrieve the error message.
     */
    std::string GetError() const { return errorMessage_; }
    
    /**
     * Access the N-API environment.
     */
    napi_env Env() const { return env_; }
    
    /**
     * Convenience: return undefined.
     */
    napi_value Undefined() const;
    
    /**
     * Convenience: return null.
     */
    napi_value Null() const;
    
    /**
     * Retrieve the `this` object.
     */
    napi_value This() const;
    
    /**
     * Alias for GetValue.
     */
    napi_value Get(size_t index) { return GetValue(index); }
    
    /**
     * Check whether the argument is null or undefined.
     */
    bool IsNullOrUndefined(size_t index);
    
    // ========== Primitive accessors ==========
    
    /**
     * Retrieve a string argument.
     * @param index Argument index
     * @param name Optional label used in error reporting
     * @return String value; returns empty string and sets an error on failure
     */
    std::string GetString(size_t index, const char* name = nullptr);
    
    /**
     * Retrieve an int32 argument.
     */
    int32_t GetInt32(size_t index, const char* name = nullptr);
    
    /**
     * Retrieve an int64 argument.
     */
    int64_t GetInt64(size_t index, const char* name = nullptr);
    
    /**
     * Retrieve a uint32 argument.
     */
    uint32_t GetUint32(size_t index, const char* name = nullptr);
    
    /**
     * Retrieve a double argument.
     */
    double GetDouble(size_t index, const char* name = nullptr);
    
    /**
     * Retrieve a bool argument.
     */
    bool GetBool(size_t index, const char* name = nullptr);
    
    /**
     * Retrieve a BigInt (int64) argument.
     * Primarily used for cases like surface IDs that require BigInt.
     */
    int64_t GetBigInt(size_t index, const char* name = nullptr);
    
    // ========== Complex type accessors ==========
    
    /**
     * Retrieve an object argument.
     * @param index Argument index
     * @param name Optional label for error reporting
     * @return napi_value object; returns nullptr and sets an error on failure
     */
    napi_value GetObject(size_t index, const char* name = nullptr);
    
    /**
     * Retrieve an array argument.
     */
    napi_value GetArray(size_t index, const char* name = nullptr);
    
    /**
     * Retrieve a function argument.
     */
    napi_value GetFunction(size_t index, const char* name = nullptr);
    
    /**
     * Retrieve a Buffer argument.
     * @param index Argument index
     * @param length Output length of the buffer
     * @param name Optional label for error reporting
     * @return Pointer to buffer data; returns nullptr and sets an error on failure
     */
    void* GetBuffer(size_t index, size_t* length, const char* name = nullptr);
    
    /**
     * Retrieve the raw napi_value, for cases requiring direct manipulation.
     */
    napi_value GetValue(size_t index);
    
    // ========== Optional parameters with defaults ==========
    
    /**
     * Retrieve an optional string argument.
     * Returns the default value when missing or type-mismatched.
     */
    std::string GetStringOr(size_t index, const std::string& defaultValue);
    
    /**
     * Retrieve an optional int32 argument.
     */
    int32_t GetInt32Or(size_t index, int32_t defaultValue);
    
    /**
     * Retrieve an optional int64 argument.
     */
    int64_t GetInt64Or(size_t index, int64_t defaultValue);
    
    /**
     * Retrieve an optional uint32 argument.
     */
    uint32_t GetUint32Or(size_t index, uint32_t defaultValue);
    
    /**
     * Retrieve an optional double argument.
     */
    double GetDoubleOr(size_t index, double defaultValue);
    
    /**
     * Retrieve an optional bool argument.
     */
    bool GetBoolOr(size_t index, bool defaultValue);
    
    // ========== Object property helpers ==========
    
    /**
     * Read a string property from an object.
     * @param obj Source object
     * @param key Property name
     * @param defaultValue Value to return when missing
     */
    std::string GetStringProperty(napi_value obj, const char* key, const std::string& defaultValue = "");
    
    /**
     * Read an int32 property from an object.
     */
    int32_t GetInt32Property(napi_value obj, const char* key, int32_t defaultValue = 0);
    
    /**
     * Read an int64 property from an object.
     */
    int64_t GetInt64Property(napi_value obj, const char* key, int64_t defaultValue = 0);
    
    /**
     * Read a uint32 property from an object.
     */
    uint32_t GetUint32Property(napi_value obj, const char* key, uint32_t defaultValue = 0);
    
    /**
     * Read a double property from an object.
     */
    double GetDoubleProperty(napi_value obj, const char* key, double defaultValue = 0.0);
    
    /**
     * Read a bool property from an object.
     */
    bool GetBoolProperty(napi_value obj, const char* key, bool defaultValue = false);

    // ========== Array helper methods ==========

    /**
     * Get the length of an array.
     * @param array The array value
     * @return Array length, or 0 on failure
     */
    uint32_t GetArrayLength(napi_value array);

    /**
     * Get a string element from an array.
     * @param array The array value
     * @param index Element index
     * @param defaultValue Value to return on failure
     */
    std::string GetArrayElementString(napi_value array, uint32_t index, const std::string& defaultValue = "");

    /**
     * Get an int32 element from an array.
     * @param array The array value
     * @param index Element index
     * @param defaultValue Value to return on failure
     */
    int32_t GetArrayElementInt32(napi_value array, uint32_t index, int32_t defaultValue = 0);

    /**
     * Get a double element from an array.
     * @param array The array value
     * @param index Element index
     * @param defaultValue Value to return on failure
     */
    double GetArrayElementDouble(napi_value array, uint32_t index, double defaultValue = 0.0);

    /**
     * Get a bool element from an array.
     * @param array The array value
     * @param index Element index
     * @param defaultValue Value to return on failure
     */
    bool GetArrayElementBool(napi_value array, uint32_t index, bool defaultValue = false);

private:
    napi_env env_;
    napi_value thisObj_;  // Stores the `this` object
    size_t argc_;
    std::vector<napi_value> args_;
    bool hasError_;
    std::string errorMessage_;
    
    /**
     * Set an error message and throw a JS exception.
     */
    void SetError(const std::string& message);
    
    /**
     * Validate that the argument index is within range.
     */
    bool CheckIndex(size_t index, const char* name = nullptr);
    
    /**
     * Generate a parameter label for error messages.
     */
    std::string GetParamName(size_t index, const char* name) const;
};

} // namespace napi
} // namespace harmony
} // namespace mbgl

#endif // MAPLIBREHARMONY_NAPI_ARGS_HPP

