/**
 * Style API - 样式模块总导出
 */

// 核心样式类（直接导出 NAPI 类型）
export { Style } from './Style';

// 样式构建器（参考 Android Style.Builder）
export { StyleBuilder } from './StyleBuilder';

// 数据源
export * from './sources/index';

// 图层（会导出 PropertyValue）
export * from './layers/index';

// 图片
export { Image } from './images/Image';

// 光照
export { Light } from './light/Light';

export type { LightOptions } from './light/Light';

// Expression 表达式系统（不导出 PropertyValue 以避免冲突）
export {
  Expression,
  ExpressionBuilder,
  ExpressionLiteral,
  ExpressionLiteralArray,
  ExpressionMap,
  ExpressionValue
} from './expressions/index';

export { FormatEntry, FormatOption, NumberFormatOption } from './expressions/index';
