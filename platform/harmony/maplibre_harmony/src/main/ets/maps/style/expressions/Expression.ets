/**
 * Expression - MapLibre 表达式系统核心类
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

export class Expression<T = any> {
  protected operator: string;
  protected arguments: Expression[] | null;

  /**
   * 创建一个表达式
   * 
   * @param operator 表达式运算符
   * @param args 表达式参数
   */
  constructor(operator: string, ...args: Expression[]) {
    this.operator = operator;
    this.arguments = args.length > 0 ? args : null;
  }

  /**
   * 获取运算符
   */
  public getOperator(): string {
    return this.operator;
  }

  /**
   * 获取参数
   */
  public getArguments(): Expression[] | null {
    return this.arguments;
  }

  /**
   * 将表达式转换为 JSON 数组格式
   * 这是 MapLibre Style Spec 要求的格式
   */
  public toArray(): Object[] {
    const array: Object[] = [this.operator];
    if (this.arguments !== null && this.arguments.length > 0) {
      for (const arg of this.arguments) {
        if (this.isValueExpression(arg)) {
          array.push((arg as any as ValueExpression).toValue());
        } else {
          array.push(arg.toArray());
        }
      }
    }
    return array;
  }

  /**
   * 检查是否为 ValueExpression
   */
  protected isValueExpression(expr: Expression): boolean {
    return typeof (expr as any).toValue === 'function';
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return JSON.stringify(this.toArray());
  }

  /**
   * 比较两个表达式是否相等
   */
  public equals(other: Expression | null): boolean {
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
  public static literal(value: number): Expression<number>;
  
  /**
   * 创建一个字符串字面量表达式
   */
  public static literal(value: string): Expression<string>;
  
  /**
   * 创建一个布尔字面量表达式
   */
  public static literal(value: boolean): Expression<boolean>;
  
  /**
   * 创建一个对象字面量表达式
   */
  public static literal(value: Object): Expression<Object>;
  
  /**
   * 创建一个数组字面量表达式
   */
  public static literal(value: Object[]): Expression<Object[]>;
  
  /**
   * 创建一个字面量表达式的实现
   */
  public static literal(value: ExpressionValue): Expression {
    if (Array.isArray(value)) {
      return new ExpressionLiteralArray(value);
    }
    return new ExpressionLiteral(value);
  }

  // ==================== 颜色操作符 ====================

  /**
   * 从整数创建颜色表达式
   * 
   * @param color ARGB 格式的颜色整数
   */
  public static color(color: number): Expression<string> {
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
  public static rgb(red: Expression<number>, green: Expression<number>, blue: Expression<number>): Expression<string> {
    return new Expression<string>('rgb', red, green, blue);
  }

  /**
   * 创建 RGB 颜色表达式（数字参数）
   */
  public static rgb(red: number, green: number, blue: number): Expression<string> {
    return Expression.rgb(Expression.literal(red), Expression.literal(green), Expression.literal(blue));
  }

  /**
   * 创建 RGBA 颜色表达式
   */
  public static rgba(
    red: Expression<number>,
    green: Expression<number>,
    blue: Expression<number>,
    alpha: Expression<number>
  ): Expression<string> {
    return new Expression<string>('rgba', red, green, blue, alpha);
  }

  /**
   * 创建 RGBA 颜色表达式（数字参数）
   */
  public static rgba(red: number, green: number, blue: number, alpha: number): Expression<string> {
    return Expression.rgba(
      Expression.literal(red),
      Expression.literal(green),
      Expression.literal(blue),
      Expression.literal(alpha)
    );
  }

  /**
   * 将颜色转换为 RGBA 数组表达式
   */
  public static toRgba(color: Expression): Expression<number[]> {
    return new Expression<number[]>('to-rgba', color);
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
  public static get<T = any>(key: Expression<string>): Expression<T> {
    return new Expression<T>('get', key);
  }

  /**
   * 从当前要素的属性中获取指定键的值
   * 
   * @param key 属性键（字符串）
   */
  public static get<T = any>(key: string): Expression<T> {
    return Expression.get(Expression.literal(key));
  }

  /**
   * 从对象中获取指定键的值
   * 
   * @param key 属性键（Expression）
   * @param object 对象表达式
   */
  public static get<T = any>(key: Expression<string>, object: Expression<Object>): Expression<T> {
    return new Expression<T>('get', key, object);
  }

  /**
   * 从对象中获取指定键的值
   * 
   * @param key 属性键（字符串）
   * @param object 对象表达式
   */
  public static get<T = any>(key: string, object: Expression<Object>): Expression<T> {
    return Expression.get(Expression.literal(key), object);
  }

  /**
   * 检查当前要素是否具有指定的属性
   * 
   * @param key 属性键（Expression）
   */
  public static has(key: Expression<string>): Expression<boolean> {
    return new Expression<boolean>('has', key);
  }

  /**
   * 检查当前要素是否具有指定的属性
   * 
   * @param key 属性键（字符串）
   */
  public static has(key: string): Expression<boolean> {
    return Expression.has(Expression.literal(key));
  }

  /**
   * 检查对象是否具有指定的属性
   * 
   * @param key 属性键（Expression）
   * @param object 对象表达式
   */
  public static has(key: Expression<string>, object: Expression<Object>): Expression<boolean> {
    return new Expression<boolean>('has', key, object);
  }

  /**
   * 检查对象是否具有指定的属性
   * 
   * @param key 属性键（字符串）
   * @param object 对象表达式
   */
  public static has(key: string, object: Expression<Object>): Expression<boolean> {
    return Expression.has(Expression.literal(key), object);
  }

  /**
   * 获取当前要素的所有属性
   */
  public static properties(): Expression<Object> {
    return new Expression<Object>('properties');
  }

  /**
   * 获取当前要素的几何类型
   * 返回值为 "Point", "MultiPoint", "LineString", "MultiLineString", "Polygon", "MultiPolygon"
   */
  public static geometryType(): Expression<string> {
    return new Expression<string>('geometry-type');
  }

  /**
   * 获取当前要素的 ID
   */
  public static id(): Expression<number | string> {
    return new Expression('id');
  }

  /**
   * 获取聚合累积值（用于聚合图层）
   */
  public static accumulated(): Expression<Object> {
    return new Expression<Object>('accumulated');
  }

  /**
   * 获取热力图密度值（仅在热力图图层的 heatmap-color 属性中可用）
   */
  public static heatmapDensity(): Expression<number> {
    return new Expression<number>('heatmap-density');
  }

  /**
   * 获取线条进度值（仅在线条图层的渐变属性中可用）
   */
  public static lineProgress(): Expression<number> {
    return new Expression<number>('line-progress');
  }

  // ==================== 数组和对象操作符 ====================

  /**
   * 从数组中获取指定索引的元素
   * 
   * @param index 索引（Expression）
   * @param array 数组表达式
   */
  public static at<T = any>(index: Expression<number>, array: Expression<T[]>): Expression<T> {
    return new Expression<T>('at', index, array);
  }

  /**
   * 从数组中获取指定索引的元素
   * 
   * @param index 索引（数字）
   * @param array 数组表达式
   */
  public static at<T = any>(index: number, array: Expression<T[]>): Expression<T> {
    return Expression.at(Expression.literal(index), array);
  }

  /**
   * 检查值是否在数组或字符串中
   * 
   * @param needle 要查找的值
   * @param haystack 数组或字符串
   */
  public static in(needle: Expression, haystack: Expression): Expression<boolean> {
    return new Expression<boolean>('in', needle, haystack);
  }

  /**
   * 检查数字是否在数组中
   */
  public static in(needle: number, haystack: Expression): Expression<boolean> {
    return Expression.in(Expression.literal(needle), haystack);
  }

  /**
   * 检查字符串是否在数组或字符串中
   */
  public static in(needle: string, haystack: Expression): Expression<boolean> {
    return Expression.in(Expression.literal(needle), haystack);
  }

  /**
   * 查找值在数组或字符串中的索引
   * 
   * @param keyword 要查找的值
   * @param input 数组或字符串
   */
  public static indexOf(keyword: Expression, input: Expression): Expression<number> {
    return new Expression<number>('index-of', keyword, input);
  }

  /**
   * 从指定位置开始查找值在数组或字符串中的索引
   * 
   * @param keyword 要查找的值
   * @param input 数组或字符串
   * @param fromIndex 开始位置
   */
  public static indexOf(keyword: Expression, input: Expression, fromIndex: Expression<number>): Expression<number> {
    return new Expression<number>('index-of', keyword, input, fromIndex);
  }

  /**
   * 数组或字符串切片
   * 
   * @param input 数组或字符串
   * @param fromIndex 开始位置
   */
  public static slice<T = any>(input: Expression<T[] | string>, fromIndex: Expression<number>): Expression<T[] | string> {
    return new Expression('slice', input, fromIndex);
  }

  /**
   * 数组或字符串切片（指定范围）
   * 
   * @param input 数组或字符串
   * @param fromIndex 开始位置
   * @param toIndex 结束位置
   */
  public static slice<T = any>(
    input: Expression<T[] | string>,
    fromIndex: Expression<number>,
    toIndex: Expression<number>
  ): Expression<T[] | string> {
    return new Expression('slice', input, fromIndex, toIndex);
  }

  /**
   * 获取数组或字符串的长度
   */
  public static length(input: Expression<any[] | string>): Expression<number> {
    return new Expression<number>('length', input);
  }

  // ==================== 比较操作符 ====================

  /**
   * 等于比较（Expression）
   */
  public static eq(compareOne: Expression, compareTwo: Expression): Expression<boolean> {
    return new Expression<boolean>('==', compareOne, compareTwo);
  }

  /**
   * 等于比较（Expression 和布尔值）
   */
  public static eq(compareOne: Expression, compareTwo: boolean): Expression<boolean> {
    return Expression.eq(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 等于比较（Expression 和字符串）
   */
  public static eq(compareOne: Expression, compareTwo: string): Expression<boolean> {
    return Expression.eq(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 等于比较（Expression 和数字）
   */
  public static eq(compareOne: Expression, compareTwo: number): Expression<boolean> {
    return Expression.eq(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 不等于比较（Expression）
   */
  public static neq(compareOne: Expression, compareTwo: Expression): Expression<boolean> {
    return new Expression<boolean>('!=', compareOne, compareTwo);
  }

  /**
   * 不等于比较（Expression 和布尔值）
   */
  public static neq(compareOne: Expression, compareTwo: boolean): Expression<boolean> {
    return Expression.neq(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 不等于比较（Expression 和字符串）
   */
  public static neq(compareOne: Expression, compareTwo: string): Expression<boolean> {
    return Expression.neq(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 不等于比较（Expression 和数字）
   */
  public static neq(compareOne: Expression, compareTwo: number): Expression<boolean> {
    return Expression.neq(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 大于比较（Expression）
   */
  public static gt(compareOne: Expression, compareTwo: Expression): Expression<boolean> {
    return new Expression<boolean>('>', compareOne, compareTwo);
  }

  /**
   * 大于比较（Expression 和数字）
   */
  public static gt(compareOne: Expression, compareTwo: number): Expression<boolean> {
    return Expression.gt(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 大于比较（Expression 和字符串）
   */
  public static gt(compareOne: Expression, compareTwo: string): Expression<boolean> {
    return Expression.gt(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 小于比较（Expression）
   */
  public static lt(compareOne: Expression, compareTwo: Expression): Expression<boolean> {
    return new Expression<boolean>('<', compareOne, compareTwo);
  }

  /**
   * 小于比较（Expression 和数字）
   */
  public static lt(compareOne: Expression, compareTwo: number): Expression<boolean> {
    return Expression.lt(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 小于比较（Expression 和字符串）
   */
  public static lt(compareOne: Expression, compareTwo: string): Expression<boolean> {
    return Expression.lt(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 大于等于比较（Expression）
   */
  public static gte(compareOne: Expression, compareTwo: Expression): Expression<boolean> {
    return new Expression<boolean>('>=', compareOne, compareTwo);
  }

  /**
   * 大于等于比较（Expression 和数字）
   */
  public static gte(compareOne: Expression, compareTwo: number): Expression<boolean> {
    return Expression.gte(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 大于等于比较（Expression 和字符串）
   */
  public static gte(compareOne: Expression, compareTwo: string): Expression<boolean> {
    return Expression.gte(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 小于等于比较（Expression）
   */
  public static lte(compareOne: Expression, compareTwo: Expression): Expression<boolean> {
    return new Expression<boolean>('<=', compareOne, compareTwo);
  }

  /**
   * 小于等于比较（Expression 和数字）
   */
  public static lte(compareOne: Expression, compareTwo: number): Expression<boolean> {
    return Expression.lte(compareOne, Expression.literal(compareTwo));
  }

  /**
   * 小于等于比较（Expression 和字符串）
   */
  public static lte(compareOne: Expression, compareTwo: string): Expression<boolean> {
    return Expression.lte(compareOne, Expression.literal(compareTwo));
  }

  // ==================== 逻辑操作符 ====================

  /**
   * 逻辑与（所有条件都为真）
   */
  public static all(...expressions: Expression<boolean>[]): Expression<boolean> {
    return new Expression<boolean>('all', ...expressions);
  }

  /**
   * 逻辑或（任一条件为真）
   */
  public static any(...expressions: Expression<boolean>[]): Expression<boolean> {
    return new Expression<boolean>('any', ...expressions);
  }

  /**
   * 逻辑非
   */
  public static not(input: Expression<boolean>): Expression<boolean> {
    return new Expression<boolean>('!', input);
  }

  /**
   * 逻辑非（布尔值）
   */
  public static not(input: boolean): Expression<boolean> {
    return Expression.not(Expression.literal(input));
  }

  // ==================== 条件操作符 ====================

  /**
   * Switch-case 条件表达式
   * 格式：case(condition1, output1, condition2, output2, ..., fallback)
   */
  public static switchCase(...expressions: Expression[]): Expression {
    return new Expression('case', ...expressions);
  }

  /**
   * Match 表达式 - 匹配输入值并返回对应的输出
   * 格式：match(input, label1, output1, label2, output2, ..., fallback)
   */
  public static match(...expressions: Expression[]): Expression {
    return new Expression('match', ...expressions);
  }

  /**
   * Coalesce 表达式 - 返回第一个非空值
   */
  public static coalesce(...expressions: Expression[]): Expression {
    return new Expression('coalesce', ...expressions);
  }

  // ==================== 算术运算操作符 ====================

  /**
   * 加法运算
   */
  public static add(...expressions: Expression<number>[]): Expression<number> {
    return new Expression<number>('+', ...expressions);
  }

  /**
   * 减法运算（二元）
   */
  public static subtract(first: Expression<number>, second: Expression<number>): Expression<number> {
    return new Expression<number>('-', first, second);
  }

  /**
   * 减法运算（二元，数字参数）
   */
  public static subtract(first: number, second: number): Expression<number> {
    return Expression.subtract(Expression.literal(first), Expression.literal(second));
  }

  /**
   * 取负（一元）
   */
  public static subtract(value: Expression<number>): Expression<number> {
    return new Expression<number>('-', value);
  }

  /**
   * 取负（一元，数字参数）
   */
  public static subtract(value: number): Expression<number> {
    return Expression.subtract(Expression.literal(value));
  }

  /**
   * 乘法运算
   */
  public static multiply(...expressions: Expression<number>[]): Expression<number> {
    return new Expression<number>('*', ...expressions);
  }

  /**
   * 除法运算
   */
  public static divide(first: Expression<number>, second: Expression<number>): Expression<number> {
    return new Expression<number>('/', first, second);
  }

  /**
   * 除法运算（数字参数）
   */
  public static divide(first: number, second: number): Expression<number> {
    return Expression.divide(Expression.literal(first), Expression.literal(second));
  }

  /**
   * 取模运算
   */
  public static mod(first: Expression<number>, second: Expression<number>): Expression<number> {
    return new Expression<number>('%', first, second);
  }

  /**
   * 取模运算（数字参数）
   */
  public static mod(first: number, second: number): Expression<number> {
    return Expression.mod(Expression.literal(first), Expression.literal(second));
  }

  /**
   * 幂运算
   */
  public static pow(base: Expression<number>, exponent: Expression<number>): Expression<number> {
    return new Expression<number>('^', base, exponent);
  }

  /**
   * 幂运算（数字参数）
   */
  public static pow(base: number, exponent: number): Expression<number> {
    return Expression.pow(Expression.literal(base), Expression.literal(exponent));
  }

  // ==================== 数学函数 ====================

  /**
   * 平方根
   */
  public static sqrt(value: Expression<number>): Expression<number> {
    return new Expression<number>('sqrt', value);
  }

  /**
   * 平方根（数字参数）
   */
  public static sqrt(value: number): Expression<number> {
    return Expression.sqrt(Expression.literal(value));
  }

  /**
   * 以 10 为底的对数
   */
  public static log10(value: Expression<number>): Expression<number> {
    return new Expression<number>('log10', value);
  }

  /**
   * 以 10 为底的对数（数字参数）
   */
  public static log10(value: number): Expression<number> {
    return Expression.log10(Expression.literal(value));
  }

  /**
   * 以 2 为底的对数
   */
  public static log2(value: Expression<number>): Expression<number> {
    return new Expression<number>('log2', value);
  }

  /**
   * 以 2 为底的对数（数字参数）
   */
  public static log2(value: number): Expression<number> {
    return Expression.log2(Expression.literal(value));
  }

  /**
   * 自然对数
   */
  public static ln(value: Expression<number>): Expression<number> {
    return new Expression<number>('ln', value);
  }

  /**
   * 自然对数（数字参数）
   */
  public static ln(value: number): Expression<number> {
    return Expression.ln(Expression.literal(value));
  }

  /**
   * 绝对值
   */
  public static abs(value: Expression<number>): Expression<number> {
    return new Expression<number>('abs', value);
  }

  /**
   * 绝对值（数字参数）
   */
  public static abs(value: number): Expression<number> {
    return Expression.abs(Expression.literal(value));
  }

  /**
   * 向上取整
   */
  public static ceil(value: Expression<number>): Expression<number> {
    return new Expression<number>('ceil', value);
  }

  /**
   * 向上取整（数字参数）
   */
  public static ceil(value: number): Expression<number> {
    return Expression.ceil(Expression.literal(value));
  }

  /**
   * 向下取整
   */
  public static floor(value: Expression<number>): Expression<number> {
    return new Expression<number>('floor', value);
  }

  /**
   * 向下取整（数字参数）
   */
  public static floor(value: number): Expression<number> {
    return Expression.floor(Expression.literal(value));
  }

  /**
   * 四舍五入
   */
  public static round(value: Expression<number>): Expression<number> {
    return new Expression<number>('round', value);
  }

  /**
   * 四舍五入（数字参数）
   */
  public static round(value: number): Expression<number> {
    return Expression.round(Expression.literal(value));
  }

  /**
   * 最小值
   */
  public static min(...values: Expression<number>[]): Expression<number> {
    return new Expression<number>('min', ...values);
  }

  /**
   * 最大值
   */
  public static max(...values: Expression<number>[]): Expression<number> {
    return new Expression<number>('max', ...values);
  }

  /**
   * 正弦函数
   */
  public static sin(value: Expression<number>): Expression<number> {
    return new Expression<number>('sin', value);
  }

  /**
   * 余弦函数
   */
  public static cos(value: Expression<number>): Expression<number> {
    return new Expression<number>('cos', value);
  }

  /**
   * 正切函数
   */
  public static tan(value: Expression<number>): Expression<number> {
    return new Expression<number>('tan', value);
  }

  /**
   * 反正弦函数
   */
  public static asin(value: Expression<number>): Expression<number> {
    return new Expression<number>('asin', value);
  }

  /**
   * 反余弦函数
   */
  public static acos(value: Expression<number>): Expression<number> {
    return new Expression<number>('acos', value);
  }

  /**
   * 反正切函数
   */
  public static atan(value: Expression<number>): Expression<number> {
    return new Expression<number>('atan', value);
  }

  /**
   * 自然常数 e
   */
  public static e(): Expression<number> {
    return new Expression<number>('e');
  }

  /**
   * 圆周率 π
   */
  public static pi(): Expression<number> {
    return new Expression<number>('pi');
  }

  // ==================== 字符串操作符 ====================

  /**
   * 字符串连接
   */
  public static concat(...strings: Expression<string>[]): Expression<string> {
    return new Expression<string>('concat', ...strings);
  }

  /**
   * 转大写
   */
  public static upcase(input: Expression<string>): Expression<string> {
    return new Expression<string>('upcase', input);
  }

  /**
   * 转大写（字符串参数）
   */
  public static upcase(input: string): Expression<string> {
    return Expression.upcase(Expression.literal(input));
  }

  /**
   * 转小写
   */
  public static downcase(input: Expression<string>): Expression<string> {
    return new Expression<string>('downcase', input);
  }

  /**
   * 转小写（字符串参数）
   */
  public static downcase(input: string): Expression<string> {
    return Expression.downcase(Expression.literal(input));
  }

  // ==================== 类型转换操作符 ====================

  /**
   * 转换为字符串
   */
  public static toString(value: Expression): Expression<string> {
    return new Expression<string>('to-string', value);
  }

  /**
   * 转换为数字
   */
  public static toNumber(value: Expression): Expression<number> {
    return new Expression<number>('to-number', value);
  }

  /**
   * 转换为布尔值
   */
  public static toBoolean(value: Expression): Expression<boolean> {
    return new Expression<boolean>('to-boolean', value);
  }

  /**
   * 转换为颜色
   */
  public static toColor(value: Expression): Expression<string> {
    return new Expression<string>('to-color', value);
  }

  /**
   * 获取值的类型
   */
  public static typeof(value: Expression): Expression<string> {
    return new Expression<string>('typeof', value);
  }

  /**
   * 断言为数组类型
   */
  public static array(value: Expression): Expression<any[]> {
    return new Expression<any[]>('array', value);
  }

  /**
   * 断言为字符串类型
   */
  public static string(value: Expression): Expression<string> {
    return new Expression<string>('string', value);
  }

  /**
   * 断言为数字类型
   */
  public static number(value: Expression): Expression<number> {
    return new Expression<number>('number', value);
  }

  /**
   * 断言为布尔类型
   */
  public static boolean(value: Expression): Expression<boolean> {
    return new Expression<boolean>('boolean', value);
  }

  /**
   * 断言为对象类型
   */
  public static object(value: Expression): Expression<Object> {
    return new Expression<Object>('object', value);
  }

  // ==================== 相机操作符 ====================

  /**
   * 获取当前缩放级别
   */
  public static zoom(): Expression<number> {
    return new Expression<number>('zoom');
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
  public static interpolate(interpolator: Expression, input: Expression<number>, ...stops: Expression[]): Expression {
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
  public static step(input: Expression<number>, defaultOutput: Expression, ...stops: Expression[]): Expression {
    return new Expression('step', ...Expression.join([input, defaultOutput], stops));
  }

  /**
   * 阶梯表达式（数字输入）
   */
  public static step(input: number, defaultOutput: Expression, ...stops: Expression[]): Expression {
    return Expression.step(Expression.literal(input), defaultOutput, ...stops);
  }

  /**
   * 阶梯表达式（数字默认输出）
   */
  public static step(input: Expression<number>, defaultOutput: number, ...stops: Expression[]): Expression {
    return Expression.step(input, Expression.literal(defaultOutput), ...stops);
  }

  /**
   * 阶梯表达式（数字输入和默认输出）
   */
  public static step(input: number, defaultOutput: number, ...stops: Expression[]): Expression {
    return Expression.step(Expression.literal(input), Expression.literal(defaultOutput), ...stops);
  }

  // ==================== 格式化表达式 ====================

  /**
   * 格式化文本表达式
   * 
   * @param entries 格式化入口数组
   */
  public static format(...entries: Expression[]): Expression<string> {
    return new Expression<string>('format', ...entries);
  }

  /**
   * 数字格式化表达式
   * 
   * @param number 要格式化的数字
   * @param options 格式化选项
   */
  public static numberFormat(number: Expression<number>, ...options: Expression[]): Expression<string> {
    return new Expression<string>('number-format', ...[number, ...options]);
  }

  /**
   * 数字格式化表达式（数字参数）
   */
  public static numberFormat(number: number, ...options: Expression[]): Expression<string> {
    return Expression.numberFormat(Expression.literal(number), ...options);
  }

  /**
   * 图像表达式
   * 
   * @param imageName 图像名称
   */
  public static image(imageName: Expression<string>): Expression {
    return new Expression('image', imageName);
  }

  /**
   * 图像表达式（字符串参数）
   */
  public static image(imageName: string): Expression {
    return Expression.image(Expression.literal(imageName));
  }

  // ==================== 空间操作符 ====================

  /**
   * 计算到 GeoJSON 几何体的距离（米）
   */
  public static distance(geoJson: Object): Expression<number> {
    const map = new Map<string, Expression>();
    map.set('json', Expression.literal(JSON.stringify(geoJson)));
    return new Expression<number>('distance', new ExpressionMap(map));
  }

  /**
   * 判断要素是否在多边形内
   */
  public static within(polygon: Object): Expression<boolean> {
    const map = new Map<string, Expression>();
    map.set('type', Expression.literal((polygon as any).type));
    map.set('json', Expression.literal(JSON.stringify(polygon)));
    return new Expression<boolean>('within', new ExpressionMap(map));
  }

  // ==================== 辅助方法 ====================

  /**
   * 连接两个数组
   */
  protected static join(array1: Expression[], array2: Expression[]): Expression[] {
    const result: Expression[] = [];
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
   * Converter - 从 JSON 转换为 Expression
   */
  public static Converter = class {
    /**
     * 从 JSON 数组转换为 Expression
     * 
     * @param json JSON 数组或值
     * @return Expression 对象
     */
    public static convert(json: any): Expression | null {
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

        const operator = json[0];
        
        // 特殊处理 literal 操作符
        if (operator === 'literal') {
          if (json.length === 2) {
            return Expression.literal(json[1]);
          }
        }

        // 递归转换参数
        const args: Expression[] = [];
        for (let i = 1; i < json.length; i++) {
          const converted = this.convert(json[i]);
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
    public static fromString(jsonString: string): Expression | null {
      try {
        const json = JSON.parse(jsonString);
        return this.convert(json);
      } catch (e) {
        console.error(`Failed to parse Expression from JSON: ${e}`);
        return null;
      }
    }
  };
}

/**
 * ExpressionLiteral - 字面量表达式
 */
export class ExpressionLiteral extends Expression implements ValueExpression {
  private literal: ExpressionValue;

  constructor(literal: ExpressionValue) {
    super('literal');
    this.literal = literal;
  }

  public toValue(): Object | null {
    if (this.literal instanceof ExpressionLiteral) {
      return (this.literal as ExpressionLiteral).toValue();
    }
    return this.literal;
  }

  public toArray(): Object[] {
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
      return [this.literal];
    }
    return ['literal', this.literal];
  }

  public equals(other: Expression | null): boolean {
    if (!(other instanceof ExpressionLiteral)) {
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
  private array: Object[];

  constructor(array: Object[]) {
    super(array);
    this.array = array;
  }

  public toArray(): Object[] {
    return ['literal', this.array];
  }

  public toValue(): Object | null {
    return this.array;
  }
}

/**
 * ExpressionMap - Map 表达式（用于 within 和 distance 等操作符）
 */
export class ExpressionMap extends Expression implements ValueExpression {
  private map: Map<string, Expression>;

  constructor(map: Map<string, Expression>) {
    super('map');
    this.map = map;
  }

  public toValue(): Object | null {
    const unwrappedMap: Record<string, Object | null> = {};
    this.map.forEach((value: Expression, key: string) => {
      if (this.isValueExpression(value)) {
        unwrappedMap[key] = (value as any as ValueExpression).toValue();
      } else {
        unwrappedMap[key] = value.toArray();
      }
    });
    return unwrappedMap;
  }

  public toArray(): Object[] {
    return [this.toValue()];
  }
}

