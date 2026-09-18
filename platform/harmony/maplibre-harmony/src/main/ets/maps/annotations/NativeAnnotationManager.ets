import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import type { MapLibreMap } from '../MapLibreMap';
import { AnnotationBase } from './AnnotationBase';

/**
 * NativeAnnotationManager - shared base for annotation managers backed by the
 * native annotation system (`nativeMapView.addPolylines` / `addPolygons`).
 *
 * Owns the id -> wrapper registry and implements the generic add / batch-add /
 * remove / update / clear / query flow. Subclasses only supply the
 * type-specific wrapper construction and native round-trips.
 *
 * Differs from `MarkerManager`, which uses a GeoJSON-based approach.
 *
 * Reference: Android `PolylineContainer` / `PolygonContainer` implementations.
 */
export abstract class NativeAnnotationManager<T extends AnnotationBase<Object>, O> {
  protected mapLibreMap: MapLibreMap;
  private annotationMap: Map<number, T> = new Map();
  private logTag: string;
  private label: string;

  /**
   * Constructor.
   *
   * @param mapLibreMap MapLibreMap instance.
   * @param logTag HiLog tag (e.g. 'PolylineManager').
   * @param label Annotation name used in log/error messages (e.g. 'polyline').
   */
  constructor(mapLibreMap: MapLibreMap, logTag: string, label: string) {
    this.mapLibreMap = mapLibreMap;
    this.logTag = logTag;
    this.label = label;
  }

  // ===== Type-specific hooks =====

  /**
   * Create a wrapper instance from user-facing options.
   */
  protected abstract create(options: O): T;

  /**
   * Register newly created wrappers on the native side.
   *
   * @returns Assigned ids in the same order as the input wrappers.
   */
  protected abstract addToNative(annotations: T[]): number[];

  /**
   * Push an updated wrapper to the native side.
   */
  protected abstract updateOnNative(annotation: T): void;

  /**
   * Read the native id of a wrapper (-1 when not yet assigned).
   */
  protected abstract readId(annotation: T): number;

  /**
   * Write the native id back onto a wrapper.
   */
  protected abstract writeId(annotation: T, id: number): void;

  // ===== Shared flow =====

  /**
   * Add a single annotation.
   */
  protected addOne(options: O): T {
    try {
      // Create annotation object
      const annotation = this.create(options);

      // Invoke native API (returns an array of IDs)
      const ids = this.addToNative([annotation]);

      if (ids.length > 0) {
        const id = ids[0];
        this.writeId(annotation, id);
        this.annotationMap.set(id, annotation);
      }

      return annotation;
    } catch (error) {
      const message = `Failed to add ${this.label}: ${error}`;
      this.logError(message);
      throw new Error(message);
    }
  }

  /**
   * Add annotations in batch.
   */
  protected addMany(optionsList: O[]): T[] {
    try {
      // Create annotation objects
      const annotations: T[] = [];
      for (const options of optionsList) {
        annotations.push(this.create(options));
      }

      // Add them to the map in batch
      const ids = this.addToNative(annotations);

      // Assign IDs and register them
      for (let i = 0; i < annotations.length; i++) {
        const annotation = annotations[i];
        const id = ids[i];
        this.writeId(annotation, id);
        this.annotationMap.set(id, annotation);
      }

      return annotations;
    } catch (error) {
      const message = `Failed to add ${this.label}s batch: ${error}`;
      this.logError(message);
      throw new Error(message);
    }
  }

  /**
   * Remove a single annotation.
   */
  protected removeOne(annotation: T): void {
    const id = this.readId(annotation);
    if (id === -1) {
      return;
    }

    this.mapLibreMap.getNativeMapView().removeAnnotations([id]);
    this.annotationMap.delete(id);
  }

  /**
   * Remove annotations in batch.
   */
  protected removeMany(annotations: T[]): void {
    const ids: number[] = [];

    for (const annotation of annotations) {
      const id = this.readId(annotation);
      if (id !== -1) {
        ids.push(id);
        this.annotationMap.delete(id);
      }
    }

    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
  }

  /**
   * Update an existing annotation.
   */
  protected updateOne(annotation: T): void {
    const id = this.readId(annotation);
    if (id === -1) {
      hilog.warn(DOMAIN, this.logTag, '%{public}s', `[${this.logTag}] Cannot update ${this.label} with id -1`);
      return;
    }

    this.updateOnNative(annotation);
  }

  /**
   * Remove all annotations.
   */
  protected clearAll(): void {
    const ids = Array.from(this.annotationMap.keys());
    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
    this.annotationMap.clear();
  }

  /**
   * Get all annotations.
   */
  protected getAll(): T[] {
    return Array.from(this.annotationMap.values());
  }

  private logError(message: string): void {
    hilog.error(DOMAIN, this.logTag, '%{public}s', `[${this.logTag}] ${message}`);
  }
}
