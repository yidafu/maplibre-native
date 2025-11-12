import type { LatLng } from '../NativeMapView';

/**
 * Polyline options.
 */
export interface PolylineOptions {
  /** Polyline vertices. */
  points: LatLng[];

  /** Optional line color (default #000000). */
  color?: string;

  /** Optional line width (default 10). */
  width?: number;

  /** Optional line alpha (default 1.0, range 0-1). */
  alpha?: number;

  /** Optional visibility flag (default true). */
  visible?: boolean;

  /** Optional Z-index (default 0). */
  zIndex?: number;

  /** Optional pattern (for example [5, 5] for 5px dash, 5px gap). */
  pattern?: number[] | null;

  /** Optional joint type (default 'round'; accepts 'round' | 'bevel' | 'miter'). */
  jointType?: string;

  /** Optional cap type (default 'round'; accepts 'round' | 'butt' | 'square'). */
  capType?: string;
}

/**
 * Polyline - polyline annotation (NAPI object).
 *
 * Renders polyline overlays with configurable color, width, and dash patterns.
 */
export class Polyline {
  /**
   * Constructor.
   * @param options Polyline options.
   */
  constructor(options: PolylineOptions);

  /**
   * Get polyline vertices.
   * @returns Coordinate array.
   */
  getPoints(): LatLng[];

  /**
   * Set polyline vertices.
   * @param points Coordinate array.
   */
  setPoints(points: LatLng[]): void;

  /**
   * Append a vertex to the end.
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
   * @returns Removed coordinate, or null when invalid.
   */
  removePoint(index: number): LatLng | null;

  /**
   * Get the line color.
   * @returns CSS color string.
   */
  getColor(): string;

  /**
   * Set the line color.
   * @param color CSS color string (for example '#FF0000' or 'red').
   */
  setColor(color: string): void;

  /**
   * Get the line width.
   * @returns Width in pixels.
   */
  getWidth(): number;

  /**
   * Set the line width.
   * @param width Width in pixels.
   */
  setWidth(width: number): void;

  /**
   * Get the line alpha.
   * @returns Alpha value (0-1).
   */
  getAlpha(): number;

  /**
   * Set the line alpha.
   * @param alpha Alpha value (0-1, where 0 is fully transparent and 1 is opaque).
   */
  setAlpha(alpha: number): void;

  /**
   * Get the visibility state.
   * @returns True when visible.
   */
  getVisible(): boolean;

  /**
   * Set the visibility.
   * @param visible True to display.
   */
  setVisible(visible: boolean): void;

  /**
   * Get the Z-index.
   * @returns Z-index value.
   */
  getZIndex(): number;

  /**
   * Set the Z-index.
   * @param zIndex Z-order value (higher values render above lower ones).
   */
  setZIndex(zIndex: number): void;

  /**
   * Get the dash pattern.
   * @returns Pattern array or null (for example [5, 5]).
   */
  getPattern(): number[] | null;

  /**
   * Set the dash pattern.
   * @param pattern Pattern array or null (for example [5, 5]).
   */
  setPattern(pattern: number[] | null): void;

  /**
   * Get the joint type.
   * @returns Joint type ('round' | 'bevel' | 'miter').
   */
  getJointType(): string;

  /**
   * Set the joint type.
   * @param jointType Joint type ('round' | 'bevel' | 'miter').
   */
  setJointType(jointType: string): void;

  /**
   * Get the cap type.
   * @returns Cap type ('round' | 'butt' | 'square').
   */
  getCapType(): string;

  /**
   * Set the cap type.
   * @param capType Cap type ('round' | 'butt' | 'square').
   */
  setCapType(capType: string): void;

  /**
   * Get the polyline identifier.
   * @returns Identifier value.
   */
  getId(): number;

  /**
   * Set the polyline identifier (internal use).
   * @internal
   * @param id Identifier.
   */
  setId(id: number): void;

  // Note: setMapLibreMap is an internal detail and not part of the public API.
  // ETS polyline wrappers handle the association with MapLibreMap.
}

