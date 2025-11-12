import { PropertyValue } from './PropertyValue';
import { Expression } from '../expressions/Expression';

/**
 * PaintPropertyValue - Paint property value wrapper
 *
 * Paint properties affect visual appearance (color, opacity, etc.)
 */
export class PaintPropertyValue<T> extends PropertyValue<T> {
  constructor(name: string, value: T | null = null, expression: Expression<T> | null = null) {
    super(name, value, expression);
  }

  /**
   * Create a paint property with a constant value
   */
  public static value<T>(name: string, value: T): PaintPropertyValue<T> {
    return new PaintPropertyValue<T>(name, value, null);
  }

  /**
   * Create a paint property backed by an Expression
   */
  public static expression<T>(name: string, expression: Expression<T>): PaintPropertyValue<T> {
    return new PaintPropertyValue<T>(name, null, expression);
  }
}

