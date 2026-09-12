/**
 * BaseLayer - shared wrapper base for the ETS style layer classes.
 *
 * The native NAPI layer classes expose an identical base surface
 * (id/type/visibility/zoom, generic property helpers, plus source/filter for
 * source-backed layers); this file hosts that surface once instead of the
 * thirteen copies that used to live in each wrapper. Subclasses keep only
 * their _TYPE_ token and their property-specific accessors.
 */
import type { ExpressionLiteral, JSONValue, PropertyValue as NativePropertyValue } from 'libmaplibre.so';
import { PropertyValue, Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';

/**
 * Base surface shared by every native NAPI layer object
 * (see cpp/types/libmaplibre/layers/*.d.ts).
 */
export interface NativeLayerCore {
  getId(): string;
  getType(): string;
  setVisibility(visibility: 'visible' | 'none'): void;
  getVisibility(): 'visible' | 'none';
  setMinZoom(zoom: number): void;
  getMinZoom(): number;
  setMaxZoom(zoom: number): void;
  getMaxZoom(): number;
}

/** Adds the generic property helpers (custom render layers do not expose them). */
export interface NativePropertyLayer extends NativeLayerCore {
  setProperty(propertyName: string, value: NativePropertyValue<JSONValue>): void;
  setProperties(properties: Record<string, NativePropertyValue<JSONValue>>): void;
}

/** Adds the source id / source layer / filter surface of source-backed layers. */
export interface NativeSourcedLayer extends NativePropertyLayer {
  getSourceId(): string;
  getSourceLayer(): string;
  setSourceLayer(sourceLayer: string): void;
  setFilter(filter: ExpressionLiteral): void;
  getFilter(): ExpressionLiteral | null;
}

/**
 * Construction tag for the dual-mode constructor pattern: fromNative() passes
 * LayerInternalTag.INSTANCE plus the wrapped native object, while user code
 * passes a plain string id.
 */
export class LayerInternalTag {
  static readonly INSTANCE = new LayerInternalTag();
  private constructor() {
  }
}

/**
 * Shared dual-mode construction for layer wrappers.
 *
 * - fromNative() path: tag instance + existing native object -> wrap it.
 * - user path: string id (+ sourceId) -> create the native layer.
 */
export function resolveLayerNative<TN extends Object>(
  idOrTag: string | LayerInternalTag,
  sourceId: string,
  nativeOrNothing: TN | undefined,
  create: (id: string, sourceId: string) => TN,
  className: string
): TN {
  if (idOrTag === LayerInternalTag.INSTANCE && nativeOrNothing instanceof Object) {
    return nativeOrNothing;
  }
  if (typeof idOrTag === 'string') {
    return create(idOrTag, sourceId);
  }
  throw new Error(`Invalid ${className} constructor arguments`);
}

export abstract class BaseLayer<T, SELF extends BaseLayer<T, SELF>> {
  protected nativeInstance: T;

  protected constructor(nativeInstance: T) {
    this.nativeInstance = nativeInstance;
  }

  getNative(): T {
    return this.nativeInstance;
  }

  protected native(): NativeLayerCore {
    return this.nativeInstance as Object as NativeLayerCore;
  }

  getId(): string {
    return this.native().getId();
  }

  getType(): string {
    return this.native().getType();
  }

  setVisibility(visibility: 'visible' | 'none'): SELF {
    this.native().setVisibility(visibility);
    return this as Object as SELF;
  }

  getVisibility(): 'visible' | 'none' {
    return this.native().getVisibility();
  }

  setMinZoom(zoom: number): SELF {
    this.native().setMinZoom(zoom);
    return this as Object as SELF;
  }

  getMinZoom(): number {
    return this.native().getMinZoom();
  }

  setMaxZoom(zoom: number): SELF {
    this.native().setMaxZoom(zoom);
    return this as Object as SELF;
  }

  getMaxZoom(): number {
    return this.native().getMaxZoom();
  }
}

/**
 * Layer base with the generic property API (setProperty/setProperties).
 */
export abstract class PropertyLayer<T, SELF extends PropertyLayer<T, SELF>> extends BaseLayer<T, SELF> {
  protected propertyNative(): NativePropertyLayer {
    return this.nativeInstance as Object as NativePropertyLayer;
  }

  /**
   * Set a single property
   * @param propertyName Property key (for example, 'fill-color', 'fill-opacity')
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): SELF {
    this.propertyNative().setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this as Object as SELF;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'fill-color': '#FF0000',
   *   'fill-opacity': 0.5,
   *   'fill-outline-color': '#000000'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): SELF {
    const convertedProps: Record<string, NativePropertyValue<JSONValue>> = {};
    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      convertedProps[key] = convertValue(properties[key]) as NativePropertyValue<JSONValue>;
    }
    this.propertyNative().setProperties(convertedProps);
    return this as Object as SELF;
  }
}

/**
 * Layer base for layers bound to a data source (source id / source layer /
 * filter surface).
 *
 * ArkTS forbids `this` return types (arkts-no-typing-with-this), so the fluent
 * setters use an F-bounded SELF type parameter instead; each concrete wrapper
 * binds SELF to itself (e.g. `class FillLayer extends SourcedLayer<N, FillLayer>`).
 */
export abstract class SourcedLayer<T, SELF extends SourcedLayer<T, SELF>> extends PropertyLayer<T, SELF> {
  protected sourcedNative(): NativeSourcedLayer {
    return this.nativeInstance as Object as NativeSourcedLayer;
  }

  getSourceId(): string {
    return this.sourcedNative().getSourceId();
  }

  getSourceLayer(): string {
    return this.sourcedNative().getSourceLayer();
  }

  setSourceLayer(sourceLayer: string): SELF {
    this.sourcedNative().setSourceLayer(sourceLayer);
    return this as Object as SELF;
  }

  /**
   * Configure the layer filter
   * @param filter Expression instance or expression literal array
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): SELF {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.sourcedNative().setFilter(filterArray as ExpressionLiteral);
    return this as Object as SELF;
  }

  getFilter(): ExpressionLiteral | null {
    return this.sourcedNative().getFilter();
  }
}
