/**
 * LayerUtils - Shared layer utilities
 *
 * Provides helper functions reused by layer classes
 */

import type { ExpressionLiteral } from 'libmaplibre.so';
import { Expression } from '../expressions/Expression';
/**
 * Convert property values, transforming Expression instances into arrays
 * @param value Property value (constant, Expression instance, or literal array)
 * @returns Converted value (constant or array)
 */
export function convertValue<T>(value: T | Expression | ExpressionLiteral): T | ExpressionLiteral {
  if (value instanceof Expression) {
    return value.toArray() as ExpressionLiteral;
  }
  return value as T | ExpressionLiteral;
}

