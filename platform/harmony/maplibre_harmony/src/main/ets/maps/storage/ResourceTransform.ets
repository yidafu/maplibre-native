/**
 * ResourceTransform - URL转换管理类
 * 
 * 提供URL转换功能，允许开发者在运行时拦截和修改地图资源请求的URL。
 * 
 * 参考实现：
 * - Android: FileSource.setResourceTransform()
 * - iOS: MLNOfflineStorageDelegate.offlineStorage:URLForResourceOfKind:withURL:
 * 
 * 使用示例：
 * ```typescript
 * import { ResourceTransform, ResourceKind } from '@ohos/maplibre';
 * 
 * // 将Mapbox CDN切换到自定义CDN
 * ResourceTransform.setCallback((kind, url) => {
 *   if (url.includes('api.mapbox.com')) {
 *     return url.replace('api.mapbox.com', 'my-cdn.example.com');
 *   }
 *   return url;
 * });
 * 
 * // 清除转换回调
 * ResourceTransform.clearCallback();
 * ```
 * 
 * 注意事项：
 * 1. 回调应尽快返回，避免阻塞请求线程
 * 2. 回调在资源请求前同步执行
 * 3. 返回空字符串或undefined将使用原URL
 * 4. 回调中的异常会被捕获，并使用原URL
 * 5. 配置对所有地图实例全局生效
 */

import maplibre from 'libmaplibre.so';

/**
 * 资源类型枚举
 * 
 * 对应mbgl::Resource::Kind
 */
export enum ResourceKind {
  /** 未知资源类型 */
  Unknown = 0,
  /** 样式文件 (.json) */
  Style = 1,
  /** 数据源定义 */
  Source = 2,
  /** 地图瓦片 */
  Tile = 3,
  /** 字体字形 */
  Glyphs = 4,
  /** 精灵图片 */
  SpriteImage = 5,
  /** 精灵JSON定义 */
  SpriteJSON = 6,
  /** 图片资源 */
  Image = 7
}

/**
 * URL转换回调函数类型
 * 
 * @param kind - 资源类型
 * @param url - 原始URL
 * @returns 转换后的URL，如果返回空字符串则使用原URL
 */
export type ResourceTransformCallback = (kind: ResourceKind, url: string) => string;

/**
 * ResourceTransform - URL转换管理类
 * 
 * 提供静态方法管理全局URL转换配置
 */
export class ResourceTransform {
  /**
   * 设置URL转换回调
   * 
   * 该回调将在每次发起资源请求前被调用，允许修改请求的URL。
   * 
   * @param callback - URL转换回调函数
   * @throws 如果callback不是函数则抛出错误
   * 
   * @example
   * ```typescript
   * // CDN切换
   * ResourceTransform.setCallback((kind, url) => {
   *   return url.replace('mapbox.com', 'my-cdn.com');
   * });
   * 
   * // 离线资源映射
   * ResourceTransform.setCallback((kind, url) => {
   *   if (kind === ResourceKind.Tile) {
   *     return `file:///data/tiles/${extractTileId(url)}.mvt`;
   *   }
   *   return url;
   * });
   * 
   * // 添加认证参数
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

    // 包装回调，确保返回值是字符串
    const wrappedCallback = (kind: number, url: string): string => {
      try {
        const result = callback(kind as ResourceKind, url);
        
        // 如果回调返回undefined、null或非字符串，返回原URL
        if (result === undefined || result === null || typeof result !== 'string') {
          console.warn('ResourceTransform: Callback returned invalid value, using original URL');
          return url;
        }
        
        // 如果返回空字符串，返回原URL
        if (result.length === 0) {
          return url;
        }
        
        return result;
        
      } catch (error) {
        console.error('ResourceTransform: Exception in callback:', error);
        return url;
      }
    };

    // 调用NAPI接口
    maplibre.setResourceTransformCallback(wrappedCallback);
  }

  /**
   * 清除URL转换回调
   * 
   * 清除后，所有资源请求将使用原始URL，不进行转换。
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
   * 检查是否设置了转换回调
   * 
   * @returns 如果设置了回调返回true，否则返回false
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

