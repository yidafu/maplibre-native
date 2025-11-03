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

import type {
  ExpressionValue,
  ExpressionLiteral as NativeExpressionLiteral,
  PropertyValue as NativePropertyValue
} from 'libmaplibre.so';

/**
 * Expression - MapLibre 表达式类
 *
 * 提供静态工厂方法构建表达式（如 Expression.literal(), Expression.get() 等）
 *
 * 与 Android/iOS 平台保持一致的 API 设计
 *
 * @template T 表达式返回值的类型（可选）
 */
export class Expression<T = Object> {
  protected operator: string | null = null;
  protected arguments: Expression[] | null = null;

  /**
   * 私有构造函数 - 用于内部创建
   * @param operator 操作符字符串
   * @param args 表达式参数
   */
  constructor(operator: string, ...args: Expression[]) {
    this.operator = operator;
    this.arguments = args.length > 0 ? args : null;
  }

  // ==================== 实例方法（getter） ====================

  /**
   * 获取操作符
   */
  public getOperator(): string | null {
    return this.operator;
  }

  /**
   * 获取参数
   */
  public getArguments(): Expression[] | null {
    return this.arguments;
  }

  /**
   * 将表达式序列化为 JSON 数组格式
   * @returns Expression 字面量（JSON 数组）
   */
  serialize(): NativeExpressionLiteral {
    return this.toArray() as NativeExpressionLiteral;
  }

  /**
   * 将表达式转换为 JSON 数组格式
   * @returns Expression 字面量：[operator, ...arguments]
   */
  public toArray(): ExpressionValue[] {
    if (this.operator === null) {
      throw new Error('Invalid expression: operator is null');
    }

    const array: ExpressionValue[] = [this.operator];
    if (this.arguments !== null && this.arguments.length > 0) {
      for (const arg of this.arguments) {
        if (arg instanceof ExpressionLiteral || arg instanceof ExpressionLiteralArray || arg instanceof ExpressionMap) {
          let val = arg.toValue() as ExpressionValue
          if (val !== null) {
            array.push(val);
          }
        } else {
          array.push(arg.toArray() as ExpressionValue);
        }
      }
    }
    return array;
  }

  /**
   * 检查当前表达式是否为值表达式
   * 使用类型守护，在条件分支中自动缩窄类型为 ValueExpression
   */
  isValue(): boolean {
    return false;
  }

  /**
   * 判断两个表达式是否相等
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
    if (this.operator === null) {
      return 0;
    }
    let result = this.operator.length;
    if (this.arguments !== null) {
      result = 31 * result + this.arguments.length;
    }
    return result;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return JSON.stringify(this.toArray());
  }

  /**
   * 辅助方法：判断表达式是否为值表达式
   */
  protected isValueExpression(expr: Expression): boolean {
    return expr.isValue();
  }

  // ==================== 静态工厂方法 ====================
  // 以下是从 ExpressionBuilder 迁移的所有静态方法

  // ==================== 字面量操作符 ====================

  /**
   * 创建数字字面量表达式
   */
  public static literal(value: number): ExpressionLiteral<number>;

  /**
   * 创建字符串字面量表达式
   */
  public static literal(value: string): ExpressionLiteral<string>;

  /**
   * 创建布尔字面量表达式
   */
  public static literal(value: boolean): ExpressionLiteral<boolean>;

  /**
   * 创建数组字面量表达式
   */
  public static literal(value: ExpressionValue[]): ExpressionLiteralArray;

  /**
   * 创建字面量表达式的实现
   */
  public static literal(value: ExpressionValue): ExpressionLiteral | ExpressionLiteralArray {
    if (Array.isArray(value)) {
      return new ExpressionLiteralArray(value as ExpressionValue[]);
    }
    return new ExpressionLiteral(value);
  }

  // ==================== 颜色操作符 ====================

  /**
   * 从整数创建颜色表达式
   *
   * @param color ARGB 格式的颜色整数
   */
  public static color(color: number): Expression {
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
  public static rgb(red: Expression<number>, green: Expression<number>, blue: Expression<number>): Expression<string>;

  /**
   * 创建 RGB 颜色表达式（数字参数）
   */
  public static rgb(red: number, green: number, blue: number): Expression<string>;

  /**
   * 创建 RGB 颜色表达式的实现
   */
  public static rgb(
    red: Expression<number> | number,
    green: Expression<number> | number,
    blue: Expression<number> | number
  ): Expression<string> {
    const redExpr = typeof red === 'number' ? Expression.literal(red) : red;
    const greenExpr = typeof green === 'number' ? Expression.literal(green) : green;
    const blueExpr = typeof blue === 'number' ? Expression.literal(blue) : blue;
    return new Expression<string>('rgb', redExpr, greenExpr, blueExpr);
  }

  /**
   * 创建 RGBA 颜色表达式
   */
  public static rgba(
    red: Expression<number>,
    green: Expression<number>,
    blue: Expression<number>,
    alpha: Expression<number>
  ): Expression<string>;

  /**
   * 创建 RGBA 颜色表达式（数字参数）
   */
  public static rgba(red: number, green: number, blue: number, alpha: number): Expression<string>;

  /**
   * 创建 RGBA 颜色表达式的实现
   */
  public static rgba(
    red: Expression<number> | number,
    green: Expression<number> | number,
    blue: Expression<number> | number,
    alpha: Expression<number> | number
  ): Expression<string> {
    const redExpr = typeof red === 'number' ? Expression.literal(red) : red;
    const greenExpr = typeof green === 'number' ? Expression.literal(green) : green;
    const blueExpr = typeof blue === 'number' ? Expression.literal(blue) : blue;
    const alphaExpr = typeof alpha === 'number' ? Expression.literal(alpha) : alpha;
    return new Expression<string>('rgba', redExpr, greenExpr, blueExpr, alphaExpr);
  }

  /**
   * 将颜色转换为 RGBA 数组表达式
   */
  public static toRgba(color: Expression<string>): Expression<number[]> {
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
  public static get<T = Object>(key: Expression<string>): Expression<T>;

  /**
   * 从当前要素的属性中获取指定键的值
   *
   * @param key 属性键（字符串）
   */
  public static get<T = Object>(key: string): Expression<T>;

  /**
   * 从对象中获取指定键的值
   *
   * @param key 属性键（Expression）
   * @param object 对象表达式
   */
  public static get<T = Object>(key: Expression<string>, object: Expression<Object>): Expression<T>;

  /**
   * 从对象中获取指定键的值
   *
   * @param key 属性键（字符串）
   * @param object 对象表达式
   */
  public static get<T = Object>(key: string, object: Expression<Object>): Expression<T>;

  /**
   * 从要素或对象中获取指定键的值的实现
   */
  public static get<T = Object>(
    key: Expression<string> | string,
    object?: Expression<Object>
  ): Expression<T> {
    const keyExpr = typeof key === 'string' ? Expression.literal(key) : key;
    if (object === undefined) {
      return new Expression<T>('get', keyExpr);
    }
    return new Expression<T>('get', keyExpr, object);
  }

  /**
   * 检查当前要素是否具有指定的属性
   *
   * @param key 属性键（Expression）
   */
  public static has(key: Expression<string>): Expression<boolean>;

  /**
   * 检查当前要素是否具有指定的属性
   *
   * @param key 属性键（字符串）
   */
  public static has(key: string): Expression<boolean>;

  /**
   * 检查对象是否具有指定的属性
   *
   * @param key 属性键（Expression）
   * @param object 对象表达式
   */
  public static has(key: Expression<string>, object: Expression<Object>): Expression<boolean>;

  /**
   * 检查对象是否具有指定的属性
   *
   * @param key 属性键（字符串）
   * @param object 对象表达式
   */
  public static has(key: string, object: Expression<Object>): Expression<boolean>;

  /**
   * 检查要素或对象是否具有指定的属性的实现
   */
  public static has(
    key: Expression<string> | string,
    object?: Expression<Object>
  ): Expression<boolean> {
    const keyExpr = typeof key === 'string' ? Expression.literal(key) : key;
    if (object === undefined) {
      return new Expression<boolean>('has', keyExpr);
    }
    return new Expression<boolean>('has', keyExpr, object);
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
    return new Expression<number | string>('id');
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
  public static at<T = Object>(index: Expression<number>, array: Expression<T[]>): Expression<T>;

  /**
   * 从数组中获取指定索引的元素
   *
   * @param index 索引（数字）
   * @param array 数组表达式
   */
  public static at<T = Object>(index: number, array: Expression<T[]>): Expression<T>;

  /**
   * 从数组中获取指定索引的元素的实现
   */
  public static at<T = Object>(
    index: Expression<number> | number,
    array: Expression<T[]>
  ): Expression<T> {
    const indexExpr = typeof index === 'number' ? Expression.literal(index) : index;
    return new Expression<T>('at', indexExpr, array);
  }

  /**
   * 检查值是否在数组或字符串中
   *
   * @param needle 要查找的值
   * @param haystack 数组或字符串
   */
  public static in(needle: Expression<Object>, haystack: Expression<Object>): Expression<boolean>;

  /**
   * 检查数字是否在数组中
   */
  public static in(needle: number, haystack: Expression<Object>): Expression<boolean>;

  /**
   * 检查字符串是否在数组或字符串中
   */
  public static in(needle: string, haystack: Expression<Object>): Expression<boolean>;

  /**
   * 检查值是否在数组或字符串中的实现
   */
  public static in(
    needle: Expression<Object> | number | string,
    haystack: Expression<Object>
  ): Expression<boolean> {
    let needleExpr: Expression<Object>;
    if (needle instanceof Expression) {
      needleExpr = needle;
    } else if (typeof needle === 'number') {
      needleExpr = Expression.literal(needle);
    } else {
      needleExpr = Expression.literal(needle as string);
    }
    return new Expression<boolean>('in', needleExpr, haystack);
  }

  /**
   * 查找值在数组或字符串中的索引
   *
   * @param keyword 要查找的值
   * @param input 数组或字符串
   */
  public static indexOf(keyword: Expression<Object>, input: Expression<Object>): Expression<number>;

  /**
   * 从指定位置开始查找值在数组或字符串中的索引
   *
   * @param keyword 要查找的值
   * @param input 数组或字符串
   * @param fromIndex 开始位置
   */
  public static indexOf(keyword: Expression<Object>, input: Expression<Object>,
    fromIndex: Expression<number>): Expression<number>;

  /**
   * 查找值在数组或字符串中的索引的实现
   */
  public static indexOf(
    keyword: Expression<Object>,
    input: Expression<Object>,
    fromIndex?: Expression<number>
  ): Expression<number> {
    if (fromIndex === undefined) {
      return new Expression<number>('index-of', keyword, input);
    }
    return new Expression<number>('index-of', keyword, input, fromIndex);
  }

  /**
   * 数组或字符串切片
   *
   * @param input 数组或字符串
   * @param fromIndex 开始位置（Expression）
   */
  public static slice<T = Object>(input: Expression<T[] | string>,
    fromIndex: Expression<number>): Expression<T[] | string>;

  /**
   * 数组或字符串切片
   *
   * @param input 数组或字符串
   * @param fromIndex 开始位置（数字）
   */
  public static slice<T = Object>(input: Expression<T[] | string>, fromIndex: number): Expression<T[] | string>;

  /**
   * 数组或字符串切片（指定范围）
   *
   * @param input 数组或字符串
   * @param fromIndex 开始位置（Expression）
   * @param toIndex 结束位置（Expression）
   */
  public static slice<T = Object>(
    input: Expression<T[] | string>,
    fromIndex: Expression<number>,
    toIndex: Expression<number>
  ): Expression<T[] | string>;

  /**
   * 数组或字符串切片（指定范围）
   *
   * @param input 数组或字符串
   * @param fromIndex 开始位置（数字）
   * @param toIndex 结束位置（数字）
   */
  public static slice<T = Object>(
    input: Expression<T[] | string>,
    fromIndex: number,
    toIndex: number
  ): Expression<T[] | string>;

  /**
   * 数组或字符串切片的实现
   */
  public static slice<T = Object>(
    input: Expression<T[] | string>,
    fromIndex: Expression<number> | number,
    toIndex?: Expression<number> | number
  ): Expression<T[] | string> {
    const fromIndexExpr = typeof fromIndex === 'number' ? Expression.literal(fromIndex) : fromIndex;
    if (toIndex === undefined) {
      return new Expression<T[] | string>('slice', input, fromIndexExpr);
    }
    const toIndexExpr = typeof toIndex === 'number' ? Expression.literal(toIndex) : toIndex;
    return new Expression<T[] | string>('slice', input, fromIndexExpr, toIndexExpr);
  }

  /**
   * 获取数组或字符串的长度
   * 注意：重命名为 len 以避免与 Function.length 冲突
   */
  public static len(input: Expression<Object[] | string>): Expression<number> {
    return new Expression<number>('length', input);
  }

  // ==================== 比较操作符 ====================

  /**
   * 等于比较（Expression）
   */
  public static eq(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * 等于比较（Expression 和布尔值）
   */
  public static eq(compareOne: Expression<Object>, compareTwo: boolean): Expression<boolean>;

  /**
   * 等于比较（Expression 和字符串）
   */
  public static eq(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * 等于比较（Expression 和数字）
   */
  public static eq(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * 等于比较的实现
   */
  public static eq(
    compareOne: Expression<Object>,
    compareTwo: Expression<Object> | boolean | string | number
  ): Expression<boolean> {
    let compareTwoExpr: Expression<Object>;
    if (compareTwo instanceof Expression) {
      compareTwoExpr = compareTwo;
    } else if (typeof compareTwo === 'boolean') {
      compareTwoExpr = Expression.literal(compareTwo);
    } else if (typeof compareTwo === 'number') {
      compareTwoExpr = Expression.literal(compareTwo);
    } else {
      compareTwoExpr = Expression.literal(compareTwo as string);
    }
    return new Expression<boolean>('==', compareOne, compareTwoExpr);
  }

  /**
   * 不等于比较（Expression）
   */
  public static neq(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * 不等于比较（Expression 和布尔值）
   */
  public static neq(compareOne: Expression<Object>, compareTwo: boolean): Expression<boolean>;

  /**
   * 不等于比较（Expression 和字符串）
   */
  public static neq(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * 不等于比较（Expression 和数字）
   */
  public static neq(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * 不等于比较的实现
   */
  public static neq(
    compareOne: Expression<Object>,
    compareTwo: Expression<Object> | boolean | string | number
  ): Expression<boolean> {
    let compareTwoExpr: Expression<Object>;
    if (compareTwo instanceof Expression) {
      compareTwoExpr = compareTwo;
    } else if (typeof compareTwo === 'boolean') {
      compareTwoExpr = Expression.literal(compareTwo);
    } else if (typeof compareTwo === 'number') {
      compareTwoExpr = Expression.literal(compareTwo);
    } else {
      compareTwoExpr = Expression.literal(compareTwo as string);
    }
    return new Expression<boolean>('!=', compareOne, compareTwoExpr);
  }

  /**
   * 大于比较（Expression）
   */
  public static gt(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * 大于比较（Expression 和数字）
   */
  public static gt(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * 大于比较（Expression 和字符串）
   */
  public static gt(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * 大于比较的实现
   */
  public static gt(
    compareOne: Expression<Object>,
    compareTwo: Expression<Object> | number | string
  ): Expression<boolean> {
    let compareTwoExpr: Expression<Object>;
    if (compareTwo instanceof Expression) {
      compareTwoExpr = compareTwo;
    } else if (typeof compareTwo === 'number') {
      compareTwoExpr = Expression.literal(compareTwo);
    } else {
      compareTwoExpr = Expression.literal(compareTwo as string);
    }
    return new Expression<boolean>('>', compareOne, compareTwoExpr);
  }

  /**
   * 小于比较（Expression）
   */
  public static lt(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * 小于比较（Expression 和数字）
   */
  public static lt(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * 小于比较（Expression 和字符串）
   */
  public static lt(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * 小于比较的实现
   */
  public static lt(
    compareOne: Expression<Object>,
    compareTwo: Expression<Object> | number | string
  ): Expression<boolean> {
    let compareTwoExpr: Expression<Object>;
    if (compareTwo instanceof Expression) {
      compareTwoExpr = compareTwo;
    } else if (typeof compareTwo === 'number') {
      compareTwoExpr = Expression.literal(compareTwo);
    } else {
      compareTwoExpr = Expression.literal(compareTwo as string);
    }
    return new Expression<boolean>('<', compareOne, compareTwoExpr);
  }

  /**
   * 大于等于比较（Expression）
   */
  public static gte(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * 大于等于比较（Expression 和数字）
   */
  public static gte(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * 大于等于比较（Expression 和字符串）
   */
  public static gte(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * 大于等于比较的实现
   */
  public static gte(
    compareOne: Expression<Object>,
    compareTwo: Expression<Object> | number | string
  ): Expression<boolean> {
    let compareTwoExpr: Expression<Object>;
    if (compareTwo instanceof Expression) {
      compareTwoExpr = compareTwo;
    } else if (typeof compareTwo === 'number') {
      compareTwoExpr = Expression.literal(compareTwo);
    } else {
      compareTwoExpr = Expression.literal(compareTwo as string);
    }
    return new Expression<boolean>('>=', compareOne, compareTwoExpr);
  }

  /**
   * 小于等于比较（Expression）
   */
  public static lte(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * 小于等于比较（Expression 和数字）
   */
  public static lte(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * 小于等于比较（Expression 和字符串）
   */
  public static lte(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * 小于等于比较的实现
   */
  public static lte(
    compareOne: Expression<Object>,
    compareTwo: Expression<Object> | number | string
  ): Expression<boolean> {
    let compareTwoExpr: Expression<Object>;
    if (compareTwo instanceof Expression) {
      compareTwoExpr = compareTwo;
    } else if (typeof compareTwo === 'number') {
      compareTwoExpr = Expression.literal(compareTwo);
    } else {
      compareTwoExpr = Expression.literal(compareTwo as string);
    }
    return new Expression<boolean>('<=', compareOne, compareTwoExpr);
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
  public static not(input: Expression<boolean>): Expression<boolean>;

  /**
   * 逻辑非（布尔值）
   */
  public static not(input: boolean): Expression<boolean>;

  /**
   * 逻辑非的实现
   */
  public static not(input: Expression<boolean> | boolean): Expression<boolean> {
    const inputExpr = typeof input === 'boolean' ? Expression.literal(input) : input;
    return new Expression<boolean>('!', inputExpr);
  }

  // ==================== 条件操作符 ====================

  /**
   * Switch-case 条件表达式
   * 格式：case(condition1, output1, condition2, output2, ..., fallback)
   */
  public static switchCase(...expressions: Expression[]): Expression<Object> {
    return new Expression<Object>('case', ...expressions);
  }

  /**
   * Case 条件表达式（switchCase的别名）
   * 格式：case(condition1, output1, condition2, output2, ..., fallback)
   */
  public static caseExpression(...expressions: Expression[]): Expression<Object> {
    return Expression.switchCase(...expressions);
  }

  /**
   * Match 表达式 - 匹配输入值并返回对应的输出
   * 格式：match(input, label1, output1, label2, output2, ..., fallback)
   */
  public static match(...expressions: Expression[]): Expression<Object> {
    return new Expression<Object>('match', ...expressions);
  }

  /**
   * Coalesce 表达式 - 返回第一个非空值
   */
  public static coalesce(...expressions: Expression[]): Expression<Object> {
    return new Expression<Object>('coalesce', ...expressions);
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
  public static subtract(first: Expression<number>, second: Expression<number>): Expression<number>;

  /**
   * 减法运算（二元，数字参数）
   */
  public static subtract(first: number, second: number): Expression<number>;

  /**
   * 取负（一元）
   */
  public static subtract(value: Expression<number>): Expression<number>;

  /**
   * 取负（一元，数字参数）
   */
  public static subtract(value: number): Expression<number>;

  /**
   * 减法运算的实现
   */
  public static subtract(
    first: Expression<number> | number,
    second?: Expression<number> | number
  ): Expression<number> {
    if (second === undefined) {
      // 一元取负
      const valueExpr = typeof first === 'number' ? Expression.literal(first) : first;
      return new Expression<number>('-', valueExpr);
    } else {
      // 二元减法
      const firstExpr = typeof first === 'number' ? Expression.literal(first) : first;
      const secondExpr = typeof second === 'number' ? Expression.literal(second) : second;
      return new Expression<number>('-', firstExpr, secondExpr);
    }
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
  public static divide(first: Expression<number>, second: Expression<number>): Expression<number>;

  /**
   * 除法运算（数字参数）
   */
  public static divide(first: number, second: number): Expression<number>;

  /**
   * 除法运算的实现
   */
  public static divide(
    first: Expression<number> | number,
    second: Expression<number> | number
  ): Expression<number> {
    const firstExpr = typeof first === 'number' ? Expression.literal(first) : first;
    const secondExpr = typeof second === 'number' ? Expression.literal(second) : second;
    return new Expression<number>('/', firstExpr, secondExpr);
  }

  /**
   * 取模运算
   */
  public static mod(first: Expression<number>, second: Expression<number>): Expression<number>;

  /**
   * 取模运算（数字参数）
   */
  public static mod(first: number, second: number): Expression<number>;

  /**
   * 取模运算的实现
   */
  public static mod(
    first: Expression<number> | number,
    second: Expression<number> | number
  ): Expression<number> {
    const firstExpr = typeof first === 'number' ? Expression.literal(first) : first;
    const secondExpr = typeof second === 'number' ? Expression.literal(second) : second;
    return new Expression<number>('%', firstExpr, secondExpr);
  }

  /**
   * 幂运算
   */
  public static pow(base: Expression<number>, exponent: Expression<number>): Expression<number>;

  /**
   * 幂运算（数字参数）
   */
  public static pow(base: number, exponent: number): Expression<number>;

  /**
   * 幂运算的实现
   */
  public static pow(
    base: Expression<number> | number,
    exponent: Expression<number> | number
  ): Expression<number> {
    const baseExpr = typeof base === 'number' ? Expression.literal(base) : base;
    const exponentExpr = typeof exponent === 'number' ? Expression.literal(exponent) : exponent;
    return new Expression<number>('^', baseExpr, exponentExpr);
  }

  // ==================== 数学函数 ====================

  /**
   * 平方根
   */
  public static sqrt(value: Expression<number>): Expression<number>;

  /**
   * 平方根（数字参数）
   */
  public static sqrt(value: number): Expression<number>;

  /**
   * 平方根的实现
   */
  public static sqrt(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('sqrt', valueExpr);
  }

  /**
   * 以 10 为底的对数
   */
  public static log10(value: Expression<number>): Expression<number>;

  /**
   * 以 10 为底的对数（数字参数）
   */
  public static log10(value: number): Expression<number>;

  /**
   * 以 10 为底的对数的实现
   */
  public static log10(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('log10', valueExpr);
  }

  /**
   * 以 2 为底的对数
   */
  public static log2(value: Expression<number>): Expression<number>;

  /**
   * 以 2 为底的对数（数字参数）
   */
  public static log2(value: number): Expression<number>;

  /**
   * 以 2 为底的对数的实现
   */
  public static log2(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('log2', valueExpr);
  }

  /**
   * 自然对数
   */
  public static ln(value: Expression<number>): Expression<number>;

  /**
   * 自然对数（数字参数）
   */
  public static ln(value: number): Expression<number>;

  /**
   * 自然对数的实现
   */
  public static ln(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('ln', valueExpr);
  }

  /**
   * 绝对值
   */
  public static abs(value: Expression<number>): Expression<number>;

  /**
   * 绝对值（数字参数）
   */
  public static abs(value: number): Expression<number>;

  /**
   * 绝对值的实现
   */
  public static abs(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('abs', valueExpr);
  }

  /**
   * 向上取整
   */
  public static ceil(value: Expression<number>): Expression<number>;

  /**
   * 向上取整（数字参数）
   */
  public static ceil(value: number): Expression<number>;

  /**
   * 向上取整的实现
   */
  public static ceil(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('ceil', valueExpr);
  }

  /**
   * 向下取整
   */
  public static floor(value: Expression<number>): Expression<number>;

  /**
   * 向下取整（数字参数）
   */
  public static floor(value: number): Expression<number>;

  /**
   * 向下取整的实现
   */
  public static floor(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('floor', valueExpr);
  }

  /**
   * 四舍五入
   */
  public static round(value: Expression<number>): Expression<number>;

  /**
   * 四舍五入（数字参数）
   */
  public static round(value: number): Expression<number>;

  /**
   * 四舍五入的实现
   */
  public static round(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('round', valueExpr);
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
  public static upcase(input: Expression<string>): Expression<string>;

  /**
   * 转大写（字符串参数）
   */
  public static upcase(input: string): Expression<string>;

  /**
   * 转大写的实现
   */
  public static upcase(input: Expression<string> | string): Expression<string> {
    const inputExpr = typeof input === 'string' ? Expression.literal(input) : input;
    return new Expression<string>('upcase', inputExpr);
  }

  /**
   * 转小写
   */
  public static downcase(input: Expression<string>): Expression<string>;

  /**
   * 转小写（字符串参数）
   */
  public static downcase(input: string): Expression<string>;

  /**
   * 转小写的实现
   */
  public static downcase(input: Expression<string> | string): Expression<string> {
    const inputExpr = typeof input === 'string' ? Expression.literal(input) : input;
    return new Expression<string>('downcase', inputExpr);
  }

  /**
   * 检查输入字符串是否能够正常渲染
   *
   * 返回 true 如果输入字符串预期能够清晰渲染。
   * 返回 false 如果输入字符串包含无法正常渲染的部分（例如需要复杂文本整形的 Indic 脚本，
   * 或者从右到左的脚本，如果未使用 mapbox-gl-rtl-text 插件）。
   *
   * 此方法对于国际化应用非常重要，可以帮助检测是否支持特定语言的文本渲染：
   * - 阿拉伯语、希伯来语等从右到左的脚本
   * - 印地语、泰米尔语、泰语等需要复杂文本整形的脚本
   * - 其他需要特殊渲染支持的语言
   *
   * @param input 要检查的字符串表达式
   * @returns 布尔值表达式，表示是否支持渲染
   *
   * @example
  * ```typescript
   * // 检查要素属性中的文本是否支持渲染
   * textField(
   *   Expression.caseExpression(
   *     Expression.isSupportedScript(Expression.get('name')),
   *     Expression.get('name'),
   *     Expression.literal('N/A')
   *   )
   * )
   *
   * // 检查特定语言文本
   * Expression.isSupportedScript('ಗೌರವಾರ್ಥವಾಗಿ')  // Kannada script
   * Expression.isSupportedScript('مرحبا')           // Arabic script  
   * Expression.isSupportedScript('שלום')            // Hebrew script
   * Expression.isSupportedScript('สวัสดี')          // Thai script
   * ```
   *
   * @see https://maplibre.org/maplibre-style-spec/expressions/#is-supported-script
   */
  public static isSupportedScript(input: Expression<string>): Expression<boolean>;

  /**
   * 检查字符串字面量是否能够正常渲染
   *
   * @param text 要检查的字符串字面量
   * @returns 布尔值表达式，表示是否支持渲染
   *
   * @example
  * ```typescript
   * Expression.isSupportedScript('Hello')  // 返回 true（拉丁文本）
   * Expression.isSupportedScript('你好')    // 返回 true（CJK文本）
   * Expression.isSupportedScript('مرحبا')  // 可能返回 false（阿拉伯语，需要RTL支持）
   * ```
   */
  public static isSupportedScript(text: string): Expression<boolean>;

  /**
   * 检查输入字符串是否能够正常渲染的实现
   */
  public static isSupportedScript(input: Expression<string> | string): Expression<boolean> {
    const inputExpr = typeof input === 'string' ? Expression.literal(input) : input;
    return new Expression<boolean>('is-supported-script', inputExpr);
  }

  /**
   * 创建 Collator 表达式（Expression 参数）
   *
   * @param caseSensitive 是否区分大小写
   * @param diacriticSensitive 是否区分变音符号
   * @param locale 区域设置（BCP 47 语言标签）
   */
  public static collator(
    caseSensitive: Expression<boolean>,
    diacriticSensitive: Expression<boolean>,
    locale: Expression<string>
  ): Expression<Object>;

  /**
   * 创建 Collator 表达式（使用选项对象）
   *
   * @param options Collator 选项
   */
  public static collator(options: Record<string, boolean | string>): Expression<Object>;

  /**
   * 创建 Collator 表达式的实现
   */
  public static collator(
    caseSensitiveOrOptions: Expression<boolean> | Record<string, boolean | string>,
    diacriticSensitive?: Expression<boolean>,
    locale?: Expression<string>
  ): Expression<Object> {
    const optionsMap = new Map<string, Expression>();

    // 判断是否使用选项对象
    if (diacriticSensitive === undefined && locale === undefined) {
      // 使用选项对象
      const options = caseSensitiveOrOptions as Record<string, boolean | string>;

      if (options['caseSensitive'] !== undefined) {
        const val = options['caseSensitive'];
        optionsMap.set('case-sensitive', Expression.literal(val as boolean));
      }
      if (options['diacriticSensitive'] !== undefined) {
        const val = options['diacriticSensitive'];
        optionsMap.set('diacritic-sensitive', Expression.literal(val as boolean));
      }
      if (options['locale'] !== undefined) {
        const val = options['locale'];
        optionsMap.set('locale', Expression.literal(val as string));
      }
    } else {
      // 使用三个 Expression 参数
      optionsMap.set('case-sensitive', caseSensitiveOrOptions as Expression<boolean>);
      if (diacriticSensitive) {
        optionsMap.set('diacritic-sensitive', diacriticSensitive);
      }
      if (locale) {
        optionsMap.set('locale', locale);
      }
    }

    return new Expression<Object>('collator', new ExpressionMap(optionsMap));
  }

  // ==================== 类型转换操作符 ====================

  /**
   * 转换为字符串
   * @param value 任意类型的表达式
   * @returns 字符串类型的表达式
   */
  public static toString<T = Object>(value: ExpressionLiteral): Expression<string> {
    return new Expression<string>('to-string', value);
  }

  /**
   * 转换为数字
   * @param value 任意类型的表达式
   * @returns 数字类型的表达式
   */
  public static toNumber<T = Object>(value: ExpressionLiteral): Expression<number> {
    return new Expression<number>('to-number', value);
  }

  /**
   * 转换为布尔值
   * @param value 任意类型的表达式
   * @returns 布尔类型的表达式
   */
  public static toBoolean<T = Object>(value: ExpressionLiteral): Expression<boolean> {
    return new Expression<boolean>('to-boolean', value);
  }

  /**
   * 转换为颜色
   * @param value 任意类型的表达式
   * @returns 颜色字符串类型的表达式
   */
  public static toColor<T = Object>(value: ExpressionLiteral): Expression<string> {
    return new Expression<string>('to-color', value);
  }

  /**
   * 获取值的类型
   * @param value 任意类型的表达式
   * @returns 类型名称的字符串表达式
   */
  public static typeof<T = Object>(value: ExpressionLiteral<T>): Expression<string> {
    return new Expression<string>('typeof', value);
  }

  /**
   * 断言为数组类型
   * @param value 任意类型的表达式
   * @returns 数组类型的表达式
   */
  public static array<T = Object>(value: ExpressionLiteral): Expression<Object[]> {
    return new Expression<Object[]>('array', value);
  }

  /**
   * 断言为字符串类型
   * @param value 任意类型的表达式
   * @returns 字符串类型的表达式
   */
  public static string<T = Object>(value: ExpressionLiteral): Expression<string> {
    return new Expression<string>('string', value);
  }

  /**
   * 断言为数字类型
   * @param value 任意类型的表达式
   * @returns 数字类型的表达式
   */
  public static number<T = Object>(value: ExpressionLiteral): Expression<number> {
    return new Expression<number>('number', value);
  }

  /**
   * 断言为布尔类型
   * @param value 任意类型的表达式
   * @returns 布尔类型的表达式
   */
  public static boolean<T = Object>(value: ExpressionLiteral): Expression<boolean> {
    return new Expression<boolean>('boolean', value);
  }

  /**
   * 断言为对象类型
   * @param value 任意类型的表达式
   * @returns 对象类型的表达式
   */
  public static object<T = Object>(value: ExpressionLiteral): Expression<Object> {
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
   * 线性插值器
   * 用于 interpolate 表达式，在输入停靠点之间线性插值
   */
  public static linear(): Expression<Object> {
    return new Expression<Object>('linear');
  }

  /**
   * 指数插值器（Expression 参数）
   *
   * 指数插值使用指定的底数进行指数变化
   *
   * @param base 指数底数（Expression）
   */
  public static exponential(base: Expression<number>): Expression<Object>;

  /**
   * 指数插值器（数字参数）
   *
   * @param base 指数底数（数字）
   */
  public static exponential(base: number): Expression<Object>;

  /**
   * 指数插值器的实现
   */
  public static exponential(base: Expression<number> | number): Expression<Object> {
    const baseExpr = typeof base === 'number' ? Expression.literal(base) : base;
    return new Expression<Object>('exponential', baseExpr);
  }

  /**
   * 三次贝塞尔曲线插值器（Expression 参数）
   *
   * 使用四个控制点定义的三次贝塞尔曲线进行插值
   *
   * @param x1 第一个控制点 x 坐标
   * @param y1 第一个控制点 y 坐标
   * @param x2 第二个控制点 x 坐标
   * @param y2 第二个控制点 y 坐标
   */
  public static cubicBezier(
    x1: Expression<number>,
    y1: Expression<number>,
    x2: Expression<number>,
    y2: Expression<number>
  ): Expression<Object>;

  /**
   * 三次贝塞尔曲线插值器（数字参数）
   *
   * @param x1 第一个控制点 x 坐标
   * @param y1 第一个控制点 y 坐标
   * @param x2 第二个控制点 x 坐标
   * @param y2 第二个控制点 y 坐标
   */
  public static cubicBezier(x1: number, y1: number, x2: number, y2: number): Expression<Object>;

  /**
   * 三次贝塞尔曲线插值器的实现
   */
  public static cubicBezier(
    x1: Expression<number> | number,
    y1: Expression<number> | number,
    x2: Expression<number> | number,
    y2: Expression<number> | number
  ): Expression<Object> {
    const x1Expr = typeof x1 === 'number' ? Expression.literal(x1) : x1;
    const y1Expr = typeof y1 === 'number' ? Expression.literal(y1) : y1;
    const x2Expr = typeof x2 === 'number' ? Expression.literal(x2) : x2;
    const y2Expr = typeof y2 === 'number' ? Expression.literal(y2) : y2;
    return new Expression<Object>('cubic-bezier', x1Expr, y1Expr, x2Expr, y2Expr);
  }

  /**
   * 插值表达式
   *
   * 通过在输入和输出对之间进行连续、平滑的结果
   *
   * @param interpolator 插值器（linear、exponential 或 cubicBezier）
   * @param input 输入表达式（通常是 zoom()）
   * @param stops 停靠点（Expression 数组，格式为 [input1, output1, input2, output2, ...]）
   */
  public static interpolate(interpolator: Expression<Object>, input: Expression<number>,
    ...stops: Expression[]): Expression<Object> {
    const args: Expression[] = [interpolator, input];
    for (const stop of stops) {
      args.push(stop);
    }
    return new Expression<Object>('interpolate', ...args);
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
  public static step(input: Expression<number>, defaultOutput: Expression<Object>,
    ...stops: Expression[]): Expression<Object>;

  /**
   * 阶梯表达式（数字输入）
   */
  public static step(input: number, defaultOutput: Expression<Object>, ...stops: Expression[]): Expression<Object>;

  /**
   * 阶梯表达式（数字默认输出）
   */
  public static step(input: Expression<number>, defaultOutput: number, ...stops: Expression[]): Expression<Object>;

  /**
   * 阶梯表达式（数字输入和默认输出）
   */
  public static step(input: number, defaultOutput: number, ...stops: Expression[]): Expression<Object>;

  /**
   * 阶梯表达式的实现
   */
  public static step(
    input: Expression<number> | number,
    defaultOutput: Expression<Object> | number,
    ...stops: Expression[]
  ): Expression<Object> {
    const inputExpr = typeof input === 'number' ? Expression.literal(input) : input;
    const defaultExpr = typeof defaultOutput === 'number' ? Expression.literal(defaultOutput) : defaultOutput;
    const args: Expression[] = [inputExpr, defaultExpr];
    for (const stop of stops) {
      args.push(stop);
    }
    return new Expression<Object>('step', ...args);
  }

  /**
   * 创建停靠点（便捷方法）
   * 用于 interpolate 和 step 表达式
   *
   * @param input 输入值
   * @param output 输出值
   * @returns 包含两个 Expression 的数组
   */
  public static stop(input: number | Expression<number>,
    output: number | string | boolean | null | Expression): Expression[] {
    const inputExpr = typeof input === 'number' ? Expression.literal(input) : input;
    const outputExpr = output instanceof Expression ? output : Expression.literal(output as number);
    return [inputExpr, outputExpr];
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
  public static numberFormat(number: Expression<number>, ...options: Expression[]): Expression<string>;

  /**
   * 数字格式化表达式（数字参数）
   */
  public static numberFormat(number: number, ...options: Expression[]): Expression<string>;

  /**
   * 数字格式化表达式的实现
   */
  public static numberFormat(
    number: Expression<number> | number,
    ...options: Expression[]
  ): Expression<string> {
    const numberExpr = typeof number === 'number' ? Expression.literal(number) : number;
    const args: Expression[] = [numberExpr, ...options];
    return new Expression<string>('number-format', ...args);
  }

  /**
   * 获取 Collator 实际使用的 IETF 语言标签
   *
   * 返回提供的 Collator 实际使用的 IETF 语言标签。
   * 可用于确定默认系统语言环境，或检查请求的语言环境是否成功加载。
   *
   * 当创建 Collator 时，可以指定期望的 locale，但系统可能会回退到其他 locale。
   * 此方法可以帮助确认实际使用的 locale，这对于调试国际化问题非常有用。
   *
   * @param collator Collator 表达式
   * @returns 字符串表达式，包含实际使用的 IETF 语言标签（如 "zh-CN", "en-US" 等）
   *
   * @example
  * ```typescript
   * // 创建一个 Collator 并获取实际使用的 locale
   * const collatorExpr = Expression.collator(
   *   Expression.literal(true),  // case-sensitive
   *   Expression.literal(true),  // diacritic-sensitive
   *   Expression.literal('zh-CN') // 期望的 locale
   * );
   * const localeExpr = Expression.resolvedLocale(collatorExpr);
   *
   * // 根据实际 locale 应用不同的样式
   * fillColor(
   *   Expression.caseExpression(
   *     Expression.eq(
   *       Expression.literal('zh-CN'),
   *       Expression.resolvedLocale(collatorExpr)
   *     ),
   *     Expression.literal('#FF0000'), // 中文环境使用红色
   *     Expression.literal('#0000FF')  // 其他环境使用蓝色
   *   )
   * )
   *
   * // 检查系统默认 locale
   * const defaultCollator = Expression.collator(
   *   Expression.literal(false),
   *   Expression.literal(false),
   *   Expression.literal(null) // 使用系统默认
   * );
   * const systemLocale = Expression.resolvedLocale(defaultCollator);
   * ```
   *
   * @see https://maplibre.org/maplibre-style-spec/expressions/#resolved-locale
   */
  public static resolvedLocale(collator: Expression): Expression<string> {
    return new Expression<string>('resolved-locale', collator);
  }

  /**
   * 图像表达式
   *
   * @param imageName 图像名称
   */
  public static image(imageName: Expression<string>): Expression<Object>;

  /**
   * 图像表达式（字符串参数）
   */
  public static image(imageName: string): Expression<Object>;

  /**
   * 图像表达式的实现
   */
  public static image(imageName: Expression<string> | string): Expression<Object> {
    const imageNameExpr = typeof imageName === 'string' ? Expression.literal(imageName) : imageName;
    return new Expression<Object>('image', imageNameExpr);
  }

  // ==================== 空间操作符 ====================

  /**
   * 计算到 GeoJSON 几何体的距离（米）
   */
  public static distance(geoJson: Object): Expression<number> {
    const map = new Map<string, Expression<Object>>();
    map.set('json', Expression.literal(JSON.stringify(geoJson)));
    return new Expression<number>('distance', new ExpressionMap(map));
  }

  /**
   * 判断要素是否在多边形内
   */
  public static within(polygon: Object): Expression<boolean> {
    const map = new Map<string, Expression<Object>>();
    const polyObj = polygon as Record<string, Object>;
    const typeValue = polyObj['type'];
    // 根据 typeValue 的类型来选择合适的 literal 重载
    if (typeof typeValue === 'string') {
      map.set('type', Expression.literal(typeValue));
    } else if (typeof typeValue === 'number') {
      map.set('type', Expression.literal(typeValue));
    } else if (typeof typeValue === 'boolean') {
      map.set('type', Expression.literal(typeValue));
    }
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
   * 从 JSON 数组转换为 Expression
   *
   * @param json JSON 数组或值
   * @return Expression 对象
   */
  public static convertFromJson(json: Object | null): Expression<Object> | null {
    if (json === null || json === undefined) {
      return null;
    }

    // 字面量值
    if (typeof json === 'number') {
      return Expression.literal(json);
    } else if (typeof json === 'string') {
      return Expression.literal(json);
    } else if (typeof json === 'boolean') {
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
      const args: Expression[] = [];
      for (let i = 1; i < json.length; i++) {
        const converted = Expression.convertFromJson(json[i]);
        if (converted !== null) {
          args.push(converted);
        }
      }

      // 根据操作符创建 Expression
      return new Expression<Object>(operator, ...args);
    }

    // 对象（用于 format, collator 等）
    if (typeof json === 'object') {
      // 对象类型暂不处理，返回 null
      return null;
    }

    return null;
  }

  /**
   * 从 JSON 字符串转换为 Expression
   *
   * @param jsonString JSON 字符串
   * @return Expression 对象
   */
  public static fromJsonString(jsonString: string): Expression<Object> | null {
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
 * @template T 字面量值的类型
 */
export class ExpressionLiteral<T = ExpressionValue> extends Expression<T> {
  private literal: T;

  constructor(literal: T) {
    super('literal');
    this.literal = literal;
  }

  /**
   * 覆盖父类方法，标识这是一个值表达式
   * 使用类型守护，在条件分支中自动缩窄类型为 ValueExpression
   */
  isValue(): boolean {
    return true;
  }

  public toValue(): T | null {
    if (this.literal instanceof ExpressionLiteral) {
      return (this.literal as ExpressionLiteral).toValue() as T;
    }
    return this.literal;
  }

  public override toArray(): ExpressionValue[] {
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
      return [this.literal as ExpressionValue];
    }
    return ['literal', this.literal as ExpressionValue];
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
export class ExpressionLiteralArray extends ExpressionLiteral<ExpressionValue[]> {
  private array: ExpressionValue[];

  constructor(array: ExpressionValue[]) {
    super(array);
    this.array = array;
  }

  public override toArray(): ExpressionValue[] {
    return ['literal', this.array];
  }

  public override toValue(): ExpressionValue[] | null {
    return this.array;
  }
}

/**
 * ExpressionMap - Map 表达式（用于 within 和 distance 等操作符）
 * @template T 返回值的类型
 */
export class ExpressionMap<T extends Object> extends Expression<T> {
  private map: Map<string, Expression>;

  constructor(map: Map<string, Expression>) {
    super('map');
    this.map = map;
  }

  public toValue(): T | null {
    const unwrappedMap: Record<string, ExpressionValue> = {};
    this.map.forEach((value: Expression, key: string) => {
      if (value instanceof ExpressionMap) {
        // 使用虚方法判断，然后安全转换
        const val = value.toValue() as ExpressionValue;
        if (val !== null) {
          unwrappedMap[key] = val;
        }
      } else {
        unwrappedMap[key] = value.toArray() as ExpressionValue;
      }
    });
    // 使用 Object 作为中间类型来避免 unknown
    return unwrappedMap as Object as T;
  }

  public override toArray(): ExpressionValue[] {
    const val = this.toValue();
    return val !== null ? [val as ExpressionValue] : [];
  }

  override isValue(): boolean {
    return true;
  }
}

// ==================== 向后兼容性 ====================

/**
 * @deprecated Use Expression instead. ExpressionBuilder has been merged into Expression.
 * This type alias is provided for backward compatibility only.
 */
export type ExpressionBuilder<T = Object> = Expression<T>;

export type PropertyValue<T> = Expression<T> | NativePropertyValue<T>
