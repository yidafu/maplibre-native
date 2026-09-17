/**
 * HeatmapLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';

import type { ExpressionLiteral } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';

import { convertValue } from './LayerUtils';
import { LayerInternalTag, SourcedLayer, resolveLayerNative } from './BaseLayer';

export class HeatmapLayer extends SourcedLayer<maplibre.HeatmapLayer, HeatmapLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'HeatmapLayer';

  constructor(idOrMarker: string | LayerInternalTag, sourceId: string = "", nativeOrNothing?: maplibre.HeatmapLayer) {
    super(resolveLayerNative(idOrMarker, sourceId, nativeOrNothing, (id, sid) => new maplibre.HeatmapLayer(id, sid), "HeatmapLayer"));
  }

  static create(id: string, sourceId: string = ""): HeatmapLayer {
    return new HeatmapLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.HeatmapLayer): HeatmapLayer {
    return new HeatmapLayer(LayerInternalTag.INSTANCE, "", nativeInstance);
  }

  // ========== Heatmap style property helpers ==========

  setHeatmapRadius(radius: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapRadius(convertValue(radius));
    return this;
  }

  setHeatmapWeight(weight: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapWeight(convertValue(weight));
    return this;
  }

  setHeatmapIntensity(intensity: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapIntensity(convertValue(intensity));
    return this;
  }

  setHeatmapColor(color: PropertyValue<string>): HeatmapLayer {
    this.nativeInstance.setHeatmapColor(convertValue(color) as ExpressionLiteral);
    return this;
  }

  getHeatmapColor(): ExpressionLiteral | undefined {
    return this.nativeInstance.getHeatmapColor();
  }

  setHeatmapOpacity(opacity: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapOpacity(convertValue(opacity));
    return this;
  }

}
