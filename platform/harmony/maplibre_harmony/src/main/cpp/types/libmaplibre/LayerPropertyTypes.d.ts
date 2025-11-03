/**
 * Layer 属性值类型定义
 *
 * 所有 Layer 类型定义共享的属性值类型
 * 支持具体值或 Expression 字面量（JSON 数组格式）
 */

import type { ExpressionLiteral } from './ExpressionTypes';

/**
 * PropertyValue - 属性值类型
 * 支持具体值或 Expression 表达式
 *
 * 在 NAPI 层面，Expression 对象会被序列化为 ExpressionLiteral
 * 所以这里简化为 T | ExpressionLiteral
 * 在 ETS 包装类中，Expression 对象会被自动转换为 ExpressionLiteral
 *
 * @example
* ```typescript
 * // 固定值
 * layer.setFillColor('#FF0000');
 *
 * // Expression 表达式
 * layer.setFillColor(['get', 'color']);
 * ```
 */
export type PropertyValue<T> = T | ExpressionLiteral;

/**
 * ExpressionType - Expression 类型（向后兼容别名）
 * @deprecated 请使用 PropertyValue<T> 替代
 */
export type ExpressionType<T> = PropertyValue<T>;

/**
 * ColorValue - 颜色值类型
 * 支持颜色字符串或 Expression 字面量
 * @deprecated 请使用 PropertyValue<string> 替代
 */
export type ColorValue = PropertyValue<string>;

/**
 * NumberValue - 数值类型
 * 支持数字或 Expression 字面量
 * @deprecated 请使用 PropertyValue<number> 替代
 */
export type NumberValue = PropertyValue<number>;

/**
 * StringValue - 字符串值类型
 * 支持字符串或 Expression 字面量
 * @deprecated 请使用 PropertyValue<string> 替代
 */
export type StringValue = PropertyValue<string>;

/**
 * BooleanValue - 布尔值类型
 * 支持布尔值或 Expression 字面量
 * @deprecated 请使用 PropertyValue<boolean> 替代
 */
export type BooleanValue = PropertyValue<boolean>;

