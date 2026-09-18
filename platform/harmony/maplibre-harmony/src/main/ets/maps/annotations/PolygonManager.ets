import type { MapLibreMap } from '../MapLibreMap';
import { Polygon, PolygonOptions } from './Polygon';
import { NativeAnnotationManager } from './NativeAnnotationManager';

/**
 * PolygonManager class.
 *
 * Manages all polygon annotations on the map via the native annotation system.
 * Shared add/remove/update/clear/query plumbing lives in
 * {@link NativeAnnotationManager}.
 */
export class PolygonManager extends NativeAnnotationManager<Polygon, PolygonOptions> {
  /**
   * Constructor.
   *
   * @param mapLibreMap MapLibreMap instance.
   */
  constructor(mapLibreMap: MapLibreMap) {
    super(mapLibreMap, 'PolygonManager', 'polygon');
  }

  protected create(options: PolygonOptions): Polygon {
    return new Polygon(options);
  }

  protected addToNative(polygons: Polygon[]): number[] {
    return this.mapLibreMap.getNativeMapView().addPolygons(polygons);
  }

  protected updateOnNative(polygon: Polygon): void {
    this.mapLibreMap.updatePolygon(polygon);
  }

  protected readId(polygon: Polygon): number {
    return polygon.getId();
  }

  protected writeId(polygon: Polygon, id: number): void {
    polygon.setId(id);
  }

  /**
   * Add a single polygon.
   *
   * @param options PolygonOptions instance.
   * @returns Created polygon.
   */
  public addPolygon(options: PolygonOptions): Polygon {
    return this.addOne(options);
  }

  /**
   * Add multiple polygons.
   *
   * @param optionsList Array of PolygonOptions.
   * @returns Array of created polygons.
   */
  public addPolygons(optionsList: PolygonOptions[]): Polygon[] {
    return this.addMany(optionsList);
  }

  /**
   * Remove a single polygon.
   *
   * @param polygon Polygon to remove.
   */
  public removePolygon(polygon: Polygon): void {
    this.removeOne(polygon);
  }

  /**
   * Remove polygons in batch.
   *
   * @param polygons Polygons to remove.
   */
  public removePolygons(polygons: Polygon[]): void {
    this.removeMany(polygons);
  }

  /**
   * Update an existing polygon.
   *
   * @param polygon Polygon to update.
   */
  public updatePolygon(polygon: Polygon): void {
    this.updateOne(polygon);
  }

  /**
   * Remove all polygons.
   */
  public clear(): void {
    this.clearAll();
  }

  /**
   * Get all polygons.
   *
   * @returns Array of polygons.
   */
  public getPolygons(): Polygon[] {
    return this.getAll();
  }
}
