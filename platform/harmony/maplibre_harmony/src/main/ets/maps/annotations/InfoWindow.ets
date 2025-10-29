import maplibre from 'libmaplibre_native.so';
import { LatLng } from '../geometry/LatLng';
import { Point } from '../geometry/Point';
// import { ComponentContent } from '@kit.ArkUI';

// 使用 NAPI Marker 类型
type Marker = maplibre.Marker;

/**
 * InfoWindow 位置信息
 */
export interface InfoWindowPosition {
  x: number;           // 屏幕 X 坐标
  y: number;           // 屏幕 Y 坐标
  arrowOffsetX: number; // 箭头相对于中心的偏移量
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
  
  constructor(marker: Marker) {
    this.marker = marker;
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
      return;
    }
    
    // 计算位置
    const position = this.calculateScreenPosition(
      markerScreenPosition,
      screenWidth,
      screenHeight
    );
    
    this.screenPosition = position;
    this._isShown = true;
    this.marker.showInfoWindow();
    
    // 通知外部显示 UI
    if (this.onShowCallback) {
      this.onShowCallback(this.marker, position);
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
    this.marker.hideInfoWindow();
    
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
      return;
    }
    
    // 重新计算位置
    const position = this.calculateScreenPosition(
      markerScreenPosition,
      screenWidth,
      screenHeight
    );
    
    this.screenPosition = position;
    
    // 通知外部更新 UI
    if (this.onUpdateCallback) {
      this.onUpdateCallback(this.marker, position);
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
    // 默认位置：居中在 Marker 上方
    let x = markerScreenPosition.x - (this._width / 2) + this.offsetX;
    let y = markerScreenPosition.y - this._height + this.offsetY;
    
    // 记录偏移量（用于后续更新）
    this.markerHeightOffset = this.offsetY;
    this.markerWidthOffset = -this.offsetX;
    
    // 计算视图偏移量
    this.viewWidthOffset = x - markerScreenPosition.x - this.offsetX;
    this.viewHeightOffset = -this._height + this.offsetY;
    
    // 箭头默认居中
    let arrowOffsetX = 0;
    
    // 边界检测和调整
    const margin = 16; // 边距（像素）
    const arrowWidth = 20; // 箭头宽度
    const tipViewOffset = arrowWidth / 2;
    
    // 检测右边界
    const rightSide = x + this._width;
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
 * 支持动态箭头、自定义样式、动画效果
 */
@Component
export struct InfoWindowComponent {
  @Prop marker: Marker;
  @Prop arrowOffsetX: number = 0; // 箭头相对于中心的偏移量
  @Prop customContent?: object;
  @Prop customStyle?: InfoWindowStyle;
  @State windowOpacity: number = 0; // 用于动画（重命名避免与 CustomComponent.opacity 冲突）
  @State windowScale: number = 0.8; // 用于动画（重命名避免与 CustomComponent.scale 冲突）
  
  onWindowClick?: () => void; // 重命名避免与 CustomComponent.onClick 冲突
  onLongClick?: () => void;
  onClose?: () => void;
  
  aboutToAppear() {
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
        // 标题
        if (this.marker.getTitle()) {
          Text(this.marker.getTitle())
            .fontSize(this.customStyle?.titleFontSize ?? 16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.customStyle?.titleFontColor ?? '#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        
        // 描述
        if (this.marker.getSnippet()) {
          Text(this.marker.getSnippet())
            .fontSize(this.customStyle?.snippetFontSize ?? 14)
            .fontColor(this.customStyle?.snippetFontColor ?? '#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
            .width('100%')
        }
        
        // 自定义内容（TODO: 等待 SDK 支持）
        // if (this.customContent) {
        //   ContentSlot(this.customContent)
        //     .margin({ top: 8 })
        // }
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
      console.info('[InfoWindow] Content clicked for marker:', this.marker.getId());
      if (this.onWindowClick) {
        this.onWindowClick();
      }
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          console.info('[InfoWindow] Content long pressed for marker:', this.marker.getId());
          if (this.onLongClick) {
            this.onLongClick();
          }
        })
    )
  }
}


