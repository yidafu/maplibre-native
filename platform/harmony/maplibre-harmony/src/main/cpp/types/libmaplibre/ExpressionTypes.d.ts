/**
 * Expression type definitions.
 *
 * Enumerates all MapLibre expression variants.
 * @see https://maplibre.org/maplibre-style-spec/expressions/
 */

/**
 * ExpressionValue - value type used inside expressions.
 * Accepts literals or nested expressions.
 *
 * @see https://maplibre.org/maplibre-style-spec/expressions/
 */
export type ExpressionValue =
  | string
    | number
    | boolean
    | null
    | ExpressionLiteral
    | { [key: string]: ExpressionValue }
    | ExpressionValue[];

/**
 * Interpolation type.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#interpolate
 */
export type InterpolationType =
  | ["linear"]
    | ["exponential", number]
    | ["cubic-bezier", number, number, number, number];

/**
 * Comparison operator expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#decision
 */
export type ComparisonExpression =
  | ["==", ExpressionValue, ExpressionValue]
    | ["!=", ExpressionValue, ExpressionValue]
    | [">", ExpressionValue, ExpressionValue]
    | [">=", ExpressionValue, ExpressionValue]
    | ["<", ExpressionValue, ExpressionValue]
    | ["<=", ExpressionValue, ExpressionValue];

/**
 * Logical operator expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#decision
 */
export type LogicalExpression =
  | ["all", ...ExpressionValue[]]
    | ["any", ...ExpressionValue[]]
    | ["!", ExpressionValue];

/**
 * Lookup operator expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#lookup
 */
export type LookupExpression =
  | ["get", string]
    | ["get", string, ExpressionValue]
    | ["has", string]
    | ["has", string, ExpressionValue]
    | ["in", ExpressionValue, ExpressionValue]
    | ["at", ExpressionValue, ExpressionValue]
    | ["length", ExpressionValue];

/**
 * Mathematical operator expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#math
 */
export type MathExpression =
  | ["+", ...ExpressionValue[]]
    | ["-", ExpressionValue, ExpressionValue]
    | ["*", ...ExpressionValue[]]
    | ["/", ExpressionValue, ExpressionValue]
    | ["%", ExpressionValue, ExpressionValue]
    | ["^", ExpressionValue, ExpressionValue]
    | ["sqrt", ExpressionValue]
    | ["log10", ExpressionValue]
    | ["ln", ExpressionValue]
    | ["log2", ExpressionValue]
    | ["sin", ExpressionValue]
    | ["cos", ExpressionValue]
    | ["tan", ExpressionValue]
    | ["asin", ExpressionValue]
    | ["acos", ExpressionValue]
    | ["atan", ExpressionValue]
    | ["min", ...ExpressionValue[]]
    | ["max", ...ExpressionValue[]]
    | ["round", ExpressionValue]
    | ["abs", ExpressionValue]
    | ["ceil", ExpressionValue]
    | ["floor", ExpressionValue];

/**
 * Conditional expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#decision
 */
export type ConditionalExpression =
  | ["case", ...ExpressionValue[]]
    | ["match", ExpressionValue, ...ExpressionValue[]]
    | ["coalesce", ...ExpressionValue[]];

/**
 * Interpolation expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#ramps-scales-curves
 */
export type InterpolationExpression =
  | ["interpolate", InterpolationType, ExpressionValue, ...ExpressionValue[]]
    | ["interpolate-hcl", InterpolationType, ExpressionValue, ...ExpressionValue[]]
    | ["interpolate-lab", InterpolationType, ExpressionValue, ...ExpressionValue[]]
    | ["step", ExpressionValue, ...ExpressionValue[]];

/**
 * Type conversion expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#types
 */
export type TypeExpression =
  | ["to-string", ExpressionValue]
    | ["to-number", ExpressionValue]
    | ["to-boolean", ExpressionValue]
    | ["to-color", ExpressionValue]
    | ["typeof", ExpressionValue]
    | ["literal", ExpressionValue]
    | ["array", ExpressionValue]
    | ["string", ExpressionValue]
    | ["number", ExpressionValue]
    | ["boolean", ExpressionValue]
    | ["object", ExpressionValue];

/**
 * String operator expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#string
 */
export type StringExpression =
  | ["concat", ...ExpressionValue[]]
    | ["downcase", ExpressionValue]
    | ["upcase", ExpressionValue];

/**
 * Color expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#color
 */
export type ColorExpression =
  | ["rgb", ExpressionValue, ExpressionValue, ExpressionValue]
    | ["rgba", ExpressionValue, ExpressionValue, ExpressionValue, ExpressionValue]
    | ["to-rgba", ExpressionValue];

/**
 * Feature data expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#feature-data
 */
export type FeatureDataExpression =
  | ["properties"]
    | ["feature-state", string]
    | ["geometry-type"]
    | ["id"];

/**
 * Context expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/
 */
export type ContextExpression =
  | ["zoom"]
    | ["heatmap-density"]
    | ["line-progress"]
    | ["accumulated"];

/**
 * Variable binding expressions.
 * @see https://maplibre.org/maplibre-style-spec/expressions/#variable-binding
 */
export type VariableExpression =
  | ["let", ...ExpressionValue[]]
    | ["var", string];

/**
 * ExpressionLiteral - expression literal type.
 * Represents the JSON array form of a MapLibre expression.
 *
 * Union of all concrete expression types.
 *
 * Format: [operator, ...arguments]
 * - operator: expression operator string (for example "get", "interpolate", "case").
 * - arguments: literal values or nested expressions.
 *
 * @see https://maplibre.org/maplibre-style-spec/expressions/
 *
 * @example
* // Feature data expression - retrieve a property.
 * ["get", "propertyName"]
 *
 * @example
* // Camera expression - interpolate over zoom level.
 * ["interpolate", ["linear"], ["zoom"], 0, 0, 10, 100]
 *
 * @example
* // Decision expression - conditional branch.
 * ["case", ["==", ["get", "type"], "restaurant"], "red", "blue"]
 *
 * @example
* // Mathematical expression - arithmetic operation.
 * ["*", ["get", "population"], 0.5]
 *
 * @example
* // Color expression.
 * ["rgb", 255, 0, 0]
 */
export type ExpressionLiteral =
  | ComparisonExpression
    | LogicalExpression
    | LookupExpression
    | MathExpression
    | ConditionalExpression
    | InterpolationExpression
    | TypeExpression
    | StringExpression
    | ColorExpression
    | FeatureDataExpression
    | ContextExpression
    | VariableExpression;

