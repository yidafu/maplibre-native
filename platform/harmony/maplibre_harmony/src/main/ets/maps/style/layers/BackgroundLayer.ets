import { Layer, LayerOptions } from './Layer';
import { PropertyValue } from './PropertyValue';
import maplibre from 'libmaplibre_native.so';

/**
 * BackgroundLayer - 背景图层
 * 
 * 用于设置地图背景色或图案
 */
export class BackgroundLayer extends Layer {
  private nativePtr: number = 0;

  /**
   * 创建背景图层
   * 
   * @param layerId 图层ID
   */
  constructor(layerId: string) {
    super({
      id: layerId,
      type: 'background',
      source: '' // 背景图层不需要数据源
    });
    this.initialize(layerId);
  }

  /**
   * 初始化native对象
   */
  private initialize(layerId: string): void {
    try {
      this.nativePtr = maplibre.BackgroundLayer.create(layerId);
    } catch (error) {
      console.error(`Failed to initialize BackgroundLayer: ${error}`);
    }
  }

  /**
   * 设置背景颜色
   */
  public setBackgroundColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.BackgroundLayer.setBackgroundColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set background color: ${error}`);
    }
  }

  /**
   * 设置背景透明度
   */
  public setBackgroundOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.BackgroundLayer.setBackgroundOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set background opacity: ${error}`);
    }
  }

  /**
   * 设置背景图案
   */
  public setBackgroundPattern(pattern: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.BackgroundLayer.setBackgroundPattern(this.nativePtr, pattern);
    } catch (error) {
      console.error(`Failed to set background pattern: ${error}`);
    }
  }

  /**
   * 链式调用 - 设置背景颜色
   */
  public withBackgroundColor(color: string): BackgroundLayer {
    this.setBackgroundColor(color);
    return this;
  }

  /**
   * 链式调用 - 设置背景透明度
   */
  public withBackgroundOpacity(opacity: number): BackgroundLayer {
    this.setBackgroundOpacity(opacity);
    return this;
  }

  /**
   * 链式调用 - 设置背景图案
   */
  public withBackgroundPattern(pattern: string): BackgroundLayer {
    this.setBackgroundPattern(pattern);
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
    return `BackgroundLayer(id=${this.id})`;
  }
}

