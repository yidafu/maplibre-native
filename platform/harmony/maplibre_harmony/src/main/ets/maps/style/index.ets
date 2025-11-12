/**
 * Style API exports.
 */

// Core style class (re-export NAPI type).
export { Style } from './Style';

// Style builder (mirrors Android Style.Builder).
export { StyleBuilder } from './StyleBuilder';

// Sources.
export * from './sources/index';

// Layers (re-export PropertyValue).
export * from './layers/index';

// Images.
export { Image } from './images/Image';

// Lighting.
export { Light } from './light/Light';

export type { LightOptions } from './light/Light';

// Expression system (PropertyValue omitted to avoid conflicts).
export {
  Expression,
  ExpressionLiteral,
  ExpressionLiteralArray,
  ExpressionMap,
  ExpressionValue
} from './expressions/index';

export { FormatEntry, FormatOption, NumberFormatOption } from './expressions/index';
