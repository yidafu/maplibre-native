/**
 * HeatmapLayer - 热力图层
 */

import { Layer } from './Layer';

export class HeatmapLayer extends Layer {
  constructor(id: string, source: string) {
    super({
      id: id,
      type: 'heatmap',
      source: source,
      layout: {},
      paint: {}
    });
  }
  
  public withHeatmapRadius(radius: number | Object): this {
    this.paint['heatmap-radius'] = radius;
    return this;
  }
  
  public withHeatmapWeight(weight: number | Object): this {
    this.paint['heatmap-weight'] = weight;
    return this;
  }
  
  public withHeatmapIntensity(intensity: number | Object): this {
    this.paint['heatmap-intensity'] = intensity;
    return this;
  }
  
  public withHeatmapColor(color: Object): this {
    this.paint['heatmap-color'] = color;
    return this;
  }
  
  public withHeatmapOpacity(opacity: number | Object): this {
    this.paint['heatmap-opacity'] = opacity;
    return this;
  }
}

