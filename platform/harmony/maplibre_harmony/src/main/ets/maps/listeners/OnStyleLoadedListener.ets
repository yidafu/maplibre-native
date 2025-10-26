import { Style } from '../style/Style';

/**
 * OnStyleLoadedListener - 样式加载完成监听器
 * 
 * 当地图样式加载完成后触发，此时可以安全地操作样式相关的资源
 */
export interface OnStyleLoadedListener {
  /**
   * 样式加载完成回调
   * 
   * @param style 已加载的样式对象
   */
  onStyleLoaded(style: Style): void;
}

