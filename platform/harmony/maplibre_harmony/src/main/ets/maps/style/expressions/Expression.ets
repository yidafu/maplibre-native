/**
 * Expression - MapLibre 表达式系统核心类
 * 
 * 使用 C++ NAPI 绑定实现，提供高性能的表达式解析和求值功能。
 * 
 * 表达式定义了一个公式，用于使用以下运算符计算属性的值：
 * - 数学运算符：执行算术和其他数字值操作
 * - 逻辑运算符：操作布尔值和进行条件决策
 * - 字符串运算符：操作字符串
 * - 数据运算符：访问源要素的属性
 * - 相机运算符：访问定义当前地图视图的参数
 * 
 * 表达式表示为 JSON 数组。数组的第一个元素是命名表达式运算符的字符串，
 * 例如 "*" 或 "case"。后续元素（如果有）是表达式的参数。
 * 每个参数都是字面量值（字符串、数字、布尔值或 null）或另一个表达式数组。
 * 
 * @see <a href="https://maplibre.org/maplibre-style-spec/expressions/">MapLibre Expression Specification</a>
 */

import { ValueExpression, ExpressionValue } from './ExpressionTypes';
import maplibre_native from 'libmaplibre_native.so';

/**
 * Expression NAPI 接口
 */
interface ExpressionNAPI {
  evaluate(globals?: Object, feature?: Object): Object;
  getType(): string;
  isFeatureConstant(): boolean;
  isZoomConstant(): boolean;
  serialize(): Object;
}

/**
 * Expression - 包装 C++ NAPI Expression 的类
 */
export class Expression {
  private nativeExpression: ExpressionNAPI; // ExpressionNAPI from C++

  /**
   * 私有构造函数 - 只能通过 parse() 静态方法创建
   */
  private constructor(nativeExpr: ExpressionNAPI) {
    this.nativeExpression = nativeExpr;
  }

  /**
   * 解析 JSON 表达式数组
   * 
   * @param json 表达式的 JSON 表示，例如：["get", "name"]、["+", 1, 2]
   * @param expectedType 期望的返回类型（可选）
   * @returns Expression 实例
   * @throws Error 如果解析失败
   */
  static parse(json: Object, expectedType?: Object): Expression {
    const result: Object = maplibre_native.Expression.parse(json, expectedType);
    
    // 检查是否为错误数组
    if (Array.isArray(result)) {
      const errors = result.map((err: Object) => {
        const errorObj = err as Record<string, string>;
        return `[${errorObj.key}] ${errorObj.error}`;
      }).join('; ');
      throw new Error(`Expression parse failed: ${errors}`);
    }
    
    return new Expression(result);
  }

  /**
   * 求值表达式
   * 
   * @param globals 全局参数对象（如 zoom）
   * @param feature GeoJSON Feature 对象
   * @returns 表达式求值结果
   */
  evaluate(globals?: Object, feature?: Object): Object {
    return this.nativeExpression.evaluate(globals, feature);
  }

  /**
   * 获取表达式的返回类型
   * @returns 类型名称（如 "string", "number", "boolean", "color" 等）
   */
  getType(): string {
    return this.nativeExpression.getType();
  }

  /**
   * 检查表达式是否与 Feature 数据无关（常量）
   * @returns true 如果表达式不依赖 Feature 数据
   */
  isFeatureConstant(): boolean {
    return this.nativeExpression.isFeatureConstant();
  }

  /**
   * 检查表达式是否与缩放级别无关（常量）
   * @returns true 如果表达式不依赖缩放级别
   */
  isZoomConstant(): boolean {
    return this.nativeExpression.isZoomConstant();
  }

  /**
   * 将表达式序列化为 JSON 数组格式
   * @returns JSON 数组表示
   */
  serialize(): Object {
    return this.nativeExpression.serialize();
  }

  /**
   * 将表达式转换为 JSON 数组格式（serialize 的别名）
   */
  toArray(): Object {
    return this.serialize();
  }

  /**
   * 转换为字符串
   */
  toString(): string {
    return JSON.stringify(this.serialize());
  }

  /**
   * 获取原生 NAPI 对象（供内部使用）
   * @internal
   */
  getNativeExpression(): Object {
    return this.nativeExpression;
  }

  /**
   * 检查当前表达式是否为值表达式
   * 保留此方法用于兼容性
   */
  isValue(): boolean {
    return false;
  }
}

/**
 * ========== 以下是辅助类，用于方便地构建表达式 ==========
 * 这些类提供了便捷的表达式构建方法，其 toArray() 结果可以被 Expression.parse() 解析
 */

/**
 * ExpressionBuilder - 表达式构建器基类
 * 保留用于向后兼容和便捷构建
 */
export class ExpressionBuilder<T = Object> {
  protected operator: string;
  protected arguments: ExpressionBuilder[] | null;

  constructor(operator: string, ...args: ExpressionBuilder[]) {
    this.operator = operator;
    this.arguments = args.length > 0 ? args : null;
  }

  /**
   * 创建字面量表达式
   */
  public static literal(value: Object | string | number | boolean | null): ExpressionLiteral;
  public static literal(value: ExpressionValue): ExpressionBuilder;
  public static literal(value: ExpressionValue): ExpressionLiteral {
    if (Array.isArray(value)) {
      return new ExpressionLiteralArray(value as (Object | null)[]);
    }
    return new ExpressionLiteral(value);
  }

  public getOperator(): string {
    return this.operator;
  }

  public getArguments(): ExpressionBuilder[] | null {
    return this.arguments;
  }

  public toArray(): (Object | null)[] {
    const array: (Object | null)[] = [this.operator];
    if (this.arguments !== null && this.arguments.length > 0) {
      for (const arg of this.arguments) {
        if (arg.isValue()) {
          array.push((arg as ExpressionLiteral).toValue());
        } else {
          array.push(arg.toArray() as Object);
        }
      }
    }
    return array;
  }

  isValue(): boolean {
    return false;
  }

  protected isValueExpression(expr: ExpressionBuilder): boolean {
    return expr.isValue();
  }

  public toString(): string {
    return JSON.stringify(this.toArray());
  }

  public equals(other: ExpressionBuilder | null): boolean {
    if (other === null) {
      return false;
    }
    if (this.operator !== other.operator) {
      return false;
    }
    if (this.arguments === null && other.arguments === null) {
      return true;
    }
    if (this.arguments === null || other.arguments === null) {
      return false;
    }
    if (this.arguments.length !== other.arguments.length) {
      return false;
    }
    for (let i = 0; i < this.arguments.length; i++) {
      if (!this.arguments[i].equals(other.arguments[i])) {
        return false;
      }
    }
    return true;
  }

  /**
   * 获取哈希码
   */
  public hashCode(): number {
    let result = this.operator.length;
    if (this.arguments !== null) {
      result = 31 * result + this.arguments.length;
    }
    return result;
  }

  // ==================== 字面量操作符 ====================

  /**
   * 创建一个数字字面量表达式
   */
  public static literal(value: number): ExpressionBuilder<number>;
  
  /**
   * 创建一个字符串字面量表达式
   */
  public static literal(value: string): ExpressionBuilder<string>;
  
  /**
   * 创建一个布尔字面量表达式
   */
  public static literal(value: boolean): ExpressionBuilder<boolean>;
  
  /**
   * 创建一个对象字面量表达式
   */
  public static literal(value: Object): ExpressionBuilder<Object>;
  
  /**
   * 创建一个数组字面量表达式
   */
  public static literal(value: Object[]): ExpressionBuilder<Object[]>;
  
  /**
   * 创建一个字面量表达式的实现
   */
  public static literal(value: ExpressionValue): Expression {
    if (Array.isArray(value)) {
      return new ExpressionLiteralArray(value as (Object | null)[]);
    }
    return new ExpressionLiteral(value);
  }

  // ==================== 颜色操作符 ====================

  /**
   * 从整数创建颜色表达式
   * 
   * @param color ARGB 格式的颜色整数
   */
  public static color(color: number): ExpressionBuilder<string> {
    const rgba = Expression.colorToRgbaArray(color);
    return Expression.rgba(
      Expression.literal(rgba[0]),
      Expression.literal(rgba[1]),
      Expression.literal(rgba[2]),
      Expression.literal(rgba[3])
    );
  }

  /**
   * 创建 RGB 颜色表达式
   */
  public static rgb(red: ExpressionBuilder<number>, green: ExpressionBuilder<number>, blue: ExpressionBuilder<number>): ExpressionBuilder<string>;
  
  /**
   * 创建 RGB 颜色表达式（数字参数）
   */
  public static rgb(red: number, green: number, blue: number): ExpressionBuilder<string>;
  
  /**
   * 创建 RGB 颜色表达式的实现
   */
  public static rgb(
    red: ExpressionBuilder<number> | number,
    green: ExpressionBuilder<number> | number,
    blue: ExpressionBuilder<number> | number
  ): ExpressionBuilder<string> {
    const redExpr = typeof red === 'number' ? Expression.literal(red) : red;
    const greenExpr = typeof green === 'number' ? Expression.literal(green) : green;
    const blueExpr = typeof blue === 'number' ? Expression.literal(blue) : blue;
    return new ExpressionBuilder<string>('rgb', redExpr, greenExpr, blueExpr);
  }

  /**
   * 创建 RGBA 颜色表达式
   */
  public static rgba(
    red: ExpressionBuilder<number>,
    green: ExpressionBuilder<number>,
    blue: ExpressionBuilder<number>,
    alpha: ExpressionBuilder<number>
  ): ExpressionBuilder<string>;
  
  /**
   * 创建 RGBA 颜色表达式（数字参数）
   */
  public static rgba(red: number, green: number, blue: number, alpha: number): ExpressionBuilder<string>;
  
  /**
   * 创建 RGBA 颜色表达式的实现
   */
  public static rgba(
    red: ExpressionBuilder<number> | number,
    green: ExpressionBuilder<number> | number,
    blue: ExpressionBuilder<number> | number,
    alpha: ExpressionBuilder<number> | number
  ): ExpressionBuilder<string> {
    const redExpr = typeof red === 'number' ? Expression.literal(red) : red;
    const greenExpr = typeof green === 'number' ? Expression.literal(green) : green;
    const blueExpr = typeof blue === 'number' ? Expression.literal(blue) : blue;
    const alphaExpr = typeof alpha === 'number' ? Expression.literal(alpha) : alpha;
    return new ExpressionBuilder<string>('rgba', redExpr, greenExpr, blueExpr, alphaExpr);
  }

  /**
   * 将颜色转换为 RGBA 数组表达式
   */
  public static toRgba(color: Expression): ExpressionBuilder<number[]> {
    return new ExpressionBuilder<number[]>('to-rgba', color);
  }

  /**
   * 辅助方法：将颜色整数转换为 RGBA 数组
   */
  private static colorToRgbaArray(color: number): number[] {
    const a = ((color >> 24) & 0xFF) / 255.0;
    const r = (color >> 16) & 0xFF;
    const g = (color >> 8) & 0xFF;
    const b = color & 0xFF;
    return [r, g, b, a];
  }

  // ==================== 数据访问操作符 ====================

  /**
   * 从当前要素的属性中获取指定键的值
   * 
   * @param key 属性键（Expression）
   */
  public static get<T = Object>(key: ExpressionBuilder<string>): ExpressionBuilder<T>;

  /**
   * 从当前要素的属性中获取指定键的值
   * 
   * @param key 属性键（字符串）
   */
  public static get<T = Object>(key: string): ExpressionBuilder<T>;

  /**
   * 从对象中获取指定键的值
   * 
   * @param key 属性键（Expression）
   * @param object 对象表达式
   */
  public static get<T = Object>(key: ExpressionBuilder<string>, object: ExpressionBuilder<Object>): ExpressionBuilder<T>;

  /**
   * 从对象中获取指定键的值
   * 
   * @param key 属性键（字符串）
   * @param object 对象表达式
   */
  public static get<T = Object>(key: string, object: ExpressionBuilder<Object>): ExpressionBuilder<T>;

  /**
   * 从要素或对象中获取指定键的值的实现
   */
  public static get<T = Object>(
    key: ExpressionBuilder<string> | string,
    object?: ExpressionBuilder<Object>
  ): ExpressionBuilder<T> {
    const keyExpr = typeof key === 'string' ? Expression.literal(key) : key;
    if (object === undefined) {
      return new ExpressionBuilder<T>('get', keyExpr);
    }
    return new ExpressionBuilder<T>('get', keyExpr, object);
  }

  /**
   * 检查当前要素是否具有指定的属性
   * 
   * @param key 属性键（Expression）
   */
  public static has(key: ExpressionBuilder<string>): ExpressionBuilder<boolean>;

  /**
   * 检查当前要素是否具有指定的属性
   * 
   * @param key 属性键（字符串）
   */
  public static has(key: string): ExpressionBuilder<boolean>;

  /**
   * 检查对象是否具有指定的属性
   * 
   * @param key 属性键（Expression）
   * @param object 对象表达式
   */
  public static has(key: ExpressionBuilder<string>, object: ExpressionBuilder<Object>): ExpressionBuilder<boolean>;

  /**
   * 检查对象是否具有指定的属性
   * 
   * @param key 属性键（字符串）
   * @param object 对象表达式
   */
  public static has(key: string, object: ExpressionBuilder<Object>): ExpressionBuilder<boolean>;

  /**
   * 检查要素或对象是否具有指定的属性的实现
   */
  public static has(
    key: ExpressionBuilder<string> | string,
    object?: ExpressionBuilder<Object>
  ): ExpressionBuilder<boolean> {
    const keyExpr = typeof key === 'string' ? Expression.literal(key) : key;
    if (object === undefined) {
      return new ExpressionBuilder<boolean>('has', keyExpr);
    }
    return new ExpressionBuilder<boolean>('has', keyExpr, object);
  }

  /**
   * 获取当前要素的所有属性
   */
  public static properties(): ExpressionBuilder<Object> {
    return new ExpressionBuilder<Object>('properties');
  }

  /**
   * 获取当前要素的几何类型
   * 返回值为 "Point", "MultiPoint", "LineString", "MultiLineString", "Polygon", "MultiPolygon"
   */
  public static geometryType(): ExpressionBuilder<string> {
    return new ExpressionBuilder<string>('geometry-type');
  }

  /**
   * 获取当前要素的 ID
   */
  public static id(): ExpressionBuilder<number | string> {
    return new Expression('id');
  }

  /**
   * 获取聚合累积值（用于聚合图层）
   */
  public static accumulated(): ExpressionBuilder<Object> {
    return new ExpressionBuilder<Object>('accumulated');
  }

  /**
   * 获取热力图密度值（仅在热力图图层的 heatmap-color 属性中可用）
   */
  public static heatmapDensity(): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('heatmap-density');
  }

  /**
   * 获取线条进度值（仅在线条图层的渐变属性中可用）
   */
  public static lineProgress(): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('line-progress');
  }

  // ==================== 数组和对象操作符 ====================

  /**
   * 从数组中获取指定索引的元素
   * 
   * @param index 索引（Expression）
   * @param array 数组表达式
   */
  public static at<T = Object>(index: ExpressionBuilder<number>, array: ExpressionBuilder<T[]>): ExpressionBuilder<T>;

  /**
   * 从数组中获取指定索引的元素
   * 
   * @param index 索引（数字）
   * @param array 数组表达式
   */
  public static at<T = Object>(index: number, array: ExpressionBuilder<T[]>): ExpressionBuilder<T>;

  /**
   * 从数组中获取指定索引的元素的实现
   */
  public static at<T = Object>(
    index: ExpressionBuilder<number> | number,
    array: ExpressionBuilder<T[]>
  ): ExpressionBuilder<T> {
    const indexExpr = typeof index === 'number' ? Expression.literal(index) : index;
    return new ExpressionBuilder<T>('at', indexExpr, array);
  }

  /**
   * 检查值是否在数组或字符串中
   * 
   * @param needle 要查找的值
   * @param haystack 数组或字符串
   */
  public static in(needle: Expression, haystack: Expression): ExpressionBuilder<boolean>;

  /**
   * 检查数字是否在数组中
   */
  public static in(needle: number, haystack: Expression): ExpressionBuilder<boolean>;

  /**
   * 检查字符串是否在数组或字符串中
   */
  public static in(needle: string, haystack: Expression): ExpressionBuilder<boolean>;

  /**
   * 检查值是否在数组或字符串中的实现
   */
  public static in(
    needle: Expression | number | string,
    haystack: Expression
  ): ExpressionBuilder<boolean> {
    const needleExpr = (needle instanceof ExpressionBuilder) 
      ? needle 
      : Expression.literal(needle);
    return new ExpressionBuilder<boolean>('in', needleExpr, haystack);
  }

  /**
   * 查找值在数组或字符串中的索引
   * 
   * @param keyword 要查找的值
   * @param input 数组或字符串
   */
  public static indexOf(keyword: Expression, input: Expression): ExpressionBuilder<number>;

  /**
   * 从指定位置开始查找值在数组或字符串中的索引
   * 
   * @param keyword 要查找的值
   * @param input 数组或字符串
   * @param fromIndex 开始位置
   */
  public static indexOf(keyword: Expression, input: Expression, fromIndex: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 查找值在数组或字符串中的索引的实现
   */
  public static indexOf(
    keyword: Expression,
    input: Expression,
    fromIndex?: ExpressionBuilder<number>
  ): ExpressionBuilder<number> {
    if (fromIndex === undefined) {
      return new ExpressionBuilder<number>('index-of', keyword, input);
    }
    return new ExpressionBuilder<number>('index-of', keyword, input, fromIndex);
  }

  /**
   * 数组或字符串切片
   * 
   * @param input 数组或字符串
   * @param fromIndex 开始位置（Expression）
   */
  public static slice<T = Object>(input: ExpressionBuilder<T[] | string>, fromIndex: ExpressionBuilder<number>): ExpressionBuilder<T[] | string>;

  /**
   * 数组或字符串切片
   * 
   * @param input 数组或字符串
   * @param fromIndex 开始位置（数字）
   */
  public static slice<T = Object>(input: ExpressionBuilder<T[] | string>, fromIndex: number): ExpressionBuilder<T[] | string>;

  /**
   * 数组或字符串切片（指定范围）
   * 
   * @param input 数组或字符串
   * @param fromIndex 开始位置（Expression）
   * @param toIndex 结束位置（Expression）
   */
  public static slice<T = Object>(
    input: ExpressionBuilder<T[] | string>,
    fromIndex: ExpressionBuilder<number>,
    toIndex: ExpressionBuilder<number>
  ): ExpressionBuilder<T[] | string>;

  /**
   * 数组或字符串切片（指定范围）
   * 
   * @param input 数组或字符串
   * @param fromIndex 开始位置（数字）
   * @param toIndex 结束位置（数字）
   */
  public static slice<T = Object>(
    input: ExpressionBuilder<T[] | string>,
    fromIndex: number,
    toIndex: number
  ): ExpressionBuilder<T[] | string>;

  /**
   * 数组或字符串切片的实现
   */
  public static slice<T = Object>(
    input: ExpressionBuilder<T[] | string>,
    fromIndex: ExpressionBuilder<number> | number,
    toIndex?: ExpressionBuilder<number> | number
  ): ExpressionBuilder<T[] | string> {
    const fromIndexExpr = typeof fromIndex === 'number' ? Expression.literal(fromIndex) : fromIndex;
    if (toIndex === undefined) {
      return new Expression('slice', input, fromIndexExpr);
    }
    const toIndexExpr = typeof toIndex === 'number' ? Expression.literal(toIndex) : toIndex;
    return new Expression('slice', input, fromIndexExpr, toIndexExpr);
  }

  /**
   * 获取数组或字符串的长度
   * 注意：重命名为 len 以避免与 Function.length 冲突
   */
  public static len(input: ExpressionBuilder<Object[] | string>): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('length', input);
  }

  // ==================== 比较操作符 ====================

  /**
   * 等于比较（Expression）
   */
  public static eq(compareOne: Expression, compareTwo: Expression): ExpressionBuilder<boolean>;

  /**
   * 等于比较（Expression 和布尔值）
   */
  public static eq(compareOne: Expression, compareTwo: boolean): ExpressionBuilder<boolean>;

  /**
   * 等于比较（Expression 和字符串）
   */
  public static eq(compareOne: Expression, compareTwo: string): ExpressionBuilder<boolean>;

  /**
   * 等于比较（Expression 和数字）
   */
  public static eq(compareOne: Expression, compareTwo: number): ExpressionBuilder<boolean>;

  /**
   * 等于比较的实现
   */
  public static eq(
    compareOne: Expression,
    compareTwo: Expression | boolean | string | number
  ): ExpressionBuilder<boolean> {
    const compareTwoExpr = (compareTwo instanceof ExpressionBuilder)
      ? compareTwo
      : Expression.literal(compareTwo);
    return new ExpressionBuilder<boolean>('==', compareOne, compareTwoExpr);
  }

  /**
   * 不等于比较（Expression）
   */
  public static neq(compareOne: Expression, compareTwo: Expression): ExpressionBuilder<boolean>;

  /**
   * 不等于比较（Expression 和布尔值）
   */
  public static neq(compareOne: Expression, compareTwo: boolean): ExpressionBuilder<boolean>;

  /**
   * 不等于比较（Expression 和字符串）
   */
  public static neq(compareOne: Expression, compareTwo: string): ExpressionBuilder<boolean>;

  /**
   * 不等于比较（Expression 和数字）
   */
  public static neq(compareOne: Expression, compareTwo: number): ExpressionBuilder<boolean>;

  /**
   * 不等于比较的实现
   */
  public static neq(
    compareOne: Expression,
    compareTwo: Expression | boolean | string | number
  ): ExpressionBuilder<boolean> {
    const compareTwoExpr = (compareTwo instanceof ExpressionBuilder)
      ? compareTwo
      : Expression.literal(compareTwo);
    return new ExpressionBuilder<boolean>('!=', compareOne, compareTwoExpr);
  }

  /**
   * 大于比较（Expression）
   */
  public static gt(compareOne: Expression, compareTwo: Expression): ExpressionBuilder<boolean>;

  /**
   * 大于比较（Expression 和数字）
   */
  public static gt(compareOne: Expression, compareTwo: number): ExpressionBuilder<boolean>;

  /**
   * 大于比较（Expression 和字符串）
   */
  public static gt(compareOne: Expression, compareTwo: string): ExpressionBuilder<boolean>;

  /**
   * 大于比较的实现
   */
  public static gt(
    compareOne: Expression,
    compareTwo: Expression | number | string
  ): ExpressionBuilder<boolean> {
    const compareTwoExpr = (compareTwo instanceof ExpressionBuilder)
      ? compareTwo
      : Expression.literal(compareTwo);
    return new ExpressionBuilder<boolean>('>', compareOne, compareTwoExpr);
  }

  /**
   * 小于比较（Expression）
   */
  public static lt(compareOne: Expression, compareTwo: Expression): ExpressionBuilder<boolean>;

  /**
   * 小于比较（Expression 和数字）
   */
  public static lt(compareOne: Expression, compareTwo: number): ExpressionBuilder<boolean>;

  /**
   * 小于比较（Expression 和字符串）
   */
  public static lt(compareOne: Expression, compareTwo: string): ExpressionBuilder<boolean>;

  /**
   * 小于比较的实现
   */
  public static lt(
    compareOne: Expression,
    compareTwo: Expression | number | string
  ): ExpressionBuilder<boolean> {
    const compareTwoExpr = (compareTwo instanceof ExpressionBuilder)
      ? compareTwo
      : Expression.literal(compareTwo);
    return new ExpressionBuilder<boolean>('<', compareOne, compareTwoExpr);
  }

  /**
   * 大于等于比较（Expression）
   */
  public static gte(compareOne: Expression, compareTwo: Expression): ExpressionBuilder<boolean>;

  /**
   * 大于等于比较（Expression 和数字）
   */
  public static gte(compareOne: Expression, compareTwo: number): ExpressionBuilder<boolean>;

  /**
   * 大于等于比较（Expression 和字符串）
   */
  public static gte(compareOne: Expression, compareTwo: string): ExpressionBuilder<boolean>;

  /**
   * 大于等于比较的实现
   */
  public static gte(
    compareOne: Expression,
    compareTwo: Expression | number | string
  ): ExpressionBuilder<boolean> {
    const compareTwoExpr = (compareTwo instanceof ExpressionBuilder)
      ? compareTwo
      : Expression.literal(compareTwo);
    return new ExpressionBuilder<boolean>('>=', compareOne, compareTwoExpr);
  }

  /**
   * 小于等于比较（Expression）
   */
  public static lte(compareOne: Expression, compareTwo: Expression): ExpressionBuilder<boolean>;

  /**
   * 小于等于比较（Expression 和数字）
   */
  public static lte(compareOne: Expression, compareTwo: number): ExpressionBuilder<boolean>;

  /**
   * 小于等于比较（Expression 和字符串）
   */
  public static lte(compareOne: Expression, compareTwo: string): ExpressionBuilder<boolean>;

  /**
   * 小于等于比较的实现
   */
  public static lte(
    compareOne: Expression,
    compareTwo: Expression | number | string
  ): ExpressionBuilder<boolean> {
    const compareTwoExpr = (compareTwo instanceof ExpressionBuilder)
      ? compareTwo
      : Expression.literal(compareTwo);
    return new ExpressionBuilder<boolean>('<=', compareOne, compareTwoExpr);
  }

  // ==================== 逻辑操作符 ====================

  /**
   * 逻辑与（所有条件都为真）
   */
  public static all(...expressions: ExpressionBuilder<boolean>[]): ExpressionBuilder<boolean> {
    return new ExpressionBuilder<boolean>('all', ...expressions);
  }

  /**
   * 逻辑或（任一条件为真）
   */
  public static any(...expressions: ExpressionBuilder<boolean>[]): ExpressionBuilder<boolean> {
    return new ExpressionBuilder<boolean>('any', ...expressions);
  }

  /**
   * 逻辑非
   */
  public static not(input: ExpressionBuilder<boolean>): ExpressionBuilder<boolean>;

  /**
   * 逻辑非（布尔值）
   */
  public static not(input: boolean): ExpressionBuilder<boolean>;

  /**
   * 逻辑非的实现
   */
  public static not(input: ExpressionBuilder<boolean> | boolean): ExpressionBuilder<boolean> {
    const inputExpr = typeof input === 'boolean' ? Expression.literal(input) : input;
    return new ExpressionBuilder<boolean>('!', inputExpr);
  }

  // ==================== 条件操作符 ====================

  /**
   * Switch-case 条件表达式
   * 格式：case(condition1, output1, condition2, output2, ..., fallback)
   */
  public static switchCase(...expressions: ExpressionBuilder[]): Expression {
    return new Expression('case', ...expressions);
  }

  /**
   * Case 条件表达式（switchCase的别名）
   * 格式：case(condition1, output1, condition2, output2, ..., fallback)
   */
  public static caseExpression(...expressions: ExpressionBuilder[]): Expression {
    return Expression.switchCase(...expressions);
  }

  /**
   * Match 表达式 - 匹配输入值并返回对应的输出
   * 格式：match(input, label1, output1, label2, output2, ..., fallback)
   */
  public static match(...expressions: ExpressionBuilder[]): Expression {
    return new Expression('match', ...expressions);
  }

  /**
   * Coalesce 表达式 - 返回第一个非空值
   */
  public static coalesce(...expressions: ExpressionBuilder[]): Expression {
    return new Expression('coalesce', ...expressions);
  }

  // ==================== 算术运算操作符 ====================

  /**
   * 加法运算
   */
  public static add(...expressions: ExpressionBuilder<number>[]): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('+', ...expressions);
  }

  /**
   * 减法运算（二元）
   */
  public static subtract(first: ExpressionBuilder<number>, second: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 减法运算（二元，数字参数）
   */
  public static subtract(first: number, second: number): ExpressionBuilder<number>;

  /**
   * 取负（一元）
   */
  public static subtract(value: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 取负（一元，数字参数）
   */
  public static subtract(value: number): ExpressionBuilder<number>;

  /**
   * 减法运算的实现
   */
  public static subtract(
    first: ExpressionBuilder<number> | number,
    second?: ExpressionBuilder<number> | number
  ): ExpressionBuilder<number> {
    if (second === undefined) {
      // 一元取负
      const valueExpr = typeof first === 'number' ? Expression.literal(first) : first;
      return new ExpressionBuilder<number>('-', valueExpr);
    } else {
      // 二元减法
      const firstExpr = typeof first === 'number' ? Expression.literal(first) : first;
      const secondExpr = typeof second === 'number' ? Expression.literal(second) : second;
      return new ExpressionBuilder<number>('-', firstExpr, secondExpr);
    }
  }

  /**
   * 乘法运算
   */
  public static multiply(...expressions: ExpressionBuilder<number>[]): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('*', ...expressions);
  }

  /**
   * 除法运算
   */
  public static divide(first: ExpressionBuilder<number>, second: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 除法运算（数字参数）
   */
  public static divide(first: number, second: number): ExpressionBuilder<number>;

  /**
   * 除法运算的实现
   */
  public static divide(
    first: ExpressionBuilder<number> | number,
    second: ExpressionBuilder<number> | number
  ): ExpressionBuilder<number> {
    const firstExpr = typeof first === 'number' ? Expression.literal(first) : first;
    const secondExpr = typeof second === 'number' ? Expression.literal(second) : second;
    return new ExpressionBuilder<number>('/', firstExpr, secondExpr);
  }

  /**
   * 取模运算
   */
  public static mod(first: ExpressionBuilder<number>, second: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 取模运算（数字参数）
   */
  public static mod(first: number, second: number): ExpressionBuilder<number>;

  /**
   * 取模运算的实现
   */
  public static mod(
    first: ExpressionBuilder<number> | number,
    second: ExpressionBuilder<number> | number
  ): ExpressionBuilder<number> {
    const firstExpr = typeof first === 'number' ? Expression.literal(first) : first;
    const secondExpr = typeof second === 'number' ? Expression.literal(second) : second;
    return new ExpressionBuilder<number>('%', firstExpr, secondExpr);
  }

  /**
   * 幂运算
   */
  public static pow(base: ExpressionBuilder<number>, exponent: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 幂运算（数字参数）
   */
  public static pow(base: number, exponent: number): ExpressionBuilder<number>;

  /**
   * 幂运算的实现
   */
  public static pow(
    base: ExpressionBuilder<number> | number,
    exponent: ExpressionBuilder<number> | number
  ): ExpressionBuilder<number> {
    const baseExpr = typeof base === 'number' ? Expression.literal(base) : base;
    const exponentExpr = typeof exponent === 'number' ? Expression.literal(exponent) : exponent;
    return new ExpressionBuilder<number>('^', baseExpr, exponentExpr);
  }

  // ==================== 数学函数 ====================

  /**
   * 平方根
   */
  public static sqrt(value: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 平方根（数字参数）
   */
  public static sqrt(value: number): ExpressionBuilder<number>;

  /**
   * 平方根的实现
   */
  public static sqrt(value: ExpressionBuilder<number> | number): ExpressionBuilder<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new ExpressionBuilder<number>('sqrt', valueExpr);
  }

  /**
   * 以 10 为底的对数
   */
  public static log10(value: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 以 10 为底的对数（数字参数）
   */
  public static log10(value: number): ExpressionBuilder<number>;

  /**
   * 以 10 为底的对数的实现
   */
  public static log10(value: ExpressionBuilder<number> | number): ExpressionBuilder<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new ExpressionBuilder<number>('log10', valueExpr);
  }

  /**
   * 以 2 为底的对数
   */
  public static log2(value: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 以 2 为底的对数（数字参数）
   */
  public static log2(value: number): ExpressionBuilder<number>;

  /**
   * 以 2 为底的对数的实现
   */
  public static log2(value: ExpressionBuilder<number> | number): ExpressionBuilder<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new ExpressionBuilder<number>('log2', valueExpr);
  }

  /**
   * 自然对数
   */
  public static ln(value: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 自然对数（数字参数）
   */
  public static ln(value: number): ExpressionBuilder<number>;

  /**
   * 自然对数的实现
   */
  public static ln(value: ExpressionBuilder<number> | number): ExpressionBuilder<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new ExpressionBuilder<number>('ln', valueExpr);
  }

  /**
   * 绝对值
   */
  public static abs(value: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 绝对值（数字参数）
   */
  public static abs(value: number): ExpressionBuilder<number>;

  /**
   * 绝对值的实现
   */
  public static abs(value: ExpressionBuilder<number> | number): ExpressionBuilder<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new ExpressionBuilder<number>('abs', valueExpr);
  }

  /**
   * 向上取整
   */
  public static ceil(value: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 向上取整（数字参数）
   */
  public static ceil(value: number): ExpressionBuilder<number>;

  /**
   * 向上取整的实现
   */
  public static ceil(value: ExpressionBuilder<number> | number): ExpressionBuilder<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new ExpressionBuilder<number>('ceil', valueExpr);
  }

  /**
   * 向下取整
   */
  public static floor(value: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 向下取整（数字参数）
   */
  public static floor(value: number): ExpressionBuilder<number>;

  /**
   * 向下取整的实现
   */
  public static floor(value: ExpressionBuilder<number> | number): ExpressionBuilder<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new ExpressionBuilder<number>('floor', valueExpr);
  }

  /**
   * 四舍五入
   */
  public static round(value: ExpressionBuilder<number>): ExpressionBuilder<number>;

  /**
   * 四舍五入（数字参数）
   */
  public static round(value: number): ExpressionBuilder<number>;

  /**
   * 四舍五入的实现
   */
  public static round(value: ExpressionBuilder<number> | number): ExpressionBuilder<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new ExpressionBuilder<number>('round', valueExpr);
  }

  /**
   * 最小值
   */
  public static min(...values: ExpressionBuilder<number>[]): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('min', ...values);
  }

  /**
   * 最大值
   */
  public static max(...values: ExpressionBuilder<number>[]): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('max', ...values);
  }

  /**
   * 正弦函数
   */
  public static sin(value: ExpressionBuilder<number>): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('sin', value);
  }

  /**
   * 余弦函数
   */
  public static cos(value: ExpressionBuilder<number>): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('cos', value);
  }

  /**
   * 正切函数
   */
  public static tan(value: ExpressionBuilder<number>): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('tan', value);
  }

  /**
   * 反正弦函数
   */
  public static asin(value: ExpressionBuilder<number>): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('asin', value);
  }

  /**
   * 反余弦函数
   */
  public static acos(value: ExpressionBuilder<number>): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('acos', value);
  }

  /**
   * 反正切函数
   */
  public static atan(value: ExpressionBuilder<number>): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('atan', value);
  }

  /**
   * 自然常数 e
   */
  public static e(): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('e');
  }

  /**
   * 圆周率 π
   */
  public static pi(): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('pi');
  }

  // ==================== 字符串操作符 ====================

  /**
   * 字符串连接
   */
  public static concat(...strings: ExpressionBuilder<string>[]): ExpressionBuilder<string> {
    return new ExpressionBuilder<string>('concat', ...strings);
  }

  /**
   * 转大写
   */
  public static upcase(input: ExpressionBuilder<string>): ExpressionBuilder<string>;

  /**
   * 转大写（字符串参数）
   */
  public static upcase(input: string): ExpressionBuilder<string>;

  /**
   * 转大写的实现
   */
  public static upcase(input: ExpressionBuilder<string> | string): ExpressionBuilder<string> {
    const inputExpr = typeof input === 'string' ? Expression.literal(input) : input;
    return new ExpressionBuilder<string>('upcase', inputExpr);
  }

  /**
   * 转小写
   */
  public static downcase(input: ExpressionBuilder<string>): ExpressionBuilder<string>;

  /**
   * 转小写（字符串参数）
   */
  public static downcase(input: string): ExpressionBuilder<string>;

  /**
   * 转小写的实现
   */
  public static downcase(input: ExpressionBuilder<string> | string): ExpressionBuilder<string> {
    const inputExpr = typeof input === 'string' ? Expression.literal(input) : input;
    return new ExpressionBuilder<string>('downcase', inputExpr);
  }

  // ==================== 类型转换操作符 ====================

  /**
   * 转换为字符串
   */
  public static toString(value: Expression): ExpressionBuilder<string> {
    return new ExpressionBuilder<string>('to-string', value);
  }

  /**
   * 转换为数字
   */
  public static toNumber(value: Expression): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('to-number', value);
  }

  /**
   * 转换为布尔值
   */
  public static toBoolean(value: Expression): ExpressionBuilder<boolean> {
    return new ExpressionBuilder<boolean>('to-boolean', value);
  }

  /**
   * 转换为颜色
   */
  public static toColor(value: Expression): ExpressionBuilder<string> {
    return new ExpressionBuilder<string>('to-color', value);
  }

  /**
   * 获取值的类型
   */
  public static typeof(value: Expression): ExpressionBuilder<string> {
    return new ExpressionBuilder<string>('typeof', value);
  }

  /**
   * 断言为数组类型
   */
  public static array(value: Expression): ExpressionBuilder<Object[]> {
    return new ExpressionBuilder<Object[]>('array', value);
  }

  /**
   * 断言为字符串类型
   */
  public static string(value: Expression): ExpressionBuilder<string> {
    return new ExpressionBuilder<string>('string', value);
  }

  /**
   * 断言为数字类型
   */
  public static number(value: Expression): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('number', value);
  }

  /**
   * 断言为布尔类型
   */
  public static boolean(value: Expression): ExpressionBuilder<boolean> {
    return new ExpressionBuilder<boolean>('boolean', value);
  }

  /**
   * 断言为对象类型
   */
  public static object(value: Expression): ExpressionBuilder<Object> {
    return new ExpressionBuilder<Object>('object', value);
  }

  // ==================== 相机操作符 ====================

  /**
   * 获取当前缩放级别
   */
  public static zoom(): ExpressionBuilder<number> {
    return new ExpressionBuilder<number>('zoom');
  }

  // ==================== 插值和阶梯表达式 ====================

  /**
   * 插值表达式
   * 
   * 通过在输入和输出对之间进行插值来生成连续、平滑的结果
   * 
   * @param interpolator 插值器（linear、exponential 或 cubicBezier）
   * @param input 输入表达式（通常是 zoom()）
   * @param stops 停靠点（Expression 数组，格式为 [input1, output1, input2, output2, ...]）
   */
  public static interpolate(interpolator: Expression, input: ExpressionBuilder<number>, ...stops: ExpressionBuilder[]): Expression {
    return new Expression('interpolate', ...Expression.join([interpolator, input], stops));
  }

  /**
   * 阶梯表达式
   * 
   * 根据输入值选择离散的输出值
   * 
   * @param input 输入表达式
   * @param defaultOutput 默认输出值
   * @param stops 停靠点（Expression 数组，格式为 [input1, output1, input2, output2, ...]）
   */
  public static step(input: ExpressionBuilder<number>, defaultOutput: Expression, ...stops: ExpressionBuilder[]): Expression;

  /**
   * 阶梯表达式（数字输入）
   */
  public static step(input: number, defaultOutput: Expression, ...stops: ExpressionBuilder[]): Expression;

  /**
   * 阶梯表达式（数字默认输出）
   */
  public static step(input: ExpressionBuilder<number>, defaultOutput: number, ...stops: ExpressionBuilder[]): Expression;

  /**
   * 阶梯表达式（数字输入和默认输出）
   */
  public static step(input: number, defaultOutput: number, ...stops: ExpressionBuilder[]): Expression;

  /**
   * 阶梯表达式的实现
   */
  public static step(
    input: ExpressionBuilder<number> | number,
    defaultOutput: Expression | number,
    ...stops: ExpressionBuilder[]
  ): Expression {
    const inputExpr = typeof input === 'number' ? Expression.literal(input) : input;
    const defaultExpr = typeof defaultOutput === 'number' ? Expression.literal(defaultOutput) : defaultOutput;
    return new Expression('step', ...Expression.join([inputExpr, defaultExpr], stops));
  }

  // ==================== 格式化表达式 ====================

  /**
   * 格式化文本表达式
   * 
   * @param entries 格式化入口数组
   */
  public static format(...entries: ExpressionBuilder[]): ExpressionBuilder<string> {
    return new ExpressionBuilder<string>('format', ...entries);
  }

  /**
   * 数字格式化表达式
   * 
   * @param number 要格式化的数字
   * @param options 格式化选项
   */
  public static numberFormat(number: ExpressionBuilder<number>, ...options: ExpressionBuilder[]): ExpressionBuilder<string>;

  /**
   * 数字格式化表达式（数字参数）
   */
  public static numberFormat(number: number, ...options: ExpressionBuilder[]): ExpressionBuilder<string>;

  /**
   * 数字格式化表达式的实现
   */
  public static numberFormat(
    number: ExpressionBuilder<number> | number,
    ...options: ExpressionBuilder[]
  ): ExpressionBuilder<string> {
    const numberExpr = typeof number === 'number' ? Expression.literal(number) : number;
    return new ExpressionBuilder<string>('number-format', ...[numberExpr, ...options]);
  }

  /**
   * 图像表达式
   * 
   * @param imageName 图像名称
   */
  public static image(imageName: ExpressionBuilder<string>): Expression;

  /**
   * 图像表达式（字符串参数）
   */
  public static image(imageName: string): Expression;

  /**
   * 图像表达式的实现
   */
  public static image(imageName: ExpressionBuilder<string> | string): Expression {
    const imageNameExpr = typeof imageName === 'string' ? Expression.literal(imageName) : imageName;
    return new Expression('image', imageNameExpr);
  }

  // ==================== 空间操作符 ====================

  /**
   * 计算到 GeoJSON 几何体的距离（米）
   */
  public static distance(geoJson: Object): ExpressionBuilder<number> {
    const map = new Map<string, Expression>();
    map.set('json', Expression.literal(JSON.stringify(geoJson)));
    return new ExpressionBuilder<number>('distance', new ExpressionMap(map));
  }

  /**
   * 判断要素是否在多边形内
   */
  public static within(polygon: Object): ExpressionBuilder<boolean> {
    const map = new Map<string, Expression>();
    const polyObj = polygon as Record<string, Object>;
    map.set('type', Expression.literal(polyObj['type']));
    map.set('json', Expression.literal(JSON.stringify(polygon)));
    return new ExpressionBuilder<boolean>('within', new ExpressionMap(map));
  }

  // ==================== 辅助方法 ====================

  /**
   * 连接两个数组
   */
  protected static join(array1: ExpressionBuilder[], array2: ExpressionBuilder[]): ExpressionBuilder[] {
    const result: ExpressionBuilder[] = [];
    for (const item of array1) {
      result.push(item);
    }
    for (const item of array2) {
      result.push(item);
    }
    return result;
  }

  // ==================== Expression Converter ====================

  /**
   * 从 JSON 数组转换为 Expression
   * 
   * @param json JSON 数组或值
   * @return Expression 对象
   */
  public static convertFromJson(json: Object | null): Expression | null {
    if (json === null || json === undefined) {
      return null;
    }

    // 字面量值
    if (typeof json === 'number' || typeof json === 'string' || typeof json === 'boolean') {
      return Expression.literal(json);
    }

    // 数组表达式
    if (Array.isArray(json)) {
      if (json.length === 0) {
        return Expression.literal([]);
      }

      const operator = json[0] as string;
      
      // 特殊处理 literal 操作符
      if (operator === 'literal') {
        if (json.length === 2) {
          return Expression.literal(json[1]);
        }
      }

      // 递归转换参数
      const args: ExpressionBuilder[] = [];
      for (let i = 1; i < json.length; i++) {
        const converted = Expression.convertFromJson(json[i]);
        if (converted !== null) {
          args.push(converted);
        }
      }

      // 根据操作符创建 Expression
      return new Expression(operator, ...args);
    }

    // 对象（用于 format, collator 等）
    if (typeof json === 'object') {
      return Expression.literal(json);
    }

    return null;
  }

  /**
   * 从 JSON 字符串转换为 Expression
   * 
   * @param jsonString JSON 字符串
   * @return Expression 对象
   */
  public static fromJsonString(jsonString: string): Expression | null {
    try {
      const json: Object = JSON.parse(jsonString);
      return Expression.convertFromJson(json);
    } catch (e) {
      console.error(`Failed to parse Expression from JSON: ${e}`);
      return null;
    }
  }
}

/**
 * ExpressionLiteral - 字面量表达式
 */
export class ExpressionLiteral extends ExpressionBuilder implements ValueExpression {
  private literal: ExpressionValue;

  constructor(literal: ExpressionValue) {
    super('literal');
    this.literal = literal;
  }

  /**
   * 覆盖父类方法，标识这是一个值表达式
   */
  isValue(): boolean {
    return true;
  }

  public toValue(): Object | null {
    if (this.literal instanceof ExpressionBuilderLiteral) {
      return (this.literal as ExpressionLiteral).toValue();
    }
    return this.literal;
  }

  public toArray(): (Object | null)[] {
    if (typeof this.literal === 'string') {
      // 字符串字面量直接返回值，不需要 ["literal", "value"] 格式
      const unwrapped = this.unwrapStringLiteral(this.literal);
      if (unwrapped === this.literal) {
        return ['literal', this.literal];
      }
      return [unwrapped];
    }
    if (typeof this.literal === 'number' || typeof this.literal === 'boolean' || this.literal === null) {
      // 数字、布尔值和 null 可以直接作为字面量
      return [this.literal as (Object | null)];
    }
    return ['literal', this.literal];
  }

  public equals(other: ExpressionBuilder | null): boolean {
    if (!(other instanceof ExpressionBuilderLiteral)) {
      return false;
    }
    return this.literal === (other as ExpressionLiteral).literal;
  }

  public hashCode(): number {
    let result = super.hashCode();
    if (this.literal !== null) {
      result = 31 * result + (typeof this.literal === 'string' ? this.literal.length : 0);
    }
    return result;
  }

  private unwrapStringLiteral(value: string): string {
    if (value.length > 1 && value.charAt(0) === '"' && value.charAt(value.length - 1) === '"') {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}

/**
 * ExpressionLiteralArray - 数组字面量表达式
 */
export class ExpressionLiteralArray extends ExpressionLiteral {
  private array: (Object | null)[];

  constructor(array: (Object | null)[]) {
    super(array as Object);
    this.array = array;
  }

  public toArray(): (Object | null)[] {
    return ['literal', this.array as Object];
  }

  public toValue(): Object | null {
    return this.array as Object;
  }
}

/**
 * ExpressionMap - Map 表达式（用于 within 和 distance 等操作符）
 */
export class ExpressionMap extends ExpressionBuilder implements ValueExpression {
  private map: Map<string, ExpressionBuilder>;

  constructor(map: Map<string, ExpressionBuilder>) {
    super('map');
    this.map = map;
  }

  public toValue(): Object | null {
    const unwrappedMap: Record<string, Object | null> = {};
    this.map.forEach((value: ExpressionBuilder, key: string) => {
      if (value.isValue()) {
        // 使用虚方法判断，然后安全转换
        unwrappedMap[key] = (value as ExpressionLiteral).toValue();
      } else {
        unwrappedMap[key] = value.toArray() as Object;
      }
    });
    return unwrappedMap;
  }

  public toArray(): (Object | null)[] {
    return [this.toValue()];
  }
}

