/**
 * 速度跟踪器
 *
 * 用于计算手势的速度，支持平滑算法以减少抖动
 * 参考 iOS MBGLPanGesture 的速度计算实现
 */

export class VelocitySample {
  x: number = 0;
  y: number = 0;
  time: number = 0;

  constructor(x: number, y: number, time: number) {
    this.x = x;
    this.y = y;
    this.time = time;
  }
}

export class Velocity {
  vx: number = 0;
  vy: number = 0;

  constructor(vx: number, vy: number) {
    this.vx = vx;
    this.vy = vy;
  }
}

/**
 * 速度跟踪器类
 *
 * 使用指数移动平均（EMA）算法平滑速度计算：
 * velocity_new = (delta / time) * 0.9 + velocity_old * 0.1
 */
export class VelocityTracker {
  // 位置样本历史记录
  private samples: VelocitySample[] = [];
  // 最大样本数量（保留最近的N个样本）
  private maxSamples: number = 5;
  // 当前平滑后的速度
  private smoothVelocity: Velocity = new Velocity(0, 0);
  // EMA 平滑因子（新值权重）
  private readonly SMOOTH_FACTOR = 0.9;

  /**
   * 添加一个位置样本
   * @param x X 坐标
   * @param y Y 坐标
   * @param time 时间戳（毫秒）
   */
  addSample(x: number, y: number, time: number): void {
    // 添加新样本
    const sample = new VelocitySample(x, y, time);
    this.samples.push(sample);

    // 限制样本数量
    if (this.samples.length > this.maxSamples) {
      this.samples.shift(); // 移除最旧的样本
    }

    // 如果有足够的样本，计算速度
    if (this.samples.length >= 2) {
      this.calculateVelocity();
    }
  }

  /**
   * 计算当前速度（使用平滑算法）
   */
  private calculateVelocity(): void {
    if (this.samples.length < 2) {
      return;
    }

    // 使用最近的两个样本计算瞬时速度
    const current = this.samples[this.samples.length - 1];
    const previous = this.samples[this.samples.length - 2];

    const deltaTime = current.time - previous.time;

    // 避免除以零
    if (deltaTime <= 0) {
      return;
    }

    // 计算瞬时速度（像素/秒）
    const instantVx = ((current.x - previous.x) / deltaTime) * 1000;
    const instantVy = ((current.y - previous.y) / deltaTime) * 1000;

    // 使用 EMA 平滑速度
    // velocity_new = instantVelocity * 0.9 + velocity_old * 0.1
    this.smoothVelocity.vx = instantVx * this.SMOOTH_FACTOR +
      this.smoothVelocity.vx * (1 - this.SMOOTH_FACTOR);
    this.smoothVelocity.vy = instantVy * this.SMOOTH_FACTOR +
      this.smoothVelocity.vy * (1 - this.SMOOTH_FACTOR);
  }

  /**
   * 获取当前平滑后的速度
   * @returns 速度对象 {vx, vy}，单位：像素/秒
   */
  getVelocity(): Velocity {
    return new Velocity(this.smoothVelocity.vx, this.smoothVelocity.vy);
  }

  /**
   * 获取速度大小（标量）
   * @returns 速度大小，单位：像素/秒
   */
  getSpeed(): number {
    return Math.sqrt(
      this.smoothVelocity.vx * this.smoothVelocity.vx +
        this.smoothVelocity.vy * this.smoothVelocity.vy
    );
  }

  /**
   * 重置跟踪器
   */
  reset(): void {
    this.samples = [];
    this.smoothVelocity = new Velocity(0, 0);
  }

  /**
   * 检查是否有足够的数据来计算速度
   */
  hasEnoughData(): boolean {
    return this.samples.length >= 2;
  }

  /**
   * 获取样本数量
   */
  getSampleCount(): number {
    return this.samples.length;
  }
}


