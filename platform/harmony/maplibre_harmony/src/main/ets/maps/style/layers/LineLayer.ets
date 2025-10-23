import { Layer, LayerOptions } from './Layer';
import { PropertyValue } from './PropertyValue';
import maplibre from 'libmaplibre_native.so';

/**
 * LineLayer - 线条图层
 * 
 * 用于渲染线条和边界
 */
export class LineLayer extends Layer {
  private nativePtr: number = 0;

  /**
   * 创建线条图层
   * 
   * @param layerId 图层ID
   * @param sourceId 数据源ID
   */
  constructor(layerId: string, sourceId: string) {
    super({
      id: layerId,
      type: 'line',
      source: sourceId
    });
    this.initialize(layerId, sourceId);
  }

  /**
   * 初始化native对象
   */
  private initialize(layerId: string, sourceId: string): void {
    try {
      this.nativePtr = maplibre.LineLayer.create(layerId, sourceId);
    } catch (error) {
      console.error(`Failed to initialize LineLayer: ${error}`);
    }
  }

  /**
   * 设置源图层
   */
  public withSourceLayer(sourceLayer: string): LineLayer {
    this.setSourceLayer(sourceLayer);
    return this;
  }

  /**
   * 设置过滤器
   */
  public withFilter(filter: Object): LineLayer {
    this.setFilter(filter);
    return this;
  }

  /**
   * 设置线条颜色
   */
  public setLineColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.LineLayer.setLineColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set line color: ${error}`);
    }
  }

  /**
   * 设置线条宽度
   */
  public setLineWidth(width: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.LineLayer.setLineWidth(this.nativePtr, width);
    } catch (error) {
      console.error(`Failed to set line width: ${error}`);
    }
  }

  /**
   * 设置线条透明度
   */
  public setLineOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.LineLayer.setLineOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set line opacity: ${error}`);
    }
  }

  /**
   * 设置线条图案
   */
  public setLinePattern(pattern: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.LineLayer.setLinePattern(this.nativePtr, pattern);
    } catch (error) {
      console.error(`Failed to set line pattern: ${error}`);
    }
  }

  /**
   * 设置线条间隙宽度
   */
  public setLineGapWidth(gapWidth: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.LineLayer.setLineGapWidth(this.nativePtr, gapWidth);
    } catch (error) {
      console.error(`Failed to set line gap width: ${error}`);
    }
  }

  /**
   * 设置线条虚线数组
   */
  public setLineDasharray(dasharray: number[]): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.LineLayer.setLineDasharray(this.nativePtr, dasharray);
    } catch (error) {
      console.error(`Failed to set line dasharray: ${error}`);
    }
  }

  /**
   * 设置线条模糊
   */
  public setLineBlur(blur: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.LineLayer.setLineBlur(this.nativePtr, blur);
    } catch (error) {
      console.error(`Failed to set line blur: ${error}`);
    }
  }

  /**
   * 设置线条端点样式 ("butt" | "round" | "square")
   */
  public setLineCap(cap: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.LineLayer.setLineCap(this.nativePtr, cap);
    } catch (error) {
      console.error(`Failed to set line cap: ${error}`);
    }
  }

  /**
   * 设置线条连接样式 ("bevel" | "round" | "miter")
   */
  public setLineJoin(join: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.LineLayer.setLineJoin(this.nativePtr, join);
    } catch (error) {
      console.error(`Failed to set line join: ${error}`);
    }
  }

  /**
   * 链式调用 - 设置线条颜色
   */
  public withLineColor(color: string): LineLayer {
    this.setLineColor(color);
    return this;
  }

  /**
   * 链式调用 - 设置线条宽度
   */
  public withLineWidth(width: number): LineLayer {
    this.setLineWidth(width);
    return this;
  }

  /**
   * 链式调用 - 设置线条透明度
   */
  public withLineOpacity(opacity: number): LineLayer {
    this.setLineOpacity(opacity);
    return this;
  }

  /**
   * 链式调用 - 设置线条虚线
   */
  public withLineDasharray(dasharray: number[]): LineLayer {
    this.setLineDasharray(dasharray);
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
    return `LineLayer(id=${this.id}, source=${this.source})`;
  }
}

