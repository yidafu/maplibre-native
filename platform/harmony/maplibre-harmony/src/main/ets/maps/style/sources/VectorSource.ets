/**
 * VectorSource - Wrapper for vector data sources
 */
import type { VectorSourceOptions, JSONValue } from 'libmaplibre.so';
import maplibre from 'libmaplibre.so';
import { BaseSource, SourceInternalTag, resolveSourceNative } from './BaseSource';

export class VectorSource extends BaseSource<maplibre.VectorSource> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'VectorSource';

  constructor(idOrMarker: string | SourceInternalTag, optionsOrNative?: VectorSourceOptions | maplibre.VectorSource) {
    super(resolveSourceNative(idOrMarker, optionsOrNative, 
      (id, o) => new maplibre.VectorSource(id, o as VectorSourceOptions), "VectorSource"));
  }

  static create(id: string, options?: VectorSourceOptions): VectorSource {
    return new VectorSource(id, options);
  }

  static fromNative(nativeInstance: maplibre.VectorSource): VectorSource {
    return new VectorSource(SourceInternalTag.INSTANCE, nativeInstance);
  }

  setTiles(tiles: string[]): VectorSource {
    this.nativeInstance.setTiles(tiles);
    return this;
  }

  setUrl(url: string): VectorSource {
    this.nativeInstance.setUrl(url);
    return this;
  }

  getUrl(): string {
    return this.nativeInstance.getUrl();
  }

  /**
   * Set the minimum zoom level
   */
  setMinZoom(minZoom: number): VectorSource {
    this.nativeInstance.setMinZoom(minZoom);
    return this;
  }

  /**
   * Set the maximum zoom level
   */
  setMaxZoom(maxZoom: number): VectorSource {
    this.nativeInstance.setMaxZoom(maxZoom);
    return this;
  }

  // ==================== Feature state ====================

  /**
   * Set the state of a feature in this source.
   *
   * Feature state can be read in style expressions through
   * `["feature-state", key]`. The target feature must already have an id in
   * the underlying source data.
   *
   * @param sourceLayerId Source layer containing the feature
   * @param featureId Id of the feature whose state to set
   * @param state JSON object with the state key-value pairs to merge
   * @returns true if the source is attached to a map and the update dispatched
   */
  setFeatureState(sourceLayerId: string, featureId: string, state: Record<string, JSONValue>): boolean {
    const host = this.getFeatureStateHost();
    if (!host) {
      return false;
    }
    return host.setFeatureState(this.getId(), sourceLayerId, featureId, state);
  }

  /**
   * Get the current state of a feature in this source.
   *
   * @param sourceLayerId Source layer containing the feature
   * @param featureId Id of the feature whose state to get
   * @returns The feature state, or undefined when the source is not attached
   *   to a map or the feature has no state
   */
  getFeatureState(sourceLayerId: string, featureId: string): Record<string, JSONValue> | undefined {
    const host = this.getFeatureStateHost();
    if (!host) {
      return undefined;
    }
    return host.getFeatureState(this.getId(), sourceLayerId, featureId);
  }

  /**
   * Remove state from a feature in this source, or from all features of the
   * layer when featureId is omitted.
   *
   * @param sourceLayerId Source layer containing the feature
   * @param featureId Id of the feature, or undefined to target all features
   * @param stateKey State key to remove, or undefined to remove all keys
   * @returns true if the source is attached to a map and the update dispatched
   */
  removeFeatureState(sourceLayerId: string, featureId?: string, stateKey?: string): boolean {
    const host = this.getFeatureStateHost();
    if (!host) {
      return false;
    }
    return host.removeFeatureState(this.getId(), sourceLayerId, featureId, stateKey);
  }

  /**
   * Remove all feature state entries from this source layer.
   *
   * @param sourceLayerId Source layer whose state to reset
   * @returns true if the source is attached to a map and the update dispatched
   */
  resetFeatureStates(sourceLayerId: string): boolean {
    return this.removeFeatureState(sourceLayerId, undefined, undefined);
  }
}
