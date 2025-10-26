/**
 * Interpolator - 插值器类
 * 
 * 用于 interpolate 表达式的第一个参数
 */

import { Expression } from './Expression';

/**
 * 插值器基类
 */
export class Interpolator extends Expression<any> {
  constructor(operator: string, ...args: Expression[]) {
    super(operator, ...args);
  }

  /**
   * 创建线性插值器
   * 
   * 线性插值在输入和输出之间进行线性过渡
   */
  public static linear(): Interpolator {
    return new Interpolator('linear');
  }

  /**
   * 创建指数插值器（Expression 参数）
   * 
   * 指数插值使用指定的底数进行指数变化
   * 
   * @param base 指数底数（Expression）
   */
  public static exponential(base: Expression<number>): Interpolator {
    return new Interpolator('exponential', base);
  }

  /**
   * 创建指数插值器（数字参数）
   * 
   * @param base 指数底数（数字）
   */
  public static exponential(base: number): Interpolator {
    return Interpolator.exponential(Expression.literal(base));
  }

  /**
   * 创建三次贝塞尔曲线插值器（Expression 参数）
   * 
   * 使用四个控制点定义的三次贝塞尔曲线进行插值
   * 
   * @param x1 第一个控制点 x 坐标
   * @param y1 第一个控制点 y 坐标
   * @param x2 第二个控制点 x 坐标
   * @param y2 第二个控制点 y 坐标
   */
  public static cubicBezier(
    x1: Expression<number>,
    y1: Expression<number>,
    x2: Expression<number>,
    y2: Expression<number>
  ): Interpolator {
    return new Interpolator('cubic-bezier', x1, y1, x2, y2);
  }

  /**
   * 创建三次贝塞尔曲线插值器（数字参数）
   * 
   * @param x1 第一个控制点 x 坐标
   * @param y1 第一个控制点 y 坐标
   * @param x2 第二个控制点 x 坐标
   * @param y2 第二个控制点 y 坐标
   */
  public static cubicBezier(x1: number, y1: number, x2: number, y2: number): Interpolator {
    return Interpolator.cubicBezier(
      Expression.literal(x1),
      Expression.literal(y1),
      Expression.literal(x2),
      Expression.literal(y2)
    );
  }
}

