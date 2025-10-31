import { Icon } from './Icon';

/**
 * Marker - 地图标记点
 * 
 * 表示地图上的一个点标注，可以显示图标、标题和描述信息
 * 
 * 此类由 C++ NAPI 层实现，ETS 层直接使用
 * 
 * 参考:
 * - Android: org.maplibre.android.annotations.Marker
 * - iOS: MLNPointAnnotation
 */
export class Marker {
  /**
   * 构造函数
   * 
   * @param options Marker 选项
   */
  constructor(options: MarkerOptions);
  
  // Getter 方法
  
  /**
   * 获取 Marker 的位置
   * 
   * @returns LatLng 位置对象
   */
  getPosition(): LatLng;
  
  /**
   * 获取 Marker 的图标 ID
   * 
   * @returns 图标 ID 或 null
   */
  getIcon(): string | null;
  
  /**
   * 获取 Marker 的标题
   * 
   * @returns 标题文本
   */
  getTitle(): string;
  
  /**
   * 获取 Marker 的描述信息
   * 
   * @returns 描述文本
   */
  getSnippet(): string;
  
  /**
   * 获取 Marker 的 annotation ID
   * 
   * @returns annotation ID（如果未添加到地图则为 -1）
   */
  getId(): number;
  
  /**
   * 获取 Marker 是否可见
   * 
   * @returns true 表示可见
   */
  getVisible(): boolean;
  
  /**
   * 获取 Marker 的透明度
   * 
   * @returns 透明度值 (0.0 - 1.0)
   */
  getAlpha(): number;
  
  /**
   * 获取 Marker 的旋转角度
   * 
   * @returns 旋转角度（度）
   */
  getRotation(): number;
  
  /**
   * 获取 Marker 是否可拖拽
   * 
   * @returns true 表示可拖拽
   */
  getDraggable(): boolean;
  
  /**
   * 获取 Marker 的 Z 轴顺序
   * 
   * @returns Z 轴顺序值
   */
  getZIndex(): number;
  
  // Setter 方法
  
  /**
   * 设置 Marker 的位置
   * 
   * @param position LatLng 位置对象
   * @returns this（支持链式调用）
   */
  setPosition(position: LatLng): Marker;
  
  /**
   * 设置 Marker 的图标
   * 
   * 支持两种方式：
   * 1. Icon 对象：推荐方式，由 IconFactory 创建的 NAPI Icon 对象（性能更好）
   * 2. 图标 ID 字符串：向后兼容方式，需要先通过 addAnnotationIcon 添加图标资源
   * 
   * @param icon Icon 对象或图标 ID 字符串（null 表示清除图标）
   * @returns this（支持链式调用）
   * 
   * @example
   * ```typescript
   * // 推荐：使用 Icon 对象
   * const factory = IconFactory.getInstance();
   * const icon = await factory.fromResource($r('app.media.marker'));
   * marker.setIcon(icon);
   * 
   * // 向后兼容：使用字符串 ID
   * marker.setIcon('my-icon-id');
   * ```
   */
  setIcon(icon: Icon | string | null): Marker;
  
  /**
   * 设置 Marker 的标题
   * 
   * @param title 标题文本
   * @returns this（支持链式调用）
   */
  setTitle(title: string): Marker;
  
  /**
   * 设置 Marker 的描述信息
   * 
   * @param snippet 描述文本
   * @returns this（支持链式调用）
   */
  setSnippet(snippet: string): Marker;
  
  /**
   * 设置 Marker 是否可见
   * 
   * @param visible true 表示可见
   * @returns this（支持链式调用）
   */
  setVisible(visible: boolean): Marker;
  
  /**
   * 设置 Marker 的透明度
   * 
   * @param alpha 透明度值 (0.0 - 1.0)
   * @returns this（支持链式调用）
   */
  setAlpha(alpha: number): Marker;
  
  /**
   * 设置 Marker 的旋转角度
   * 
   * @param rotation 旋转角度（度）
   * @returns this（支持链式调用）
   */
  setRotation(rotation: number): Marker;
  
  /**
   * 设置 Marker 是否可拖拽
   * 
   * @param draggable true 表示可拖拽
   * @returns this（支持链式调用）
   */
  setDraggable(draggable: boolean): Marker;
  
  /**
   * 设置 Marker 的 Z 轴顺序
   * 
   * @param zIndex Z 轴顺序值
   * @returns this（支持链式调用）
   */
  setZIndex(zIndex: number): Marker;
  
  /**
   * 从地图移除此 Marker
   * 
   * 注意：此方法只标记 Marker 为已移除状态
   * 实际的移除操作需要调用 MapLibreMap.removeMarker()
   */
  remove(): void;
  
  // InfoWindow methods
  
  /**
   * 显示 InfoWindow
   */
  showInfoWindow(): void;
  
  /**
   * 隐藏 InfoWindow
   */
  hideInfoWindow(): void;
  
  /**
   * InfoWindow 是否正在显示
   */
  isInfoWindowShown(): boolean;
  
  // Selection methods
  
  /**
   * Marker 是否被选中
   */
  isSelected(): boolean;
  
  /**
   * 设置 Marker 选中状态
   * @returns this（支持链式调用）
   */
  setSelected(selected: boolean): Marker;
  
  // Drag state methods
  
  /**
   * 获取拖拽状态
   * 0=None, 1=Start, 2=Drag, 3=End
   */
  getDragState(): number;
  
  /**
   * 设置拖拽状态
   * @returns this（支持链式调用）
   */
  setDragState(state: number): Marker;
  
  // Internal methods (used by MarkerManager)
  
  /**
   * 设置 annotation ID（内部使用）
   * @returns this（支持链式调用）
   */
  setId(id: number): Marker;
  
  /**
   * 设置关联的 MapLibreMap（内部使用）
   * @returns this（支持链式调用）
   */
  setMapLibreMap(map: any): Marker;
  
  // Animation methods
  
  /**
   * 动画移动到指定位置
   * 
   * @param targetPosition 目标位置
   * @param duration 动画持续时间（毫秒）
   * @param onComplete 动画完成回调（可选）
   */
  animateToPosition(targetPosition: LatLng, duration: number, onComplete?: () => void): void;
  
  /**
   * 透明度渐变动画
   * 
   * @param targetAlpha 目标透明度 (0.0-1.0)
   * @param duration 动画持续时间（毫秒）
   * @param onComplete 动画完成回调（可选）
   */
  animateAlpha(targetAlpha: number, duration: number, onComplete?: () => void): void;
  
  /**
   * 旋转动画
   * 
   * @param targetRotation 目标旋转角度（度）
   * @param duration 动画持续时间（毫秒）
   * @param onComplete 动画完成回调（可选）
   */
  animateRotation(targetRotation: number, duration: number, onComplete?: () => void): void;
  
  // Anchor methods
  
  /**
   * 获取锚点
   * 
   * @returns 锚点对象 { u: number, v: number }
   */
  getAnchor(): { u: number, v: number };
  
  /**
   * 设置锚点
   * 
   * 锚点决定图标相对于 Marker 位置的对齐方式
   * (0.5, 1.0) 表示底部中心对齐（默认值）
   * (0.0, 0.0) 表示左上角对齐
   * (1.0, 1.0) 表示右下角对齐
   * 
   * @param u 水平锚点（0.0 - 1.0）
   * @param v 垂直锚点（0.0 - 1.0）
   * @returns this（支持链式调用）
   */
  setAnchor(u: number, v: number): Marker;
}

/**
 * MarkerOptions - Marker 构造选项接口
 */
export interface MarkerOptions {
  /**
   * Marker 的地理位置（必需）
   */
  position: LatLng;
  
  /**
   * 图标 ID（可选）
   * 
   * 如果不设置，Marker 将不可见
   * 需要先通过 addAnnotationIcon() 添加图标资源
   */
  icon?: string;
  
  /**
   * 标题（可选）
   */
  title?: string;
  
  /**
   * 描述信息（可选）
   */
  snippet?: string;
  
  /**
   * 是否可见（可选，默认 true）
   */
  visible?: boolean;
  
  /**
   * 透明度（可选，默认 1.0）
   * 范围：0.0（完全透明）- 1.0（完全不透明）
   */
  alpha?: number;
  
  /**
   * 旋转角度（可选，默认 0）
   * 单位：度
   */
  rotation?: number;
  
  /**
   * 是否可拖拽（可选，默认 false）
   */
  draggable?: boolean;
  
  /**
   * Z 轴顺序（可选，默认 0）
   * 值越大，显示越靠前
   */
  zIndex?: number;
  
  /**
   * 锚点（可选，默认 {u: 0.5, v: 1.0}）
   * 决定图标相对于 Marker 位置的对齐方式
   */
  anchor?: { u: number, v: number };
}

/**
 * LatLng - 地理坐标
 */
export interface LatLng {
  /**
   * 纬度
   */
  latitude: number;
  
  /**
   * 经度
   */
  longitude: number;
}

