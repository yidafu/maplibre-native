/**
 * PropertyTypes - 图层属性值类型定义
 * 
 * 这些类型定义与 NAPI 层的 LayerPropertyTypes.d.ts 保持一致
 * 支持常量值和 Expression 表达式
 * 
 * 注意：ExpressionNAPI 在 NAPI 层定义为接口，在 ArkTS 层使用 Object 来表示
 */

/**
 * ColorValue - 颜色值类型
 * 
 * 支持：
 * - 十六进制颜色字符串: "#FF0000", "#F00", "#FF0000FF"
 * - RGB/RGBA字符串: "rgb(255, 0, 0)", "rgba(255, 0, 0, 1.0)"
 * - HSL/HSLA字符串: "hsl(0, 100%, 50%)", "hsla(0, 100%, 50%, 1.0)"
 * - 颜色名称: "red", "blue", "transparent"
 * - MapLibre表达式对象: ExpressionNAPI 实例
 */
export type ColorValue = string | Object;

/**
 * NumberValue - 数值类型
 * 
 * 支持：
 * - 数字常量: 5, 10.5, 0
 * - MapLibre表达式对象: ExpressionNAPI 实例
 */
export type NumberValue = number | Object;

/**
 * BooleanValue - 布尔值类型
 * 
 * 支持：
 * - 布尔常量: true, false
 * - MapLibre表达式对象: ExpressionNAPI 实例
 */
export type BooleanValue = boolean | Object;

/**
 * StringValue - 字符串值类型
 * 
 * 支持：
 * - 字符串常量: "solid", "round", "bevel"
 * - MapLibre表达式对象: ExpressionNAPI 实例
 */
export type StringValue = string | Object;

/**
 * PropertyValue - 通用属性值类型
 * 
 * 支持任何基础类型或表达式对象
 */
export type PropertyValue<T> = T | Object;

