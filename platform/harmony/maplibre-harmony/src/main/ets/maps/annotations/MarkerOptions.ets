import { InfoWindowStyle } from './InfoWindow';
import { Icon } from './Icon';
import { LatLng } from '../geometry/LatLng';
import { Marker, NativeMarkerOptions } from './Marker';

/**
 * MarkerOptions - builder for configuring markers.
 *
 * Provides a fluent API for constructing markers; call `getMarker()` to produce the native marker.
 *
 * References:
 * - Android: org.maplibre.android.annotations.MarkerOptions
 *
 * @example
 * ```typescript
 * const iconFactory = IconFactory.getInstance();
 * const customIcon = await iconFactory.fromResource($r('app.media.marker'));
 *
 * // Use `new maplibre.LatLng()` when setting the position
 * const marker = new MarkerOptions()
 *   .position(new maplibre.LatLng(39.9042, 116.4074))
 *   .title('Beijing')
 *   .snippet('Capital of China')
 *   .draggable(true)
 *   .icon(customIcon)
 *   .rotation(45)
 *   .alpha(0.8)
 *   .zIndex(100)
 *   .getMarker();
 * ```
 */
export class MarkerOptions {
  private _position: LatLng | null = null;
  private _title?: string;
  private _snippet?: string;
  private _icon?: Icon;
  private _reuseIdentifier?: string;
  private _draggable: boolean = false;
  private _visible: boolean = true;
  private _alpha: number = 1.0;
  private _rotation: number = 0;
  private _zIndex: number = 0;
  // InfoWindow configuration
  private _infoWindowStyle?: InfoWindowStyle;
  private _infoWindowOffsetX: number = 0;
  private _infoWindowOffsetY: number = 0;

  /**
   * Set the marker position.
   *
   * @param position Geographic location of the marker.
   * @returns `this` for chaining.
   */
  public position(position: LatLng): MarkerOptions {
    this._position = position;
    return this;
  }

  /**
   * Set the marker title.
   *
   * @param title Title text.
   * @returns `this` for chaining.
   */
  public title(title: string): MarkerOptions {
    this._title = title;
    return this;
  }

  /**
   * Set the marker snippet.
   *
   * @param snippet Description text.
   * @returns `this` for chaining.
   */
  public snippet(snippet: string): MarkerOptions {
    this._snippet = snippet;
    return this;
  }

  /**
   * Set a custom icon.
   *
   * @param icon Icon instance.
   * @returns `this` for chaining.
   */
  public icon(icon: Icon): MarkerOptions {
    this._icon = icon;
    return this;
  }

  /**
   * Set the icon along with a reuse identifier.
   *
   * @param icon Icon instance.
   * @param reuseIdentifier Reuse identifier.
   * @returns `this` for chaining.
   */
  public iconWithIdentifier(icon: Icon, reuseIdentifier: string): MarkerOptions {
    this._icon = icon;
    this._reuseIdentifier = reuseIdentifier;
    return this;
  }

  /**
   * Select an icon by reuse identifier.
   *
   * Note: ensure the icon is already registered with `IconManager`.
   *
   * @param reuseIdentifier Reuse identifier.
   * @returns `this` for chaining.
   */
  public iconFromReusableIdentifier(reuseIdentifier: string): MarkerOptions {
    this._reuseIdentifier = reuseIdentifier;
    return this;
  }

  /**
   * Set whether the marker is draggable.
   *
   * @param draggable `true` to allow dragging.
   * @returns `this` for chaining.
   */
  public draggable(draggable: boolean): MarkerOptions {
    this._draggable = draggable;
    return this;
  }

  /**
   * Set marker visibility.
   *
   * @param visible `true` when visible.
   * @returns `this` for chaining.
   */
  public visible(visible: boolean): MarkerOptions {
    this._visible = visible;
    return this;
  }

  /**
   * Set marker opacity.
   *
   * @param alpha Opacity range 0.0-1.0.
   * @returns `this` for chaining.
   */
  public alpha(alpha: number): MarkerOptions {
    this._alpha = Math.max(0, Math.min(1, alpha));
    return this;
  }

  /**
   * Set marker rotation.
   *
   * @param rotation Rotation in degrees.
   * @returns `this` for chaining.
   */
  public rotation(rotation: number): MarkerOptions {
    this._rotation = rotation;
    return this;
  }

  /**
   * Set the marker z-index.
   *
   * Higher values render above lower values.
   *
   * @param zIndex Z-order value.
   * @returns `this` for chaining.
   */
  public zIndex(zIndex: number): MarkerOptions {
    this._zIndex = zIndex;
    return this;
  }

  /**
   * Configure the InfoWindow style.
   *
   * @param style InfoWindow style definition.
   * @returns `this` for chaining.
   *
   * @example
   * ```typescript
   * new MarkerOptions()
   *   .position(latLng)
   *   .title('Location')
   *   .infoWindowStyle({
   *     backgroundColor: '#2196F3',
   *     titleFontColor: Color.White,
   *     showCloseButton: true
   *   })
   * ```
   */
  public infoWindowStyle(style: InfoWindowStyle): MarkerOptions {
    this._infoWindowStyle = style;
    // Copy offsets from style when provided
    if (style.offsetX !== undefined) {
      this._infoWindowOffsetX = style.offsetX;
    }
    if (style.offsetY !== undefined) {
      this._infoWindowOffsetY = style.offsetY;
    }
    return this;
  }

  /**
   * Set the InfoWindow X-axis offset.
   *
   * @param offsetX Offset in pixels.
   * @returns `this` for chaining.
   */
  public infoWindowOffsetX(offsetX: number): MarkerOptions {
    this._infoWindowOffsetX = offsetX;
    return this;
  }

  /**
   * Set the InfoWindow Y-axis offset.
   *
   * @param offsetY Offset in pixels.
   * @returns `this` for chaining.
   */
  public infoWindowOffsetY(offsetY: number): MarkerOptions {
    this._infoWindowOffsetY = offsetY;
    return this;
  }

  // ========== Getters ==========

  /**
   * Get the configured position.
   */
  public getPosition(): LatLng | null {
    return this._position;
  }

  /**
   * Get the configured title.
   */
  public getTitle(): string | undefined {
    return this._title;
  }

  /**
   * Get the configured snippet.
   */
  public getSnippet(): string | undefined {
    return this._snippet;
  }

  /**
   * Get the configured icon.
   */
  public getIcon(): Icon | undefined {
    return this._icon;
  }

  /**
   * Get the configured reuse identifier.
   */
  public getReuseIdentifier(): string | undefined {
    return this._reuseIdentifier;
  }

  /**
   * Determine whether the marker is draggable.
   */
  public isDraggable(): boolean {
    return this._draggable;
  }

  /**
   * Determine whether the marker is visible.
   */
  public isVisible(): boolean {
    return this._visible;
  }

  /**
   * Get the configured opacity.
   */
  public getAlpha(): number {
    return this._alpha;
  }

  /**
   * Get the configured rotation.
   */
  public getRotation(): number {
    return this._rotation;
  }

  /**
   * Get the configured z-index.
   */
  public getZIndex(): number {
    return this._zIndex;
  }

  /**
   * Get the InfoWindow style.
   */
  public getInfoWindowStyle(): InfoWindowStyle | undefined {
    return this._infoWindowStyle;
  }

  /**
   * Get the InfoWindow X offset.
   */
  public getInfoWindowOffsetX(): number {
    return this._infoWindowOffsetX;
  }

  /**
   * Get the InfoWindow Y offset.
   */
  public getInfoWindowOffsetY(): number {
    return this._infoWindowOffsetY;
  }

  /**
   * Create the marker instance.
   *
   * @returns Wrapped marker.
   * @throws Error When position is not set.
   */
  public getMarker(): Marker {
    if (this._position === null) {
      throw new Error('Marker position must be set');
    }

    // Build the native options object
    const options: NativeMarkerOptions = {
      position: this._position.toObject()  // Pass a literal object
    };

    // Apply optional properties
    if (this._icon !== undefined) {
      // Pass the icon ID string (NAPI expects a string, not the wrapper object)
      options.icon = this._icon.getId();
    }
    if (this._title !== undefined) {
      options.title = this._title;
    }
    if (this._snippet !== undefined) {
      options.snippet = this._snippet;
    }
    if (this._visible !== true) {
      options.visible = this._visible;
    }
    if (this._alpha !== 1.0) {
      options.alpha = this._alpha;
    }
    if (this._rotation !== 0) {
      options.rotation = this._rotation;
    }
    if (this._draggable !== false) {
      options.draggable = this._draggable;
    }
    if (this._zIndex !== 0) {
      options.zIndex = this._zIndex;
    }

    // [MarkerDebug] Log marker creation info
    const iconStatus = this._icon ? `"${this._icon.getId()}"` : 'null (warning: marker may be invisible)';

    // Create the Marker wrapper instance
    return Marker.createFromOptions(options);
  }
}

