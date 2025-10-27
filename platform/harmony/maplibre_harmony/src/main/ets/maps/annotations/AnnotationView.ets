import maplibre from 'libmaplibre_native.so';
import { LatLng } from '../geometry/LatLng';
// import { ComponentContent } from '@kit.ArkUI';

type Marker = maplibre.Marker;

/**
 * 拖拽状态枚举
 * 
 * 参考: iOS MLNAnnotationViewDragState
 */
export enum DragState {
  None = 0,        // 未拖拽
  Starting = 1,    // 开始拖拽
  Dragging = 2,    // 拖拽中
  Canceling = 3,   // 取消拖拽
  Ending = 4       // 结束拖拽
}

/**
 * 中心偏移
 * 
 * 用于调整视图中心点相对于 Marker 位置的偏移
 * 正值向右/下移动，负值向左/上移动
 */
export interface CenterOffset {
  dx: number;  // 水平偏移（点）
  dy: number;  // 垂直偏移（点）
}

/**
 * ViewPosition - 视图位置
 */
interface ViewPosition {
  x: number;
  y: number;
}

/**
 * AnnotationView 状态
 */
export class AnnotationViewState {
  selected: boolean = false;
  enabled: boolean = true;
  draggable: boolean = false;
  dragState: DragState = DragState.None;
  scalesWithViewingDistance: boolean = false;
  rotatesToMatchCamera: boolean = false;
}

/**
 * AnnotationView 协议
 * 
 * 参考: iOS MLNAnnotationView
 */
export interface AnnotationViewProtocol {
  reuseIdentifier: string | null;
  prepareForReuse(): void;
  setSelected(selected: boolean, animated: boolean): void;
  setDragState(state: DragState, animated: boolean): void;
}

/**
 * AnnotationView - Marker 自定义视图组件
 * 
 * 允许使用 ETS 组件作为 Marker 的显示视图
 * 支持选中状态、拖拽、视图重用、动画效果等高级特性
 * 
 * 参考:
 * - iOS: MLNAnnotationView
 * - Android: 使用自定义布局 XML
 * 
 * 使用示例:
 * ```typescript
 * AnnotationView({
 *   marker: myMarker,
 *   reuseIdentifier: "custom-pin",
 *   customContentBuilder: () => { ... },
 *   screenX: 100,
 *   screenY: 200
 * })
 * ```
 */
@Component
export struct AnnotationView {
  @Prop marker: Marker;
  @Prop reuseIdentifier: string | null = null;
  @State private viewState: AnnotationViewState = new AnnotationViewState();
  @State private viewOpacity: number = 1; // 重命名避免冲突
  @State private viewScale: number = 1; // 重命名避免冲突
  @State private rotation: number = 0;
  
  // 位置信息（屏幕坐标）
  @Prop screenX: number = 0;
  @Prop screenY: number = 0;
  @Prop centerOffset: CenterOffset = { dx: 0, dy: 0 };
  
  // 锚点（用于定位，默认底部中心）
  @Prop anchorU: number = 0.5;
  @Prop anchorV: number = 1.0;
  
  // 可见性
  @Prop visible: boolean = true;
  
  // 自定义内容构建器
  @BuilderParam customContentBuilder?: () => void;
  
  // 视图尺寸（用于计算位置）
  private viewWidth: number = 40;
  private viewHeight: number = 40;
  
  // 拖拽相关
  private dragStartX: number = 0;
  private dragStartY: number = 0;
  private currentDragX: number = 0;
  private currentDragY: number = 0;
  
  // 地图相关（用于高级特性）
  @Prop mapBearing: number = 0;
  @Prop mapPitch: number = 0;
  @Prop screenHeight: number = 800;
  
  // 回调（重命名避免与 CustomComponent 方法冲突）
  onSelect?: (marker: Marker) => void;
  onDeselect?: (marker: Marker) => void;
  onMarkerDragStart?: (marker: Marker) => void; // 重命名
  onDrag?: (marker: Marker, screenX: number, screenY: number) => void;
  onMarkerDragEnd?: (marker: Marker, screenX: number, screenY: number) => void; // 重命名
  
  /**
   * 准备复用（重置状态）
   */
  public prepareForReuse(): void {
    this.viewState.selected = false;
    this.viewState.dragState = DragState.None;
    this.viewOpacity = 1;
    this.viewScale = 1;
    this.rotation = 0;
  }
  
  /**
   * 设置选中状态
   */
  public setSelected(selected: boolean, animated: boolean): void {
    if (this.viewState.selected === selected) {
      return;
    }
    
    this.viewState.selected = selected;
    
    if (animated) {
      animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
        this.viewScale = selected ? 1.2 : 1.0;
        this.viewOpacity = selected ? 1.0 : 0.8;
      });
    } else {
      this.viewScale = selected ? 1.2 : 1.0;
      this.viewOpacity = selected ? 1.0 : 0.8;
    }
    
    // 触发回调
    if (selected && this.onSelect) {
      this.onSelect(this.marker);
    } else if (!selected && this.onDeselect) {
      this.onDeselect(this.marker);
    }
  }
  
  /**
   * 设置拖拽状态
   */
  public setDragState(state: DragState, animated: boolean): void {
    this.viewState.dragState = state;
    
    // 根据拖拽状态调整视觉效果
    if (animated) {
      animateTo({ duration: 150, curve: Curve.EaseOut }, () => {
        if (state === DragState.Dragging) {
          this.viewScale = 1.3;
          this.viewOpacity = 0.9;
        } else if (state === DragState.None) {
          this.viewScale = 1.0;
          this.viewOpacity = 1.0;
        }
      });
    }
  }
  
  /**
   * 计算实际位置（考虑锚点和中心偏移）
   */
  private calculatePosition(): ViewPosition {
    // 拖拽中使用拖拽位置
    if (this.viewState.dragState === DragState.Dragging) {
      const pos: ViewPosition = {
        x: this.currentDragX - (this.viewWidth * this.anchorU) + this.centerOffset.dx,
        y: this.currentDragY - (this.viewHeight * this.anchorV) + this.centerOffset.dy
      };
      return pos;
    }
    
    // 正常情况
    const pos: ViewPosition = {
      x: this.screenX - (this.viewWidth * this.anchorU) + this.centerOffset.dx,
      y: this.screenY - (this.viewHeight * this.anchorV) + this.centerOffset.dy
    };
    return pos;
  }
  
  /**
   * 计算缩放比例（根据距离）
   */
  private calculateScale(): number {
    let baseScale = this.viewScale;
    
    if (this.viewState.scalesWithViewingDistance && this.mapPitch > 0) {
      // 根据地图倾斜角度和位置计算缩放
      // 越靠近屏幕顶部（地平线）越小，越靠近底部越大
      const normalizedY = this.screenY / this.screenHeight;
      const scaleFactor = 0.5 + (normalizedY * 0.5); // 0.5 到 1.0
      baseScale *= Math.max(0.5, Math.min(1.5, scaleFactor));
    }
    
    return baseScale;
  }
  
  /**
   * 计算旋转角度
   */
  private calculateRotation(): number {
    let rotation = this.marker.getRotation();
    
    if (this.viewState.rotatesToMatchCamera) {
      rotation += this.mapBearing;
    }
    
    return rotation;
  }
  
  /**
   * 创建手势
   */
  private createGestures(): GestureType {
    if (!this.viewState.enabled) {
      return TapGesture({ count: 1 })
        .onAction(() => {
          // 禁用状态下不响应
        });
    }
    
    // 基础点击手势
    const tapGesture = TapGesture({ count: 1 })
      .onAction(() => {
        if (!this.viewState.selected) {
          this.setSelected(true, true);
        }
      });
    
    // 如果可拖拽，添加拖拽手势
    if (this.viewState.draggable) {
      return GestureGroup(GestureMode.Exclusive,
        // 长按开始拖拽
        LongPressGesture({ fingers: 1, repeat: false, duration: 500 })
          .onAction((event: GestureEvent) => {
            this.startDrag(event);
          })
          .onActionEnd(() => {
            // 如果没有进入拖拽状态，则当作点击
            if (this.viewState.dragState === DragState.Starting) {
              this.cancelDrag();
              this.setSelected(!this.viewState.selected, true);
            }
          }),
        // 普通点击
        tapGesture
      );
    }
    
    return tapGesture;
  }
  
  /**
   * 开始拖拽
   */
  private startDrag(event: GestureEvent): void {
    if (!this.viewState.draggable) {
      return;
    }
    
    this.setDragState(DragState.Starting, true);
    this.dragStartX = this.screenX;
    this.dragStartY = this.screenY;
    this.currentDragX = this.screenX;
    this.currentDragY = this.screenY;
    
      if (this.onMarkerDragStart) {
        this.onMarkerDragStart(this.marker);
      }
    
    // 短暂延迟后进入拖拽状态
    setTimeout(() => {
      if (this.viewState.dragState === DragState.Starting) {
        this.setDragState(DragState.Dragging, false);
      }
    }, 100);
  }
  
  /**
   * 更新拖拽
   */
  private updateDrag(event: GestureEvent): void {
    if (this.viewState.dragState !== DragState.Dragging) {
      return;
    }
    
    // 更新拖拽位置
    this.currentDragX = this.dragStartX + event.offsetX;
    this.currentDragY = this.dragStartY + event.offsetY;
    
    if (this.onDrag) {
      this.onDrag(this.marker, this.currentDragX, this.currentDragY);
    }
  }
  
  /**
   * 结束拖拽
   */
  private endDrag(event: GestureEvent): void {
    if (this.viewState.dragState !== DragState.Dragging) {
      return;
    }
    
    this.setDragState(DragState.Ending, true);
    
      if (this.onMarkerDragEnd) {
        this.onMarkerDragEnd(this.marker, this.currentDragX, this.currentDragY);
      }
    
    // 结束后恢复正常状态
    setTimeout(() => {
      this.setDragState(DragState.None, false);
    }, 150);
  }
  
  /**
   * 取消拖拽
   */
  private cancelDrag(): void {
    this.setDragState(DragState.Canceling, true);
    this.currentDragX = this.screenX;
    this.currentDragY = this.screenY;
    
    setTimeout(() => {
      this.setDragState(DragState.None, false);
    }, 150);
  }
  
  /**
   * 默认图标视图
   */
  @Builder
  private defaultIconView() {
    Image(this.marker.getIcon() || $r('app.media.maplibre_marker_icon_default'))
      .width(this.viewWidth)
      .height(this.viewHeight)
      .opacity(this.marker.getAlpha())
      .objectFit(ImageFit.Contain)
  }
  
  build() {
    if (!this.visible) {
      return;
    }
    
    const pos = this.calculatePosition();
    const finalScale = this.calculateScale();
    const finalRotation = this.calculateRotation();
    
    Stack() {
      if (this.customContentBuilder) {
        // 自定义内容
        this.customContentBuilder()
      } else {
        // 默认图标
        this.defaultIconView()
      }
    }
    .position({ x: pos.x, y: pos.y })
    .opacity(this.viewOpacity * this.marker.getAlpha())
    .scale({ x: finalScale, y: finalScale })
    .rotate({ angle: finalRotation })
    .gesture(this.createGestures())
    .onAreaChange((oldValue: Area, newValue: Area) => {
      // 更新视图尺寸
      this.viewWidth = Number(newValue.width);
      this.viewHeight = Number(newValue.height);
    })
  }
}

