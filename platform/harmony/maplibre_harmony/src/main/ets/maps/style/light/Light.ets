/**
 * Light - 光照类
 */
export class Light {
  public anchor: string;
  public position: number[];
  public color: string;
  public intensity: number;

  constructor(options: {
    anchor?: string;
    position?: number[];
    color?: string;
    intensity?: number;
  } = {}) {
    this.anchor = options.anchor || 'viewport';
    this.position = options.position || [1.15, 210, 30];
    this.color = options.color || '#ffffff';
    this.intensity = options.intensity || 0.5;
  }

  /**
   * 获取锚点
   */
  public getAnchor(): string {
    return this.anchor;
  }

  /**
   * 设置锚点
   */
  public setAnchor(anchor: string): void {
    this.anchor = anchor;
  }

  /**
   * 获取位置
   */
  public getPosition(): number[] {
    return this.position;
  }

  /**
   * 设置位置
   */
  public setPosition(position: number[]): void {
    this.position = position;
  }

  /**
   * 获取颜色
   */
  public getColor(): string {
    return this.color;
  }

  /**
   * 设置颜色
   */
  public setColor(color: string): void {
    this.color = color;
  }

  /**
   * 获取强度
   */
  public getIntensity(): number {
    return this.intensity;
  }

  /**
   * 设置强度
   */
  public setIntensity(intensity: number): void {
    this.intensity = Math.max(0, Math.min(1, intensity));
  }

  /**
   * 比较两个光照是否相等
   */
  public equals(other: Light): boolean {
    return this.anchor === other.anchor &&
           this.position.length === other.position.length &&
           this.position.every((val, index) => val === other.position[index]) &&
           this.color === other.color &&
           this.intensity === other.intensity;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Light(anchor=${this.anchor}, position=[${this.position.join(', ')}], color=${this.color}, intensity=${this.intensity})`;
  }
}
