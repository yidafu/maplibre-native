import { Icon } from './Icon';

/**
 * IconFactory - Static factory for creating icons with optimized performance
 * 
 * This factory creates icons directly in C++ layer, avoiding expensive PixelMap
 * conversions across the NAPI boundary.
 * 
 * **Performance Benefits:**
 * - Zero-copy image creation (no PixelMap-to-bytes conversion)
 * - Single memory allocation in C++ layer
 * - Direct image decoding using HarmonyOS native APIs
 * 
 * **Supported Image Formats:**
 * - PNG
 * - JPEG
 * - WEBP
 * 
 * @example
 * ```typescript
 * // From resource data (recommended)
 * const uint8Array = await resourceMgr.getMediaContent($r('app.media.marker'));
 * const icon = maplibre.IconFactory.fromResourceData(uint8Array);
 * 
 * // From file path
 * const icon = maplibre.IconFactory.fromFilePath('/data/storage/marker.png');
 * 
 * // Create default marker
 * const defaultIcon = maplibre.IconFactory.createDefaultMarker();
 * ```
 */
export class IconFactory {
  /**
   * Private constructor - use static factory methods
   */
  private constructor();
  
  /**
   * Create icon from ArrayBuffer containing raw image data
   * 
   * Decodes the image directly in C++ layer using HarmonyOS ImageSource API.
   * 
   * @param data Raw image file data (PNG/JPEG/WEBP)
   * @param iconId Optional icon identifier (auto-generated if not provided)
   * @param scale Optional pixel scale ratio (default: 1.0)
   * @returns Icon instance
   * @throws Error if image decoding fails
   * 
   * @example
   * ```typescript
   * const buffer = await fileToArrayBuffer('/path/to/image.png');
   * const icon = maplibre.IconFactory.fromArrayBuffer(buffer, 'my-icon', 1.0);
   * ```
   */
  static fromArrayBuffer(data: ArrayBuffer, iconId?: string, scale?: number): Icon;
  
  /**
   * Create icon from Uint8Array containing raw image data
   * 
   * This is the recommended method when loading from resources, as it avoids
   * PixelMap creation overhead.
   * 
   * @param data Raw image file data (PNG/JPEG/WEBP)
   * @param iconId Optional icon identifier (auto-generated if not provided)
   * @param scale Optional pixel scale ratio (default: 1.0)
   * @returns Icon instance
   * @throws Error if image decoding fails
   * 
   * @example
   * ```typescript
   * // Load from resource
   * const uint8Array = await resourceMgr.getMediaContent($r('app.media.marker'));
   * const icon = maplibre.IconFactory.fromResourceData(uint8Array);
   * 
   * // Use with marker
   * marker.setIcon(icon.getId());
   * ```
   */
  static fromResourceData(data: Uint8Array, iconId?: string, scale?: number): Icon;
  
  /**
   * Create icon from rawfile resource (NOT YET IMPLEMENTED)
   * 
   * @param fileName Rawfile name (e.g., 'marker.png')
   * @param iconId Optional icon identifier (auto-generated if not provided)
   * @param scale Optional pixel scale ratio (default: 1.0)
   * @returns Icon instance
   * @throws Error - Currently not implemented, use fromResourceData() instead
   * 
   * @deprecated Use fromResourceData() with ETS layer reading the rawfile
   */
  static fromRawfile(fileName: string, iconId?: string, scale?: number): Icon;
  
  /**
   * Create icon from file path
   * 
   * Loads and decodes image from file system directly in C++ layer.
   * 
   * @param path Absolute file path
   * @param iconId Optional icon identifier (auto-generated if not provided)
   * @param scale Optional pixel scale ratio (default: 1.0)
   * @returns Icon instance
   * @throws Error if file not found or image decoding fails
   * 
   * @example
   * ```typescript
   * const icon = maplibre.IconFactory.fromFilePath(
   *   '/data/storage/el2/base/haps/entry/files/marker.png',
   *   'custom-marker',
   *   2.0
   * );
   * ```
   */
  static fromFilePath(path: string, iconId?: string, scale?: number): Icon;
  
  /**
   * Create default marker icon (programmatically generated)
   * 
   * Generates a simple red circle marker without requiring image files.
   * This is useful as a fallback when custom icons are not available.
   * 
   * @param iconId Optional icon identifier (default: 'com.maplibre.marker.default')
   * @param size Optional icon size in pixels (default: 48)
   * @returns Icon instance
   * 
   * @example
   * ```typescript
   * // Create default marker
   * const defaultIcon = maplibre.IconFactory.createDefaultMarker();
   * 
   * // Create custom-sized default marker
   * const largeIcon = maplibre.IconFactory.createDefaultMarker('large-marker', 64);
   * ```
   */
  static createDefaultMarker(iconId?: string, size?: number): Icon;
}

