/**
 * 地图手势检测器
 *
 * 统一管理地图的所有手势交互
 * 参考 Android MapGestureDetector 和 iOS MLNMapView 手势处理
 */

import { DOMAIN } from '../../constants/HiLogConstants';
import {
  OnDoubleTapListener,
  OnMapClickListener,
  OnMapLongClickListener,
  OnMoveListener,
  OnQuickZoomListener,
  OnRotateListener,
  OnScaleListener,
  OnShoveListener,
  OnTiltListener,
  OnTouchMoveListener,
  OnTouchUpListener
} from './GestureListeners';
import { FocalPoint, UiSettings } from '../UiSettings';
import { VelocityTracker } from './VelocityTracker';
import { hilog } from '@kit.PerformanceAnalysisKit';
import display from '@ohos.display';
import { NativeMapView } from 'libmaplibre.so';
import type { MapLibreMap } from '../MapLibreMap';
// 类型定义
type NativeMapViewType = NativeMapView;

const TAG = 'MapGestureDetector';
const ZOOM_RATE = 0.65; // Android MapLibreConstants.ZOOM_RATE - 缩放速率系数
const ROTATION_RATE = 0.1; // 旋转速率系数 - 调节旋转速度（越小越慢，速度降低50%）

// Android 手势优先级判断常量（参考 MapGestureDetector.java）
const MINIMUM_GESTURE_SPEED = 3.0; // 最小手势速度（像素/毫秒）
const MINIMUM_ANGLED_GESTURE_SPEED = 1.5; // 旋转时的最小缩放速度（像素/毫秒）
const ROTATION_ANGLE_THRESHOLD = 0.4; // 旋转角度阈值（度）

// Android 缩放惯性动画常量（参考 MapLibreConstants.java）
const MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE = 2.5; // 最大缩放速度变化
const SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER = 150; // 动画时长乘数（毫秒）
const MIN_SCALE_VELOCITY_THRESHOLD = 0.5; // 最小速度阈值，低于此值不触发惯性

// Android 旋转惯性动画常量（参考 MapLibreConstants.java）
const MAXIMUM_ANGULAR_VELOCITY = 30; // 最大角速度（度/秒）
const MIN_ANGULAR_VELOCITY_THRESHOLD = 5; // 最小角速度阈值（度/秒）

/**
 * 地图手势检测器类
 */
export class MapGestureDetector {
  // 监听器列表
  private moveListeners: OnMoveListener[] = [];
  private scaleListeners: OnScaleListener[] = [];
  private rotateListeners: OnRotateListener[] = [];
  private clickListeners: OnMapClickListener[] = [];
  private longClickListeners: OnMapLongClickListener[] = [];
  private doubleTapListeners: OnDoubleTapListener[] = [];
  private tiltListeners: OnTiltListener[] = [];
  private shoveListeners: OnShoveListener[] = []; // Android 风格命名，等同于 Tilt
  private quickZoomListeners: OnQuickZoomListener[] = [];
  private touchMoveListeners: OnTouchMoveListener[] = []; // 触摸移动监听器（用于 Marker 拖拽）
  private touchUpListeners: OnTouchUpListener[] = []; // 触摸释放监听器（用于 Marker 拖拽）

  // UI 设置
  private uiSettings: UiSettings;
  // 手势状态跟踪
  private isMoving: boolean = false;
  private isScaling: boolean = false;
  private isRotating: boolean = false;
  private isTilting: boolean = false;
  private isQuickZooming: boolean = false;
  // 手势互斥控制（参考 Android disableRotateWhenScaling）
  private shouldIgnoreRotation: boolean = false;
  // 缩放结束时间戳（用于判断 Pan Fling 是否应该被禁用）
  private lastScaleEndTimestamp: number = 0;
  private readonly SCALE_END_GRACE_PERIOD = 100; // 缩放结束后 100ms 内禁用 Pan Fling

  // 旋转结束时间戳（用于判断 Pan Fling 是否应该被禁用）
  private lastRotateEndTimestamp: number = 0;
  private readonly ROTATE_END_GRACE_PERIOD = 100; // 旋转结束后 100ms 内禁用 Pan Fling

  // 倾斜结束时间戳（用于判断 Pan Fling 是否应该被禁用）
  private lastTiltEndTimestamp: number = 0;
  private readonly TILT_END_GRACE_PERIOD = 100; // 倾斜结束后 100ms 内禁用 Pan Fling

  // 手势互斥控制 - Tilt 相关
  private shouldIgnoreTilt: boolean = false;
  // 缩放相关状态
  private currentScale: number = 1.0;
  private lastScale: number = 1.0;
  private initialZoom: number = 0;
  private currentZoomLevel: number = 0; // 🔑 缓存当前zoom级别，避免频繁调用getZoom()导致并发问题
  // 手势优先级判断相关（参考 Android）
  private previousPinchSpan: number = 0; // 上一帧的两指距离
  private previousPinchTimestamp: number = 0; // 上一帧的时间戳
  private rotationDeltaAccumulated: number = 0; // 累积的旋转增量（用于优先级判断）

  // 旋转相关状态
  private lastRotation: number = 0;
  private totalRotation: number = 0;
  private rotationAnchorX: number = 0; // 🔑 固定的旋转锚点X（手势开始时确定）
  private rotationAnchorY: number = 0; // 🔑 固定的旋转锚点Y（手势开始时确定）
  
  // 🔧 FIX: 固定的缩放锚点（在整个手势过程中保持不变）
  // 参考 Android: zoomBy 使用固定的 focalPoint，避免因 anchor 变化导致地图漂移
  private fixedScaleAnchorX: number = 0;  // 固定的缩放锚点 X（手势开始时确定）
  private fixedScaleAnchorY: number = 0;  // 固定的缩放锚点 Y（手势开始时确定）

  // 平移相关状态
  private lastPanX: number = 0;
  private lastPanY: number = 0;
  // Tilt 相关状态
  private initialPitch: number = 0;
  private tiltStartY: number = 0;
  // Quick Zoom 相关状态
  private quickZoomStartY: number = 0;
  private quickZoomStartZoom: number = 0;
  private screenHeight: number = 0;
  private doubleTapTimestamp: number = 0;
  private doubleTapX: number = 0;
  private doubleTapY: number = 0;
  private readonly QUICK_ZOOM_TIME_THRESHOLD = 300; // 双击后300ms内开始拖动触发Quick Zoom

  // 地图控制器引用 (NativeMapView 实例)
  private mapController: NativeMapViewType | null = null;
  // MapLibreMap 实例引用（用于触发高层监听器）
  private mapLibreMapInstance: MapLibreMap | null = null;
  // 速度跟踪器
  private panVelocityTracker: VelocityTracker = new VelocityTracker();
  private scaleVelocityTracker: VelocityTracker = new VelocityTracker();
  private rotateVelocityTracker: VelocityTracker = new VelocityTracker();
  // Android 的 Fling 系数（经过用户测试确定的经验值）
  // 参考：platform/android/MapLibreAndroid/src/main/java/org/maplibre/android/maps/MapGestureDetector.java:444
  // 目的：确保惯性动画的起始速度与松手瞬间的速度无缝衔接
  private readonly FLING_VELOCITY_COEFFICIENT = 0.28;
  // 缓存的设备像素比（初始化时获取一次，避免每帧查询）
  private cachedPixelRatio: number = 1.0;

  constructor(uiSettings: UiSettings) {
    this.uiSettings = uiSettings;
    // 初始化时获取并缓存 pixelRatio
    this.cachedPixelRatio = this.initializePixelRatio();
  }

  /**
   * 设置地图控制器
   */
  setMapController(controller: NativeMapViewType): void {
    this.mapController = controller;
  }

  /**
   * 设置 MapLibreMap 实例
   * 用于连接手势检测器和 MapLibreMap 的监听器系统
   */
  setMapLibreMapInstance(mapLibreMap: MapLibreMap): void {
    this.mapLibreMapInstance = mapLibreMap;
  }

  // ==================== 监听器管理 ====================

  /**
   * 添加平移手势监听器
   */
  addOnMoveListener(listener: OnMoveListener): void {
    if (!this.moveListeners.includes(listener)) {
      this.moveListeners.push(listener);
    }
  }

  /**
   * 移除平移手势监听器
   */
  removeOnMoveListener(listener: OnMoveListener): void {
    const index = this.moveListeners.indexOf(listener);
    if (index > -1) {
      this.moveListeners.splice(index, 1);
    }
  }

  /**
   * 添加缩放手势监听器
   */
  addOnScaleListener(listener: OnScaleListener): void {
    if (!this.scaleListeners.includes(listener)) {
      this.scaleListeners.push(listener);
    }
  }

  /**
   * 移除缩放手势监听器
   */
  removeOnScaleListener(listener: OnScaleListener): void {
    const index = this.scaleListeners.indexOf(listener);
    if (index > -1) {
      this.scaleListeners.splice(index, 1);
    }
  }

  /**
   * 添加旋转手势监听器
   */
  addOnRotateListener(listener: OnRotateListener): void {
    if (!this.rotateListeners.includes(listener)) {
      this.rotateListeners.push(listener);
    }
  }

  /**
   * 移除旋转手势监听器
   */
  removeOnRotateListener(listener: OnRotateListener): void {
    const index = this.rotateListeners.indexOf(listener);
    if (index > -1) {
      this.rotateListeners.splice(index, 1);
    }
  }

  /**
   * 添加点击监听器
   */
  addOnMapClickListener(listener: OnMapClickListener): void {
    if (!this.clickListeners.includes(listener)) {
      this.clickListeners.push(listener);
    }
  }

  /**
   * 移除点击监听器
   */
  removeOnMapClickListener(listener: OnMapClickListener): void {
    const index = this.clickListeners.indexOf(listener);
    if (index > -1) {
      this.clickListeners.splice(index, 1);
    }
  }

  /**
   * 添加长按监听器
   */
  addOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (!this.longClickListeners.includes(listener)) {
      this.longClickListeners.push(listener);
    }
  }

  /**
   * 移除长按监听器
   */
  removeOnMapLongClickListener(listener: OnMapLongClickListener): void {
    const index = this.longClickListeners.indexOf(listener);
    if (index > -1) {
      this.longClickListeners.splice(index, 1);
    }
  }

  /**
   * 添加双击监听器
   */
  addOnDoubleTapListener(listener: OnDoubleTapListener): void {
    if (!this.doubleTapListeners.includes(listener)) {
      this.doubleTapListeners.push(listener);
    }
  }

  /**
   * 移除双击监听器
   */
  removeOnDoubleTapListener(listener: OnDoubleTapListener): void {
    const index = this.doubleTapListeners.indexOf(listener);
    if (index > -1) {
      this.doubleTapListeners.splice(index, 1);
    }
  }

  /**
   * 添加倾斜监听器
   */
  addOnTiltListener(listener: OnTiltListener): void {
    if (!this.tiltListeners.includes(listener)) {
      this.tiltListeners.push(listener);
    }
  }

  /**
   * 移除倾斜监听器
   */
  removeOnTiltListener(listener: OnTiltListener): void {
    const index = this.tiltListeners.indexOf(listener);
    if (index > -1) {
      this.tiltListeners.splice(index, 1);
    }
  }

  /**
   * 添加 Shove 监听器（Android 风格，等同于 Tilt）
   * 参考 Android MapLibreMap.addOnShoveListener
   */
  addOnShoveListener(listener: OnShoveListener): void {
    if (!this.shoveListeners.includes(listener)) {
      this.shoveListeners.push(listener);
    }
  }

  /**
   * 移除 Shove 监听器
   */
  removeOnShoveListener(listener: OnShoveListener): void {
    const index = this.shoveListeners.indexOf(listener);
    if (index > -1) {
      this.shoveListeners.splice(index, 1);
    }
  }

  /**
   * 添加 Quick Zoom 监听器
   */
  addOnQuickZoomListener(listener: OnQuickZoomListener): void {
    if (!this.quickZoomListeners.includes(listener)) {
      this.quickZoomListeners.push(listener);
    }
  }

  /**
   * 移除 Quick Zoom 监听器
   */
  removeOnQuickZoomListener(listener: OnQuickZoomListener): void {
    const index = this.quickZoomListeners.indexOf(listener);
    if (index > -1) {
      this.quickZoomListeners.splice(index, 1);
    }
  }

  /**
   * 添加触摸移动监听器（用于 Marker 拖拽等功能）
   * 参考 Android AndroidGesturesManager.setMoveGestureListener
   */
  addOnTouchMoveListener(listener: OnTouchMoveListener): void {
    if (!this.touchMoveListeners.includes(listener)) {
      this.touchMoveListeners.push(listener);
    }
  }

  /**
   * 移除触摸移动监听器
   */
  removeOnTouchMoveListener(listener: OnTouchMoveListener): void {
    const index = this.touchMoveListeners.indexOf(listener);
    if (index > -1) {
      this.touchMoveListeners.splice(index, 1);
    }
  }

  /**
   * 添加触摸释放监听器（用于 Marker 拖拽结束等功能）
   */
  addOnTouchUpListener(listener: OnTouchUpListener): void {
    if (!this.touchUpListeners.includes(listener)) {
      this.touchUpListeners.push(listener);
    }
  }

  /**
   * 移除触摸释放监听器
   */
  removeOnTouchUpListener(listener: OnTouchUpListener): void {
    const index = this.touchUpListeners.indexOf(listener);
    if (index > -1) {
      this.touchUpListeners.splice(index, 1);
    }
  }

  // ==================== 手势处理 ====================

  /**
   * 平移手势开始
   */
  onPanStart(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🟡 onPanStart: offset=(${event.offsetX.toFixed(1)}, ${event.offsetY.toFixed(1)})`);
    
    // 检查是否是 Quick Zoom 手势（双击后立即拖动）
    const timeSinceDoubleTap = Date.now() - this.doubleTapTimestamp;
    if (timeSinceDoubleTap < this.QUICK_ZOOM_TIME_THRESHOLD && this.doubleTapTimestamp > 0) {
      hilog.info(DOMAIN, TAG, `   🚀 Quick Zoom detected`);
      // 触发 Quick Zoom
      this.onQuickZoomStart(event, this.screenHeight || 800); // 使用默认屏幕高度
      return;
    }

    // ✅ 使用实际手指坐标初始化（与 onPanUpdate 保持一致）
    const fingerX = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const fingerY = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;
    
    hilog.debug(DOMAIN, TAG, `   finger=(${fingerX.toFixed(1)}, ${fingerY.toFixed(1)})`);

    // 🎯 在 Pan 手势开始时检查是否可以开始拖拽 Marker
    // 不需要长按，直接在触摸移动开始时检查
    if (this.mapLibreMapInstance) {
      if (this.mapLibreMapInstance.tryStartMarkerDrag(fingerX, fingerY)) {
        // Marker 拖拽已开始，不启动地图移动
        // 注意：不要设置 isMoving=true，这样地图不会移动
        return;
      }
    }

    if (!this.uiSettings.isScrollGesturesEnabled()) {
      return;
    }

    this.isMoving = true;

    this.lastPanX = fingerX;
    this.lastPanY = fingerY;

    // 重置速度跟踪器
    this.panVelocityTracker.reset();

    // 取消当前动画
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // 通知监听器
    this.notifyMoveBegin();
  }

  /**
   * 平移手势更新
   */
  onPanUpdate(event: GestureEvent): void {
    hilog.debug(DOMAIN, TAG, `🔄 onPanUpdate: offset=(${event.offsetX.toFixed(1)}, ${event.offsetY.toFixed(1)})`);
    
    // 如果正在 Quick Zoom，转发到 Quick Zoom 处理
    if (this.isQuickZooming) {
      this.onQuickZoomUpdate(event);
      return;
    }

    // ✅ HarmonyOS 关键修复：使用 fingerList[0] 的实际坐标
    // event.offsetX/offsetY 是相对偏移，值太小
    // fingerList[0].localX/localY 是手指在组件中的实际坐标（逻辑像素）
    const fingerX = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const fingerY = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;

    // 🎯 分发触摸移动事件（用于 Marker 拖拽）
    // ⚠️ 关键修复：必须在 isMoving 检查之前分发 touchMove 事件！
    // 原因：LongPress 触发后，Pan 手势可能还在 DETECTING 状态，需要移动一定距离才会被接受
    // 在 Pan 被接受之前，onPanStart 不会被调用，isMoving 仍为 false
    // 但是我们需要让 Marker 拖拽能够立即响应，所以必须先分发 touchMove 事件
    // 参考 Android AndroidGesturesManager.onTouchEvent + MoveGestureDetector
    if (this.mapLibreMapInstance) {
      if (this.mapLibreMapInstance.fireTouchMoveEvent(fingerX, fingerY)) {
        // 事件被消费（Marker 拖拽中），停止地图移动
        return;
      }
    }

    if (!this.uiSettings.isScrollGesturesEnabled() || !this.isMoving) {
      return;
    }

    // 🔑 关键修复：如果正在缩放或旋转，或者刚刚结束，忽略平移更新（避免多手势冲突导致地图漂移）
    const timeSinceScaleEnd = Date.now() - this.lastScaleEndTimestamp;
    const timeSinceRotateEnd = Date.now() - this.lastRotateEndTimestamp;
    const timeSinceTiltEnd = Date.now() - this.lastTiltEndTimestamp;
    
    if (this.isScaling || this.isRotating || this.isTilting ||
        timeSinceScaleEnd < this.SCALE_END_GRACE_PERIOD ||
        timeSinceRotateEnd < this.ROTATE_END_GRACE_PERIOD ||
        timeSinceTiltEnd < this.TILT_END_GRACE_PERIOD) {
      hilog.debug(DOMAIN, TAG, `   ⏸️ Pan update ignored: isScaling=${this.isScaling}, isRotating=${this.isRotating}, timeSinceScaleEnd=${timeSinceScaleEnd}ms`);
      return;
    }

    // 计算原始增量（逻辑像素）
    const rawDeltaX = fingerX - this.lastPanX;
    const rawDeltaY = fingerY - this.lastPanY;

    // 应用 pixelRatio 缩放（使用缓存的值，避免每帧查询）
    const pixelRatio = this.getPixelRatio();
    const deltaX = rawDeltaX * pixelRatio;
    const deltaY = rawDeltaY * pixelRatio;

    // 🔍 调试日志：输出原始和缩放后的 delta

    // 更新记录（使用实际手指坐标）
    this.lastPanX = fingerX;
    this.lastPanY = fingerY;

    // 记录速度样本（使用实际手指坐标）
    const now = Date.now();
    this.panVelocityTracker.addSample(fingerX, fingerY, now);

    // 检查水平滚动限制
    let actualDeltaX = deltaX;
    if (!this.uiSettings.isHorizontalScrollGesturesEnabled()) {
      actualDeltaX = 0;
    }

    // 移动地图（使用 pixelRatio 缩放后的 delta）
    // ✅ HarmonyOS 手势语义：手指向右滑 → 地图向右移（跟随手指）
    if (this.mapController && (actualDeltaX !== 0 || deltaY !== 0)) {
      this.mapController.moveBy(actualDeltaX, deltaY, 0);
    }

    // 通知监听器
    this.notifyMove(actualDeltaX, deltaY);
  }

  /**
   * 平移手势结束
   *
   * 完全匹配 Android 实现（MapGestureDetector.java:416-463）
   * 关键点：
   * 1. pixelRatio 归一化速度，确保跨设备体验一致
   * 2. 使用归一化速度计算 duration
   * 3. 使用 0.28 系数（Android 经验值）
   */
  onPanEnd(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🔴 onPanEnd: offset=(${event.offsetX.toFixed(1)}, ${event.offsetY.toFixed(1)})`);
    
    // 如果正在 Quick Zoom，转发到 Quick Zoom 处理
    if (this.isQuickZooming) {
      this.onQuickZoomEnd(event);
      return;
    }

    // 🎯 分发触摸释放事件（用于 Marker 拖拽结束）
    // 参考 Android MoveGestureDetector.onMoveEnd + iOS handlePan (UIGestureRecognizerStateEnded)
    const fingerX = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const fingerY = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;

    // 通过 MapLibreMap 分发事件
    if (this.mapLibreMapInstance) {
      if (this.mapLibreMapInstance.fireTouchUpEvent(fingerX, fingerY)) {
        // 事件被消费
      }
    }

    if (!this.isMoving) {
      return;
    }

    // 🔧 关键修复：如果正在缩放/旋转/倾斜或刚刚完成这些手势，禁用 Pan 的 Fling 动画
    // 避免这些手势时的手指移动被误认为是平移手势，触发不必要的 Fling
    const timeSinceScaleEnd = Date.now() - this.lastScaleEndTimestamp;
    const timeSinceRotateEnd = Date.now() - this.lastRotateEndTimestamp;
    const timeSinceTiltEnd = Date.now() - this.lastTiltEndTimestamp;
    if (this.isScaling || this.isRotating || this.isTilting ||
      timeSinceScaleEnd < this.SCALE_END_GRACE_PERIOD ||
      timeSinceRotateEnd < this.ROTATE_END_GRACE_PERIOD ||
      timeSinceTiltEnd < this.TILT_END_GRACE_PERIOD) {
      let reason = '';
      if (this.isScaling) {
        reason = 'scaling in progress';
      } else if (this.isRotating) {
        reason = 'rotation in progress';
      } else if (this.isTilting) {
        reason = 'tilt in progress';
      } else if (timeSinceScaleEnd < this.SCALE_END_GRACE_PERIOD) {
        reason = `scaling ended ${timeSinceScaleEnd}ms ago`;
      } else if (timeSinceRotateEnd < this.ROTATE_END_GRACE_PERIOD) {
        reason = `rotation ended ${timeSinceRotateEnd}ms ago`;
      } else {
        reason = `tilt ended ${timeSinceTiltEnd}ms ago`;
      }
      this.isMoving = false;

      // 设置手势完成
      if (this.mapController) {
        this.mapController.setGestureInProgress(false);
      }

      // 通知监听器
      this.notifyMoveEnd();
      return;
    }

    // 检查是否应该播放惯性动画（Fling）
    if (this.uiSettings.isFlingVelocityAnimationEnabled() &&
    this.panVelocityTracker.hasEnoughData()) {

      const velocity = this.panVelocityTracker.getVelocity();
      const speed = this.panVelocityTracker.getSpeed();

      // ⚠️ 注意：HarmonyOS 与 Android 的关键区别
      // - Android: MotionEvent 返回物理像素坐标 → 需要除以 pixelRatio 归一化
      // - HarmonyOS: GestureEvent 返回逻辑像素坐标（vp）→ 已经归一化，无需处理
      // 因此 HarmonyOS 的速度已经是"逻辑像素/秒"，直接使用即可

      // 检查速度是否超过阈值
      if (speed >= this.uiSettings.getMinFlingVelocity()) {
        // 计算动画时长
        const duration = this.calculateFlingDuration(speed);

        // 使用 Android 的 0.28 系数计算偏移量
        // factor 1000: 单位转换（毫秒 → 秒）
        // factor 0.28: 经过用户测试确定的经验值，确保惯性动画起始速度与松手瞬间速度无缝衔接
        const offsetX = velocity.vx * duration * this.FLING_VELOCITY_COEFFICIENT / 1000;
        const offsetY = velocity.vy * duration * this.FLING_VELOCITY_COEFFICIENT / 1000;

        // ✅ 步骤 6：执行惯性动画（与 Android 第 463 行对应）
        // HarmonyOS 手势语义：地图跟随手指方向（正号）
        if (this.mapController && this.mapController.moveBy) {
          this.mapController.moveBy(offsetX, offsetY, duration);
        }
      } else {
      }
    }

    this.isMoving = false;

    // 设置手势完成
    if (this.mapController) {
      this.mapController.setGestureInProgress(false);
    }

    // 通知监听器
    this.notifyMoveEnd();
  }

  /**
   * 缩放手势开始
   */
  onPinchStart(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🔵 onPinchStart: scale=${event.scale.toFixed(3)}, center=(${event.pinchCenterX.toFixed(1)}, ${event.pinchCenterY.toFixed(1)})`);
    
    if (!this.uiSettings.isZoomGesturesEnabled()) {
      hilog.warn(DOMAIN, TAG, `   ⚠️ Zoom gestures disabled`);
      return;
    }

    // 🔑 Android 风格的手势优先级判断
    // 计算当前两指距离（span）
    let currentSpan = 0;
    if (event.fingerList && event.fingerList.length >= 2) {
      const dx = event.fingerList[1].localX - event.fingerList[0].localX;
      const dy = event.fingerList[1].localY - event.fingerList[0].localY;
      currentSpan = Math.sqrt(dx * dx + dy * dy);
    }

    // 如果有上一帧数据，计算速度
    if (this.previousPinchSpan > 0 && this.previousPinchTimestamp > 0) {
      const currTime = Date.now();
      const prevTime = this.previousPinchTimestamp;

      if (currTime !== prevTime) {
        const spanDelta = Math.abs(currentSpan - this.previousPinchSpan);
        const timeDelta = currTime - prevTime;
        const speed = spanDelta / timeDelta; // 像素/毫秒

        // 检查最小手势速度
        if (speed < MINIMUM_GESTURE_SPEED) {
          return;
        }

        // 如果旋转手势还没有开始，检查是否应该优先旋转
        if (!this.isRotating) {
          const rotationDelta = Math.abs(this.rotationDeltaAccumulated);

          if (rotationDelta > ROTATION_ANGLE_THRESHOLD && speed < MINIMUM_ANGLED_GESTURE_SPEED) {
            // 旋转幅度较大且缩放速度不够快，优先旋转
            return;
          }
        }
      }
    }

    // 记录当前帧数据供下次判断
    this.previousPinchSpan = currentSpan;
    this.previousPinchTimestamp = Date.now();

    this.isScaling = true;
    this.lastScale = 1.0;
    this.currentScale = 1.0;

    // 🔑 关键修复：如果旋转手势已经开始，立即终止它（避免旋转和缩放冲突）
    if (this.isRotating) {
      this.isRotating = false;
      this.notifyRotateEnd();
    }

    // 🔑 关键修复：如果倾斜手势已经开始，立即终止它（避免倾斜和缩放冲突）
    if (this.isTilting) {
      this.isTilting = false;
      this.notifyTiltEnd();
    }

    // 🔑 参考 Android: 缩放时禁用旋转和倾斜手势，避免手势冲突
    this.shouldIgnoreRotation = true;
    this.shouldIgnoreTilt = true;

    // 初始化缩放相关状态
    if (this.mapController && this.mapController.getZoom) {
      this.initialZoom = this.mapController.getZoom();
      this.currentZoomLevel = this.initialZoom; // 🔑 缓存初始zoom，避免在Update中频繁调用getZoom()
      hilog.info(DOMAIN, TAG, `   initialZoom=${this.initialZoom.toFixed(2)}`);
    } else {
      this.initialZoom = 0;
      this.currentZoomLevel = 0;
      hilog.warn(DOMAIN, TAG, `   ⚠️ mapController or getZoom not available`);
    }

    // 重置速度跟踪器
    this.scaleVelocityTracker.reset();

    // 取消动画并标记手势进行中
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // 🔧 FIX: 计算并固定缩放锚点（在整个手势过程中保持不变）
    // 参考 Android: transform.zoomBy 使用固定的 focalPoint，避免 anchor 变化导致漂移
    let anchorX = event.pinchCenterX;
    let anchorY = event.pinchCenterY;
    
    if (event.fingerList && event.fingerList.length >= 2) {
      anchorX = (event.fingerList[0].localX + event.fingerList[1].localX) / 2;
      anchorY = (event.fingerList[0].localY + event.fingerList[1].localY) / 2;
      hilog.info(DOMAIN, TAG, `   📍 Fixed anchor from fingerList: (${anchorX.toFixed(1)}, ${anchorY.toFixed(1)})`);
    }
    
    this.fixedScaleAnchorX = anchorX;
    this.fixedScaleAnchorY = anchorY;
    
    // 获取焦点并通知监听器
    const focalPoint = this.getFocalPoint(anchorX, anchorY);

    this.notifyScaleBegin(focalPoint.x, focalPoint.y);
  }

  /**
   * 缩放手势更新
   * 参考 Android onScale 实现 - 使用增量式缩放计算
   */
  onPinchUpdate(event: GestureEvent): void {
    if (!this.uiSettings.isZoomGesturesEnabled() || !this.isScaling) {
      return;
    }

    // 获取本帧的缩放因子（增量）
    this.currentScale = event.scale;
    const scaleFactor = this.currentScale / this.lastScale;

    // Android 风格的增量式缩放计算
    // 参考: MapGestureDetector.ScaleGestureListener.onScale()
    const zoomBy = (Math.log(scaleFactor) / Math.log(Math.PI / 2)) * ZOOM_RATE * this.uiSettings.getZoomRate();
    
    hilog.debug(DOMAIN, TAG, `🔄 onPinchUpdate: scale=${event.scale.toFixed(3)}, scaleFactor=${scaleFactor.toFixed(3)}, zoomBy=${zoomBy.toFixed(4)}, center=(${event.pinchCenterX.toFixed(1)}, ${event.pinchCenterY.toFixed(1)})`);

    // 🔑 关键修复：如果zoom变化太小（< 0.001），跳过本帧，避免无效的setZoom调用导致地图漂移
    // 当用户保持两指距离不变但整体移动时，固定的anchor会导致地图"吸附"
    if (Math.abs(zoomBy) < 0.001) {
      // 仍然更新 lastScale，避免下一帧计算错误
      this.lastScale = this.currentScale;
      // 仍然通知监听器（虽然zoom没变，但手势still在进行）
      // 使用固定的缩放锚点（与 Android transform.zoomBy 保持一致）
      const focalPoint = this.getFocalPoint(this.fixedScaleAnchorX, this.fixedScaleAnchorY);
      this.notifyScale(scaleFactor, focalPoint.x, focalPoint.y);
      return;
    }

    // 记录速度样本（用于惯性动画）
    const now = Date.now();
    this.scaleVelocityTracker.addSample(this.currentScale, 0, now);

    // 🔧 修复漂移问题：使用固定的缩放锚点（参考 Android transform.zoomBy）
    // Android 的 zoomBy 在整个手势过程中使用相同的 focalPoint，避免累积偏差
    // 我们在 onPinchStart 时计算并固定锚点，整个手势过程中不再变化
    const focalPoint = this.getFocalPoint(this.fixedScaleAnchorX, this.fixedScaleAnchorY);

    // 🔑 使用缓存的zoom值（避免调用getZoom()导致的并发问题和性能损耗）
    // 使用增量式缩放（类似 Android 的 transform.zoomBy）
    if (this.mapController && this.mapController.setZoom) {
      const newZoom: number = this.currentZoomLevel + zoomBy;

      // 🔑 DPI 修复：将逻辑像素转换为物理像素
      const pixelRatio = this.getPixelRatio();
      const scaledAnchorX = focalPoint.x * pixelRatio;
      const scaledAnchorY = focalPoint.y * pixelRatio;

      hilog.debug(DOMAIN, TAG, `   setZoom: ${this.currentZoomLevel.toFixed(2)} -> ${newZoom.toFixed(2)}, anchor=(${scaledAnchorX.toFixed(1)}, ${scaledAnchorY.toFixed(1)}), pixelRatio=${pixelRatio.toFixed(2)}`);
      
      this.mapController.setZoom(newZoom, scaledAnchorX, scaledAnchorY, 0);
      
      // 🔑 更新缓存的zoom级别
      this.currentZoomLevel = newZoom;
    }

    // 通知监听器
    this.notifyScale(scaleFactor, focalPoint.x, focalPoint.y);

    // 更新上一帧状态
    this.lastScale = this.currentScale;
  }

  /**
   * 计算缩放惯性动画的 zoom 增量
   * 参考 Android MapGestureDetector.calculateScale()
   * @param velocityXY 速度大小（绝对值）
   * @param isScalingOut 是否缩小
   * @returns zoom 增量
   */
  private calculateScaleZoomDelta(velocityXY: number, isScalingOut: boolean): number {
    // 对数计算，速度越大增量越大，但增长率递减
    // log(velocityXY / 4 + 1) * ZOOM_RATE
    let zoomAddition = Math.log(velocityXY / 4 + 1) * ZOOM_RATE;

    if (isScalingOut) {
      zoomAddition = -zoomAddition;
    }

    // 限制最大/最小变化量（参考 Android MathUtils.clamp）
    return Math.max(-MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE,
      Math.min(MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE, zoomAddition));
  }

  /**
   * 计算缩放惯性动画时长
   * 参考 Android MapGestureDetector.onScaleEnd()
   * @param zoomDelta zoom 增量
   * @returns 动画时长（毫秒）
   */
  private calculateScaleAnimationDuration(zoomDelta: number): number {
    // (log(|zoomDelta| + 1/e^2) + 2) * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER
    const duration = (Math.log(Math.abs(zoomDelta) + 1 / Math.pow(Math.E, 2)) + 2)
      * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER;

    // 限制在合理范围 100ms - 1000ms
    return Math.max(100, Math.min(1000, duration));
  }

  /**
   * 限制角速度到合理范围
   * 参考 Android MathUtils.clamp
   * @param angularVelocity 角速度（度/秒）
   * @returns 限制后的角速度
   */
  private clampAngularVelocity(angularVelocity: number): number {
    return Math.max(-MAXIMUM_ANGULAR_VELOCITY,
      Math.min(MAXIMUM_ANGULAR_VELOCITY, angularVelocity));
  }

  /**
   * 计算旋转惯性动画时长
   * 参考 Android MapGestureDetector.onRotateEnd()
   * @param angularVelocity 角速度（度/秒）
   * @returns 动画时长（毫秒）
   */
  private calculateRotateAnimationDuration(angularVelocity: number): number {
    // 使用与缩放相同的对数公式
    // (log(|angularVelocity| + 1/e^2) + 2) * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER
    const duration = (Math.log(Math.abs(angularVelocity) + 1 / Math.pow(Math.E, 2)) + 2)
      * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER;

    // 限制在合理范围 100ms - 1000ms
    return Math.max(100, Math.min(1000, duration));
  }

  /**
   * 缩放手势结束
   */
  onPinchEnd(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🔴 onPinchEnd: scale=${event.scale.toFixed(3)}, center=(${event.pinchCenterX.toFixed(1)}, ${event.pinchCenterY.toFixed(1)}), currentZoom=${this.currentZoomLevel.toFixed(2)}`);
    
    if (!this.isScaling) {
      hilog.warn(DOMAIN, TAG, `   ⚠️ onPinchEnd: Not in scaling state`);
      return;
    }

    // 🔧 FIX: 使用固定的缩放锚点启动惯性动画（参考 Android transform.zoomBy）
    // 整个手势过程（包括惯性动画）都使用同一个锚点，避免累积偏差
    const focalPoint = this.getFocalPoint(this.fixedScaleAnchorX, this.fixedScaleAnchorY);
    
    hilog.debug(DOMAIN, TAG, `   📍 Using fixed anchor: (${this.fixedScaleAnchorX.toFixed(1)}, ${this.fixedScaleAnchorY.toFixed(1)})`);

    // 🔧 Android 风格的缩放惯性动画（完整重写）
    // 参考：MapGestureDetector.java onScaleEnd() 方法
    if (this.uiSettings.isScaleVelocityAnimationEnabled() &&
    this.scaleVelocityTracker.hasEnoughData()) {

      const velocity = this.scaleVelocityTracker.getVelocity();
      const scaleVelocity = velocity.vx; // 使用 X 分量表示缩放速度

      // ✅ Android 风格：检查速度阈值（使用常量而非 UiSettings）
      if (Math.abs(scaleVelocity) < MIN_SCALE_VELOCITY_THRESHOLD) {
        hilog.info(DOMAIN, TAG, `   ⏸️ No fling animation: velocity=${scaleVelocity.toFixed(2)} < threshold=${MIN_SCALE_VELOCITY_THRESHOLD}`);
      } else {
        // ✅ 判断是放大还是缩小
        const isScalingOut = scaleVelocity < 0;
        const velocityXY = Math.abs(scaleVelocity);

        // ✅ 使用 Android 算法计算 zoom 增量（对数缩放）
        const zoomDelta = this.calculateScaleZoomDelta(velocityXY, isScalingOut);

        // ✅ 使用 Android 算法计算动画时长（根据缩放量动态调整）
        const duration = this.calculateScaleAnimationDuration(zoomDelta);

        hilog.info(DOMAIN, TAG, `   🚀 Fling animation: velocity=${velocityXY.toFixed(2)}, zoomDelta=${zoomDelta.toFixed(4)}, duration=${duration}ms, isScalingOut=${isScalingOut}`);

        // 🔑 执行缩放动画（使用缓存的zoom值避免并发问题）
        if (this.mapController && this.mapController.setZoom) {
          const finalZoom: number = this.currentZoomLevel + zoomDelta;

          // 🔑 DPI 修复：将逻辑像素转换为物理像素
          const pixelRatio = this.getPixelRatio();
          const scaledAnchorX = focalPoint.x * pixelRatio;
          const scaledAnchorY = focalPoint.y * pixelRatio;

          hilog.info(DOMAIN, TAG, `   setZoom with animation: ${this.currentZoomLevel.toFixed(2)} -> ${finalZoom.toFixed(2)}, anchor=(${scaledAnchorX.toFixed(1)}, ${scaledAnchorY.toFixed(1)})`);

          this.mapController.setZoom(finalZoom, scaledAnchorX, scaledAnchorY, duration);
          // 注意：不更新 currentZoomLevel，因为动画结束后 isScaling 已经是 false
        }
      }
    } else {
      hilog.info(DOMAIN, TAG, `   ⏸️ No fling animation: ScaleVelocityAnimation disabled or not enough data`);
    }

    this.isScaling = false;

    // 🔧 记录缩放结束时间戳，用于禁用紧随其后的 Pan Fling
    this.lastScaleEndTimestamp = Date.now();

    // 🔑 重置 Pan 手势状态，避免缩放期间积累的 Pan offset 在缩放结束后被应用
    // 问题：Pinch 期间 Pan 也在进行，但被 isScaling 检查忽略，lastPanX/Y 没有更新
    // 当 Pinch 结束后，下一个 Pan Update 会计算出巨大的 delta，导致地图突然跳动
    if (event.fingerList && event.fingerList.length >= 1) {
      this.lastPanX = event.fingerList[0].localX;
      this.lastPanY = event.fingerList[0].localY;
      hilog.debug(DOMAIN, TAG, `   🔧 Reset Pan state to avoid accumulated offset: (${this.lastPanX.toFixed(1)}, ${this.lastPanY.toFixed(1)})`);
    }

    // 🔑 重置手势优先级判断状态，确保下次 pinch 能正常开始
    this.previousPinchSpan = 0;
    this.previousPinchTimestamp = 0;
    this.rotationDeltaAccumulated = 0;

    // 🔑 参考 Android: 缩放结束，重新启用旋转和倾斜手势
    this.shouldIgnoreRotation = false;
    this.shouldIgnoreTilt = false;

    // 设置手势完成
    if (this.mapController) {
      this.mapController.setGestureInProgress(false);
    }

    // 通知监听器
    this.notifyScaleEnd();
  }

  /**
   * 旋转手势开始
   */
  onRotateStart(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🟢 onRotateStart: angle=${event.angle.toFixed(2)}`);
    
    if (!this.uiSettings.isRotateGesturesEnabled()) {
      hilog.warn(DOMAIN, TAG, `   ⚠️ Rotate gestures disabled`);
      return;
    }

    // 🔑 关键修复：如果正在缩放或应该忽略旋转，立即返回（避免手势冲突）
    if (this.shouldIgnoreRotation || this.isScaling) {
      return;
    }

    // 🔑 关键修复：如果倾斜手势已经开始，立即终止它（避免倾斜和旋转冲突）
    if (this.isTilting) {
      this.isTilting = false;
      this.notifyTiltEnd();
    }

    this.isRotating = true;
    this.lastRotation = 0; // 重置上一帧角度
    this.totalRotation = 0;
    this.rotationDeltaAccumulated = 0; // 重置累积的旋转增量（用于优先级判断）

    // 重置速度跟踪器
    this.rotateVelocityTracker.reset();

    // 取消动画并标记手势进行中
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // 🔑 关键修复：RotationGesture 需要从 fingerList 计算中心点
    // pinchCenterX/Y 只存在于 PinchGesture，在 RotationGesture 中为 undefined
    let centerX = 0;
    let centerY = 0;

    if (event.fingerList && event.fingerList.length >= 2) {
      const finger0X = event.fingerList[0].localX;
      const finger0Y = event.fingerList[0].localY;
      const finger1X = event.fingerList[1].localX;
      const finger1Y = event.fingerList[1].localY;

      // 计算两指中心点
      centerX = (finger0X + finger1X) / 2;
      centerY = (finger0Y + finger1Y) / 2;

    }

    const focalPoint = this.getFocalPoint(centerX, centerY);

    // 🔑 关键修复：保存固定的旋转锚点（参考 iOS - 整个旋转过程使用同一个锚点）
    this.rotationAnchorX = focalPoint.x;
    this.rotationAnchorY = focalPoint.y;

    this.notifyRotateBegin(this.rotationAnchorX, this.rotationAnchorY);
  }

  /**
   * 旋转手势更新
   * 参考 Android onRotate 实现 - 使用增量式计算
   */
  onRotateUpdate(event: GestureEvent): void {
    if (!this.uiSettings.isRotateGesturesEnabled() || !this.isRotating) {
      return;
    }

    // 🔑 关键修复：如果正在缩放或被标记为应忽略，立即返回（避免旋转和缩放冲突）
    if (this.shouldIgnoreRotation || this.isScaling) {
      return;
    }

    // 获取旋转角度（弧度转度）
    const currentRotation = event.angle * 180 / Math.PI;

    // 🔑 关键修复：使用新的增量计算函数，处理跨越边界的情况
    let rotationDelta = this.calculateAngleDelta(currentRotation, this.lastRotation);

    // 🔑 方向修复：反转旋转方向以匹配手指旋转方向（顺时针手势 → 地图顺时针旋转）
    rotationDelta = -rotationDelta;

    // 🔑 优化：如果增量太小（< 0.1°），跳过此帧，避免抖动和重复计算
    if (Math.abs(rotationDelta) < 0.1) {
      // 仍然更新 lastRotation，避免下一帧计算错误
      this.lastRotation = currentRotation;
      return;
    }

    hilog.debug(DOMAIN, TAG, `🔄 onRotateUpdate: angle=${currentRotation.toFixed(2)}°, delta=${rotationDelta.toFixed(2)}°`);

    this.totalRotation += rotationDelta;

    // 🔑 累积旋转增量供 Pinch 优先级判断使用（参考 Android getDeltaSinceLast）
    if (!this.isScaling) {
      this.rotationDeltaAccumulated += rotationDelta;
    }

    // 记录速度样本（用于惯性动画）
    const now = Date.now();
    this.rotateVelocityTracker.addSample(currentRotation, 0, now);

    // 🔑 关键修复：使用固定的旋转锚点（参考 iOS）
    // 不要每帧重新计算，而是使用手势开始时保存的固定锚点
    const anchorX = this.rotationAnchorX;
    const anchorY = this.rotationAnchorY;

    // 🔑 Android 风格：每帧从地图获取当前 bearing，加上增量
    if (this.mapController && this.mapController.getBearing && this.mapController.setBearingXY) {
      const currentBearing: number = this.mapController.getBearing();

      // 🔑 应用旋转速率系数，控制旋转速度
      const adjustedRotationDelta = rotationDelta * ROTATION_RATE * this.uiSettings.getRotationRate();
      let newBearing: number = currentBearing + adjustedRotationDelta;

      // 🔑 关键修复：归一化 bearing 到 [-180, 180]，避免跨越边界突变
      newBearing = this.normalizeBearing(newBearing);

      // 🔑 DPI 修复：鸿蒙手势坐标是逻辑像素，需要乘以 pixelRatio 转换
      const pixelRatio = this.getPixelRatio();
      const scaledAnchorX = anchorX * pixelRatio;
      const scaledAnchorY = anchorY * pixelRatio;

      this.mapController.setBearingXY(newBearing, scaledAnchorX, scaledAnchorY, 0);
    }

    // 通知监听器
    this.notifyRotate(rotationDelta, anchorX, anchorY);

    // 保存当前角度，用于下一帧计算增量
    this.lastRotation = currentRotation;
  }

  /**
   * 旋转手势结束
   */
  onRotateEnd(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🔴 onRotateEnd: angle=${event.angle.toFixed(2)}°`);
    
    if (!this.isRotating) {
      hilog.warn(DOMAIN, TAG, `   ⚠️ Not in rotating state`);
      return;
    }

    // 🔑 关键修复：使用固定的旋转锚点（用于惯性动画）
    const anchorX = this.rotationAnchorX;
    const anchorY = this.rotationAnchorY;

    // 🔧 Android 风格的旋转惯性动画（完整重写）
    // 参考：MapGestureDetector.java onRotateEnd() 方法
    if (this.uiSettings.isRotateVelocityAnimationEnabled() &&
    this.rotateVelocityTracker.hasEnoughData()) {

      const velocity = this.rotateVelocityTracker.getVelocity();
      let angularVelocity = velocity.vx; // 度/秒

      // ✅ Android 风格：限制角速度到 ±30°/s（参考 MAXIMUM_ANGULAR_VELOCITY）
      angularVelocity = this.clampAngularVelocity(angularVelocity);

      // ✅ 检查速度阈值（使用常量而非 UiSettings）
      if (Math.abs(angularVelocity) < MIN_ANGULAR_VELOCITY_THRESHOLD) {
      } else {
        // ✅ 使用 Android 算法计算动画时长（对数公式）
        const duration = this.calculateRotateAnimationDuration(angularVelocity);

        // ✅ 计算角度增量（iOS 风格：velocity * duration * 0.1）
        const deltaBearing = angularVelocity * duration / 1000 * 0.1;

        // 执行旋转动画
        if (this.mapController && this.mapController.getBearing && this.mapController.setBearingXY) {
          const currentBearing: number = this.mapController.getBearing();
          let newBearing: number = currentBearing + deltaBearing;

          // 归一化 bearing
          newBearing = this.normalizeBearing(newBearing);

          // 🔑 DPI 修复：将逻辑像素转换为物理像素
          const pixelRatio = this.getPixelRatio();
          const scaledAnchorX = anchorX * pixelRatio;
          const scaledAnchorY = anchorY * pixelRatio;

          this.mapController.setBearingXY(newBearing, scaledAnchorX, scaledAnchorY, duration);
        }
      }
    }

    this.isRotating = false;

    // 🔧 记录旋转结束时间戳，用于禁用紧随其后的 Pan Fling
    this.lastRotateEndTimestamp = Date.now();

    // 🔑 重置 Pan 手势状态，避免旋转期间积累的 Pan offset 在旋转结束后被应用
    // 与 onPinchEnd 中的修复逻辑一致
    if (event.fingerList && event.fingerList.length >= 1) {
      this.lastPanX = event.fingerList[0].localX;
      this.lastPanY = event.fingerList[0].localY;
      hilog.debug(DOMAIN, TAG, `   🔧 Reset Pan state to avoid accumulated offset: (${this.lastPanX.toFixed(1)}, ${this.lastPanY.toFixed(1)})`);
    }

    // 🔑 重置手势优先级判断状态，确保下次 pinch 能正常开始
    this.previousPinchSpan = 0;
    this.previousPinchTimestamp = 0;
    this.rotationDeltaAccumulated = 0;

    // 设置手势完成
    if (this.mapController) {
      this.mapController.setGestureInProgress(false);
    }

    // 通知监听器
    this.notifyRotateEnd();
  }

  /**
   * 单击手势
   */
  onSingleTap(event: GestureEvent): void {

    const x = event.fingerList[0].localX;
    const y = event.fingerList[0].localY;

    // 通知监听器
    this.notifyMapClick(x, y);
  }

  /**
   * 双击手势
   */
  onDoubleTap(event: GestureEvent): void {
    if (!this.uiSettings.isDoubleTapGesturesEnabled()) {
      return;
    }

    const x = event.fingerList[0].localX;
    const y = event.fingerList[0].localY;

    // 记录双击事件，用于 Quick Zoom 检测
    this.doubleTapTimestamp = Date.now();
    this.doubleTapX = x;
    this.doubleTapY = y;

    // 注意：不立即执行缩放，等待一小段时间看是否有拖动动作
    // 如果没有拖动，则在 timeout 后执行双击缩放
    setTimeout(() => {
      // 如果在这段时间内没有触发 Quick Zoom，执行双击缩放
      if (!this.isQuickZooming && Date.now() - this.doubleTapTimestamp < this.QUICK_ZOOM_TIME_THRESHOLD + 100) {
        // 默认行为：放大一级
        if (this.mapController && this.mapController.getZoom && this.mapController.setZoom) {
          const currentZoom: number = this.mapController.getZoom() as number;
          this.mapController.setZoom(currentZoom + 1);
        }

        // 通知监听器
        this.notifyDoubleTap(x, y);
      }
    }, this.QUICK_ZOOM_TIME_THRESHOLD);
  }

  /**
   * 双指点击手势（缩小）
   * 参考 iOS MLNMapView handleTwoFingerTapGesture
   */
  onTwoFingerTap(event: GestureEvent): void {
    if (!this.uiSettings.isZoomGesturesEnabled()) {
      return;
    }

    // 检查是否已经在最小缩放级别
    if (this.mapController && this.mapController.getZoom && this.mapController.getMinZoom) {
      const currentZoom: number = this.mapController.getZoom() as number;
      const minZoom: number = this.mapController.getMinZoom() as number;

      if (currentZoom <= minZoom) {
        return;
      }
    }

    // 取消当前动画
    if (this.mapController) {
      this.mapController.cancelTransitions();
    }

    // 计算两指中心点作为焦点
    let centerX = 0;
    let centerY = 0;

    if (event.fingerList && event.fingerList.length >= 2) {
      const finger0X = event.fingerList[0].localX;
      const finger0Y = event.fingerList[0].localY;
      const finger1X = event.fingerList[1].localX;
      const finger1Y = event.fingerList[1].localY;

      centerX = (finger0X + finger1X) / 2;
      centerY = (finger0Y + finger1Y) / 2;

    }

    // 获取焦点（如果用户设置了自定义焦点，使用自定义焦点）
    const focalPoint = this.getFocalPoint(centerX, centerY);

    // 🔑 DPI 修复：将逻辑像素转换为物理像素
    const pixelRatio = this.getPixelRatio();
    const scaledAnchorX = focalPoint.x * pixelRatio;
    const scaledAnchorY = focalPoint.y * pixelRatio;

    // 计算新的缩放级别：当前级别 - 1（参考 iOS）
    if (this.mapController && this.mapController.getZoom && this.mapController.setZoom) {
      const currentZoom: number = this.mapController.getZoom() as number;
      const newZoom: number = Math.round(currentZoom) - 1.0;

      // 执行带动画的缩放（300ms，参考 iOS MLNAnimationDuration）
      const duration = 300;
      this.mapController.setZoom(newZoom, scaledAnchorX, scaledAnchorY, duration);
    }

    // 通知监听器
    this.notifyDoubleTap(centerX, centerY); // 复用 DoubleTap 监听器
  }

  /**
   * 长按手势
   */
  onLongPress(event: GestureEvent): void {
    const x = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const y = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;

    // 通知监听器
    this.notifyMapLongClick(x, y);
  }

  /**
   * 双指拖动倾斜手势开始
   */
  onTwoFingerPanStart(event: GestureEvent): void {
    if (!this.uiSettings.isTiltGesturesEnabled()) {
      return;
    }

    // 🔑 参考 Android Shove 手势：如果正在缩放或旋转，或被标记为应忽略，拒绝启动倾斜
    if (this.shouldIgnoreTilt || this.isScaling || this.isRotating) {
      return;
    }

    this.isTilting = true;
    this.tiltStartY = event.offsetY;

    // 获取当前 pitch
    if (this.mapController && this.mapController.getPitch) {
      this.initialPitch = this.mapController.getPitch() as number;
    } else {
      this.initialPitch = 0;
    }

    // 取消动画
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // 通知监听器
    this.notifyTiltBegin();
  }

  /**
   * 双指拖动倾斜手势更新
   */
  onTwoFingerPanUpdate(event: GestureEvent): void {
    if (!this.isTilting) {
      return;
    }

    // 计算垂直移动距离
    const deltaY = event.offsetY - this.tiltStartY;

    // 计算新的 pitch（参考 iOS slowdown factor = 2.0）
    // 参考 Android: pitch -= deltaPixels × SHOVE_PIXEL_CHANGE_FACTOR (0.1)
    const sensitivity = this.uiSettings.getTiltSensitivity();
    const newPitch = this.initialPitch - (deltaY / sensitivity);

    // 限制在有效范围内
    const clampedPitch = Math.max(
      this.uiSettings.getMinPitch(),
      Math.min(this.uiSettings.getMaxPitch(), newPitch)
    );

    // 应用倾斜
    if (this.mapController && this.mapController.setPitch) {
      this.mapController.setPitch(clampedPitch, 0); // 0 表示立即设置，无动画
    }

    // 通知监听器
    this.notifyTilt(clampedPitch);
  }

  /**
   * 双指拖动倾斜手势结束
   */
  onTwoFingerPanEnd(event: GestureEvent): void {
    if (!this.isTilting) {
      return;
    }

    this.isTilting = false;

    // 🔧 记录倾斜结束时间戳，用于禁用紧随其后的 Pan Fling
    this.lastTiltEndTimestamp = Date.now();

    // 设置手势完成
    if (this.mapController) {
      this.mapController.setGestureInProgress(false);
    }

    // 通知监听器
    this.notifyTiltEnd();
  }

  /**
   * Quick Zoom 手势开始（双击后拖动）
   */
  onQuickZoomStart(event: GestureEvent, screenHeight: number): void {
    if (!this.uiSettings.isQuickZoomGesturesEnabled()) {
      return;
    }

    this.isQuickZooming = true;
    this.quickZoomStartY = event.fingerList[0].localY;
    this.screenHeight = screenHeight;

    // 获取当前缩放级别
    if (this.mapController && this.mapController.getZoom) {
      this.quickZoomStartZoom = this.mapController.getZoom() as number;
    } else {
      this.quickZoomStartZoom = 10;
    }

    // 取消动画
    if (this.mapController) {
      this.mapController.cancelTransitions();
    }

    // 通知监听器
    this.notifyQuickZoomBegin();
  }

  /**
   * Quick Zoom 手势更新
   */
  onQuickZoomUpdate(event: GestureEvent): void {
    if (!this.isQuickZooming) {
      return;
    }

    const currentY = event.fingerList[0].localY;
    const deltaY = currentY - this.quickZoomStartY;

    // 归一化像素变化到缩放变化（参考 Android）
    const normalizedDelta = this.normalize(
      Math.abs(deltaY),
      0,
      this.screenHeight,
      0,
      this.uiSettings.getQuickZoomMaxChange()
    );

    // 向上拖动放大，向下拖动缩小
    const zoomedOut = deltaY > 0;
    const targetZoom = zoomedOut
      ? this.quickZoomStartZoom - normalizedDelta
      : this.quickZoomStartZoom + normalizedDelta;

    // 应用缩放
    if (this.mapController && this.mapController.setZoom) {
      this.mapController.setZoom(targetZoom, undefined, undefined, 0);
    }

    // 通知监听器
    this.notifyQuickZoom(targetZoom);
  }

  /**
   * Quick Zoom 手势结束
   */
  onQuickZoomEnd(event: GestureEvent): void {
    if (!this.isQuickZooming) {
      return;
    }

    this.isQuickZooming = false;

    // 通知监听器
    this.notifyQuickZoomEnd();
  }

  // ==================== 辅助方法 ====================

  /**
   * 获取手势焦点
   * 如果用户设置了自定义焦点，使用自定义焦点；否则使用手势中心点
   */
  private getFocalPoint(defaultX: number, defaultY: number): FocalPoint {
    const userFocalPoint = this.uiSettings.getFocalPoint();
    if (userFocalPoint) {
      return userFocalPoint;
    }
    return new FocalPoint(defaultX, defaultY);
  }

  /**
   * 获取手势锚点（统一的锚点计算方法）
   *
   * @param event 手势事件
   * @param gestureType 手势类型 ('pinch' | 'rotate' | 'twoFinger')
   * @returns 锚点坐标（逻辑像素）
   */
  private getGestureAnchor(event: GestureEvent, gestureType: string): FocalPoint {
    let anchorX = 0;
    let anchorY = 0;

    // 根据手势类型计算锚点
    if (gestureType === 'pinch') {
      // Pinch 手势：使用 event.pinchCenterX/Y
      anchorX = event.pinchCenterX || 0;
      anchorY = event.pinchCenterY || 0;
    } else if (gestureType === 'rotate' || gestureType === 'twoFinger') {
      // Rotate 和 TwoFinger 手势：从 fingerList 计算两指中心点
      if (event.fingerList && event.fingerList.length >= 2) {
        const finger0X = event.fingerList[0].localX;
        const finger0Y = event.fingerList[0].localY;
        const finger1X = event.fingerList[1].localX;
        const finger1Y = event.fingerList[1].localY;

        anchorX = (finger0X + finger1X) / 2;
        anchorY = (finger0Y + finger1Y) / 2;
      }
    }

    // 应用用户自定义焦点（如果有）
    return this.getFocalPoint(anchorX, anchorY);
  }

  /**
   * 将逻辑像素锚点转换为物理像素锚点
   *
   * @param anchor 逻辑像素锚点
   * @returns 物理像素锚点
   */
  private applyPixelRatioToAnchor(anchor: FocalPoint): FocalPoint {
    const pixelRatio = this.getPixelRatio();
    return new FocalPoint(
      anchor.x * pixelRatio,
      anchor.y * pixelRatio
    );
  }

  /**
   * 计算 Fling 动画时长
   *
   * 参考 Android 实现（MapGestureDetector.java:440）：
   * duration = velocityXY / 7 / tiltFactor + baseTime
   *
   * @param speed 速度大小（逻辑像素/秒）
   * @returns 动画时长（毫秒）
   */
  private calculateFlingDuration(speed: number): number {
    // 获取实际 tilt 并计算因子（tilt 越大，惯性越弱）
    let tiltFactor = 1.0;
    if (this.mapController && this.mapController.getPitch) {
      const pitch = this.mapController.getPitch() as number;
      // pitch 范围 [0, 60]，转换为 tilt 因子 [1.0, 1.5]
      // pitch 越大，tiltFactor 越大，惯性时长越短
      tiltFactor = 1.0 + (pitch / 60.0) * 0.5;
    }
    const duration = speed / 7 / tiltFactor + this.uiSettings.getFlingAnimationBaseTime();

    // 限制动画时长在合理范围（100ms - 2000ms）
    return Math.max(100, Math.min(2000, duration));
  }

  /**
   * 初始化设备像素比（只在构造时调用一次）
   * 从 display API 获取，用于坐标转换
   */
  private initializePixelRatio(): number {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      if (defaultDisplay && defaultDisplay.densityDPI) {
        const pixelRatio = defaultDisplay.densityDPI / 160.0;
        return pixelRatio;
      }
    } catch (error) {
      hilog.warn(DOMAIN, TAG, `Failed to get display DPI: ${error}, using pixelRatio=1.0`);
    }
    return 1.0;
  }

  /**
   * 获取缓存的设备像素比（高性能，无需每次查询）
   */
  private getPixelRatio(): number {
    return this.cachedPixelRatio;
  }

  /**
   * 归一化函数
   * 将值从一个范围映射到另一个范围
   */
  private normalize(value: number, min: number, max: number, newMin: number, newMax: number): number {
    if (max === min) {
      return newMin;
    } // 避免除以零
    return ((value - min) / (max - min)) * (newMax - newMin) + newMin;
  }

  /**
   * 归一化 bearing 到 [-180, 180] 范围
   * 参考 Android: 处理角度跨越边界的问题
   */
  private normalizeBearing(bearing: number): number {
    // 将角度归一化到 [-180, 180] 范围
    while (bearing > 180) {
      bearing -= 360;
    }
    while (bearing < -180) {
      bearing += 360;
    }
    return bearing;
  }

  /**
   * 计算角度增量，处理跨越边界的情况
   * 例如：从 179° 到 -179° 实际是增加了 2°，而不是减少了 358°
   */
  private calculateAngleDelta(currentAngle: number, lastAngle: number): number {
    let delta = currentAngle - lastAngle;

    // 如果增量超过 180°，说明跨越了边界，需要调整
    if (delta > 180) {
      delta -= 360;
    } else if (delta < -180) {
      delta += 360;
    }

    return delta;
  }

  // ==================== 监听器通知方法 ====================

  private notifyMoveBegin(): void {
    for (const listener of this.moveListeners) {
      try {
        listener.onMoveBegin();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onMoveBegin listener: ${error}`);
      }
    }
  }

  private notifyMove(distanceX: number, distanceY: number): void {
    for (const listener of this.moveListeners) {
      try {
        listener.onMove(distanceX, distanceY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onMove listener: ${error}`);
      }
    }
  }

  private notifyMoveEnd(): void {
    for (const listener of this.moveListeners) {
      try {
        listener.onMoveEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onMoveEnd listener: ${error}`);
      }
    }
  }

  private notifyScaleBegin(focalX: number, focalY: number): void {
    for (const listener of this.scaleListeners) {
      try {
        listener.onScaleBegin(focalX, focalY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onScaleBegin listener: ${error}`);
      }
    }
  }

  private notifyScale(scaleFactor: number, focalX: number, focalY: number): void {
    for (const listener of this.scaleListeners) {
      try {
        listener.onScale(scaleFactor, focalX, focalY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onScale listener: ${error}`);
      }
    }
  }

  private notifyScaleEnd(): void {
    for (const listener of this.scaleListeners) {
      try {
        listener.onScaleEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onScaleEnd listener: ${error}`);
      }
    }
  }

  private notifyRotateBegin(focalX: number, focalY: number): void {
    for (const listener of this.rotateListeners) {
      try {
        listener.onRotateBegin(focalX, focalY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onRotateBegin listener: ${error}`);
      }
    }
  }

  private notifyRotate(rotationDelta: number, focalX: number, focalY: number): void {
    for (const listener of this.rotateListeners) {
      try {
        listener.onRotate(rotationDelta, focalX, focalY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onRotate listener: ${error}`);
      }
    }
  }

  private notifyRotateEnd(): void {
    for (const listener of this.rotateListeners) {
      try {
        listener.onRotateEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onRotateEnd listener: ${error}`);
      }
    }
  }

  private notifyMapClick(x: number, y: number): void {
    // 1. 首先调用 MapLibreMap 的监听器（参考 Android 优先级）
    let consumed = false;
    if (this.mapLibreMapInstance) {
      consumed = this.mapLibreMapInstance._notifyMapClick(x, y);
    }

    // 2. 如果事件未被消费，调用本地监听器
    if (!consumed) {
      for (const listener of this.clickListeners) {
        try {
          if (listener.onMapClick(x, y)) {
            break; // 如果监听器消费了事件，停止传播
          }
        } catch (error) {
          hilog.error(DOMAIN, TAG, `Error in onMapClick listener: ${error}`);
        }
      }
    }
  }

  private notifyMapLongClick(x: number, y: number): void {
    // 1. 首先调用 MapLibreMap 的监听器（参考 Android 优先级）
    let consumed = false;
    if (this.mapLibreMapInstance) {
      consumed = this.mapLibreMapInstance._notifyMapLongClick(x, y);
    }

    // 2. 如果事件未被消费，调用本地监听器
    if (!consumed) {
      for (const listener of this.longClickListeners) {
        try {
          if (listener.onMapLongClick(x, y)) {
            break; // 如果监听器消费了事件，停止传播
          }
        } catch (error) {
          hilog.error(DOMAIN, TAG, `Error in onMapLongClick listener: ${error}`);
        }
      }
    }
  }

  private notifyDoubleTap(x: number, y: number): void {
    for (const listener of this.doubleTapListeners) {
      try {
        if (listener.onDoubleTap(x, y)) {
          break; // 如果监听器消费了事件，停止传播
        }
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onDoubleTap listener: ${error}`);
      }
    }
  }

  private notifyTiltBegin(): void {
    // 通知 Tilt 监听器
    for (const listener of this.tiltListeners) {
      try {
        listener.onTiltBegin();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onTiltBegin listener: ${error}`);
      }
    }
    // 同时通知 Shove 监听器（向后兼容 Android 命名）
    for (const listener of this.shoveListeners) {
      try {
        listener.onShoveBegin();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onShoveBegin listener: ${error}`);
      }
    }
  }

  private notifyTilt(pitch: number): void {
    // 通知 Tilt 监听器
    for (const listener of this.tiltListeners) {
      try {
        listener.onTilt(pitch);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onTilt listener: ${error}`);
      }
    }
    // 同时通知 Shove 监听器（向后兼容 Android 命名）
    for (const listener of this.shoveListeners) {
      try {
        listener.onShove(pitch);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onShove listener: ${error}`);
      }
    }
  }

  private notifyTiltEnd(): void {
    // 通知 Tilt 监听器
    for (const listener of this.tiltListeners) {
      try {
        listener.onTiltEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onTiltEnd listener: ${error}`);
      }
    }
    // 同时通知 Shove 监听器（向后兼容 Android 命名）
    for (const listener of this.shoveListeners) {
      try {
        listener.onShoveEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onShoveEnd listener: ${error}`);
      }
    }
  }

  private notifyQuickZoomBegin(): void {
    for (const listener of this.quickZoomListeners) {
      try {
        listener.onQuickZoomBegin();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onQuickZoomBegin listener: ${error}`);
      }
    }
  }

  private notifyQuickZoom(zoom: number): void {
    for (const listener of this.quickZoomListeners) {
      try {
        listener.onQuickZoom(zoom);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onQuickZoom listener: ${error}`);
      }
    }
  }

  private notifyQuickZoomEnd(): void {
    for (const listener of this.quickZoomListeners) {
      try {
        listener.onQuickZoomEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onQuickZoomEnd listener: ${error}`);
      }
    }
  }
}

