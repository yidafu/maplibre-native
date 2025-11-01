/**
 * TransitionOptions - 过渡选项
 * ETS 类实现
 */

/**
 * ITransitionOptions - 过渡选项接口
 * 用于对象字面量
 */
export interface ITransitionOptions {
  duration?: number;
  delay?: number;
}

/**
 * TransitionOptions - 过渡选项类
 * 用于控制图层属性变化的过渡动画
 */
export class TransitionOptions implements ITransitionOptions {
  duration: number;
  delay: number;

  constructor(duration: number = 300, delay: number = 0) {
    this.duration = Math.max(0, duration);
    this.delay = Math.max(0, delay);
  }

  /**
   * 从对象字面量创建 TransitionOptions 实例
   */
  static fromObject(obj: ITransitionOptions): TransitionOptions {
    return new TransitionOptions(obj.duration ?? 300, obj.delay ?? 0);
  }

  /**
   * 转换为对象字面量
   */
  toObject(): ITransitionOptions {
    return {
      duration: this.duration,
      delay: this.delay
    };
  }

  /**
   * 创建过渡选项（静态工厂方法）
   */
  static create(duration: number = 300, delay: number = 0): TransitionOptions {
    return new TransitionOptions(duration, delay);
  }
}

