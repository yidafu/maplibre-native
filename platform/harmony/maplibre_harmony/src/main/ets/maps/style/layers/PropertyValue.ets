import { Expression, ExpressionBuilder } from '../expressions/Expression';

/**
 * PropertyValue - 图层属性值封装类
 * 
 * 支持常量值和表达式两种类型的属性值
 */
export class PropertyValue<T> {
  public name: string;
  public value: T | null;
  public expression: ExpressionBuilder<T> | null;

  constructor(name: string, value: T | null = null, expression: ExpressionBuilder<T> | null = null) {
    this.name = name;
    this.value = value;
    this.expression = expression;
  }

  /**
   * 获取属性名称
   */
  public getName(): string {
    return this.name;
  }

  /**
   * 获取属性值
   */
  public getValue(): T | null {
    return this.value;
  }

  /**
   * 是否是常量值
   */
  public isValue(): boolean {
    return this.value !== null && this.expression === null;
  }

  /**
   * 是否是表达式
   */
  public isExpression(): boolean {
    return this.expression !== null;
  }

  /**
   * 获取表达式
   */
  public getExpression(): ExpressionBuilder<T> | null {
    return this.expression;
  }

  /**
   * 转换为JSON对象
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
   * 转换为字符串
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

