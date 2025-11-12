/**
 * PropertyTypes - Layer property type definitions
 *
 * Re-export NAPI type definitions while extending support for ETS Expressions.
 * Each property type supports: constant values, Expression instances, and Expression literals.
 */

import { Expression, ExpressionLiteral } from '../expressions/Expression';

// Import base expression types from libmaplibre.so
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
 * ColorValue - Color property type
 *
 * Supported forms:
 * 1. Color string constants: "#FF0000", "rgb(255,0,0)", "red"
 * 2. Expression instances
 * 3. Expression literals: JSON array syntax like ["get", "color"]
 */
export type ColorValue = string | Expression | ExpressionLiteral;

/**
 * NumberValue - Numeric property type
 *
 * Supported forms:
 * 1. Numeric constants: 5, 10.5, 0
 * 2. Expression instances
 * 3. Expression literals: ["get", "size"]
 */
export type NumberValue = number | Expression | ExpressionLiteral;

/**
 * BooleanValue - Boolean property type
 *
 * Supported forms:
 * 1. Boolean constants: true, false
 * 2. Expression instances
 * 3. Expression literals: ["get", "visible"]
 */
export type BooleanValue = boolean | Expression | ExpressionLiteral;

/**
 * StringValue - String property type
 *
 * Supported forms:
 * 1. String constants: "solid", "round", "bevel"
 * 2. Expression instances
 * 3. Expression literals: ["get", "lineJoin"]
 */
export type StringValue = string | Expression | ExpressionLiteral;

/**
 * PropertyValue - Generic property type
 *
 * Supported forms:
 * 1. Constant values of type T
 * 2. Expression instances
 * 3. Expression literals (JSON array format)
 */
export type PropertyValue<T> = T | Expression | ExpressionLiteral;

