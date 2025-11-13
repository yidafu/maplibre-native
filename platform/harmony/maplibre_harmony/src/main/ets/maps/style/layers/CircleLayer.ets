/**
 * CircleLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';
import type { PropertyValue as NativePropertyValue, JSONValue } from 'libmaplibre.so';
import type { ExpressionLiteral } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';


class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class CircleLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'CircleLayer';
  private nativeInstance: maplibre.CircleLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.CircleLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.CircleLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid CircleLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): CircleLayer {
    return new CircleLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.CircleLayer): CircleLayer {
    return new CircleLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.CircleLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getType(): string {
    return this.nativeInstance.getType();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  getSourceLayer(): string {
    return this.nativeInstance.getSourceLayer();
  }

  setVisibility(visibility: 'visible' | 'none'): CircleLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  getVisibility(): 'visible' | 'none' {
    return this.nativeInstance.getVisibility();
  }

  setMinZoom(zoom: number): CircleLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  getMinZoom(): number {
    return this.nativeInstance.getMinZoom();
  }

  setMaxZoom(zoom: number): CircleLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  getMaxZoom(): number {
    return this.nativeInstance.getMaxZoom();
  }

  /**
   * Configure the layer filter
   * @param filter Expression instance or expression literal array
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): CircleLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  getFilter(): ExpressionLiteral | null {
    return this.nativeInstance.getFilter();
  }

  setSourceLayer(sourceLayer: string): CircleLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
  }

  // ========== Circle style property helpers ==========

  setCircleRadius(radius: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleRadius(convertValue(radius));
    return this;
  }

  setCircleColor(color: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleColor(convertValue(color));
    return this;
  }

  setCircleOpacity(opacity: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleOpacity(convertValue(opacity));
    return this;
  }

  setCircleBlur(blur: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleBlur(convertValue(blur));
    return this;
  }

  setCircleStrokeWidth(width: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleStrokeWidth(convertValue(width));
    return this;
  }

  setCircleStrokeColor(color: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleStrokeColor(convertValue(color));
    return this;
  }

  setCircleStrokeOpacity(opacity: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleStrokeOpacity(convertValue(opacity));
    return this;
  }

  setCircleTranslate(translate: PropertyValue<number[]>): CircleLayer {
    this.nativeInstance.setCircleTranslate(convertValue(translate));
    return this;
  }

  setCircleTranslateAnchor(anchor: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleTranslateAnchor(convertValue(anchor));
    return this;
  }

  setCirclePitchScale(scale: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCirclePitchScale(convertValue(scale));
    return this;
  }

  setCirclePitchAlignment(alignment: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCirclePitchAlignment(convertValue(alignment));
    return this;
  }

  setCircleSortKey(sortKey: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleSortKey(convertValue(sortKey));
    return this;
  }

  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key (for example, 'circle-color', 'circle-radius')
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): CircleLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'circle-color': '#00FF00',
   *   'circle-radius': 10,
   *   'circle-stroke-width': 2
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): CircleLayer {
    const convertedProps: Record<string, NativePropertyValue<JSONValue>> = {};
    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      convertedProps[key] = convertValue(properties[key]) as NativePropertyValue<JSONValue>;
    }
    this.nativeInstance.setProperties(convertedProps);
    return this;
  }

  // ========== Getter helpers ==========

  getCircleRadius(): number | undefined {
    return this.nativeInstance.getCircleRadius();
  }

  getCircleColor(): string | undefined {
    return this.nativeInstance.getCircleColor();
  }

  getCircleOpacity(): number | undefined {
    return this.nativeInstance.getCircleOpacity();
  }

  getCircleTranslate(): number[] | undefined {
    return this.nativeInstance.getCircleTranslate();
  }

  getCircleTranslateAnchor(): string | undefined {
    return this.nativeInstance.getCircleTranslateAnchor();
  }

  getCirclePitchScale(): string | undefined {
    return this.nativeInstance.getCirclePitchScale();
  }

  getCirclePitchAlignment(): string | undefined {
    return this.nativeInstance.getCirclePitchAlignment();
  }

  getCircleSortKey(): number | undefined {
    return this.nativeInstance.getCircleSortKey();
  }
}
