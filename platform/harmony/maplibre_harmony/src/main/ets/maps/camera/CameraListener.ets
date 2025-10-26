/**
 * CameraListener - 相机监听器接口
 * 
 * 监听地图相机的各种状态变化
 */

import { CameraMoveReason } from './CameraMoveReason';

/**
 * 相机空闲监听器
 * 当相机停止移动（所有动画和手势结束）时触发
 */
export interface OnCameraIdleListener {
  /**
   * 相机已停止移动
   */
  onCameraIdle(): void;
}

/**
 * 相机开始移动监听器
 * 当相机开始移动时触发
 */
export interface OnCameraMoveStartedListener {
  /**
   * 相机开始移动
   * @param reason 移动原因
   */
  onCameraMoveStarted(reason: CameraMoveReason): void;
}

/**
 * 相机移动中监听器
 * 在相机移动过程中频繁触发
 */
export interface OnCameraMoveListener {
  /**
   * 相机正在移动
   */
  onCameraMove(): void;
}

/**
 * 相机移动取消监听器
 * 当相机动画被中断或取消时触发
 */
export interface OnCameraMoveCanceledListener {
  /**
   * 相机移动已取消
   */
  onCameraMoveCanceled(): void;
}

/**
 * 动画完成监听器
 * 当 flyTo 或 easeTo 动画完成时触发
 */
export interface OnAnimationFinishedListener {
  /**
   * 动画已完成
   */
  onAnimationFinished(): void;
}

/**
 * 组合相机监听器
 * 包含所有相机事件的监听器
 */
export interface CameraChangeListener {
  /**
   * 相机开始移动
   */
  onCameraMoveStarted?(reason: CameraMoveReason): void;
  
  /**
   * 相机正在移动
   */
  onCameraMove?(): void;
  
  /**
   * 相机停止移动
   */
  onCameraIdle?(): void;
  
  /**
   * 相机移动取消
   */
  onCameraMoveCanceled?(): void;
}

