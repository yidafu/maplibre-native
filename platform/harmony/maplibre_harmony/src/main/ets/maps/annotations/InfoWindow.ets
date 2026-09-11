import { Marker } from './Marker';
import { CenterOffset } from './AnnotationView';
import type { InfoWindowBuilderContext } from './ViewAnnotationTypes';
import { ComponentContent } from '@kit.ArkUI';
import measure from '@ohos.measure';

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
  // Reserved fields: the default ComponentContent render pipeline cannot inject
  // arbitrary @Builder functions, so these are currently not rendered.
  leftAccessoryBuilder?: () => void;
  rightAccessoryBuilder?: () => void;
  showCloseButton?: boolean;
  thumbnailImage?: ResourceStr;
  offsetX?: number;
  offsetY?: number;
}

/** Shared default so estimation and layout agree on the same clamp. */
const DEFAULT_MAX_WIDTH = 280;

const DEFAULT_INFO_WINDOW_STYLE: InfoWindowStyle = {
  showCloseButton: true
};

/**
 * Layout options applied to the underlying ViewAnnotation entry.
 */
export interface InfoWindowLayoutOptions {
  centerOffset?: CenterOffset;
  anchorHeight?: number;
  anchorU?: number;
  anchorV?: number;
  zIndex?: number;
}

export interface InfoWindowRenderContext {
  onWindowClick?: () => void;
  onLongClick?: () => void;
  onClose?: () => void;
  onSizeChanged?: (width: number, height: number) => void;
}

/**
 * InfoWindowRenderParams - data passed to the default ComponentContent for rendering.
 */
export interface InfoWindowRenderParams {
  markerId: number;
  title: string;
  snippet: string;
  style: InfoWindowStyle;
  onClick?: () => void;
  onLongClick?: () => void;
  onClose?: () => void;
  onSizeChanged?: (width: number, height: number) => void;
}

/**
 * Default @Builder for rendering an InfoWindow via the ComponentContent pipeline.
 *
 * Wrapped via wrapBuilder<[InfoWindowRenderParams]> and passed to the
 * ComponentContent constructor so the ArkUI framework can instantiate
 * the InfoWindowComponent with the correct parameters.
 */
@Builder
function infoWindowDefaultBuilder(params: InfoWindowRenderParams) {
  InfoWindowComponent({
    markerId: params.markerId,
    markerTitle: params.title,
    markerSnippet: params.snippet,
    arrowOffsetX: 0,
    customStyle: params.style,
    onWindowClick: params.onClick,
    onLongClick: params.onLongClick,
    onClose: params.onClose,
    onSizeChanged: params.onSizeChanged,
  });
}

/**
 * InfoWindow - ViewAnnotation-backed InfoWindow descriptor.
 *
 * Each InfoWindow wraps a Marker and manages its own style, layout options,
 * and ComponentContent for rendering via the ViewAnnotation pipeline.
 */
export class InfoWindow {
  private readonly marker: Marker;
  private style: InfoWindowStyle;
  private width: number = 0;
  private height: number = 0;
  private annotationId: number = -1;
  private visible: boolean = false;
  private layoutOptions: InfoWindowLayoutOptions = {
    centerOffset: undefined,
    anchorHeight: undefined,
    anchorU: 0.5,
    anchorV: 1.0,
    zIndex: undefined
  };
  private customComponentContent: ComponentContent<InfoWindowRenderParams> | null = null;
  private defaultComponentContent: ComponentContent<InfoWindowRenderParams> | null = null;
  private renderContext: InfoWindowRenderContext;

  constructor(marker: Marker, renderContext: InfoWindowRenderContext, style?: InfoWindowStyle, customComponentContent?: ComponentContent<InfoWindowRenderParams>) {
    this.marker = marker;
    this.renderContext = renderContext;
    this.style = {};
    this.applyStylePatch(DEFAULT_INFO_WINDOW_STYLE);
    this.applyStylePatch(style ?? {});
    if (customComponentContent) {
      this.customComponentContent = customComponentContent;
    }
  }

  public getMarker(): Marker {
    return this.marker;
  }

  public getStyle(): InfoWindowStyle {
    return this.style;
  }

  /**
   * Merge the patch into the current style. Fields left undefined in the
   * patch keep their previous values (true partial update).
   */
  public setStyle(style: InfoWindowStyle): InfoWindow {
    this.applyStylePatch(style);
    this.width = 0;
    this.height = 0;
    return this;
  }

  private applyStylePatch(patch: InfoWindowStyle): void {
    if (patch.backgroundColor !== undefined) {
      this.style.backgroundColor = patch.backgroundColor;
    }
    if (patch.borderRadius !== undefined) {
      this.style.borderRadius = patch.borderRadius;
    }
    if (patch.shadowRadius !== undefined) {
      this.style.shadowRadius = patch.shadowRadius;
    }
    if (patch.shadowColor !== undefined) {
      this.style.shadowColor = patch.shadowColor;
    }
    if (patch.titleFontSize !== undefined) {
      this.style.titleFontSize = patch.titleFontSize;
    }
    if (patch.titleFontColor !== undefined) {
      this.style.titleFontColor = patch.titleFontColor;
    }
    if (patch.snippetFontSize !== undefined) {
      this.style.snippetFontSize = patch.snippetFontSize;
    }
    if (patch.snippetFontColor !== undefined) {
      this.style.snippetFontColor = patch.snippetFontColor;
    }
    if (patch.padding !== undefined) {
      this.style.padding = patch.padding;
    }
    if (patch.maxWidth !== undefined) {
      this.style.maxWidth = patch.maxWidth;
    }
    if (patch.animated !== undefined) {
      this.style.animated = patch.animated;
    }
    if (patch.leftAccessoryBuilder !== undefined) {
      this.style.leftAccessoryBuilder = patch.leftAccessoryBuilder;
    }
    if (patch.rightAccessoryBuilder !== undefined) {
      this.style.rightAccessoryBuilder = patch.rightAccessoryBuilder;
    }
    if (patch.thumbnailImage !== undefined) {
      this.style.thumbnailImage = patch.thumbnailImage;
    }
    if (patch.offsetX !== undefined) {
      this.style.offsetX = patch.offsetX;
    }
    if (patch.offsetY !== undefined) {
      this.style.offsetY = patch.offsetY;
    }
    if (patch.showCloseButton !== undefined) {
      this.style.showCloseButton = patch.showCloseButton;
    }
  }

  public setLayoutOptions(options: InfoWindowLayoutOptions): InfoWindow {
    this.layoutOptions = {
      centerOffset: options.centerOffset ? { dx: options.centerOffset.dx, dy: options.centerOffset.dy } : undefined,
      anchorHeight: options.anchorHeight ?? this.layoutOptions.anchorHeight,
      anchorU: options.anchorU ?? this.layoutOptions.anchorU ?? 0.5,
      anchorV: options.anchorV ?? this.layoutOptions.anchorV ?? 1.0,
      zIndex: options.zIndex ?? undefined
    };
    return this;
  }

  public getLayoutOptions(): InfoWindowLayoutOptions {
    return {
      centerOffset: this.layoutOptions.centerOffset ? { dx: this.layoutOptions.centerOffset.dx, dy: this.layoutOptions.centerOffset.dy } : undefined,
      anchorHeight: this.layoutOptions.anchorHeight,
      anchorU: this.layoutOptions.anchorU,
      anchorV: this.layoutOptions.anchorV,
      zIndex: this.layoutOptions.zIndex
    };
  }

  public setAnnotationId(id: number): void {
    this.annotationId = id;
  }

  public getAnnotationId(): number {
    return this.annotationId;
  }

  public resetAnnotation(): void {
    this.annotationId = -1;
    this.visible = false;
  }

  public setVisible(visible: boolean): void {
    this.visible = visible;
  }

  public isShown(): boolean {
    return this.visible;
  }

  /**
   * Record a measured size, deduplicating sub-epsilon changes so callers can
   * skip redundant native updates when onAreaChange fires repeatedly.
   */
  public updateSize(width: number, height: number): boolean {
    if (width <= 0 || height <= 0) {
      return false;
    }
    const SIZE_EPSILON = 0.1;
    const widthChanged = Math.abs(width - this.width) > SIZE_EPSILON;
    const heightChanged = Math.abs(height - this.height) > SIZE_EPSILON;
    if (!(widthChanged || heightChanged)) {
      return false;
    }
    this.width = width;
    this.height = height;
    return true;
  }

  public getWidth(): number {
    return this.width;
  }

  public getHeight(): number {
    return this.height;
  }

  public estimateSize(): InfoWindowSize {
    const title = this.marker.getTitle() || '';
    const snippet = this.marker.getSnippet() || '';
    const titleFontSize = this.style.titleFontSize ?? 16;
    const snippetFontSize = this.style.snippetFontSize ?? 14;
    const padding = this.style.padding ?? 12;
    const maxWidth = this.style.maxWidth ?? DEFAULT_MAX_WIDTH;
    const showCloseButton = this.style.showCloseButton !== false;
    const thumbnailWidth = this.style.thumbnailImage ? 40 : 0;
    const closeButtonWidth = showCloseButton ? 36 : 0;

    const textAreaWidth = Math.max(maxWidth - padding * 2 - thumbnailWidth - closeButtonWidth, 60);
    const titleWidth = title ? this.measureTextWidth(title, titleFontSize, true) : 0;
    const snippetWidth = snippet ? this.measureTextWidth(snippet, snippetFontSize, false) : 0;
    const contentWidth = Math.max(titleWidth, snippetWidth);
    const estimatedWidth = Math.max(contentWidth + padding * 2 + thumbnailWidth + closeButtonWidth, 80);
    const width = Math.min(estimatedWidth, maxWidth);

    // The default UI renders the title on one line and the snippet on at most two.
    const titleLines = title ? 1 : 0;
    const snippetLines = snippet ? Math.min(2, Math.max(1, Math.ceil(snippetWidth / textAreaWidth))) : 0;
    const titleHeight = titleLines * (titleFontSize + 8);
    const snippetHeight = snippetLines * (snippetFontSize + 4);
    const arrowHeight = 10;
    const closeButtonHeight = showCloseButton ? 32 : 0;
    const estimatedHeight = closeButtonHeight + titleHeight + snippetHeight + padding * 2 + arrowHeight;
    return {
      width: width,
      height: estimatedHeight
    };
  }

  private measureTextWidth(text: string, fontSize: number, bold: boolean): number {
    try {
      return measure.measureText({
        textContent: text,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.Bold : FontWeight.Normal
      });
    } catch (error) {
      // Fallback heuristic: CJK glyphs are ~1em wide, Latin ~0.55em.
      let width = 0;
      for (const ch of text) {
        width += ch.charCodeAt(0) > 0x2E7F ? fontSize : fontSize * 0.55;
      }
      return width;
    }
  }

  /**
   * Snapshot the current marker/style state as render params. Used both when
   * creating the default ComponentContent and when refreshing it via update().
   */
  public buildRenderParams(): InfoWindowRenderParams {
    return {
      markerId: this.marker.getId(),
      title: this.marker.getTitle() || '',
      snippet: this.marker.getSnippet() || '',
      style: this.style,
      onClick: this.renderContext.onWindowClick,
      onLongClick: this.renderContext.onLongClick,
      onClose: this.renderContext.onClose,
      onSizeChanged: this.renderContext.onSizeChanged,
    };
  }

  /**
   * Get the ComponentContent for rendering this InfoWindow.
   *
   * Returns the custom ComponentContent if set via adapter or
   * setCustomComponentContent(). Otherwise returns the cached default
   * ComponentContent, refreshing its params (title/snippet/style) via
   * update() so later marker edits are reflected; creates it on first use.
   *
   * @param uiContext UIContext required to create the default content.
   * @returns The ComponentContent to render, or null if UIContext is missing for default.
   */
  public getComponentContent(uiContext: UIContext | null): ComponentContent<InfoWindowRenderParams> | null {
    if (this.customComponentContent) {
      return this.customComponentContent;
    }
    if (!uiContext) {
      return null;
    }
    if (this.defaultComponentContent) {
      this.defaultComponentContent.update(this.buildRenderParams());
      return this.defaultComponentContent;
    }
    this.defaultComponentContent = new ComponentContent<InfoWindowRenderParams>(
      uiContext,
      wrapBuilder<[InfoWindowRenderParams]>(infoWindowDefaultBuilder),
      this.buildRenderParams()
    );
    return this.defaultComponentContent;
  }

  /**
   * Set a custom ComponentContent for this InfoWindow.
   * Pass null to revert to the default rendering.
   */
  public setCustomComponentContent(content: ComponentContent<InfoWindowRenderParams> | null): void {
    this.customComponentContent = content;
  }

  /**
   * Get the currently set custom ComponentContent (may be null).
   */
  public getCustomComponentContent(): ComponentContent<InfoWindowRenderParams> | null {
    return this.customComponentContent;
  }

  public getRenderContext(): InfoWindowRenderContext {
    return this.renderContext;
  }
}

/**
 * InfoWindowComponent - Default InfoWindow UI component.
 *
 * Used by the default ComponentContent factory to render standard InfoWindows.
 * Custom adapters can create entirely different UIs via their own ComponentContent.
 */
@Component
export struct InfoWindowComponent {
  @Prop markerId: number = 0;
  @Prop markerTitle: string = '';
  @Prop markerSnippet: string = '';
  @Prop arrowOffsetX: number = 0;
  @Prop customStyle: InfoWindowStyle | null = null;
  onWindowClick?: () => void;
  onLongClick?: () => void;
  onClose?: () => void;
  onSizeChanged?: (width: number, height: number) => void;

  /**
   * Appear/disappear transition. Plays a fade + scale-in entrance unless the
   * style opts out via animated === false. Removal stays immediate because the
   * owning ViewAnnotation is torn down on close.
   */
  private buildTransition(): TransitionEffect {
    if (this.customStyle?.animated === false) {
      return TransitionEffect.IDENTITY;
    }
    const curve: AnimateParam = { duration: 250, curve: Curve.EaseOut };
    return TransitionEffect.OPACITY
      .animation(curve)
      .combine(TransitionEffect.scale({ x: 0.85, y: 0.85, centerX: '50%', centerY: '100%' }).animation(curve));
  }

  build() {
    Column() {
      Column() {
        Row({ space: 8 }) {
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
                  .constraintSize({ maxWidth: this.customStyle?.maxWidth ?? DEFAULT_MAX_WIDTH })
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
                .constraintSize({ maxWidth: this.customStyle?.maxWidth ?? DEFAULT_MAX_WIDTH })
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
      .constraintSize({ maxWidth: this.customStyle?.maxWidth ?? DEFAULT_MAX_WIDTH })

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
    .constraintSize({ maxWidth: this.customStyle?.maxWidth ?? DEFAULT_MAX_WIDTH })
    .transition(this.buildTransition())
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
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const width = Number(newValue.width);
      const height = Number(newValue.height);
      if (this.onSizeChanged && width > 0 && height > 0) {
        this.onSizeChanged(width, height);
      }
    })
  }
}
