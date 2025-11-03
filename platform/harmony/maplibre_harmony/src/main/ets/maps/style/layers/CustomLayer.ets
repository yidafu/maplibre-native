/**
 * CustomLayer - 自定义渲染图层封装类
 *
 * 对应Android平台: org.maplibre.android.style.layers.CustomLayer
 *
 * 自定义图层允许开发者使用OpenGL ES直接在地图上渲染内容
 */
import maplibre from 'libmaplibre.so';

/**
 * RGBA颜色接口
 */
export interface RGBAColor {
  r: number; // 红色分量 (0.0 - 1.0)
  g: number; // 绿色分量 (0.0 - 1.0)
  b: number; // 蓝色分量 (0.0 - 1.0)
  a: number; // 透明度 (0.0 - 1.0)
}

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * CustomLayer - 自定义渲染图层
 *
 * 允许开发者通过OpenGL ES在地图上进行自定义渲染
 *
 * @example
* ```typescript
 * const customLayer = new CustomLayer('custom-layer');
 * customLayer.setColor(1.0, 0.0, 0.0, 0.5);  // 红色半透明
 * map.getStyle().addLayer(customLayer);
 * ```
 */
export class CustomLayer {
  static readonly _TYPE_ = 'CustomLayer';
  private nativeInstance: maplibre.CustomLayer;

  constructor(idOrMarker: string | InternalMarker, nativeOrNothing?: maplibre.CustomLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.CustomLayer(idOrMarker);
    } else {
      throw new Error('Invalid CustomLayer constructor arguments');
    }
  }

  static create(id: string): CustomLayer {
    return new CustomLayer(id);
  }

  static fromNative(nativeInstance: maplibre.CustomLayer): CustomLayer {
    return new CustomLayer(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.CustomLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getType(): string {
    return this.nativeInstance.getType();
  }

  setVisibility(visibility: 'visible' | 'none'): CustomLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  getVisibility(): 'visible' | 'none' {
    return this.nativeInstance.getVisibility() as 'visible' | 'none';
  }

  setMinZoom(zoom: number): CustomLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  getMinZoom(): number {
    return this.nativeInstance.getMinZoom();
  }

  setMaxZoom(zoom: number): CustomLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  getMaxZoom(): number {
    return this.nativeInstance.getMaxZoom();
  }

  /**
   * 设置渲染颜色（示例实现专用）
   * @param r 红色分量 (0.0 - 1.0)
   * @param g 绿色分量 (0.0 - 1.0)
   * @param b 蓝色分量 (0.0 - 1.0)
   * @param a 透明度 (0.0 - 1.0)
   */
  setColor(r: number, g: number, b: number, a: number): CustomLayer {
    this.nativeInstance.setColor(r, g, b, a);
    return this;
  }

  /**
   * 获取当前颜色（示例实现专用）
   * @returns 颜色数组 [r, g, b, a]
   */
  getColor(): number[] {
    return this.nativeInstance.getColor();
  }
}

/**
 * 辅助函数：创建 CustomLayer 并设置颜色
 *
 * @param id 图层ID
 * @param color 颜色对象
 * @returns CustomLayer 实例
 */
export function createCustomLayerWithColor(id: string, color: RGBAColor): CustomLayer {
  const layer = new CustomLayer(id);
  layer.setColor(color.r, color.g, color.b, color.a);
  return layer;
}

