import maplibre from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import { CenterOffset } from './AnnotationView';

import { Marker } from './Marker';

/**
 * AnnotationViewConfig - AnnotationView 配置
 * 
 * 用于定义自定义 AnnotationView 的属性和行为
 */
export interface AnnotationViewConfig {
  // 复用标识符
  reuseIdentifier: string;
  
  // 自定义内容构建器
  contentBuilder?: () => void;
  
  // 是否可拖拽
  draggable?: boolean;
  
  // 是否根据距离缩放
  scalesWithViewingDistance?: boolean;
  
  // 是否跟随地图旋转
  rotatesToMatchCamera?: boolean;
  
  // 中心偏移
  centerOffset?: CenterOffset;
  
  // 初始选中状态
  selected?: boolean;
  
  // 是否启用
  enabled?: boolean;
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
 *   viewForAnnotation: (marker: Marker) => {
 *     if (marker.getIcon() === 'custom-pin') {
 *       return {
 *         reuseIdentifier: 'custom-pin',
 *         contentBuilder: () => { ... },
 *         draggable: true
 *       };
 *     }
 *     return null; // 使用默认图标
 *   },
 *   
 *   didSelectAnnotationView: (marker: Marker) => {
 *     console.log('Marker selected:', marker.getTitle());
 *   }
 * };
 * 
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
   * 此方法会在 Marker 添加到地图或需要重新创建视图时调用
   */
  viewForAnnotation?(marker: Marker): AnnotationViewConfig | null;
  
  /**
   * AnnotationView 被选中时调用
   * 
   * @param marker 被选中的 Marker
   * 
   * 用户点击 AnnotationView 后会触发此方法
   */
  didSelectAnnotationView?(marker: Marker): void;
  
  /**
   * AnnotationView 被取消选中时调用
   * 
   * @param marker 被取消选中的 Marker
   * 
   * 当选中其他 AnnotationView 或点击地图时会触发此方法
   */
  didDeselectAnnotationView?(marker: Marker): void;
  
  /**
   * AnnotationView 即将开始拖拽
   * 
   * @param marker 即将拖拽的 Marker
   * 
   * 用户长按并开始拖拽时触发
   * 可以在此方法中修改 Marker 的外观或执行其他准备操作
   */
  annotationViewWillStartDragging?(marker: Marker): void;
  
  /**
   * AnnotationView 拖拽中
   * 
   * @param marker 正在拖拽的 Marker
   * @param newPosition 新的地理位置
   * 
   * 拖拽过程中频繁触发
   * 可以在此方法中实时更新 Marker 的位置或执行其他操作
   */
  annotationViewDidDrag?(marker: Marker, newPosition: LatLng): void;
  
  /**
   * AnnotationView 拖拽结束
   * 
   * @param marker 拖拽的 Marker
   * @param finalPosition 最终的地理位置
   * 
   * 用户释放手指，拖拽结束时触发
   * 可以在此方法中保存 Marker 的新位置或执行清理操作
   */
  annotationViewDidEndDragging?(marker: Marker, finalPosition: LatLng): void;
}


