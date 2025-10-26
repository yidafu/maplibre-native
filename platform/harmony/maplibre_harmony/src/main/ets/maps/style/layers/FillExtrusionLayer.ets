/**
 * FillExtrusionLayer - 3D 填充拉伸图层
 */

import { Layer } from './Layer';

export class FillExtrusionLayer extends Layer {
  constructor(id: string, source: string) {
    super({
      id: id,
      type: 'fill-extrusion',
      source: source,
      layout: {},
      paint: {}
    });
  }
  
  public withFillExtrusionOpacity(opacity: number | Object): this {
    this.paint['fill-extrusion-opacity'] = opacity;
    return this;
  }
  
  public withFillExtrusionColor(color: string | Object): this {
    this.paint['fill-extrusion-color'] = color;
    return this;
  }
  
  public withFillExtrusionHeight(height: number | Object): this {
    this.paint['fill-extrusion-height'] = height;
    return this;
  }
  
  public withFillExtrusionBase(base: number | Object): this {
    this.paint['fill-extrusion-base'] = base;
    return this;
  }
  
  public withFillExtrusionVerticalGradient(enabled: boolean): this {
    this.paint['fill-extrusion-vertical-gradient'] = enabled;
    return this;
  }
}

