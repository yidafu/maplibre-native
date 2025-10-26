/**
 * FillLayer - 填充图层
 * 
 * 支持 Expression 数据驱动样式
 */

import { Layer } from './Layer';
import { Expression } from '../expressions/Expression';

export class FillLayer extends Layer {
  constructor(id: string, source: string) {
    super({
      id: id,
      type: 'fill',
      source: source,
      layout: {},
      paint: {}
    });
  }
  
  /**
   * 设置填充颜色（字符串）
   */
  public withFillColor(color: string): this;
  
  /**
   * 设置填充颜色（Expression）
   */
  public withFillColor(expression: Expression<string>): this;
  
  public withFillColor(value: string | Expression<string>): this {
    if (typeof value === 'string') {
      this.paint['fill-color'] = value;
    } else {
      this.paint['fill-color'] = value.toArray();
    }
    return this;
  }
  
  /**
   * 设置填充透明度（数字）
   */
  public withFillOpacity(opacity: number): this;
  
  /**
   * 设置填充透明度（Expression）
   */
  public withFillOpacity(expression: Expression<number>): this;
  
  public withFillOpacity(value: number | Expression<number>): this {
    if (typeof value === 'number') {
      this.paint['fill-opacity'] = value;
    } else {
      this.paint['fill-opacity'] = value.toArray();
    }
    return this;
  }
  
  /**
   * 设置填充轮廓颜色（字符串）
   */
  public withFillOutlineColor(color: string): this;
  
  /**
   * 设置填充轮廓颜色（Expression）
   */
  public withFillOutlineColor(expression: Expression<string>): this;
  
  public withFillOutlineColor(value: string | Expression<string>): this {
    if (typeof value === 'string') {
      this.paint['fill-outline-color'] = value;
    } else {
      this.paint['fill-outline-color'] = value.toArray();
    }
    return this;
  }
  
  /**
   * 设置填充图案（字符串）
   */
  public withFillPattern(pattern: string): this;
  
  /**
   * 设置填充图案（Expression）
   */
  public withFillPattern(expression: Expression<string>): this;
  
  public withFillPattern(value: string | Expression<string>): this {
    if (typeof value === 'string') {
      this.paint['fill-pattern'] = value;
    } else {
      this.paint['fill-pattern'] = value.toArray();
    }
    return this;
  }
}

