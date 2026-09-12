/**
 * PropertyTypes - Layer expression type definitions
 *
 * Re-export expression definitions from the NAPI layer while extending ETS Expression support.
 * Expressions can be provided as constant values, Expression instances, or Expression literals.
 */

import { ComparisonExpression, ExpressionLiteral, LogicalExpression, LookupExpression } from 'libmaplibre.so';

// Re-export Expression for downstream modules
export { Expression } from '../expressions/Expression';

// Re-export all expression types from libmaplibre.so
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

// ==================== Filter expressions ====================

/**
 * FilterExpression - Layer filter expressions
 *
 * Used with `layer.filter`. Supports all comparison, logical, and lookup operators.
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
 * Complete MapLibre expression type
 *
 * Union encompassing every expression, equivalent to ExpressionLiteral
 */
export type MapLibreExpression = ExpressionLiteral;
