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

/**
 * ExpressionType - backward-compatibility alias for expressions.
 * @deprecated Use PropertyValue<T> instead.
 */
export type ExpressionType<T> = PropertyValue<T>;

/**
 * ColorValue - color property type.
 * Accepts CSS color strings or expression literals.
 * @deprecated Use PropertyValue<string> instead.
 */
export type ColorValue = PropertyValue<string>;

/**
 * NumberValue - numeric property type.
 * Accepts numbers or expression literals.
 * @deprecated Use PropertyValue<number> instead.
 */
export type NumberValue = PropertyValue<number>;

/**
 * StringValue - string property type.
 * Accepts strings or expression literals.
 * @deprecated Use PropertyValue<string> instead.
 */
export type StringValue = PropertyValue<string>;

/**
 * BooleanValue - boolean property type.
 * Accepts booleans or expression literals.
 * @deprecated Use PropertyValue<boolean> instead.
 */
export type BooleanValue = PropertyValue<boolean>;

