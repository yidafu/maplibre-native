import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
/**
 * NetworkConfiguration - network configuration manager.
 *
 * Provides global configuration for HTTP headers, allowing custom headers on map resource requests.
 *
 * References:
 * - Android: `HttpRequestUtil.setOkHttpClient()`
 * - iOS: `MLNNetworkConfiguration`
 *
 * Usage example:
 * ```typescript
 * import { NetworkConfiguration } from '@ohos/maplibre';
 * 
 * // Set custom headers
 * NetworkConfiguration.setCustomHttpHeaders({
 *   'Authorization': 'Bearer your-token',
 *   'X-Custom-Header': 'custom-value'
 * });
 * 
 * // Add a single header
 * NetworkConfiguration.addCustomHttpHeader('X-API-Key', 'your-api-key');
 * 
 * // Get current configuration
 * const headers = NetworkConfiguration.getCustomHttpHeaders();
 * 
 * // Clear all custom headers
 * NetworkConfiguration.clearCustomHttpHeaders();
 * ```
 * 
 * Notes:
 * 1. Configure headers before creating a MapView.
 * 2. Settings apply to all map instances (global configuration).
 * 3. The User-Agent header cannot be overridden.
 * 4. Header keys and values must comply with HTTP specifications.
 */

import maplibre from 'libmaplibre.so';

/**
 * HTTP header type definition.
 */
export type HttpHeaders = Record<string, string>;

/**
 * Network configuration class.
 *
 * Provides static helpers to manage global HTTP request settings.
 */
export class NetworkConfiguration {
  /**
   * Set custom HTTP headers (replacing all existing custom headers).
   *
   * This method replaces any previously configured custom headers.
   *
   * @param headers Header key-value map.
   * @throws Error if headers is not a valid object.
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

    // Validate key/value (use Object.keys instead of for...in)
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

    // Call NAPI interface
    // Call NAPI interface
    // Call NAPI interface
    // Call NAPI interface
    maplibre.setCustomHttpHeaders(headers);
  }

  /**
   * Add a single custom HTTP header.
   *
   * Overwrites any existing value for the same header.
   *
   * @param key Header name.
   * @param value Header value.
   * @throws Error if key or value is invalid.
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

    // Prevent overriding reserved headers
    if (key.toLowerCase() === 'user-agent') {
      hilog.warn(DOMAIN, 'NetworkConfiguration', '%{public}s', 'NetworkConfiguration: Cannot override User-Agent header');
      return;
    }

    // Invoke NAPI API
    maplibre.addCustomHttpHeader(key, value);
  }

  /**
   * Remove a custom HTTP header.
   *
   * @param key Header name.
   * @returns True if removed successfully, false if it did not exist.
   *
   * @example
   * ```typescript
   * const removed = NetworkConfiguration.removeCustomHttpHeader('X-Custom-Header');
   * hilog.info(DOMAIN, 'Header removed:', '%{public}s', removed);
   * ```
   */
  static removeCustomHttpHeader(key: string): boolean {
    if (!key || typeof key !== 'string') {
      throw new Error('Header key must be a non-empty string');
    }

    // Invoke NAPI API
    return maplibre.removeCustomHttpHeader(key);
  }

  /**
   * Clear all custom HTTP headers.
   *
   * Removes previously set custom headers without affecting SDK defaults.
   *
   * @example
   * ```typescript
   * NetworkConfiguration.clearCustomHttpHeaders();
   * ```
   */
  static clearCustomHttpHeaders(): void {
    // Invoke NAPI API
    maplibre.clearCustomHttpHeaders();
  }

  /**
   * Retrieve the current custom HTTP headers.
   *
   * @returns Copy of the header key-value pairs.
   *
   * @example
   * ```typescript
   * const headers = NetworkConfiguration.getCustomHttpHeaders();
   * hilog.info(DOMAIN, 'Current headers:', '%{public}s', headers);
   * ```
   */
  static getCustomHttpHeaders(): HttpHeaders {
    // Invoke NAPI API
    return maplibre.getCustomHttpHeaders();
  }

  /**
   * Validate header name.
   *
   * HTTP header names must only contain visible ASCII characters without whitespace or colon.
   *
   * @param name Header name.
   * @returns True if valid, otherwise false.
   */
  private static isValidHeaderName(name: string): boolean {
    if (!name || name.length === 0) {
      return false;
    }

    // Check for invalid characters (no whitespace or colon)
    const invalidChars = /[\s:]/;
    if (invalidChars.test(name)) {
      return false;
    }

    // Ensure only visible ASCII characters
    for (let i = 0; i < name.length; i++) {
      const code = name.charCodeAt(i);
      if (code < 33 || code > 126) {
        return false;
      }
    }

    return true;
  }

  /**
   * Validate header value.
   *
   * HTTP header values must not include control characters such as newlines.
   *
   * @param value Header value.
   * @returns True if valid, otherwise false.
   */
  private static isValidHeaderValue(value: string): boolean {
    if (value === null || value === undefined) {
      return false;
    }

    // Reject control characters (especially newlines)
    const controlChars = /[\r\n]/;
    if (controlChars.test(value)) {
      return false;
    }

    return true;
  }
}

