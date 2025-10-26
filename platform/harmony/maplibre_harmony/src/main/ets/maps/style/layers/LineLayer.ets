/**
 * LineLayer - 线条图层
 * 
 * 支持 Expression 数据驱动样式
 */

import { Layer } from './Layer';
import { Expression } from '../expressions/Expression';

export class LineLayer extends Layer {
  constructor(id: string, source: string) {
    super({
      id: id,
      type: 'line',
      source: source,
      layout: {},
      paint: {}
    });
  }
  
  /**
   * 设置线条颜色（字符串）
   */
  public withLineColor(color: string): this;
  
  /**
   * 设置线条颜色（Expression）
   */
  public withLineColor(expression: Expression<string>): this;
  
  public withLineColor(value: string | Expression<string>): this {
    if (typeof value === 'string') {
      this.paint['line-color'] = value;
    } else {
      this.paint['line-color'] = value.toArray();
    }
    return this;
  }
  
  /**
   * 设置线条宽度（数字）
   */
  public withLineWidth(width: number): this;
  
  /**
   * 设置线条宽度（Expression）
   */
  public withLineWidth(expression: Expression<number>): this;
  
  public withLineWidth(value: number | Expression<number>): this {
    if (typeof value === 'number') {
      this.paint['line-width'] = value;
    } else {
      this.paint['line-width'] = value.toArray();
    }
    return this;
  }
  
  /**
   * 设置线条透明度（数字）
   */
  public withLineOpacity(opacity: number): this;
  
  /**
   * 设置线条透明度（Expression）
   */
  public withLineOpacity(expression: Expression<number>): this;
  
  public withLineOpacity(value: number | Expression<number>): this {
    if (typeof value === 'number') {
      this.paint['line-opacity'] = value;
    } else {
      this.paint['line-opacity'] = value.toArray();
    }
    return this;
  }
  
  /**
   * 设置线条间隙宽度（数字）
   */
  public withLineGapWidth(gapWidth: number): this;
  
  /**
   * 设置线条间隙宽度（Expression）
   */
  public withLineGapWidth(expression: Expression<number>): this;
  
  public withLineGapWidth(value: number | Expression<number>): this {
    if (typeof value === 'number') {
      this.paint['line-gap-width'] = value;
    } else {
      this.paint['line-gap-width'] = value.toArray();
    }
    return this;
  }
  
  /**
   * 设置线条虚线数组（数组）
   */
  public withLineDasharray(dasharray: number[]): this;
  
  /**
   * 设置线条虚线数组（Expression）
   */
  public withLineDasharray(expression: Expression<number[]>): this;
  
  public withLineDasharray(value: number[] | Expression<number[]>): this {
    if (Array.isArray(value)) {
      this.paint['line-dasharray'] = value;
    } else {
      this.paint['line-dasharray'] = value.toArray();
    }
    return this;
  }
  
  /**
   * 设置线条端点样式（字符串）
   */
  public withLineCap(cap: string): this;
  
  /**
   * 设置线条端点样式（Expression）
   */
  public withLineCap(expression: Expression<string>): this;
  
  public withLineCap(value: string | Expression<string>): this {
    if (typeof value === 'string') {
      this.layout['line-cap'] = value;
    } else {
      this.layout['line-cap'] = value.toArray();
    }
    return this;
  }
  
  /**
   * 设置线条连接样式（字符串）
   */
  public withLineJoin(join: string): this;
  
  /**
   * 设置线条连接样式（Expression）
   */
  public withLineJoin(expression: Expression<string>): this;
  
  public withLineJoin(value: string | Expression<string>): this {
    if (typeof value === 'string') {
      this.layout['line-join'] = value;
    } else {
      this.layout['line-join'] = value.toArray();
    }
    return this;
  }
}

