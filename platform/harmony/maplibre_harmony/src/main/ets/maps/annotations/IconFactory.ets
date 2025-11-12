import image from '@ohos.multimedia.image';
import resourceManager from '@ohos.resourceManager';
import fs from '@ohos.file.fs';
import maplibre from 'libmaplibre.so';
import { TooManyIconsException } from '../exceptions/TooManyIconsException';
import { Icon } from './Icon';

/**
 * Color information descriptor.
 */
interface ColorInfo {
  red: number;
  green: number;
  blue: number;
  alpha: number;
}

/**
 * IconFactory - singleton factory for map icons.
 *
 * Builds on the NAPI `Icon` class to create and manage icons used by the map.
 *
 * Supported icon sources:
 * - PixelMap objects: create directly from in-memory bitmaps.
 * - Resource IDs: create from application resources (via `$r`).
 * - File paths: load images from the filesystem.
 * - Rawfile resources: load images from the `rawfile` directory.
 *
 * **Key optimizations**:
 * - Icon image data lives in the C++ layer, avoiding repeated PixelMap-to-bytes conversions.
 * - Singleton pattern guarantees a single factory instance.
 * - Automatically manages icon ID generation to prevent collisions.
 * - Caches the default icon to improve performance.
 *
 * **Lifecycle management**:
 * - Icons are reference-counted by `IconManager`.
 * - Once an icon is released (`isReleased() === true`), it cannot be reused.
 * - To reuse the same visual asset, create a new icon instance.
 *
 * References:
 * - Android: `org.maplibre.android.annotations.IconFactory`
 * - NAPI: `IconNAPI` C++ implementation
 *
 * @example
* ```typescript
 * const factory = IconFactory.getInstance();
 *
 * // Create from a resource
 * const icon1 = await factory.fromResource($r('app.media.marker'));
 * marker.setIcon(icon1);
 *
 * // Create from a file path
 * const icon2 = await factory.fromPath('/data/storage/el2/base/haps/entry/files/marker.png');
 *
 * // Create from an existing PixelMap
 * const icon3 = factory.fromPixelMap(pixelMap);
 *
 * // Obtain the default marker icon
 * const defaultIcon = await factory.defaultMarker();
 *
 * // Reminder: recreate icons after cleanup
 * markerManager.clear(); // Icons are released
 * const icon4 = await factory.fromResource($r('app.media.marker')); // Recreate
 * ```
 */
export class IconFactory {
  private static readonly ICON_ID_PREFIX = 'com.maplibre.icons.icon_';
  private static readonly MAX_ICONS = 1000000; // Prevent ID overflow

  // Default icon name used by SymbolLayer references
  public static readonly DEFAULT_MARKER_ICON_ID = 'com.maplibre.marker.default';
  private static instance: IconFactory | null = null;
  private nextId: number = 0;
  private defaultMarkerIcon: Icon | null = null;
  private resourceMgr: resourceManager.ResourceManager | null = null;
  private pixelRatio: number = 1.0;

  /**
   * Private constructor (singleton).
   *
   * @param resourceMgr Optional resource manager for loading app assets.
   */
  private constructor(resourceMgr?: resourceManager.ResourceManager) {
    this.resourceMgr = resourceMgr || null;
    this.pixelRatio = 1.0; // Default pixel density, configurable via setPixelRatio()
  }

  /**
   * Retrieve the IconFactory singleton.
   *
   * @param resourceMgr Optional resource manager for asset loading.
   * @returns IconFactory instance.
   */
  public static getInstance(resourceMgr?: resourceManager.ResourceManager): IconFactory {
    if (!IconFactory.instance) {
      IconFactory.instance = new IconFactory(resourceMgr);
    } else if (resourceMgr && !IconFactory.instance.resourceMgr) {
      // Assign the resource manager if it was previously unset
      IconFactory.instance.resourceMgr = resourceMgr;
    }
    return IconFactory.instance;
  }

  /**
   * Set the resource manager.
   *
   * @param resourceMgr ResourceManager instance.
   */
  public setResourceManager(resourceMgr: resourceManager.ResourceManager): void {
    this.resourceMgr = resourceMgr;
  }

  /**
   * Set the pixel density ratio.
   *
   * @param pixelRatio Pixel density value.
   */
  public setPixelRatio(pixelRatio: number): void {
    this.pixelRatio = pixelRatio;
  }

  /**
   * Create an icon from a PixelMap.
   *
   * Builds a map icon from a HarmonyOS `PixelMap`.
   *
   * **Performance note**: this path transfers PixelMap data into C++; when dealing with static assets,
   * prefer `fromResource()` or `fromPath()` so decoding happens natively for better performance.
   *
   * @param pixelMap HarmonyOS `PixelMap` instance.
   * @param iconId Optional icon ID; when omitted a unique ID is generated.
   * @returns Wrapped `Icon` instance.
   * @throws TooManyIconsException When the ID counter overflows.
   * @throws Error If the PixelMap is invalid or creation fails.
   */
  public fromPixelMap(pixelMap: image.PixelMap, iconId?: string): Icon {
    const id = iconId || this.generateUniqueIconId();
    return Icon.createInternal(id, pixelMap, this.pixelRatio);
  }

  /**
   * Create an icon from an application resource.
   *
   * Loads an image from `resources/media` and creates an `Icon`.
   *
   * **Performance note**: currently the ETS layer creates a PixelMap and hands it to C++.
   * Future optimizations will decode image data directly in C++ to avoid PixelMap overhead.
   *
   * @param resource Resource object (use `$r`, for example `$r('app.media.marker')`).
   * @param reuseIdentifier Optional reuse identifier (deprecated, ignored).
   * @returns Promise resolving to the wrapped `Icon`.
   * @throws Error If the resource manager is not set, the resource is missing, or loading fails.
   *
   * @example
  * ```typescript
   * const icon = await iconFactory.fromResource($r('app.media.marker_icon'));
   * ```
   */
  public async fromResource(resource: Resource, reuseIdentifier?: string): Promise<Icon> {
    if (!this.resourceMgr) {
      throw new Error(
        '[IconFactory] ResourceManager not set. ' +
          'Call setResourceManager() first or pass it to getInstance()'
      );
    }

    try {
      // 1. Fetch the resource content (returns Uint8Array)
      const uint8Array = await this.resourceMgr.getMediaByName(resource.id.toString());

      // 2. Create an ImageSource
      const imageSource = image.createImageSource(uint8Array.buffer);
      if (!imageSource) {
        throw new Error('Failed to create ImageSource from resource buffer');
      }

      // 3. Decode to a PixelMap (RGBA_8888 format expected by the NAPI icon)
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });

      // 4. Release the ImageSource (PixelMap already created)
      imageSource.release();

      // 5. Create the icon (reuseIdentifier ignored)
      return this.fromPixelMap(pixelMap);
    } catch (error) {
      throw new Error(`[IconFactory] Failed to load icon from resource: ${error}`);
    }
  }

  /**
   * Create an icon from a file path.
   *
   * Loads an image file from the filesystem and produces an `Icon`.
   *
   * **Performance note**: the current implementation reads the file in ETS and creates a PixelMap.
   * Future optimization will decode images directly in C++.
   *
   * @param absolutePath Absolute path to the image file.
   * @param reuseIdentifier Optional reuse identifier (deprecated, ignored).
   * @returns Promise resolving to the wrapped `Icon`.
   * @throws Error If the file is missing, not a regular file, or loading fails.
   *
   * @example
  * ```typescript
   * const icon = await iconFactory.fromPath('/data/storage/el2/base/haps/entry/files/marker.png');
   * ```
   */
  public async fromPath(absolutePath: string, reuseIdentifier?: string): Promise<Icon> {
    try {
      // 1. Ensure the file exists and is a regular file
      const stat = fs.statSync(absolutePath);
      if (!stat.isFile()) {
        throw new Error(`Path is not a file: ${absolutePath}`);
      }

      // 2. Read the file contents
      const file = fs.openSync(absolutePath, fs.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      // 3. Create an ImageSource
      const imageSource = image.createImageSource(buffer);
      if (!imageSource) {
        throw new Error('Failed to create ImageSource from file buffer');
      }

      // 4. Decode to a PixelMap
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });

      // 5. Release the ImageSource
      imageSource.release();

      // 6. Create the icon
      return this.fromPixelMap(pixelMap);
    } catch (error) {
      throw new Error(`[IconFactory] Failed to load icon from path '${absolutePath}': ${error}`);
    }
  }

  /**
   * Create an icon from a rawfile.
   *
   * Loads an image from the application's `resources/rawfile` directory and produces an `Icon`.
   *
   * @param fileName Rawfile name (for example `marker.png`, path prefix not required).
   * @param iconId Optional icon ID; generated automatically when omitted.
   * @returns Promise resolving to the wrapped `Icon`.
   * @throws Error If the resource manager is unset or the rawfile cannot be loaded.
   *
   * @example
  * ```typescript
   * // Load resources/rawfile/marker.png
   * const icon = await iconFactory.fromRawfile('marker.png');
   *
   * // Use a custom ID
   * const icon2 = await iconFactory.fromRawfile('marker.png', 'my-custom-marker');
   * ```
   */
  public async fromRawfile(fileName: string, iconId?: string): Promise<Icon> {

    if (!this.resourceMgr) {
      const error = '[IconFactory] ResourceManager not set. ' +
        'Call setResourceManager() first or pass it to getInstance()';
      console.error(error);
      throw new Error(error);
    }

    try {
      // 1. Read the rawfile contents
      const uint8Array = await this.resourceMgr.getRawFileContent(fileName);

      // 2. Create an ImageSource
      const imageSource = image.createImageSource(uint8Array.buffer);
      if (!imageSource) {
        throw new Error('Failed to create ImageSource from rawfile buffer');
      }

      // 3. Decode to a PixelMap
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });

      // 4. Release the ImageSource
      imageSource.release();

      // 5. Create the icon (optionally specifying a custom ID)
      const icon = await this.fromPixelMap(pixelMap, iconId);
      return icon;
    } catch (error) {
      const errorMsg = `[IconFactory] Failed to load icon from rawfile '${fileName}': ${error}`;
      console.error(errorMsg);
      console.error('[IconFactory] Error stack:', error?.stack);
      throw new Error(errorMsg);
    }
  }

  /**
   * Get the default marker icon.
   *
   * The default icon is cached; repeated calls return the same instance.
   *
   * **Performance optimization**: prefer the C++-generated red circular icon (zero I/O). If that fails,
   * fall back to the ETS implementation.
   *
   * **Lifecycle notes**:
   * - If the cached icon has been released (for example after calling `markerManager.clear()`),
   *   it is recreated automatically.
   * - The default icon always uses {@link DEFAULT_MARKER_ICON_ID}.
   *
   * @returns Promise resolving to the wrapped default icon.
   *
   * @example
  * ```typescript
   * const defaultIcon = await iconFactory.defaultMarker();
   * marker.setIcon(defaultIcon.getId());
   * ```
   */
  public async defaultMarker(): Promise<Icon> {

    // Return the cached icon if it is still valid
    if (this.defaultMarkerIcon && !this.defaultMarkerIcon.isReleased()) {
      return this.defaultMarkerIcon;
    }

    // Clear the cache when the existing icon has been released
    if (this.defaultMarkerIcon?.isReleased()) {
      this.defaultMarkerIcon = null;
    }

    try {
      // Strategy 1: load the Android-style default icon from a rawfile (preferred for visuals)
      if (this.resourceMgr) {
        try {
          this.defaultMarkerIcon = await this.fromRawfile(
            'maplibre_marker_icon_default.png',
            IconFactory.DEFAULT_MARKER_ICON_ID
          );
          return this.defaultMarkerIcon;
        } catch (rawfileError) {
          console.error('[IconFactory] Failed to load default icon from rawfile:', rawfileError);
          console.error('[IconFactory] Error details:', JSON.stringify(rawfileError));
        }
      } else {
        console.warn('[IconFactory] ResourceManager is null, skipping rawfile loading');
      }

      // Strategy 2: generate a procedural red pin icon via the C++ layer
      try {
        const nativeIcon: maplibre.Icon = maplibre.IconFactory.createDefaultMarker(
          IconFactory.DEFAULT_MARKER_ICON_ID,
          48  // 48x48 pixels
        );
        this.defaultMarkerIcon = Icon.fromNative(nativeIcon);
        return this.defaultMarkerIcon;
      } catch (cppError) {
        console.error('[IconFactory] C++ createDefaultMarker failed:', cppError);
      }

      // Strategy 3: procedural ETS fallback (last resort)
      this.defaultMarkerIcon = await this.createFallbackMarkerIcon();
      return this.defaultMarkerIcon;
    } catch (error) {
      throw new Error(`[IconFactory] Failed to create default marker icon: ${error}`);
    }
  }

  /**
   * Recreate an icon using a specific ID.
   *
   * Useful in restoration scenarios where an icon ID is already known. The provided ID is used as-is.
   *
   * @param iconId Icon identifier (required).
   * @param pixelMap PixelMap instance.
   * @param reuseIdentifier Optional reuse identifier (deprecated, ignored).
   * @returns Wrapped `Icon` instance.
   *
   * @example
  * ```typescript
   * // Recreate a previously used icon
   * const icon = iconFactory.recreate('my-saved-icon-id', pixelMap);
   * ```
   */
  public recreate(iconId: string, pixelMap: image.PixelMap, reuseIdentifier?: string): Icon {
    return Icon.createInternal(iconId, pixelMap, this.pixelRatio);
  }

  /**
   * Generate a unique icon ID with overflow protection.
   *
   * Produces IDs in the form `com.maplibre.icons.icon_{number}`.
   *
   * @returns Unique icon ID.
   * @throws TooManyIconsException When the counter exceeds its maximum.
   */
  private generateUniqueIconId(): string {
    if (this.nextId >= IconFactory.MAX_ICONS) {
      throw new TooManyIconsException(
        `[IconFactory] Icon count limit reached: ${IconFactory.MAX_ICONS}. ` +
          'Consider calling reset() or creating a new IconFactory instance.'
      );
    }
    return IconFactory.ICON_ID_PREFIX + (++this.nextId);
  }

  /**
   * Create a procedurally generated fallback marker icon.
   *
   * Invoked when the default icon cannot be loaded from rawfile; produces a pin-shaped icon so the
   * app continues to function without external assets.
   *
   * Icon specification:
   * - Size: 48x48 pixels
   * - Shape: Pin (circular head + triangular tip, similar to Google Maps)
   * - Color: Material Blue (#2196F3) with transparent background
   * - Format: RGBA_8888
   * - ID: {@link DEFAULT_MARKER_ICON_ID}
   *
   * @returns Promise resolving to the procedural fallback icon.
   * @throws Error If creation fails.
   */
  private async createFallbackMarkerIcon(): Promise<Icon> {
    try {
      // Icon specification
      const width = 48;
      const height = 48;
      const color: ColorInfo = {
        red: 255,
        green: 0,
        blue: 0,
        alpha: 255
      }; // Red (#FF0000 - standard map marker color)

      // 1. Create a blank PixelMap
      const pixelMap = await image.createPixelMap(
        new ArrayBuffer(width * height * 4),
        {
          size: { width, height },
          pixelFormat: image.PixelMapFormat.RGBA_8888
        }
      );

      // 2. Generate pin-shaped pixel data (circular head + triangular tip)
      const buffer = new ArrayBuffer(width * height * 4);
      const pixels = new Uint8Array(buffer);
      const centerX = width / 2;
      const headCenterY = height * 0.35; // Head center Y position (upper portion)
      const headRadius = width * 0.25; // Head radius
      const tipY = height * 0.9; // Tip Y coordinate (lower portion)

      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const dx = x - centerX;
          const dy = y - headCenterY;
          const distance = Math.sqrt(dx * dx + dy * dy);

          const offset = (y * width + x) * 4;
          let isInside = false;

          // 1. Circular head
          if (distance <= headRadius) {
            isInside = true;
          }
          // 2. Triangular tip (from the circle downward to the tip)
          else if (y > headCenterY) {
            // Compute triangle bounds (isosceles triangle from circle base to tip)
            const triangleY = y - headCenterY;
            const maxWidth = headRadius * (1.0 - (triangleY / (tipY - headCenterY)));
            if (Math.abs(dx) <= maxWidth) {
              isInside = true;
            }
          }

          if (isInside) {
            // Inside the pin → red
            pixels[offset] = color.red;
            pixels[offset + 1] = color.green;
            pixels[offset + 2] = color.blue;
            pixels[offset + 3] = color.alpha;
          } else {
            // Outside the pin → fully transparent
            pixels[offset] = 0;
            pixels[offset + 1] = 0;
            pixels[offset + 2] = 0;
            pixels[offset + 3] = 0;
          }
        }
      }

      // 3. Write pixel data
      await pixelMap.writeBufferToPixels(buffer);

      // 4. Create the icon (using the fixed default icon ID)
      return this.fromPixelMap(pixelMap, IconFactory.DEFAULT_MARKER_ICON_ID);
    } catch (error) {
      throw new Error(`[IconFactory] Failed to create fallback marker icon: ${error}`);
    }
  }

  /**
   * Reset the factory state.
   *
   * Clears all caches and resets the ID counter; useful for tests or full reinitialization.
   *
   * **Actions**:
   * - Release and clear the cached default icon.
   * - Reset the icon ID counter to 0.
   *
   * **Notes**:
   * - Calling this method releases the default icon, invalidating existing references.
   * - Icons already handed to markers remain managed by `IconManager`.
   *
   * @example
  * ```typescript
   * // Reset state in a test scenario
   * iconFactory.reset();
   * ```
   */
  public reset(): void {
    // Release the cached default icon
    if (this.defaultMarkerIcon && !this.defaultMarkerIcon.isReleased()) {
      this.defaultMarkerIcon.release();
    }
    this.defaultMarkerIcon = null;

    // Reset ID counter
    this.nextId = 0;

  }
}

