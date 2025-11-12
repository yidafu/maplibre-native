import maplibre from 'libmaplibre.so';
import { InfoWindow, InfoWindowPosition, InfoWindowStyle } from './InfoWindow';
import { InfoWindowAdapter } from './InfoWindowAdapter';
import { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from '../listeners/OnInfoWindowCloseListener';
import { OnInfoWindowLongClickListener } from '../listeners/OnInfoWindowLongClickListener';
import { Point } from '../geometry/Point';
import { Marker } from './Marker';

/**
 * InfoWindowManager - InfoWindow controller
 *
 * Manages display and dismissal of all InfoWindows.
 *
 * Reference:
 * - Android: InfoWindowManager.java
 */
export class InfoWindowManager {
  private infoWindows: Map<number, InfoWindow> = new Map();
  private adapter: InfoWindowAdapter | null = null;
  private onClickListener: OnInfoWindowClickListener | null = null;
  private onLongClickListener: OnInfoWindowLongClickListener | null = null;
  private onCloseListener: OnInfoWindowCloseListener | null = null;
  private allowConcurrentMultiple: boolean = false;
  // UI callbacks notifying external layer to show/hide/update
  private onShowUICallback?: (marker: Marker, position: InfoWindowPosition) => void;
  private onHideUICallback?: (marker: Marker) => void;
  private onUpdateUICallback?: (marker: Marker, position: InfoWindowPosition) => void;

  /**
   * Register UI show callback
   */
  setOnShowUICallback(callback: (marker: Marker, position: InfoWindowPosition) => void): void {
    console.info(`[InfoWindowManager] setOnShowUICallback called`);
    this.onShowUICallback = callback;
  }

  /**
   * Register UI hide callback
   */
  setOnHideUICallback(callback: (marker: Marker) => void): void {
    this.onHideUICallback = callback;
  }

  /**
   * Register UI update callback
   */
  setOnUpdateUICallback(callback: (marker: Marker, position: InfoWindowPosition) => void): void {
    this.onUpdateUICallback = callback;
  }

  /**
   * Assign InfoWindowAdapter
   */
  setAdapter(adapter: InfoWindowAdapter | null): void {
    this.adapter = adapter;
  }

  /**
   * Retrieve InfoWindowAdapter
   */
  getAdapter(): InfoWindowAdapter | null {
    return this.adapter;
  }

  /**
   * Set click listener
   */
  setOnClickListener(listener: OnInfoWindowClickListener | null): void {
    this.onClickListener = listener;
  }

  /**
   * Get click listener
   */
  getOnClickListener(): OnInfoWindowClickListener | null {
    return this.onClickListener;
  }

  /**
   * Set long-click listener
   */
  setOnLongClickListener(listener: OnInfoWindowLongClickListener | null): void {
    this.onLongClickListener = listener;
  }

  /**
   * Get long-click listener
   */
  getOnLongClickListener(): OnInfoWindowLongClickListener | null {
    return this.onLongClickListener;
  }

  /**
   * Set close listener
   */
  setOnCloseListener(listener: OnInfoWindowCloseListener | null): void {
    this.onCloseListener = listener;
  }

  /**
   * Get close listener
   */
  getOnCloseListener(): OnInfoWindowCloseListener | null {
    return this.onCloseListener;
  }

  /**
   * Control whether multiple InfoWindows may be shown simultaneously
   */
  setAllowConcurrentMultiple(allow: boolean): void {
    this.allowConcurrentMultiple = allow;
  }

  /**
   * Check whether multiple InfoWindows are allowed simultaneously
   */
  isAllowConcurrentMultiple(): boolean {
    return this.allowConcurrentMultiple;
  }

  /**
   * Show InfoWindow for a marker
   * @param marker Marker instance
   * @param screenWidth Screen width
   * @param screenHeight Screen height
   * @param markerScreenPosition Marker screen coordinates
   * @param style Optional InfoWindow style
   */
  show(marker: Marker, screenWidth: number, screenHeight: number, markerScreenPosition: Point,
    style?: InfoWindowStyle): InfoWindow | null {
    console.info(`[InfoWindowManager] show() called for marker: ${marker.getTitle()}, screenWidth: ${screenWidth}, screenHeight: ${screenHeight}, markerPos: (${markerScreenPosition.x}, ${markerScreenPosition.y})`);
    console.info(`[InfoWindowManager] onShowUICallback is ${this.onShowUICallback ? 'defined' : 'null/undefined'}`);
    
    // Close existing windows if multiple display not allowed
    if (!this.allowConcurrentMultiple) {
      this.closeAll();
    }

    // Ensure marker has content to display
    if (!this.isValidForMarker(marker)) {
      console.warn('[InfoWindowManager] Marker has no title or snippet, cannot show InfoWindow');
      return null;
    }
    
    console.info(`[InfoWindowManager] Marker has valid content, proceeding to create/show InfoWindow`);

    // Create or retrieve InfoWindow
    const markerId = marker.getId();
    let infoWindow = this.infoWindows.get(markerId);

    if (!infoWindow) {
      // Instantiate InfoWindow with style
      infoWindow = new InfoWindow(marker, style);

      // Configure callbacks
      infoWindow.setOnShowCallback((m: Marker, pos: InfoWindowPosition) => {
        if (this.onShowUICallback) {
          this.onShowUICallback(m, pos);
        }
      });

      infoWindow.setOnCloseCallback((m: Marker) => {
        if (this.onHideUICallback) {
          this.onHideUICallback(m);
        }
        if (this.onCloseListener) {
          this.onCloseListener.onInfoWindowClose(m);
        }
      });

      infoWindow.setOnUpdateCallback((m: Marker, pos: InfoWindowPosition) => {
        if (this.onUpdateUICallback) {
          this.onUpdateUICallback(m, pos);
        }
      });

      this.infoWindows.set(markerId, infoWindow);
    } else if (style) {
      // Update style when InfoWindow exists and new style provided
      infoWindow.setStyle(style);
    }

    // Display InfoWindow
    console.info(`[InfoWindowManager] Calling infoWindow.show()`);
    infoWindow.show(screenWidth, screenHeight, markerScreenPosition);
    console.info(`[InfoWindowManager] InfoWindow.show() completed, isShown: ${infoWindow.isShown()}`);

    return infoWindow;
  }

  /**
   * Close InfoWindow for specific marker
   */
  close(marker: Marker): void {
    const infoWindow = this.infoWindows.get(marker.getId());
    if (infoWindow && infoWindow.isShown()) {
      infoWindow.close();
    }
  }

  /**
   * Close all InfoWindows
   */
  closeAll(): void {
    let closedCount = 0;
    this.infoWindows.forEach(infoWindow => {
      if (infoWindow.isShown()) {
        infoWindow.close();
        closedCount++;
      }
    });

    if (closedCount > 0) {
    }
  }

  /**
   * Determine whether marker has InfoWindow content
   */
  isValidForMarker(marker: Marker): boolean {
    const title = marker.getTitle();
    const snippet = marker.getSnippet();
    const hasTitle = title ? title.length > 0 : false;
    const hasSnippet = snippet ? snippet.length > 0 : false;
    return hasTitle || hasSnippet;
  }

  /**
   * Retrieve InfoWindow for marker
   */
  get(marker: Marker): InfoWindow | null {
    return this.infoWindows.get(marker.getId()) || null;
  }

  /**
   * Update positions for all visible InfoWindows
   * @param screenWidth Screen width
   * @param screenHeight Screen height
   * @param getMarkerScreenPosition Function returning marker screen position
   */
  updatePositions(
    screenWidth: number,
    screenHeight: number,
    getMarkerScreenPosition: (marker: Marker) => Point
  ): void {
    console.info(`[InfoWindowManager] updatePositions called, infoWindows count: ${this.infoWindows.size}`);
    
    this.infoWindows.forEach(infoWindow => {
      if (infoWindow.isShown()) {
        const marker = infoWindow.getMarker();
        const markerPos = getMarkerScreenPosition(marker);
        console.info(`[InfoWindowManager] Updating InfoWindow for marker: ${marker.getTitle()}, pos: (${markerPos.x}, ${markerPos.y})`);
        infoWindow.update(screenWidth, screenHeight, markerPos);
      }
    });
  }

  /**
   * Trigger InfoWindow click event
   */
  triggerClick(marker: Marker): boolean {
    if (this.onClickListener) {
      this.onClickListener.onInfoWindowClick(marker);
      return true;
    }
    return false;
  }

  /**
   * Trigger InfoWindow long-click event
   */
  triggerLongClick(marker: Marker): boolean {
    if (this.onLongClickListener) {
      this.onLongClickListener.onInfoWindowLongClick(marker);
      return true;
    }
    return false;
  }

  /**
   * Get all visible InfoWindows
   */
  getVisibleInfoWindows(): InfoWindow[] {
    const visible: InfoWindow[] = [];
    this.infoWindows.forEach(infoWindow => {
      if (infoWindow.isShown()) {
        visible.push(infoWindow);
      }
    });
    return visible;
  }
}

