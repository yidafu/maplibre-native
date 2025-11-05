import { Context } from '@kit.AbilityKit';
import { ResourceTransform, ResourceTransformCallback } from './ResourceTransform';

/**
 * FileSource - 文件源类
 */
export class FileSource {
  private static instance: FileSource | null = null;
  private context: Context | null = null;

  private constructor(context: Context) {
    this.context = context;
  }

  /**
   * 获取FileSource实例（单例模式）
   */
  public static getInstance(context: Context): FileSource {
    if (!FileSource.instance) {
      FileSource.instance = new FileSource(context);
    }
    return FileSource.instance;
  }

  /**
   * 获取上下文
   */
  public getContext(): Context | null {
    return this.context;
  }

  /**
   * 设置上下文
   */
  public setContext(context: Context): void {
    this.context = context;
  }

  /**
   * 设置资源URL转换回调
   * 
   * 允许在运行时修改资源请求的URL，用于实现CDN切换、离线资源映射等功能。
   * 
   * @param callback - URL转换回调函数，如果传入null则清除回调
   * 
   * @example
   * ```typescript
   * import { FileSource, ResourceKind } from '@ohos/maplibre';
   * 
   * const fileSource = FileSource.getInstance(context);
   * fileSource.setResourceTransform((kind, url) => {
   *   if (kind === ResourceKind.Tile) {
   *     return url.replace('api.mapbox.com', 'my-cdn.com');
   *   }
   *   return url;
   * });
   * ```
   */
  public setResourceTransform(callback: ResourceTransformCallback | null): void {
    if (callback) {
      ResourceTransform.setCallback(callback);
    } else {
      ResourceTransform.clearCallback();
    }
  }
}
