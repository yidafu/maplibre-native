/**
 * Expression system exports.
 */

export {
  Expression,
  ExpressionLiteral,
  ExpressionLiteralArray,
  ExpressionMap
} from './Expression';

export { PropertyValue as NativePropertyValue, ExpressionValue } from 'libmaplibre.so';

export { FormatEntry, FormatOption, NumberFormatOption } from './FormatEntry';
export type { PropertyValue } from './Expression'
// Backward-compatible aliases.
// Interpolator, Stop, and CollatorExpression are now part of Expression.
// Use the replacements below:
// - Interpolator.linear() -> Expression.linear()
// - Interpolator.exponential() -> Expression.exponential()
// - Interpolator.cubicBezier() -> Expression.cubicBezier()
// - Stop.stop() -> Expression.stop()
// - CollatorExpression.collator() -> Expression.collator()

