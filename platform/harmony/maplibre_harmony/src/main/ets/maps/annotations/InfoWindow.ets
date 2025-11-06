import { Point } from '../geometry/Point';
// import { ComponentContent } from '@kit.ArkUI';

// 使用 NAPI Marker 类型
import { Marker } from './Marker';

/**
 * InfoWindow 位置信息
 */
export interface InfoWindowPosition {
  x: number; // 屏幕 X 坐标
  y: number; // 屏幕 Y 坐标
  arrowOffsetX: number; // 箭头相对于中心的偏移量
}

/**
 * InfoWindow 尺寸信息
 */
interface InfoWindowSize {
  width: number;
  height: number;
}

/**
 * InfoWindow 样式配置
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

  // 附件视图支持（参考 iOS MLNCalloutView）
  leftAccessoryBuilder?: () => void; // @Builder 函数，用于自定义左侧附件
  rightAccessoryBuilder?: () => void; // @Builder 函数，用于自定义右侧附件

  // 附加功能
  showCloseButton?: boolean; // 是否显示关闭按钮
  thumbnailImage?: ResourceStr; // 缩略图（显示在标题左侧）

  // InfoWindow 偏移量
  offsetX?: number; // X 轴偏移量（像素）
  offsetY?: number; // Y 轴偏移量（像素）
}

/**
 * InfoWindow - 信息窗口类
 *
 * 显示 Marker 的详细信息，使用 Popup 组件实现
 *
 * 参考:
 * - Android: InfoWindow.java
 * - iOS: MLNCalloutView
 */
export class InfoWindow {
  private marker: Marker;
  private customView: object | null = null;
  private _isShown: boolean = false;
  private _width: number = 0;
  private _height: number = 0;
  // 位置和偏移量
  private offsetX: number = 0;
  private offsetY: number = 0;
  private markerHeightOffset: number = 0;
  private markerWidthOffset: number = 0;
  private viewWidthOffset: number = 0;
  private viewHeightOffset: number = 0;
  private screenPosition: InfoWindowPosition | null = null;
  // 样式配置
  private style: InfoWindowStyle = {};
  // 回调函数，用于通知外部需要显示/隐藏 InfoWindow
  private onShowCallback?: (marker: Marker, position: InfoWindowPosition) => void;
  private onCloseCallback?: (marker: Marker) => void;
  private onUpdateCallback?: (marker: Marker, position: InfoWindowPosition) => void;

  constructor(marker: Marker, style?: InfoWindowStyle) {
    this.marker = marker;
    if (style) {
      this.setStyle(style);
      // 从样式中应用偏移量
      if (style.offsetX !== undefined) {
        this.offsetX = style.offsetX;
      }
      if (style.offsetY !== undefined) {
        this.offsetY = style.offsetY;
      }
    }
  }

  /**
   * 设置显示回调
   */
  public setOnShowCallback(callback: (marker: Marker, position: InfoWindowPosition) => void): void {
    this.onShowCallback = callback;
  }

  /**
   * 设置关闭回调
   */
  public setOnCloseCallback(callback: (marker: Marker) => void): void {
    this.onCloseCallback = callback;
  }

  /**
   * 设置更新回调
   */
  public setOnUpdateCallback(callback: (marker: Marker, position: InfoWindowPosition) => void): void {
    this.onUpdateCallback = callback;
  }

  /**
   * 设置偏移量
   */
  public setOffset(offsetX: number, offsetY: number): void {
    this.offsetX = offsetX;
    this.offsetY = offsetY;
  }

  /**
   * 设置 InfoWindow 尺寸
   */
  public setSize(width: number, height: number): void {
    this._width = width;
    this._height = height;
  }

  /**
   * 获取 InfoWindow 宽度
   */
  public getWidth(): number {
    return this._width;
  }

  /**
   * 获取 InfoWindow 高度
   */
  public getHeight(): number {
    return this._height;
  }

  /**
   * 设置样式
   */
  public setStyle(style: InfoWindowStyle): void {
    this.style = style;
  }

  /**
   * 获取样式
   */
  public getStyle(): InfoWindowStyle {
    return this.style;
  }

  /**
   * 显示 InfoWindow
   * @param screenWidth 屏幕宽度（用于边界检测）
   * @param screenHeight 屏幕高度（用于边界检测）
   * @param markerScreenPosition Marker 的屏幕坐标
   */
  public show(screenWidth: number, screenHeight: number, markerScreenPosition: Point): void {
    if (this._isShown) {
      console.info(`[InfoWindow] Already shown, skipping`);
      return;
    }

    console.info(`[InfoWindow] show() called, calculating position...`);

    // 计算位置
    const position = this.calculateScreenPosition(
      markerScreenPosition,
      screenWidth,
      screenHeight
    );

    this.screenPosition = position;
    this._isShown = true;
    // 移除循环调用：this.marker.showInfoWindow() 
    // Marker 的状态会在 MarkerManager.selectMarker() 中管理

    console.info(`[InfoWindow] Position calculated: (${position.x}, ${position.y}), calling onShowCallback...`);

    // 通知外部显示 UI
    if (this.onShowCallback) {
      console.info(`[InfoWindow] onShowCallback exists, invoking...`);
      this.onShowCallback(this.marker, position);
      console.info(`[InfoWindow] onShowCallback completed`);
    } else {
      console.warn(`[InfoWindow] onShowCallback is null or undefined!`);
    }
  }

  /**
   * 关闭 InfoWindow
   */
  public close(): void {
    if (!this._isShown) {
      return;
    }

    this._isShown = false;
    // 移除循环调用：this.marker.hideInfoWindow()
    // Marker 的状态会在 MarkerManager 中管理

    // 通知外部隐藏 UI
    if (this.onCloseCallback) {
      this.onCloseCallback(this.marker);
    }
  }

  /**
   * 更新 InfoWindow 位置
   * @param screenWidth 屏幕宽度
   * @param screenHeight 屏幕高度
   * @param markerScreenPosition Marker 的新屏幕坐标
   */
  public update(screenWidth: number, screenHeight: number, markerScreenPosition: Point): void {
    if (!this._isShown) {
      console.info(`[InfoWindow] update() skipped - InfoWindow not shown`);
      return;
    }

    console.info(`[InfoWindow] update() called - recalculating position with size: ${this._width}x${this._height}`);

    // 重新计算位置
    const position = this.calculateScreenPosition(
      markerScreenPosition,
      screenWidth,
      screenHeight
    );

    this.screenPosition = position;
    console.info(`[InfoWindow] New position calculated: (${position.x}, ${position.y}), arrowOffsetX: ${position.arrowOffsetX}`);

    // 通知外部更新 UI
    if (this.onUpdateCallback) {
      console.info(`[InfoWindow] Calling onUpdateCallback to update UI position`);
      this.onUpdateCallback(this.marker, position);
      console.info(`[InfoWindow] onUpdateCallback completed`);
    } else {
      console.warn(`[InfoWindow] onUpdateCallback is null/undefined!`);
    }
  }

  /**
   * InfoWindow 是否正在显示
   */
  public isShown(): boolean {
    return this._isShown;
  }

  /**
   * 设置自定义视图
   */
  public setCustomView(view: object | null): void {
    this.customView = view;
  }

  /**
   * 获取自定义视图
   */
  public getCustomView(): object | null {
    return this.customView;
  }

  /**
   * 获取关联的 Marker
   */
  public getMarker(): Marker {
    return this.marker;
  }

  /**
   * 获取 InfoWindow 的标题
   */
  public getTitle(): string {
    return this.marker.getTitle();
  }

  /**
   * 获取 InfoWindow 的描述
   */
  public getSnippet(): string {
    return this.marker.getSnippet();
  }

  /**
   * 获取当前屏幕位置
   */
  public getScreenPosition(): InfoWindowPosition | null {
    return this.screenPosition;
  }

  /**
   * 估算 InfoWindow 的尺寸
   * 
   * 在实际渲染前，基于内容和样式估算尺寸
   * 
   * @returns 估算的宽度和高度（物理像素）
   */
  private estimateSize(): InfoWindowSize {
    const title = this.marker.getTitle() || '';
    const snippet = this.marker.getSnippet() || '';
    
    // 从样式中获取配置
    const titleFontSize = this.style.titleFontSize ?? 16;
    const snippetFontSize = this.style.snippetFontSize ?? 14;
    const padding = this.style.padding ?? 12;
    
    // 估算宽度：基于文本长度和字体大小
    // 使用 0.7 作为平均字符宽度比例（中英文混合）
    const titleWidth = title.length * titleFontSize * 0.7;
    const snippetWidth = snippet ? snippet.length * snippetFontSize * 0.6 : 0;
    const maxTextWidth = Math.max(titleWidth, snippetWidth);
    
    // 额外宽度：只在有缩略图时添加
    const thumbnailWidth = this.style.thumbnailImage ? 40 : 0;  // 32px 图标 + 8px margin
    
    // 估算宽度 = 文本宽度 + 左右 padding + 缩略图宽度
    const estimatedWidth = Math.max(
      maxTextWidth + padding * 2 + thumbnailWidth,
      80  // 最小宽度（保证美观）
    );
    
    // 限制最大宽度
    const maxWidth = this.style.maxWidth ?? 280;
    const width = Math.min(estimatedWidth, maxWidth);
    
    // 估算高度：基于内容行数
    const titleHeight = title ? titleFontSize + 8 : 0;  // 标题行 + 间距
    const snippetHeight = snippet ? snippetFontSize + 4 : 0;  // 描述行 + 间距
    const arrowHeight = 10;  // 箭头高度
    const closeButtonHeight = this.style.showCloseButton ? 32 : 0;
    
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
   * 计算 InfoWindow 的屏幕位置
   * 参考 Android InfoWindow.java 的位置计算逻辑
   *
   * @param markerScreenPosition Marker 的屏幕坐标
   * @param screenWidth 屏幕宽度
   * @param screenHeight 屏幕高度
   * @returns 计算后的位置信息
   */
  private calculateScreenPosition(
    markerScreenPosition: Point,
    screenWidth: number,
    screenHeight: number
  ): InfoWindowPosition {
    // 如果尺寸未知（首次显示），使用估算尺寸
    let width = this._width;
    let height = this._height;
    
    if (width === 0 || height === 0) {
      const estimated = this.estimateSize();
      width = estimated.width;
      height = estimated.height;
      console.info(`[InfoWindow] Using estimated size: ${width}x${height}`);
    }
    
    // 默认位置：居中在 Marker 上方
    let x = markerScreenPosition.x - (width / 2) + this.offsetX;
    let y = markerScreenPosition.y - height + this.offsetY;

    // 记录偏移量（用于后续更新）
    this.markerHeightOffset = this.offsetY;
    this.markerWidthOffset = -this.offsetX;

    // 计算视图偏移量
    this.viewWidthOffset = x - markerScreenPosition.x - this.offsetX;
    this.viewHeightOffset = -height + this.offsetY;

    // 箭头默认居中
    let arrowOffsetX = 0;

    // 边界检测和调整
    const margin = 16; // 边距（像素）
    const arrowWidth = 20; // 箭头宽度
    const tipViewOffset = arrowWidth / 2;

    // 检测右边界
    const rightSide = x + width;
    if (rightSide > screenWidth - margin) {
      const overflow = rightSide - (screenWidth - margin);
      x -= overflow;
      arrowOffsetX += overflow;
    }

    // 检测左边界
    const leftSide = x;
    if (leftSide < margin) {
      const overflow = margin - leftSide;
      x += overflow;
      arrowOffsetX -= overflow;
    }

    // 检测上边界
    if (y < margin) {
      y = margin;
    }

    // 检测下边界（InfoWindow 显示在 Marker 下方）
    if (y < 0) {
      // 如果上方空间不够，考虑显示在 Marker 下方
      y = markerScreenPosition.y + 10; // 10px 偏移
    }

    return {
      x: x,
      y: y,
      arrowOffsetX: arrowOffsetX
    };
  }
}

/**
 * InfoWindowComponent - InfoWindow UI 组件
 *
 * 使用 Popup 显示 Marker 信息
 * 支持动态箭头、自定义样式、动画效果、附件视图
 *
 * 参考:
 * - Android: InfoWindow with custom views
 * - iOS: MLNCalloutView with accessory views
 */
@Component
export struct InfoWindowComponent {
  // ⚠️ 重要：不使用 @Prop marker: Marker，因为 NAPI 对象无法被 @Prop 正确传递
  // 改为传递 Marker 的数据字段
  @Prop markerId: number = 0;
  @Prop markerTitle: string = '';
  @Prop markerSnippet: string = '';
  @Prop arrowOffsetX: number = 0; // 箭头相对于中心的偏移量
  @Prop customContent: object | null = null;
  @Prop customStyle: InfoWindowStyle | null = null;
  @State windowOpacity: number = 0; // 用于动画（重命名避免与 CustomComponent.opacity 冲突）
  @State windowScale: number = 0.8; // 用于动画（重命名避免与 CustomComponent.scale 冲突）
  @BuilderParam leftAccessoryBuilder?: () => void; // 左侧附件视图
  @BuilderParam rightAccessoryBuilder?: () => void; // 右侧附件视图
  onWindowClick?: () => void; // 重命名避免与 CustomComponent.onClick 冲突
  onLongClick?: () => void;
  onClose?: () => void;
  onSizeChanged?: (width: number, height: number) => void; // 尺寸变化回调

  aboutToAppear() {
    console.info(`[InfoWindowComponent] aboutToAppear - marker title: "${this.markerTitle}", snippet: "${this.markerSnippet}"`);
    console.info(`[InfoWindowComponent] arrowOffsetX: ${this.arrowOffsetX}`);
    // 显示动画
    const animated = this.customStyle?.animated !== false;
    if (animated) {
      // 使用 animation 替代废弃的 animateTo
      this.windowOpacity = 1;
      this.windowScale = 1;
    } else {
      this.windowOpacity = 1;
      this.windowScale = 1;
    }
  }

  build() {
    Column() {
      // 内容区域
      Column() {
        // 顶部：关闭按钮
        if (this.customStyle?.showCloseButton) {
          Row() {
            Blank()

            Text('×')
              .fontSize(24)
              .fontColor('#999999')
              .width(32)
              .height(32)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                if (this.onClose) {
                  this.onClose();
                }
              })
          }
          .width('100%')
          .height(32)
        }

        // 主内容区域：左附件 + 内容 + 右附件
        Row() {
          // 左侧附件视图（参考 iOS leftAccessoryView）
          if (this.leftAccessoryBuilder || this.customStyle?.leftAccessoryBuilder) {
            Column() {
              if (this.leftAccessoryBuilder) {
                this.leftAccessoryBuilder()
              }
            }
            .margin({ right: 8 })
          }

          // 中间内容区域
          Column() {
            // 标题行：缩略图 + 标题
            if (this.markerTitle) {
              Row() {
                // 缩略图
                if (this.customStyle?.thumbnailImage) {
                  Image(this.customStyle.thumbnailImage)
                    .width(32)
                    .height(32)
                    .borderRadius(4)
                    .margin({ right: 8 })
                }

                // 标题
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

            // 描述
            if (this.markerSnippet) {
              Text(this.markerSnippet)
                .fontSize(this.customStyle?.snippetFontSize ?? 14)
                .fontColor(this.customStyle?.snippetFontColor ?? '#666666')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 4 })
                .constraintSize({ maxWidth: this.customStyle?.maxWidth ?? 250 })
            }

            // 自定义内容（TODO: 等待 SDK 支持）
            // if (this.customContent) {
            //   ContentSlot(this.customContent)
            //     .margin({ top: 8 })
            // }
          }

          // 右侧附件视图（参考 iOS rightAccessoryView）
          if (this.rightAccessoryBuilder || this.customStyle?.rightAccessoryBuilder) {
            Column() {
              if (this.rightAccessoryBuilder) {
                this.rightAccessoryBuilder()
              }
            }
            .margin({ left: 8 })
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

      // 箭头指示器（指向 Marker）
      // 根据 arrowOffsetX 调整箭头位置
      Row() {
        // 左侧占位
        if (this.arrowOffsetX < 0) {
          Blank()
            .width(-this.arrowOffsetX)
        }

        // 箭头
        Polygon()
          .points([[0, 0], [10, 10], [20, 0]])
          .fill(this.customStyle?.backgroundColor ?? Color.White)
          .width(20)
          .height(10)

        // 右侧占位
        if (this.arrowOffsetX > 0) {
          Blank()
            .width(this.arrowOffsetX)
        }
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

