import { PropertyValue } from './PropertyValue';
import { Expression } from '../expressions/Expression';

/**
 * PaintPropertyValue - Paint 属性值封装类
 *
 * Paint属性影响图层的渲染外观（如颜色、透明度等）
 */
export class PaintPropertyValue<T> extends PropertyValue<T> {
  constructor(name: string, value: T | null = null, expression: Expression<T> | null = null) {
    super(name, value, expression);
  }

  /**
   * 创建常量值的Paint属性
   */
  public static value<T>(name: string, value: T): PaintPropertyValue<T> {
    return new PaintPropertyValue<T>(name, value, null);
  }

  /**
   * 创建表达式的Paint属性
   */
  public static expression<T>(name: string, expression: Expression<T>): PaintPropertyValue<T> {
    return new PaintPropertyValue<T>(name, null, expression);
  }
}

