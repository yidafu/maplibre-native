/**
 * Layer property value type definitions.
 *
 * Shared property value types for every layer definition.
 * Supports concrete values or expression literals (JSON array form).
 */

import type { ExpressionLiteral } from './ExpressionTypes';

/**
 * PropertyValue - generic property value.
 * Accepts concrete values or expression literals.
 *
 * In the NAPI layer, expression objects are serialized into ExpressionLiteral,
 * so this simplifies to T | ExpressionLiteral.
 * ETS wrappers automatically convert expressions to ExpressionLiteral.
 *
 * @example
* ```typescript
 * // Fixed value.
 * layer.setFillColor('#FF0000');
 *
 * // Expression literal.
 * layer.setFillColor(['get', 'color']);
 * ```
 */
export type PropertyValue<T> = T | ExpressionLiteral;

