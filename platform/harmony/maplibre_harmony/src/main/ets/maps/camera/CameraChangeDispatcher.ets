/**
 * CameraChangeDispatcher - 相机变化事件调度器
 * 
 * 管理相机事件监听器并分发事件
 * 参考 Android 的 CameraChangeDispatcher 设计
 */

import { OnCameraIdleListener, OnCameraMoveStartedListener, 
         OnCameraMoveListener, OnCameraMoveCanceledListener } from './CameraListener';
import { CameraMoveReason } from './CameraMoveReason';

export class CameraChangeDispatcher {
  private idleListeners: OnCameraIdleListener[] = [];
  private moveStartedListeners: OnCameraMoveStartedListener[] = [];
  private moveListeners: OnCameraMoveListener[] = [];
  private canceledListeners: OnCameraMoveCanceledListener[] = [];
  
  // 状态追踪
  private isIdle: boolean = true;
  
  // ========== 添加监听器 ==========
  
  /**
   * 添加相机空闲监听器
   */
  addOnCameraIdleListener(listener: OnCameraIdleListener): void {
    if (listener && !this.idleListeners.includes(listener)) {
      this.idleListeners.push(listener);
      console.log('CameraChangeDispatcher: Added idle listener, total:', this.idleListeners.length);
    }
  }
  
  /**
   * 移除相机空闲监听器
   */
  removeOnCameraIdleListener(listener: OnCameraIdleListener): void {
    const index = this.idleListeners.indexOf(listener);
    if (index !== -1) {
      this.idleListeners.splice(index, 1);
      console.log('CameraChangeDispatcher: Removed idle listener, remaining:', this.idleListeners.length);
    }
  }
  
  /**
   * 添加相机开始移动监听器
   */
  addOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    if (listener && !this.moveStartedListeners.includes(listener)) {
      this.moveStartedListeners.push(listener);
      console.log('CameraChangeDispatcher: Added move started listener, total:', this.moveStartedListeners.length);
    }
  }
  
  /**
   * 移除相机开始移动监听器
   */
  removeOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    const index = this.moveStartedListeners.indexOf(listener);
    if (index !== -1) {
      this.moveStartedListeners.splice(index, 1);
      console.log('CameraChangeDispatcher: Removed move started listener, remaining:', this.moveStartedListeners.length);
    }
  }
  
  /**
   * 添加相机移动中监听器
   */
  addOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (listener && !this.moveListeners.includes(listener)) {
      this.moveListeners.push(listener);
      console.log('CameraChangeDispatcher: Added move listener, total:', this.moveListeners.length);
    }
  }
  
  /**
   * 移除相机移动中监听器
   */
  removeOnCameraMoveListener(listener: OnCameraMoveListener): void {
    const index = this.moveListeners.indexOf(listener);
    if (index !== -1) {
      this.moveListeners.splice(index, 1);
      console.log('CameraChangeDispatcher: Removed move listener, remaining:', this.moveListeners.length);
    }
  }
  
  /**
   * 添加相机移动取消监听器
   */
  addOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (listener && !this.canceledListeners.includes(listener)) {
      this.canceledListeners.push(listener);
      console.log('CameraChangeDispatcher: Added canceled listener, total:', this.canceledListeners.length);
    }
  }
  
  /**
   * 移除相机移动取消监听器
   */
  removeOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    const index = this.canceledListeners.indexOf(listener);
    if (index !== -1) {
      this.canceledListeners.splice(index, 1);
      console.log('CameraChangeDispatcher: Removed canceled listener, remaining:', this.canceledListeners.length);
    }
  }
  
  // ========== 事件通知方法（由 NAPI 回调或内部调用）==========
  
  /**
   * 通知相机开始移动
   * @param reason 移动原因
   */
  notifyCameraMoveStarted(reason: CameraMoveReason): void {
    // 如果已经在移动中，不重复触发
    if (!this.isIdle) {
      console.log('CameraChangeDispatcher: Camera already moving, skipping moveStarted');
      return;
    }
    
    this.isIdle = false;
    console.log('CameraChangeDispatcher: Camera move started, reason:', reason);
    
    // 通知所有监听器
    for (const listener of this.moveStartedListeners) {
      try {
        listener.onCameraMoveStarted(reason);
      } catch (error) {
        console.error('CameraChangeDispatcher: Error in onCameraMoveStarted listener:', error);
      }
    }
  }
  
  /**
   * 通知相机正在移动
   */
  notifyCameraMove(): void {
    // 只在移动中触发
    if (this.isIdle) {
      return;
    }
    
    // 通知所有监听器
    for (const listener of this.moveListeners) {
      try {
        listener.onCameraMove();
      } catch (error) {
        console.error('CameraChangeDispatcher: Error in onCameraMove listener:', error);
      }
    }
  }
  
  /**
   * 通知相机停止移动（空闲）
   */
  notifyCameraIdle(): void {
    // 如果已经 idle，不重复触发
    if (this.isIdle) {
      console.log('CameraChangeDispatcher: Camera already idle, skipping');
      return;
    }
    
    this.isIdle = true;
    console.log('CameraChangeDispatcher: Camera idle');
    
    // 通知所有监听器
    for (const listener of this.idleListeners) {
      try {
        listener.onCameraIdle();
      } catch (error) {
        console.error('CameraChangeDispatcher: Error in onCameraIdle listener:', error);
      }
    }
  }
  
  /**
   * 通知相机移动取消
   */
  notifyCameraMoveCanceled(): void {
    // 只在移动中触发取消事件
    if (this.isIdle) {
      return;
    }
    
    console.log('CameraChangeDispatcher: Camera move canceled');
    
    // 通知所有监听器
    for (const listener of this.canceledListeners) {
      try {
        listener.onCameraMoveCanceled();
      } catch (error) {
        console.error('CameraChangeDispatcher: Error in onCameraMoveCanceled listener:', error);
      }
    }
  }
  
  /**
   * 清除所有监听器
   */
  clear(): void {
    console.log('CameraChangeDispatcher: Clearing all listeners');
    this.idleListeners = [];
    this.moveStartedListeners = [];
    this.moveListeners = [];
    this.canceledListeners = [];
    this.isIdle = true;
  }
  
  /**
   * 获取当前状态
   */
  isCurrentlyIdle(): boolean {
    return this.isIdle;
  }
}

