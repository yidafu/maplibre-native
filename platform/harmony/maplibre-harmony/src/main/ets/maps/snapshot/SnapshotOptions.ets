/**
 * SnapshotOptions - options for map snapshots.
 *
 * Configures `MapSnapshotter`.
 */

import { CameraPosition } from '../camera/CameraPosition';
import { LatLngBounds } from '../geometry/LatLngBounds';
import { Size } from '../types/NativeTypes';

/**
 * Snapshot options interface.
 */
export interface SnapshotOptions {
  /**
   * Output image size.
   */
  size: Size;

  /**
   * Pixel ratio (for high-resolution images).
   * Default: 1.0
   */
  pixelRatio?: number;

  /**
   * Style URL.
   */
  styleUrl: string;

  /**
   * Style JSON (optional, mutually exclusive with styleUrl).
   */
  styleJson?: string;

  /**
   * Camera position (optional).
   */
  cameraPosition?: CameraPosition;

  /**
   * Geographic bounds (optional).
   * If provided, the camera adjusts to fit the region.
   */
  region?: LatLngBounds;

  /**
   * Whether to display the MapLibre logo.
   * Default: true.
   */
  showLogo?: boolean;

  /**
   * Local font family (optional).
   */
  localFontFamily?: string;
}

/**
 * Builder for snapshot options.
 */
export class SnapshotOptionsBuilder {
  private options: SnapshotOptions;

  /**
   * Constructor.
   *
   * @param width Output width.
   * @param height Output height.
   */
  constructor(width: number, height: number) {
    this.options = {
      size: { width, height },
      pixelRatio: 1.0,
      styleUrl: '',
      showLogo: true
    };
  }

  /**
   * Set pixel ratio.
   */
  withPixelRatio(pixelRatio: number): SnapshotOptionsBuilder {
    this.options.pixelRatio = pixelRatio;
    return this;
  }

  /**
   * Set style URL.
   */
  withStyleUrl(styleUrl: string): SnapshotOptionsBuilder {
    this.options.styleUrl = styleUrl;
    return this;
  }

  /**
   * Set style JSON.
   */
  withStyleJson(styleJson: string): SnapshotOptionsBuilder {
    this.options.styleJson = styleJson;
    return this;
  }

  /**
   * Set camera position.
   */
  withCameraPosition(cameraPosition: CameraPosition): SnapshotOptionsBuilder {
    this.options.cameraPosition = cameraPosition;
    return this;
  }

  /**
   * Set geographic bounds.
   */
  withRegion(region: LatLngBounds): SnapshotOptionsBuilder {
    this.options.region = region;
    return this;
  }

  /**
   * Set whether to display the logo.
   */
  withShowLogo(showLogo: boolean): SnapshotOptionsBuilder {
    this.options.showLogo = showLogo;
    return this;
  }

  /**
   * Set local font family.
   */
  withLocalFontFamily(localFontFamily: string): SnapshotOptionsBuilder {
    this.options.localFontFamily = localFontFamily;
    return this;
  }

  /**
   * Build the snapshot options object.
   */
  build(): SnapshotOptions {
    if (!this.options.styleUrl && !this.options.styleJson) {
      throw new Error('Must specify either styleUrl or styleJson');
    }
    return this.options;
  }
}

