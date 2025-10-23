/**
 * 地图手势检测器
 * 
 * 统一管理地图的所有手势交互
 * 参考 Android MapGestureDetector 和 iOS MLNMapView 手势处理
 */

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
import maplibre from 'libmaplibre_native.so';

// 类型定义
type NativeMapViewType = maplibre.NativeMapView;

const DOMAIN = 0xFF00;
const TAG = 'MapGestureDetector';

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

  // 缩放相关状态
  private initialZoom: number = 0;
  private currentScale: number = 1.0;
  private lastScale: number = 1.0;
  private previousPinchCenterX: number = 0;
  private previousPinchCenterY: number = 0;

  // 旋转相关状态
  private lastRotation: number = 0;
  private totalRotation: number = 0;
  private previousRotateCenterX: number = 0;
  private previousRotateCenterY: number = 0;
  private currentBearing: number = 0;

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

  constructor(uiSettings: UiSettings) {
    this.uiSettings = uiSettings;
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
    this.lastPanX = 0;
    this.lastPanY = 0;

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

    // 获取增量位移
    const deltaX = event.offsetX - this.lastPanX;
    const deltaY = event.offsetY - this.lastPanY;

    // 更新记录
    this.lastPanX = event.offsetX;
    this.lastPanY = event.offsetY;

    // 记录速度样本（用于惯性动画）
    const now = Date.now();
    this.panVelocityTracker.addSample(event.offsetX, event.offsetY, now);

    // 检查水平滚动限制
    let actualDeltaX = deltaX;
    if (!this.uiSettings.isHorizontalScrollGesturesEnabled()) {
      actualDeltaX = 0;
    }

    // 移动地图（立即移动，不带动画）
    if (this.mapController && (actualDeltaX !== 0 || deltaY !== 0)) {
      this.mapController.moveBy(actualDeltaX, deltaY, 0);
    }

    // 通知监听器
    this.notifyMove(actualDeltaX, deltaY);
  }

  /**
   * 平移手势结束
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

    // 检查是否应该播放惯性动画（Fling）
    if (this.uiSettings.isFlingVelocityAnimationEnabled() && 
        this.panVelocityTracker.hasEnoughData()) {
      
      const velocity = this.panVelocityTracker.getVelocity();
      const speed = this.panVelocityTracker.getSpeed();
      
      hilog.debug(DOMAIN, TAG, `Pan velocity: vx=${velocity.vx.toFixed(2)}, vy=${velocity.vy.toFixed(2)}, speed=${speed.toFixed(2)}`);
      
      // 检查速度是否超过阈值
      if (speed >= this.uiSettings.getMinFlingVelocity()) {
        // 计算动画参数（参考 Android 实现）
        const duration = this.calculateFlingDuration(speed);
        const offsetX = velocity.vx * duration * 0.28 / 1000;  // Android 的经验系数
        const offsetY = velocity.vy * duration * 0.28 / 1000;
        
        hilog.info(DOMAIN, TAG, `Fling animation: offset=(${offsetX.toFixed(2)}, ${offsetY.toFixed(2)}), duration=${duration}ms`);
        
        // 执行惯性动画（使用带动画时长的 moveBy）
        if (this.mapController && this.mapController.moveBy) {
          this.mapController.moveBy(offsetX, offsetY, duration);
        }
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

    hilog.debug(DOMAIN, TAG, 'Pinch gesture started');

    this.isScaling = true;
    this.lastScale = 1.0;
    this.currentScale = 1.0;

    // 重置速度跟踪器
    this.scaleVelocityTracker.reset();

    // 获取当前缩放级别
    if (this.mapController) {
      this.initialZoom = this.mapController.getZoom();
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // 获取焦点并保存（用于下一帧的补偿计算）
    const focalPoint = this.getFocalPoint(event.pinchCenterX, event.pinchCenterY);
    this.previousPinchCenterX = focalPoint.x;
    this.previousPinchCenterY = focalPoint.y;

    // 通知监听器
    this.notifyScaleBegin(focalPoint.x, focalPoint.y);
  }

  /**
   * 缩放手势更新
   * 参考 iOS handlePinchGesture 和 Android onScale 实现
   */
  onPinchUpdate(event: GestureEvent): void {
    if (!this.uiSettings.isZoomGesturesEnabled() || !this.isScaling) {
      return;
    }

    // 获取缩放比例
    this.currentScale = event.scale;
    const scaleFactor = this.currentScale / this.lastScale;

    // 计算新的缩放级别
    const newZoom = this.initialZoom + Math.log2(this.currentScale);

    // 记录速度样本（用于惯性动画）
    const now = Date.now();
    this.scaleVelocityTracker.addSample(this.currentScale, 0, now);

    // 获取当前焦点
    const focalPoint = this.getFocalPoint(event.pinchCenterX, event.pinchCenterY);

    // 应用缩放 - 使用锚点避免抖动
    if (this.mapController) {
      // 🔑 关键修复：使用 setZoom 的锚点参数（参考 iOS 和 Android）
      // setZoom 参数：zoom, cx (锚点X), cy (锚点Y), duration
      if (this.mapController.setZoom) {
        this.mapController.setZoom(newZoom, focalPoint.x, focalPoint.y, 0);
      }

      // 🔑 iOS 关键技巧：补偿焦点移动造成的偏移
      // 当焦点位置变化时，需要 moveBy 来保持地图内容在手指下方不移动
      const deltaX = focalPoint.x - this.previousPinchCenterX;
      const deltaY = focalPoint.y - this.previousPinchCenterY;
      
      if ((Math.abs(deltaX) > 0.5 || Math.abs(deltaY) > 0.5) && this.mapController.moveBy) {
        // 补偿焦点移动
        this.mapController.moveBy(deltaX, deltaY, 0);
      }
    }

    // 通知监听器
    this.notifyScale(scaleFactor, focalPoint.x, focalPoint.y);

    // 保存当前焦点，用于下一帧的补偿计算
    this.previousPinchCenterX = focalPoint.x;
    this.previousPinchCenterY = focalPoint.y;
    this.lastScale = this.currentScale;
  }

  /**
   * 缩放手势结束
   */
  onPinchEnd(event: GestureEvent): void {
    if (!this.isScaling) {
      return;
    }

    hilog.debug(DOMAIN, TAG, `Pinch gesture ended, final scale: ${this.currentScale}`);

    // 获取最终焦点（用于惯性动画）
    const focalPoint = this.getFocalPoint(event.pinchCenterX, event.pinchCenterY);

    // 检查是否应该播放惯性动画
    if (this.uiSettings.isScaleVelocityAnimationEnabled() && 
        this.scaleVelocityTracker.hasEnoughData()) {
      
      const velocity = this.scaleVelocityTracker.getVelocity();
      const scaleVelocity = velocity.vx;  // 只使用 X 分量
      
      hilog.debug(DOMAIN, TAG, `Scale velocity: ${scaleVelocity.toFixed(3)}`);
      
      // 检查速度阈值（参考 iOS: -0.5 < velocity < 3，排除接近零的速度）
      if (Math.abs(scaleVelocity) >= this.uiSettings.getMinScaleVelocity() &&
          Math.abs(scaleVelocity) > 0.1) {
        
        // 计算动画时长（参考 iOS）
        const duration = (scaleVelocity > 0 ? 1 : 0.25) * this.uiSettings.getDecelerationRate() * 1000;
        
        // 计算最终缩放级别
        const finalScale = this.currentScale + scaleVelocity * duration / 1000 * 0.1;
        const finalZoom = this.initialZoom + Math.log2(finalScale);
        
        hilog.info(DOMAIN, TAG, `Scale inertia animation: finalZoom=${finalZoom.toFixed(2)}, duration=${duration.toFixed(0)}ms`);
        
        // 🔑 关键修复：执行缩放动画时也要传递锚点
        if (this.mapController && this.mapController.setZoom) {
          // setZoom 的参数：zoom, cx (锚点X), cy (锚点Y), duration
          this.mapController.setZoom(finalZoom, focalPoint.x, focalPoint.y, duration);
        }
      }
    }

    this.isScaling = false;

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

    hilog.debug(DOMAIN, TAG, 'Rotation gesture started');

    this.isRotating = true;
    this.lastRotation = 0;
    this.totalRotation = 0;

    // 重置速度跟踪器
    this.rotateVelocityTracker.reset();

    // 取消当前动画并获取当前bearing
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
      this.currentBearing = this.mapController.getBearing();
    }

    // 获取焦点并保存
    const focalPoint = this.getFocalPoint(event.pinchCenterX, event.pinchCenterY);
    this.previousRotateCenterX = focalPoint.x;
    this.previousRotateCenterY = focalPoint.y;

    // 通知监听器
    this.notifyRotateBegin(focalPoint.x, focalPoint.y);
  }

  /**
   * 旋转手势更新
   * 参考 iOS handleRotateGesture 和 Android 实现
   */
  onRotateUpdate(event: GestureEvent): void {
    if (!this.uiSettings.isRotateGesturesEnabled() || !this.isRotating) {
      return;
    }

    // 获取旋转角度（弧度转度）
    const currentRotation = event.angle * 180 / Math.PI;
    const rotationDelta = currentRotation - this.lastRotation;
    this.totalRotation += rotationDelta;

    // 计算新的bearing
    this.currentBearing += rotationDelta;

    // 记录速度样本（用于惯性动画）
    const now = Date.now();
    this.rotateVelocityTracker.addSample(currentRotation, 0, now);

    // 获取当前焦点
    const focalPoint = this.getFocalPoint(event.pinchCenterX, event.pinchCenterY);

    // 🔑 关键修复：应用旋转时使用锚点（参考 iOS 和 Android）
    if (this.mapController) {
      if (this.mapController.setBearingXY) {
        // 使用 setBearingXY 方法，传递锚点参数
        this.mapController.setBearingXY(this.currentBearing, focalPoint.x, focalPoint.y, 0);
      }

      // 🔑 iOS 关键技巧：补偿焦点移动造成的偏移
      const deltaX = focalPoint.x - this.previousRotateCenterX;
      const deltaY = focalPoint.y - this.previousRotateCenterY;
      
      if ((Math.abs(deltaX) > 0.5 || Math.abs(deltaY) > 0.5) && this.mapController.moveBy) {
        this.mapController.moveBy(deltaX, deltaY, 0);
      }
    }

    // 通知监听器
    this.notifyRotate(rotationDelta, focalPoint.x, focalPoint.y);

    // 保存当前状态
    this.previousRotateCenterX = focalPoint.x;
    this.previousRotateCenterY = focalPoint.y;
    this.lastRotation = currentRotation;
  }

  /**
   * 旋转手势结束
   */
  onRotateEnd(event: GestureEvent): void {
    if (!this.isRotating) {
      return;
    }

    hilog.debug(DOMAIN, TAG, `Rotation gesture ended, total rotation: ${this.totalRotation}`);

    // 获取最终焦点（用于惯性动画）
    const focalPoint = this.getFocalPoint(event.pinchCenterX, event.pinchCenterY);

    // 检查是否应该播放惯性动画
    if (this.uiSettings.isRotateVelocityAnimationEnabled() && 
        this.rotateVelocityTracker.hasEnoughData()) {
      
      const velocity = this.rotateVelocityTracker.getVelocity();
      const angularVelocity = velocity.vx;  // 度/秒
      
      hilog.debug(DOMAIN, TAG, `Rotate velocity: ${angularVelocity.toFixed(2)} deg/s`);
      
      // 检查速度阈值
      if (Math.abs(angularVelocity) >= this.uiSettings.getMinRotateVelocity()) {
        // 计算动画时长
        const duration = this.uiSettings.getDecelerationRate() * 1000;
        
        // 计算最终角度（减半作为减速效果）
        const deltaBearing = angularVelocity * duration / 1000 * 0.5;
        
        hilog.info(DOMAIN, TAG, `Rotate inertia animation: deltaBearing=${deltaBearing.toFixed(2)}°, duration=${duration.toFixed(0)}ms`);
        
        // 🔑 关键修复：执行旋转动画时也使用锚点
        if (this.mapController) {
          const currentBearing = this.mapController.getBearing();
          const newBearing = (currentBearing + deltaBearing) % 360;
          
          if (this.mapController.setBearingXY) {
            // 使用 setBearingXY 方法传递锚点参数
            this.mapController.setBearingXY(newBearing, focalPoint.x, focalPoint.y, duration);
          }
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
   * 参考 Android 实现：duration = velocityXY / 7 / tiltFactor + baseTime
   * @param speed 速度大小（像素/秒）
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
   * 归一化函数
   * 将值从一个范围映射到另一个范围
   */
  private normalize(value: number, min: number, max: number, newMin: number, newMax: number): number {
    if (max === min) return newMin;  // 避免除以零
    return ((value - min) / (max - min)) * (newMax - newMin) + newMin;
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

