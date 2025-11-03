/**
 * PropertyTypes - 图层属性值类型定义
 *
 * 重新导出 NAPI 层的类型定义，并扩展支持 ETS Expression 对象
 * 支持三种形式：常量值、Expression 对象、Expression 字面量
 */

import { ComparisonExpression, ExpressionLiteral, LogicalExpression, LookupExpression } from 'libmaplibre.so';

// 导出 Expression 类供其他模块使用
export { Expression } from '../expressions/Expression';

// 从 libmaplibre.so 重新导出所有表达式类型
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

// ==================== 过滤器表达式 ====================

/**
 * FilterExpression - 图层过滤器表达式
 *
 * 用于 layer.filter 属性，支持所有比较、逻辑和查找运算符
 *
 * @example
* ["==", ["get", "type"], "restaurant"]
 * ["all", [">=", ["get", "price"], 10], ["<", ["get", "price"], 100]]
 * ["in", "cuisine", ["literal", ["italian", "french", "chinese"]]]
 */
export type FilterExpression =
  | ComparisonExpression
    | LogicalExpression
    | LookupExpression
    | boolean;

/**
 * 完整的 MapLibre 表达式类型
 *
 * 这是所有表达式的总联合类型，等同于 ExpressionLiteral
 */
export type MapLibreExpression = ExpressionLiteral;

