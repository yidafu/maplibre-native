import { LatLng } from '../geometry/LatLng';

/**
 * Polyline - 折线类
 */
export class Polyline {
  public id: string;
  public points: LatLng[];
  public color: string;
  public width: number;
  public alpha: number;
  public visible: boolean;
  public zIndex: number;
  public pattern: number[] | null;
  public jointType: string;
  public capType: string;

  constructor(options: {
    id?: string;
    points: LatLng[];
    color?: string;
    width?: number;
    alpha?: number;
    visible?: boolean;
    zIndex?: number;
    pattern?: number[];
    jointType?: string;
    capType?: string;
  }) {
    this.id = options.id || this.generateId();
    this.points = options.points;
    this.color = options.color || '#000000';
    this.width = options.width || 5;
    this.alpha = options.alpha !== undefined ? options.alpha : 1.0;
    this.visible = options.visible !== undefined ? options.visible : true;
    this.zIndex = options.zIndex || 0;
    this.pattern = options.pattern || null;
    this.jointType = options.jointType || 'round';
    this.capType = options.capType || 'round';
  }

  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return 'polyline_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * 设置点列表
   */
  public setPoints(points: LatLng[]): void {
    this.points = points;
  }

  /**
   * 获取点列表
   */
  public getPoints(): LatLng[] {
    return this.points;
  }

  /**
   * 添加点
   */
  public addPoint(point: LatLng): void {
    this.points.push(point);
  }

  /**
   * 插入点
   */
  public insertPoint(index: number, point: LatLng): void {
    this.points.splice(index, 0, point);
  }

  /**
   * 移除点
   */
  public removePoint(index: number): LatLng | null {
    if (index >= 0 && index < this.points.length) {
      return this.points.splice(index, 1)[0];
    }
    return null;
  }

  /**
   * 设置颜色
   */
  public setColor(color: string): void {
    this.color = color;
  }

  /**
   * 获取颜色
   */
  public getColor(): string {
    return this.color;
  }

  /**
   * 设置宽度
   */
  public setWidth(width: number): void {
    this.width = Math.max(0, width);
  }

  /**
   * 获取宽度
   */
  public getWidth(): number {
    return this.width;
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
   * 设置虚线模式
   */
  public setPattern(pattern: number[] | null): void {
    this.pattern = pattern;
  }

  /**
   * 获取虚线模式
   */
  public getPattern(): number[] | null {
    return this.pattern;
  }

  /**
   * 设置连接类型
   */
  public setJointType(jointType: string): void {
    this.jointType = jointType;
  }

  /**
   * 获取连接类型
   */
  public getJointType(): string {
    return this.jointType;
  }

  /**
   * 设置端点类型
   */
  public setCapType(capType: string): void {
    this.capType = capType;
  }

  /**
   * 获取端点类型
   */
  public getCapType(): string {
    return this.capType;
  }

  /**
   * 计算长度（米）
   */
  public getLength(): number {
    if (this.points.length < 2) {
      return 0;
    }

    let length = 0;
    for (let i = 1; i < this.points.length; i++) {
      length += this.points[i - 1].distanceTo(this.points[i]);
    }
    return length;
  }

  /**
   * 计算边界框
   */
  public getBounds(): { north: number; east: number; south: number; west: number } {
    if (this.points.length === 0) {
      return { north: 0, east: 0, south: 0, west: 0 };
    }

    let north = this.points[0].latitude;
    let east = this.points[0].longitude;
    let south = this.points[0].latitude;
    let west = this.points[0].longitude;

    for (const point of this.points) {
      north = Math.max(north, point.latitude);
      east = Math.max(east, point.longitude);
      south = Math.min(south, point.latitude);
      west = Math.min(west, point.longitude);
    }

    return { north, east, south, west };
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Polyline(id=${this.id}, points=${this.points.length}, color=${this.color})`;
  }
}
