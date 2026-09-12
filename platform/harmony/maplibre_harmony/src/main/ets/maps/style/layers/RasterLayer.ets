/**
 * RasterLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';

import type { PropertyValue } from '../expressions/index';

import { convertValue } from './LayerUtils';
import { LayerInternalTag, SourcedLayer, resolveLayerNative } from './BaseLayer';

export class RasterLayer extends SourcedLayer<maplibre.RasterLayer, RasterLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'RasterLayer';

  constructor(idOrMarker: string | LayerInternalTag, sourceId: string = "", nativeOrNothing?: maplibre.RasterLayer) {
    super(resolveLayerNative(idOrMarker, sourceId, nativeOrNothing, (id, sid) => new maplibre.RasterLayer(id, sid), "RasterLayer"));
  }

  static create(id: string, sourceId: string = ""): RasterLayer {
    return new RasterLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.RasterLayer): RasterLayer {
    return new RasterLayer(LayerInternalTag.INSTANCE, "", nativeInstance);
  }

  // ========== Raster style property helpers ==========

  setRasterOpacity(opacity: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterOpacity(convertValue(opacity));
    return this;
  }

  setRasterHueRotate(hueRotate: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterHueRotate(convertValue(hueRotate));
    return this;
  }

  setRasterBrightnessMin(brightnessMin: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterBrightnessMin(convertValue(brightnessMin));
    return this;
  }

  setRasterBrightnessMax(brightnessMax: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterBrightnessMax(convertValue(brightnessMax));
    return this;
  }

  setRasterSaturation(saturation: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterSaturation(convertValue(saturation));
    return this;
  }

  setRasterContrast(contrast: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterContrast(convertValue(contrast));
    return this;
  }

  setRasterResampling(resampling: PropertyValue<string>): RasterLayer {
    this.nativeInstance.setRasterResampling(convertValue(resampling));
    return this;
  }

  setRasterFadeDuration(duration: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterFadeDuration(convertValue(duration));
    return this;
  }

  getRasterFadeDuration(): number | undefined {
    return this.nativeInstance.getRasterFadeDuration();
  }

  getRasterResampling(): string | undefined {
    return this.nativeInstance.getRasterResampling();
  }

}
