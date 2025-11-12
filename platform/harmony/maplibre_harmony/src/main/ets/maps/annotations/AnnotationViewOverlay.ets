import maplibre from 'libmaplibre.so';
import { AnnotationView, CenterOffset } from './AnnotationView';
import { AnnotationViewData } from './AnnotationViewManager';
import { LatLng } from '../geometry/LatLng';

import { Marker } from './Marker';

/**
 * AnnotationViewOverlay - Rendering layer for AnnotationView instances
 *
 * Acts as an overlay above the map to render all AnnotationViews.
 *
 * References:
 * - iOS: MLNMapView annotationContainerView
 * - Android: Custom ViewGroup overlay
 *
 * Features:
 * - Supports custom view content
 * - Z-index ordering (selected and dragged views appear on top)
 * - Event passthrough (allows map gestures underneath)
 * - Animation support
 *
 * Usage example:
 * ```typescript
 * Stack() {
 *   // Map layer
 *   XComponent(...)
 *
 *   // Annotation layer
 *   AnnotationViewOverlay({
 *     visibleAnnotationViews: $visibleAnnotationViews,
 *     mapBearing: this.mapBearing,
 *     mapPitch: this.mapPitch,
 *     onAnnotationSelect: (marker) => { ... }
 *   })
 * }
 * ```
 */
@Component
export struct AnnotationViewOverlay {
  @Link visibleAnnotationViews: AnnotationViewData[];
  // Map state for advanced behavior
  @Prop mapBearing: number = 0;
  @Prop mapPitch: number = 0;
  @Prop screenWidth: number = 0;
  @Prop screenHeight: number = 0;
  // Event callbacks
  onAnnotationSelect?: (marker: Marker) => void;
  onAnnotationDeselect?: (marker: Marker) => void;
  onAnnotationDragStart?: (marker: Marker) => void;
  onAnnotationDrag?: (marker: Marker, screenX: number, screenY: number) => void;
  onAnnotationDragEnd?: (marker: Marker, screenX: number, screenY: number) => void;
  // Custom view builder factory provided by the consumer
  customViewBuilderFactory?: (marker: Marker) => (() => void) | null;

  /**
   * Build a single AnnotationView
   *
   * Creates an AnnotationView component for each AnnotationViewData entry
   */
  @Builder
  buildAnnotationView(viewData: AnnotationViewData) {
    // 🔒 Prevent ObservedObject errors by ensuring marker is not null
    if (viewData.marker !== null) {
      AnnotationView({
        marker: viewData.marker,
        reuseIdentifier: viewData.reuseIdentifier,
        screenX: viewData.screenX,
        screenY: viewData.screenY,
        centerOffset: viewData.centerOffset,
        anchorU: viewData.anchorU,
        anchorV: viewData.anchorV,
        visible: viewData.visible,
        mapBearing: this.mapBearing,
        mapPitch: this.mapPitch,
        screenHeight: this.screenHeight,
        customContentBuilder: this.resolveCustomContentBuilder(viewData),
        isDraggable: viewData.draggable,
        scalesWithViewingDistance: viewData.scalesWithViewingDistance,
        rotatesToMatchCamera: viewData.rotatesToMatchCamera,
        isEnabled: viewData.enabled,
        selected: viewData.selected,
        viewAlpha: viewData.alpha,
        baseZIndex: viewData.zIndex,
        preferredWidth: viewData.preferredWidth,
        preferredHeight: viewData.preferredHeight,
        nativeScale: viewData.nativeScale ?? 1,
        nativeRotation: viewData.nativeRotation ?? 0,
        nativeOpacity: viewData.nativeOpacity ?? 1,
        reuseVersion: viewData.reuseVersion ?? 0,
        onSelect: (marker: Marker) => {
          if (this.onAnnotationSelect) {
            this.onAnnotationSelect(marker);
          }
        },
        onDeselect: (marker: Marker) => {
          if (this.onAnnotationDeselect) {
            this.onAnnotationDeselect(marker);
          }
        },
        onMarkerDragStart: (marker: Marker) => {
          if (this.onAnnotationDragStart) {
            this.onAnnotationDragStart(marker);
          }
        },
        onDrag: (marker: Marker, screenX: number, screenY: number) => {
          if (this.onAnnotationDrag) {
            this.onAnnotationDrag(marker, screenX, screenY);
          }
        },
        onMarkerDragEnd: (marker: Marker, screenX: number, screenY: number) => {
          if (this.onAnnotationDragEnd) {
            this.onAnnotationDragEnd(marker, screenX, screenY);
          }
        }
      })
    }
  }

  private resolveCustomContentBuilder(viewData: AnnotationViewData): (() => void) | undefined {
    if (viewData.customBuilder) {
      return viewData.customBuilder;
    }
    if (viewData.marker !== null && this.customViewBuilderFactory) {
      return this.customViewBuilderFactory(viewData.marker) ?? undefined;
    }
    return undefined;
  }

  /**
   * Sort AnnotationViews for optimal Z-index ordering
   *
   * Selected or dragged views should render above others
   *
   * @param viewDataArray Array of view data entries
   * @returns Sorted array
   */
  private sortAnnotationViews(viewDataArray: AnnotationViewData[]): AnnotationViewData[] {
    return viewDataArray.slice().sort((a, b) => {
      // Simple ordering: items appended later appear on top (default behavior)
      // ForEach and zIndex handle layering automatically
      return 0;
    });
  }

  build() {
    Stack() {
        ForEach(
          this.visibleAnnotationViews,
          (viewData: AnnotationViewData) => {
            Stack() {
              this.buildAnnotationView(viewData)
            }
              .hitTestBehavior(HitTestMode.Transparent);
          },
          (viewData: AnnotationViewData) => {
            return `annotation-view-${viewData.marker?.getId() ?? 0}`;
          }
        )
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(this.visibleAnnotationViews.length > 0 ? HitTestMode.Transparent : HitTestMode.None)
  }
}

/**
 * Helper: wrap a parameterized Builder so it can be used dynamically
 *
 * Converts a Builder with parameters into a no-arg Builder for AnnotationView
 *
 * @param builder Builder function
 * @param params Parameter object
 * @returns Wrapped no-argument Builder
 */
export function wrapBuilderWithParams<T>(builder: (params: T) => void, params: T): () => void {
  return () => {
    builder(params);
  };
}

