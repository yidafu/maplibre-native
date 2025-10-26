import { Layer, LayerOptions } from './Layer';
import { PropertyValue } from './PropertyValue';
import maplibre from 'libmaplibre_native.so';

/**
 * HillshadeLayer - 山体阴影图层
 * 
 * 用于显示地形山体阴影效果
 */
export class HillshadeLayer extends Layer {
  private nativePtr: number = 0;

  /**
   * 创建山体阴影图层
   * 
   * @param layerId 图层ID
   * @param sourceId 数据源ID (通常是raster-dem类型)
   */
  constructor(layerId: string, sourceId: string) {
    super({
      id: layerId,
      type: 'hillshade',
      source: sourceId
    });
    this.initialize(layerId, sourceId);
  }

  /**
   * 初始化native对象
   */
  private initialize(layerId: string, sourceId: string): void {
    try {
      this.nativePtr = maplibre.HillshadeLayer.create(layerId, sourceId);
    } catch (error) {
      console.error(`Failed to initialize HillshadeLayer: ${error}`);
    }
  }

  /**
   * 设置光照方向（度数，0-359）
   */
  public setHillshadeIlluminationDirection(direction: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HillshadeLayer.setHillshadeIlluminationDirection(this.nativePtr, direction);
    } catch (error) {
      console.error(`Failed to set hillshade illumination direction: ${error}`);
    }
  }

  /**
   * 设置光照锚点 ("map" | "viewport")
   */
  public setHillshadeIlluminationAnchor(anchor: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HillshadeLayer.setHillshadeIlluminationAnchor(this.nativePtr, anchor as 'map' | 'viewport');
    } catch (error) {
      console.error(`Failed to set hillshade illumination anchor: ${error}`);
    }
  }

  /**
   * 设置地形夸张程度
   */
  public setHillshadeExaggeration(exaggeration: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HillshadeLayer.setHillshadeExaggeration(this.nativePtr, exaggeration);
    } catch (error) {
      console.error(`Failed to set hillshade exaggeration: ${error}`);
    }
  }

  /**
   * 设置阴影颜色
   */
  public setHillshadeShadowColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HillshadeLayer.setHillshadeShadowColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set hillshade shadow color: ${error}`);
    }
  }

  /**
   * 设置高光颜色
   */
  public setHillshadeHighlightColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HillshadeLayer.setHillshadeHighlightColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set hillshade highlight color: ${error}`);
    }
  }

  /**
   * 设置强调颜色
   */
  public setHillshadeAccentColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.HillshadeLayer.setHillshadeAccentColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set hillshade accent color: ${error}`);
    }
  }

  /**
   * 链式调用 - 设置光照方向
   */
  public withHillshadeIlluminationDirection(direction: number): HillshadeLayer {
    this.setHillshadeIlluminationDirection(direction);
    return this;
  }

  /**
   * 链式调用 - 设置地形夸张程度
   */
  public withHillshadeExaggeration(exaggeration: number): HillshadeLayer {
    this.setHillshadeExaggeration(exaggeration);
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
    return `HillshadeLayer(id=${this.id}, source=${this.source})`;
  }
}

