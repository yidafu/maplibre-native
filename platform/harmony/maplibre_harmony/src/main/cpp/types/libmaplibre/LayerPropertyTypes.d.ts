/**
 * Layer 属性值类型定义
 * 
 * 所有 Layer 类型定义共享的属性值类型
 * 支持具体值或 Expression 字面量（JSON 数组格式）
 */

import type { ExpressionLiteral } from './ExpressionTypes';

/**
 * PropertyValue - 通用属性值类型
 * 支持具体值或 Expression 字面量
 */
export type PropertyValue<T> = T | ExpressionLiteral;

/**
 * ColorValue - 颜色值类型
 * 支持颜色字符串或 Expression 字面量
 */
export type ColorValue = string | ExpressionLiteral;

/**
 * NumberValue - 数值类型
 * 支持数字或 Expression 字面量
 */
export type NumberValue = number | ExpressionLiteral;

/**
 * StringValue - 字符串值类型
 * 支持字符串或 Expression 字面量
 */
export type StringValue = string | ExpressionLiteral;

/**
 * BooleanValue - 布尔值类型
 * 支持布尔值或 Expression 字面量
 */
export type BooleanValue = boolean | ExpressionLiteral;

