import { Layer, LayerOptions } from './Layer';
import { PropertyValue } from './PropertyValue';
import maplibre from 'libmaplibre_native.so';

/**
 * FillExtrusionLayer - 3D拉伸填充图层
 * 
 * 用于渲染3D建筑等立体效果
 */
export class FillExtrusionLayer extends Layer {
  private nativePtr: number = 0;

  /**
   * 创建3D拉伸填充图层
   * 
   * @param layerId 图层ID
   * @param sourceId 数据源ID
   */
  constructor(layerId: string, sourceId: string) {
    super({
      id: layerId,
      type: 'fill-extrusion',
      source: sourceId
    });
    this.initialize(layerId, sourceId);
  }

  /**
   * 初始化native对象
   */
  private initialize(layerId: string, sourceId: string): void {
    try {
      this.nativePtr = maplibre.FillExtrusionLayer.create(layerId, sourceId);
    } catch (error) {
      console.error(`Failed to initialize FillExtrusionLayer: ${error}`);
    }
  }

  /**
   * 设置源图层
   */
  public withSourceLayer(sourceLayer: string): FillExtrusionLayer {
    this.setSourceLayer(sourceLayer);
    return this;
  }

  /**
   * 设置过滤器
   */
  public withFilter(filter: Object): FillExtrusionLayer {
    this.setFilter(filter);
    return this;
  }

  /**
   * 设置拉伸高度
   */
  public setFillExtrusionHeight(height: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillExtrusionLayer.setFillExtrusionHeight(this.nativePtr, height);
    } catch (error) {
      console.error(`Failed to set fill extrusion height: ${error}`);
    }
  }

  /**
   * 设置拉伸基础高度
   */
  public setFillExtrusionBase(base: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillExtrusionLayer.setFillExtrusionBase(this.nativePtr, base);
    } catch (error) {
      console.error(`Failed to set fill extrusion base: ${error}`);
    }
  }

  /**
   * 设置拉伸颜色
   */
  public setFillExtrusionColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillExtrusionLayer.setFillExtrusionColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set fill extrusion color: ${error}`);
    }
  }

  /**
   * 设置拉伸透明度
   */
  public setFillExtrusionOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillExtrusionLayer.setFillExtrusionOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set fill extrusion opacity: ${error}`);
    }
  }

  /**
   * 设置拉伸图案
   */
  public setFillExtrusionPattern(pattern: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillExtrusionLayer.setFillExtrusionPattern(this.nativePtr, pattern);
    } catch (error) {
      console.error(`Failed to set fill extrusion pattern: ${error}`);
    }
  }

  /**
   * 设置拉伸偏移
   */
  public setFillExtrusionTranslate(translate: number[]): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillExtrusionLayer.setFillExtrusionTranslate(this.nativePtr, translate);
    } catch (error) {
      console.error(`Failed to set fill extrusion translate: ${error}`);
    }
  }

  /**
   * 设置垂直渐变
   */
  public setFillExtrusionVerticalGradient(verticalGradient: boolean): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.FillExtrusionLayer.setFillExtrusionVerticalGradient(this.nativePtr, verticalGradient);
    } catch (error) {
      console.error(`Failed to set fill extrusion vertical gradient: ${error}`);
    }
  }

  /**
   * 链式调用 - 设置拉伸高度和基础高度
   */
  public withFillExtrusionHeight(height: number, base?: number): FillExtrusionLayer {
    this.setFillExtrusionHeight(height);
    if (base !== undefined) {
      this.setFillExtrusionBase(base);
    }
    return this;
  }

  /**
   * 链式调用 - 设置拉伸颜色
   */
  public withFillExtrusionColor(color: string): FillExtrusionLayer {
    this.setFillExtrusionColor(color);
    return this;
  }

  /**
   * 链式调用 - 设置拉伸透明度
   */
  public withFillExtrusionOpacity(opacity: number): FillExtrusionLayer {
    this.setFillExtrusionOpacity(opacity);
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
    return `FillExtrusionLayer(id=${this.id}, source=${this.source})`;
  }
}

