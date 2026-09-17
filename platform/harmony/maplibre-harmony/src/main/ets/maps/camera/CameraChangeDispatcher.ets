import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
/**
 * CameraChangeDispatcher - camera change event dispatcher
 *
 * Manages camera event listeners and distributes events.
 * Mirrors Android's CameraChangeDispatcher design.
 *
 * 🔧 Fix: Add message queue mechanism to resolve camera event ordering issues
 * - Use deferred handling to avoid inconsistent state from rapid consecutive events
 * - Implement event deduplication, inspired by the Android Handler mechanism
 */

import {
  OnCameraIdleListener,
  OnCameraMoveCanceledListener,
  OnCameraMoveListener,
  OnCameraMoveStartedListener
} from './CameraListener';
import { CameraMoveReason } from './CameraMoveReason';

/**
 * Camera event type enumeration
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
  
  // State tracking
  private isIdle: boolean = true;
  private moveStartedReason: CameraMoveReason = CameraMoveReason.UNKNOWN;
  
  // Message queue mechanism (mirrors Android Handler)
  private pendingMessages: Map<CameraEventType, number> = new Map();
  private readonly MESSAGE_DELAY = 0; // Use zero delay to coalesce within the same event loop
  
  // ========== Add listeners ==========

  /**
   * Add camera idle listener
   */
  addOnCameraIdleListener(listener: OnCameraIdleListener): void {
    if (listener && !this.idleListeners.includes(listener)) {
      this.idleListeners.push(listener);
    }
  }

  /**
   * Remove camera idle listener
   */
  removeOnCameraIdleListener(listener: OnCameraIdleListener): void {
    const index = this.idleListeners.indexOf(listener);
    if (index !== -1) {
      this.idleListeners.splice(index, 1);
    }
  }

  /**
   * Add camera move-started listener
   */
  addOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    if (listener && !this.moveStartedListeners.includes(listener)) {
      this.moveStartedListeners.push(listener);
    }
  }

  /**
   * Remove camera move-started listener
   */
  removeOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    const index = this.moveStartedListeners.indexOf(listener);
    if (index !== -1) {
      this.moveStartedListeners.splice(index, 1);
    }
  }

  /**
   * Add camera move listener
   */
  addOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (listener && !this.moveListeners.includes(listener)) {
      this.moveListeners.push(listener);
    }
  }

  /**
   * Remove camera move listener
   */
  removeOnCameraMoveListener(listener: OnCameraMoveListener): void {
    const index = this.moveListeners.indexOf(listener);
    if (index !== -1) {
      this.moveListeners.splice(index, 1);
    }
  }

  /**
   * Add camera move-canceled listener
   */
  addOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (listener && !this.canceledListeners.includes(listener)) {
      this.canceledListeners.push(listener);
    }
  }

  /**
   * Remove camera move-canceled listener
   */
  removeOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    const index = this.canceledListeners.indexOf(listener);
    if (index !== -1) {
      this.canceledListeners.splice(index, 1);
    }
  }

  // ========== Message queue helpers ==========

  /**
   * Determine whether a message is pending
   * @param eventType Event type
   * @returns true if a message is pending
   */
  private hasMessage(eventType: CameraEventType): boolean {
    return this.pendingMessages.has(eventType);
  }

  /**
   * Cancel a pending message
   * @param eventType Event type
   */
  private cancelMessage(eventType: CameraEventType): void {
    const timerId = this.pendingMessages.get(eventType);
    if (timerId !== undefined) {
      clearTimeout(timerId);
      this.pendingMessages.delete(eventType);
    }
  }

  /**
   * Schedule a message (mirrors Android Handler.scheduleMessage)
   * @param eventType Event type
   * @param executor Execution callback
   */
  private scheduleMessage(eventType: CameraEventType, executor: () => void): void {
    // Special handling: MOVE_STARTED events (mirrors Android implementation)
    if (eventType === CameraEventType.MOVE_STARTED) {
      // If there are pending IDLE or CANCELED messages and we're not idle,
      // the camera is still moving—no need to emit another MOVE_STARTED
      const hasIdleOrCanceled = this.hasMessage(CameraEventType.IDLE) || 
                                this.hasMessage(CameraEventType.MOVE_CANCELED);
      
      // Remove pending IDLE and CANCELED messages
      this.cancelMessage(CameraEventType.IDLE);
      this.cancelMessage(CameraEventType.MOVE_CANCELED);
      
      // Skip MOVE_STARTED when not idle and completion events are pending
      if (!this.isIdle && hasIdleOrCanceled) {
        return;
      }
    }

    // Throttle MOVE events: skip if a pending MOVE already exists (avoid queue buildup)
    // Mirrors Android behavior where MOVE events are rate-limited
    if (eventType === CameraEventType.MOVE) {
      if (this.hasMessage(CameraEventType.MOVE)) {
        return;
      }
    } else {
      // For other events, cancel previous of the same type to avoid duplicates
      this.cancelMessage(eventType);
    }

    // Schedule the new message
    const timerId = setTimeout(() => {
      this.pendingMessages.delete(eventType);
      executor();
    }, this.MESSAGE_DELAY);

    this.pendingMessages.set(eventType, timerId);
  }

  // ========== Event notification methods (from NAPI callbacks or internal calls) ==========

  /**
   * Notify that the camera started moving
   * @param reason Movement reason
   */
  notifyCameraMoveStarted(reason: CameraMoveReason): void {
    this.moveStartedReason = reason;
    
    this.scheduleMessage(CameraEventType.MOVE_STARTED, () => {
      this.executeOnCameraMoveStarted();
    });
  }

  /**
   * Notify that the camera is moving
   */
  notifyCameraMove(): void {
    this.scheduleMessage(CameraEventType.MOVE, () => {
      this.executeOnCameraMove();
    });
  }

  /**
   * Notify that the camera became idle
   */
  notifyCameraIdle(): void {
    this.scheduleMessage(CameraEventType.IDLE, () => {
      this.executeOnCameraIdle();
    });
  }

  /**
   * Notify that the camera movement was canceled
   */
  notifyCameraMoveCanceled(): void {
    this.scheduleMessage(CameraEventType.MOVE_CANCELED, () => {
      this.executeOnCameraMoveCanceled();
    });
  }

  // ========== Execution helpers (private) ==========

  /**
   * Execute camera move-started callbacks
   * @private
   */
  private executeOnCameraMoveStarted(): void {
    // Avoid firing when already moving
    if (!this.isIdle) {
      return;
    }

    this.isIdle = false;

    // Notify listeners
    for (const listener of this.moveStartedListeners) {
      try {
        listener.onCameraMoveStarted(this.moveStartedReason);
      } catch (error) {
        hilog.error(DOMAIN, 'CameraChangeDispatcher', 'CameraChangeDispatcher: Error in onCameraMoveStarted listener: %{public}s', error);
      }
    }
  }

  /**
   * Execute camera move callbacks
   * @private
   */
  private executeOnCameraMove(): void {
    // Only fire while moving
    if (this.isIdle) {
      return;
    }

    // Notify listeners
    for (const listener of this.moveListeners) {
      try {
        listener.onCameraMove();
      } catch (error) {
        hilog.error(DOMAIN, 'CameraChangeDispatcher', 'CameraChangeDispatcher: Error in onCameraMove listener: %{public}s', error);
      }
    }
  }

  /**
   * Execute camera idle callbacks
   * @private
   */
  private executeOnCameraIdle(): void {
    // Avoid re-firing if already idle
    if (this.isIdle) {
      return;
    }

    this.isIdle = true;

    // Notify listeners
    for (const listener of this.idleListeners) {
      try {
        listener.onCameraIdle();
      } catch (error) {
        hilog.error(DOMAIN, 'CameraChangeDispatcher', 'CameraChangeDispatcher: Error in onCameraIdle listener: %{public}s', error);
      }
    }
  }

  /**
   * Execute camera move-canceled callbacks
   * @private
   */
  private executeOnCameraMoveCanceled(): void {
    // Only fire cancel event when moving
    if (this.isIdle) {
      return;
    }

    // Notify listeners
    for (const listener of this.canceledListeners) {
      try {
        listener.onCameraMoveCanceled();
      } catch (error) {
        hilog.error(DOMAIN, 'CameraChangeDispatcher', 'CameraChangeDispatcher: Error in onCameraMoveCanceled listener: %{public}s', error);
      }
    }
  }

  /**
   * Clear all listeners and pending messages
   */
  clear(): void {
    // Cancel pending messages
    for (const timerId of this.pendingMessages.values()) {
      clearTimeout(timerId);
    }
    this.pendingMessages.clear();
    
    // Reset listener arrays
    this.idleListeners = [];
    this.moveStartedListeners = [];
    this.moveListeners = [];
    this.canceledListeners = [];
    this.isIdle = true;
  }

  /**
   * Alias for clearing all listeners
   */
  clearAllListeners(): void {
    this.clear();
  }

  /**
   * Get current idle state
   */
  isCurrentlyIdle(): boolean {
    return this.isIdle;
  }
}
