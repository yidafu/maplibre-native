/**
 * CameraChangeDispatcher - 相机变化事件调度器
 *
 * 管理相机事件监听器并分发事件
 * 参考 Android 的 CameraChangeDispatcher 设计
 * 
 * 🔧 修复：添加消息队列机制，解决相机事件时序问题
 * - 使用延迟处理避免快速连续事件导致的状态混乱
 * - 实现事件去重逻辑，参考 Android Handler 机制
 */

import {
  OnCameraIdleListener,
  OnCameraMoveCanceledListener,
  OnCameraMoveListener,
  OnCameraMoveStartedListener
} from './CameraListener';
import { CameraMoveReason } from './CameraMoveReason';

/**
 * 相机事件类型枚举
 */
enum CameraEventType {
  MOVE_STARTED = 'MOVE_STARTED',
  MOVE = 'MOVE',
  MOVE_CANCELED = 'MOVE_CANCELED',
  IDLE = 'IDLE'
}

export class CameraChangeDispatcher {
  private idleListeners: OnCameraIdleListener[] = [];
  private moveStartedListeners: OnCameraMoveStartedListener[] = [];
  private moveListeners: OnCameraMoveListener[] = [];
  private canceledListeners: OnCameraMoveCanceledListener[] = [];
  
  // 状态追踪
  private isIdle: boolean = true;
  private moveStartedReason: CameraMoveReason = CameraMoveReason.UNKNOWN;
  
  // 消息队列机制（参考 Android Handler）
  private pendingMessages: Map<CameraEventType, number> = new Map();
  private readonly MESSAGE_DELAY = 0; // 使用 0 延迟，允许事件在同一事件循环中合并

  // ========== 添加监听器 ==========

  /**
   * 添加相机空闲监听器
   */
  addOnCameraIdleListener(listener: OnCameraIdleListener): void {
    if (listener && !this.idleListeners.includes(listener)) {
      this.idleListeners.push(listener);
    }
  }

  /**
   * 移除相机空闲监听器
   */
  removeOnCameraIdleListener(listener: OnCameraIdleListener): void {
    const index = this.idleListeners.indexOf(listener);
    if (index !== -1) {
      this.idleListeners.splice(index, 1);
    }
  }

  /**
   * 添加相机开始移动监听器
   */
  addOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    if (listener && !this.moveStartedListeners.includes(listener)) {
      this.moveStartedListeners.push(listener);
    }
  }

  /**
   * 移除相机开始移动监听器
   */
  removeOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    const index = this.moveStartedListeners.indexOf(listener);
    if (index !== -1) {
      this.moveStartedListeners.splice(index, 1);
    }
  }

  /**
   * 添加相机移动中监听器
   */
  addOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (listener && !this.moveListeners.includes(listener)) {
      this.moveListeners.push(listener);
    }
  }

  /**
   * 移除相机移动中监听器
   */
  removeOnCameraMoveListener(listener: OnCameraMoveListener): void {
    const index = this.moveListeners.indexOf(listener);
    if (index !== -1) {
      this.moveListeners.splice(index, 1);
    }
  }

  /**
   * 添加相机移动取消监听器
   */
  addOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (listener && !this.canceledListeners.includes(listener)) {
      this.canceledListeners.push(listener);
    }
  }

  /**
   * 移除相机移动取消监听器
   */
  removeOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    const index = this.canceledListeners.indexOf(listener);
    if (index !== -1) {
      this.canceledListeners.splice(index, 1);
    }
  }

  // ========== 消息队列辅助方法 ==========

  /**
   * 检查是否有待处理的消息
   * @param eventType 事件类型
   * @returns 是否有待处理的消息
   */
  private hasMessage(eventType: CameraEventType): boolean {
    return this.pendingMessages.has(eventType);
  }

  /**
   * 取消待处理的消息
   * @param eventType 事件类型
   */
  private cancelMessage(eventType: CameraEventType): void {
    const timerId = this.pendingMessages.get(eventType);
    if (timerId !== undefined) {
      clearTimeout(timerId);
      this.pendingMessages.delete(eventType);
    }
  }

  /**
   * 调度消息（参考 Android Handler.scheduleMessage）
   * @param eventType 事件类型
   * @param executor 执行函数
   */
  private scheduleMessage(eventType: CameraEventType, executor: () => void): void {
    // 特殊处理：MOVE_STARTED 事件（参考 Android 实现）
    if (eventType === CameraEventType.MOVE_STARTED) {
      // 如果有待处理的 IDLE 或 CANCELED 消息，并且当前不是 idle 状态
      // 说明相机还在移动，不需要触发新的 MOVE_STARTED
      const hasIdleOrCanceled = this.hasMessage(CameraEventType.IDLE) || 
                                this.hasMessage(CameraEventType.MOVE_CANCELED);
      
      // 移除待处理的 IDLE 和 CANCELED 消息
      this.cancelMessage(CameraEventType.IDLE);
      this.cancelMessage(CameraEventType.MOVE_CANCELED);
      
      // 如果当前不是 idle 并且有待处理的结束事件，则跳过此次 MOVE_STARTED
      if (!this.isIdle && hasIdleOrCanceled) {
        console.info('[CameraChangeDispatcher] Skip MOVE_STARTED - camera movement continues');
        return;
      }
    }

    // 对于 MOVE 事件，如果已经有待处理的消息，跳过（避免队列堆积）
    // 参考 Android 实现，MOVE 事件应该被节流处理
    if (eventType === CameraEventType.MOVE) {
      if (this.hasMessage(CameraEventType.MOVE)) {
        return;
      }
    } else {
      // 对于其他事件类型，取消之前的同类消息（避免重复）
      this.cancelMessage(eventType);
    }

    // 调度新消息
    const timerId = setTimeout(() => {
      this.pendingMessages.delete(eventType);
      executor();
    }, this.MESSAGE_DELAY);

    this.pendingMessages.set(eventType, timerId);
  }

  // ========== 事件通知方法（由 NAPI 回调或内部调用）==========

  /**
   * 通知相机开始移动
   * @param reason 移动原因
   */
  notifyCameraMoveStarted(reason: CameraMoveReason): void {
    console.info('[CameraChangeDispatcher] notifyCameraMoveStarted called, isIdle:', this.isIdle);
    this.moveStartedReason = reason;
    
    this.scheduleMessage(CameraEventType.MOVE_STARTED, () => {
      this.executeOnCameraMoveStarted();
    });
  }

  /**
   * 通知相机正在移动
   */
  notifyCameraMove(): void {
    console.info('[CameraChangeDispatcher] notifyCameraMove called, isIdle:', this.isIdle);
    this.scheduleMessage(CameraEventType.MOVE, () => {
      this.executeOnCameraMove();
    });
  }

  /**
   * 通知相机停止移动（空闲）
   */
  notifyCameraIdle(): void {
    this.scheduleMessage(CameraEventType.IDLE, () => {
      this.executeOnCameraIdle();
    });
  }

  /**
   * 通知相机移动取消
   */
  notifyCameraMoveCanceled(): void {
    this.scheduleMessage(CameraEventType.MOVE_CANCELED, () => {
      this.executeOnCameraMoveCanceled();
    });
  }

  // ========== 实际执行方法（私有）==========

  /**
   * 执行相机开始移动回调
   * @private
   */
  private executeOnCameraMoveStarted(): void {
    // 如果已经在移动中，不重复触发
    if (!this.isIdle) {
      return;
    }

    this.isIdle = false;

    // 通知所有监听器
    for (const listener of this.moveStartedListeners) {
      try {
        listener.onCameraMoveStarted(this.moveStartedReason);
      } catch (error) {
        console.error('CameraChangeDispatcher: Error in onCameraMoveStarted listener:', error);
      }
    }
  }

  /**
   * 执行相机移动中回调
   * @private
   */
  private executeOnCameraMove(): void {
    // 只在移动中触发
    if (this.isIdle) {
      console.info('[CameraChangeDispatcher] executeOnCameraMove skipped - isIdle is true');
      return;
    }

    console.info('[CameraChangeDispatcher] executeOnCameraMove - notifying', this.moveListeners.length, 'listeners');
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
   * 执行相机停止移动（空闲）回调
   * @private
   */
  private executeOnCameraIdle(): void {
    // 如果已经 idle，不重复触发
    if (this.isIdle) {
      return;
    }

    this.isIdle = true;

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
   * 执行相机移动取消回调
   * @private
   */
  private executeOnCameraMoveCanceled(): void {
    // 只在移动中触发取消事件
    if (this.isIdle) {
      return;
    }

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
   * 清除所有监听器和待处理消息
   */
  clear(): void {
    // 取消所有待处理的消息
    for (const timerId of this.pendingMessages.values()) {
      clearTimeout(timerId);
    }
    this.pendingMessages.clear();
    
    // 清除监听器
    this.idleListeners = [];
    this.moveStartedListeners = [];
    this.moveListeners = [];
    this.canceledListeners = [];
    this.isIdle = true;
  }

  /**
   * 清除所有监听器（别名方法）
   */
  clearAllListeners(): void {
    this.clear();
  }

  /**
   * 获取当前状态
   */
  isCurrentlyIdle(): boolean {
    return this.isIdle;
  }
}
