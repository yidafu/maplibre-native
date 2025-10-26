/**
 * HillshadeLayer - 山体阴影图层
 */

import { Layer } from './Layer';

export class HillshadeLayer extends Layer {
  constructor(id: string, source: string) {
    super({
      id: id,
      type: 'hillshade',
      source: source,
      layout: {},
      paint: {}
    });
  }
  
  public withHillshadeIlluminationDirection(direction: number): this {
    this.paint['hillshade-illumination-direction'] = direction;
    return this;
  }
  
  public withHillshadeIlluminationAnchor(anchor: string): this {
    this.paint['hillshade-illumination-anchor'] = anchor;
    return this;
  }
  
  public withHillshadeExaggeration(exaggeration: number): this {
    this.paint['hillshade-exaggeration'] = exaggeration;
    return this;
  }
  
  public withHillshadeShadowColor(color: string): this {
    this.paint['hillshade-shadow-color'] = color;
    return this;
  }
  
  public withHillshadeHighlightColor(color: string): this {
    this.paint['hillshade-highlight-color'] = color;
    return this;
  }
  
  public withHillshadeAccentColor(color: string): this {
    this.paint['hillshade-accent-color'] = color;
    return this;
  }
}

