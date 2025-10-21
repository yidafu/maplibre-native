/**
 * OnFpsChangedListener - 帧率变化监听器接口
 */
export interface OnFpsChangedListener {
  onFpsChanged(fps: number): void;
}
