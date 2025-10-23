# NapiArgs 工具类使用指南

## 概述

`NapiArgs` 是一个用于简化 N-API 参数解析的工具类，提供类型安全的参数访问和自动错误处理。使用此工具类可以大幅减少样板代码，提高代码可读性和可维护性。

## 基本用法

### 1. 引入头文件

```cpp
#include "napi_args.hpp"
```

### 2. 创建 NapiArgs 实例

在 N-API 函数中，使用 `env` 和 `info` 创建 `NapiArgs` 实例：

```cpp
napi_value MyFunction(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // 检查参数数量
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr; // 或返回适当的错误值
    }
    
    // 获取参数
    std::string name = args.GetString(0, "name");
    int64_t value = args.GetInt64(1, "value");
    if (args.HasError()) {
        return nullptr;
    }
    
    // 使用参数进行处理
    // ...
}
```

## 支持的参数类型

### 基础类型

#### 字符串 (String)
```cpp
std::string text = args.GetString(0, "text");
// 可选参数，带默认值
std::string optionalText = args.GetStringOr(1, "default value");
```

#### 整数 (Int32/Int64/Uint32)
```cpp
int32_t count = args.GetInt32(0, "count");
int64_t id = args.GetInt64(0, "id");
uint32_t unsigned_value = args.GetUint32(0, "value");

// 可选参数
int64_t optionalId = args.GetInt64Or(1, 0);
```

#### 浮点数 (Double)
```cpp
double opacity = args.GetDouble(0, "opacity");
// 可选参数
double optionalOpacity = args.GetDoubleOr(1, 1.0);
```

#### 布尔值 (Boolean)
```cpp
bool enabled = args.GetBool(0, "enabled");
// 可选参数
bool optionalFlag = args.GetBoolOr(1, false);
```

#### BigInt
```cpp
// 用于 Surface ID 等需要 BigInt 的场景
int64_t surfaceId = args.GetBigInt(0, "surfaceId");
```

### 复杂类型

#### 对象 (Object)
```cpp
napi_value obj = args.GetObject(0, "options");
if (!args.HasError() && obj) {
    // 从对象中获取属性
    std::string name = args.GetStringProperty(obj, "name", "default");
    int64_t value = args.GetInt64Property(obj, "value", 0);
    double ratio = args.GetDoubleProperty(obj, "ratio", 1.0);
    bool flag = args.GetBoolProperty(obj, "flag", false);
}
```

#### 数组 (Array)
```cpp
napi_value arr = args.GetArray(0, "items");
if (!args.HasError() && arr) {
    // 获取数组长度
    uint32_t length;
    napi_get_array_length(env, arr, &length);
    
    // 遍历数组元素
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, arr, i, &element);
        // 处理元素
    }
}
```

#### 函数 (Function)
```cpp
napi_value callback = args.GetFunction(0, "callback");
if (!args.HasError() && callback) {
    // 调用回调函数
    napi_value result;
    napi_call_function(env, nullptr, callback, 0, nullptr, &result);
}
```

#### Buffer
```cpp
size_t bufferLength;
void* bufferData = args.GetBuffer(0, &bufferLength, "data");
if (!args.HasError() && bufferData) {
    // 使用 buffer 数据
    // bufferData 指向 buffer 内容
    // bufferLength 是 buffer 的长度
}
```

## 参数检查和验证

### 检查参数数量
```cpp
args.RequireMinArgs(3); // 要求至少 3 个参数
if (args.HasError()) {
    // 参数不足，错误已自动抛出到 JS 侧
    return nullptr;
}
```

### 检查参数是否存在
```cpp
if (args.Has(2)) {
    // 第3个参数存在
    std::string optional = args.GetString(2, "optional");
}
```

### 检查参数类型
```cpp
if (args.IsType(0, napi_string)) {
    std::string text = args.GetString(0, "text");
}
```

### 获取参数总数
```cpp
size_t count = args.Count();
```

## 错误处理

`NapiArgs` 会自动处理错误并抛出 JS 异常。在 C++ 侧，你需要检查 `HasError()` 并适当地返回。

```cpp
napi_value MyFunction(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // 每次获取参数后检查错误
    args.RequireMinArgs(2);
    if (args.HasError()) return CreateBoolValue(env, false);
    
    std::string name = args.GetString(0, "name");
    int64_t value = args.GetInt64(1, "value");
    if (args.HasError()) return CreateBoolValue(env, false);
    
    // 继续处理
    // ...
}
```

### 错误信息

当发生错误时，`NapiArgs` 会：
1. 设置内部错误标志
2. 存储错误消息
3. 自动调用 `napi_throw_type_error` 抛出 JS 异常

错误消息会包含参数名称（如果提供），使调试更容易：
```
// 示例错误消息：
"Argument 'name' must be a string"
"Argument [0] is missing (index 0, but only 0 arguments provided)"
"Insufficient arguments: expected at least 2, but got 1"
```

## 可选参数

使用 `GetXxxOr` 方法获取可选参数，并提供默认值：

```cpp
// 如果参数不存在或类型不匹配，返回默认值
std::string name = args.GetStringOr(1, "Unknown");
int64_t timeout = args.GetInt64Or(2, 5000);
double opacity = args.GetDoubleOr(3, 1.0);
bool debug = args.GetBoolOr(4, false);
```

## 对象属性访问

`NapiArgs` 提供了便捷的方法从对象中提取属性：

```cpp
napi_value options = args.GetObject(0, "options");
if (!args.HasError() && options) {
    // 所有属性方法都支持默认值
    std::string url = args.GetStringProperty(options, "url", "");
    int64_t timeout = args.GetInt64Property(options, "timeout", 3000);
    double zoom = args.GetDoubleProperty(options, "zoom", 15.0);
    bool cache = args.GetBoolProperty(options, "cache", true);
}
```

## 代码迁移示例

### 重构前（旧代码）

```cpp
napi_value AddSource(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value args[4];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 4) {
        LOGE("AddSource: insufficient arguments");
        return CreateBoolValue(env, false);
    }

    int64_t mapPtr = GetInt64FromValue(env, args[0]);
    mbgl::Map* map = reinterpret_cast<mbgl::Map*>(mapPtr);

    if (!map) {
        LOGE("AddSource: invalid map pointer");
        return CreateBoolValue(env, false);
    }

    std::string sourceId = GetStringFromValue(env, args[1]);
    std::string sourceJson = GetStringFromValue(env, args[2]);
    int64_t sourceNativePtr = GetInt64FromValue(env, args[3]);

    // 处理逻辑...
}
```

### 重构后（使用 NapiArgs）

```cpp
napi_value AddSource(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(4);
    if (args.HasError()) return CreateBoolValue(env, false);

    int64_t mapPtr = args.GetInt64(0, "mapPtr");
    std::string sourceId = args.GetString(1, "sourceId");
    std::string sourceJson = args.GetString(2, "sourceJson");
    int64_t sourceNativePtr = args.GetInt64(3, "sourceNativePtr");
    if (args.HasError()) return CreateBoolValue(env, false);

    mbgl::Map* map = reinterpret_cast<mbgl::Map*>(mapPtr);
    if (!map) {
        LOGE("AddSource: invalid map pointer");
        return CreateBoolValue(env, false);
    }

    // 处理逻辑...
}
```

### 代码改进对比

**代码减少**：约 40% 的样板代码
- 不需要声明 `argc` 和 `args[]`
- 不需要手动调用 `napi_get_cb_info`
- 不需要为每个参数单独调用转换函数
- 参数验证和错误处理自动完成

**错误消息改进**：
- 旧代码："AddSource: insufficient arguments"
- 新代码："Insufficient arguments: expected at least 4, but got 2"

**类型安全**：
- 自动类型检查，并提供清晰的错误消息
- 例如："Argument 'sourceId' must be a string"

## 完整示例

### 示例 1: 创建图层

```cpp
napi_value FillLayerHarmony::Create(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return CreateInt64Value(env, 0);

    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) return CreateInt64Value(env, 0);

    try {
        auto layer = std::make_unique<mbgl::style::FillLayer>(layerId, sourceId);
        int64_t layerPtr = reinterpret_cast<int64_t>(layer.release());
        LOGI("FillLayer.Create: %s (source: %s)", layerId.c_str(), sourceId.c_str());
        return CreateInt64Value(env, layerPtr);
    } catch (const std::exception& e) {
        LOGE("FillLayer.Create failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}
```

### 示例 2: 设置图层属性

```cpp
napi_value FillLayerHarmony::SetFillColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = args.GetInt64(0, "layerPtr");
    std::string colorStr = args.GetString(1, "color");
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    auto* layer = reinterpret_cast<mbgl::style::FillLayer*>(layerPtr);
    if (!layer) {
        LOGE("SetFillColor: invalid layer pointer");
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    try {
        auto color = mbgl::Color::parse(colorStr);
        if (color) {
            layer->setFillColor(PropertyValue<Color>(*color));
            LOGI("SetFillColor: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        LOGE("SetFillColor failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}
```

### 示例 3: 处理可选参数

```cpp
napi_value ConfigureMap(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return CreateBoolValue(env, false);

    int64_t mapPtr = args.GetInt64(0, "mapPtr");
    
    // 可选参数，提供默认值
    double zoom = args.GetDoubleOr(1, 15.0);
    double bearing = args.GetDoubleOr(2, 0.0);
    double pitch = args.GetDoubleOr(3, 0.0);
    bool animate = args.GetBoolOr(4, true);
    
    if (args.HasError()) return CreateBoolValue(env, false);

    // 使用参数配置地图
    // ...
    
    return CreateBoolValue(env, true);
}
```

### 示例 4: 处理对象参数

```cpp
napi_value CreateSourceWithOptions(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return CreateInt64Value(env, 0);

    std::string sourceId = args.GetString(0, "sourceId");
    napi_value options = args.GetObject(1, "options");
    if (args.HasError()) return CreateInt64Value(env, 0);

    // 从选项对象中提取属性
    std::string url = args.GetStringProperty(options, "url", "");
    int64_t maxZoom = args.GetInt64Property(options, "maxZoom", 18);
    int64_t minZoom = args.GetInt64Property(options, "minZoom", 0);
    bool cluster = args.GetBoolProperty(options, "cluster", false);
    double clusterRadius = args.GetDoubleProperty(options, "clusterRadius", 50.0);

    // 使用这些参数创建数据源
    // ...

    return CreateInt64Value(env, sourcePtr);
}
```

## 最佳实践

1. **始终检查错误**：在获取参数后检查 `HasError()`
   ```cpp
   args.RequireMinArgs(2);
   if (args.HasError()) return errorValue;
   ```

2. **提供参数名称**：使用参数名称使错误消息更清晰
   ```cpp
   std::string name = args.GetString(0, "name"); // 好
   std::string name = args.GetString(0);         // 可以，但错误消息不够清晰
   ```

3. **使用可选参数方法**：对于可选参数，使用 `GetXxxOr` 方法
   ```cpp
   double opacity = args.GetDoubleOr(2, 1.0); // 好
   // 而不是手动检查参数是否存在
   ```

4. **集中错误检查**：可以在获取所有参数后统一检查
   ```cpp
   std::string a = args.GetString(0, "a");
   int64_t b = args.GetInt64(1, "b");
   double c = args.GetDouble(2, "c");
   if (args.HasError()) return errorValue; // 统一检查
   ```

5. **处理对象属性时使用辅助方法**：
   ```cpp
   // 好：使用辅助方法
   std::string url = args.GetStringProperty(obj, "url", "");
   
   // 不推荐：手动获取属性
   napi_value urlValue;
   napi_get_named_property(env, obj, "url", &urlValue);
   // ... 手动转换
   ```

## 与旧 API 的兼容性

`NapiArgs` 不会替换现有的 `napi_utils.h` 中的工具函数。两者可以共存：

- **新代码**：使用 `NapiArgs` 以获得更好的体验
- **旧代码**：可以继续使用现有的工具函数
- **迁移**：可以逐步将旧代码迁移到新的 API

## 性能考虑

`NapiArgs` 的性能开销很小：
- 构造函数只调用一次 `napi_get_cb_info`
- 参数存储在 `std::vector` 中，访问开销可忽略
- 错误检查是轻量级的布尔标志检查

对于绝大多数场景，使用 `NapiArgs` 的便利性远超过微小的性能开销。

## 总结

`NapiArgs` 工具类显著简化了 N-API 参数解析：
- ✅ 减少样板代码约 40%
- ✅ 自动类型检查和转换
- ✅ 清晰的错误消息
- ✅ 支持可选参数
- ✅ 便捷的对象属性访问
- ✅ 类型安全

推荐在所有新的 N-API 函数中使用 `NapiArgs`。

