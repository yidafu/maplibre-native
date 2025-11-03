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
   * @param style 已加载的样式对象（可能为 null，表示使用 NativeMapView 直接操作）
   */
  onStyleLoaded(style: Style | null): void;
}

