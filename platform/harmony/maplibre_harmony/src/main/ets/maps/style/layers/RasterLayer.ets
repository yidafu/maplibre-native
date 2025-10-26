import { Layer, LayerOptions } from './Layer';
import { PropertyValue } from './PropertyValue';
import maplibre from 'libmaplibre_native.so';

/**
 * RasterLayer - 栅格图层
 * 
 * 用于显示栅格瓦片
 */
export class RasterLayer extends Layer {
  private nativePtr: number = 0;

  /**
   * 创建栅格图层
   * 
   * @param layerId 图层ID
   * @param sourceId 数据源ID
   */
  constructor(layerId: string, sourceId: string) {
    super({
      id: layerId,
      type: 'raster',
      source: sourceId
    });
    this.initialize(layerId, sourceId);
  }

  /**
   * 初始化native对象
   */
  private initialize(layerId: string, sourceId: string): void {
    try {
      this.nativePtr = maplibre.RasterLayer.create(layerId, sourceId);
    } catch (error) {
      console.error(`Failed to initialize RasterLayer: ${error}`);
    }
  }

  /**
   * 设置栅格透明度
   */
  public setRasterOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.RasterLayer.setRasterOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set raster opacity: ${error}`);
    }
  }

  /**
   * 设置栅格色相旋转
   */
  public setRasterHueRotate(hueRotate: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.RasterLayer.setRasterHueRotate(this.nativePtr, hueRotate);
    } catch (error) {
      console.error(`Failed to set raster hue rotate: ${error}`);
    }
  }

  /**
   * 设置栅格亮度最小值
   */
  public setRasterBrightnessMin(brightnessMin: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.RasterLayer.setRasterBrightnessMin(this.nativePtr, brightnessMin);
    } catch (error) {
      console.error(`Failed to set raster brightness min: ${error}`);
    }
  }

  /**
   * 设置栅格亮度最大值
   */
  public setRasterBrightnessMax(brightnessMax: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.RasterLayer.setRasterBrightnessMax(this.nativePtr, brightnessMax);
    } catch (error) {
      console.error(`Failed to set raster brightness max: ${error}`);
    }
  }

  /**
   * 设置栅格饱和度
   */
  public setRasterSaturation(saturation: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.RasterLayer.setRasterSaturation(this.nativePtr, saturation);
    } catch (error) {
      console.error(`Failed to set raster saturation: ${error}`);
    }
  }

  /**
   * 设置栅格对比度
   */
  public setRasterContrast(contrast: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.RasterLayer.setRasterContrast(this.nativePtr, contrast);
    } catch (error) {
      console.error(`Failed to set raster contrast: ${error}`);
    }
  }

  /**
   * 设置栅格重采样 ("linear" | "nearest")
   */
  public setRasterResampling(resampling: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.RasterLayer.setRasterResampling(this.nativePtr, resampling as 'linear' | 'nearest');
    } catch (error) {
      console.error(`Failed to set raster resampling: ${error}`);
    }
  }

  /**
   * 链式调用 - 设置透明度
   */
  public withRasterOpacity(opacity: number): RasterLayer {
    this.setRasterOpacity(opacity);
    return this;
  }

  /**
   * 链式调用 - 设置亮度范围
   */
  public withRasterBrightness(min: number, max: number): RasterLayer {
    this.setRasterBrightnessMin(min);
    this.setRasterBrightnessMax(max);
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
    return `RasterLayer(id=${this.id}, source=${this.source})`;
  }
}

