import { Layer, LayerOptions } from './Layer';
import { Expression } from '../expressions/Expression';
import maplibre from 'libmaplibre_native.so';

/**
 * SymbolLayer - 符号图层
 * 
 * 用于显示图标和文本标签
 * 支持 Expression 数据驱动样式
 * 
 * @see https://maplibre.org/maplibre-style-spec/#layers-symbol
 */
export class SymbolLayer extends Layer {
  private nativeLayer: maplibre.SymbolLayer | null = null;

  /**
   * 创建一个新的 SymbolLayer
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
    
    try {
      this.nativeLayer = new maplibre.SymbolLayer(layerId, sourceId);
      console.info(`SymbolLayer created: ${layerId}`);
    } catch (error) {
      console.error(`Failed to create SymbolLayer: ${error}`);
    }
  }

  /**
   * 获取 Native 层对象
   */
  public getNativeLayer(): maplibre.SymbolLayer | null {
    return this.nativeLayer;
  }

  // ==================== 基本方法 ====================

  /**
   * 获取图层ID
   */
  public override getId(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getId();
    }
    return this.id;
  }

  /**
   * 获取图层类型
   */
  public override getType(): string {
    return 'symbol';
  }

  /**
   * 获取数据源ID
   */
  public override getSource(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getSourceId();
    }
    return this.source;
  }

  /**
   * 设置源图层（用于矢量瓦片）
   */
  public override setSourceLayer(sourceLayer: string | null): void {
    super.setSourceLayer(sourceLayer);
    if (this.nativeLayer && sourceLayer) {
      this.nativeLayer.setSourceLayer(sourceLayer);
    }
  }

  /**
   * 设置最小缩放级别
   */
  public override setMinZoom(minZoom: number | null): void {
    super.setMinZoom(minZoom);
    if (this.nativeLayer && minZoom !== null) {
      this.nativeLayer.setMinZoom(minZoom);
    }
  }

  /**
   * 设置最大缩放级别
   */
  public override setMaxZoom(maxZoom: number | null): void {
    super.setMaxZoom(maxZoom);
    if (this.nativeLayer && maxZoom !== null) {
      this.nativeLayer.setMaxZoom(maxZoom);
    }
  }

  // ==================== 图标布局属性 ====================

  /**
   * 设置图标图片名称（字符串）
   * 
   * @param iconImage 图片名称（必须先通过 Style.addImage() 添加）
   */
  public setIconImage(iconImage: string): this;
  
  /**
   * 设置图标图片名称（Expression）
   * 
   * @param expression 图片名称表达式
   */
  public setIconImage(expression: Expression<string>): this;
  
  public setIconImage(value: string | Expression<string>): this {
    if (this.nativeLayer) {
      if (typeof value === 'string') {
        this.nativeLayer.setIconImage(value);
      } else {
        // Expression 需要转换为 JSON 数组格式传给 native 层
        this.nativeLayer.setIconImageExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取图标图片名称
   */
  public getIconImage(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconImage();
    }
    return '';
  }

  /**
   * 设置图标大小（数字）
   * 
   * @param size 缩放比例（1.0 表示原始大小）
   */
  public setIconSize(size: number): this;
  
  /**
   * 设置图标大小（Expression）
   * 
   * @param expression 大小表达式
   */
  public setIconSize(expression: Expression<number>): this;
  
  public setIconSize(value: number | Expression<number>): this {
    if (this.nativeLayer) {
      if (typeof value === 'number') {
        this.nativeLayer.setIconSize(value);
      } else {
        this.nativeLayer.setIconSizeExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取图标大小
   */
  public getIconSize(): number {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconSize();
    }
    return 1.0;
  }

  /**
   * 设置图标旋转角度（数字）
   * 
   * @param rotate 旋转角度（度）
   */
  public setIconRotate(rotate: number): this;
  
  /**
   * 设置图标旋转角度（Expression）
   * 
   * @param expression 旋转角度表达式
   */
  public setIconRotate(expression: Expression<number>): this;
  
  public setIconRotate(value: number | Expression<number>): this {
    if (this.nativeLayer) {
      if (typeof value === 'number') {
        this.nativeLayer.setIconRotate(value);
      } else {
        this.nativeLayer.setIconRotateExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取图标旋转角度
   */
  public getIconRotate(): number {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconRotate();
    }
    return 0;
  }

  /**
   * 设置图标偏移
   * 
   * @param offsetX X方向偏移（像素）
   * @param offsetY Y方向偏移（像素）
   */
  public setIconOffset(offsetX: number, offsetY: number): this {
    if (this.nativeLayer) {
      this.nativeLayer.setIconOffset(offsetX, offsetY);
    }
    return this;
  }

  /**
   * 获取图标偏移
   */
  public getIconOffset(): number[] {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconOffset();
    }
    return [0, 0];
  }

  /**
   * 设置图标锚点
   * 
   * @param anchor 锚点位置：'center' | 'left' | 'right' | 'top' | 'bottom' | 
   *               'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
   */
  public setIconAnchor(anchor: string): this {
    if (this.nativeLayer) {
      this.nativeLayer.setIconAnchor(anchor);
    }
    return this;
  }

  /**
   * 获取图标锚点
   */
  public getIconAnchor(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconAnchor();
    }
    return 'center';
  }

  /**
   * 设置图标是否允许重叠
   * 
   * @param allow true 允许重叠，false 避免重叠
   */
  public setIconAllowOverlap(allow: boolean): this {
    if (this.nativeLayer) {
      this.nativeLayer.setIconAllowOverlap(allow);
    }
    return this;
  }

  /**
   * 获取图标是否允许重叠
   */
  public getIconAllowOverlap(): boolean {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconAllowOverlap();
    }
    return false;
  }

  // ==================== 文本布局属性 ====================

  /**
   * 设置文本内容（字符串）
   * 
   * @param text 文本内容（支持 {property} 占位符）
   */
  public setTextField(text: string): this;
  
  /**
   * 设置文本内容（Expression）
   * 
   * @param expression 文本表达式
   */
  public setTextField(expression: Expression<string>): this;
  
  public setTextField(value: string | Expression<string>): this {
    if (this.nativeLayer) {
      if (typeof value === 'string') {
        this.nativeLayer.setTextField(value);
      } else {
        this.nativeLayer.setTextFieldExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取文本内容
   */
  public getTextField(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextField();
    }
    return '';
  }

  /**
   * 设置文本字体
   * 
   * @param font 字体名称
   */
  public setTextFont(font: string): this {
    if (this.nativeLayer) {
      this.nativeLayer.setTextFont(font);
    }
    return this;
  }

  /**
   * 获取文本字体
   */
  public getTextFont(): string[] {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextFont();
    }
    return [];
  }

  /**
   * 设置文本大小（数字）
   * 
   * @param size 字体大小（像素）
   */
  public setTextSize(size: number): this;
  
  /**
   * 设置文本大小（Expression）
   * 
   * @param expression 字体大小表达式
   */
  public setTextSize(expression: Expression<number>): this;
  
  public setTextSize(value: number | Expression<number>): this {
    if (this.nativeLayer) {
      if (typeof value === 'number') {
        this.nativeLayer.setTextSize(value);
      } else {
        this.nativeLayer.setTextSizeExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取文本大小
   */
  public getTextSize(): number {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextSize();
    }
    return 16;
  }

  /**
   * 设置文本最大宽度
   * 
   * @param maxWidth 最大宽度（em）
   */
  public setTextMaxWidth(maxWidth: number): this {
    if (this.nativeLayer) {
      this.nativeLayer.setTextMaxWidth(maxWidth);
    }
    return this;
  }

  /**
   * 获取文本最大宽度
   */
  public getTextMaxWidth(): number {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextMaxWidth();
    }
    return 10;
  }

  /**
   * 设置文本偏移
   * 
   * @param offsetX X方向偏移（em）
   * @param offsetY Y方向偏移（em）
   */
  public setTextOffset(offsetX: number, offsetY: number): this {
    if (this.nativeLayer) {
      this.nativeLayer.setTextOffset(offsetX, offsetY);
    }
    return this;
  }

  /**
   * 获取文本偏移
   */
  public getTextOffset(): number[] {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextOffset();
    }
    return [0, 0];
  }

  /**
   * 设置文本锚点
   * 
   * @param anchor 锚点位置
   */
  public setTextAnchor(anchor: string): this {
    if (this.nativeLayer) {
      this.nativeLayer.setTextAnchor(anchor);
    }
    return this;
  }

  /**
   * 获取文本锚点
   */
  public getTextAnchor(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextAnchor();
    }
    return 'center';
  }

  /**
   * 设置文本是否允许重叠
   * 
   * @param allow true 允许重叠，false 避免重叠
   */
  public setTextAllowOverlap(allow: boolean): this {
    if (this.nativeLayer) {
      this.nativeLayer.setTextAllowOverlap(allow);
    }
    return this;
  }

  /**
   * 获取文本是否允许重叠
   */
  public getTextAllowOverlap(): boolean {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextAllowOverlap();
    }
    return false;
  }

  // ==================== 图标绘制属性 ====================

  /**
   * 设置图标不透明度（数字）
   * 
   * @param opacity 不透明度（0-1）
   */
  public setIconOpacity(opacity: number): this;
  
  /**
   * 设置图标不透明度（Expression）
   * 
   * @param expression 不透明度表达式
   */
  public setIconOpacity(expression: Expression<number>): this;
  
  public setIconOpacity(value: number | Expression<number>): this {
    if (this.nativeLayer) {
      if (typeof value === 'number') {
        this.nativeLayer.setIconOpacity(value);
      } else {
        this.nativeLayer.setIconOpacityExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取图标不透明度
   */
  public getIconOpacity(): number {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconOpacity();
    }
    return 1.0;
  }

  /**
   * 设置图标颜色（字符串）
   * 
   * @param color 颜色值（如 '#FF0000'）
   */
  public setIconColor(color: string): this;
  
  /**
   * 设置图标颜色（Expression）
   * 
   * @param expression 颜色表达式
   */
  public setIconColor(expression: Expression<string>): this;
  
  public setIconColor(value: string | Expression<string>): this {
    if (this.nativeLayer) {
      if (typeof value === 'string') {
        this.nativeLayer.setIconColor(value);
      } else {
        this.nativeLayer.setIconColorExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取图标颜色
   */
  public getIconColor(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconColor();
    }
    return '#000000';
  }

  /**
   * 设置图标光晕颜色
   * 
   * @param color 颜色值
   */
  public setIconHaloColor(color: string): this {
    if (this.nativeLayer) {
      this.nativeLayer.setIconHaloColor(color);
    }
    return this;
  }

  /**
   * 获取图标光晕颜色
   */
  public getIconHaloColor(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconHaloColor();
    }
    return '#000000';
  }

  /**
   * 设置图标光晕宽度
   * 
   * @param width 宽度（像素）
   */
  public setIconHaloWidth(width: number): this {
    if (this.nativeLayer) {
      this.nativeLayer.setIconHaloWidth(width);
    }
    return this;
  }

  /**
   * 获取图标光晕宽度
   */
  public getIconHaloWidth(): number {
    if (this.nativeLayer) {
      return this.nativeLayer.getIconHaloWidth();
    }
    return 0;
  }

  // ==================== 文本绘制属性 ====================

  /**
   * 设置文本不透明度（数字）
   * 
   * @param opacity 不透明度（0-1）
   */
  public setTextOpacity(opacity: number): this;
  
  /**
   * 设置文本不透明度（Expression）
   * 
   * @param expression 不透明度表达式
   */
  public setTextOpacity(expression: Expression<number>): this;
  
  public setTextOpacity(value: number | Expression<number>): this {
    if (this.nativeLayer) {
      if (typeof value === 'number') {
        this.nativeLayer.setTextOpacity(value);
      } else {
        this.nativeLayer.setTextOpacityExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取文本不透明度
   */
  public getTextOpacity(): number {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextOpacity();
    }
    return 1.0;
  }

  /**
   * 设置文本颜色（字符串）
   * 
   * @param color 颜色值（如 '#000000'）
   */
  public setTextColor(color: string): this;
  
  /**
   * 设置文本颜色（Expression）
   * 
   * @param expression 颜色表达式
   */
  public setTextColor(expression: Expression<string>): this;
  
  public setTextColor(value: string | Expression<string>): this {
    if (this.nativeLayer) {
      if (typeof value === 'string') {
        this.nativeLayer.setTextColor(value);
      } else {
        this.nativeLayer.setTextColorExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取文本颜色
   */
  public getTextColor(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextColor();
    }
    return '#000000';
  }

  /**
   * 设置文本光晕颜色（字符串）
   * 
   * @param color 颜色值
   */
  public setTextHaloColor(color: string): this;
  
  /**
   * 设置文本光晕颜色（Expression）
   * 
   * @param expression 颜色表达式
   */
  public setTextHaloColor(expression: Expression<string>): this;
  
  public setTextHaloColor(value: string | Expression<string>): this {
    if (this.nativeLayer) {
      if (typeof value === 'string') {
        this.nativeLayer.setTextHaloColor(value);
      } else {
        this.nativeLayer.setTextHaloColorExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取文本光晕颜色
   */
  public getTextHaloColor(): string {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextHaloColor();
    }
    return '#000000';
  }

  /**
   * 设置文本光晕宽度（数字）
   * 
   * @param width 宽度（像素）
   */
  public setTextHaloWidth(width: number): this;
  
  /**
   * 设置文本光晕宽度（Expression）
   * 
   * @param expression 宽度表达式
   */
  public setTextHaloWidth(expression: Expression<number>): this;
  
  public setTextHaloWidth(value: number | Expression<number>): this {
    if (this.nativeLayer) {
      if (typeof value === 'number') {
        this.nativeLayer.setTextHaloWidth(value);
      } else {
        this.nativeLayer.setTextHaloWidthExpression(JSON.stringify(value.toArray()));
      }
    }
    return this;
  }

  /**
   * 获取文本光晕宽度
   */
  public getTextHaloWidth(): number {
    if (this.nativeLayer) {
      return this.nativeLayer.getTextHaloWidth();
    }
    return 0;
  }

  // ==================== 辅助方法 ====================

  /**
   * 转换为JSON
   */
  public override toJSON(): ESObject {
    const obj = super.toJSON();
    obj['type'] = 'symbol';
    
    // TODO: 添加所有属性到 JSON
    
    return obj;
  }

  /**
   * 转换为字符串
   */
  public override toString(): string {
    return `SymbolLayer(id=${this.id}, source=${this.source})`;
  }
}
