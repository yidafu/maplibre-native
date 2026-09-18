import type { MapLibreMap } from '../MapLibreMap';
import { Polyline, PolylineOptions } from './Polyline';
import { NativeAnnotationManager } from './NativeAnnotationManager';

/**
 * PolylineManager class.
 *
 * Manages all polyline annotations on the map via the native annotation system.
 * Shared add/remove/update/clear/query plumbing lives in
 * {@link NativeAnnotationManager}.
 */
export class PolylineManager extends NativeAnnotationManager<Polyline, PolylineOptions> {
  /**
   * Constructor.
   *
   * @param mapLibreMap MapLibreMap instance.
   */
  constructor(mapLibreMap: MapLibreMap) {
    super(mapLibreMap, 'PolylineManager', 'polyline');
  }

  protected create(options: PolylineOptions): Polyline {
    return new Polyline(options);
  }

  protected addToNative(polylines: Polyline[]): number[] {
    return this.mapLibreMap.getNativeMapView().addPolylines(polylines);
  }

  protected updateOnNative(polyline: Polyline): void {
    this.mapLibreMap.updatePolyline(polyline);
  }

  protected readId(polyline: Polyline): number {
    return polyline.getId();
  }

  protected writeId(polyline: Polyline, id: number): void {
    polyline.setId(id);
  }

  /**
   * Add a single polyline.
   *
   * @param options PolylineOptions instance.
   * @returns Created polyline.
   */
  public addPolyline(options: PolylineOptions): Polyline {
    return this.addOne(options);
  }

  /**
   * Add multiple polylines.
   *
   * @param optionsList Array of PolylineOptions.
   * @returns Array of created polylines.
   */
  public addPolylines(optionsList: PolylineOptions[]): Polyline[] {
    return this.addMany(optionsList);
  }

  /**
   * Remove a single polyline.
   *
   * @param polyline Polyline to remove.
   */
  public removePolyline(polyline: Polyline): void {
    this.removeOne(polyline);
  }

  /**
   * Remove polylines in batch.
   *
   * @param polylines Polylines to remove.
   */
  public removePolylines(polylines: Polyline[]): void {
    this.removeMany(polylines);
  }

  /**
   * Update an existing polyline.
   *
   * @param polyline Polyline to update.
   */
  public updatePolyline(polyline: Polyline): void {
    this.updateOne(polyline);
  }

  /**
   * Remove all polylines.
   */
  public clear(): void {
    this.clearAll();
  }

  /**
   * Get all polylines.
   *
   * @returns Array of polylines.
   */
  public getPolylines(): Polyline[] {
    return this.getAll();
  }
}
