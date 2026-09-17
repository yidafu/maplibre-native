import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
/**
 * Style - Map style management wrapper
 *
 * Wraps the NAPI Style class to avoid exposing internal types
 */
import maplibre from 'libmaplibre.so';
import { Layer } from './layers/Layer';
import type { Source } from './sources/Source';
import type { Icon, LightSpecification, TransitionOptions } from 'libmaplibre.so';
import { Image } from './images/Image';
import { Light } from './light/Light';

// Source wrappers
import { GeoJsonSource } from './sources/GeoJsonSource';
import { VectorSource } from './sources/VectorSource';
import { RasterSource } from './sources/RasterSource';
import { RasterDemSource } from './sources/RasterDemSource';
import { ImageSource } from './sources/ImageSource';
import { VideoSource } from './sources/VideoSource';
import { CustomGeometrySource } from './sources/CustomGeometrySource';

// Layer wrappers
import { FillLayer } from './layers/FillLayer';
import { LineLayer } from './layers/LineLayer';
import { CircleLayer } from './layers/CircleLayer';
import { SymbolLayer } from './layers/SymbolLayer';
import { RasterLayer } from './layers/RasterLayer';
import { BackgroundLayer } from './layers/BackgroundLayer';
import { HeatmapLayer } from './layers/HeatmapLayer';
import { HillshadeLayer } from './layers/HillshadeLayer';
import { ColorReliefLayer } from './layers/ColorReliefLayer';
import { FillExtrusionLayer } from './layers/FillExtrusionLayer';
import { LocationIndicatorLayer } from './layers/LocationIndicatorLayer';

/**
 * Internal marker to prevent constructing Style externally
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * Style - Map style management class
 *
 * Obtain an instance via MapLibreMap.getStyle()
 * Should not be constructed directly
 */
export class Style {
  private nativeInstance: maplibre.Style;

  /**
   * Private constructor, only available through fromNative
   */
  constructor(marker: InternalMarker, nativeInstance: maplibre.Style) {
    if (marker !== InternalMarker.INSTANCE) {
      throw new Error('Style cannot be constructed directly. Use MapLibreMap.getStyle() instead.');
    }
    this.nativeInstance = nativeInstance;
  }

  /**
   * Create the wrapper from a NAPI instance (internal use)
   */
  static fromNative(nativeInstance: maplibre.Style): Style {
    return new Style(InternalMarker.INSTANCE, nativeInstance);
  }

  /**
   * Get the underlying NAPI instance (internal use)
   */
  getNative(): maplibre.Style {
    return this.nativeInstance;
  }

  // ========== Conversion helpers ==========

  /**
   * Wrap a NAPI Source object into the corresponding ETS Source class
   */
  private static wrapSource(nativeSource: Object): Source | null {
    if (!nativeSource) {
      hilog.warn(DOMAIN, 'Style', '%{public}s', '[Style] wrapSource: nativeSource is null/undefined');
      return null;
    }

    // Determine the type via the _TYPE_ property (instanceof does not work on NAPI plain objects)
    const sourceObj = nativeSource as Record<string, Object>;
    const napiType = sourceObj._TYPE_ as string;

    // Match the Source class by the _TYPE_ property
    if (napiType === GeoJsonSource._TYPE_) {
      return GeoJsonSource.fromNative(nativeSource as maplibre.GeoJsonSource);
    }
    if (napiType === VectorSource._TYPE_) {
      return VectorSource.fromNative(nativeSource as maplibre.VectorSource);
    }
    if (napiType === RasterSource._TYPE_) {
      return RasterSource.fromNative(nativeSource as maplibre.RasterSource);
    }
    if (napiType === RasterDemSource._TYPE_) {
      return RasterDemSource.fromNative(nativeSource as maplibre.RasterDemSource);
    }
    if (napiType === ImageSource._TYPE_) {
      return ImageSource.fromNative(nativeSource as maplibre.ImageSource);
    }
    if (napiType === VideoSource._TYPE_) {
      return VideoSource.fromNative(nativeSource as maplibre.VideoSource);
    }
    if (napiType === CustomGeometrySource._TYPE_) {
      return CustomGeometrySource.fromNative(nativeSource as maplibre.CustomGeometrySource);
    }

    hilog.error(DOMAIN, 'Style', '%{public}s', `[Style] wrapSource: ❌ No matching type found for source! _TYPE_=${napiType}`);
    return null;
  }

  /**
   * Wrap a NAPI Layer object into the corresponding ETS Layer class
   */
  private static wrapLayer(nativeLayer: Object): Layer | null {
    if (!nativeLayer) {
      hilog.warn(DOMAIN, 'Style', '%{public}s', '[Style] wrapLayer: nativeLayer is null/undefined');
      return null;
    }

    // Determine the type via the _TYPE_ property (instanceof does not work on NAPI plain objects)
    const layerObj = nativeLayer as Record<string, Object>;
    const napiType = layerObj._TYPE_ as string;

    // Match the Layer class by the _TYPE_ property
    if (napiType === FillLayer._TYPE_) {
      return FillLayer.fromNative(nativeLayer as maplibre.FillLayer);
    }
    if (napiType === LineLayer._TYPE_) {
      return LineLayer.fromNative(nativeLayer as maplibre.LineLayer);
    }
    if (napiType === CircleLayer._TYPE_) {
      return CircleLayer.fromNative(nativeLayer as maplibre.CircleLayer);
    }
    if (napiType === SymbolLayer._TYPE_) {
      return SymbolLayer.fromNative(nativeLayer as maplibre.SymbolLayer);
    }
    if (napiType === RasterLayer._TYPE_) {
      return RasterLayer.fromNative(nativeLayer as maplibre.RasterLayer);
    }
    if (napiType === BackgroundLayer._TYPE_) {
      return BackgroundLayer.fromNative(nativeLayer as maplibre.BackgroundLayer);
    }
    if (napiType === HeatmapLayer._TYPE_) {
      return HeatmapLayer.fromNative(nativeLayer as maplibre.HeatmapLayer);
    }
    if (napiType === HillshadeLayer._TYPE_) {
      return HillshadeLayer.fromNative(nativeLayer as maplibre.HillshadeLayer);
    }
    if (napiType === ColorReliefLayer._TYPE_) {
      return ColorReliefLayer.fromNative(nativeLayer as maplibre.ColorReliefLayer);
    }
    if (napiType === FillExtrusionLayer._TYPE_) {
      return FillExtrusionLayer.fromNative(nativeLayer as maplibre.FillExtrusionLayer);
    }
    if (napiType === LocationIndicatorLayer._TYPE_) {
      return LocationIndicatorLayer.fromNative(nativeLayer as maplibre.LocationIndicatorLayer);
    }

    hilog.error(DOMAIN, 'Style', '%{public}s', `[Style] wrapLayer: ❌ No matching type found for layer! _TYPE_=${napiType}`);
    return null;
  }

  // ========== Core methods ==========

  /**
   * Get the style URI
   */
  getUri(): string {
    return this.nativeInstance.getUri();
  }

  /**
   * Get the style JSON
   */
  getJson(): string {
    return this.nativeInstance.getJson();
  }

  /**
   * Check whether the style has fully loaded
   */
  isFullyLoaded(): boolean {
    return this.nativeInstance.isFullyLoaded();
  }

  // ========== Source management ==========

  /**
   * Add a data source
   *
   * @param source ETS Source wrapper
   */
  addSource(source: Source): void {
    this.nativeInstance.addSource(source.getNative());
  }

  /**
   * Remove a data source
   */
  removeSource(sourceId: string): boolean {
    return this.nativeInstance.removeSource(sourceId);
  }

  /**
   * Get a specific data source
   */
  getSource(sourceId: string): Source | null {
    const nativeSource = this.nativeInstance.getSource(sourceId);
    if (nativeSource == null) {
      return null
    }
    return Style.wrapSource(nativeSource);
  }

  /**
   * Get all data sources
   */
  getSources(): Source[] {
    const nativeSources = this.nativeInstance.getSources();
    return nativeSources
      .map(nativeSource => Style.wrapSource(nativeSource))
      .filter(source => source !== null) as Source[];
  }

  // ========== Layer management ==========

  /**
   * Add a layer (append to the top)
   *
   * @param layer ETS Layer wrapper
   */
  addLayer(layer: Layer): void {
    this.nativeInstance.addLayer(layer.getNative());
  }

  /**
   * Add a layer below a target layer
   *
   * @param layer ETS Layer wrapper
   * @param belowLayerId Reference layer ID
   */
  addLayerBelow(layer: Layer, belowLayerId: string): void {
    this.nativeInstance.addLayerBelow(layer.getNative(), belowLayerId);
  }

  /**
   * Add a layer above a target layer
   *
   * @param layer ETS Layer wrapper
   * @param aboveLayerId Reference layer ID
   */
  addLayerAbove(layer: Layer, aboveLayerId: string): void {
    this.nativeInstance.addLayerAbove(layer.getNative(), aboveLayerId);
  }

  /**
   * Insert a layer at a specific index
   *
   * @param layer ETS Layer wrapper
   * @param index Target index
   */
  addLayerAt(layer: Layer, index: number): void {
    this.nativeInstance.addLayerAt(layer.getNative(), index);
  }

  /**
   * Remove a layer by ID
   */
  removeLayer(layerId: string): boolean {
    return this.nativeInstance.removeLayer(layerId);
  }

  /**
   * Remove a layer by index
   */
  removeLayerAt(index: number): boolean {
    return this.nativeInstance.removeLayerAt(index);
  }

  /**
   * Get a specific layer
   */
  getLayer(layerId: string): Layer | null {
    const nativeLayer = this.nativeInstance.getLayer(layerId);
    if (nativeLayer == null) {
      return null
    }
    return Style.wrapLayer(nativeLayer);
  }

  /**
   * Get all layers
   */
  getLayers(): Layer[] {
    const nativeLayers = this.nativeInstance.getLayers();
    return nativeLayers
      .map(nativeLayer => Style.wrapLayer(nativeLayer))
      .filter(layer => layer !== null) as Layer[];
  }

  // ========== Image management ==========

  /**
   * Add an image.
   *
   * Supported forms:
   * - `addImage(name, buffer, width, height, sdf?)`
   * - `addImage(name, buffer, width, height, pixelRatio?, sdf?)`
   *
   * @param name Image identifier.
   * @param imageData Raw RGBA (premultiplied) pixel data; its byte length
   *                  must equal `width * height * 4`.
   * @param pixelRatioOrSdf Pixel ratio (defaults to 1.0) or SDF flag.
   * @param sdf Whether the image is an SDF (Signed Distance Field) asset.
   */
  addImage(
    name: string,
    imageData: ArrayBuffer | Uint8Array,
    width: number,
    height: number,
    pixelRatioOrSdf?: number | boolean,
    sdf?: boolean
  ): void {
    this.nativeInstance.addImage(name, imageData, width, height, pixelRatioOrSdf, sdf);
  }

  /**
   * Add an image asynchronously (non-blocking for the UI thread).
   *
   * Accepts the same argument forms as `addImage`.
   */
  addImageAsync(
    name: string,
    imageData: ArrayBuffer | Uint8Array,
    width: number,
    height: number,
    pixelRatioOrSdf?: number | boolean,
    sdf?: boolean
  ): Promise<void> {
    return this.nativeInstance.addImageAsync(name, imageData, width, height, pixelRatioOrSdf, sdf);
  }

  /**
   * Add images in batch asynchronously (non-blocking for the UI thread)
   */
  addImagesAsync(images: Image[]): Promise<void> {
    const nativeImages = images.map(img => img.getNative());
    return this.nativeInstance.addImagesAsync(nativeImages);
  }

  /**
   * Remove an image
   */
  removeImage(name: string): boolean {
    return this.nativeInstance.removeImage(name);
  }

  /**
   * Get an image
   */
  getImage(name: string): Icon | null {
    const result = this.nativeInstance.getImage(name);
    return result ? (result as Object as Icon) : null;
  }

  // ========== Lighting management ==========

  /**
   * Get the lighting specification
   */
  getLight(): Light | null {
    const nativeLight = this.nativeInstance.getLight();
    if (!nativeLight) {
      return null;
    }
    return Light.fromNative(nativeLight as maplibre.Light);
  }

  /**
   * Set the lighting configuration
   */
  setLight(light: Light | LightSpecification): void {
    let specification: LightSpecification;
    if (light instanceof Light) {
      specification = light.toSpecification();
    } else {
      specification = light;
    }
    this.nativeInstance.setLight(specification);
  }

  // ========== Transition management ==========

  /**
   * Get the transition settings
   */
  getTransition(): TransitionOptions | null {
    return this.nativeInstance.getTransition() as TransitionOptions | null;
  }

  /**
   * Set the transition settings
   */
  setTransition(transitionJson: string): void {
    this.nativeInstance.setTransition(transitionJson);
  }

  /**
   * Get the data source by ID and cast it to a specific type
   * TODO: Provide type-safe accessors
   * @param sourceId - Data source ID
   * @returns Data source instance or null
   */
  getSourceAs<T>(sourceId: string): T | null {
    const source = this.getSource(sourceId);
    return source as T | null;
  }
}

/**
 * StyleBuilder - Re-export NAPI StyleBuilder
 */
export { StyleBuilder } from 'libmaplibre.so';
