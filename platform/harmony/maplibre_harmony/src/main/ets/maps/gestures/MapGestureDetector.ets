/**
 * 地图手势检测器
 * 
 * 统一管理地图的所有手势交互
 * 参考 Android MapGestureDetector 和 iOS MLNMapView 手势处理
 */

import { DOMAIN } from '../../constants/HiLogConstants';
import {
  OnMoveListener,
  OnScaleListener,
  OnRotateListener,
  OnMapClickListener,
  OnMapLongClickListener,
  OnDoubleTapListener,
  OnTiltListener,
  OnQuickZoomListener
} from './GestureListeners';
import { UiSettings, FocalPoint } from '../UiSettings';
import { VelocityTracker } from './VelocityTracker';
import { hilog } from '@kit.PerformanceAnalysisKit';
import display from '@ohos.display';
import maplibre from 'libmaplibre.so';

// 类型定义
type NativeMapViewType = maplibre.NativeMapView;

const TAG = 'MapGestureDetector';
const ZOOM_RATE = 0.65;  // Android MapLibreConstants.ZOOM_RATE - 缩放速率系数
const ROTATION_RATE = 0.1;  // 旋转速率系数 - 调节旋转速度（越小越慢，速度降低50%）

// Android 缩放惯性动画常量（参考 MapLibreConstants.java）
const MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE = 2.5;  // 最大缩放速度变化
const SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER = 150;  // 动画时长乘数（毫秒）
const MIN_SCALE_VELOCITY_THRESHOLD = 0.5;  // 最小速度阈值，低于此值不触发惯性

// Android 旋转惯性动画常量（参考 MapLibreConstants.java）
const MAXIMUM_ANGULAR_VELOCITY = 30;  // 最大角速度（度/秒）
const MIN_ANGULAR_VELOCITY_THRESHOLD = 5;  // 最小角速度阈值（度/秒）

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
  private quickZoomListeners: OnQuickZoomListener[] = [];

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

  // 缩放相关状态
  private currentScale: number = 1.0;
  private lastScale: number = 1.0;
  private initialZoom: number = 0;
  private previousPinchCenterX: number = 0;
  private previousPinchCenterY: number = 0;

  // 旋转相关状态
  private lastRotation: number = 0;
  private totalRotation: number = 0;
  private rotationAnchorX: number = 0;  // 🔑 固定的旋转锚点X（手势开始时确定）
  private rotationAnchorY: number = 0;  // 🔑 固定的旋转锚点Y（手势开始时确定）

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

  // ==================== 手势处理 ====================

  /**
   * 平移手势开始
   */
  onPanStart(event: GestureEvent): void {
    // 检查是否是 Quick Zoom 手势（双击后立即拖动）
    const timeSinceDoubleTap = Date.now() - this.doubleTapTimestamp;
    if (timeSinceDoubleTap < this.QUICK_ZOOM_TIME_THRESHOLD && this.doubleTapTimestamp > 0) {
      // 触发 Quick Zoom
      hilog.debug(DOMAIN, TAG, 'Quick Zoom detected (double tap + drag)');
      this.onQuickZoomStart(event, this.screenHeight || 800); // 使用默认屏幕高度
      return;
    }

    if (!this.uiSettings.isScrollGesturesEnabled()) {
      return;
    }

    hilog.debug(DOMAIN, TAG, 'Pan gesture started');

    this.isMoving = true;
    
    // ✅ 使用实际手指坐标初始化（与 onPanUpdate 保持一致）
    const fingerX = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const fingerY = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;
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
    // 如果正在 Quick Zoom，转发到 Quick Zoom 处理
    if (this.isQuickZooming) {
      this.onQuickZoomUpdate(event);
      return;
    }

    if (!this.uiSettings.isScrollGesturesEnabled() || !this.isMoving) {
      return;
    }

    // ✅ HarmonyOS 关键修复：使用 fingerList[0] 的实际坐标
    // event.offsetX/offsetY 是相对偏移，值太小
    // fingerList[0].localX/localY 是手指在组件中的实际坐标（逻辑像素）
    const fingerX = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const fingerY = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;

    // 计算原始增量（逻辑像素）
    const rawDeltaX = fingerX - this.lastPanX;
    const rawDeltaY = fingerY - this.lastPanY;

    // 应用 pixelRatio 缩放（使用缓存的值，避免每帧查询）
    const pixelRatio = this.getPixelRatio();
    const deltaX = rawDeltaX * pixelRatio;
    const deltaY = rawDeltaY * pixelRatio;

    // 🔍 调试日志：输出原始和缩放后的 delta
    hilog.debug(DOMAIN, TAG, `Pan: raw=(${rawDeltaX.toFixed(2)}, ${rawDeltaY.toFixed(2)}), ` +
                            `scaled=(${deltaX.toFixed(2)}, ${deltaY.toFixed(2)}), ratio=${pixelRatio.toFixed(2)}`);

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
    // 如果正在 Quick Zoom，转发到 Quick Zoom 处理
    if (this.isQuickZooming) {
      this.onQuickZoomEnd(event);
      return;
    }

    if (!this.isMoving) {
      return;
    }

    hilog.debug(DOMAIN, TAG, 'Pan gesture ended');

    // 🔧 关键修复：如果正在缩放或刚刚完成缩放，禁用 Pan 的 Fling 动画
    // 避免缩放时的手指移动被误认为是平移手势，触发不必要的 Fling
    const timeSinceScaleEnd = Date.now() - this.lastScaleEndTimestamp;
    if (this.isScaling || timeSinceScaleEnd < this.SCALE_END_GRACE_PERIOD) {
      hilog.info(DOMAIN, TAG, `Pan Fling ignored - scaling ${this.isScaling ? 'in progress' : `ended ${timeSinceScaleEnd}ms ago`}`);
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
      
      hilog.debug(DOMAIN, TAG, `Pan velocity: vx=${velocity.vx.toFixed(2)}, vy=${velocity.vy.toFixed(2)}, speed=${speed.toFixed(2)}`);
      
      // 检查速度是否超过阈值
      if (speed >= this.uiSettings.getMinFlingVelocity()) {
        // 计算动画时长
        const duration = this.calculateFlingDuration(speed);
        
        // 使用 Android 的 0.28 系数计算偏移量
        // factor 1000: 单位转换（毫秒 → 秒）
        // factor 0.28: 经过用户测试确定的经验值，确保惯性动画起始速度与松手瞬间速度无缝衔接
        const offsetX = velocity.vx * duration * this.FLING_VELOCITY_COEFFICIENT / 1000;
        const offsetY = velocity.vy * duration * this.FLING_VELOCITY_COEFFICIENT / 1000;
        
        hilog.info(DOMAIN, TAG, `Fling animation: offset=(${offsetX.toFixed(2)}, ${offsetY.toFixed(2)}), ` +
                                `duration=${duration.toFixed(0)}ms, coefficient=${this.FLING_VELOCITY_COEFFICIENT}`);
        
        // ✅ 步骤 6：执行惯性动画（与 Android 第 463 行对应）
        // HarmonyOS 手势语义：地图跟随手指方向（正号）
        if (this.mapController && this.mapController.moveBy) {
          this.mapController.moveBy(offsetX, offsetY, duration);
        }
      } else {
        hilog.debug(DOMAIN, TAG, `Fling ignored: speed ${speed.toFixed(2)} < threshold ${this.uiSettings.getMinFlingVelocity()}`);
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
    if (!this.uiSettings.isZoomGesturesEnabled()) {
      return;
    }

    hilog.info(DOMAIN, TAG, '========== Pinch gesture started ==========');

    this.isScaling = true;
    this.lastScale = 1.0;
    this.currentScale = 1.0;
    
    // 🔑 参考 Android: 缩放时禁用旋转手势，避免手势冲突
    this.shouldIgnoreRotation = true;
    hilog.info(DOMAIN, TAG, '🚫 Rotation gestures disabled during scaling');

    // 初始化缩放相关状态
    if (this.mapController && this.mapController.getZoom) {
      this.initialZoom = this.mapController.getZoom();
      hilog.info(DOMAIN, TAG, `Initial zoom: ${this.initialZoom.toFixed(3)}`);
    } else {
      this.initialZoom = 0;
    }
    this.previousPinchCenterX = event.pinchCenterX;
    this.previousPinchCenterY = event.pinchCenterY;

    // 重置速度跟踪器
    this.scaleVelocityTracker.reset();

    // 取消动画并标记手势进行中
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // 获取焦点并通知监听器
    const focalPoint = this.getFocalPoint(event.pinchCenterX, event.pinchCenterY);
    hilog.info(DOMAIN, TAG, `Focal point: (${focalPoint.x.toFixed(1)}, ${focalPoint.y.toFixed(1)}), ` +
                            `Pinch center from event: (${event.pinchCenterX.toFixed(1)}, ${event.pinchCenterY.toFixed(1)})`);
    
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

    hilog.info(DOMAIN, TAG, `[Pinch Update] event.scale=${event.scale.toFixed(4)}, ` +
                            `currentScale=${this.currentScale.toFixed(4)}, ` +
                            `lastScale=${this.lastScale.toFixed(4)}, ` +
                            `scaleFactor=${scaleFactor.toFixed(4)}`);

    // Android 风格的增量式缩放计算
    // 参考: MapGestureDetector.ScaleGestureListener.onScale()
    const zoomBy = (Math.log(scaleFactor) / Math.log(Math.PI / 2)) * ZOOM_RATE * this.uiSettings.getZoomRate();

    hilog.info(DOMAIN, TAG, `[Pinch Update] zoomBy=${zoomBy.toFixed(4)}, ` +
                            `ZOOM_RATE=${ZOOM_RATE}, ` +
                            `uiSettings.zoomRate=${this.uiSettings.getZoomRate()}`);

    // 记录速度样本（用于惯性动画）
    const now = Date.now();
    this.scaleVelocityTracker.addSample(this.currentScale, 0, now);

    // 🔧 修复漂移问题：使用缩放开始时的固定初始焦点，整个缩放过程保持锚点不变
    // 避免因手指移动导致的锚点偏移
    const focalPoint = this.getFocalPoint(this.previousPinchCenterX, this.previousPinchCenterY);
    
    hilog.info(DOMAIN, TAG, `[Pinch Update] FIXED anchor: (${focalPoint.x.toFixed(1)}, ${focalPoint.y.toFixed(1)}), ` +
                            `Current pinch center: (${event.pinchCenterX.toFixed(1)}, ${event.pinchCenterY.toFixed(1)})`);

    // 使用增量式缩放（类似 Android 的 transform.zoomBy）
    if (this.mapController && this.mapController.getZoom && this.mapController.setZoom) {
      const currentZoom = this.mapController.getZoom();
      const newZoom = currentZoom + zoomBy;
      
      // 🔑 DPI 修复：将逻辑像素转换为物理像素
      const pixelRatio = this.getPixelRatio();
      const scaledAnchorX = focalPoint.x * pixelRatio;
      const scaledAnchorY = focalPoint.y * pixelRatio;
      
      hilog.info(DOMAIN, TAG, `[Pinch Update] currentZoom=${currentZoom.toFixed(4)}, ` +
                              `newZoom=${newZoom.toFixed(4)}, ` +
                              `fixedAnchor=(${focalPoint.x.toFixed(1)}, ${focalPoint.y.toFixed(1)}), ` +
                              `pixelRatio=${pixelRatio.toFixed(2)}, ` +
                              `scaledAnchor=(${scaledAnchorX.toFixed(1)}, ${scaledAnchorY.toFixed(1)})`);
      
      this.mapController.setZoom(newZoom, scaledAnchorX, scaledAnchorY, 0);
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
    if (!this.isScaling) {
      return;
    }

    hilog.info(DOMAIN, TAG, `========== Pinch gesture ended, final scale: ${this.currentScale.toFixed(4)} ==========`);

    // 🔧 修复漂移问题：使用缩放开始时的初始焦点，而不是结束时的焦点
    // 避免因手指在缩放过程中移动导致的锚点偏移
    const focalPoint = this.getFocalPoint(this.previousPinchCenterX, this.previousPinchCenterY);

    // 🔧 Android 风格的缩放惯性动画（完整重写）
    // 参考：MapGestureDetector.java onScaleEnd() 方法
    if (this.uiSettings.isScaleVelocityAnimationEnabled() && 
        this.scaleVelocityTracker.hasEnoughData()) {
      
      const velocity = this.scaleVelocityTracker.getVelocity();
      const scaleVelocity = velocity.vx;  // 使用 X 分量表示缩放速度
      
      hilog.info(DOMAIN, TAG, `[Pinch End] Scale velocity: ${scaleVelocity.toFixed(3)}`);
      
      // ✅ Android 风格：检查速度阈值（使用常量而非 UiSettings）
      if (Math.abs(scaleVelocity) < MIN_SCALE_VELOCITY_THRESHOLD) {
        hilog.info(DOMAIN, TAG, `[Pinch End] Velocity too small (${Math.abs(scaleVelocity).toFixed(3)} < ${MIN_SCALE_VELOCITY_THRESHOLD}), skipping inertia`);
      } else {
        // ✅ 判断是放大还是缩小
        const isScalingOut = scaleVelocity < 0;
        const velocityXY = Math.abs(scaleVelocity);
        
        // ✅ 使用 Android 算法计算 zoom 增量（对数缩放）
        const zoomDelta = this.calculateScaleZoomDelta(velocityXY, isScalingOut);
        
        // ✅ 使用 Android 算法计算动画时长（根据缩放量动态调整）
        const duration = this.calculateScaleAnimationDuration(zoomDelta);
        
        hilog.info(DOMAIN, TAG, `[Pinch End] Android-style animation: zoomDelta=${zoomDelta.toFixed(3)}, ` +
                                `duration=${duration.toFixed(0)}ms, isScalingOut=${isScalingOut}`);
        
        // 执行缩放动画
        if (this.mapController && this.mapController.getZoom && this.mapController.setZoom) {
          const currentZoom = this.mapController.getZoom();
          const finalZoom = currentZoom + zoomDelta;
          
          // 🔑 DPI 修复：将逻辑像素转换为物理像素
          const pixelRatio = this.getPixelRatio();
          const scaledAnchorX = focalPoint.x * pixelRatio;
          const scaledAnchorY = focalPoint.y * pixelRatio;
          
          hilog.info(DOMAIN, TAG, `[Pinch End] currentZoom=${currentZoom.toFixed(4)}, ` +
                                  `finalZoom=${finalZoom.toFixed(4)}, ` +
                                  `fixedAnchor=(${focalPoint.x.toFixed(1)}, ${focalPoint.y.toFixed(1)}), ` +
                                  `scaledAnchor=(${scaledAnchorX.toFixed(1)}, ${scaledAnchorY.toFixed(1)})`);
          
          this.mapController.setZoom(finalZoom, scaledAnchorX, scaledAnchorY, duration);
        }
      }
    }

    this.isScaling = false;
    
    // 🔧 记录缩放结束时间戳，用于禁用紧随其后的 Pan Fling
    this.lastScaleEndTimestamp = Date.now();
    
    // 🔑 参考 Android: 缩放结束，重新启用旋转手势
    this.shouldIgnoreRotation = false;
    hilog.info(DOMAIN, TAG, '✅ Rotation gestures re-enabled after scaling');

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
    if (!this.uiSettings.isRotateGesturesEnabled()) {
      return;
    }
    
    // 🔑 参考 Android: 如果正在缩放，忽略旋转手势（避免手势冲突）
    if (this.shouldIgnoreRotation) {
      hilog.info(DOMAIN, TAG, '🚫 Rotation gesture ignored - scaling in progress');
      return;
    }

    hilog.info(DOMAIN, TAG, '========== Rotation gesture started ==========');

    this.isRotating = true;
    this.lastRotation = 0;  // 重置上一帧角度
    this.totalRotation = 0;

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
      
      hilog.info(DOMAIN, TAG, `🔍 Finger positions: finger0=(${finger0X.toFixed(1)}, ${finger0Y.toFixed(1)}), ` +
                              `finger1=(${finger1X.toFixed(1)}, ${finger1Y.toFixed(1)})`);
      hilog.info(DOMAIN, TAG, `🔍 Calculated rotation center: (${centerX.toFixed(1)}, ${centerY.toFixed(1)})`);
    }
    
    const focalPoint = this.getFocalPoint(centerX, centerY);
    
    // 🔑 关键修复：保存固定的旋转锚点（参考 iOS - 整个旋转过程使用同一个锚点）
    this.rotationAnchorX = focalPoint.x;
    this.rotationAnchorY = focalPoint.y;
    
    hilog.info(DOMAIN, TAG, `Rotation anchor FIXED at: (${this.rotationAnchorX.toFixed(1)}, ${this.rotationAnchorY.toFixed(1)})`);
    
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
    
    // 🔑 如果正在缩放，忽略旋转更新
    if (this.shouldIgnoreRotation) {
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
      hilog.debug(DOMAIN, TAG, `[Rotate Update] Skipping frame - rotationDelta too small: ${rotationDelta.toFixed(3)}°`);
      // 仍然更新 lastRotation，避免下一帧计算错误
      this.lastRotation = currentRotation;
      return;
    }
    
    this.totalRotation += rotationDelta;

    hilog.info(DOMAIN, TAG, `[Rotate Update] currentRotation=${currentRotation.toFixed(2)}°, ` +
                            `lastRotation=${this.lastRotation.toFixed(2)}°, ` +
                            `rotationDelta=${rotationDelta.toFixed(2)}°, ` +
                            `totalRotation=${this.totalRotation.toFixed(2)}°`);

    // 记录速度样本（用于惯性动画）
    const now = Date.now();
    this.rotateVelocityTracker.addSample(currentRotation, 0, now);

    // 🔑 关键修复：使用固定的旋转锚点（参考 iOS）
    // 不要每帧重新计算，而是使用手势开始时保存的固定锚点
    const anchorX = this.rotationAnchorX;
    const anchorY = this.rotationAnchorY;

    // 🔑 Android 风格：每帧从地图获取当前 bearing，加上增量
    if (this.mapController && this.mapController.getBearing && this.mapController.setBearingXY) {
      const currentBearing = this.mapController.getBearing();
      
      // 🔑 应用旋转速率系数，控制旋转速度
      const adjustedRotationDelta = rotationDelta * ROTATION_RATE * this.uiSettings.getRotationRate();
      let newBearing = currentBearing + adjustedRotationDelta;
      
      // 🔑 关键修复：归一化 bearing 到 [-180, 180]，避免跨越边界突变
      newBearing = this.normalizeBearing(newBearing);
      
      // 🔑 DPI 修复：鸿蒙手势坐标是逻辑像素，需要乘以 pixelRatio 转换
      const pixelRatio = this.getPixelRatio();
      const scaledAnchorX = anchorX * pixelRatio;
      const scaledAnchorY = anchorY * pixelRatio;
      
      hilog.info(DOMAIN, TAG, `[Rotate Update] currentBearing=${currentBearing.toFixed(2)}°, ` +
                              `rotationDelta=${rotationDelta.toFixed(2)}°, ` +
                              `adjustedDelta=${adjustedRotationDelta.toFixed(2)}° (×${ROTATION_RATE}), ` +
                              `newBearing=${newBearing.toFixed(2)}°, ` +
                              `logicalAnchor=(${anchorX.toFixed(1)}, ${anchorY.toFixed(1)}) [FIXED], ` +
                              `pixelRatio=${pixelRatio.toFixed(2)}, ` +
                              `scaledAnchor=(${scaledAnchorX.toFixed(1)}, ${scaledAnchorY.toFixed(1)})`);
      
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
    if (!this.isRotating) {
      return;
    }

    hilog.info(DOMAIN, TAG, `========== Rotation gesture ended, total rotation: ${this.totalRotation.toFixed(2)}° ==========`);

    // 🔑 关键修复：使用固定的旋转锚点（用于惯性动画）
    const anchorX = this.rotationAnchorX;
    const anchorY = this.rotationAnchorY;

    // 🔧 Android 风格的旋转惯性动画（完整重写）
    // 参考：MapGestureDetector.java onRotateEnd() 方法
    if (this.uiSettings.isRotateVelocityAnimationEnabled() && 
        this.rotateVelocityTracker.hasEnoughData()) {
      
      const velocity = this.rotateVelocityTracker.getVelocity();
      let angularVelocity = velocity.vx;  // 度/秒
      
      hilog.info(DOMAIN, TAG, `[Rotate End] Raw angular velocity: ${angularVelocity.toFixed(2)} deg/s`);
      
      // ✅ Android 风格：限制角速度到 ±30°/s（参考 MAXIMUM_ANGULAR_VELOCITY）
      angularVelocity = this.clampAngularVelocity(angularVelocity);
      
      hilog.info(DOMAIN, TAG, `[Rotate End] Clamped angular velocity: ${angularVelocity.toFixed(2)} deg/s`);
      
      // ✅ 检查速度阈值（使用常量而非 UiSettings）
      if (Math.abs(angularVelocity) < MIN_ANGULAR_VELOCITY_THRESHOLD) {
        hilog.info(DOMAIN, TAG, `[Rotate End] Velocity too small (${Math.abs(angularVelocity).toFixed(2)} < ${MIN_ANGULAR_VELOCITY_THRESHOLD}), skipping inertia`);
      } else {
        // ✅ 使用 Android 算法计算动画时长（对数公式）
        const duration = this.calculateRotateAnimationDuration(angularVelocity);
        
        // ✅ 计算角度增量（iOS 风格：velocity * duration * 0.1）
        const deltaBearing = angularVelocity * duration / 1000 * 0.1;
        
        hilog.info(DOMAIN, TAG, `[Rotate End] Android-style animation: deltaBearing=${deltaBearing.toFixed(2)}°, ` +
                                `duration=${duration.toFixed(0)}ms, angularVelocity=${angularVelocity.toFixed(2)}°/s`);
        
        // 执行旋转动画
        if (this.mapController && this.mapController.getBearing && this.mapController.setBearingXY) {
          const currentBearing = this.mapController.getBearing();
          let newBearing = currentBearing + deltaBearing;
          
          // 归一化 bearing
          newBearing = this.normalizeBearing(newBearing);
          
          // 🔑 DPI 修复：将逻辑像素转换为物理像素
          const pixelRatio = this.getPixelRatio();
          const scaledAnchorX = anchorX * pixelRatio;
          const scaledAnchorY = anchorY * pixelRatio;
          
          hilog.info(DOMAIN, TAG, `[Rotate End] currentBearing=${currentBearing.toFixed(2)}°, ` +
                                  `finalBearing=${newBearing.toFixed(2)}°, ` +
                                  `fixedAnchor=(${anchorX.toFixed(1)}, ${anchorY.toFixed(1)}), ` +
                                  `scaledAnchor=(${scaledAnchorX.toFixed(1)}, ${scaledAnchorY.toFixed(1)})`);
          
          this.mapController.setBearingXY(newBearing, scaledAnchorX, scaledAnchorY, duration);
        }
      }
    }

    this.isRotating = false;

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
    hilog.debug(DOMAIN, TAG, `Single tap at (${event.fingerList[0].localX}, ${event.fingerList[0].localY})`);

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

    hilog.debug(DOMAIN, TAG, `Double tap at (${event.fingerList[0].localX}, ${event.fingerList[0].localY})`);

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
   * 长按手势
   */
  onLongPress(event: GestureEvent): void {
    hilog.debug(DOMAIN, TAG, `Long press at (${event.fingerList[0].localX}, ${event.fingerList[0].localY})`);

    const x = event.fingerList[0].localX;
    const y = event.fingerList[0].localY;

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

    hilog.debug(DOMAIN, TAG, 'Two finger pan (tilt) started');

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

    hilog.debug(DOMAIN, TAG, `Tilt: deltaY=${deltaY.toFixed(2)}, newPitch=${clampedPitch.toFixed(2)}`);

    // 应用倾斜
    if (this.mapController && this.mapController.setPitch) {
      this.mapController.setPitch(clampedPitch, 0);  // 0 表示立即设置，无动画
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

    hilog.debug(DOMAIN, TAG, 'Two finger pan (tilt) ended');

    this.isTilting = false;

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

    hilog.debug(DOMAIN, TAG, 'Quick Zoom started');

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

    hilog.debug(DOMAIN, TAG, `Quick Zoom: deltaY=${deltaY.toFixed(2)}, targetZoom=${targetZoom.toFixed(2)}`);

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

    hilog.debug(DOMAIN, TAG, 'Quick Zoom ended');

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
   * 计算 Fling 动画时长
   * 
   * 参考 Android 实现（MapGestureDetector.java:440）：
   * duration = velocityXY / 7 / tiltFactor + baseTime
   * 
   * @param speed 速度大小（逻辑像素/秒）
   * @returns 动画时长（毫秒）
   */
  private calculateFlingDuration(speed: number): number {
    // 简化版本：暂不考虑 tilt 因素
    const tiltFactor = 1.0;  // TODO: 从地图获取实际 tilt
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
        hilog.info(DOMAIN, TAG, `Initialized pixelRatio: ${pixelRatio.toFixed(2)} (DPI: ${defaultDisplay.densityDPI})`);
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
    if (max === min) return newMin;  // 避免除以零
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
    for (const listener of this.clickListeners) {
      try {
        if (listener.onMapClick(x, y)) {
          break;  // 如果监听器消费了事件，停止传播
        }
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onMapClick listener: ${error}`);
      }
    }
  }

  private notifyMapLongClick(x: number, y: number): void {
    for (const listener of this.longClickListeners) {
      try {
        if (listener.onMapLongClick(x, y)) {
          break;  // 如果监听器消费了事件，停止传播
        }
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onMapLongClick listener: ${error}`);
      }
    }
  }

  private notifyDoubleTap(x: number, y: number): void {
    for (const listener of this.doubleTapListeners) {
      try {
        if (listener.onDoubleTap(x, y)) {
          break;  // 如果监听器消费了事件，停止传播
        }
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onDoubleTap listener: ${error}`);
      }
    }
  }

  private notifyTiltBegin(): void {
    for (const listener of this.tiltListeners) {
      try {
        listener.onTiltBegin();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onTiltBegin listener: ${error}`);
      }
    }
  }

  private notifyTilt(pitch: number): void {
    for (const listener of this.tiltListeners) {
      try {
        listener.onTilt(pitch);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onTilt listener: ${error}`);
      }
    }
  }

  private notifyTiltEnd(): void {
    for (const listener of this.tiltListeners) {
      try {
        listener.onTiltEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onTiltEnd listener: ${error}`);
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

