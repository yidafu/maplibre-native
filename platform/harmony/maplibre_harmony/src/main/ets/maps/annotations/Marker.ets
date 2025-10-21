import { LatLng } from '../geometry/LatLng';

/**
 * Marker - 标记点类
 */
interface IMarkerOptions {
  id?: string;
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

interface IMarkerAnchor {
  x: number;
  y: number;
}

export class Marker {
  public id: string;
  public position: LatLng;
  public title: string;
  public snippet: string;
  public icon: string | null;
  public anchor: IMarkerAnchor;
  public visible: boolean;
  public alpha: number;
  public rotation: number;
  public flat: boolean;
  public draggable: boolean;
  public zIndex: number;

  constructor(options: IMarkerOptions) {
    this.id = options.id || this.generateId();
    this.position = options.position;
    this.title = options.title || '';
    this.snippet = options.snippet || '';
    this.icon = options.icon || null;
    this.anchor = options.anchor || { x: 0.5, y: 1.0 };
    this.visible = options.visible !== undefined ? options.visible : true;
    this.alpha = options.alpha !== undefined ? options.alpha : 1.0;
    this.rotation = options.rotation || 0;
    this.flat = options.flat !== undefined ? options.flat : false;
    this.draggable = options.draggable !== undefined ? options.draggable : false;
    this.zIndex = options.zIndex || 0;
  }

  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return 'marker_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * 设置位置
   */
  public setPosition(position: LatLng): void {
    this.position = position;
  }

  /**
   * 获取位置
   */
  public getPosition(): LatLng {
    return this.position;
  }

  /**
   * 设置标题
   */
  public setTitle(title: string): void {
    this.title = title;
  }

  /**
   * 获取标题
   */
  public getTitle(): string {
    return this.title;
  }

  /**
   * 设置描述
   */
  public setSnippet(snippet: string): void {
    this.snippet = snippet;
  }

  /**
   * 获取描述
   */
  public getSnippet(): string {
    return this.snippet;
  }

  /**
   * 设置图标
   */
  public setIcon(icon: string | null): void {
    this.icon = icon;
  }

  /**
   * 获取图标
   */
  public getIcon(): string | null {
    return this.icon;
  }

  /**
   * 设置锚点
   */
  public setAnchor(anchor: IMarkerAnchor): void {
    this.anchor = anchor;
  }

  /**
   * 获取锚点
   */
  public getAnchor(): IMarkerAnchor {
    return this.anchor;
  }

  /**
   * 设置可见性
   */
  public setVisible(visible: boolean): void {
    this.visible = visible;
  }

  /**
   * 是否可见
   */
  public isVisible(): boolean {
    return this.visible;
  }

  /**
   * 设置透明度
   */
  public setAlpha(alpha: number): void {
    this.alpha = Math.max(0, Math.min(1, alpha));
  }

  /**
   * 获取透明度
   */
  public getAlpha(): number {
    return this.alpha;
  }

  /**
   * 设置旋转角度
   */
  public setRotation(rotation: number): void {
    this.rotation = rotation;
  }

  /**
   * 获取旋转角度
   */
  public getRotation(): number {
    return this.rotation;
  }

  /**
   * 设置是否平贴地面
   */
  public setFlat(flat: boolean): void {
    this.flat = flat;
  }

  /**
   * 是否平贴地面
   */
  public isFlat(): boolean {
    return this.flat;
  }

  /**
   * 设置是否可拖拽
   */
  public setDraggable(draggable: boolean): void {
    this.draggable = draggable;
  }

  /**
   * 是否可拖拽
   */
  public isDraggable(): boolean {
    return this.draggable;
  }

  /**
   * 设置Z轴顺序
   */
  public setZIndex(zIndex: number): void {
    this.zIndex = zIndex;
  }

  /**
   * 获取Z轴顺序
   */
  public getZIndex(): number {
    return this.zIndex;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Marker(id=${this.id}, position=${this.position.toString()}, title=${this.title})`;
  }
}
