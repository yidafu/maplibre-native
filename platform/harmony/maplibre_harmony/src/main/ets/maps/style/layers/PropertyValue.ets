import { Expression } from '../expressions/Expression';

/**
 * PropertyValue - Layer property value wrapper
 *
 * Supports constant values or Expression-backed values
 */
export class PropertyValue<T> {
  public name: string;
  public value: T | null;
  public expression: Expression<T> | null;

  constructor(name: string, value: T | null = null, expression: Expression<T> | null = null) {
    this.name = name;
    this.value = value;
    this.expression = expression;
  }

  /**
   * Get the property name
   */
  public getName(): string {
    return this.name;
  }

  /**
   * Retrieve the property value
   */
  public getValue(): T | null {
    return this.value;
  }

  /**
   * Determine whether the property represents a constant value
   */
  public isValue(): boolean {
    return this.value !== null && this.expression === null;
  }

  /**
   * Determine whether the property is expression-backed
   */
  public isExpression(): boolean {
    return this.expression !== null;
  }

  /**
   * Retrieve the backing expression
   */
  public getExpression(): Expression<T> | null {
    return this.expression;
  }

  /**
   * Serialize to a JSON-compatible object
   */
  public toJSON(): Record<string, Object> {
    const obj: Record<string, Object> = {};
    obj['name'] = this.name;
    if (this.isValue()) {
      obj['value'] = this.value as Object;
    } else if (this.isExpression() && this.expression !== null) {
      obj['expression'] = this.expression.toArray();
    }
    return obj;
  }

  /**
   * Convert to string representation
   */
  public toString(): string {
    if (this.isValue()) {
      return `PropertyValue(${this.name}=${this.value})`;
    } else if (this.isExpression()) {
      return `PropertyValue(${this.name}=[expression])`;
    }
    return `PropertyValue(${this.name}=null)`;
  }
}
