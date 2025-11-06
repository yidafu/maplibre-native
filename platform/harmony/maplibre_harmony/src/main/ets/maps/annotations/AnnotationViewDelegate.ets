import maplibre from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import { CenterOffset } from './AnnotationView';

import { Marker } from './Marker';

/**
 * AnnotationView 自定义内容构建器类型
 * 
 * 用于为 AnnotationView 提供自定义的 UI 内容
 * 
 * @param marker 关联的 Marker
 * @returns Builder 函数，用于渲染自定义内容
 * 
 * @example
 * ```typescript
 * const customBuilder: AnnotationViewBuilder = (marker: Marker) => {
 *   return () => {
 *     Column() {
 *       Image($r('app.media.custom_icon'))
 *         .width(40)
 *         .height(40)
 *       Text(marker.getTitle())
 *         .fontSize(12)
 *     }
 *   };
 * };
 * ```
 */
export type AnnotationViewBuilder = (marker: Marker) => (() => void) | null;

/**
 * AnnotationView 尺寸配置
 */
export interface AnnotationViewSize {
  width: number;
  height: number;
}

/**
 * AnnotationViewConfig - AnnotationView 配置
 *
 * 用于定义自定义 AnnotationView 的属性和行为
 * 
 * 参考：
 * - iOS: MLNAnnotationView 的各项属性
 * - Android: Marker 的配置选项
 * 
 * @example
 * ```typescript
 * const config: AnnotationViewConfig = {
 *   reuseIdentifier: 'custom-marker',
 *   contentBuilder: () => {
 *     Column() {
 *       Image($r('app.media.pin')).width(32).height(32)
 *       Text('Label').fontSize(10)
 *     }
 *   },
 *   draggable: true,
 *   scalesWithViewingDistance: true,
 *   centerOffset: { dx: 0, dy: -16 }
 * };
 * ```
 */
export interface AnnotationViewConfig {
  /**
   * 复用标识符
   * 
   * 具有相同标识符的视图可以被复用，提高性能
   * 
   * 参考：iOS MLNAnnotationView.reuseIdentifier
   */
  reuseIdentifier: string;

  /**
   * 自定义内容构建器
   * 
   * 提供自定义的 UI 内容来替代默认图标
   * 如果不提供，将使用 Marker 的 icon 作为显示内容
   * 
   * @example
   * ```typescript
   * contentBuilder: () => {
   *   Stack() {
   *     Image($r('app.media.marker'))
   *       .width(40)
   *       .height(40)
   *   }
   * }
   * ```
   */
  contentBuilder?: () => void;

  /**
   * 是否可拖拽
   * 
   * 设置为 true 后，用户可以长按并拖动 AnnotationView
   * 
   * 参考：iOS MLNAnnotationView.draggable
   * 
   * @default false
   */
  draggable?: boolean;

  /**
   * 是否根据距离缩放
   * 
   * 当地图倾斜时，靠近地平线的视图会自动缩小，
   * 模拟透视效果，使地图更加立体
   * 
   * 参考：iOS MLNAnnotationView.scalesWithViewingDistance
   * 
   * @default false
   */
  scalesWithViewingDistance?: boolean;

  /**
   * 是否跟随地图旋转
   * 
   * 设置为 true 后，AnnotationView 会跟随地图一起旋转
   * 
   * 参考：iOS MLNAnnotationView.rotatesToMatchCamera
   * 
   * @default false
   */
  rotatesToMatchCamera?: boolean;

  /**
   * 中心偏移
   * 
   * 调整视图中心点相对于 Marker 位置的偏移
   * 正值向右/下移动，负值向左/上移动
   * 
   * 参考：iOS MLNAnnotationView.centerOffset
   * 
   * @default { dx: 0, dy: 0 }
   */
  centerOffset?: CenterOffset;

  /**
   * 初始选中状态
   * 
   * 设置视图的初始选中状态
   * 
   * 参考：iOS MLNAnnotationView.selected
   * 
   * @default false
   */
  selected?: boolean;

  /**
   * 是否启用
   * 
   * 禁用后，视图不响应手势事件
   * 
   * 参考：iOS MLNAnnotationView.enabled
   * 
   * @default true
   */
  enabled?: boolean;

  /**
   * 视图大小（可选）
   * 
   * 指定自定义视图的尺寸，如果不指定则由内容自适应
   */
  size?: AnnotationViewSize;

  /**
   * z-index（可选）
   * 
   * 控制视图的显示层级，值越大越在上层
   * 如果不指定，使用 Marker 的 zIndex
   */
  zIndex?: number;

  /**
   * 初始透明度（可选）
   * 
   * 设置视图的初始透明度
   * 
   * @default 1.0
   */
  alpha?: number;
}

/**
 * AnnotationViewDelegate - AnnotationView 委托接口
 *
 * 用于自定义 AnnotationView 的创建和事件处理
 *
 * 参考: iOS MLNMapViewDelegate 的 annotation view 相关方法
 *
 * 使用示例:
 * ```typescript
 * const delegate: AnnotationViewDelegate = {
 *   // 为特定 Marker 创建自定义视图
 *   viewForAnnotation: (marker: Marker) => {
 *     if (marker.getIcon() === 'custom-pin') {
 *       return {
 *         reuseIdentifier: 'custom-pin',
 *         contentBuilder: () => {
 *           Column() {
 *             Image($r('app.media.custom_marker'))
 *               .width(40)
 *               .height(40)
 *             Text(marker.getTitle())
 *               .fontSize(12)
 *               .fontColor(Color.White)
 *           }
 *         },
 *         draggable: true,
 *         scalesWithViewingDistance: true
 *       };
 *     }
 *     return null; // 使用默认图标
 *   },
 *
 *   // 处理选中事件
 *   didSelectAnnotationView: (marker: Marker) => {
 *     console.log('Marker selected:', marker.getTitle());
 *   },
 *
 *   // 处理拖拽事件
 *   annotationViewDidEndDragging: (marker: Marker, position: LatLng) => {
 *     console.log('Marker dragged to:', position);
 *   }
 * };
 *
 * // 设置到地图
 * mapLibreMap.setAnnotationViewDelegate(delegate);
 * ```
 */
export interface AnnotationViewDelegate {
  /**
   * 请求为 Marker 创建 AnnotationView 配置
   *
   * @param marker Marker 实例
   * @returns AnnotationViewConfig 配置对象，返回 null 使用默认图标
   *
   * 参考：iOS `mapView:viewForAnnotation:`
   * 
   * 此方法会在以下时机被调用：
   * - Marker 添加到地图时
   * - Marker 进入屏幕可见区域时（如果启用虚拟化）
   * - 需要从复用池获取视图时
   * 
   * @example
   * ```typescript
   * viewForAnnotation: (marker: Marker) => {
   *   // 根据不同类型返回不同配置
   *   const type = marker.getSnippet();
   *   
   *   if (type === 'restaurant') {
   *     return {
   *       reuseIdentifier: 'restaurant-pin',
   *       contentBuilder: () => {
   *         Image($r('app.media.restaurant_icon'))
   *           .width(32).height(32)
   *       },
   *       centerOffset: { dx: 0, dy: -16 }
   *     };
   *   }
   *   
   *   return null; // 使用默认图标
   * }
   * ```
   */
  viewForAnnotation?(marker: Marker): AnnotationViewConfig | null;

  /**
   * AnnotationView 被选中时调用
   *
   * @param marker 被选中的 Marker
   *
   * 参考：iOS `mapView:didSelectAnnotationView:`
   * 
   * 用户点击 AnnotationView 后会触发此方法
   * 可以在此方法中显示详细信息、修改样式等
   */
  didSelectAnnotationView?(marker: Marker): void;

  /**
   * AnnotationView 被取消选中时调用
   *
   * @param marker 被取消选中的 Marker
   *
   * 参考：iOS `mapView:didDeselectAnnotationView:`
   * 
   * 当选中其他 AnnotationView 或点击地图时会触发此方法
   * 可以在此方法中恢复样式、隐藏信息等
   */
  didDeselectAnnotationView?(marker: Marker): void;

  /**
   * AnnotationView 即将开始拖拽
   *
   * @param marker 即将拖拽的 Marker
   *
   * 参考：iOS `mapView:annotationView:didChangeDragState:` with state starting
   * 
   * 用户长按并开始拖拽时触发
   * 可以在此方法中修改 Marker 的外观或执行其他准备操作
   * 
   * @example
   * ```typescript
   * annotationViewWillStartDragging: (marker: Marker) => {
   *   // 修改透明度表示正在拖拽
   *   marker.setAlpha(0.7);
   * }
   * ```
   */
  annotationViewWillStartDragging?(marker: Marker): void;

  /**
   * AnnotationView 拖拽中
   *
   * @param marker 正在拖拽的 Marker
   * @param newPosition 新的地理位置
   *
   * 参考：iOS `mapView:annotationView:didChangeDragState:` with state dragging
   * 
   * 拖拽过程中频繁触发
   * 可以在此方法中实时更新 UI 或执行其他操作
   * 
   * **注意**：此方法调用频率很高，避免执行耗时操作
   */
  annotationViewDidDrag?(marker: Marker, newPosition: LatLng): void;

  /**
   * AnnotationView 拖拽结束
   *
   * @param marker 拖拽的 Marker
   * @param finalPosition 最终的地理位置
   *
   * 参考：iOS `mapView:annotationView:didChangeDragState:` with state ending
   * 
   * 用户释放手指，拖拽结束时触发
   * 可以在此方法中保存 Marker 的新位置或执行清理操作
   * 
   * @example
   * ```typescript
   * annotationViewDidEndDragging: (marker: Marker, position: LatLng) => {
   *   // 恢复透明度
   *   marker.setAlpha(1.0);
   *   // 保存新位置到服务器
   *   saveMarkerPosition(marker.getId(), position);
   * }
   * ```
   */
  annotationViewDidEndDragging?(marker: Marker, finalPosition: LatLng): void;

  /**
   * 获取复用标识符（可选）
   *
   * @param marker Marker 实例
   * @returns 复用标识符，可以返回 undefined
   * 
   * 如果不提供此方法，将使用 viewForAnnotation 返回的 config.reuseIdentifier
   * 
   * @example
   * ```typescript
   * getReuseIdentifier: (marker: Marker) => {
   *   // 根据 Marker 类型返回不同的标识符
   *   return marker.getSnippet() || 'default';
   * }
   * ```
   */
  getReuseIdentifier?(marker: Marker): string | undefined;
}

