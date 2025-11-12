/**
 * MapLibre Native for HarmonyOS - Style API type definitions.
 * Map style management API (NAPI object).
 *
 * Refactored as an object-oriented interface aligned with the Android/iOS design.
 */

import type { Layer } from './layers';
import type { Source } from './sources';
import type { Image } from './images/Image';
import type { LightSpecification } from './CommonTypes';
import type { Light } from './light/Light';

/**
 * Style - map style manager.
 *
 * Obtain via MapLibreMap.getStyle().
 * Should not be constructed directly.
 */
export class Style {
  /**
   * Get the style URI.
   * @returns Style URI.
   */
  getUri(): string;

  /**
   * Get the style JSON.
   * @returns Style JSON string.
   */
  getJson(): string;

  /**
   * Check whether the style is fully loaded.
   * @returns True when loading has completed.
   */
  isFullyLoaded(): boolean;

  // ========== Source management ==========

  /**
   * Add a source.
   * @param source Source object (GeoJsonSource, VectorSource, RasterSource, etc.).
   */
  addSource(source: Source): void;

  /**
   * Remove a source.
   * @param sourceId Source identifier.
   * @returns True if the source was removed.
   */
  removeSource(sourceId: string): boolean;

  /**
   * Retrieve a source by identifier.
   * @param sourceId Source identifier.
   * @returns Source instance (GeoJsonSource, VectorSource, etc.) or null if missing.
   */
  getSource(sourceId: string): Source | null;

  /**
   * Get all sources.
   * @returns Array containing every registered source.
   */
  getSources(): Source[];

  // ========== Layer management ==========

  /**
   * Add a layer (appended to the top).
   * @param layer Layer object (FillLayer, LineLayer, CircleLayer, etc.).
   */
  addLayer(layer: Layer): void;

  /**
   * Add a layer below another layer.
   * @param layer Layer object.
   * @param belowLayerId Reference layer identifier; the new layer is inserted below it.
   */
  addLayerBelow(layer: Layer, belowLayerId: string): void;

  /**
   * Add a layer above another layer.
   * @param layer Layer object.
   * @param aboveLayerId Reference layer identifier; the new layer is inserted above it.
   */
  addLayerAbove(layer: Layer, aboveLayerId: string): void;

  /**
   * Insert a layer at a specific index.
   * @param layer Layer object.
   * @param index Destination index.
   */
  addLayerAt(layer: Layer, index: number): void;

  /**
   * Remove a layer by identifier.
   * @param layerId Layer identifier.
   * @returns True if the layer was removed.
   */
  removeLayer(layerId: string): boolean;

  /**
   * Remove a layer at an index.
   * @param index Target index.
   * @returns True if the layer was removed.
   */
  removeLayerAt(index: number): boolean;

  /**
   * Retrieve a layer by identifier.
   * @param layerId Layer identifier.
   * @returns Layer instance (FillLayer, LineLayer, etc.) or null when missing.
   */
  getLayer(layerId: string): Layer | null;

  /**
   * Get all layers.
   * @returns Array containing every registered layer.
   */
  getLayers(): Layer[];

  // ========== Image management ==========

  /**
   * Add an image to the style.
   * @param name Image name.
   * @param imageData Image data (ArrayBuffer or Uint8Array, RGBA format).
   * @param width Pixel width.
   * @param height Pixel height.
   * @param sdf Whether this is an SDF (signed distance field) image; defaults to false.
   */
  addImage(name: string, imageData: ArrayBuffer | Uint8Array, width: number, height: number, sdf?: boolean): void;

  /**
   * Add an image asynchronously (non-blocking).
   * @param name Image name.
   * @param imageData Image data (ArrayBuffer or Uint8Array, RGBA format).
   * @param width Pixel width.
   * @param height Pixel height.
   * @param sdf Whether this is an SDF image; defaults to false.
   * @returns Promise<void> resolved on completion.
   */
  addImageAsync(name: string, imageData: ArrayBuffer | Uint8Array, width: number, height: number, sdf?: boolean): Promise<void>;

  /**
   * Add multiple images asynchronously (non-blocking).
   * @param images Array of image objects.
   * @returns Promise<void> resolved on completion.
   */
  addImagesAsync(images: Image[]): Promise<void>;

  /**
   * Remove an image from the style.
   * @param name Image name.
   * @returns True if the image was removed.
   */
  removeImage(name: string): boolean;

  /**
   * Retrieve an image.
   * @param name Image name.
   * @returns Image object, or null if missing.
   */
  getImage(name: string): Image | null;

  // ========== Lighting ==========

  /**
   * Get the lighting configuration.
   * @returns Light instance (NAPI) or null if undefined.
   */
  getLight(): Light | null;

  /**
   * Set the lighting configuration.
   * @param light Light instance or specification.
   */
  setLight(light: Light | LightSpecification): void;

  // ========== Transition handling ==========

  /**
   * Get transition options.
   * @returns Transition object (duration, delay, etc.) or null when unavailable.
   */
  getTransition(): { duration?: number; delay?: number } | null;

  /**
   * Set transition options.
   * @param transitionJson Transition configuration JSON.
   */
  setTransition(transitionJson: string): void;
}

/**
 * StyleBuilder - style builder.
 *
 * Builds map styles via the builder pattern.
 *
 * @example
 * ```typescript
 * const builder = new maplibre.StyleBuilder()
 *     .fromUri("https://demotiles.maplibre.org/style.json")
 *     .withSource(mySource)
 *     .withLayer(myLayer);
 * mapLibreMap.setStyle(builder);
 * ```
 */
export class StyleBuilder {
  /**
   * Construct a new style builder.
   */
  constructor();

  /**
   * Load style data from a URI.
   *
   * Supported schemes include:
   * - http://... or https://... for network resources.
   * - file://... for local files.
   * - resource://... for packaged resources.
   *
   * @param uri Style URI.
   * @returns this (chainable).
   */
  fromUri(uri: string): this;

  /**
   * Load style data from a JSON string.
   * @param json Style JSON string.
   * @returns this (chainable).
   */
  fromJson(json: string): this;

  /**
   * Append a source (to be added after the style loads).
   * @param source Source object (GeoJsonSource, VectorSource, RasterSource, etc.).
   * @returns this (chainable).
   */
  withSource(source: Source): this;

  /**
   * Append a layer (added after the style loads).
   * @param layer Layer object (FillLayer, LineLayer, CircleLayer, etc.).
   * @returns this (chainable).
   */
  withLayer(layer: Layer): this;

  /**
   * Append an image (added after the style loads).
   * @param image Image object containing name, data, and metadata.
   * @returns this (chainable).
   */
  withImage(image: Image): this;

  /**
   * Configure transition options.
   * @param options Transition options (duration, delay, etc.).
   * @returns this (chainable).
   */
  withTransitionOptions(options: { duration?: number; delay?: number }): this;
}

