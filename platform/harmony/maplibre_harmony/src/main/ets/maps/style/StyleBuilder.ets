/**
 * StyleBuilder - style configuration helper.
 *
 * Inspired by Android `Style.Builder`, it batches source/layer additions and
 * guarantees layout properties are set before `SymbolBucket` creation to avoid timing issues.
 *
 * @example
 * ```typescript
 * new StyleBuilder()
 *   .withSource(new GeoJsonSource('source-id'))
 *   .withLayer(
 *     new SymbolLayer('layer-id', 'source-id')
 *       .setTextField(['get', 'title'])
 *       .setTextAllowOverlap(true)
 *   )
 *   .build(map);
 * ```
 */

import type { MapLibreMap } from '../MapLibreMap';
import type { Source } from './sources/Source';
import type { Layer } from './layers/Layer';

/**
 * Layer configuration container.
 */
class LayerConfig {
  /** Layer instance. */
  layer: Layer;
  /** Insert before a specific layer ID. */
  beforeId?: string;
  /** Insert after a specific layer ID. */
  afterId?: string;
  /** Insert at a specific index. */
  atIndex?: number;

  constructor(layer: Layer, beforeId?: string, afterId?: string, atIndex?: number) {
    this.layer = layer;
    this.beforeId = beforeId;
    this.afterId = afterId;
    this.atIndex = atIndex;
  }
}

/**
 * Statistics tracker.
 */
class StyleBuilderStats {
  sources: number = 0;
  layers: number = 0;
  images: number = 0;
}

/**
 * Image configuration descriptor.
 */
class ImageConfig {
  /** Image identifier. */
  id: string;
  /** Image data. */
  image: ArrayBuffer | Uint8Array;
  /** Image width. */
  width: number;
  /** Image height. */
  height: number;
  /** Whether the image is SDF. */
  sdf?: boolean;

  constructor(id: string, image: ArrayBuffer | Uint8Array, width: number, height: number, sdf?: boolean) {
    this.id = id;
    this.image = image;
    this.width = width;
    this.height = height;
    this.sdf = sdf;
  }
}

/**
 * StyleBuilder - declarative style builder ensuring consistent ordering.
 */
export class StyleBuilder {
  /** Source map keyed by source ID. */
  private sources: Map<string, Source> = new Map();
  
  /** Layer configuration list. */
  private layers: LayerConfig[] = [];
  
  /** Image configuration list. */
  private images: ImageConfig[] = [];
  
  /** Indicates whether build() has been executed. */
  private built: boolean = false;

  /**
   * Add a data source.
   * @param source Source instance.
   * @returns This builder for chaining.
   */
  public withSource(source: Source): StyleBuilder {
    this.checkNotBuilt();
    const sourceId = this.getSourceId(source);
    if (sourceId) {
      this.sources.set(sourceId, source);
    }
    return this;
  }

  /**
   * Add multiple data sources.
   * @param sources Source array.
   * @returns This builder for chaining.
   */
  public withSources(...sources: Source[]): StyleBuilder {
    this.checkNotBuilt();
    for (const source of sources) {
      this.withSource(source);
    }
    return this;
  }

  /**
   * Add a layer.
   * @param layer Layer instance (all properties should be preconfigured).
   * @returns This builder for chaining.
   */
  public withLayer(layer: Layer): StyleBuilder {
    this.checkNotBuilt();
    this.layers.push(new LayerConfig(layer));
    return this;
  }

  /**
   * Add multiple layers.
   * @param layers Layer array.
   * @returns This builder for chaining.
   */
  public withLayers(...layers: Layer[]): StyleBuilder {
    this.checkNotBuilt();
    for (const layer of layers) {
      this.withLayer(layer);
    }
    return this;
  }

  /**
   * Insert a layer before another layer.
   * @param layer Layer instance.
   * @param beforeLayerId Reference layer ID.
   * @returns This builder for chaining.
   */
  public withLayerBefore(layer: Layer, beforeLayerId: string): StyleBuilder {
    this.checkNotBuilt();
    this.layers.push(new LayerConfig(layer, beforeLayerId));
    return this;
  }

  /**
   * Insert a layer after another layer.
   * @param layer Layer instance.
   * @param afterLayerId Reference layer ID.
   * @returns This builder for chaining.
   */
  public withLayerAfter(layer: Layer, afterLayerId: string): StyleBuilder {
    this.checkNotBuilt();
    this.layers.push(new LayerConfig(layer, undefined, afterLayerId));
    return this;
  }

  /**
   * Insert a layer at a specific index.
   * @param layer Layer instance.
   * @param index Target index.
   * @returns This builder for chaining.
   */
  public withLayerAt(layer: Layer, index: number): StyleBuilder {
    this.checkNotBuilt();
    this.layers.push(new LayerConfig(layer, undefined, undefined, index));
    return this;
  }

  /**
   * Add an image resource.
   * @param id Image identifier.
   * @param image Image data (`ArrayBuffer` or `Uint8Array`).
   * @param width Image width.
   * @param height Image height.
   * @param sdf Whether the image is SDF.
   * @returns This builder for chaining.
   */
  public withImage(
    id: string,
    image: ArrayBuffer | Uint8Array,
    width: number,
    height: number,
    sdf: boolean = false
  ): StyleBuilder {
    this.checkNotBuilt();
    this.images.push(new ImageConfig(id, image, width, height, sdf));
    return this;
  }

  /**
   * Build and apply the style.
   * @param map Map instance.
   * @returns Promise resolved after all components are added.
   */
  public async build(map: MapLibreMap): Promise<void> {
    this.checkNotBuilt();
    this.built = true;

    try {
      // 1. Add images.
      await this.addImages(map);

      // 2. Add sources.
      await this.addSources(map);

      // 3. Add layers.
      await this.addLayers(map);

      console.info(`✅ StyleBuilder: Successfully built style with ${this.sources.size} sources, ${this.layers.length} layers, ${this.images.length} images`);
    } catch (error) {
      const errorMsg = `StyleBuilder: Failed to build style: ${error}`;
      console.error('❌', errorMsg);
      throw new Error(errorMsg);
    }
  }

  /**
   * Add all configured images.
   */
  private async addImages(map: MapLibreMap): Promise<void> {
    const style = map.getStyle();
    if (!style) {
      throw new Error('Style not loaded');
    }

    for (const imageConfig of this.images) {
      try {
        style.addImage(
          imageConfig.id,
          imageConfig.image,
          imageConfig.width,
          imageConfig.height,
          imageConfig.sdf ?? false
        );
        console.info(`✅ Added image: ${imageConfig.id}`);
      } catch (error) {
        console.error(`❌ Failed to add image ${imageConfig.id}:`, error);
        throw new Error(`Failed to add image ${imageConfig.id}: ${error}`);
      }
    }
  }

  /**
   * Add all configured sources.
   */
  private async addSources(map: MapLibreMap): Promise<void> {
    this.sources.forEach((source, sourceId) => {
      try {
        map.addSource(source);
        console.info(`✅ Added source: ${sourceId}`);
      } catch (error) {
        console.error(`❌ Failed to add source ${sourceId}:`, error);
        throw new Error(`Failed to add source ${sourceId}: ${error}`);
      }
    });

    // Allow sources time to register.
    if (this.sources.size > 0) {
      await this.delay(50);
    }
  }

  /**
   * Add all configured layers.
   */
  private async addLayers(map: MapLibreMap): Promise<void> {
    for (const config of this.layers) {
      try {
        const layerId = this.getLayerId(config.layer);
        
        if (config.beforeId) {
          // Insert before a specific layer.
          map.addLayerAbove(config.layer, config.beforeId);
          console.info(`✅ Added layer ${layerId} before ${config.beforeId}`);
        } else if (config.afterId) {
          // Insert after a specific layer.
          map.addLayerAbove(config.layer, config.afterId);
          console.info(`✅ Added layer ${layerId} after ${config.afterId}`);
        } else if (config.atIndex !== undefined) {
          // Insert at an explicit index.
          map.addLayerAt(config.layer, config.atIndex);
          console.info(`✅ Added layer ${layerId} at index ${config.atIndex}`);
        } else {
          // Append to the end.
          map.addLayer(config.layer);
          console.info(`✅ Added layer: ${layerId}`);
        }
      } catch (error) {
        const layerId = this.getLayerId(config.layer);
        console.error(`❌ Failed to add layer ${layerId}:`, error);
        throw new Error(`Failed to add layer ${layerId}: ${error}`);
      }
    }
  }

  /**
   * Ensure the builder has not been finalized.
   */
  private checkNotBuilt(): void {
    if (this.built) {
      throw new Error('StyleBuilder has already been built. Create a new instance for additional changes.');
    }
  }

  /**
   * Helper delay.
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Get a source ID.
   */
  private getSourceId(source: Source): string | null {
    try {
      // Sources expose getId().
      return source.getId();
    } catch (error) {
      console.error('Error getting source ID:', error);
      return null;
    }
  }

  /**
   * Get a layer ID.
   */
  private getLayerId(layer: Layer): string {
    try {
      // Layers expose getId().
      return layer.getId();
    } catch (error) {
      console.error('Error getting layer ID:', error);
      return 'unknown-layer';
    }
  }

  /**
   * Retrieve current configuration statistics.
   */
  public getStats(): StyleBuilderStats {
    const stats = new StyleBuilderStats();
    stats.sources = this.sources.size;
    stats.layers = this.layers.length;
    stats.images = this.images.length;
    return stats;
  }

  /**
   * Clear all configuration (reset).
   */
  public clear(): void {
    this.sources.clear();
    this.layers = [];
    this.images = [];
    this.built = false;
  }
}

