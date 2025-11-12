import maplibre from 'libmaplibre.so';
import { InfoWindowComponent, InfoWindowPosition, InfoWindowStyle } from './InfoWindow';
import { InfoWindowManager } from './InfoWindowManager';
import { Marker } from './Marker';

/**
 * InfoWindow state data.
 */
export interface InfoWindowState {
  marker: Marker; // Keep a reference for callbacks
  // Rendering data below (avoids passing NAPI objects through @Prop)
  markerId: number;
  markerTitle: string;
  markerSnippet: string;
  position: InfoWindowPosition;
  style?: InfoWindowStyle;
  key: string; // Unique key for ForEach
}

/**
 * InfoWindowOverlay - InfoWindow rendering layer.
 *
 * Renders all InfoWindows as an overlay above the map.
 *
 * Usage:
 * ```typescript
 * Stack() {
 *   // Map layer
 *   XComponent(...)
 *
 *   // InfoWindow layer
 *   InfoWindowOverlay({ manager: this.infoWindowManager })
 * }
 * ```
 */
@Component
export struct InfoWindowOverlay {
  @Link @Watch('onInfoWindowsChanged') visibleInfoWindows: InfoWindowState[];
  // Event callbacks
  onInfoWindowClick?: (marker: Marker) => void;
  onInfoWindowLongClick?: (marker: Marker) => void;
  onInfoWindowClose?: (marker: Marker) => void;
  onInfoWindowSizeChanged?: (marker: Marker, width: number, height: number) => void;

  /**
   * Callback triggered when the InfoWindow list changes.
   */
  onInfoWindowsChanged() {
    console.info(`[InfoWindowOverlay] visibleInfoWindows changed, count: ${this.visibleInfoWindows.length}`);
  }

  build() {
    Stack() {
      // Render every visible InfoWindow
      ForEach(
        this.visibleInfoWindows,
        (infoWindowState: InfoWindowState) => {
          InfoWindowComponent({
            markerId: infoWindowState.markerId,
            markerTitle: infoWindowState.markerTitle,
            markerSnippet: infoWindowState.markerSnippet,
            arrowOffsetX: infoWindowState.position.arrowOffsetX,
            customStyle: infoWindowState.style,
            onWindowClick: () => {
              if (this.onInfoWindowClick) {
                this.onInfoWindowClick(infoWindowState.marker);
              }
            },
            onLongClick: () => {
              if (this.onInfoWindowLongClick) {
                this.onInfoWindowLongClick(infoWindowState.marker);
              }
            },
            onClose: () => {
              if (this.onInfoWindowClose) {
                this.onInfoWindowClose(infoWindowState.marker);
              }
            },
            onSizeChanged: (width: number, height: number) => {
              if (this.onInfoWindowSizeChanged) {
                this.onInfoWindowSizeChanged(infoWindowState.marker, width, height);
              }
            }
          })
            .position({
              x: infoWindowState.position.x,
              y: infoWindowState.position.y
            })
        },
        (infoWindowState: InfoWindowState) => infoWindowState.key
      )
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None) // Do not intercept events; allow passthrough to the map
  }
}

