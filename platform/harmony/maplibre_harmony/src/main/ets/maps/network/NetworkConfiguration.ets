/**
 * NetworkConfiguration - 网络配置管理类
 * 
 * 提供HTTP请求头的全局配置，允许开发者为地图资源请求添加自定义请求头。
 * 
 * 参考实现：
 * - Android: HttpRequestUtil.setOkHttpClient()
 * - iOS: MLNNetworkConfiguration
 * 
 * 使用示例：
 * ```typescript
 * import { NetworkConfiguration } from '@ohos/maplibre';
 * 
 * // 设置自定义请求头
 * NetworkConfiguration.setCustomHttpHeaders({
 *   'Authorization': 'Bearer your-token',
 *   'X-Custom-Header': 'custom-value'
 * });
 * 
 * // 添加单个请求头
 * NetworkConfiguration.addCustomHttpHeader('X-API-Key', 'your-api-key');
 * 
 * // 获取当前配置
 * const headers = NetworkConfiguration.getCustomHttpHeaders();
 * 
 * // 清除所有自定义请求头
 * NetworkConfiguration.clearCustomHttpHeaders();
 * ```
 * 
 * 注意事项：
 * 1. 需要在创建MapView之前配置请求头
 * 2. 配置对所有地图实例生效（全局配置）
 * 3. 不允许覆盖User-Agent请求头
 * 4. 请求头键值需符合HTTP规范
 */

import maplibre from 'libmaplibre.so';

/**
 * HTTP请求头类型定义
 */
export type HttpHeaders = Record<string, string>;

/**
 * 网络配置类
 * 
 * 提供静态方法管理全局HTTP请求配置
 */
export class NetworkConfiguration {
  /**
   * 设置自定义HTTP请求头（替换所有现有请求头）
   * 
   * 此方法会替换所有之前设置的自定义请求头。
   * 
   * @param headers - 请求头键值对对象
   * @throws 如果headers不是有效对象则抛出错误
   * 
   * @example
   * ```typescript
   * NetworkConfiguration.setCustomHttpHeaders({
   *   'Authorization': 'Bearer token123',
   *   'X-API-Key': 'key456'
   * });
   * ```
   */
  static setCustomHttpHeaders(headers: HttpHeaders): void {
    if (!headers || typeof headers !== 'object') {
      throw new Error('Headers must be a valid object');
    }

    // 验证请求头键值 (使用Object.keys代替for...in)
    const keys = Object.keys(headers);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (!NetworkConfiguration.isValidHeaderName(key)) {
        throw new Error(`Invalid header name: ${key}`);
      }
      if (!NetworkConfiguration.isValidHeaderValue(headers[key])) {
        throw new Error(`Invalid header value for ${key}`);
      }
    }

    // 调用NAPI接口
    maplibre.setCustomHttpHeaders(headers);
  }

  /**
   * 添加单个自定义HTTP请求头
   * 
   * 如果该请求头已存在，则会覆盖原有值。
   * 
   * @param key - 请求头名称
   * @param value - 请求头值
   * @throws 如果key或value不合法则抛出错误
   * 
   * @example
   * ```typescript
   * NetworkConfiguration.addCustomHttpHeader('X-Custom-Header', 'custom-value');
   * ```
   */
  static addCustomHttpHeader(key: string, value: string): void {
    if (!key || typeof key !== 'string') {
      throw new Error('Header key must be a non-empty string');
    }
    if (!value || typeof value !== 'string') {
      throw new Error('Header value must be a non-empty string');
    }

    if (!NetworkConfiguration.isValidHeaderName(key)) {
      throw new Error(`Invalid header name: ${key}`);
    }
    if (!NetworkConfiguration.isValidHeaderValue(value)) {
      throw new Error(`Invalid header value for ${key}`);
    }

    // 检查是否为保留请求头
    if (key.toLowerCase() === 'user-agent') {
      console.warn('NetworkConfiguration: Cannot override User-Agent header');
      return;
    }

    // 调用NAPI接口
    maplibre.addCustomHttpHeader(key, value);
  }

  /**
   * 移除指定的自定义HTTP请求头
   * 
   * @param key - 请求头名称
   * @returns 如果成功移除返回true，如果不存在返回false
   * 
   * @example
   * ```typescript
   * const removed = NetworkConfiguration.removeCustomHttpHeader('X-Custom-Header');
   * console.log('Header removed:', removed);
   * ```
   */
  static removeCustomHttpHeader(key: string): boolean {
    if (!key || typeof key !== 'string') {
      throw new Error('Header key must be a non-empty string');
    }

    // 调用NAPI接口
    return maplibre.removeCustomHttpHeader(key);
  }

  /**
   * 清除所有自定义HTTP请求头
   * 
   * 此方法会移除所有之前设置的自定义请求头，但不影响SDK内部的默认请求头。
   * 
   * @example
   * ```typescript
   * NetworkConfiguration.clearCustomHttpHeaders();
   * ```
   */
  static clearCustomHttpHeaders(): void {
    // 调用NAPI接口
    maplibre.clearCustomHttpHeaders();
  }

  /**
   * 获取当前配置的所有自定义HTTP请求头
   * 
   * @returns 请求头键值对对象的副本
   * 
   * @example
   * ```typescript
   * const headers = NetworkConfiguration.getCustomHttpHeaders();
   * console.log('Current headers:', headers);
   * ```
   */
  static getCustomHttpHeaders(): HttpHeaders {
    // 调用NAPI接口
    return maplibre.getCustomHttpHeaders();
  }

  /**
   * 验证请求头名称是否合法
   * 
   * 根据HTTP规范，请求头名称应该只包含可见ASCII字符，
   * 不包含空格、冒号等特殊字符。
   * 
   * @param name - 请求头名称
   * @returns 如果合法返回true，否则返回false
   */
  private static isValidHeaderName(name: string): boolean {
    if (!name || name.length === 0) {
      return false;
    }

    // 检查是否包含非法字符
    // HTTP请求头名称应该只包含可见ASCII字符（不包含空格、冒号等）
    const invalidChars = /[\s:]/;
    if (invalidChars.test(name)) {
      return false;
    }

    // 检查是否只包含ASCII可见字符
    for (let i = 0; i < name.length; i++) {
      const code = name.charCodeAt(i);
      if (code < 33 || code > 126) {
        return false;
      }
    }

    return true;
  }

  /**
   * 验证请求头值是否合法
   * 
   * 根据HTTP规范，请求头值不应包含换行符等控制字符。
   * 
   * @param value - 请求头值
   * @returns 如果合法返回true，否则返回false
   */
  private static isValidHeaderValue(value: string): boolean {
    if (value === null || value === undefined) {
      return false;
    }

    // 检查是否包含控制字符（特别是换行符）
    const controlChars = /[\r\n]/;
    if (controlChars.test(value)) {
      return false;
    }

    return true;
  }
}

