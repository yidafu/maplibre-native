import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import { IconFactory } from './IconFactory';
import { Icon } from './Icon';
import maplibre, { NativeMapView } from 'libmaplibre.so';

/**
 * Icon reference-count record.
 *
 * Stores an icon instance and the number of markers referencing it.
 */
interface IconRefData {
  icon: Icon;
  refCount: number;
}

/**
 * IconManager - icon lifecycle manager.
 *
 * Manages the complete lifecycle of icons built on the NAPI `Icon` class.
 *
 * **Core responsibilities**:
 * 1. **Reference counting**: track how many markers use each icon.
 * 2. **Native synchronization**: automatically load and unload icons in the native map.
 * 3. **Automatic disposal**: release an icon when the reference count drops to zero (calls `release()`).
 * 4. **Icon reuse**: reuse loaded icons by identifier.
 * 5. **Size tracking**: record the maximum icon dimensions (used for gesture hit-testing).
 *
 * **Architecture**:
 * ```
 * IconFactory (creation) → Icon → IconManager (management) → NativeMapView (rendering)
 *                               ↓
 *                        Reference counting
 *                               ↓
 *                        Automatic release
 * ```
 *
 * **Lifecycle methods**:
 * - `addIconToManager()`: add an icon, increment the reference count, and load it to the native map on first use.
 * - `iconCleanup()`: decrement the reference count and release it automatically when it reaches zero.
 * - `cleanup()`: clear all icons and free every resource.
 *
 * **Important notes**:
 * - Use the icon ID (string) as the unique identifier.
 * - An icon cannot be used again once `isReleased() === true`.
 * - To reuse the same visual asset, create a fresh icon instance through `IconFactory`.
 *
 * References:
 * - Android: `org.maplibre.android.annotations.AnnotationManager`
 * - iOS: `MLNAnnotationController`
 *
 * @example
* ```typescript
 * // Basic usage
 * const iconManager = new IconManager(nativeMapView);
 *
 * // Create and register an icon
 * const icon = await iconFactory.fromResource($r('app.media.marker'));
 * await iconManager.addIconToManager(icon);  // refCount = 1
 * marker.setIcon(icon.getId());
 *
 * // Share the icon across markers
 * marker2.setIcon(icon.getId());  // refCount = 2
 *
 * // Clean up when finished
 * iconManager.iconCleanup(icon);  // refCount = 1
 * iconManager.iconCleanup(icon);  // refCount = 0, release automatically
 * ```
 */
export class IconManager {
  // Icon ID → reference-count record
  private iconMap: Map<string, IconRefData> = new Map();
  // Reuse identifier → icon mapping (for icon reuse)
  private reuseIdentifierMap: Map<string, Icon> = new Map();
  // Native map view reference
  private nativeMapView: NativeMapView | null = null;
  // Largest icon size (used for gesture hit-testing)
  private highestIconWidth: number = 0;
  private highestIconHeight: number = 0;
  // Icon factory reference
  public iconFactory: IconFactory | null = null;

  /**
   * Constructor.
   *
   * @param nativeMapView Native map view instance used to communicate with the C++ layer.
   * @param iconFactory Optional `IconFactory` instance; defaults to the global singleton.
   */
  constructor(nativeMapView: NativeMapView, iconFactory?: IconFactory) {
    this.nativeMapView = nativeMapView;
    this.iconFactory = iconFactory || IconFactory.getInstance();
  }

  /**
   * Load the icon for a marker.
   *
   * The process is fully automated:
   * 1. If the marker already has an icon ID, fetch it from the cache.
   * 2. If no icon is set, load and assign the default icon.
   * 3. Increment the icon reference count.
   * 4. Load the icon into the native map on first use.
   *
   * @param marker Marker instance.
   * @returns Promise that resolves to the wrapped `Icon` instance.
   * @throws Error When the icon is not cached or the load fails.
   */
  public async loadIconForMarker(marker: maplibre.Marker): Promise<Icon> {
    try {
      // Fetch the marker icon ID
      let iconId: string | null = marker.getIcon();
      let icon: Icon;

      if (!iconId) {
        // Marker has no icon; load the default icon
        icon = await this.loadDefaultIconForMarker(marker);
        iconId = icon.getId();
      } else {
        // Retrieve the cached icon
        const cached = this.iconMap.get(iconId);
        if (cached) {
          icon = cached.icon;
        } else {
          // Icon not found in cache; this usually indicates misuse
          throw new Error(
            `[IconManager] Icon '${iconId}' not found in cache. ` +
              'Make sure to call addIconToManager() before using the icon.'
          );
        }
        // Update the maximum icon dimensions
        this.updateHighestIconSize(icon);
      }

      // Add the icon (increase ref-count and load to native on first use)
      await this.addIcon(icon);

      return icon;
    } catch (error) {
      hilog.error(DOMAIN, 'IconManager', '[IconManager] Failed to load icon for marker: %{public}s', error);
      throw new Error(`[IconManager] Failed to load icon for marker: ${error}`);
    }
  }

  /**
   * Load the default icon (private helper).
   *
   * Retrieves the default icon from `IconFactory` and assigns it to the marker.
   *
   * @param marker Marker instance.
   * @returns Promise resolving to the default wrapped `Icon`.
   * @throws Error When `IconFactory` is not initialized or the load fails.
   */
  private async loadDefaultIconForMarker(marker: maplibre.Marker): Promise<Icon> {
    if (!this.iconFactory) {
      throw new Error('[IconManager] IconFactory is not initialized');
    }

    // Acquire the default icon from the factory
    const icon = await this.iconFactory.defaultMarker();

    // Update maximum icon dimensions (Android parity: height / 2)
    const width = icon.getWidth();
    const height = icon.getHeight() / 2;
    this.updateHighestIconSize(width, height);

    // Assign the default icon ID to the marker
    marker.setIcon(icon.getId());

    return icon;
  }

  /**
   * Add an icon to the cache (private helper).
   *
   * **Reference counting**:
   * - First addition: `refCount = 1` and optionally load it to the native map.
   * - Repeated additions: `refCount++` without reloading.
   *
   * @param icon Wrapped `Icon` instance.
   * @param addIconToMap Whether to load it into the native map (default true).
   */
  private async addIcon(icon: Icon, addIconToMap: boolean = true): Promise<void> {
    const iconId = icon.getId();
    const cached = this.iconMap.get(iconId);

    if (!cached) {
      // First time seeing this icon
      const refData: IconRefData = { icon, refCount: 1 };
      this.iconMap.set(iconId, refData);

      if (addIconToMap) {
        await this.loadIconToNative(icon);
      } else {
      }

    } else {
      // Icon already cached; increment ref-count
      cached.refCount++;
    }
  }

  /**
   * Add an icon to the manager.
   *
   * Primary public API that brings an icon under lifecycle management.
   *
   * **Use cases**:
   * - A marker sets a custom icon that must be tracked.
   * - Multiple markers share the same icon.
   *
   * **Automatically handles**:
   * - Loading the icon into the native map on first use.
   * - Managing the reference count.
   * - Ensuring the icon has not been released.
   *
   * @param icon Wrapped `Icon` instance (must be valid and not released).
   * @throws Error If the icon has already been released.
   *
   * @example
  * ```typescript
   * const icon = await iconFactory.fromResource($r('app.media.marker'));
   * marker.setIcon(icon.getId());
   * await iconManager.addIconToManager(icon);  // Register for lifecycle management
   * ```
   */
  public async addIconToManager(icon: Icon): Promise<void> {
    // Ensure the icon has not been released
    if (icon.isReleased()) {
      throw new Error(
        `[IconManager] Cannot add released Icon '${icon.getId()}'. ` +
          'After calling markerManager.clear() or marker.remove(), ' +
          'the Icon is released and cannot be reused. ' +
          'You must create a new Icon through IconFactory.'
      );
    }

    // Cache the icon and load it into the native map
    await this.addIcon(icon, true);
  }

  /**
   * Retrieve a cached icon by reuse identifier.
   *
   * Mirrors iOS `dequeueReusableAnnotationImageWithIdentifier`.
   *
   * @param reuseIdentifier Reuse identifier.
   * @returns Wrapped `Icon` instance, or null if missing or released.
   */
  public dequeueReusableIcon(reuseIdentifier: string): Icon | null {
    const icon = this.reuseIdentifierMap.get(reuseIdentifier);

    // Ensure the icon exists and has not been released
    if (icon && icon.isReleased()) {
      // If the icon was released, remove it from the reuse map and return null
      hilog.warn(DOMAIN, 'IconManager', '%{public}s', `[IconManager] Reusable icon '${reuseIdentifier}' was released, removing from reuse map`);
      this.reuseIdentifierMap.delete(reuseIdentifier);
      return null;
    }

    return icon || null;
  }

  /**
   * Get or load the icon assigned to a marker.
   *
   * Automatically handles icon reuse and default icon fallback.
   *
   * @param marker Marker instance.
   * @param defaultIconProvider Optional provider for a default icon.
   * @returns Promise resolving to the wrapped `Icon`.
   */
  public async getOrLoadIcon(marker: maplibre.Marker, defaultIconProvider?: () => Promise<Icon>): Promise<Icon> {
    try {
      let iconId: string | null = marker.getIcon();
      let icon: Icon;

      if (!iconId) {
        // No icon present: use the supplied or default icon
        if (defaultIconProvider) {
          icon = await defaultIconProvider();
        } else {
          if (!this.iconFactory) {
            throw new Error('[IconManager] IconFactory is not initialized');
          }
          icon = await this.iconFactory.defaultMarker();
        }
        marker.setIcon(icon.getId());
        iconId = icon.getId();
      } else {
        // Check whether the icon is already cached
        const cached = this.iconMap.get(iconId);
        if (cached) {
          icon = cached.icon;
        } else {
          throw new Error(`Icon ${iconId} not found in cache`);
        }
      }

      // Update the maximum icon dimensions
      this.updateHighestIconSize(icon);

      return icon;
    } catch (error) {
      hilog.error(DOMAIN, 'IconManager', '[IconManager] Failed to get or load icon: %{public}s', error);
      throw new Error('Failed to get or load icon: ' + error);
    }
  }

  /**
   * Update the icon bound to a marker.
   *
   * Automatically decrements the old icon reference count and increments the new one.
   *
   * @param marker Marker instance.
   * @param oldIcon Previous wrapped icon (nullable).
   * @param newIcon Replacement wrapped icon.
   */
  public async updateMarkerIcon(marker: maplibre.Marker, oldIcon: Icon | null, newIcon: Icon): Promise<void> {
    try {
      // Decrease the reference count for the existing icon
      if (oldIcon) {
        this.iconCleanup(oldIcon);
      }

      // Update the marker icon ID
      marker.setIcon(newIcon.getId());

      // Register the new icon (increments the reference count)
      await this.addIconToManager(newIcon);

      // Update the maximum icon dimensions
      this.updateHighestIconSize(newIcon);

    } catch (error) {
      hilog.error(DOMAIN, 'IconManager', '[IconManager] Failed to update marker icon: %{public}s', error);
      throw new Error('Failed to update marker icon: ' + error);
    }
  }

  /**
   * Load an icon into the native layer (private helper).
   *
   * Uploads the icon to the native map style so that SymbolLayer can reference it.
   *
   * **NAPI Icon advantages**:
   * - Pass icon objects directly without PixelMap-to-bytes conversion.
   * - The C++ layer accesses `PremultipliedImage` data directly.
   * - Avoids data copies and serialization overhead.
   *
   * @param icon Wrapped `Icon` instance.
   * @throws Error If the icon has been released or `NativeMapView` is uninitialized.
   */
  private async loadIconToNative(icon: Icon): Promise<void> {
    try {
      // 1. Validate icon state
      if (icon.isReleased()) {
        throw new Error(
          `Cannot load released Icon '${icon.getId()}' to native. ` +
            'Icon has been released and cannot be reused.'
        );
      }

      // 2. Ensure the native map view is present
      if (!this.nativeMapView) {
        throw new Error('[IconManager] NativeMapView is not initialized');
      }

      // 3. Gather icon metadata for logging
      const iconId = icon.getId();
      const width = icon.getWidth();
      const height = icon.getHeight();
      const scale = icon.getScale();

      // 4. Invoke the native API with the NAPI icon object
      // Benefit: the C++ layer accesses `PremultipliedImage` directly without extra conversion
      this.nativeMapView.addAnnotationIcon(icon.getNative());

    } catch (error) {
      const iconId = icon.getId();
      hilog.error(DOMAIN, 'IconManager', '%{public}s', `[IconManager] Failed to load icon '${iconId}' to native: ${error}`);
      throw new Error(`[IconManager] Failed to load icon '${iconId}' to native: ${error}`);
    }
  }

  /**
   * Clean up an icon (decrement its reference count).
   *
   * Core resource-management method that enables automatic reclamation.
   *
   * **Reference-counting rules**:
   * - `refCount > 1`: decrement the count and keep the icon cached.
   * - `refCount === 1`: drop the count to zero and release the resources.
   *
   * **Automatic release pipeline** (when `refCount` reaches 0):
   * 1. Remove the icon from the native layer.
   * 2. Delete it from the local cache.
   * 3. Call `icon.release()` to free the C++ image data.
   *
   * **Important notes**:
   * - Once an icon is released (`isReleased() === true`), it cannot be used again.
   * - To reuse the artwork, create a new icon through `IconFactory`.
   *
   * @param iconOrId Icon instance or icon ID string.
   *
   * @example
  * ```typescript
   * // Option 1: pass an Icon instance
   * iconManager.iconCleanup(icon);
   *
   * // Option 2: pass an icon ID
   * iconManager.iconCleanup('com.maplibre.icons.icon_1');
   * ```
   */
  public iconCleanup(iconOrId: Icon | string): void {
    const iconId = typeof iconOrId === 'string' ? iconOrId : iconOrId.getId();
    const cached = this.iconMap.get(iconId);

    if (!cached) {
      hilog.warn(DOMAIN, 'IconManager', '%{public}s', `[IconManager] Icon '${iconId}' not found in cache, cannot cleanup`);
      return;
    }

    if (cached.refCount === 1) {
      // When refCount reaches zero after cleanup, perform full removal
      this.remove(cached.icon);
    } else {
      // For refCount > 1, just decrement
      cached.refCount--;
    }
  }

  /**
   * Remove an icon from both the cache and native layer (private helper).
   *
   * Performs the full removal workflow:
   * 1. Remove it from the native map style.
   * 2. Delete it from the local cache.
   * 3. Call `icon.release()` to free the C++ resources.
   *
   * @param icon Wrapped `Icon` instance.
   */
  private remove(icon: Icon): void {
    const iconId = icon.getId();

    try {
      // 1. Remove the icon from the native layer
      if (!this.nativeMapView) {
        throw new Error('[IconManager] NativeMapView is not initialized');
      }
      this.nativeMapView.removeAnnotationIcon(iconId);

      // 2. Remove it from the cache
      this.iconMap.delete(iconId);

      // 3. Release icon resources (C++ `PremultipliedImage`)
      if (!icon.isReleased()) {
        icon.release();
      }
    } catch (error) {
      hilog.error(DOMAIN, 'IconManager', '%{public}s', `[IconManager] Failed to remove icon '${iconId}': ${error}`);
    }
  }

  /**
   * Reload every icon.
   *
   * Useful when the map is restored or reinitialized.
   */
  public async reloadIcons(): Promise<void> {

    let successCount = 0;
    let failCount = 0;

    for (const cached of this.iconMap.values()) {
      try {
        await this.loadIconToNative(cached.icon);
        successCount++;
      } catch (error) {
        hilog.error(DOMAIN, 'IconManager', '%{public}s', `[IconManager] Failed to reload icon ${cached.icon.getId()}: ${error}`);
        failCount++;
      }
    }

  }

  /**
   * Ensure the marker's icon is loaded.
   *
   * Guarantees the icon exists when updating a marker.
   *
   * @param marker Marker instance.
   */
  public async ensureIconLoaded(marker: maplibre.Marker): Promise<void> {
    const iconId: string | null = marker.getIcon();
    if (!iconId) {
      const icon = await this.loadDefaultIconForMarker(marker);
      marker.setIcon(icon.getId());
      await this.addIcon(icon);
    } else {
      // Icon ID exists; ensure it is loaded
      const cached = this.iconMap.get(iconId);
      if (cached) {
        await this.addIcon(cached.icon);
      }
    }
  }

  /**
   * Get the top offset for an icon (used for anchor calculations).
   *
   * @param icon Wrapped `Icon` instance.
   * @returns Top offset in pixels.
   */
  public getTopOffsetPixelsForIcon(icon: Icon): number {
    try {
      if (!this.nativeMapView) {
        throw new Error('[IconManager] NativeMapView is not initialized');
      }
      // TODO: `NativeMapView` has no `getPixelRatio()` method; fall back to the default value
      const pixelRatio: number = 1.0;
      const topOffset: number = this.nativeMapView.getTopOffsetPixelsForAnnotationSymbol(icon.getId());
      return topOffset * pixelRatio;
    } catch (error) {
      hilog.warn(DOMAIN, 'IconManager', '%{public}s', `[IconManager] Failed to get top offset for icon ${icon.getId()}: ${error}`);
      return 0;
    }
  }

  /**
   * Get the maximum icon width.
   *
   * @returns Maximum width in pixels.
   */
  public getHighestIconWidth(): number {
    return this.highestIconWidth;
  }

  /**
   * Get the maximum icon height.
   *
   * @returns Maximum height in pixels.
   */
  public getHighestIconHeight(): number {
    return this.highestIconHeight;
  }

  /**
   * Get the height of a specific icon.
   *
   * @param iconId Icon identifier.
   * @returns Icon height in logical pixels, or 0 when missing.
   */
  public getIconHeight(iconId: string): number {
    const iconRefData = this.iconMap.get(iconId);
    if (iconRefData) {
      return iconRefData.icon.getHeight();
    }
    return 0;
  }

  /**
   * Get the width of a specific icon.
   *
   * @param iconId Icon identifier.
   * @returns Icon width in logical pixels, or 0 when missing.
   */
  public getIconWidth(iconId: string): number {
    const iconRefData = this.iconMap.get(iconId);
    if (iconRefData) {
      return iconRefData.icon.getWidth();
    }
    return 0;
  }

  /**
   * Update the cached maximum icon size (icon overload).
   *
   * @param iconOrWidth Icon instance or width value.
   * @param height Optional height when providing width directly.
   */
  private updateHighestIconSize(iconOrWidth: Icon | number, height?: number): void {
    let width: number;
    let h: number;
    let iconId = '';

    if (typeof iconOrWidth === 'number') {
      // Width and height provided directly
      width = iconOrWidth;
      h = height!;
    } else {
      // Icon instance provided
      width = iconOrWidth.getWidth();
      h = iconOrWidth.getHeight();
      iconId = iconOrWidth.getId();
    }

    let updated = false;
    if (width > this.highestIconWidth) {
      this.highestIconWidth = width;
      updated = true;
    }
    if (h > this.highestIconHeight) {
      this.highestIconHeight = h;
      updated = true;
    }

    if (updated || width === 0 || h === 0) {
    }
  }

  /**
   * Clean up all icons.
   *
   * Fully reset the `IconManager` and release every resource.
   * Typically invoked when the map is destroyed or reset.
   *
   * **Cleanup steps**:
   * 1. Iterate over all cached icons.
   * 2. Remove each icon from the native layer.
   * 3. Release each icon's C++ resources.
   * 4. Clear every cache and tracking field.
   *
   * **Notes**:
   * - After cleanup, all icons are released and cannot be reused.
   * - References to released icons become invalid.
   *
   * @example
  * ```typescript
   * // Clean up when the map is destroyed
   * onDestroy() {
   *   iconManager.cleanup();
   * }
   * ```
   */
  public cleanup(): void {

    let successCount = 0;
    let failCount = 0;

    // Iterate over every icon and clean it up
    this.iconMap.forEach((cached: IconRefData, iconId: string) => {
      try {
        // Remove the icon from the native layer
        if (this.nativeMapView) {
          this.nativeMapView.removeAnnotationIcon(iconId);
        }

        // Release icon resources
        if (!cached.icon.isReleased()) {
          cached.icon.release();
        }

        successCount++;
      } catch (error) {
        hilog.error(DOMAIN, 'IconManager', '%{public}s', `[IconManager] Failed to cleanup icon '${iconId}': ${error}`);
        failCount++;
      }
    });

    // Clear all caches
    this.iconMap.clear();
    this.reuseIdentifierMap.clear();

    // Reset size tracking
    this.highestIconWidth = 0;
    this.highestIconHeight = 0;

  }

  /**
   * Get the number of cached icons.
   *
   * @returns Icon count.
   */
  public getIconCount(): number {
    return this.iconMap.size;
  }

  /**
   * Get the reference count for a specific icon.
   *
   * @param icon Wrapped icon object.
   * @returns Reference count; returns 0 when the icon is missing.
   */
  public getRefCount(icon: Icon): number {
    const cached = this.iconMap.get(icon.getId());
    return cached ? cached.refCount : 0;
  }
}

