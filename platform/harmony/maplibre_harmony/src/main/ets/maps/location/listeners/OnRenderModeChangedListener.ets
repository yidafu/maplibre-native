/**
 * 渲染模式变更监听器
 */
export interface OnRenderModeChangedListener {
  /**
   * 当渲染模式变更时调用
   * @param currentMode 当前渲染模式
   */
  onRenderModeChanged(currentMode: number): void;
}

