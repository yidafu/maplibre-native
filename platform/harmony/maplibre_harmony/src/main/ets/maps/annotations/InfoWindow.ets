import { Marker } from './Marker';
import { CenterOffset } from './AnnotationView';
import {
  InfoWindowBuilderContext,
  InfoWindowWrappedBuilder,
  ViewAnnotationWrappedBuilder as ctx } from './ViewAnnotationTypes';

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
  leftAccessoryBuilder?: () => void;
  rightAccessoryBuilder?: () => void;
  showCloseButton?: boolean;
  thumbnailImage?: ResourceStr;
  offsetX?: number;
  offsetY?: number;
}

const DEFAULT_INFO_WINDOW_STYLE: InfoWindowStyle = {
  showCloseButton: true
};

/**
 * Layout options applied to the underlying ViewAnnotation entry.
 */
export interface InfoWindowLayoutOptions {
  centerOffset?: CenterOffset;
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
 * InfoWindow - ViewAnnotation-backed InfoWindow descriptor.
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
    anchorU: 0.5,
    anchorV: 1.0,
    zIndex: undefined
  };
  private customWrappedBuilder: InfoWindowWrappedBuilder | null = null
  private renderContext: InfoWindowRenderContext
  constructor(marker: Marker,  renderContext: InfoWindowRenderContext,style?: InfoWindowStyle,customWrappedBuilder?: InfoWindowWrappedBuilder) {
    this.marker = marker;
    this.style = this.mergeStyle(style ?? {});
    this.renderContext = renderContext
    if (customWrappedBuilder) {
      this.customWrappedBuilder = customWrappedBuilder
    }
  }

  public getMarker(): Marker {
    return this.marker;
  }

  public getStyle(): InfoWindowStyle {
    return this.style;
  }

  public setStyle(style: InfoWindowStyle): void {
    this.style = this.mergeStyle(style);
    this.width = 0;
    this.height = 0;
  }

  public setLayoutOptions(options: InfoWindowLayoutOptions): void {
    this.layoutOptions = {
      centerOffset: options.centerOffset ? { dx: options.centerOffset.dx, dy: options.centerOffset.dy } : undefined,
      anchorU: options.anchorU ?? this.layoutOptions.anchorU ?? 0.5,
      anchorV: options.anchorV ?? this.layoutOptions.anchorV ?? 1.0,
      zIndex: options.zIndex ?? undefined
    };
  }

  public getLayoutOptions(): InfoWindowLayoutOptions {
    return {
      centerOffset: this.layoutOptions.centerOffset ? { dx: this.layoutOptions.centerOffset.dx, dy: this.layoutOptions.centerOffset.dy } : undefined,
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

  public updateSize(width: number, height: number): boolean {
    if (width <= 0 || height <= 0) {
      return false;
    }
    const WIDTH_EPSILON = 0.1;
    const HEIGHT_EPSILON = 0.1;
    const widthChanged = Math.abs(width - this.width) > WIDTH_EPSILON;
    const heightChanged = Math.abs(height - this.height) > HEIGHT_EPSILON;
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
    const titleWidth = title.length * titleFontSize * 0.7;
    const snippetWidth = snippet ? snippet.length * snippetFontSize * 0.6 : 0;
    const maxTextWidth = Math.max(titleWidth, snippetWidth);
    const thumbnailWidth = this.style.thumbnailImage ? 40 : 0;
    const showCloseButton = this.style.showCloseButton !== false;
    const closeButtonWidth = showCloseButton ? 36 : 0;
    const estimatedWidth = Math.max(maxTextWidth + padding * 2 + thumbnailWidth + closeButtonWidth, 80);
    const maxWidth = this.style.maxWidth ?? 240;
    const width = Math.min(estimatedWidth, maxWidth);
    const titleHeight = title ? titleFontSize + 8 : 0;
    const snippetHeight = snippet ? snippetFontSize + 4 : 0;
    const arrowHeight = 10;
    const closeButtonHeight = showCloseButton ? 32 : 0;
    const estimatedHeight = closeButtonHeight + titleHeight + snippetHeight + padding * 2 + arrowHeight;
    return {
      width: width,
      height: estimatedHeight
    };
  }

  private mergeStyle(style: InfoWindowStyle): InfoWindowStyle {
    const merged: InfoWindowStyle = {};

    if (style.backgroundColor !== undefined) {
      merged.backgroundColor = style.backgroundColor;
    }
    if (style.borderRadius !== undefined) {
      merged.borderRadius = style.borderRadius;
    }
    if (style.shadowRadius !== undefined) {
      merged.shadowRadius = style.shadowRadius;
    }
    if (style.shadowColor !== undefined) {
      merged.shadowColor = style.shadowColor;
    }
    if (style.titleFontSize !== undefined) {
      merged.titleFontSize = style.titleFontSize;
    }
    if (style.titleFontColor !== undefined) {
      merged.titleFontColor = style.titleFontColor;
    }
    if (style.snippetFontSize !== undefined) {
      merged.snippetFontSize = style.snippetFontSize;
    }
    if (style.snippetFontColor !== undefined) {
      merged.snippetFontColor = style.snippetFontColor;
    }
    if (style.padding !== undefined) {
      merged.padding = style.padding;
    }
    if (style.maxWidth !== undefined) {
      merged.maxWidth = style.maxWidth;
    }
    if (style.animated !== undefined) {
      merged.animated = style.animated;
    }
    if (style.leftAccessoryBuilder !== undefined) {
      merged.leftAccessoryBuilder = style.leftAccessoryBuilder;
    }
    if (style.rightAccessoryBuilder !== undefined) {
      merged.rightAccessoryBuilder = style.rightAccessoryBuilder;
    }
    if (style.thumbnailImage !== undefined) {
      merged.thumbnailImage = style.thumbnailImage;
    }
    if (style.offsetX !== undefined) {
      merged.offsetX = style.offsetX;
    }
    if (style.offsetY !== undefined) {
      merged.offsetY = style.offsetY;
    }

    merged.showCloseButton = style.showCloseButton !== undefined
      ? style.showCloseButton
      : DEFAULT_INFO_WINDOW_STYLE.showCloseButton;

    return merged;
  }

  getWrappedBuilder(): InfoWindowWrappedBuilder {
    if (!this.customWrappedBuilder) {
      return INFO_WINDOW_WRAPPED_BUILDER_INSTANCE
    }
    return this.customWrappedBuilder
  }

  getRenderContext(): InfoWindowRenderContext {
    return this.renderContext;
  }

  public setCustomWrappedBuilder(builder: InfoWindowWrappedBuilder | null): void {
    this.customWrappedBuilder = builder;
  }

  public getCustomWrappedBuilder(): InfoWindowWrappedBuilder | null {
    return this.customWrappedBuilder;
  }
}

const INFO_WINDOW_WRAPPED_BUILDER_INSTANCE: ctx<InfoWindowBuilderContext> =
  wrapBuilder<[InfoWindowBuilderContext]>(RenderDefaultInfoWindow);

@Builder
export function RenderDefaultInfoWindow(ctx: InfoWindowBuilderContext): void {
  DefaultInfoWindowHost({
    marker: ctx.marker,
    style: ctx.infoWindow.getStyle(),
    context: ctx.builderContext,
    notifySizeChanged: ctx.notifySizeChanged
  });
}


@Component
struct DefaultInfoWindowHost {
  @Prop marker: Marker;
  @Prop style: InfoWindowStyle;
  @Prop context: InfoWindowRenderContext;
  @Prop notifySizeChanged: (width: number, height: number) => void;

  build() {
    InfoWindowComponent({
      markerId: this.marker.getId(),
      markerTitle: this.marker.getTitle(),
      markerSnippet: this.marker.getSnippet(),
      arrowOffsetX: 0,
      customStyle: this.style,
      onWindowClick: () => {
        this.context.onWindowClick?.();
      },
      onLongClick: () => {
        this.context.onLongClick?.();
      },
      onClose: () => {
        this.context.onClose?.();
      },
      onSizeChanged: (width: number, height: number) => {
        this.notifySizeChanged(width, height);
      }
    });
  }
}

/**
 * InfoWindowComponent - Default InfoWindow UI component.
 */
@Component
export struct InfoWindowComponent {
  @Prop markerId: number = 0;
  @Prop markerTitle: string = '';
  @Prop markerSnippet: string = '';
  @Prop arrowOffsetX: number = 0;
  @Prop customStyle: InfoWindowStyle | null = null;
  @State windowOpacity: number = 0;
  @State windowScale: number = 0.8;
  @BuilderParam leftAccessoryBuilder?: () => void;
  @BuilderParam rightAccessoryBuilder?: () => void;
  onWindowClick?: () => void;
  onLongClick?: () => void;
  onClose?: () => void;
  onSizeChanged?: (width: number, height: number) => void;

  aboutToAppear() {
    const animated = this.customStyle?.animated !== false;
    if (animated) {
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
                this.leftAccessoryBuilder();
              } else if (this.customStyle?.leftAccessoryBuilder) {
                // this.customStyle.leftAccessoryBuilder();
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
                this.rightAccessoryBuilder();
              } else if (this.customStyle?.rightAccessoryBuilder) {
                // this.customStyle.rightAccessoryBuilder();
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
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const width = Number(newValue.width);
      const height = Number(newValue.height);
      if (this.onSizeChanged && width > 0 && height > 0) {
        this.onSizeChanged(width, height);
      }
    })
  }
}
