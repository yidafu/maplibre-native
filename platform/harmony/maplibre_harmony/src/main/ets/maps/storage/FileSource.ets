import { Context } from '@kit.AbilityKit';
import { ResourceTransform, ResourceTransformCallback } from './ResourceTransform';

/**
 * FileSource - file source singleton wrapper.
 */
export class FileSource {
  private static instance: FileSource | null = null;
  private context: Context | null = null;

  private constructor(context: Context) {
    this.context = context;
  }

  /**
   * Retrieve the FileSource singleton instance.
   */
  public static getInstance(context: Context): FileSource {
    if (!FileSource.instance) {
      FileSource.instance = new FileSource(context);
    }
    return FileSource.instance;
  }

  /**
   * Get the stored context.
   */
  public getContext(): Context | null {
    return this.context;
  }

  /**
   * Update the stored context.
   */
  public setContext(context: Context): void {
    this.context = context;
  }

  /**
   * Configure the resource URL transform callback.
   *
   * Allows runtime modification of resource URLs (e.g. CDN switching, offline remapping).
   *
   * @param callback URL transform callback; pass null to clear.
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
