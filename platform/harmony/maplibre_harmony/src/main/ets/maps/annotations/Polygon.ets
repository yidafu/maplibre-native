/**
 * Polygon - ArkTS wrapper for polygon annotations.
 *
 * Provides an ArkTS-compliant implementation.
 */
import maplibre from 'libmaplibre.so';
import { AnnotationBase, AnnotationInternalTag } from './AnnotationBase';
import { LatLng } from '../geometry/LatLng';
import { MapLibreMap } from '../MapLibreMap';
import type { ILatLng } from '../types/NativeTypes';

/**
 * Native polygon options interface (used for NAPI interop).
 */
interface NativePolygonOptions {
  points: ILatLng[];
  holes: ILatLng[][];
  fillColor: string;
  strokeColor: string;
  strokeWidth: number;
  fillAlpha: number;
  strokeAlpha: number;
  visible: boolean;
  zIndex: number;
}
/**
 * PolygonOptions - configuration interface for polygons.
 */
export interface PolygonOptions {
  /** Optional polygon ID. */
  id?: string;

  /** Array of polygon vertices. */
  points: LatLng[];

  /** Optional array of holes. */
  holes?: LatLng[][];

  /** Optional fill color (default #000000). */
  fillColor?: string;

  /** Optional stroke color (default #000000). */
  strokeColor?: string;

  /** Optional stroke width (default 1). */
  strokeWidth?: number;

  /** Optional fill opacity (default 0.5, range 0-1). */
  fillAlpha?: number;

  /** Optional stroke opacity (default 1.0, range 0-1). */
  strokeAlpha?: number;

  /** Optional visibility flag (default true). */
  visible?: boolean;

  /** Optional z-index (default 0). */
  zIndex?: number;
}

/**
 * Polygon wrapper.
 */
export class Polygon extends AnnotationBase<maplibre.Polygon> {

  /**
   * Constructor supporting two modes:
   * 1. Create from options: `new Polygon(options)`
   * 2. Create from a NAPI instance (internal use): `new Polygon(marker, nativeInstance)`
   */
  constructor(optionsOrPolygon: PolygonOptions | AnnotationInternalTag, nativeInstance?: maplibre.Polygon) {
    let native: maplibre.Polygon;
    if (optionsOrPolygon === AnnotationInternalTag.INSTANCE && nativeInstance) {
      // Internal mode: construct from NAPI instance
      native = nativeInstance;
    } else if (typeof optionsOrPolygon === 'object') {
      // Standard mode: construct from options
      const options = optionsOrPolygon as PolygonOptions;

      // Convert LatLng objects to native format
      const nativeOptions: NativePolygonOptions = {
        points: options.points.map((p: LatLng): ILatLng => p.toObject()),
        holes: options.holes ? options.holes.map((hole: LatLng[]): ILatLng[] =>
        hole.map((p: LatLng): ILatLng => p.toObject())
        ) : [],
        fillColor: options.fillColor || '#000000',
        strokeColor: options.strokeColor || '#000000',
        strokeWidth: options.strokeWidth !== undefined ? options.strokeWidth : 1,
        fillAlpha: options.fillAlpha !== undefined ? options.fillAlpha : 0.5,
        strokeAlpha: options.strokeAlpha !== undefined ? options.strokeAlpha : 1.0,
        visible: options.visible !== undefined ? options.visible : true,
        zIndex: options.zIndex || 0
      };

      native = new maplibre.Polygon(nativeOptions as PolygonOptions);
    } else {
      throw new Error('Invalid Polygon constructor arguments');
    }
    super(native);
  }

  /**
   * Construct from a NAPI instance (internal use).
   */
  static fromNative(nativeInstance: maplibre.Polygon): Polygon {
    return new Polygon(AnnotationInternalTag.INSTANCE, nativeInstance);
  }

  /**
   * Create a polygon from options (factory helper).
   */
  static createFromOptions(options: PolygonOptions): Polygon {
    return new Polygon(options);
  }

  // ========== Polygon API ==========

  /**
   * Get polygon vertices.
   * @returns Array of points.
   */
  getPoints(): LatLng[] {
    const nativePoints: ILatLng[] = this.nativeInstance.getPoints() as ILatLng[];
    return nativePoints.map((pt: ILatLng): LatLng => new LatLng(pt.latitude, pt.longitude));
  }

  /**
   * Set polygon vertices.
   * @param points Array of points.
   * @returns `this` for chaining.
   */
  setPoints(points: LatLng[]): Polygon {
    const nativePoints: ILatLng[] = points.map((p: LatLng): ILatLng => p.toObject());
    this.nativeInstance.setPoints(nativePoints);
    return this;
  }

  /**
   * Add a point to the polygon.
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
   * @returns Removed point or null if the index is invalid.
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
   * Get polygon holes.
   * @returns Array of holes, each represented by an array of points.
   */
  getHoles(): LatLng[][] {
    const nativeHoles: ILatLng[][] = this.nativeInstance.getHoles() as ILatLng[][];
    return nativeHoles.map((hole: ILatLng[]): LatLng[] =>
    hole.map((pt: ILatLng): LatLng => new LatLng(pt.latitude, pt.longitude))
    );
  }

  /**
   * Set polygon holes.
   * @param holes Array of holes.
   * @returns `this` for chaining.
   */
  setHoles(holes: LatLng[][]): Polygon {
    const nativeHoles: ILatLng[][] = holes.map((hole: LatLng[]): ILatLng[] =>
    hole.map((p: LatLng): ILatLng => p.toObject())
    );
    this.nativeInstance.setHoles(nativeHoles);
    return this;
  }

  /**
   * Add a hole.
   * @param hole Hole represented as points.
   */
  addHole(hole: LatLng[]): void {
    const nativeHole: ILatLng[] = hole.map((p: LatLng): ILatLng => p.toObject());
    this.nativeInstance.addHole(nativeHole);
  }

  /**
   * Remove a hole by index.
   * @param index Hole index.
   * @returns Removed hole or null if the index is invalid.
   */
  removeHole(index: number): LatLng[] | null {
    const nativeHole = this.nativeInstance.removeHole(index);
    if (!nativeHole) {
      return null;
    }
    const holes = nativeHole as ILatLng[];
    return holes.map((pt: ILatLng): LatLng => new LatLng(pt.latitude, pt.longitude));
  }

  /**
   * Get fill color.
   * @returns Color string.
   */
  getFillColor(): string {
    return this.nativeInstance.getFillColor();
  }

  /**
   * Set fill color.
   * @param color Color string (e.g. '#FF0000' or 'red').
   * @returns `this` for chaining.
   */
  setFillColor(color: string): Polygon {
    this.nativeInstance.setFillColor(color);
    return this;
  }

  /**
   * Get stroke color.
   * @returns Color string.
   */
  getStrokeColor(): string {
    return this.nativeInstance.getStrokeColor();
  }

  /**
   * Set stroke color.
   * @param color Color string (e.g. '#FF0000' or 'red').
   * @returns `this` for chaining.
   */
  setStrokeColor(color: string): Polygon {
    this.nativeInstance.setStrokeColor(color);
    return this;
  }

  /**
   * Get stroke width.
   * @returns Width in pixels.
   */
  getStrokeWidth(): number {
    return this.nativeInstance.getStrokeWidth();
  }

  /**
   * Set stroke width.
   * @param width Width in pixels.
   * @returns `this` for chaining.
   */
  setStrokeWidth(width: number): Polygon {
    this.nativeInstance.setStrokeWidth(width);
    return this;
  }

  /**
   * Get fill opacity.
   * @returns Opacity value (0-1).
   */
  getFillAlpha(): number {
    return this.nativeInstance.getFillAlpha();
  }

  /**
   * Set fill opacity.
   * @param alpha Opacity (0-1, where 0 is transparent).
   * @returns `this` for chaining.
   */
  setFillAlpha(alpha: number): Polygon {
    this.nativeInstance.setFillAlpha(alpha);
    return this;
  }

  /**
   * Get stroke opacity.
   * @returns Opacity value (0-1).
   */
  getStrokeAlpha(): number {
    return this.nativeInstance.getStrokeAlpha();
  }

  /**
   * Set stroke opacity.
   * @param alpha Opacity (0-1, where 0 is transparent).
   * @returns `this` for chaining.
   */
  setStrokeAlpha(alpha: number): Polygon {
    this.nativeInstance.setStrokeAlpha(alpha);
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
  setVisible(visible: boolean): Polygon {
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
  setZIndex(zIndex: number): Polygon {
    this.nativeInstance.setZIndex(zIndex);
    return this;
  }

  // ========== Extended methods (internal use) ==========

  /**
   * Get the polygon ID (internal use).
   */
  getId(): number {
    return this.nativeInstance.getId();
  }

  /**
   * Set the polygon ID (internal use).
   */
  setId(id: number): Polygon {
    this.nativeInstance.setId(id);
    return this;
  }

  /**
   * Associate the polygon with a MapLibreMap (internal use).
   * @param map MapLibreMap instance.
   * @returns `this` for chaining.
   */
  setMapLibreMap(map: MapLibreMap): Polygon {
    // this.nativeInstance.setMapLibreMap(map);
    return this;
  }

  /**
   * Convert to string representation.
   * @returns String with ID, point count, and hole count.
   */
  public toString(): string {
    return `Polygon(id=${this.getId()}, points=${this.getPoints().length}, holes=${this.getHoles().length})`;
  }
}
