import { Layer, LayerOptions } from './Layer';
import { PropertyValue } from './PropertyValue';
import maplibre from 'libmaplibre_native.so';

/**
 * SymbolLayer - 符号图层
 * 
 * 用于渲染文本和图标
 */
export class SymbolLayer extends Layer {
  private nativePtr: number = 0;

  /**
   * 创建符号图层
   * 
   * @param layerId 图层ID
   * @param sourceId 数据源ID
   */
  constructor(layerId: string, sourceId: string) {
    super({
      id: layerId,
      type: 'symbol',
      source: sourceId
    });
    this.initialize(layerId, sourceId);
  }

  /**
   * 初始化native对象
   */
  private initialize(layerId: string, sourceId: string): void {
    try {
      this.nativePtr = maplibre.SymbolLayer.create(layerId, sourceId);
    } catch (error) {
      console.error(`Failed to initialize SymbolLayer: ${error}`);
    }
  }

  /**
   * 设置源图层
   */
  public withSourceLayer(sourceLayer: string): SymbolLayer {
    this.setSourceLayer(sourceLayer);
    return this;
  }

  /**
   * 设置过滤器
   */
  public withFilter(filter: Object): SymbolLayer {
    this.setFilter(filter);
    return this;
  }

  // Layout 属性

  /**
   * 设置图标图片
   */
  public setIconImage(iconImage: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setIconImage(this.nativePtr, iconImage);
    } catch (error) {
      console.error(`Failed to set icon image: ${error}`);
    }
  }

  /**
   * 设置图标大小
   */
  public setIconSize(size: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setIconSize(this.nativePtr, size);
    } catch (error) {
      console.error(`Failed to set icon size: ${error}`);
    }
  }

  /**
   * 设置图标旋转角度
   */
  public setIconRotate(rotate: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setIconRotate(this.nativePtr, rotate);
    } catch (error) {
      console.error(`Failed to set icon rotate: ${error}`);
    }
  }

  /**
   * 设置文本字段
   */
  public setTextField(textField: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setTextField(this.nativePtr, textField);
    } catch (error) {
      console.error(`Failed to set text field: ${error}`);
    }
  }

  /**
   * 设置文本大小
   */
  public setTextSize(size: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setTextSize(this.nativePtr, size);
    } catch (error) {
      console.error(`Failed to set text size: ${error}`);
    }
  }

  /**
   * 设置文本字体
   */
  public setTextFont(fonts: string[]): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setTextFont(this.nativePtr, fonts);
    } catch (error) {
      console.error(`Failed to set text font: ${error}`);
    }
  }

  /**
   * 设置文本偏移
   */
  public setTextOffset(offset: number[]): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setTextOffset(this.nativePtr, offset);
    } catch (error) {
      console.error(`Failed to set text offset: ${error}`);
    }
  }

  /**
   * 设置文本锚点 ("center" | "left" | "right" | "top" | "bottom" | ...)
   */
  public setTextAnchor(anchor: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setTextAnchor(this.nativePtr, anchor);
    } catch (error) {
      console.error(`Failed to set text anchor: ${error}`);
    }
  }

  // Paint 属性

  /**
   * 设置图标颜色
   */
  public setIconColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setIconColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set icon color: ${error}`);
    }
  }

  /**
   * 设置图标透明度
   */
  public setIconOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setIconOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set icon opacity: ${error}`);
    }
  }

  /**
   * 设置文本颜色
   */
  public setTextColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setTextColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set text color: ${error}`);
    }
  }

  /**
   * 设置文本透明度
   */
  public setTextOpacity(opacity: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setTextOpacity(this.nativePtr, opacity);
    } catch (error) {
      console.error(`Failed to set text opacity: ${error}`);
    }
  }

  /**
   * 设置文本光晕颜色
   */
  public setTextHaloColor(color: string): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setTextHaloColor(this.nativePtr, color);
    } catch (error) {
      console.error(`Failed to set text halo color: ${error}`);
    }
  }

  /**
   * 设置文本光晕宽度
   */
  public setTextHaloWidth(width: number): void {
    if (this.nativePtr === 0) return;
    try {
      maplibre.SymbolLayer.setTextHaloWidth(this.nativePtr, width);
    } catch (error) {
      console.error(`Failed to set text halo width: ${error}`);
    }
  }

  /**
   * 链式调用 - 设置图标
   */
  public withIcon(iconImage: string, size?: number): SymbolLayer {
    this.setIconImage(iconImage);
    if (size !== undefined) {
      this.setIconSize(size);
    }
    return this;
  }

  /**
   * 链式调用 - 设置文本
   */
  public withText(textField: string, size?: number, color?: string): SymbolLayer {
    this.setTextField(textField);
    if (size !== undefined) {
      this.setTextSize(size);
    }
    if (color !== undefined) {
      this.setTextColor(color);
    }
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
    return `SymbolLayer(id=${this.id}, source=${this.source})`;
  }
}

