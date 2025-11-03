/**
 * PropertyTypes - 图层属性值类型定义
 *
 * 重新导出 NAPI 层的类型定义，并扩展支持 ETS Expression 对象
 * 支持三种形式：常量值、Expression 对象、Expression 字面量
 */

import { Expression, ExpressionLiteral } from '../expressions/Expression';

// 从 libmaplibre.so 导入基础表达式类型
export type {
  ExpressionValue,
  ExpressionLiteral,
  InterpolationType,
  ComparisonExpression,
  LogicalExpression,
  LookupExpression,
  MathExpression,
  ConditionalExpression,
  InterpolationExpression,
  TypeExpression,
  StringExpression,
  ColorExpression,
  FeatureDataExpression,
  ContextExpression,
  VariableExpression
} from 'libmaplibre.so';

/**
 * ColorValue - 颜色值类型
 *
 * 支持三种形式：
 * 1. 颜色字符串常量: "#FF0000", "rgb(255,0,0)", "red"
 * 2. Expression 对象: Expression 类实例
 * 3. Expression 字面量: JSON 数组格式 ["get", "color"]
 */
export type ColorValue = string | Expression | ExpressionLiteral;

/**
 * NumberValue - 数值类型
 *
 * 支持三种形式：
 * 1. 数值常量: 5, 10.5, 0
 * 2. Expression 对象: Expression 类实例
 * 3. Expression 字面量: JSON 数组格式 ["get", "size"]
 */
export type NumberValue = number | Expression | ExpressionLiteral;

/**
 * BooleanValue - 布尔值类型
 *
 * 支持三种形式：
 * 1. 布尔常量: true, false
 * 2. Expression 对象: Expression 类实例
 * 3. Expression 字面量: JSON 数组格式 ["get", "visible"]
 */
export type BooleanValue = boolean | Expression | ExpressionLiteral;

/**
 * StringValue - 字符串值类型
 *
 * 支持三种形式：
 * 1. 字符串常量: "solid", "round", "bevel"
 * 2. Expression 对象: Expression 类实例
 * 3. Expression 字面量: JSON 数组格式 ["get", "lineJoin"]
 */
export type StringValue = string | Expression | ExpressionLiteral;

/**
 * PropertyValue - 通用属性值类型
 *
 * 支持三种形式：
 * 1. T 类型的常量值
 * 2. Expression 对象: Expression 类实例
 * 3. Expression 字面量: JSON 数组格式
 */
export type PropertyValue<T> = T | Expression | ExpressionLiteral;

