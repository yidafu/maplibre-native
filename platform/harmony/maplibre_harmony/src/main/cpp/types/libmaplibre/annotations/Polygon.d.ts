import type { LatLng } from '../NativeMapView';

/**
 * Polygon options.
 */
export interface PolygonOptions {
  /** Polygon vertices. */
  points: LatLng[];

  /** Optional array of holes. */
  holes?: LatLng[][];

  /** Optional fill color. */
  fillColor?: string;

  /** Optional stroke color. */
  strokeColor?: string;

  /** Optional stroke width. */
  strokeWidth?: number;

  /** Optional fill alpha (0-1). */
  fillAlpha?: number;

  /** Optional stroke alpha (0-1). */
  strokeAlpha?: number;

  /** Optional visibility flag. */
  visible?: boolean;

  /** Optional Z-index. */
  zIndex?: number;
}

/**
 * Polygon - polygon annotation (NAPI object).
 *
 * Renders polygon overlays with support for fill, stroke, and holes.
 */
export class Polygon {
  /**
   * Constructor.
   * @param options Polygon options.
   */
  constructor(options: PolygonOptions);

  /**
   * Get polygon vertices.
   * @returns Array of coordinates.
   */
  getPoints(): LatLng[];

  /**
   * Set polygon vertices.
   * @param points Coordinate array.
   */
  setPoints(points: LatLng[]): void;

  /**
   * Append a vertex.
   * @param point Coordinate.
   */
  addPoint(point: LatLng): void;

  /**
   * Insert a vertex at an index.
   * @param index Target index.
   * @param point Coordinate.
   */
  insertPoint(index: number, point: LatLng): void;

  /**
   * Remove a vertex.
   * @param index Vertex index.
   * @returns Removed coordinate, or null if the index is invalid.
   */
  removePoint(index: number): LatLng | null;

  /**
   * Get polygon holes.
   * @returns Array of holes, each a coordinate array.
   */
  getHoles(): LatLng[][];

  /**
   * Set polygon holes.
   * @param holes Hole array.
   */
  setHoles(holes: LatLng[][]): void;

  /**
   * Append a hole.
   * @param hole Coordinate array.
   */
  addHole(hole: LatLng[]): void;

  /**
   * Remove a hole.
   * @param index Hole index.
   * @returns Removed hole coordinates, or null if the index is invalid.
   */
  removeHole(index: number): LatLng[] | null;

  /**
   * Get the fill color.
   */
  getFillColor(): string;

  /**
   * Set the fill color.
   * @param color CSS color string.
   */
  setFillColor(color: string): void;

  /**
   * Get the stroke color.
   */
  getStrokeColor(): string;

  /**
   * Set the stroke color.
   * @param color CSS color string.
   */
  setStrokeColor(color: string): void;

  /**
   * Get the stroke width.
   */
  getStrokeWidth(): number;

  /**
   * Set the stroke width.
   * @param width Width value.
   */
  setStrokeWidth(width: number): void;

  /**
   * Get the fill alpha.
   */
  getFillAlpha(): number;

  /**
   * Set the fill alpha.
   * @param alpha Alpha value (0-1).
   */
  setFillAlpha(alpha: number): void;

  /**
   * Get the stroke alpha.
   */
  getStrokeAlpha(): number;

  /**
   * Set the stroke alpha.
   * @param alpha Alpha value (0-1).
   */
  setStrokeAlpha(alpha: number): void;

  /**
   * Get the visibility flag.
   */
  getVisible(): boolean;

  /**
   * Set the visibility.
   * @param visible True to display.
   */
  setVisible(visible: boolean): void;

  /**
   * Get the Z-index.
   */
  getZIndex(): number;

  /**
   * Set the Z-index.
   * @param zIndex Z-order value.
   */
  setZIndex(zIndex: number): void;

  /**
   * Get the identifier.
   */
  getId(): number;

  /**
   * Set the identifier (internal use).
   * @internal
   * @param id Identifier.
   */
  setId(id: number): void;

  // Note: setMapLibreMap is an internal detail and not part of the public API.
  // ETS polygon wrappers manage MapLibreMap associations.
}

