/**
 * BackgroundLayer - 背景图层
 */

import { Layer } from './Layer';

export class BackgroundLayer extends Layer {
  constructor(id: string) {
    super({
      id: id,
      type: 'background',
      source: '', // Background layer 不需要 source
      layout: {},
      paint: {}
    });
  }
  
  public withBackgroundColor(color: string | Object): this {
    this.paint['background-color'] = color;
    return this;
  }
  
  public withBackgroundOpacity(opacity: number | Object): this {
    this.paint['background-opacity'] = opacity;
    return this;
  }
  
  public withBackgroundPattern(pattern: string | Object): this {
    this.paint['background-pattern'] = pattern;
    return this;
  }
}

