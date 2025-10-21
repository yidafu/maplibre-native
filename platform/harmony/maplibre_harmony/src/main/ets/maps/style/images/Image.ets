/**
 * Image - 图片类
 */
export class Image {
  public name: string;
  public width: number;
  public height: number;
  public pixelRatio: number;
  public sdf: boolean;
  public data: Uint8Array | null;

  constructor(options: {
    name: string;
    width: number;
    height: number;
    pixelRatio?: number;
    sdf?: boolean;
    data?: Uint8Array;
  }) {
    this.name = options.name;
    this.width = options.width;
    this.height = options.height;
    this.pixelRatio = options.pixelRatio || 1.0;
    this.sdf = options.sdf || false;
    this.data = options.data || null;
  }

  /**
   * 获取图片名称
   */
  public getName(): string {
    return this.name;
  }

  /**
   * 设置图片名称
   */
  public setName(name: string): void {
    this.name = name;
  }

  /**
   * 获取宽度
   */
  public getWidth(): number {
    return this.width;
  }

  /**
   * 设置宽度
   */
  public setWidth(width: number): void {
    this.width = Math.max(0, width);
  }

  /**
   * 获取高度
   */
  public getHeight(): number {
    return this.height;
  }

  /**
   * 设置高度
   */
  public setHeight(height: number): void {
    this.height = Math.max(0, height);
  }

  /**
   * 获取像素比
   */
  public getPixelRatio(): number {
    return this.pixelRatio;
  }

  /**
   * 设置像素比
   */
  public setPixelRatio(pixelRatio: number): void {
    this.pixelRatio = Math.max(0, pixelRatio);
  }

  /**
   * 是否为SDF图片
   */
  public isSdf(): boolean {
    return this.sdf;
  }

  /**
   * 设置SDF
   */
  public setSdf(sdf: boolean): void {
    this.sdf = sdf;
  }

  /**
   * 获取图片数据
   */
  public getData(): Uint8Array | null {
    return this.data;
  }

  /**
   * 设置图片数据
   */
  public setData(data: Uint8Array | null): void {
    this.data = data;
  }

  /**
   * 获取图片尺寸
   */
  public getSize(): { width: number; height: number } {
    return { width: this.width, height: this.height };
  }

  /**
   * 设置图片尺寸
   */
  public setSize(width: number, height: number): void {
    this.width = Math.max(0, width);
    this.height = Math.max(0, height);
  }

  /**
   * 比较两个图片是否相等
   */
  public equals(other: Image): boolean {
    return this.name === other.name &&
           this.width === other.width &&
           this.height === other.height &&
           this.pixelRatio === other.pixelRatio &&
           this.sdf === other.sdf;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Image(name=${this.name}, size=${this.width}x${this.height}, pixelRatio=${this.pixelRatio})`;
  }
}
