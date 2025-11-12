/**
 * ResourceTransform - URL transform manager.
 *
 * Intercepts and rewrites resource request URLs at runtime.
 *
 * References:
 * - Android: `FileSource.setResourceTransform()`
 * - iOS: `MLNOfflineStorageDelegate.offlineStorage:URLForResourceOfKind:withURL:`
 *
 * Usage example:
 * ```typescript
 * import { ResourceTransform, ResourceKind } from '@ohos/maplibre';
 * 
 * // Switch Mapbox CDN to a custom CDN
 * ResourceTransform.setCallback((kind, url) => {
 *   if (url.includes('api.mapbox.com')) {
 *     return url.replace('api.mapbox.com', 'my-cdn.example.com');
 *   }
 *   return url;
 * });
 * 
 * // Clear the transform callback
 * ResourceTransform.clearCallback();
 * ```
 * 
 * Notes:
 * 1. The callback should return quickly to avoid blocking the request thread.
 * 2. The callback runs synchronously before each resource request.
 * 3. Returning an empty string or `undefined` keeps the original URL.
 * 4. Exceptions thrown in the callback are caught and the original URL is used.
 * 5. The configuration applies globally to all map instances.
 */

import maplibre from 'libmaplibre.so';

/**
 * Resource kind enumeration.
 *
 * Mirrors `mbgl::Resource::Kind`.
 */
export enum ResourceKind {
  /** Unknown resource type. */
  Unknown = 0,
  /** Style JSON. */
  Style = 1,
  /** Source definition. */
  Source = 2,
  /** Map tile. */
  Tile = 3,
  /** Glyphs. */
  Glyphs = 4,
  /** Sprite image. */
  SpriteImage = 5,
  /** Sprite JSON definition. */
  SpriteJSON = 6,
  /** Raster image resource. */
  Image = 7
}

/**
 * URL transform callback type.
 *
 * @param kind Resource type.
 * @param url Original URL.
 * @returns Transformed URL; return empty string to keep the original.
 */
export type ResourceTransformCallback = (kind: ResourceKind, url: string) => string;

/**
 * ResourceTransform - URL transform manager (static helpers).
 */
export class ResourceTransform {
  /**
   * Register a URL transform callback.
   *
   * Called before each resource request, allowing URL rewriting.
   *
   * @param callback Transform callback.
   * @throws Error when callback is not a function.
   *
   * @example
   * ```typescript
   * // CDN switching
   * ResourceTransform.setCallback((kind, url) => {
   *   return url.replace('mapbox.com', 'my-cdn.com');
   * });
   * 
   * // Offline resource remapping
   * ResourceTransform.setCallback((kind, url) => {
   *   if (kind === ResourceKind.Tile) {
   *     return `file:///data/tiles/${extractTileId(url)}.mvt`;
   *   }
   *   return url;
   * });
   * 
   * // Append auth parameters
   * ResourceTransform.setCallback((kind, url) => {
   *   const separator = url.includes('?') ? '&' : '?';
   *   return `${url}${separator}token=${getAuthToken()}`;
   * });
   * ```
   */
  static setCallback(callback: ResourceTransformCallback): void {
    if (!callback || typeof callback !== 'function') {
      throw new Error('Callback must be a function');
    }

    // Wrap the callback to ensure a string result.
    const wrappedCallback = (kind: number, url: string): string => {
      try {
        const result = callback(kind as ResourceKind, url);
        
        // Fall back to the original URL when the callback returns undefined, null, or a non-string.
        if (result === undefined || result === null || typeof result !== 'string') {
          console.warn('ResourceTransform: Callback returned invalid value, using original URL');
          return url;
        }
        
        // Empty string also falls back to the original URL.
        if (result.length === 0) {
          return url;
        }
        
        return result;
        
      } catch (error) {
        console.error('ResourceTransform: Exception in callback:', error);
        return url;
      }
    };

    // Call the NAPI bridge.
    maplibre.setResourceTransformCallback(wrappedCallback);
  }

  /**
   * Clear the URL transform callback.
   *
   * After clearing, resource requests use the original URLs without modification.
   *
   * @example
   * ```typescript
   * ResourceTransform.clearCallback();
   * ```
   */
  static clearCallback(): void {
    maplibre.clearResourceTransformCallback();
  }

  /**
   * Check whether a transform callback is registered.
   *
   * @returns True when a callback is registered; otherwise false.
   *
   * @example
   * ```typescript
   * if (ResourceTransform.hasCallback()) {
   *   console.log('URL transform is active');
   * }
   * ```
   */
  static hasCallback(): boolean {
    return maplibre.hasResourceTransformCallback();
  }
}

