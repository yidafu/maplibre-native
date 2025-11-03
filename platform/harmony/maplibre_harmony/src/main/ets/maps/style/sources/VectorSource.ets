/**
 * VectorSource - 矢量数据源封装类
 */
import maplibre from 'libmaplibre.so';
import type { VectorSourceOptions } from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class VectorSource {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'VectorSource';
  
  private nativeInstance: maplibre.VectorSource;

  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: VectorSourceOptions | maplibre.VectorSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      this.nativeInstance = optionsOrNative as maplibre.VectorSource;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.VectorSource(idOrMarker, optionsOrNative as VectorSourceOptions);
    } else {
      throw new Error('Invalid VectorSource constructor arguments');
    }
  }

  static create(id: string, options?: VectorSourceOptions): VectorSource {
    return new VectorSource(id, options);
  }
  
  setTiles(tiles: string[]): VectorSource {
    this.nativeInstance.setTiles(tiles);
    return this;
  }

  static fromNative(nativeInstance: maplibre.VectorSource): VectorSource {
    return new VectorSource(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.VectorSource {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setUrl(url: string): VectorSource {
    this.nativeInstance.setUrl(url);
    return this;
  }

  getUrl(): string {
    return this.nativeInstance.getUrl();
  }

  /**
   * 设置最小缩放级别
   * 注意：minZoom 和 maxZoom 通常在源创建时通过 TileSet 配置设置，
   * 运行时动态修改需要重新创建源。此方法暂不支持运行时修改。
   * 请在构造函数的 options 参数中设置 minzoom 属性。
   */
  setMinZoom(minZoom: number): VectorSource {
    console.warn('[VectorSource] setMinZoom: minZoom should be set via constructor options (minzoom property)');
    return this;
  }

  /**
   * 设置最大缩放级别
   * 注意：minZoom 和 maxZoom 通常在源创建时通过 TileSet 配置设置，
   * 运行时动态修改需要重新创建源。此方法暂不支持运行时修改。
   * 请在构造函数的 options 参数中设置 maxzoom 属性。
   */
  setMaxZoom(maxZoom: number): VectorSource {
    console.warn('[VectorSource] setMaxZoom: maxZoom should be set via constructor options (maxzoom property)');
    return this;
  }
}
