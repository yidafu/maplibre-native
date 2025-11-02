/**
 * LayerUtils - 图层工具函数
 * 
 * 提供所有图层类共用的工具方法
 */

import type { ExpressionLiteral } from 'libmaplibre.so';
import { Expression } from '../expressions/Expression';

/**
 * 转换属性值 - 将 Expression 对象转为数组
 * @param value 属性值（常量、Expression 对象或字面量数组）
 * @returns 转换后的值（常量或数组）
 */
export function convertValue<T>(value: T | Expression | ExpressionLiteral): T | ExpressionLiteral {
  if (value instanceof Expression) {
    return value.toArray() as ExpressionLiteral;
  }
  return value as T | ExpressionLiteral;
}

