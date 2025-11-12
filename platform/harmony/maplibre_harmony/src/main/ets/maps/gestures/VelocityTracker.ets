/**
 * Velocity tracker.
 *
 * Computes gesture speed with smoothing to reduce jitter.
 * Inspired by the iOS MBGLPanGesture velocity calculation.
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
 * Velocity tracker implementation.
 *
 * Uses an exponential moving average (EMA) to smooth velocity:
 * velocity_new = (delta / time) * 0.9 + velocity_old * 0.1
 */
export class VelocityTracker {
  // History of position samples
  private samples: VelocitySample[] = [];
  // Maximum number of samples (keep most recent entries)
  private maxSamples: number = 5;
  // Current smoothed velocity
  private smoothVelocity: Velocity = new Velocity(0, 0);
  // EMA smoothing factor (weight of new value)
  private readonly SMOOTH_FACTOR = 0.9;

  /**
   * Add a position sample.
   * @param x X coordinate.
   * @param y Y coordinate.
   * @param time Timestamp in milliseconds.
   */
  addSample(x: number, y: number, time: number): void {
    // Add new sample
    const sample = new VelocitySample(x, y, time);
    this.samples.push(sample);

    // Enforce sample limit
    if (this.samples.length > this.maxSamples) {
      this.samples.shift(); // Remove oldest sample
    }

    // Calculate velocity when enough samples exist
    if (this.samples.length >= 2) {
      this.calculateVelocity();
    }
  }

  /**
   * Calculate current velocity using smoothing.
   */
  private calculateVelocity(): void {
    if (this.samples.length < 2) {
      return;
    }

    // Compute instantaneous velocity from latest two samples
    const current = this.samples[this.samples.length - 1];
    const previous = this.samples[this.samples.length - 2];

    const deltaTime = current.time - previous.time;

    // Avoid division by zero
    if (deltaTime <= 0) {
      return;
    }

    // Instantaneous velocity (pixels per second)
    const instantVx = ((current.x - previous.x) / deltaTime) * 1000;
    const instantVy = ((current.y - previous.y) / deltaTime) * 1000;

    // Smooth velocity with EMA
    // velocity_new = instantVelocity * 0.9 + velocity_old * 0.1
    this.smoothVelocity.vx = instantVx * this.SMOOTH_FACTOR +
      this.smoothVelocity.vx * (1 - this.SMOOTH_FACTOR);
    this.smoothVelocity.vy = instantVy * this.SMOOTH_FACTOR +
      this.smoothVelocity.vy * (1 - this.SMOOTH_FACTOR);
  }

  /**
   * Get the smoothed velocity.
   * @returns Velocity {vx, vy} in pixels per second.
   */
  getVelocity(): Velocity {
    return new Velocity(this.smoothVelocity.vx, this.smoothVelocity.vy);
  }

  /**
   * Get scalar speed.
   * @returns Speed in pixels per second.
   */
  getSpeed(): number {
    return Math.sqrt(
      this.smoothVelocity.vx * this.smoothVelocity.vx +
        this.smoothVelocity.vy * this.smoothVelocity.vy
    );
  }

  /**
   * Reset the tracker.
   */
  reset(): void {
    this.samples = [];
    this.smoothVelocity = new Velocity(0, 0);
  }

  /**
   * Determine whether there is enough data to compute velocity.
   */
  hasEnoughData(): boolean {
    return this.samples.length >= 2;
  }

  /**
   * Get current sample count.
   */
  getSampleCount(): number {
    return this.samples.length;
  }
}


