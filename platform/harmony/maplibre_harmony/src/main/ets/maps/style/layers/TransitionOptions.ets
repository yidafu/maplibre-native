/**
 * TransitionOptions - Transition configuration (ETS implementation)
 */

/**
 * ITransitionOptions - Transition options interface
 * Useful for object literals
 */
export interface ITransitionOptions {
  duration?: number;
  delay?: number;
}

/**
 * TransitionOptions - Transition options class
 * Controls the animation used when layer properties change
 */
export class TransitionOptions implements ITransitionOptions {
  duration: number;
  delay: number;

  constructor(duration: number = 300, delay: number = 0) {
    this.duration = Math.max(0, duration);
    this.delay = Math.max(0, delay);
  }

  /**
   * Create TransitionOptions from a literal object
   */
  static fromObject(obj: ITransitionOptions): TransitionOptions {
    return new TransitionOptions(obj.duration ?? 300, obj.delay ?? 0);
  }

  /**
   * Convert to a literal object
   */
  toObject(): ITransitionOptions {
    return {
      duration: this.duration,
      delay: this.delay
    };
  }

  /**
   * Static factory helper
   */
  static create(duration: number = 300, delay: number = 0): TransitionOptions {
    return new TransitionOptions(duration, delay);
  }
}

