import { AnnotationType } from './AnnotationType';
import { MapLibreMap } from '../MapLibreMap';

/**
 * Annotation - base class for map annotations.
 *
 * Abstract base class that manages annotation IDs, map association, and other fundamentals.
 *
 * References:
 * - Android: org.maplibre.android.annotations.Annotation
 *
 * @abstract
 */
export abstract class Annotation {
  /**
   * Unique annotation ID.
   * `-1` indicates the annotation is not yet added to the map.
   * Assigned by `MapLibreMap` when the annotation is added.
   */
  private id: number = -1;
  /**
   * Associated `MapLibreMap` instance.
   */
  protected mapLibreMap: MapLibreMap | null = null;

  /**
   * Constructor.
   */
  protected constructor() {
  }

  /**
   * Get the unique annotation ID.
   *
   * @returns Annotation ID; `-1` means it has not been added to the map.
   */
  public getId(): number {
    return this.id;
  }

  /**
   * Set the annotation ID.
   *
   * Internal use only, invoked by `MapLibreMap`.
   *
   * @param id Annotation ID.
   */
  public setId(id: number): void {
    this.id = id;
  }

  /**
   * Remove this annotation from the map.
   */
  public remove(): void {
    if (this.mapLibreMap === null) {
      return;
    }
    this.mapLibreMap.removeAnnotation(this);
  }

  /**
   * Set the associated `MapLibreMap`.
   *
   * Internal use only, invoked by `MapLibreMap`.
   *
   * @param map `MapLibreMap` instance.
   */
  public setMapLibreMap(map: MapLibreMap): void {
    this.mapLibreMap = map;
  }

  /**
   * Get the associated `MapLibreMap`.
   *
   * @returns `MapLibreMap` instance, or `null` if not added to a map.
   */
  public getMapLibreMap(): MapLibreMap | null {
    return this.mapLibreMap;
  }

  /**
   * Get the annotation type.
   *
   * Must be implemented by subclasses.
   *
   * @returns Annotation type.
   */
  public abstract getType(): AnnotationType;

  /**
   * Determine whether two annotations are equal.
   *
   * @param other Another annotation.
   * @returns `true` if they share the same ID.
   */
  public equals(other: Annotation | null): boolean {
    if (this === other) {
      return true;
    }
    if (other === null) {
      return false;
    }
    return this.id === other.getId();
  }

  /**
   * Compare two annotations by their IDs.
   *
   * @param other Another annotation.
   * @returns `-1`, `0`, or `1`.
   */
  public compareTo(other: Annotation): number {
    if (this.id < other.getId()) {
      return -1;
    } else if (this.id > other.getId()) {
      return 1;
    }
    return 0;
  }

  /**
   * Get the hash code.
   *
   * @returns Hash code.
   */
  public hashCode(): number {
    return this.id;
  }
}

