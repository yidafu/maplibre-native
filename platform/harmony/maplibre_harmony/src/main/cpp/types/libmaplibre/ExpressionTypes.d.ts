/**
 * Expression 类型定义
 *
 * 定义 MapLibre Expression 的所有具体类型
 * @see https://maplibre.org/maplibre-style-spec/expressions/
 */

/**
 * ExpressionValue - Expression 中的值类型
 * 可以是字面量值或嵌套表达式
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
 * 插值类型
 * @see https://maplibre.org/maplibre-style-spec/expressions/#interpolate
 */
export type InterpolationType =
  | ["linear"]
    | ["exponential", number]
    | ["cubic-bezier", number, number, number, number];

/**
 * 比较运算符表达式
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
 * 逻辑运算符表达式
 * @see https://maplibre.org/maplibre-style-spec/expressions/#decision
 */
export type LogicalExpression =
  | ["all", ...ExpressionValue[]]
    | ["any", ...ExpressionValue[]]
    | ["!", ExpressionValue];

/**
 * 查找运算符表达式
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
 * 数学运算符表达式
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
 * 条件表达式
 * @see https://maplibre.org/maplibre-style-spec/expressions/#decision
 */
export type ConditionalExpression =
  | ["case", ...ExpressionValue[]]
    | ["match", ExpressionValue, ...ExpressionValue[]]
    | ["coalesce", ...ExpressionValue[]];

/**
 * 插值表达式
 * @see https://maplibre.org/maplibre-style-spec/expressions/#ramps-scales-curves
 */
export type InterpolationExpression =
  | ["interpolate", InterpolationType, ExpressionValue, ...ExpressionValue[]]
    | ["interpolate-hcl", InterpolationType, ExpressionValue, ...ExpressionValue[]]
    | ["interpolate-lab", InterpolationType, ExpressionValue, ...ExpressionValue[]]
    | ["step", ExpressionValue, ...ExpressionValue[]];

/**
 * 类型转换表达式
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
 * 字符串运算符表达式
 * @see https://maplibre.org/maplibre-style-spec/expressions/#string
 */
export type StringExpression =
  | ["concat", ...ExpressionValue[]]
    | ["downcase", ExpressionValue]
    | ["upcase", ExpressionValue];

/**
 * 颜色表达式
 * @see https://maplibre.org/maplibre-style-spec/expressions/#color
 */
export type ColorExpression =
  | ["rgb", ExpressionValue, ExpressionValue, ExpressionValue]
    | ["rgba", ExpressionValue, ExpressionValue, ExpressionValue, ExpressionValue]
    | ["to-rgba", ExpressionValue];

/**
 * 特殊数据表达式
 * @see https://maplibre.org/maplibre-style-spec/expressions/#feature-data
 */
export type FeatureDataExpression =
  | ["properties"]
    | ["feature-state", string]
    | ["geometry-type"]
    | ["id"];

/**
 * 特殊上下文表达式
 * @see https://maplibre.org/maplibre-style-spec/expressions/
 */
export type ContextExpression =
  | ["zoom"]
    | ["heatmap-density"]
    | ["line-progress"]
    | ["accumulated"];

/**
 * 变量绑定表达式
 * @see https://maplibre.org/maplibre-style-spec/expressions/#variable-binding
 */
export type VariableExpression =
  | ["let", ...ExpressionValue[]]
    | ["var", string];

/**
 * ExpressionLiteral - Expression 字面量类型
 * 表示 MapLibre Expression 的 JSON 数组格式
 *
 * 这是所有具体表达式类型的联合类型
 *
 * 格式：[operator, ...arguments]
 * - operator: 表达式操作符字符串（如 "get", "interpolate", "case" 等）
 * - arguments: 字面量值或嵌套表达式
 *
 * @see https://maplibre.org/maplibre-style-spec/expressions/
 *
 * @example
* // 数据表达式 - 获取属性
 * ["get", "propertyName"]
 *
 * @example
* // 相机表达式 - 缩放插值
 * ["interpolate", ["linear"], ["zoom"], 0, 0, 10, 100]
 *
 * @example
* // 决策表达式 - 条件判断
 * ["case", ["==", ["get", "type"], "restaurant"], "red", "blue"]
 *
 * @example
* // 数学表达式 - 算术运算
 * ["*", ["get", "population"], 0.5]
 *
 * @example
* // 颜色表达式
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

