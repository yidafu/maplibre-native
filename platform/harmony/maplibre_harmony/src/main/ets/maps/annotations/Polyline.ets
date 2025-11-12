/**
 * Polyline - ArkTS wrapper for polyline annotations.
 *
 * Provides an ArkTS-compliant implementation.
 */
import maplibre from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import { MapLibreMap } from '../MapLibreMap';
import type { ILatLng } from '../types/NativeTypes';

/**
 * Native polyline options interface (used for NAPI interop).
 */
interface NativePolylineOptions {
  points: ILatLng[];
  color: string;
  width: number;
  alpha: number;
  visible: boolean;
  zIndex: number;
  pattern: number[] | null;
  jointType: string;
  capType: string;
}

/**
 * PolylineOptions - configuration interface for polylines.
 */
export interface PolylineOptions {
  /** Optional polyline ID. */
  id?: string;

  /** Array of polyline points. */
  points: LatLng[];

  /** Optional line color (default #000000). */
  color?: string;

  /** Optional line width (default 10). */
  width?: number;

  /** Optional line opacity (default 1.0, range 0-1). */
  alpha?: number;

  /** Optional visibility flag (default true). */
  visible?: boolean;

  /** Optional z-index (default 0). */
  zIndex?: number;

  /** Optional dash pattern (e.g. [5, 5] means 5 px line, 5 px gap). */
  pattern?: number[] | null;

  /** Optional join type (default 'round'). */
  jointType?: string;

  /** Optional cap type (default 'round'). */
  capType?: string;
}

/**
 * Internal constructor tag.
 */
class InternalPolyline {
  static readonly INSTANCE = new InternalPolyline();

  private constructor() {
  }
}

/**
 * Polyline wrapper.
 */
export class Polyline {
  private nativeInstance: maplibre.Polyline;

  /**
   * Constructor supporting two modes:
   * 1. Create from options: `new Polyline(options)`
   * 2. Create from a NAPI instance (internal use): `new Polyline(marker, nativeInstance)`
   */
  constructor(optionsOrPolyline: PolylineOptions | InternalPolyline, nativeInstance?: maplibre.Polyline) {
    if (optionsOrPolyline === InternalPolyline.INSTANCE && nativeInstance) {
      // Internal mode: construct from NAPI instance
      this.nativeInstance = nativeInstance;
    } else if (typeof optionsOrPolyline === 'object') {
      // Standard mode: construct from options
      const options = optionsOrPolyline as PolylineOptions;

      // Convert LatLng objects to native format
      const nativeOptions: NativePolylineOptions = {
        points: options.points.map((p: LatLng): ILatLng => p.toObject()),
        color: options.color || '#000000',
        width: options.width !== undefined ? options.width : 10,
        alpha: options.alpha !== undefined ? options.alpha : 1.0,
        visible: options.visible !== undefined ? options.visible : true,
        zIndex: options.zIndex || 0,
        pattern: options.pattern !== undefined ? options.pattern : null,
        jointType: options.jointType || 'round',
        capType: options.capType || 'round'
      };

      this.nativeInstance = new maplibre.Polyline(nativeOptions as PolylineOptions);
    } else {
      throw new Error('Invalid Polyline constructor arguments');
    }
  }

  /**
   * Construct from a NAPI instance (internal use).
   */
  static fromNative(nativeInstance: maplibre.Polyline): Polyline {
    return new Polyline(InternalPolyline.INSTANCE, nativeInstance);
  }

  /**
   * Create a polyline from options (factory helper).
   */
  static createFromOptions(options: PolylineOptions): Polyline {
    return new Polyline(options);
  }

  /**
   * Retrieve the native polyline (internal use).
   */
  getNative(): maplibre.Polyline {
    return this.nativeInstance;
  }

  // ========== Polyline API ==========

  /**
   * Get polyline vertices.
   * @returns Array of points.
   */
  getPoints(): LatLng[] {
    const nativePoints: ILatLng[] = this.nativeInstance.getPoints() as ILatLng[];
    return nativePoints.map((pt: ILatLng): LatLng => new LatLng(pt.latitude, pt.longitude));
  }

  /**
   * Set polyline vertices.
   * @param points Array of points.
   * @returns `this` for chaining.
   */
  setPoints(points: LatLng[]): Polyline {
    const nativePoints: ILatLng[] = points.map((p: LatLng): ILatLng => p.toObject());
    this.nativeInstance.setPoints(nativePoints);
    return this;
  }

  /**
   * Add a point to the end of the polyline.
   * @param point Point to add.
   */
  addPoint(point: LatLng): void {
    this.nativeInstance.addPoint(point.toObject());
  }

  /**
   * Insert a point at the specified index.
   * @param index Target index.
   * @param point Point to insert.
   */
  insertPoint(index: number, point: LatLng): void {
    this.nativeInstance.insertPoint(index, point.toObject());
  }

  /**
   * Remove a point by index.
   * @param index Point index.
   * @returns Removed point, or null if the index is invalid.
   */
  removePoint(index: number): LatLng | null {
    const nativePoint = this.nativeInstance.removePoint(index);
    if (nativePoint) {
      const pt = nativePoint as ILatLng;
      return new LatLng(pt.latitude, pt.longitude);
    }
    return null;
  }

  /**
   * Get line color.
   * @returns Color string.
   */
  getColor(): string {
    return this.nativeInstance.getColor();
  }

  /**
   * Set line color.
   * @param color Color string (e.g. '#FF0000' or 'red').
   * @returns `this` for chaining.
   */
  setColor(color: string): Polyline {
    this.nativeInstance.setColor(color);
    return this;
  }

  /**
   * Get line width.
   * @returns Width in pixels.
   */
  getWidth(): number {
    return this.nativeInstance.getWidth();
  }

  /**
   * Set line width.
   * @param width Width in pixels.
   * @returns `this` for chaining.
   */
  setWidth(width: number): Polyline {
    this.nativeInstance.setWidth(width);
    return this;
  }

  /**
   * Get line opacity.
   * @returns Opacity value (0-1).
   */
  getAlpha(): number {
    return this.nativeInstance.getAlpha();
  }

  /**
   * Set line opacity.
   * @param alpha Opacity (0-1, where 0 is transparent).
   * @returns `this` for chaining.
   */
  setAlpha(alpha: number): Polyline {
    this.nativeInstance.setAlpha(alpha);
    return this;
  }

  /**
   * Get visibility.
   * @returns Visibility flag.
   */
  getVisible(): boolean {
    return this.nativeInstance.getVisible();
  }

  /**
   * Set visibility.
   * @param visible Visibility flag.
   * @returns `this` for chaining.
   */
  setVisible(visible: boolean): Polyline {
    this.nativeInstance.setVisible(visible);
    return this;
  }

  /**
   * Alias for `isVisible`.
   * @returns Visibility flag.
   */
  isVisible(): boolean {
    return this.getVisible();
  }

  /**
   * Get z-index.
   * @returns Z-index value.
   */
  getZIndex(): number {
    return this.nativeInstance.getZIndex();
  }

  /**
   * Set z-index.
   * @param zIndex Z-index value (higher values render on top).
   * @returns `this` for chaining.
   */
  setZIndex(zIndex: number): Polyline {
    this.nativeInstance.setZIndex(zIndex);
    return this;
  }

  /**
   * Get line pattern/dash array.
   * @returns Pattern array or null (e.g. [5, 5] for 5 px line, 5 px gap).
   */
  getPattern(): number[] | null {
    return this.nativeInstance.getPattern();
  }

  /**
   * Set line pattern/dash array.
   * @param pattern Pattern array or null (e.g. [5, 5] for 5 px line, 5 px gap).
   * @returns `this` for chaining.
   */
  setPattern(pattern: number[] | null): Polyline {
    this.nativeInstance.setPattern(pattern);
    return this;
  }

  /**
   * Get line join type.
   * @returns Join type ('round' | 'bevel' | 'miter').
   */
  getJointType(): string {
    return this.nativeInstance.getJointType();
  }

  /**
   * Set line join type.
   * @param jointType Join type ('round' | 'bevel' | 'miter').
   * @returns `this` for chaining.
   */
  setJointType(jointType: string): Polyline {
    this.nativeInstance.setJointType(jointType);
    return this;
  }

  /**
   * Get line cap type.
   * @returns Cap type ('round' | 'butt' | 'square').
   */
  getCapType(): string {
    return this.nativeInstance.getCapType();
  }

  /**
   * Set line cap type.
   * @param capType Cap type ('round' | 'butt' | 'square').
   * @returns `this` for chaining.
   */
  setCapType(capType: string): Polyline {
    this.nativeInstance.setCapType(capType);
    return this;
  }

  // ========== Extended methods (internal use) ==========

  /**
   * Get the polyline ID (internal use).
   */
  getId(): number {
    return this.nativeInstance.getId();
  }

  /**
   * Set the polyline ID (internal use).
   */
  setId(id: number): Polyline {
    this.nativeInstance.setId(id);
    return this;
  }

  /**
   * Associate the polyline with a MapLibreMap (internal use).
   * @param map MapLibreMap instance.
   * @returns `this` for chaining.
   */
  setMapLibreMap(map: MapLibreMap): Polyline {
    // Note: NAPI setMapLibreMap is called internally
    return this;
  }

  /**
   * Convert to string representation.
   * @returns String containing ID, point count, and color.
   */
  public toString(): string {
    return `Polyline(id=${this.getId()}, points=${this.getPoints().length}, color=${this.getColor()})`;
  }
}
