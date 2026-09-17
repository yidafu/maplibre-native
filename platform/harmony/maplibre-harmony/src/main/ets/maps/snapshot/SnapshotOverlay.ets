import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
/**
 * SnapshotOverlay - helper for drawing overlays on map snapshots.
 *
 * Provides utilities to draw the MapLibre logo and attribution text on snapshot images.
 * Mirrors the Android `MapSnapshotter.addOverlay()` pattern.
 */

import image from '@ohos.multimedia.image';
import { drawing } from '@kit.ArkGraphics2D';
import { MapSnapshot } from './MapSnapshot';

/**
 * Logo placement enumeration.
 */
export enum LogoPosition {
  BOTTOM_LEFT = 0,
  BOTTOM_RIGHT = 1,
  TOP_LEFT = 2,
  TOP_RIGHT = 3
}

/**
 * Attribution placement enumeration.
 */
export enum AttributionPosition {
  BOTTOM_LEFT = 0,
  BOTTOM_RIGHT = 1,
  TOP_LEFT = 2,
  TOP_RIGHT = 3
}

/**
 * Overlay configuration options.
 */
export interface OverlayOptions {
  /**
   * Logo position.
   * Default: BOTTOM_LEFT.
   */
  logoPosition?: LogoPosition;
  
  /**
   * Attribution position.
   * Default: BOTTOM_RIGHT.
   */
  attributionPosition?: AttributionPosition;
  
  /**
   * Margin in pixels.
   * Default: 8.
   */
  margin?: number;
  
  /**
   * Logo scale factor.
   * Default: 1.0.
   */
  logoScale?: number;
  
  /**
   * Attribution text size.
   * Default: 10.
   */
  attributionTextSize?: number;
  
  /**
   * Whether to draw the logo.
   * Default: true.
   */
  drawLogo?: boolean;
  
  /**
   * Whether to draw attribution text.
   * Default: true.
   */
  drawAttribution?: boolean;
}

/**
 * SnapshotOverlay class.
 *
 * Draws logos and attribution strings onto map snapshots.
 *
 * @example
 * ```typescript
 * // Add default overlay
 * await SnapshotOverlay.addOverlay(snapshot);
 * 
 * // Customize placement and style
 * await SnapshotOverlay.addOverlay(snapshot, {
 *   logoPosition: LogoPosition.BOTTOM_RIGHT,
 *   attributionPosition: AttributionPosition.BOTTOM_LEFT,
 *   margin: 12
 * });
 * 
 * // Draw the logo only
 * await SnapshotOverlay.drawLogo(snapshot.getImage());
 * ```
 */
export class SnapshotOverlay {
  private static readonly DEFAULT_MARGIN = 8;
  private static readonly DEFAULT_LOGO_SCALE = 1.0;
  private static readonly DEFAULT_TEXT_SIZE = 10;

  /**
   * Draw the MapLibre logo onto the snapshot.
   *
   * @param pixelMap Snapshot image.
   * @param position Logo placement.
   * @param margin Margin in pixels.
   * @param scale Logo scale factor.
   * @returns Promise<void>
   */
  public static async drawLogo(
    pixelMap: image.PixelMap,
    position: LogoPosition = LogoPosition.BOTTOM_LEFT,
    margin: number = SnapshotOverlay.DEFAULT_MARGIN,
    scale: number = SnapshotOverlay.DEFAULT_LOGO_SCALE
  ): Promise<void> {
    // TODO: implement logo drawing
    // 1. Load MapLibre logo resources.
    // 2. Compute the drawing position based on `position`.
    // 3. Use the drawing API to render onto pixelMap.
    
    hilog.warn(DOMAIN, 'SnapshotOverlay', '%{public}s', '[SnapshotOverlay] drawLogo: Not yet implemented - requires graphics.drawing API');
  }

  /**
   * Draw attribution text onto the snapshot.
   *
   * @param pixelMap Snapshot image.
   * @param attributions Attribution strings.
   * @param position Attribution placement.
   * @param margin Margin in pixels.
   * @param textSize Text size.
   * @returns Promise<void>
   */
  public static async drawAttributions(
    pixelMap: image.PixelMap,
    attributions: string[],
    position: AttributionPosition = AttributionPosition.BOTTOM_RIGHT,
    margin: number = SnapshotOverlay.DEFAULT_MARGIN,
    textSize: number = SnapshotOverlay.DEFAULT_TEXT_SIZE
  ): Promise<void> {
    if (!attributions || attributions.length === 0) {
      return;
    }

    // TODO: implement attribution drawing
    // 1. Merge attribution text.
    // 2. Compute drawing position based on `position`.
    // 3. Use the drawing API to place text on the pixelMap.
    
    hilog.warn(DOMAIN, 'SnapshotOverlay', '%{public}s', '[SnapshotOverlay] drawAttributions: Not yet implemented - requires graphics.drawing API');
  }

  /**
   * Add both logo and attribution overlays automatically.
   *
   * Mirrors Android `MapSnapshotter.addOverlay(MapSnapshot)`.
   *
   * @param snapshot MapSnapshot instance.
   * @param options Optional configuration.
   * @returns Promise<void>
   *
   * @example
   * ```typescript
   * snapshotter.start({
   *   onSnapshotReady: async (snapshot) => {
   *     // Add both logo and attribution overlays
   *     await SnapshotOverlay.addOverlay(snapshot);
   *     
   *     // Use the snapshot
   *     const pixelMap = snapshot.getImage();
   *   }
   * });
   * ```
   */
  public static async addOverlay(
    snapshot: MapSnapshot,
    options?: OverlayOptions
  ): Promise<void> {
    // Use explicit types to avoid object literal mismatches
    const logoPos: LogoPosition = options?.logoPosition ?? LogoPosition.BOTTOM_LEFT;
    const attrPos: AttributionPosition = options?.attributionPosition ?? AttributionPosition.BOTTOM_RIGHT;
    const margin: number = options?.margin ?? SnapshotOverlay.DEFAULT_MARGIN;
    const logoScale: number = options?.logoScale ?? SnapshotOverlay.DEFAULT_LOGO_SCALE;
    const attrTextSize: number = options?.attributionTextSize ?? SnapshotOverlay.DEFAULT_TEXT_SIZE;
    const drawLogo: boolean = options?.drawLogo !== false;
    const drawAttribution: boolean = options?.drawAttribution !== false;

    const pixelMap = snapshot.getImage();

    try {
      // Draw the logo overlay.
      if (drawLogo && snapshot.showLogo) {
        await SnapshotOverlay.drawLogo(
          pixelMap,
          logoPos,
          margin,
          logoScale
        );
      }

      // Draw attribution overlay.
      if (drawAttribution && snapshot.attributions.length > 0) {
        await SnapshotOverlay.drawAttributions(
          pixelMap,
          snapshot.attributions,
          attrPos,
          margin,
          attrTextSize
        );
      }
    } catch (err) {
      const error = err as Error;
      hilog.error(DOMAIN, 'SnapshotOverlay', '[SnapshotOverlay] addOverlay failed: %{public}s', error.message);
      throw new Error(`Overlay drawing failed: ${error.message}`);
    }
  }
}

