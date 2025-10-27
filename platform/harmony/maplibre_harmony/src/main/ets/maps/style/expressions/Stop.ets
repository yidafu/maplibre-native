/**
 * Stop - 停靠点类
 * 
 * 用于 interpolate 和 step 表达式中定义输入-输出对
 */

import { Expression } from './Expression';
import { ExpressionValue } from './ExpressionTypes';

/**
 * Stop 类 - 表示一个停靠点
 */
export class Stop {
  private value: Object;
  private output: Object;

  /**
   * 创建一个停靠点
   * 
   * @param value 输入值
   * @param output 输出值
   */
  constructor(value: Object, output: Object) {
    this.value = value;
    this.output = output;
  }

  /**
   * 获取输入值
   */
  public getValue(): Object {
    return this.value;
  }

  /**
   * 获取输出值
   */
  public getOutput(): Object {
    return this.output;
  }

  /**
   * 创建一个停靠点（工厂方法）
   * 
   * @param value 输入值（可以是 Expression 或原始值）
   * @param output 输出值（可以是 Expression 或原始值）
   */
  public static stop(value: Object, output: Object): Stop {
    return new Stop(value, output);
  }

  /**
   * 将 Stop 数组转换为 Expression 数组
   * 
   * Stop 数组格式：[stop(5, 10), stop(10, 20)]
   * 转换为 Expression 数组：[literal(5), literal(10), literal(10), literal(20)]
   * 
   * @param stops Stop 数组
   * @return Expression 数组
   */
  public static toExpressionArray(stops: Stop[]): Expression[] {
    const expressions: Expression[] = [];
    
    for (const stop of stops) {
      const inputValue = stop.value;
      const outputValue = stop.output;

      // 处理输入值
      if (inputValue instanceof Expression) {
        expressions.push(inputValue);
      } else if (Array.isArray(inputValue)) {
        expressions.push(Expression.literal(inputValue as (Object | null)[]));
      } else if (typeof inputValue === 'number') {
        expressions.push(Expression.literal(inputValue));
      } else if (typeof inputValue === 'string') {
        expressions.push(Expression.literal(inputValue));
      } else if (typeof inputValue === 'boolean') {
        expressions.push(Expression.literal(inputValue));
      } else if (inputValue !== null) {
        expressions.push(Expression.literal(inputValue as Object));
      }

      // 处理输出值
      if (outputValue instanceof Expression) {
        expressions.push(outputValue);
      } else if (Array.isArray(outputValue)) {
        expressions.push(Expression.literal(outputValue as (Object | null)[]));
      } else if (typeof outputValue === 'number') {
        expressions.push(Expression.literal(outputValue));
      } else if (typeof outputValue === 'string') {
        expressions.push(Expression.literal(outputValue));
      } else if (typeof outputValue === 'boolean') {
        expressions.push(Expression.literal(outputValue));
      } else if (outputValue !== null) {
        expressions.push(Expression.literal(outputValue as Object));
      }
    }

    return expressions;
  }
}

