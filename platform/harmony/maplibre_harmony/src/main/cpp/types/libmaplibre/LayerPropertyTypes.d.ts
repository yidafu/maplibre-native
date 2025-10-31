/**
 * Layer 属性值类型定义
 * 
 * 所有 Layer 类型定义共享的属性值类型
 * 支持具体值或 Expression NAPI 对象
 */

import { ExpressionNAPI } from './Expression';

/**
 * 属性值类型 - 支持具体值或 Expression
 */
export type PropertyValue<T> = T | ExpressionNAPI;

/**
 * 颜色值类型 - 支持颜色字符串或 Expression
 */
export type ColorValue = string | ExpressionNAPI;

/**
 * 数字值类型 - 支持数字或 Expression
 */
export type NumberValue = number | ExpressionNAPI;

/**
 * 字符串值类型 - 支持字符串或 Expression
 */
export type StringValue = string | ExpressionNAPI;

/**
 * 布尔值类型 - 支持布尔值或 Expression
 */
export type BooleanValue = boolean | ExpressionNAPI;

