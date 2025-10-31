/**
 * Expression - MapLibre 表达式系统 C++ NAPI 绑定类型定义
 * 
 * 提供高性能的表达式解析和求值功能
 */

/**
 * 解析错误接口
 */
export interface ParsingError {
  /** 错误发生的位置键 */
  key: string;
  /** 错误消息 */
  error: string;
}

/**
 * 表达式求值上下文（全局参数）
 */
export interface EvaluationGlobals {
  /** 缩放级别 */
  zoom?: number;
  /** 热力图密度（用于热力图属性） */
  heatmapDensity?: number;
}

/**
 * Expression NAPI 实例接口
 * 
 * 代表一个已编译的表达式对象
 */
export interface ExpressionNAPI {
  /**
   * 求值表达式
   * @param globals 全局参数（如 zoom 等）
   * @param feature GeoJSON Feature 对象
   * @returns 表达式求值结果，可能是任意类型（string, number, boolean, array, object 等）
   */
  evaluate(globals?: EvaluationGlobals, feature?: Object): any;
  
  /**
   * 获取表达式的返回类型
   * @returns 类型名称（如 "string", "number", "boolean", "color" 等）
   */
  getType(): string;
  
  /**
   * 检查表达式是否与 Feature 数据无关（常量）
   * @returns true 如果表达式不依赖 Feature 数据
   */
  isFeatureConstant(): boolean;
  
  /**
   * 检查表达式是否与缩放级别无关（常量）
   * @returns true 如果表达式不依赖缩放级别
   */
  isZoomConstant(): boolean;
  
  /**
   * 将表达式序列化为 JSON 数组格式
   * @returns JSON 数组表示
   */
  serialize(): Object;
}

/**
 * Expression 类（静态方法）
 */
export interface ExpressionConstructor {
  /**
   * 解析 JSON 表达式数组
   * 
   * @param json 表达式的 JSON 表示，通常是数组格式，例如：
   *   - ["get", "name"]
   *   - ["+", 1, 2]
   *   - ["case", condition, value1, value2]
   * @param expectedType 期望的返回类型（可选），例如 {kind: "string"}
   * @returns 成功时返回 ExpressionNAPI 实例，失败时返回 ParsingError 数组
   * 
   * @example
   * ```typescript
   * // 解析获取属性表达式
   * const expr = Expression.parse(["get", "name"]);
   * if (Array.isArray(expr)) {
   *   // 解析失败，expr 是错误数组
   *   console.error("Parse errors:", expr);
   * } else {
   *   // 解析成功，expr 是 ExpressionNAPI
   *   const result = expr.evaluate({}, { properties: { name: "Test" } });
   *   console.log(result); // "Test"
   * }
   * ```
   */
  parse(json: Object, expectedType?: Object): ExpressionNAPI | ParsingError[];
}

/**
 * Expression 类导出
 */
export const Expression: ExpressionConstructor;

