import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
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
 * - Encoded image bytes (PNG/JPEG/WEBP) are decoded in the C++ layer via the
 *   Image Kit native APIs (no intermediate ArkTS PixelMap). Each source method
   * falls back to ArkTS decoding if native decoding fails.
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
 * - NAPI: `IconNAPI` / `IconFactoryNAPI` C++ implementations
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
   * **Performance note**: the encoded media bytes are decoded in the C++ layer
   * when possible (single allocation, no intermediate ArkTS PixelMap). If native
   * decoding fails, the factory falls back to the ArkTS decode path.
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
      // 1. Fetch the encoded media content (returns Uint8Array)
      const uint8Array = await this.resourceMgr.getMediaContent(resource);

      // 2. Preferred path: decode in C++ (no intermediate PixelMap)
      const nativeIcon = this.tryCreateNativeIconFromData(uint8Array);
      if (nativeIcon !== null) {
        return nativeIcon;
      }

      // 3. Fallback: decode in ArkTS
      return await this.createIconFromDataInArkTS(uint8Array);
    } catch (error) {
      throw new Error(`[IconFactory] Failed to load icon from resource: ${error}`);
    }
  }

  /**
   * Create an icon from a file path.
   *
   * Loads an image file from the filesystem and produces an `Icon`.
   *
   * **Performance note**: the file is read and decoded in the C++ layer when
   * possible (single allocation, no intermediate ArkTS PixelMap). If native
   * decoding fails, the factory falls back to the ArkTS decode path.
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

      // 2. Preferred path: read + decode in C++ (no intermediate PixelMap)
      const nativeIcon = this.tryCreateNativeIconFromPath(absolutePath);
      if (nativeIcon !== null) {
        return nativeIcon;
      }

      // 3. Fallback: read the file in ArkTS and decode
      const file = fs.openSync(absolutePath, fs.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      return await this.createIconFromDataInArkTS(new Uint8Array(buffer));
    } catch (error) {
      throw new Error(`[IconFactory] Failed to load icon from path '${absolutePath}': ${error}`);
    }
  }

  /**
   * Create an icon from a rawfile.
   *
   * Loads an image from the application's `resources/rawfile` directory and produces an `Icon`.
   *
   * **Performance note**: the rawfile is read and decoded in the C++ layer when
   * possible (single allocation, no intermediate ArkTS PixelMap). If native
   * decoding fails, the factory falls back to the ArkTS decode path.
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
      hilog.error(DOMAIN, 'IconFactory', '%{public}s', error);
      throw new Error(error);
    }

    // Preferred path: read + decode in C++ (no intermediate PixelMap)
    try {
      const nativeIcon = maplibre.IconFactory.fromRawfile(
        this.resourceMgr, fileName, iconId, this.pixelRatio);
      return Icon.fromNative(nativeIcon);
    } catch (nativeError) {
      hilog.error(DOMAIN, 'IconFactory', '%{public}s', `[IconFactory] Native rawfile decoding failed, falling back to ArkTS: ${nativeError}`);
    }

    // Fallback: read + decode in ArkTS
    try {
      // 1. Read the rawfile contents
      const uint8Array = await this.resourceMgr.getRawFileContent(fileName);

      // 2. Create the icon (optionally specifying a custom ID)
      return await this.createIconFromDataInArkTS(uint8Array, iconId);
    } catch (error) {
      const errorMsg = `[IconFactory] Failed to load icon from rawfile '${fileName}': ${error}`;
      hilog.error(DOMAIN, 'IconFactory', '%{public}s', errorMsg);
      hilog.error(DOMAIN, 'IconFactory', '[IconFactory] Error stack: %{public}s', error?.stack);
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
          hilog.error(DOMAIN, 'IconFactory', '[IconFactory] Failed to load default icon from rawfile: %{public}s', rawfileError);
          hilog.error(DOMAIN, 'IconFactory', '[IconFactory] Error details: %{public}s', JSON.stringify(rawfileError));
        }
      } else {
        hilog.warn(DOMAIN, 'IconFactory', '%{public}s', '[IconFactory] ResourceManager is null, skipping rawfile loading');
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
        hilog.error(DOMAIN, 'IconFactory', '[IconFactory] C++ createDefaultMarker failed: %{public}s', cppError);
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
   * Decode encoded image bytes in the C++ layer and wrap the result.
   *
   * @param data Encoded image bytes (PNG/JPEG/WEBP).
   * @param iconId Optional icon ID; generated automatically when omitted.
   * @returns Wrapped `Icon`, or null when native decoding fails
   *          (callers should fall back to the ArkTS decode path).
   */
  private tryCreateNativeIconFromData(data: Uint8Array, iconId?: string): Icon | null {
    try {
      const nativeIcon = maplibre.IconFactory.fromResourceData(data, iconId, this.pixelRatio);
      return Icon.fromNative(nativeIcon);
    } catch (error) {
      hilog.error(DOMAIN, 'IconFactory', '%{public}s', `[IconFactory] Native image decoding failed, falling back to ArkTS: ${error}`);
      return null;
    }
  }

  /**
   * Read and decode an image file in the C++ layer and wrap the result.
   *
   * @param absolutePath Absolute path to the image file.
   * @returns Wrapped `Icon`, or null when native decoding fails
   *          (callers should fall back to the ArkTS decode path).
   */
  private tryCreateNativeIconFromPath(absolutePath: string): Icon | null {
    try {
      const nativeIcon = maplibre.IconFactory.fromFilePath(absolutePath, undefined, this.pixelRatio);
      return Icon.fromNative(nativeIcon);
    } catch (error) {
      hilog.error(DOMAIN, 'IconFactory', '%{public}s', `[IconFactory] Native file decoding failed, falling back to ArkTS: ${error}`);
      return null;
    }
  }

  /**
   * ArkTS decode path: encoded bytes → ImageSource → PixelMap → Icon.
   *
   * Used as fallback when native decoding fails. Decodes to RGBA_8888, the
   * format expected by the NAPI icon implementation.
   *
   * @param data Encoded image bytes (PNG/JPEG/WEBP).
   * @param iconId Optional icon ID; generated automatically when omitted.
   * @returns Promise resolving to the wrapped `Icon`.
   * @throws Error If decoding fails.
   */
  private async createIconFromDataInArkTS(data: Uint8Array, iconId?: string): Promise<Icon> {
    // 1. Create an ImageSource (slice to the view range; the backing buffer may
    //    be larger than the view or start at a non-zero offset)
    const exactBuffer = data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
    const imageSource = image.createImageSource(exactBuffer);
    if (!imageSource) {
      throw new Error('Failed to create ImageSource from image data');
    }

    // 2. Decode to a PixelMap (RGBA_8888 format expected by the NAPI icon)
    const pixelMap = await imageSource.createPixelMap({
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888
    });

    // 3. Release the ImageSource (PixelMap already created)
    imageSource.release();

    // 4. Create the icon
    return this.fromPixelMap(pixelMap, iconId);
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

