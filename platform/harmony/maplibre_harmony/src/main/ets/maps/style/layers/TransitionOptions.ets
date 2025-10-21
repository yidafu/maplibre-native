/**
 * TransitionOptions - 过渡选项类
 */
export class TransitionOptions {
  public duration: number;
  public delay: number;

  constructor(options: {
    duration?: number;
    delay?: number;
  } = {}) {
    this.duration = options.duration || 300;
    this.delay = options.delay || 0;
  }

  /**
   * 获取持续时间
   */
  public getDuration(): number {
    return this.duration;
  }

  /**
   * 设置持续时间
   */
  public setDuration(duration: number): void {
    this.duration = Math.max(0, duration);
  }

  /**
   * 获取延迟时间
   */
  public getDelay(): number {
    return this.delay;
  }

  /**
   * 设置延迟时间
   */
  public setDelay(delay: number): void {
    this.delay = Math.max(0, delay);
  }

  /**
   * 比较两个过渡选项是否相等
   */
  public equals(other: TransitionOptions): boolean {
    return this.duration === other.duration && this.delay === other.delay;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `TransitionOptions(duration=${this.duration}, delay=${this.delay})`;
  }
}
