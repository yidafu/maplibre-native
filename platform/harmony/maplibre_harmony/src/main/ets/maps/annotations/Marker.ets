import { LatLng } from '../geometry/LatLng';
import { Annotation } from './Annotation';
import { AnnotationType } from './AnnotationType';
import { MarkerDragState } from './MarkerDragState';
import { InfoWindow } from './InfoWindow';
import { MapLibreMap } from '../MapLibreMap';

/**
 * Marker - 标记点类
 * 
 * 表示地图上的一个点标注，可以显示图标、标题和描述信息
 * 
 * 参考:
 * - Android: org.maplibre.android.annotations.Marker
 * - iOS: MLNPointAnnotation + MLNAnnotationView
 */

/**
 * IMarkerOptions - Marker 创建选项接口（用于内部构造）
 * 
 * @deprecated 建议使用 MarkerOptions 类
 */
interface IMarkerOptions {
  position: LatLng;
  title?: string;
  snippet?: string;
  icon?: string;
  anchor?: IMarkerAnchor;
  visible?: boolean;
  alpha?: number;
  rotation?: number;
  flat?: boolean;
  draggable?: boolean;
  zIndex?: number;
}

/**
 * IMarkerAnchor - Marker 锚点接口
 */
export interface IMarkerAnchor {
  x: number;
  y: number;
}

export class Marker extends Annotation {
  // 基础属性
  private _position: LatLng;
  private _title: string;
  private _snippet: string;
  private _icon: string | null;
  private _anchor: IMarkerAnchor;
  private _visible: boolean;
  private _alpha: number;
  private _rotation: number;
  private _flat: boolean;
  private _draggable: boolean;
  private _zIndex: number;
  
  // 状态属性
  private _selected: boolean = false;
  private _dragState: MarkerDragState = MarkerDragState.None;
  
  // InfoWindow 相关
  private _infoWindow: InfoWindow | null = null;
  private _infoWindowShown: boolean = false;

  constructor(options: IMarkerOptions) {
    super();
    this._position = options.position;
    this._title = options.title || '';
    this._snippet = options.snippet || '';
    this._icon = options.icon || null;
    this._anchor = options.anchor || { x: 0.5, y: 1.0 };
    this._visible = options.visible !== undefined ? options.visible : true;
    this._alpha = options.alpha !== undefined ? options.alpha : 1.0;
    this._rotation = options.rotation || 0;
    this._flat = options.flat !== undefined ? options.flat : false;
    this._draggable = options.draggable !== undefined ? options.draggable : false;
    this._zIndex = options.zIndex || 0;
  }
  
  /**
   * 获取标注类型
   */
  public getType(): AnnotationType {
    return AnnotationType.MARKER;
  }

  // ========== 基础属性的 getter/setter ==========
  
  /**
   * 设置位置
   */
  public setPosition(position: LatLng): void {
    this._position = position;
    this.updateMarkerOnMap();
  }

  /**
   * 获取位置
   */
  public getPosition(): LatLng {
    return this._position;
  }

  /**
   * 设置标题
   */
  public setTitle(title: string): void {
    this._title = title;
    this.refreshInfoWindowContent();
  }

  /**
   * 获取标题
   */
  public getTitle(): string {
    return this._title;
  }

  /**
   * 设置描述
   */
  public setSnippet(snippet: string): void {
    this._snippet = snippet;
    this.refreshInfoWindowContent();
  }

  /**
   * 获取描述
   */
  public getSnippet(): string {
    return this._snippet;
  }

  /**
   * 设置图标
   */
  public setIcon(icon: string | null): void {
    this._icon = icon;
    this.updateMarkerOnMap();
  }

  /**
   * 获取图标
   */
  public getIcon(): string | null {
    return this._icon;
  }

  /**
   * 设置锚点
   */
  public setAnchor(anchor: IMarkerAnchor): void {
    this._anchor = anchor;
  }

  /**
   * 获取锚点
   */
  public getAnchor(): IMarkerAnchor {
    return this._anchor;
  }

  /**
   * 设置可见性
   */
  public setVisible(visible: boolean): void {
    this._visible = visible;
  }

  /**
   * 是否可见
   */
  public isVisible(): boolean {
    return this._visible;
  }

  /**
   * 设置透明度
   */
  public setAlpha(alpha: number): void {
    this._alpha = Math.max(0, Math.min(1, alpha));
  }

  /**
   * 获取透明度
   */
  public getAlpha(): number {
    return this._alpha;
  }

  /**
   * 设置旋转角度
   */
  public setRotation(rotation: number): void {
    this._rotation = rotation;
  }

  /**
   * 获取旋转角度
   */
  public getRotation(): number {
    return this._rotation;
  }

  /**
   * 设置是否平贴地面
   */
  public setFlat(flat: boolean): void {
    this._flat = flat;
  }

  /**
   * 是否平贴地面
   */
  public isFlat(): boolean {
    return this._flat;
  }

  /**
   * 设置是否可拖拽
   */
  public setDraggable(draggable: boolean): void {
    this._draggable = draggable;
  }

  /**
   * 是否可拖拽
   */
  public isDraggable(): boolean {
    return this._draggable;
  }

  /**
   * 设置Z轴顺序
   */
  public setZIndex(zIndex: number): void {
    this._zIndex = zIndex;
  }

  /**
   * 获取Z轴顺序
   */
  public getZIndex(): number {
    return this._zIndex;
  }
  
  // ========== 选中状态相关 ==========
  
  /**
   * 设置选中状态
   */
  public setSelected(selected: boolean): void {
    this._selected = selected;
  }
  
  /**
   * 是否被选中
   */
  public isSelected(): boolean {
    return this._selected;
  }
  
  // ========== 拖拽状态相关 ==========
  
  /**
   * 设置拖拽状态
   */
  public setDragState(dragState: MarkerDragState): void {
    this._dragState = dragState;
  }
  
  /**
   * 获取拖拽状态
   */
  public getDragState(): MarkerDragState {
    return this._dragState;
  }
  
  // ========== InfoWindow 相关 ==========
  
  /**
   * 显示 InfoWindow
   */
  public showInfoWindow(): void {
    if (this.mapLibreMap === null) {
      return;
    }
    
    // 获取或创建 InfoWindow
    if (this._infoWindow === null) {
      this._infoWindow = new InfoWindow(this);
    }
    
    // 显示 InfoWindow
    this._infoWindow.show();
    this._infoWindowShown = true;
  }
  
  /**
   * 隐藏 InfoWindow
   */
  public hideInfoWindow(): void {
    if (this._infoWindow !== null) {
      this._infoWindow.close();
    }
    this._infoWindowShown = false;
  }
  
  /**
   * InfoWindow 是否显示
   */
  public isInfoWindowShown(): boolean {
    return this._infoWindowShown;
  }
  
  /**
   * 获取 InfoWindow
   */
  public getInfoWindow(): InfoWindow | null {
    return this._infoWindow;
  }
  
  /**
   * 设置 InfoWindow（内部使用）
   */
  public setInfoWindow(infoWindow: InfoWindow | null): void {
    this._infoWindow = infoWindow;
  }
  
  /**
   * 刷新 InfoWindow 内容
   * 当 title 或 snippet 改变时调用
   */
  private refreshInfoWindowContent(): void {
    if (this._infoWindowShown && this._infoWindow !== null) {
      this._infoWindow.update();
    }
  }
  
  // ========== 动画支持 ==========
  
  /**
   * 平滑移动到目标位置（动画）
   * 
   * 注意：动画功能需要在UI上下文中使用，当前版本仅提供接口
   * 实际动画效果需要在视图层实现
   * 
   * @param targetPosition 目标位置
   * @param duration 动画时长（毫秒）
   * @param callback 动画完成回调
   */
  public animateToPosition(
    targetPosition: LatLng,
    duration: number,
    callback?: () => void
  ): void {
    // 直接设置位置
    // TODO: 在视图层集成时实现真正的动画效果
    this.setPosition(targetPosition);
    
    // 模拟动画延迟
    if (callback) {
      setTimeout(callback, duration);
    }
  }
  
  /**
   * 透明度动画
   * 
   * 注意：动画功能需要在UI上下文中使用
   * 
   * @param targetAlpha 目标透明度
   * @param duration 动画时长（毫秒）
   * @param callback 动画完成回调
   */
  public animateAlpha(
    targetAlpha: number,
    duration: number,
    callback?: () => void
  ): void {
    // 直接设置透明度
    // TODO: 在视图层集成时实现真正的动画效果
    this.setAlpha(targetAlpha);
    
    // 模拟动画延迟
    if (callback) {
      setTimeout(callback, duration);
    }
  }
  
  /**
   * 旋转动画
   * 
   * 注意：动画功能需要在UI上下文中使用
   * 
   * @param targetRotation 目标旋转角度
   * @param duration 动画时长（毫秒）
   * @param callback 动画完成回调
   */
  public animateRotation(
    targetRotation: number,
    duration: number,
    callback?: () => void
  ): void {
    // 直接设置旋转
    // TODO: 在视图层集成时实现真正的动画效果
    this.setRotation(targetRotation);
    
    // 模拟动画延迟
    if (callback) {
      setTimeout(callback, duration);
    }
  }
  
  // ========== 内部辅助方法 ==========
  
  /**
   * 更新地图上的 Marker
   * 当 position 或 icon 改变时调用
   */
  private updateMarkerOnMap(): void {
    const map = this.getMapLibreMap();
    if (map !== null && this.getId() !== -1) {
      map.updateMarker(
        this.getId(),
        this._position.latitude,
        this._position.longitude,
        this._icon || ''
      );
    }
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Marker(id=${this.getId()}, position=${this._position.toString()}, title=${this._title})`;
  }
}
