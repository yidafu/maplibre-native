/**
 * RasterLayer - 栅格图层
 */

import { Layer } from './Layer';

export class RasterLayer extends Layer {
  constructor(id: string, source: string) {
    super({
      id: id,
      type: 'raster',
      source: source,
      layout: {},
      paint: {}
    });
  }
  
  public withRasterOpacity(opacity: number | Object): this {
    this.paint['raster-opacity'] = opacity;
    return this;
  }
  
  public withRasterHueRotate(degrees: number | Object): this {
    this.paint['raster-hue-rotate'] = degrees;
    return this;
  }
  
  public withRasterBrightnessMin(brightness: number | Object): this {
    this.paint['raster-brightness-min'] = brightness;
    return this;
  }
  
  public withRasterBrightnessMax(brightness: number | Object): this {
    this.paint['raster-brightness-max'] = brightness;
    return this;
  }
  
  public withRasterSaturation(saturation: number | Object): this {
    this.paint['raster-saturation'] = saturation;
    return this;
  }
  
  public withRasterContrast(contrast: number | Object): this {
    this.paint['raster-contrast'] = contrast;
    return this;
  }
}

