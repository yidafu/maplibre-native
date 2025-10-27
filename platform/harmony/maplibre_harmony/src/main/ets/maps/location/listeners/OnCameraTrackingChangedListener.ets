/**
 * 相机跟踪状态变更监听器
 */
export interface OnCameraTrackingChangedListener {
  /**
   * 当相机跟踪模式变更时调用
   * @param currentMode 当前相机模式
   */
  onCameraTrackingChanged(currentMode: number): void;

  /**
   * 当用户手势操作导致相机跟踪被取消时调用
   */
  onCameraTrackingDismissed?(): void;
}

