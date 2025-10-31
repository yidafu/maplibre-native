import { PropertyValue } from './PropertyValue';
import { Expression, ExpressionBuilder } from '../expressions/Expression';

/**
 * LayoutPropertyValue - Layout 属性值封装类
 * 
 * Layout属性影响图层的布局和几何形状
 */
export class LayoutPropertyValue<T> extends PropertyValue<T> {
  constructor(name: string, value: T | null = null, expression: ExpressionBuilder<T> | null = null) {
    super(name, value, expression);
  }

  /**
   * 创建常量值的Layout属性
   */
  public static value<T>(name: string, value: T): LayoutPropertyValue<T> {
    return new LayoutPropertyValue<T>(name, value, null);
  }

  /**
   * 创建表达式的Layout属性
   */
  public static expression<T>(name: string, expression: ExpressionBuilder<T>): LayoutPropertyValue<T> {
    return new LayoutPropertyValue<T>(name, null, expression);
  }
}

