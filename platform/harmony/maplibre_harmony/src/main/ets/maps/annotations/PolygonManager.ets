/**
 * PolygonManager - polygon manager.
 *
 * Handles polygon creation, updates, deletion, and queries.
 *
 * Architecture:
 * - Uses the native annotation system (`nativeMapView.addPolygons`)
 * - Queries run via the `queryShapeAnnotations` API
 * - Differs from `MarkerManager`, which uses a GeoJSON-based approach
 *
 * Reference: Android `PolygonContainer` implementation.
 */
import type { MapLibreMap } from '../MapLibreMap';
import { Polygon, PolygonOptions } from './Polygon';
import { Rect } from '../geometry/Rect';

/**
 * PolygonManager class.
 *
 * Manages all polygon annotations on the map via the native annotation system.
 */
export class PolygonManager {
  private mapLibreMap: MapLibreMap;
  // Polygon ID -> Polygon mapping
  private polygonMap: Map<number, Polygon> = new Map();

  /**
   * Constructor.
   *
   * @param mapLibreMap MapLibreMap instance.
   */
  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
  }

  /**
   * Add a single polygon.
   *
   * @param options PolygonOptions instance.
   * @returns Created polygon.
   */
  public addPolygon(options: PolygonOptions): Polygon {
    try {
      // Create polygon object
      const polygon = new Polygon(options);

      // Invoke native API (returns an array of IDs)
      const ids = this.mapLibreMap.getNativeMapView().addPolygons([polygon]);

      if (ids.length > 0) {
        const id = ids[0];
        polygon.setId(id);
        this.polygonMap.set(id, polygon);
      }

      return polygon;
    } catch (error) {
      console.error(`[PolygonManager] Failed to add polygon: ${error}`);
      throw new Error(`Failed to add polygon: ${error}`);
    }
  }

  /**
   * Add multiple polygons.
   *
   * @param optionsList Array of PolygonOptions.
   * @returns Array of created polygons.
   */
  public addPolygons(optionsList: PolygonOptions[]): Polygon[] {
    try {
      // Create polygon objects
      const polygons: Polygon[] = [];
      for (const options of optionsList) {
        polygons.push(new Polygon(options));
      }

      // Add them to the map in batch
      const ids = this.mapLibreMap.getNativeMapView().addPolygons(polygons);

      // Assign IDs and register them
      for (let i = 0; i < polygons.length; i++) {
        const polygon = polygons[i];
        const id = ids[i];
        polygon.setId(id);
        this.polygonMap.set(id, polygon);
      }

      return polygons;
    } catch (error) {
      console.error(`[PolygonManager] Failed to add polygons batch: ${error}`);
      throw new Error(`Failed to add polygons batch: ${error}`);
    }
  }

  /**
   * Remove a single polygon.
   *
   * @param polygon Polygon to remove.
   */
  public removePolygon(polygon: Polygon): void {
    const id = polygon.getId();
    if (id === -1) {
      return;
    }

    this.mapLibreMap.getNativeMapView().removeAnnotations([id]);
    this.polygonMap.delete(id);
  }

  /**
   * Remove polygons in batch.
   *
   * @param polygons Polygons to remove.
   */
  public removePolygons(polygons: Polygon[]): void {
    const ids: number[] = [];

    for (const polygon of polygons) {
      const id = polygon.getId();
      if (id !== -1) {
        ids.push(id);
        this.polygonMap.delete(id);
      }
    }

    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
  }

  /**
   * Update an existing polygon.
   *
   * @param polygon Polygon to update.
   */
  public updatePolygon(polygon: Polygon): void {
    const id = polygon.getId();
    if (id === -1) {
      console.warn('[PolygonManager] Cannot update polygon with id -1');
      return;
    }

    this.mapLibreMap.updatePolygon(polygon);
  }

  /**
   * Remove all polygons.
   */
  public clear(): void {
    const ids = Array.from(this.polygonMap.keys());
    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
    this.polygonMap.clear();
  }

  /**
   * Get all polygons.
   *
   * @returns Array of polygons.
   */
  public getPolygons(): Polygon[] {
    return Array.from(this.polygonMap.values());
  }
}

