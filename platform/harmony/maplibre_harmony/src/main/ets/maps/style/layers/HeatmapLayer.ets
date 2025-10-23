import { Layer, LayerOptions } from './Layer';
import { PropertyValue } from './PropertyValue';
import maplibre from 'libmaplibre_native.so';

/**
 * HeatmapLayer - 热力图图层
 * 
 * 用于显示密度热力图
 */
export class HeatmapLayer extends Layer {
  private nativePtr: number = 0;

  /**
   * 创建热力图图层
   * 
   * @param layerId 图层ID
   * @param sourceId 数据源ID
   */
  constructor(layerId: string, sourceId: string) {
    super({
      id: layerId,
      type: 'heatmap',
      source: sourceId
    });
    this.initialize(layerId, sourceId);
  }

  /**
   * 初始化native对象
   */
  private initialize(layerId: string, sourceId: string): void {
    try {
      this.nativePtr = maplibre.HeatmapLayer.create(layerId, sourceId);
    } catch (error) {
      console.error(`Failed to initialize HeatmapLayer: ${error}`);
    }
  }

  /**
   * 设置源图层
   */
  public withSourceLayer(sourceLayer: string): HeatmapLayer {
    this.setSourceLayer(sourceLayer);
    return this;
  }

  /**
   * 设置过滤器
   */
  public withFilter(filter: Object): HeatmapLayer {
    this.setFilter(filter);
    return this;
  }

  /**
   * 设置热力图权重
   */
  public setHeatmapWeight(weight: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HeatmapLayer.setHeatmapWeight(this.nativePtr, weight);
    } catch (error) {
      console.error(`Failed to set heatmap weight: ${error}`);
    }
  }

  /**
   * 设置热力图强度
   */
  public setHeatmapIntensity(intensity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HeatmapLayer.setHeatmapIntensity(this.nativePtr, intensity);
    } catch (error) {
      console.error(`Failed to set heatmap intensity: ${error}`);
    }
  }

  /**
   * 设置热力图颜色（使用渐变表达式）
   */
  public setHeatmapColor(colorExpression: Object): void {
    if (this.nativePtr === 0) return;
    try {
      const colorJson = JSON.stringify(colorExpression);
      maplibre.HeatmapLayer.setHeatmapColor(this.nativePtr, colorJson);
    } catch (error) {
      console.error(`Failed to set heatmap color: ${error}`);
    }
  }

  /**
   * 设置热力图半径
   */
  public setHeatmapRadius(radius: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HeatmapLayer.setHeatmapRadius(this.nativePtr, radius);
    } catch (error) {
      console.error(`Failed to set heatmap radius: ${error}`);
    }
  }

  /**
   * 设置热力图透明度
   */
  public setHeatmapOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HeatmapLayer.setHeatmapOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set heatmap opacity: ${error}`);
    }
  }

  /**
   * 链式调用 - 设置热力图半径
   */
  public withHeatmapRadius(radius: number): HeatmapLayer {
    this.setHeatmapRadius(radius);
    return this;
  }

  /**
   * 链式调用 - 设置热力图强度
   */
  public withHeatmapIntensity(intensity: number): HeatmapLayer {
    this.setHeatmapIntensity(intensity);
    return this;
  }

  /**
   * 链式调用 - 设置热力图透明度
   */
  public withHeatmapOpacity(opacity: number): HeatmapLayer {
    this.setHeatmapOpacity(opacity);
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
    return `HeatmapLayer(id=${this.id}, source=${this.source})`;
  }
}

