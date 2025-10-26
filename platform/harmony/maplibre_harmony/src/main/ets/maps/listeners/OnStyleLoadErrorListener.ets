/**
 * OnStyleLoadErrorListener - 样式加载错误监听器
 * 
 * 当地图样式加载失败时触发
 */
export interface OnStyleLoadErrorListener {
  /**
   * 样式加载失败回调
   * 
   * @param error 错误信息描述
   */
  onStyleLoadError(error: string): void;
}

