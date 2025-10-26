/**
 * CircleLayer - 圆形图层
 */

import { Layer } from './Layer';
import { Expression } from '../expressions/Expression';

export class CircleLayer extends Layer {
  constructor(id: string, source: string) {
    super({
      id: id,
      type: 'circle',
      source: source,
      layout: {},
      paint: {}
    });
  }
  
  public withCircleRadius(radius: number): this;
  public withCircleRadius(expression: Expression<number>): this;
  public withCircleRadius(value: number | Expression<number>): this {
    if (typeof value === 'number') {
      this.paint['circle-radius'] = value;
    } else {
      this.paint['circle-radius'] = value.toArray();
    }
    return this;
  }
  
  public withCircleColor(color: string): this;
  public withCircleColor(expression: Expression<string>): this;
  public withCircleColor(value: string | Expression<string>): this {
    if (typeof value === 'string') {
      this.paint['circle-color'] = value;
    } else {
      this.paint['circle-color'] = value.toArray();
    }
    return this;
  }
  
  public withCircleOpacity(opacity: number): this;
  public withCircleOpacity(expression: Expression<number>): this;
  public withCircleOpacity(value: number | Expression<number>): this {
    if (typeof value === 'number') {
      this.paint['circle-opacity'] = value;
    } else {
      this.paint['circle-opacity'] = value.toArray();
    }
    return this;
  }
  
  public withCircleStrokeWidth(width: number): this;
  public withCircleStrokeWidth(expression: Expression<number>): this;
  public withCircleStrokeWidth(value: number | Expression<number>): this {
    if (typeof value === 'number') {
      this.paint['circle-stroke-width'] = value;
    } else {
      this.paint['circle-stroke-width'] = value.toArray();
    }
    return this;
  }
  
  public withCircleStrokeColor(color: string): this;
  public withCircleStrokeColor(expression: Expression<string>): this;
  public withCircleStrokeColor(value: string | Expression<string>): this {
    if (typeof value === 'string') {
      this.paint['circle-stroke-color'] = value;
    } else {
      this.paint['circle-stroke-color'] = value.toArray();
    }
    return this;
  }
  
  public withCircleBlur(blur: number): this;
  public withCircleBlur(expression: Expression<number>): this;
  public withCircleBlur(value: number | Expression<number>): this {
    if (typeof value === 'number') {
      this.paint['circle-blur'] = value;
    } else {
      this.paint['circle-blur'] = value.toArray();
    }
    return this;
  }
}

