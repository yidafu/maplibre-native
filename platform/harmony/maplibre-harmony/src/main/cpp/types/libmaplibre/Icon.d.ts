import image from '@ohos.multimedia.image';

/**
 * Icon class (NAPI implementation).
 *
 * Represents a map annotation icon, including bitmap data and metadata.
 * Icon instances hold image data in C++ to avoid redundant conversions.
 *
 * **Important: Icon lifecycle management**
 * - Managed by IconManager, which tracks references via ref-counting.
 * - Calling markerManager.clear() or marker.remove() decreases the reference count.
 * - When the count reaches 0, the icon is automatically released (release() is invoked).
 * - **Released icons cannot be reused**; create a new Icon instance instead.
 * - To re-add the same artwork after clearing, create a fresh Icon object.
 *
 * Implemented by the C++ NAPI layer and consumed directly from ETS.
 *
 * References:
 * - Android: org.maplibre.android.annotations.Icon
 * - iOS: MLNAnnotationImage
 *
 * @example
* ```typescript
 * import maplibre from 'libmaplibre.so';
 * import image from '@ohos.multimedia.image';
 *
* // Preferred: create icons via IconFactory.
 * const factory = IconFactory.getInstance();
 * const icon = await factory.fromResource($r('app.media.marker'));
 * marker.setIcon(icon);
 *
* // Alternative (not recommended — mostly used internally by IconFactory).
* const pixelMap = ...; // obtain a PixelMap
 * const icon = new maplibre.Icon('my-icon-id', pixelMap, 2.0);
 *
* // Wrong: reuse after clearing.
* markerManager.clear(); // icon gets released
* marker2.setIcon(icon); // ❌ Error! Icon already released.
 *
* // Correct: create a new Icon.
 * const icon2 = await factory.fromResource($r('app.media.marker'));
* marker2.setIcon(icon2); // ✓ Works.
 * ```
 */
export class Icon {
  /**
   * Constructor.
   *
   * Creates a new Icon instance. The PixelMap is immediately converted to C++ image data.
   *
   * **Note**: Prefer creating icons via IconFactory rather than calling the constructor directly.
   *
   * @param id Unique icon identifier.
   * @param pixelMap HarmonyOS PixelMap instance (converted to C++ image data).
   * @param scale Pixel density scale factor (optional, defaults to 1.0).
   */
  constructor(id: string, pixelMap: image.PixelMap, scale?: number);

  /**
   * Get the icon identifier.
   *
   * @returns Icon ID.
   */
  getId(): string;

  /**
   * Get the icon width in pixels.
   *
   * @returns Width.
   */
  getWidth(): number;

  /**
   * Get the icon height in pixels.
   *
   * @returns Height.
   */
  getHeight(): number;

  /**
   * Get the pixel density scale factor.
   *
   * Used to adapt to devices with different screen densities.
   *
   * @returns Scale factor.
   */
  getScale(): number;

  /**
   * Check whether the icon has been released.
   *
   * After release() (or reference count reaching zero) the image data is freed.
   * A released icon cannot be used; attempting to do so throws an error.
   *
   * @returns True when released, false when still valid.
   */
  isReleased(): boolean;

  /**
   * Release resources.
   *
   * Frees the C++ image data held by the icon. Typically invoked automatically by IconManager
   * when the reference count reaches zero (for example when all markers using the icon are removed).
   *
   * **Warning**: Released icons cannot be reused—trying to use them throws an error.
   * Create a new Icon instance if you need the same artwork again.
   */
  release(): void;
}

