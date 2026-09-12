import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import { LatLng } from '../geometry/LatLng';
import { CenterOffset } from './ViewAnnotationUtils';

import { Marker } from './Marker';

/**
 * AnnotationView custom content builder type
 *
 * Supplies custom UI content for an AnnotationView.
 *
 * @param marker Associated marker
 * @returns Builder function that renders custom content
 *
 * @example
 * ```typescript
 * const customBuilder: AnnotationViewBuilder = (marker: Marker) => {
 *   return () => {
 *     Column() {
 *       Image($r('app.media.custom_icon'))
 *         .width(40)
 *         .height(40)
 *       Text(marker.getTitle())
 *         .fontSize(12)
 *     }
 *   };
 * };
 * ```
 */
export type AnnotationViewBuilder = (marker: Marker) => (() => void) | null;

/**
 * AnnotationView size configuration
 */
export interface AnnotationViewSize {
  width: number;
  height: number;
}

/**
 * AnnotationViewConfig - AnnotationView configuration
 *
 * Defines properties and behavior for custom AnnotationViews.
 *
 * References:
 * - iOS: MLNAnnotationView properties
 * - Android: Marker configuration options
 *
 * @example
 * ```typescript
 * const config: AnnotationViewConfig = {
 *   reuseIdentifier: 'custom-marker',
 *   contentBuilder: () => {
 *     Column() {
 *       Image($r('app.media.pin')).width(32).height(32)
 *       Text('Label').fontSize(10)
 *     }
 *   },
 *   draggable: true,
 *   scalesWithViewingDistance: true,
 *   centerOffset: { dx: 0, dy: -16 }
 * };
 * ```
 */
export interface AnnotationViewConfig {
  /**
   * Reuse identifier
   *
   * Views sharing the same identifier can be reused for performance.
   *
   * Reference: iOS MLNAnnotationView.reuseIdentifier
   */
  reuseIdentifier: string;

  /**
   * Custom content builder
   *
   * Provides custom UI rendered as a marker-anchored ViewAnnotation.
   * A config without a contentBuilder produces no custom view (the marker
   * falls back to its default symbol icon). The builder closure is bridged
   * into the ComponentContent pipeline internally; omitting size lets the
   * SDK measure the content and anchor on its real bounds.
   *
   * @example
   * ```typescript
   * contentBuilder: () => {
   *   Stack() {
   *     Image($r('app.media.marker'))
   *       .width(40)
   *       .height(40)
   *   }
   * }
   * ```
   */
  contentBuilder?: () => void;

  /**
   * Draggable flag
   *
   * When true, users can long-press and drag the AnnotationView.
   *
   * Reference: iOS MLNAnnotationView.draggable
   *
   * @default false
   */
  draggable?: boolean;

  /**
   * Distance-based scaling
   *
   * When enabled, views near the horizon shrink during pitch to simulate perspective.
   *
   * Reference: iOS MLNAnnotationView.scalesWithViewingDistance
   *
   * @default false
   */
  scalesWithViewingDistance?: boolean;

  /**
   * Rotate with map
   *
   * When true, the AnnotationView rotates with the map.
   *
   * Reference: iOS MLNAnnotationView.rotatesToMatchCamera
   *
   * @default false
   */
  rotatesToMatchCamera?: boolean;

  /**
   * Center offset
   *
   * Adjusts the view center relative to the marker.
   * Positive values move right/down; negative left/up.
   *
   * Reference: iOS MLNAnnotationView.centerOffset
   *
   * @default { dx: 0, dy: 0 }
   */
  centerOffset?: CenterOffset;

  /**
   * Initial selection state
   *
   * Sets the initial selection state of the view.
   *
   * Reference: iOS MLNAnnotationView.selected
   *
   * @default false
   */
  selected?: boolean;

  /**
   * Enabled flag
   *
   * Disabled views do not respond to gestures.
   *
   * Reference: iOS MLNAnnotationView.enabled
   *
   * @default true
   */
  enabled?: boolean;

  /**
   * Optional view size
   *
   * Provide explicit size; otherwise content drives layout.
   */
  size?: AnnotationViewSize;

  /**
   * Optional z-index
   *
   * Controls stacking order (higher draws on top). Defaults to marker zIndex.
   */
  zIndex?: number;

  /**
   * Optional initial opacity
   *
   * Sets starting opacity.
   *
   * @default 1.0
   */
  alpha?: number;
}

/**
 * AnnotationViewDelegate - AnnotationView delegate interface
 *
 * Customizes creation and event handling for AnnotationViews.
 *
 * Reference: iOS MLNMapViewDelegate annotation view methods.
 *
 * Usage example:
 * ```typescript
 * const delegate: AnnotationViewDelegate = {
 *   // Create a custom view for specific markers
 *   viewForAnnotation: (marker: Marker) => {
 *     if (marker.getIcon() === 'custom-pin') {
 *       return {
 *         reuseIdentifier: 'custom-pin',
 *         contentBuilder: () => {
 *           Column() {
 *             Image($r('app.media.custom_marker'))
 *               .width(40)
 *               .height(40)
 *             Text(marker.getTitle())
 *               .fontSize(12)
 *               .fontColor(Color.White)
 *           }
 *         },
 *         draggable: true,
 *         scalesWithViewingDistance: true
 *       };
 *     }
 *     return null; // Use the default icon
 *   },
 *
 *   // Handle selection events
 *   didSelectAnnotationView: (marker: Marker) => {
 *     hilog.info(DOMAIN, 'Marker selected:', '%{public}s', marker.getTitle());
 *   },
 *
 *   // Handle drag events
 *   annotationViewDidEndDragging: (marker: Marker, position: LatLng) => {
 *     hilog.info(DOMAIN, 'Marker dragged to:', '%{public}s', position);
 *   }
 * };
 *
 * // Attach to the map
 * mapLibreMap.setAnnotationViewDelegate(delegate);
 * ```
 */
export interface AnnotationViewDelegate {
  /**
   * Request AnnotationView configuration for a marker
   *
   * @param marker Marker instance
   * @returns AnnotationViewConfig or null to use default icon
   *
   * Reference: iOS `mapView:viewForAnnotation:`
   *
   * Invoked when:
   * - Marker is added to the map
   * - Marker enters the visible region (when virtualization enabled)
   * - A view is required from the reuse pool
   *
   * @example
   * ```typescript
 * viewForAnnotation: (marker: Marker) => {
 *   // Return different configs based on marker type
   *   const type = marker.getSnippet();
   *   
   *   if (type === 'restaurant') {
   *     return {
   *       reuseIdentifier: 'restaurant-pin',
   *       contentBuilder: () => {
   *         Image($r('app.media.restaurant_icon'))
   *           .width(32).height(32)
   *       },
   *       centerOffset: { dx: 0, dy: -16 }
   *     };
   *   }
 * 
 *   return null; // Use the default icon
   * }
   * ```
   */
  viewForAnnotation?(marker: Marker): AnnotationViewConfig | null;

  /**
   * Called when AnnotationView is selected
   *
   * @param marker Selected marker
   *
   * Reference: iOS `mapView:didSelectAnnotationView:`
   *
   * Triggered when the user taps the AnnotationView; update styling or show details here.
   */
  didSelectAnnotationView?(marker: Marker): void;

  /**
   * Called when AnnotationView is deselected
   *
   * @param marker Marker being deselected
   *
   * Reference: iOS `mapView:didDeselectAnnotationView:`
   *
   * Triggered when another AnnotationView is selected or the map is tapped; use to restore styling.
   */
  didDeselectAnnotationView?(marker: Marker): void;

  /**
   * AnnotationView will start dragging
   *
   * @param marker Marker about to be dragged
   *
   * Reference: iOS `mapView:annotationView:didChangeDragState:` (starting)
   *
   * Triggered when user long-presses and begins dragging; prepare UI here.
   *
   * @example
   * ```typescript
 * annotationViewWillStartDragging: (marker: Marker) => {
 *   // Adjust opacity to indicate dragging
   *   marker.setAlpha(0.7);
   * }
   * ```
   */
  annotationViewWillStartDragging?(marker: Marker): void;

  /**
   * AnnotationView is being dragged
   *
   * @param marker Marker being dragged
   * @param newPosition Updated geographic position
   *
   * Reference: iOS `mapView:annotationView:didChangeDragState:` (dragging)
   *
   * Called frequently during drag; update UI carefully (avoid heavy work).
   */
  annotationViewDidDrag?(marker: Marker, newPosition: LatLng): void;

  /**
   * AnnotationView finished dragging
   *
   * @param marker Dragged marker
   * @param finalPosition Final geographic position
   *
   * Reference: iOS `mapView:annotationView:didChangeDragState:` (ending)
   *
   * Triggered when the user releases the marker; persist position or cleanup here.
   *
   * @example
   * ```typescript
 * annotationViewDidEndDragging: (marker: Marker, position: LatLng) => {
 *   // Restore opacity
   *   marker.setAlpha(1.0);
 *   // Persist the new position to a server
   *   saveMarkerPosition(marker.getId(), position);
   * }
   * ```
   */
  annotationViewDidEndDragging?(marker: Marker, finalPosition: LatLng): void;

  /**
   * Optional reuse identifier lookup
   *
   * @param marker Marker instance
   * @returns Reuse identifier or undefined
   *
  * If omitted, config.reuseIdentifier from viewForAnnotation is used.
   *
   * @example
   * ```typescript
 * getReuseIdentifier: (marker: Marker) => {
 *   // Return different identifiers based on marker type
   *   return marker.getSnippet() || 'default';
   * }
   * ```
   */
  getReuseIdentifier?(marker: Marker): string | undefined;
}

