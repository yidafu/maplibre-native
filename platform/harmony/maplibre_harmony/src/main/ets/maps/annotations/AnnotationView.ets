import maplibre from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
// import { ComponentContent } from '@kit.ArkUI';

import { Marker } from './Marker';

// 常量定义（参考 iOS/mbgl）
const PITCH_MAX_DEGREES = 60; // mbgl::util::PITCH_MAX 约为 60度
const DEFAULT_VIEW_SIZE = 40;

/**
 * 拖拽状态枚举
 *
 * 参考: iOS MLNAnnotationViewDragState
 */
export enum DragState {
  None = 0, // 未拖拽
  Starting = 1, // 开始拖拽
  Dragging = 2, // 拖拽中
  Canceling = 3, // 取消拖拽
  Ending = 4 // 结束拖拽
}

/**
 * 中心偏移
 *
 * 用于调整视图中心点相对于 Marker 位置的偏移
 * 正值向右/下移动，负值向左/上移动
 */
export interface CenterOffset {
  dx: number; // 水平偏移（点）
  dy: number; // 垂直偏移（点）
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
 * 允许使用 ArkTS 组件作为 Marker 的显示视图，提供完整的自定义能力和交互特性
 * 
 * **核心特性**：
 * - ✅ 自定义视图内容（通过 @BuilderParam）
 * - ✅ 选中状态管理（点击切换）
 * - ✅ 拖拽支持（长按启动）
 * - ✅ 视图复用（reuseIdentifier）
 * - ✅ 距离缩放（scalesWithViewingDistance）
 * - ✅ 跟随旋转（rotatesToMatchCamera）
 * - ✅ 流畅动画效果
 * 
 * **参考实现**：
 * - iOS: MLNAnnotationView - UIView 子类，支持完整的视图层次
 * - Android: 使用自定义布局 XML 或 View
 * 
 * **生命周期**：
 * 1. 创建 - 从委托或复用池获取
 * 2. aboutToAppear - 初始化位置和变换
 * 3. 更新 - 响应地图相机变化
 * 4. prepareForReuse - 重置状态用于复用
 * 5. 销毁 - 从地图移除
 * 
 * **使用示例**：
 * ```typescript
 * // 基础用法 - 使用默认图标
 * AnnotationView({
 *   marker: myMarker,
 *   reuseIdentifier: "default-pin",
 *   screenX: 100,
 *   screenY: 200
 * })
 * 
 * // 高级用法 - 自定义内容
 * AnnotationView({
 *   marker: myMarker,
 *   reuseIdentifier: "custom-pin",
 *   customContentBuilder: () => {
 *     Column() {
 *       Image($r('app.media.custom_marker'))
 *         .width(40)
 *         .height(40)
 *       Text(this.marker.getTitle())
 *         .fontSize(12)
 *         .fontColor(Color.White)
 *         .backgroundColor(Color.Red)
 *         .padding(4)
 *         .borderRadius(4)
 *     }
 *   },
 *   screenX: 100,
 *   screenY: 200,
 *   scalesWithViewingDistance: true,
 *   rotatesToMatchCamera: true
 * })
 * ```
 * 
 * **性能优化建议**：
 * - 使用 reuseIdentifier 启用视图复用
 * - 避免在 customContentBuilder 中执行耗时操作
 * - 谨慎使用 scalesWithViewingDistance（大量视图时）
 * - 合理设置 zIndex 避免过度重绘
 * 
 * @see {@link AnnotationViewDelegate} 委托接口定义
 * @see {@link AnnotationViewConfig} 配置选项
 * @see {@link AnnotationViewManager} 管理器实现
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
  // 配置属性
  @Prop isDraggable: boolean = false;
  @Prop scalesWithViewingDistance: boolean = false;
  @Prop rotatesToMatchCamera: boolean = false;
  @Prop isEnabled: boolean = true;
  @Prop selected: boolean = false;
  @Prop viewAlpha: number = 1;
  @Prop baseZIndex: number = -1;
  @Prop preferredWidth: number | null = null;
  @Prop preferredHeight: number | null = null;
  // 可见性
  @Prop visible: boolean = true;
  @Prop nativeScale: number = 1;
  @Prop nativeRotation: number = 0;
  @Prop nativeOpacity: number = 1;
  @Prop reuseVersion: number = 0;
  // 自定义内容构建器
  @BuilderParam customContentBuilder?: () => void;
  // 视图尺寸（用于计算位置）
  private viewWidth: number = DEFAULT_VIEW_SIZE;
  private viewHeight: number = DEFAULT_VIEW_SIZE;
  // Transform 跟踪（用于增量更新）
  private lastAppliedScale: number = 1;
  private lastAppliedRotation: number = 0;
  // 拖拽相关
  private dragStartX: number = 0;
  private dragStartY: number = 0;
  private currentDragX: number = 0;
  private currentDragY: number = 0;
  // 地图相关（用于高级特性）
  @Prop mapBearing: number = 0;
  @Prop mapPitch: number = 0;
  @Prop screenHeight: number = 800;
  // 计算后的位置和变换（用于 build 方法）
  @State private computedPosX: number = 0;
  @State private computedPosY: number = 0;
  @State private computedScale: number = 1;
  @State private computedRotation: number = 0;
  // 回调（重命名避免与 CustomComponent 方法冲突）
  onSelect?: (marker: Marker) => void;
  onDeselect?: (marker: Marker) => void;
  onMarkerDragStart?: (marker: Marker) => void; // 重命名
  onDrag?: (marker: Marker, screenX: number, screenY: number) => void;
  onMarkerDragEnd?: (marker: Marker, screenX: number, screenY: number) => void; // 重命名
  // 外部配置缓存
  private viewAlphaInternal: number = 1;
  private baseZIndexInternal: number = 1;
  private lastSelectedProp: boolean = false;
  private lastReuseVersion: number = -1;

  /**
   * 准备复用（重置状态）
   *
   * 参考: iOS MLNAnnotationView prepareForReuse
   * 当视图从复用池中取出时调用，重置所有可变状态
   */
  public prepareForReuse(): void {
    this.viewState.selected = false;
    this.viewState.dragState = DragState.None;
    this.viewOpacity = 1;
    this.viewScale = 1;
    this.rotation = 0;
    this.lastAppliedScale = 1;
    this.lastAppliedRotation = 0;
    this.viewAlphaInternal = 1;
    this.baseZIndexInternal = 1;
    this.lastSelectedProp = false;
    this.updateComputedProperties();
  }

  /**
   * 设置选中状态
   */
  public setSelected(selected: boolean, animated: boolean): void {
    if (this.viewState.selected === selected) {
      return;
    }

    this.viewState.selected = selected;

    // animation 属性会自动应用到状态变化
    this.viewScale = selected ? 1.2 : 1.0;
    this.viewOpacity = selected ? 1.0 : 0.8;

    this.updateComputedProperties();

    // 触发回调
    if (selected && this.onSelect) {
      this.onSelect(this.marker);
    } else if (!selected && this.onDeselect) {
      this.onDeselect(this.marker);
    }
  }

  /**
   * 设置拖拽状态
   *
   * 参考: iOS MLNAnnotationView setDragState:animated:
   * 根据不同的拖拽状态应用不同的动画效果
   */
  public setDragState(state: DragState, animated: boolean): void {
    const prevState = this.viewState.dragState;
    this.viewState.dragState = state;

    // 参考 iOS MBXAnnotationView 的动画实现
    switch (state) {
      case DragState.None:
        this.viewScale = 1.0;
        this.viewOpacity = 1.0;
        break;

      case DragState.Starting:
        // 开始拖拽时快速放大（弹性效果）
        this.viewScale = 1.5;
        this.viewOpacity = 0.95;
        break;

      case DragState.Dragging:
        // 拖拽中保持放大状态
        this.viewScale = 1.3;
        this.viewOpacity = 0.9;
        break;

      case DragState.Canceling:
        // 取消时快速恢复
        this.viewScale = 1.0;
        this.viewOpacity = 1.0;
        break;

      case DragState.Ending:
        // 结束时从放大状态缓慢恢复
        this.viewScale = 1.0;
        this.viewOpacity = 1.0;
        break;
    }

    this.updateComputedProperties();
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
   * 更新计算后的属性
   */
  private updateComputedProperties(): void {
    const pos = this.calculatePosition();
    this.computedPosX = pos.x;
    this.computedPosY = pos.y;
    this.computedScale = this.calculateScale();
    this.computedRotation = this.calculateRotation();
  }

  aboutToAppear() {
    this.handleReuseSignal();
    this.syncStateWithProps(true);
    this.updateComputedProperties();
  }

  aboutToRender() {
    this.handleReuseSignal();
    this.syncStateWithProps(false);
    this.updateComputedProperties();
  }

  private handleReuseSignal(): void {
    if (this.lastReuseVersion === -1) {
      this.lastReuseVersion = this.reuseVersion;
      return;
    }

    if (this.reuseVersion !== this.lastReuseVersion) {
      this.prepareForReuse();
      this.lastReuseVersion = this.reuseVersion;
    }
  }

  private syncStateWithProps(initial: boolean): void {
    this.viewState.enabled = this.isEnabled;
    this.viewState.draggable = this.isEnabled && this.isDraggable;

    this.viewState.scalesWithViewingDistance = this.scalesWithViewingDistance;
    this.viewState.rotatesToMatchCamera = this.rotatesToMatchCamera;

    if (this.preferredWidth !== null && this.preferredWidth > 0) {
      this.viewWidth = this.preferredWidth;
    }

    if (this.preferredHeight !== null && this.preferredHeight > 0) {
      this.viewHeight = this.preferredHeight;
    }

    this.viewAlphaInternal = this.viewAlpha >= 0 ? this.viewAlpha : 1;
    this.baseZIndexInternal = this.baseZIndex >= 0 ? this.baseZIndex : (this.marker.getZIndex() || 1);

    if (initial || this.lastSelectedProp !== this.selected) {
      this.applyExternalSelection(this.selected);
      this.lastSelectedProp = this.selected;
    }
  }

  private applyExternalSelection(selected: boolean): void {
    if (this.viewState.selected === selected) {
      return;
    }

    this.viewState.selected = selected;
    this.viewScale = selected ? 1.2 : 1.0;
    this.viewOpacity = selected ? 1.0 : 0.8;
  }

  /**
   * 计算缩放比例（根据距离）
   *
   * 参考: iOS MLNAnnotationView updateScaleTransformForViewingDistance
   *
   * 实现原理：
   * 1. 计算视图在屏幕上的相对位置（0.0 = 顶部，1.0 = 底部）
   * 2. 计算最大缩放减少量 = 1.0 - 相对位置
   * 3. 计算倾斜强度 = 当前倾斜角度 / 最大倾斜角度
   * 4. 最终缩放 = 1.0 - (最大缩放减少量 * 倾斜强度)
   *
   * 这样越靠近地平线的视图越小，模拟透视效果
   */
  private calculateScale(): number {
    let baseScale = this.viewScale * (this.nativeScale || 1);

    // 如果未启用或拖拽中，不应用距离缩放
    if (!this.viewState.scalesWithViewingDistance ||
      this.viewState.dragState === DragState.Dragging ||
      this.screenHeight <= 0 ||
      this.mapPitch <= 0) {
    return baseScale;
    }

    // 计算视图中心在屏幕上的归一化 Y 位置 (0.0 = 顶部, 1.0 = 底部)
    const normalizedY = Math.max(0, Math.min(1, this.screenY / this.screenHeight));

    // 最大缩放减少量：越靠近顶部（地平线），减少量越大
    const maxScaleReduction = 1.0 - normalizedY;

    // 倾斜强度：当前倾斜角度占最大倾斜角度的比例
    const pitch = Math.max(0, this.mapPitch); // 防止负值
    const pitchIntensity = Math.min(1.0, pitch / PITCH_MAX_DEGREES);

    // 计算倾斜调整后的缩放比例
    // pitchAdjustedScale 范围从 1.0（无倾斜）到 0.0（最大倾斜且在顶部）
    const pitchAdjustedScale = 1.0 - (maxScaleReduction * pitchIntensity);

    // 应用缩放，确保不会太小
    const distanceScale = Math.max(0.3, pitchAdjustedScale);

    return baseScale * distanceScale;
  }

  /**
   * 计算旋转角度
   *
   * 参考: iOS MLNAnnotationView updateRotateTransform
   */
  private calculateRotation(): number {
    let rotation = this.marker.getRotation() + (this.nativeRotation || 0);

    // 如果启用跟随地图旋转，叠加地图方向
    if (this.viewState.rotatesToMatchCamera) {
      // mapBearing 是顺时针角度，需要取负值以匹配 iOS 行为
      rotation -= this.mapBearing;
    }

    return rotation;
  }

  /**
   * 创建手势
   *
   * 组合点击、长按和拖拽手势
   * 参考: iOS MLNAnnotationView 的手势识别器配置
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

    // 如果可拖拽，添加拖拽手势组合
    if (this.viewState.draggable) {
      // 拖拽手势（Pan）
      const panGesture = PanGesture({ fingers: 1, distance: 5 })
        .onActionStart((event: GestureEvent) => {
          // Pan 开始时检查是否已经在拖拽状态
          if (this.viewState.dragState === DragState.Starting ||
            this.viewState.dragState === DragState.Dragging) {
            this.setDragState(DragState.Dragging, false);
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          if (this.viewState.dragState === DragState.Dragging) {
            this.updateDrag(event);
            this.updateComputedProperties();
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (this.viewState.dragState === DragState.Dragging) {
            this.endDrag(event);
          }
        })
        .onActionCancel(() => {
          if (this.viewState.dragState !== DragState.None) {
            this.cancelDrag();
          }
        });

      // 长按手势用于启动拖拽
      const longPressGesture = LongPressGesture({ fingers: 1, repeat: false, duration: 500 })
        .onAction((event: GestureEvent) => {
          this.startDrag(event);
        })
        .onActionEnd(() => {
          // 如果长按结束但没有进入拖拽状态，当作点击
          if (this.viewState.dragState === DragState.Starting) {
            this.cancelDrag();
            this.setSelected(!this.viewState.selected, true);
          }
        });

      // 组合手势：长按 + 拖动（序列）或 点击（独立）
      return GestureGroup(GestureMode.Parallel,
        // 拖拽序列：长按后可以拖动
        GestureGroup(GestureMode.Sequence, longPressGesture, panGesture),
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
   * 获取当前动画曲线
   * 根据不同的状态返回不同的动画曲线
   *
   * 注意：由于 Harmony SDK 限制，使用基础曲线类型
   * 理想情况下应该使用 SpringMotion 或 Spring，但这些在当前 SDK 版本中不可用
   */
  private getAnimationCurve(): Curve {
    switch (this.viewState.dragState) {
      case DragState.Starting:
        // 开始拖拽：快速加速
        return Curve.FastOutSlowIn;
      case DragState.Ending:
        // 结束拖拽：缓慢结束
        return Curve.FastOutSlowIn;
      case DragState.Canceling:
        // 取消拖拽：快速恢复
        return Curve.FastOutSlowIn;
      default:
      // 默认：平滑过渡
        return Curve.EaseOut;
    }
  }

  /**
   * 获取动画时长
   */
  private getAnimationDuration(): number {
    switch (this.viewState.dragState) {
      case DragState.Starting:
      case DragState.Ending:
        return 400; // 参考 iOS 的 0.4 秒
      case DragState.Canceling:
        return 200;
      default:
        return 250;
    }
  }

  /**
   * 构建视图
   * 
   * 渲染逻辑：
   * 1. 如果提供了 customContentBuilder，渲染自定义内容
   * 2. 否则渲染默认图标（从 Marker 获取）
   * 3. 应用所有变换（位置、缩放、旋转、透明度）
   * 4. 设置手势、动画和 z-index
   */
  build() {
    Stack() {
      // 内容区域
      if (this.customContentBuilder) {
        // 渲染自定义内容
        // 参考：iOS MLNAnnotationView 的子视图层次
        this.customContentBuilder()
      } else {
        // 渲染默认图标
        // 参考：Android Marker 的 Icon 显示
        Image(this.marker.getIcon() || $r('app.media.startIcon'))
          .width(this.viewWidth || DEFAULT_VIEW_SIZE)
          .height(this.viewHeight || DEFAULT_VIEW_SIZE)
          .opacity(this.marker.getAlpha())
          .objectFit(ImageFit.Contain)
          .interpolation(ImageInterpolation.High) // 高质量插值
      }
    }
    .width('auto')
    .height('auto')
    // 位置变换
    .position({ x: this.computedPosX, y: this.computedPosY })
    // 透明度变换（组合 Marker 的 alpha 和视图状态的 opacity）
    .opacity(this.viewOpacity * this.marker.getAlpha() * this.viewAlphaInternal * (this.nativeOpacity || 1))
    // 缩放变换（组合距离缩放和状态缩放）
    .scale({ 
      x: this.computedScale, 
      y: this.computedScale,
      centerX: '50%',
      centerY: '100%' // 从底部中心缩放，模拟 pin 效果
    })
    // 旋转变换（组合 Marker 旋转和相机旋转）
    .rotate({ 
      angle: this.computedRotation,
      centerX: '50%',
      centerY: '100%' // 从底部中心旋转
    })
    // 动画配置
    .animation({
      duration: this.getAnimationDuration(),
      curve: this.getAnimationCurve(),
      tempo: 1.0,
      playMode: PlayMode.Normal
    })
    // 可见性
    .visibility(this.visible && this.marker.getVisible() ? Visibility.Visible : Visibility.None)
    // 手势处理
    .gesture(this.createGestures())
    // Z-index 层级管理
    // 选中 > 拖拽中 > Marker 的 zIndex > 默认
    .zIndex(
      this.viewState.selected
        ? this.baseZIndexInternal + 1000
        : (this.viewState.dragState !== DragState.None
            ? this.baseZIndexInternal + 500
            : this.baseZIndexInternal)
    )
    // 监听尺寸变化（用于位置计算）
    .onAreaChange((oldValue: Area, newValue: Area) => {
      const newWidth = Number(newValue.width);
      const newHeight = Number(newValue.height);
      
      // 只在尺寸真正改变时更新
      if (newWidth !== this.viewWidth || newHeight !== this.viewHeight) {
        this.viewWidth = newWidth;
        this.viewHeight = newHeight;
        this.updateComputedProperties();
      }
    })
    // 辅助开发：设置组件 ID（便于调试）
    .id(`annotation-view-${this.marker.getId()}`)
  }
}

