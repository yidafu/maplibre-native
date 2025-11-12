/**
 * PolylineManager - polyline manager.
 *
 * Handles polyline creation, updates, deletion, and queries.
 *
 * Architecture:
 * - Uses the native annotation system (`nativeMapView.addPolylines`)
 * - Queries run via the `queryShapeAnnotations` API
 * - Differs from `MarkerManager`, which uses a GeoJSON-based approach
 *
 * Reference: Android `PolylineContainer` implementation.
 */
import type { MapLibreMap } from '../MapLibreMap';
import { Polyline, PolylineOptions } from './Polyline';
import { Rect } from '../geometry/Rect';

/**
 * PolylineManager class.
 *
 * Manages all polyline annotations on the map via the native annotation system.
 */
export class PolylineManager {
  private mapLibreMap: MapLibreMap;
  // Polyline ID -> Polyline mapping
  private polylineMap: Map<number, Polyline> = new Map();

  /**
   * Constructor.
   *
   * @param mapLibreMap MapLibreMap instance.
   */
  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
  }

  /**
   * Add a single polyline.
   *
   * @param options PolylineOptions instance.
   * @returns Created polyline.
   */
  public addPolyline(options: PolylineOptions): Polyline {
    try {
      // Create polyline object
      const polyline = new Polyline(options);

      // Invoke native API (returns an array of IDs)
      const ids = this.mapLibreMap.getNativeMapView().addPolylines([polyline]);

      if (ids.length > 0) {
        const id = ids[0];
        polyline.setId(id);
        this.polylineMap.set(id, polyline);
      }

      return polyline;
    } catch (error) {
      console.error(`[PolylineManager] Failed to add polyline: ${error}`);
      throw new Error(`Failed to add polyline: ${error}`);
    }
  }

  /**
   * Add polylines in batch.
   *
   * @param optionsList Array of PolylineOptions.
   * @returns Array of created polylines.
   */
  public addPolylines(optionsList: PolylineOptions[]): Polyline[] {
    try {
      // Create polyline objects
      const polylines: Polyline[] = [];
      for (const options of optionsList) {
        polylines.push(new Polyline(options));
      }

      // Add them to the map in batch
      const ids = this.mapLibreMap.getNativeMapView().addPolylines(polylines);

      // Assign IDs and register them
      for (let i = 0; i < polylines.length; i++) {
        const polyline = polylines[i];
        const id = ids[i];
        polyline.setId(id);
        this.polylineMap.set(id, polyline);
      }

      return polylines;
    } catch (error) {
      console.error(`[PolylineManager] Failed to add polylines batch: ${error}`);
      throw new Error(`Failed to add polylines batch: ${error}`);
    }
  }

  /**
   * Remove a single polyline.
   *
   * @param polyline Polyline to remove.
   */
  public removePolyline(polyline: Polyline): void {
    const id = polyline.getId();
    if (id === -1) {
      return;
    }

    this.mapLibreMap.getNativeMapView().removeAnnotations([id]);
    this.polylineMap.delete(id);
  }

  /**
   * Remove polylines in batch.
   *
   * @param polylines Polylines to remove.
   */
  public removePolylines(polylines: Polyline[]): void {
    const ids: number[] = [];

    for (const polyline of polylines) {
      const id = polyline.getId();
      if (id !== -1) {
        ids.push(id);
        this.polylineMap.delete(id);
      }
    }

    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
  }

  /**
   * Update an existing polyline.
   *
   * @param polyline Polyline to update.
   */
  public updatePolyline(polyline: Polyline): void {
    const id = polyline.getId();
    if (id === -1) {
      console.warn('[PolylineManager] Cannot update polyline with id -1');
      return;
    }

    this.mapLibreMap.updatePolyline(polyline);
  }

  /**
   * Remove all polylines.
   */
  public clear(): void {
    const ids = Array.from(this.polylineMap.keys());
    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
    this.polylineMap.clear();
  }

  /**
   * Get all polylines.
   *
   * @returns Array of polylines.
   */
  public getPolylines(): Polyline[] {
    return Array.from(this.polylineMap.values());
  }
}

