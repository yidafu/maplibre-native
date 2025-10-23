import { Layer, LayerOptions } from './Layer';
import { PropertyValue } from './PropertyValue';
import maplibre from 'libmaplibre_native.so';

/**
 * FillLayer - 填充图层
 * 
 * 用于渲染多边形区域
 */
export class FillLayer extends Layer {
  private nativePtr: number = 0;

  /**
   * 创建填充图层
   * 
   * @param layerId 图层ID
   * @param sourceId 数据源ID
   */
  constructor(layerId: string, sourceId: string) {
    super({
      id: layerId,
      type: 'fill',
      source: sourceId
    });
    this.initialize(layerId, sourceId);
  }

  /**
   * 初始化native对象
   */
  private initialize(layerId: string, sourceId: string): void {
    try {
      this.nativePtr = maplibre.FillLayer.create(layerId, sourceId);
    } catch (error) {
      console.error(`Failed to initialize FillLayer: ${error}`);
    }
  }

  /**
   * 设置源图层
   */
  public withSourceLayer(sourceLayer: string): FillLayer {
    this.setSourceLayer(sourceLayer);
    return this;
  }

  /**
   * 设置过滤器
   */
  public withFilter(filter: Object): FillLayer {
    this.setFilter(filter);
    return this;
  }

  /**
   * 设置填充颜色
   */
  public setFillColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillLayer.setFillColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set fill color: ${error}`);
    }
  }

  /**
   * 设置填充透明度
   */
  public setFillOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillLayer.setFillOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set fill opacity: ${error}`);
    }
  }

  /**
   * 设置填充轮廓颜色
   */
  public setFillOutlineColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillLayer.setFillOutlineColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set fill outline color: ${error}`);
    }
  }

  /**
   * 设置填充图案
   */
  public setFillPattern(pattern: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillLayer.setFillPattern(this.nativePtr, pattern);
    } catch (error) {
      console.error(`Failed to set fill pattern: ${error}`);
    }
  }

  /**
   * 设置是否抗锯齿
   */
  public setFillAntialias(antialias: boolean): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillLayer.setFillAntialias(this.nativePtr, antialias);
    } catch (error) {
      console.error(`Failed to set fill antialias: ${error}`);
    }
  }

  /**
   * 设置填充偏移
   */
  public setFillTranslate(translate: number[]): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillLayer.setFillTranslate(this.nativePtr, translate);
    } catch (error) {
      console.error(`Failed to set fill translate: ${error}`);
    }
  }

  /**
   * 链式调用 - 设置填充颜色
   */
  public withFillColor(color: string): FillLayer {
    this.setFillColor(color);
    return this;
  }

  /**
   * 链式调用 - 设置填充透明度
   */
  public withFillOpacity(opacity: number): FillLayer {
    this.setFillOpacity(opacity);
    return this;
  }

  /**
   * 链式调用 - 设置填充轮廓颜色
   */
  public withFillOutlineColor(color: string): FillLayer {
    this.setFillOutlineColor(color);
    return this;
  }

  /**
   * 链式调用 - 设置填充图案
   */
  public withFillPattern(pattern: string): FillLayer {
    this.setFillPattern(pattern);
    return this;
  }

  /**
   * 获取原生指针
   */
  public override getNativePtr(): number {
    return this.nativePtr;
  }

  /**
   * 转换为字符串
   */
  public override toString(): string {
    return `FillLayer(id=${this.id}, source=${this.source})`;
  }
}

