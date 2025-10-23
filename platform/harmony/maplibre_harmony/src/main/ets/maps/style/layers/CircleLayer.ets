import { Layer, LayerOptions } from './Layer';
import { PropertyValue } from './PropertyValue';
import maplibre from 'libmaplibre_native.so';

/**
 * CircleLayer - 圆形图层
 * 
 * 用于渲染圆形点
 */
export class CircleLayer extends Layer {
  private nativePtr: number = 0;

  /**
   * 创建圆形图层
   * 
   * @param layerId 图层ID
   * @param sourceId 数据源ID
   */
  constructor(layerId: string, sourceId: string) {
    super({
      id: layerId,
      type: 'circle',
      source: sourceId
    });
    this.initialize(layerId, sourceId);
  }

  /**
   * 初始化native对象
   */
  private initialize(layerId: string, sourceId: string): void {
    try {
      this.nativePtr = maplibre.CircleLayer.create(layerId, sourceId);
    } catch (error) {
      console.error(`Failed to initialize CircleLayer: ${error}`);
    }
  }

  /**
   * 设置源图层
   */
  public withSourceLayer(sourceLayer: string): CircleLayer {
    this.setSourceLayer(sourceLayer);
    return this;
  }

  /**
   * 设置过滤器
   */
  public withFilter(filter: Object): CircleLayer {
    this.setFilter(filter);
    return this;
  }

  /**
   * 设置圆形半径
   */
  public setCircleRadius(radius: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.CircleLayer.setCircleRadius(this.nativePtr, radius);
    } catch (error) {
      console.error(`Failed to set circle radius: ${error}`);
    }
  }

  /**
   * 设置圆形颜色
   */
  public setCircleColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.CircleLayer.setCircleColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set circle color: ${error}`);
    }
  }

  /**
   * 设置圆形透明度
   */
  public setCircleOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.CircleLayer.setCircleOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set circle opacity: ${error}`);
    }
  }

  /**
   * 设置圆形模糊
   */
  public setCircleBlur(blur: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.CircleLayer.setCircleBlur(this.nativePtr, blur);
    } catch (error) {
      console.error(`Failed to set circle blur: ${error}`);
    }
  }

  /**
   * 设置圆形边框宽度
   */
  public setCircleStrokeWidth(width: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.CircleLayer.setCircleStrokeWidth(this.nativePtr, width);
    } catch (error) {
      console.error(`Failed to set circle stroke width: ${error}`);
    }
  }

  /**
   * 设置圆形边框颜色
   */
  public setCircleStrokeColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.CircleLayer.setCircleStrokeColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set circle stroke color: ${error}`);
    }
  }

  /**
   * 设置圆形边框透明度
   */
  public setCircleStrokeOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.CircleLayer.setCircleStrokeOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set circle stroke opacity: ${error}`);
    }
  }

  /**
   * 链式调用 - 设置圆形半径
   */
  public withCircleRadius(radius: number): CircleLayer {
    this.setCircleRadius(radius);
    return this;
  }

  /**
   * 链式调用 - 设置圆形颜色
   */
  public withCircleColor(color: string): CircleLayer {
    this.setCircleColor(color);
    return this;
  }

  /**
   * 链式调用 - 设置圆形透明度
   */
  public withCircleOpacity(opacity: number): CircleLayer {
    this.setCircleOpacity(opacity);
    return this;
  }

  /**
   * 链式调用 - 设置圆形边框
   */
  public withCircleStroke(width: number, color: string): CircleLayer {
    this.setCircleStrokeWidth(width);
    this.setCircleStrokeColor(color);
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
    return `CircleLayer(id=${this.id}, source=${this.source})`;
  }
}

