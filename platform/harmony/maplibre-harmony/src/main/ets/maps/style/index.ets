/**
 * Style API exports.
 */

// Core style class (re-export NAPI type).
export { Style } from './Style';

// StyleBuilder: the NAPI StyleBuilder re-exported by './Style' is the single
// public builder (the former ETS StyleBuilder wrapper was dead code).

// Sources.
export * from './sources/index';

// Layers (re-export PropertyValue).
export * from './layers/index';

// Images.
export { Image } from './images/Image';

// Lighting.
export { Light } from './light/Light';

// Expression system (PropertyValue omitted to avoid conflicts).
export {
  Expression,
  ExpressionLiteral,
  ExpressionLiteralArray,
  ExpressionMap,
  ExpressionValue
} from './expressions/index';

export { FormatEntry, FormatOption, NumberFormatOption } from './expressions/index';
