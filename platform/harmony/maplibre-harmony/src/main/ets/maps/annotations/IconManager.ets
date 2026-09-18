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
}

