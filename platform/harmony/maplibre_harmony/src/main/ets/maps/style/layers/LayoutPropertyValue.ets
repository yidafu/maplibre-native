import { PropertyValue } from './PropertyValue';
import { Expression } from '../expressions/Expression';

/**
 * LayoutPropertyValue - Layout property value wrapper
 *
 * Layout properties influence layer geometry and placement
 */
export class LayoutPropertyValue<T> extends PropertyValue<T> {
  constructor(name: string, value: T | null = null, expression: Expression<T> | null = null) {
    super(name, value, expression);
  }

  /**
   * Create a layout property with a constant value
   */
  public static value<T>(name: string, value: T): LayoutPropertyValue<T> {
    return new LayoutPropertyValue<T>(name, value, null);
  }

  /**
   * Create a layout property backed by an Expression
   */
  public static expression<T>(name: string, expression: Expression<T>): LayoutPropertyValue<T> {
    return new LayoutPropertyValue<T>(name, null, expression);
  }
}

