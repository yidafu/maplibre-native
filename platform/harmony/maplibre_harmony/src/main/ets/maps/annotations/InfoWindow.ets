import { Point } from '../geometry/Point';
// import { ComponentContent } from '@kit.ArkUI';

// Use NAPI Marker type
import { Marker } from './Marker';

/**
 * InfoWindow position payload
 */
export interface InfoWindowPosition {
  x: number; // Screen X coordinate
  y: number; // Screen Y coordinate
  arrowOffsetX: number; // Arrow offset relative to center
}

/**
 * InfoWindow size info
 */
interface InfoWindowSize {
  width: number;
  height: number;
}

/**
 * InfoWindow style configuration
 */
export interface InfoWindowStyle {
  backgroundColor?: string;
  borderRadius?: number;
  shadowRadius?: number;
  shadowColor?: string;
  titleFontSize?: number;
  titleFontColor?: string;
  snippetFontSize?: number;
  snippetFontColor?: string;
  padding?: number;
  maxWidth?: number;
  animated?: boolean;

  // Accessory view support (mirrors iOS MLNCalloutView)
  leftAccessoryBuilder?: () => void; // @Builder for custom left accessory
  rightAccessoryBuilder?: () => void; // @Builder for custom right accessory

  // Additional features
  showCloseButton?: boolean; // Whether to display close button
  thumbnailImage?: ResourceStr; // Thumbnail displayed left of title

  // InfoWindow offsets
  offsetX?: number; // X-axis offset (pixels)
  offsetY?: number; // Y-axis offset (pixels)
}

const DEFAULT_INFO_WINDOW_STYLE: InfoWindowStyle = {
  showCloseButton: true
};

/**
 * InfoWindow - Information window component
 *
 * Displays marker details using a Popup component.
 *
 * References:
 * - Android: InfoWindow.java
 * - iOS: MLNCalloutView
 */
export class InfoWindow {
  private marker: Marker;
  private customView: object | null = null;
  private _isShown: boolean = false;
  private _width: number = 0;
  private _height: number = 0;
  // Position and offsets
  private offsetX: number = 0;
  private offsetY: number = 0;
  private markerHeightOffset: number = 0;
  private markerWidthOffset: number = 0;
  private viewWidthOffset: number = 0;
  private viewHeightOffset: number = 0;
  private screenPosition: InfoWindowPosition | null = null;
  // Style configuration
  private style: InfoWindowStyle = {
    showCloseButton: DEFAULT_INFO_WINDOW_STYLE.showCloseButton,
  };
  // Callbacks to inform external consumers about visibility changes
  private onShowCallback?: (marker: Marker, position: InfoWindowPosition) => void;
  private onCloseCallback?: (marker: Marker) => void;
  private onUpdateCallback?: (marker: Marker, position: InfoWindowPosition) => void;

  constructor(marker: Marker, style?: InfoWindowStyle) {
    this.marker = marker;
    this.setStyle(style ?? {});
  }

  /**
   * Assign show callback
   */
  public setOnShowCallback(callback: (marker: Marker, position: InfoWindowPosition) => void): void {
    this.onShowCallback = callback;
  }

  /**
   * Assign close callback
   */
  public setOnCloseCallback(callback: (marker: Marker) => void): void {
    this.onCloseCallback = callback;
  }

  /**
   * Assign update callback
   */
  public setOnUpdateCallback(callback: (marker: Marker, position: InfoWindowPosition) => void): void {
    this.onUpdateCallback = callback;
  }

  /**
   * Configure offset
   */
  public setOffset(offsetX: number, offsetY: number): void {
    this.offsetX = offsetX;
    this.offsetY = offsetY;
  }

  /**
   * Set InfoWindow size
   */
  public setSize(width: number, height: number): void {
    this._width = width;
    this._height = height;
  }

  /**
   * Get InfoWindow width
   */
  public getWidth(): number {
    return this._width;
  }

  /**
   * Get InfoWindow height
   */
  public getHeight(): number {
    return this._height;
  }

  /**
   * Apply style
   */
  public setStyle(style: InfoWindowStyle): void {
    const mergedStyle: InfoWindowStyle = {};

    if (style.backgroundColor !== undefined) {
      mergedStyle.backgroundColor = style.backgroundColor;
    }
    if (style.borderRadius !== undefined) {
      mergedStyle.borderRadius = style.borderRadius;
    }
    if (style.shadowRadius !== undefined) {
      mergedStyle.shadowRadius = style.shadowRadius;
    }
    if (style.shadowColor !== undefined) {
      mergedStyle.shadowColor = style.shadowColor;
    }
    if (style.titleFontSize !== undefined) {
      mergedStyle.titleFontSize = style.titleFontSize;
    }
    if (style.titleFontColor !== undefined) {
      mergedStyle.titleFontColor = style.titleFontColor;
    }
    if (style.snippetFontSize !== undefined) {
      mergedStyle.snippetFontSize = style.snippetFontSize;
    }
    if (style.snippetFontColor !== undefined) {
      mergedStyle.snippetFontColor = style.snippetFontColor;
    }
    if (style.padding !== undefined) {
      mergedStyle.padding = style.padding;
    }
    if (style.maxWidth !== undefined) {
      mergedStyle.maxWidth = style.maxWidth;
    }
    if (style.animated !== undefined) {
      mergedStyle.animated = style.animated;
    }
    if (style.leftAccessoryBuilder !== undefined) {
      mergedStyle.leftAccessoryBuilder = style.leftAccessoryBuilder;
    }
    if (style.rightAccessoryBuilder !== undefined) {
      mergedStyle.rightAccessoryBuilder = style.rightAccessoryBuilder;
    }
    if (style.thumbnailImage !== undefined) {
      mergedStyle.thumbnailImage = style.thumbnailImage;
    }
    if (style.offsetX !== undefined) {
      mergedStyle.offsetX = style.offsetX;
    }
    if (style.offsetY !== undefined) {
      mergedStyle.offsetY = style.offsetY;
    }

    if (style.showCloseButton !== undefined) {
      mergedStyle.showCloseButton = style.showCloseButton;
    } else {
      mergedStyle.showCloseButton = DEFAULT_INFO_WINDOW_STYLE.showCloseButton;
    }

    this.style = mergedStyle;

    if (mergedStyle.offsetX !== undefined) {
      this.offsetX = mergedStyle.offsetX;
    }
    if (mergedStyle.offsetY !== undefined) {
      this.offsetY = mergedStyle.offsetY;
    }
  }

  /**
   * Retrieve current style
   */
  public getStyle(): InfoWindowStyle {
    return this.style;
  }

  /**
   * Show the InfoWindow
   * @param screenWidth Screen width (for boundary checks)
   * @param screenHeight Screen height (for boundary checks)
   * @param markerScreenPosition Marker screen position
   */
  public show(screenWidth: number, screenHeight: number, markerScreenPosition: Point): void {
    if (this._isShown) {
      console.info(`[InfoWindow] Already shown, skipping`);
      return;
    }

    console.info(`[InfoWindow] show() called, calculating position...`);

    // Compute position
    const position = this.calculateScreenPosition(
      markerScreenPosition,
      screenWidth,
      screenHeight
    );

    this.screenPosition = position;
    this._isShown = true;
    // Avoid recursive calls: marker state handled in MarkerManager.selectMarker()

    console.info(`[InfoWindow] Position calculated: (${position.x}, ${position.y}), calling onShowCallback...`);

    // Notify UI layer to display
    if (this.onShowCallback) {
      console.info(`[InfoWindow] onShowCallback exists, invoking...`);
      this.onShowCallback(this.marker, position);
      console.info(`[InfoWindow] onShowCallback completed`);
    } else {
      console.warn(`[InfoWindow] onShowCallback is null or undefined!`);
    }
  }

  /**
   * Close InfoWindow
   */
  public close(): void {
    if (!this._isShown) {
      return;
    }

    this._isShown = false;
    // Avoid recursion: marker state maintained by MarkerManager

    // Notify UI layer to hide
    if (this.onCloseCallback) {
      this.onCloseCallback(this.marker);
    }
  }

  /**
   * Update InfoWindow position
   * @param screenWidth Screen width
   * @param screenHeight Screen height
   * @param markerScreenPosition Marker screen position
   */
  public update(screenWidth: number, screenHeight: number, markerScreenPosition: Point): void {
    if (!this._isShown) {
      console.info(`[InfoWindow] update() skipped - InfoWindow not shown`);
      return;
    }

    console.info(`[InfoWindow] update() called - recalculating position with size: ${this._width}x${this._height}`);

    // Recompute position
    const position = this.calculateScreenPosition(
      markerScreenPosition,
      screenWidth,
      screenHeight
    );

    this.screenPosition = position;
    console.info(`[InfoWindow] New position calculated: (${position.x}, ${position.y}), arrowOffsetX: ${position.arrowOffsetX}`);

    // Notify UI layer to refresh
    if (this.onUpdateCallback) {
      console.info(`[InfoWindow] Calling onUpdateCallback to update UI position`);
      this.onUpdateCallback(this.marker, position);
      console.info(`[InfoWindow] onUpdateCallback completed`);
    } else {
      console.warn(`[InfoWindow] onUpdateCallback is null/undefined!`);
    }
  }

  /**
   * Determine whether InfoWindow is visible
   */
  public isShown(): boolean {
    return this._isShown;
  }

  /**
   * Set custom view
   */
  public setCustomView(view: object | null): void {
    this.customView = view;
  }

  /**
   * Get custom view
   */
  public getCustomView(): object | null {
    return this.customView;
  }

  /**
   * Retrieve associated marker
   */
  public getMarker(): Marker {
    return this.marker;
  }

  /**
   * Get InfoWindow title
   */
  public getTitle(): string {
    return this.marker.getTitle();
  }

  /**
   * Get InfoWindow snippet
   */
  public getSnippet(): string {
    return this.marker.getSnippet();
  }

  /**
   * Get current screen position
   */
  public getScreenPosition(): InfoWindowPosition | null {
    return this.screenPosition;
  }

  /**
   * Estimate InfoWindow size
   *
   * Approximate dimensions before actual rendering using content and style.
   *
   * @returns Estimated width/height (physical pixels)
   */
  private estimateSize(): InfoWindowSize {
    const title = this.marker.getTitle() || '';
    const snippet = this.marker.getSnippet() || '';
    
    // Pull configuration from style
    const titleFontSize = this.style.titleFontSize ?? 16;
    const snippetFontSize = this.style.snippetFontSize ?? 14;
    const padding = this.style.padding ?? 12;
    
    // Estimate width based on text length and font size
    // Use 0.7 as average character width factor (mixed languages)
    const titleWidth = title.length * titleFontSize * 0.7;
    const snippetWidth = snippet ? snippet.length * snippetFontSize * 0.6 : 0;
    const maxTextWidth = Math.max(titleWidth, snippetWidth);
    
    // Extra width if thumbnail present
    const thumbnailWidth = this.style.thumbnailImage ? 40 : 0;  // 32px icon + 8px margin
    const showCloseButton = this.style.showCloseButton !== false;
    const closeButtonWidth = showCloseButton ? 36 : 0; // 28 button + 8 margin

    // Estimated width = text width + padding + thumbnail/close button
    const estimatedWidth = Math.max(
      maxTextWidth + padding * 2 + thumbnailWidth + closeButtonWidth,
      80  // Minimum width for visual balance
    );
    
    // Enforce max width
    const maxWidth = this.style.maxWidth ?? 240;
    const width = Math.min(estimatedWidth, maxWidth);
    
    // Estimate height based on content rows
    const titleHeight = title ? titleFontSize + 8 : 0;  // Title line + spacing
    const snippetHeight = snippet ? snippetFontSize + 4 : 0;  // Snippet line + spacing
    const arrowHeight = 10;  // Arrow height
    const closeButtonHeight = showCloseButton ? 32 : 0;
    
    const estimatedHeight = 
      closeButtonHeight +
      titleHeight +
      snippetHeight +
      padding * 2 + 
      arrowHeight;
    
    return {
      width: width,
      height: estimatedHeight
    };
  }

  /**
   * Calculate InfoWindow screen position
   * Mirrors Android InfoWindow.java positioning logic.
   *
   * @param markerScreenPosition Marker screen coordinates
   * @param screenWidth Screen width
   * @param screenHeight Screen height
   * @returns Computed position info
   */
  private calculateScreenPosition(
    markerScreenPosition: Point,
    screenWidth: number,
    screenHeight: number
  ): InfoWindowPosition {
    // Use estimated size if unknown (first render)
    let width = this._width;
    let height = this._height;
    
    if (width === 0 || height === 0) {
      const estimated = this.estimateSize();
      width = estimated.width;
      height = estimated.height;
      console.info(`[InfoWindow] Using estimated size: ${width}x${height}`);
    }
    
    // Default position: centered above marker
    let x = markerScreenPosition.x - (width / 2) + this.offsetX;
    let y = markerScreenPosition.y - height + this.offsetY;

    // Store offsets for future updates
    this.markerHeightOffset = this.offsetY;
    this.markerWidthOffset = -this.offsetX;

    // Calculate view offsets
    this.viewWidthOffset = x - markerScreenPosition.x - this.offsetX;
    this.viewHeightOffset = -height + this.offsetY;

    // Arrow centered by default
    let arrowOffsetX = 0;

    // Arrow alignment helper: keep arrow pointing at the marker (or offset anchor)
    const arrowWidth = 20; // Arrow width
    const maxArrowOffset = (width / 2) - (arrowWidth / 2) - 4; // Prevent arrow from leaving bounds
    const infoWindowCenterX = x + (width / 2);
    const markerAnchorX = markerScreenPosition.x;

    arrowOffsetX = markerAnchorX - infoWindowCenterX;

    if (arrowOffsetX > maxArrowOffset) {
      arrowOffsetX = maxArrowOffset;
    } else if (arrowOffsetX < -maxArrowOffset) {
      arrowOffsetX = -maxArrowOffset;
    }

    return {
      x: x,
      y: y,
      arrowOffsetX: arrowOffsetX
    };
  }
}

/**
 * InfoWindowComponent - InfoWindow UI component
 *
 * Renders marker info via Popup with dynamic arrow, custom styling, animations, and accessory views.
 *
 * References:
 * - Android: InfoWindow with custom views
 * - iOS: MLNCalloutView with accessory views
 */
@Component
export struct InfoWindowComponent {
  // Important: do not expose @Prop marker: Marker (NAPI objects do not traverse @Prop)
  // Instead pass marker data fields
  @Prop markerId: number = 0;
  @Prop markerTitle: string = '';
  @Prop markerSnippet: string = '';
  @Prop arrowOffsetX: number = 0; // Arrow offset relative to center
  @Prop customContent: object | null = null;
  @Prop customStyle: InfoWindowStyle | null = null;
  @State windowOpacity: number = 0; // Animation helper (renamed to avoid conflicts)
  @State windowScale: number = 0.8; // Animation helper (renamed to avoid conflicts)
  @BuilderParam leftAccessoryBuilder?: () => void; // Left accessory view
  @BuilderParam rightAccessoryBuilder?: () => void; // Right accessory view
  onWindowClick?: () => void; // Renamed to avoid CustomComponent.onClick conflict
  onLongClick?: () => void;
  onClose?: () => void;
  onSizeChanged?: (width: number, height: number) => void; // Size change callback

  aboutToAppear() {
    console.info(`[InfoWindowComponent] aboutToAppear - marker title: "${this.markerTitle}", snippet: "${this.markerSnippet}"`);
    console.info(`[InfoWindowComponent] arrowOffsetX: ${this.arrowOffsetX}`);
    // Play show animation
    const animated = this.customStyle?.animated !== false;
    if (animated) {
      // animation replaces deprecated animateTo
      this.windowOpacity = 1;
      this.windowScale = 1;
    } else {
      this.windowOpacity = 1;
      this.windowScale = 1;
    }
  }

  build() {
    Column() {
      Column() {
        Row({ space: 8 }) {
          if (this.leftAccessoryBuilder || this.customStyle?.leftAccessoryBuilder) {
            Column() {
              if (this.leftAccessoryBuilder) {
                this.leftAccessoryBuilder()
              }
            }
            .margin({ right: 8 })
          }

          Column() {
            if (this.markerTitle) {
              Row() {
                if (this.customStyle?.thumbnailImage) {
                  Image(this.customStyle.thumbnailImage)
                    .width(32)
                    .height(32)
                    .borderRadius(4)
                    .margin({ right: 8 })
                }

                Text(this.markerTitle)
                  .fontSize(this.customStyle?.titleFontSize ?? 16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.customStyle?.titleFontColor ?? '#333333')
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .constraintSize({ maxWidth: this.customStyle?.maxWidth ?? 250 })
              }
              .alignItems(VerticalAlign.Center)
            }

            if (this.markerSnippet) {
              Text(this.markerSnippet)
                .fontSize(this.customStyle?.snippetFontSize ?? 14)
                .fontColor(this.customStyle?.snippetFontColor ?? '#666666')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 4 })
                .constraintSize({ maxWidth: this.customStyle?.maxWidth ?? 250 })
            }
          }

          if (this.rightAccessoryBuilder || this.customStyle?.rightAccessoryBuilder) {
            Column() {
              if (this.rightAccessoryBuilder) {
                this.rightAccessoryBuilder()
              }
            }
          }

          if (this.customStyle?.showCloseButton !== false) {
            Text('×')
              .fontSize(20)
              .fontColor('#999999')
              .width(28)
              .height(28)
              .textAlign(TextAlign.Center)
              .borderRadius(14)
              .backgroundColor('rgba(0,0,0,0.05)')
              .margin({ left: 8, top: -4 })
              .onClick(() => {
                if (this.onClose) {
                  this.onClose();
                }
              })
          }
        }
        .alignItems(VerticalAlign.Top)
      }
      .padding(this.customStyle?.padding ?? 12)
      .backgroundColor(this.customStyle?.backgroundColor ?? Color.White)
      .borderRadius(this.customStyle?.borderRadius ?? 8)
      .shadow({
        radius: this.customStyle?.shadowRadius ?? 8,
        color: this.customStyle?.shadowColor ?? 'rgba(0, 0, 0, 0.2)',
        offsetX: 0,
        offsetY: 2
      })
      .constraintSize({ maxWidth: this.customStyle?.maxWidth ?? 280 })

      Row() {
        Polygon()
          .points([[0, 0], [10, 10], [20, 0]])
          .fill(this.customStyle?.backgroundColor ?? Color.White)
          .width(20)
          .height(10)
          .translate({ x: this.arrowOffsetX, y: 0 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: -1 })
    }
    .alignItems(HorizontalAlign.Center)
    .opacity(this.windowOpacity)
    .scale({ x: this.windowScale, y: this.windowScale })
    .animation({ duration: 250, curve: Curve.EaseOut })
    .onClick(() => {
      if (this.onWindowClick) {
        this.onWindowClick();
      }
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          if (this.onLongClick) {
            this.onLongClick();
          }
        })
    )
    .onAreaChange((oldValue: Area, newValue: Area) => {
      const width = Number(newValue.width);
      const height = Number(newValue.height);
      if (this.onSizeChanged && width > 0 && height > 0) {
        console.info(`[InfoWindowComponent] Size measured: ${width}x${height}`);
        this.onSizeChanged(width, height);
      }
    })
  }
}

