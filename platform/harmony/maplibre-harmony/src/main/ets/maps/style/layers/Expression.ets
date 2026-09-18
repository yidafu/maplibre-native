/**
 * Expression - Layer expression type definitions
 *
 * Filter/expression helpers built on top of the NAPI expression literals.
 * The upstream expression type set (ExpressionValue, InterpolationType,
 * ComparisonExpression, ... ) is re-exported from PropertyTypes - see the note
 * below; this module used to carry its own copy of that same 15-name list.
 */

import { ComparisonExpression, ExpressionLiteral, LogicalExpression, LookupExpression } from 'libmaplibre.so';

// Re-export Expression for downstream modules
export { Expression } from '../expressions/Expression';

// NOTE: the expression types themselves are surfaced by ./PropertyTypes
// (which re-exports them from libmaplibre.so). This file used to repeat the
// identical 15-name `export type { ... }` block, so the two modules could drift
// apart without anyone noticing. Import them from './PropertyTypes' instead.

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
