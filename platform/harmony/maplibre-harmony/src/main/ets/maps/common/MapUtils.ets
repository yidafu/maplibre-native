/**
 * MapUtils - shared helpers extracted from duplicated boilerplate across
 * MapLibreMap / NativeMapViewController / Projection / ViewAnnotationManager /
 * NativeMapView.
 *
 * Pure module-level functions only: no component state, no decorators, so the
 * file is safe to import from structs and plain classes alike.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import type { NativeMapView } from 'libmaplibre.so';
import { Margins } from '../types/NativeTypes';

/** Fallback pixel ratio when the native value cannot be read. */
const FALLBACK_PIXEL_RATIO: number = 1;

/**
 * Safely read the device pixel ratio from a native map view.
 *
 * Returns 1 when the view is null, the call throws, or the native layer
 * returns a non-finite / non-positive value. Replaces the four copies that
 * previously lived in MapLibreMap.readPixelRatioSafe,
 * ViewAnnotationManager.readPixelRatio, Projection.getPixelRatio and
 * NativeMapViewController.getPixelRatio.
 *
 * @param mapView Native map view (may be null).
 * @param tag Log tag identifying the call site.
 * @returns Positive pixel ratio, or 1 as a safe fallback.
 */
export function safePixelRatio(mapView: NativeMapView | null, tag: string = 'MapUtils'): number {
  if (!mapView) {
    return FALLBACK_PIXEL_RATIO;
  }
  try {
    const ratio = mapView.getPixelRatio?.();
    if (typeof ratio === 'number' && Number.isFinite(ratio) && ratio > 0) {
      return ratio;
    }
  } catch (error) {
    const reason = error instanceof Error ? error.message : `${error}`;
    hilog.warn(DOMAIN, 'MapUtils', '%{public}s', `[${tag}] Failed to read pixel ratio, fallback to 1: ${reason}`);
  }
  return FALLBACK_PIXEL_RATIO;
}

/**
 * Horizontal position of a map widget from its alignment and margins.
 *
 * Start-side alignments pin to the left margin; every other alignment pins to
 * the right edge via `calc(100% - <widget width> - <right margin>)`.
 * Module-level pure function so ArkUI struct methods can call it without
 * touching `this`.
 *
 * @param widgetSizeVp Widget width in vp.
 * @param alignment ArkUI alignment of the widget.
 * @param margins Widget margins in vp.
 * @returns X position usable as an ArkUI `Length`.
 */
export function widgetX(widgetSizeVp: number, alignment: Alignment, margins: Margins): Length {
  switch (alignment) {
    case Alignment.TopStart:
    case Alignment.Start:
    case Alignment.BottomStart:
      return margins.left;
    default:
      return `calc(100% - ${widgetSizeVp}vp - ${margins.right}vp)`;
  }
}

/**
 * Vertical position of a map widget from its alignment and margins.
 *
 * Bottom-side alignments pin to the bottom edge via
 * `calc(100% - <widget height> - <bottom margin>)`; every other alignment pins
 * to the top margin. Module-level pure function (see widgetX).
 *
 * @param widgetSizeVp Widget height in vp.
 * @param alignment ArkUI alignment of the widget.
 * @param margins Widget margins in vp.
 * @returns Y position usable as an ArkUI `Length`.
 */
export function widgetY(widgetSizeVp: number, alignment: Alignment, margins: Margins): Length {
  switch (alignment) {
    case Alignment.BottomStart:
    case Alignment.Bottom:
    case Alignment.BottomEnd:
      return `calc(100% - ${widgetSizeVp}vp - ${margins.bottom}vp)`;
    default:
      return margins.top;
  }
}
