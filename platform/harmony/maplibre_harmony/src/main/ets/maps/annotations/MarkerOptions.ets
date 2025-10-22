import { LatLng } from '../geometry/LatLng';
import { Marker, IMarkerAnchor } from './Marker';

/**
 * MarkerOptions - Marker 构建器类
 * 
 * 使用构建器模式创建 Marker，支持链式调用
 * 
 * 参考:
 * - Android: org.maplibre.android.annotations.MarkerOptions
 * 
 * @example
 * ```typescript
 * const marker = new MarkerOptions()
 *   .position(new LatLng(39.9042, 116.4074))
 *   .title("北京")
 *   .snippet("中国首都")
 *   .draggable(true)
 *   .icon("custom-marker")
 *   .anchor(0.5, 1.0)
 *   .rotation(45)
 *   .alpha(0.8)
 *   .zIndex(100)
 *   .getMarker();
 * ```
 */
export class MarkerOptions {
  private _position: LatLng | null = null;
  private _title?: string;
  private _snippet?: string;
  private _icon?: string;
  private _anchor?: IMarkerAnchor;
  private _draggable: boolean = false;
  private _visible: boolean = true;
  private _alpha: number = 1.0;
  private _rotation: number = 0;
  private _zIndex: number = 0;
  private _flat: boolean = false;
  
  /**
   * 设置 Marker 的位置
   * 
   * @param position Marker 的地理位置
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public position(position: LatLng): MarkerOptions {
    this._position = position;
    return this;
  }
  
  /**
   * 设置 Marker 的标题
   * 
   * @param title 标题文本
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public title(title: string): MarkerOptions {
    this._title = title;
    return this;
  }
  
  /**
   * 设置 Marker 的描述信息
   * 
   * @param snippet 描述文本
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public snippet(snippet: string): MarkerOptions {
    this._snippet = snippet;
    return this;
  }
  
  /**
   * 设置 Marker 的图标
   * 
   * @param icon 图标 ID
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public icon(icon: string): MarkerOptions {
    this._icon = icon;
    return this;
  }
  
  /**
   * 设置 Marker 的锚点
   * 
   * 锚点决定图标相对于 Marker 位置的对齐方式
   * (0.5, 1.0) 表示底部中心对齐（默认值）
   * 
   * @param x 水平锚点（0.0 - 1.0）
   * @param y 垂直锚点（0.0 - 1.0）
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public anchor(x: number, y: number): MarkerOptions {
    this._anchor = { x, y };
    return this;
  }
  
  /**
   * 设置 Marker 是否可拖拽
   * 
   * @param draggable true 表示可拖拽
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public draggable(draggable: boolean): MarkerOptions {
    this._draggable = draggable;
    return this;
  }
  
  /**
   * 设置 Marker 是否可见
   * 
   * @param visible true 表示可见
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public visible(visible: boolean): MarkerOptions {
    this._visible = visible;
    return this;
  }
  
  /**
   * 设置 Marker 的透明度
   * 
   * @param alpha 透明度（0.0 - 1.0）
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public alpha(alpha: number): MarkerOptions {
    this._alpha = Math.max(0, Math.min(1, alpha));
    return this;
  }
  
  /**
   * 设置 Marker 的旋转角度
   * 
   * @param rotation 旋转角度（度）
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public rotation(rotation: number): MarkerOptions {
    this._rotation = rotation;
    return this;
  }
  
  /**
   * 设置 Marker 的 Z 轴顺序
   * 
   * Z 值越大，Marker 显示越靠前
   * 
   * @param zIndex Z 轴顺序
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public zIndex(zIndex: number): MarkerOptions {
    this._zIndex = zIndex;
    return this;
  }
  
  /**
   * 设置 Marker 是否平贴地面
   * 
   * @param flat true 表示平贴地面
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public flat(flat: boolean): MarkerOptions {
    this._flat = flat;
    return this;
  }
  
  // ========== Getter 方法 ==========
  
  /**
   * 获取位置
   */
  public getPosition(): LatLng | null {
    return this._position;
  }
  
  /**
   * 获取标题
   */
  public getTitle(): string | undefined {
    return this._title;
  }
  
  /**
   * 获取描述
   */
  public getSnippet(): string | undefined {
    return this._snippet;
  }
  
  /**
   * 获取图标
   */
  public getIcon(): string | undefined {
    return this._icon;
  }
  
  /**
   * 获取锚点
   */
  public getAnchor(): IMarkerAnchor | undefined {
    return this._anchor;
  }
  
  /**
   * 是否可拖拽
   */
  public isDraggable(): boolean {
    return this._draggable;
  }
  
  /**
   * 是否可见
   */
  public isVisible(): boolean {
    return this._visible;
  }
  
  /**
   * 获取透明度
   */
  public getAlpha(): number {
    return this._alpha;
  }
  
  /**
   * 获取旋转角度
   */
  public getRotation(): number {
    return this._rotation;
  }
  
  /**
   * 获取 Z 轴顺序
   */
  public getZIndex(): number {
    return this._zIndex;
  }
  
  /**
   * 是否平贴地面
   */
  public isFlat(): boolean {
    return this._flat;
  }
  
  /**
   * 创建 Marker 实例
   * 
   * @returns Marker 实例
   * @throws Error 如果未设置位置
   */
  public getMarker(): Marker {
    if (this._position === null) {
      throw new Error('Marker position must be set');
    }
    
    return new Marker({
      position: this._position,
      title: this._title,
      snippet: this._snippet,
      icon: this._icon,
      anchor: this._anchor,
      draggable: this._draggable,
      visible: this._visible,
      alpha: this._alpha,
      rotation: this._rotation,
      zIndex: this._zIndex,
      flat: this._flat
    });
  }
}

