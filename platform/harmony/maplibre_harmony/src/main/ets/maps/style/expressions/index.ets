/**
 * Expression 系统导出
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
// 向后兼容性别名
// Interpolator、Stop、CollatorExpression 已整合到 Expression 类中
// 请使用以下方法代替：
// - Interpolator.linear() -> Expression.linear()
// - Interpolator.exponential() -> Expression.exponential()
// - Interpolator.cubicBezier() -> Expression.cubicBezier()
// - Stop.stop() -> Expression.stop()
// - CollatorExpression.collator() -> Expression.collator()

