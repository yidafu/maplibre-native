import { LatLng } from '../geometry/LatLng';
import { InfoWindowStyle } from './InfoWindow';
import maplibre from 'libmaplibre.so';

// 使用 NAPI 类型
type Icon = maplibre.Icon;
type Marker = maplibre.Marker;

/**
 * MarkerOptions - Marker 构建器类
 * 
 * 使用构建器模式创建 Marker，支持链式调用
 * 构建完成后通过 getMarker() 创建 NAPI Marker 实例
 * 
 * 参考:
 * - Android: org.maplibre.android.annotations.MarkerOptions
 * 
 * @example
 * ```typescript
 * const iconFactory = IconFactory.getInstance();
 * const customIcon = await iconFactory.fromResource($r('app.media.marker'));
 * 
 * // 注意：必须使用 new maplibre.LatLng() 创建位置
 * const marker = new MarkerOptions()
 *   .position(new maplibre.LatLng(39.9042, 116.4074))
 *   .title("北京")
 *   .snippet("中国首都")
 *   .draggable(true)
 *   .icon(customIcon)
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
  private _icon?: Icon;
  private _reuseIdentifier?: string;
  private _draggable: boolean = false;
  private _visible: boolean = true;
  private _alpha: number = 1.0;
  private _rotation: number = 0;
  private _zIndex: number = 0;
  
  // InfoWindow 配置
  private _infoWindowStyle?: InfoWindowStyle;
  private _infoWindowOffsetX: number = 0;
  private _infoWindowOffsetY: number = 0;
  
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
   * @param icon Icon 对象
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public icon(icon: Icon): MarkerOptions {
    this._icon = icon;
    return this;
  }

  /**
   * 设置 Marker 的图标和复用标识符
   * 
   * @param icon Icon 对象
   * @param reuseIdentifier 复用标识符
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public iconWithIdentifier(icon: Icon, reuseIdentifier: string): MarkerOptions {
    this._icon = icon;
    this._reuseIdentifier = reuseIdentifier;
    return this;
  }

  /**
   * 通过复用标识符设置图标
   * 
   * 注意：需要确保 IconManager 中已存在该标识符的图标
   * 
   * @param reuseIdentifier 复用标识符
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public iconFromReusableIdentifier(reuseIdentifier: string): MarkerOptions {
    this._reuseIdentifier = reuseIdentifier;
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
   * 设置 InfoWindow 的样式配置
   * 
   * @param style InfoWindow 样式
   * @returns MarkerOptions 实例（支持链式调用）
   * 
   * @example
   * ```typescript
   * new MarkerOptions()
   *   .position(latLng)
   *   .title('标题')
   *   .infoWindowStyle({
   *     backgroundColor: '#2196F3',
   *     titleFontColor: Color.White,
   *     showCloseButton: true
   *   })
   * ```
   */
  public infoWindowStyle(style: InfoWindowStyle): MarkerOptions {
    this._infoWindowStyle = style;
    // 如果样式中包含偏移量，也设置到偏移量字段
    if (style.offsetX !== undefined) {
      this._infoWindowOffsetX = style.offsetX;
    }
    if (style.offsetY !== undefined) {
      this._infoWindowOffsetY = style.offsetY;
    }
    return this;
  }
  
  /**
   * 设置 InfoWindow 的 X 轴偏移量
   * 
   * @param offsetX X 轴偏移量（像素）
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public infoWindowOffsetX(offsetX: number): MarkerOptions {
    this._infoWindowOffsetX = offsetX;
    return this;
  }
  
  /**
   * 设置 InfoWindow 的 Y 轴偏移量
   * 
   * @param offsetY Y 轴偏移量（像素）
   * @returns MarkerOptions 实例（支持链式调用）
   */
  public infoWindowOffsetY(offsetY: number): MarkerOptions {
    this._infoWindowOffsetY = offsetY;
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
  public getIcon(): Icon | undefined {
    return this._icon;
  }

  /**
   * 获取复用标识符
   */
  public getReuseIdentifier(): string | undefined {
    return this._reuseIdentifier;
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
   * 获取 InfoWindow 样式配置
   */
  public getInfoWindowStyle(): InfoWindowStyle | undefined {
    return this._infoWindowStyle;
  }
  
  /**
   * 获取 InfoWindow X 轴偏移量
   */
  public getInfoWindowOffsetX(): number {
    return this._infoWindowOffsetX;
  }
  
  /**
   * 获取 InfoWindow Y 轴偏移量
   */
  public getInfoWindowOffsetY(): number {
    return this._infoWindowOffsetY;
  }
  
  
  /**
   * 创建 Marker 实例
   * 
   * @returns NAPI Marker 实例
   * @throws Error 如果未设置位置
   */
  public getMarker(): Marker {
    if (this._position === null) {
      throw new Error('Marker position must be set');
    }
    
    // 构建 options 对象
    // 注意：ESObject 用于与 NAPI 层交互的动态对象，这是 HarmonyOS 官方推荐的方式
    const options: ESObject = {
      position: this._position
    };
    
    // 添加可选属性
    if (this._icon !== undefined) {
      // 传递 Icon 的 ID 到 Native 层
      options.icon = this._icon.getId();
    }
    if (this._title !== undefined) {
      options.title = this._title;
    }
    if (this._snippet !== undefined) {
      options.snippet = this._snippet;
    }
    if (this._visible !== true) {
      options.visible = this._visible;
    }
    if (this._alpha !== 1.0) {
      options.alpha = this._alpha;
    }
    if (this._rotation !== 0) {
      options.rotation = this._rotation;
    }
    if (this._draggable !== false) {
      options.draggable = this._draggable;
    }
    if (this._zIndex !== 0) {
      options.zIndex = this._zIndex;
    }
    
    // [MarkerDebug] 记录 Marker 创建信息
    const iconStatus = this._icon ? `"${this._icon.getId()}"` : 'null (⚠️ 可能导致不可见)';
    console.info(`[MarkerDebug] ETS-Create: position={${this._position.latitude}, ${this._position.longitude}}, ` +
                 `icon=${iconStatus}, visible=${this._visible}, alpha=${this._alpha}, ` +
                 `rotation=${this._rotation}, zIndex=${this._zIndex}, draggable=${this._draggable}`);
    
    // 创建 NAPI Marker 实例
    return new maplibre.Marker(options);
  }
}


