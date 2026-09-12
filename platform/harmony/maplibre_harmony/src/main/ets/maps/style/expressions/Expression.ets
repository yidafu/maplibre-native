import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../../constants/HiLogConstants';
/**
 * Expression - core MapLibre expression class.
 *
 * Backed by C++ NAPI bindings to provide high-performance parsing and evaluation.
 *
 * Expressions describe formulas that compute property values using operators such as:
 * - Math operators: arithmetic and numeric manipulation.
 * - Logic operators: boolean operations and conditional branching.
 * - String operators: string manipulation.
 * - Data operators: access source feature attributes.
 * - Camera operators: access parameters describing the current map view.
 *
 * Each expression is represented as a JSON array. The first element is the operator name
 * (e.g., `"*"`, `"case"`). Additional elements, if any, are arguments—either literals
 * (string, number, boolean, or null) or nested expressions.
 *
 * @see <a href="https://maplibre.org/maplibre-style-spec/expressions/">MapLibre Expression Specification</a>
 */

import type {
  ExpressionValue,
  ExpressionLiteral as NativeExpressionLiteral,
  PropertyValue as NativePropertyValue
} from 'libmaplibre.so';

/**
 * Expression - convenience wrapper with factory helpers (e.g., `Expression.literal()`, `Expression.get()`).
 *
 * API surface mirrors Android/iOS implementations.
 *
 * @template T Optional expression return type.
 */
export class Expression<T = Object> {
  protected operator: string | null = null;
  protected arguments: Expression[] | null = null;

  /**
   * Private constructor used internally.
   * @param operator Operator string.
   * @param args Expression arguments.
   */
  constructor(operator: string, ...args: Expression[]) {
    this.operator = operator;
    this.arguments = args.length > 0 ? args : null;
  }

  // ==================== Instance Methods (getters) ====================

  /**
   * Retrieve the operator.
   */
  public getOperator(): string | null {
    return this.operator;
  }

  /**
   * Retrieve the arguments.
   */
  public getArguments(): Expression[] | null {
    return this.arguments;
  }

  /**
   * Serialize the expression to a JSON array.
   * @returns Expression literal (JSON array).
   */
  serialize(): NativeExpressionLiteral {
    return this.toArray() as NativeExpressionLiteral;
  }

  /**
   * Convert the expression to a JSON array.
   * @returns Expression literal `[operator, ...arguments]`.
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
   * Check whether this expression is a value expression.
   * Enables type guarding that narrows to `ValueExpression` inside branches.
   */
  isValue(): boolean {
    return false;
  }

  /**
   * Determine whether two expressions are equal.
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
   * Get the hash code.
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
   * Convert to a string.
   */
  public toString(): string {
    return JSON.stringify(this.toArray());
  }

  /**
   * Helper: determine whether an expression is a value expression.
   */
  protected isValueExpression(expr: Expression): boolean {
    return expr.isValue();
  }

  // ==================== Static Factory Methods ====================
  // Migrated from the legacy ExpressionBuilder.

  // ==================== Literal Operators ====================

  /**
   * Create a numeric literal expression.
   */
  public static literal(value: number): ExpressionLiteral<number>;

  /**
   * Create a string literal expression.
   */
  public static literal(value: string): ExpressionLiteral<string>;

  /**
   * Create a boolean literal expression.
   */
  public static literal(value: boolean): ExpressionLiteral<boolean>;

  /**
   * Create an array literal expression.
   */
  public static literal(value: ExpressionValue[]): ExpressionLiteralArray;

  /**
   * Implementation helper for literal expressions.
   */
  public static literal(value: ExpressionValue): ExpressionLiteral | ExpressionLiteralArray {
    if (Array.isArray(value)) {
      return new ExpressionLiteralArray(value as ExpressionValue[]);
    }
    return new ExpressionLiteral(value);
  }

  // ==================== Color Operators ====================

  /**
   * Create a color expression from an integer value.
   *
   * @param color ARGB integer.
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
   * Create an RGB color expression.
   */
  public static rgb(red: Expression<number>, green: Expression<number>, blue: Expression<number>): Expression<string>;

  /**
   * Create an RGB color expression (numeric parameters).
   */
  public static rgb(red: number, green: number, blue: number): Expression<string>;

  /**
   * Implementation helper for RGB color expressions.
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
   * Create an RGBA color expression.
   */
  public static rgba(
    red: Expression<number>,
    green: Expression<number>,
    blue: Expression<number>,
    alpha: Expression<number>
  ): Expression<string>;

  /**
   * Create an RGBA color expression (numeric parameters).
   */
  public static rgba(red: number, green: number, blue: number, alpha: number): Expression<string>;

  /**
   * Implementation helper for RGBA color expressions.
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
   * Convert a color to an RGBA array expression.
   */
  public static toRgba(color: Expression<string>): Expression<number[]> {
    return new Expression<number[]>('to-rgba', color);
  }

  /**
   * Helper: convert an integer color to an RGBA array.
   */
  private static colorToRgbaArray(color: number): number[] {
    const a = ((color >> 24) & 0xFF) / 255.0;
    const r = (color >> 16) & 0xFF;
    const g = (color >> 8) & 0xFF;
    const b = color & 0xFF;
    return [r, g, b, a];
  }

  // ==================== Data Access Operators ====================

  /**
   * Get a property from the current feature by key.
   *
   * @param key Property key (Expression).
   */
  public static get<T = Object>(key: Expression<string>): Expression<T>;

  /**
   * Get a property from the current feature by key.
   *
   * @param key Property key (string).
   */
  public static get<T = Object>(key: string): Expression<T>;

  /**
   * Get a value from an object by key.
   *
   * @param key Property key (Expression).
   * @param object Object expression.
   */
  public static get<T = Object>(key: Expression<string>, object: Expression<Object>): Expression<T>;

  /**
   * Get a value from an object by key.
   *
   * @param key Property key (string).
   * @param object Object expression.
   */
  public static get<T = Object>(key: string, object: Expression<Object>): Expression<T>;

  /**
   * Implementation helper for retrieving a value from a feature or object.
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
   * Check whether the current feature has a property.
   *
   * @param key Property key (Expression).
   */
  public static has(key: Expression<string>): Expression<boolean>;

  /**
   * Check whether the current feature has a property.
   *
   * @param key Property key (string).
   */
  public static has(key: string): Expression<boolean>;

  /**
   * Check whether an object has the specified property.
   *
   * @param key Property key (Expression).
   * @param object Object expression.
   */
  public static has(key: Expression<string>, object: Expression<Object>): Expression<boolean>;

  /**
   * Check whether an object has the specified property.
   *
   * @param key Property key (string).
   * @param object Object expression.
   */
  public static has(key: string, object: Expression<Object>): Expression<boolean>;

  /**
   * Implementation helper for feature/object property checks.
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
   * Get all properties of the current feature.
   */
  public static properties(): Expression<Object> {
    return new Expression<Object>('properties');
  }

  /**
   * Get the geometry type of the current feature.
   * Returns `"Point"`, `"MultiPoint"`, `"LineString"`, `"MultiLineString"`, `"Polygon"`, or `"MultiPolygon"`.
   */
  public static geometryType(): Expression<string> {
    return new Expression<string>('geometry-type');
  }

  /**
   * Get the ID of the current feature.
   */
  public static id(): Expression<number | string> {
    return new Expression<number | string>('id');
  }

  /**
   * Get the aggregated accumulation value (for aggregation layers).
   */
  public static accumulated(): Expression<Object> {
    return new Expression<Object>('accumulated');
  }

  /**
   * Get the heatmap density value (available only within heatmap-color).
   */
  public static heatmapDensity(): Expression<number> {
    return new Expression<number>('heatmap-density');
  }

  /**
   * Get the line progress value (available only for line gradient properties).
   */
  public static lineProgress(): Expression<number> {
    return new Expression<number>('line-progress');
  }

  // ==================== Array and Object Operators ====================

  /**
   * Get an element from an array at the specified index.
   *
   * @param index Index (Expression).
   * @param array Array expression.
   */
  public static at<T = Object>(index: Expression<number>, array: Expression<T[]>): Expression<T>;

  /**
   * Get an element from an array at the specified index.
   *
   * @param index Index (number).
   * @param array Array expression.
   */
  public static at<T = Object>(index: number, array: Expression<T[]>): Expression<T>;

  /**
   * Implementation helper for array element access.
   */
  public static at<T = Object>(
    index: Expression<number> | number,
    array: Expression<T[]>
  ): Expression<T> {
    const indexExpr = typeof index === 'number' ? Expression.literal(index) : index;
    return new Expression<T>('at', indexExpr, array);
  }

  /**
   * Check whether a value exists within an array or string.
   *
   * @param needle Value to search for.
   * @param haystack Array or string.
   */
  public static in(needle: Expression<Object>, haystack: Expression<Object>): Expression<boolean>;

  /**
   * Check whether a number exists within the array.
   */
  public static in(needle: number, haystack: Expression<Object>): Expression<boolean>;

  /**
   * Check whether a string exists within an array or string.
   */
  public static in(needle: string, haystack: Expression<Object>): Expression<boolean>;

  /**
   * Implementation helper for membership checks in arrays/strings.
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
   * Find the index of a value within an array or string.
   *
   * @param keyword Value to locate.
   * @param input Array or string.
   */
  public static indexOf(keyword: Expression<Object>, input: Expression<Object>): Expression<number>;

  /**
   * Find the index of a value within an array or string starting at a position.
   *
   * @param keyword Value to locate.
   * @param input Array or string.
   * @param fromIndex Start position.
   */
  public static indexOf(keyword: Expression<Object>, input: Expression<Object>,
    fromIndex: Expression<number>): Expression<number>;

  /**
   * Implementation helper for index lookup.
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
   * Slice a portion of an array or string.
   *
   * @param input Array or string.
   * @param fromIndex Start position (Expression).
   */
  public static slice<T = Object>(input: Expression<T[] | string>,
    fromIndex: Expression<number>): Expression<T[] | string>;

  /**
   * Slice a portion of an array or string.
   *
   * @param input Array or string.
   * @param fromIndex Start position (number).
   */
  public static slice<T = Object>(input: Expression<T[] | string>, fromIndex: number): Expression<T[] | string>;

  /**
   * Slice an array or string within a specific range.
   *
   * @param input Array or string.
   * @param fromIndex Start position (Expression).
   * @param toIndex End position (Expression).
   */
  public static slice<T = Object>(
    input: Expression<T[] | string>,
    fromIndex: Expression<number>,
    toIndex: Expression<number>
  ): Expression<T[] | string>;

  /**
   * Slice an array or string within a specific range.
   *
   * @param input Array or string.
   * @param fromIndex Start position (number).
   * @param toIndex End position (number).
   */
  public static slice<T = Object>(
    input: Expression<T[] | string>,
    fromIndex: number,
    toIndex: number
  ): Expression<T[] | string>;

  /**
   * Implementation helper for array/string slicing.
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
   * Get the length of an array or string.
   * Note: renamed to `len` to avoid clashing with `Function.length`.
   */
  public static len(input: Expression<Object[] | string>): Expression<number> {
    return new Expression<number>('length', input);
  }

  // ==================== Comparison Operators ====================

  /**
   * Equality comparison (Expression).
   */
  public static eq(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * Equality comparison (Expression vs boolean).
   */
  public static eq(compareOne: Expression<Object>, compareTwo: boolean): Expression<boolean>;

  /**
   * Equality comparison (Expression vs string).
   */
  public static eq(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * Equality comparison (Expression vs number).
   */
  public static eq(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * Implementation helper for equality comparison.
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
   * Inequality comparison (Expression).
   */
  public static neq(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * Inequality comparison (Expression vs boolean).
   */
  public static neq(compareOne: Expression<Object>, compareTwo: boolean): Expression<boolean>;

  /**
   * Inequality comparison (Expression vs string).
   */
  public static neq(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * Inequality comparison (Expression vs number).
   */
  public static neq(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * Implementation helper for inequality comparison.
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
   * Greater-than comparison (Expression).
   */
  public static gt(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * Greater-than comparison (Expression vs number).
   */
  public static gt(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * Greater-than comparison (Expression vs string).
   */
  public static gt(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * Implementation helper for greater-than comparison.
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
   * Less-than comparison (Expression).
   */
  public static lt(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * Less-than comparison (Expression vs number).
   */
  public static lt(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * Less-than comparison (Expression vs string).
   */
  public static lt(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * Implementation helper for less-than comparison.
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
   * Greater-than-or-equal comparison (Expression).
   */
  public static gte(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * Greater-than-or-equal comparison (Expression vs number).
   */
  public static gte(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * Greater-than-or-equal comparison (Expression vs string).
   */
  public static gte(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * Implementation helper for greater-than-or-equal comparison.
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
   * Less-than-or-equal comparison (Expression).
   */
  public static lte(compareOne: Expression<Object>, compareTwo: Expression<Object>): Expression<boolean>;

  /**
   * Less-than-or-equal comparison (Expression vs number).
   */
  public static lte(compareOne: Expression<Object>, compareTwo: number): Expression<boolean>;

  /**
   * Less-than-or-equal comparison (Expression vs string).
   */
  public static lte(compareOne: Expression<Object>, compareTwo: string): Expression<boolean>;

  /**
   * Implementation helper for less-than-or-equal comparison.
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

  // ==================== Logical Operators ====================

  /**
   * Logical AND (all conditions must be true).
   */
  public static all(...expressions: Expression<boolean>[]): Expression<boolean> {
    return new Expression<boolean>('all', ...expressions);
  }

  /**
   * Logical OR (any condition may be true).
   */
  public static any(...expressions: Expression<boolean>[]): Expression<boolean> {
    return new Expression<boolean>('any', ...expressions);
  }

  /**
   * Logical NOT.
   */
  public static not(input: Expression<boolean>): Expression<boolean>;

  /**
   * Logical NOT (boolean parameter).
   */
  public static not(input: boolean): Expression<boolean>;

  /**
   * Implementation helper for logical NOT.
   */
  public static not(input: Expression<boolean> | boolean): Expression<boolean> {
    const inputExpr = typeof input === 'boolean' ? Expression.literal(input) : input;
    return new Expression<boolean>('!', inputExpr);
  }

  // ==================== Conditional Operators ====================

  /**
   * Switch-case conditional expression.
   * Syntax: `case(condition1, output1, condition2, output2, ..., fallback)`.
   */
  public static switchCase(...expressions: Expression[]): Expression<Object> {
    return new Expression<Object>('case', ...expressions);
  }

  /**
   * `case` conditional expression (alias of `switchCase`).
   * Syntax: `case(condition1, output1, condition2, output2, ..., fallback)`.
   */
  public static caseExpression(...expressions: Expression[]): Expression<Object> {
    return Expression.switchCase(...expressions);
  }

  /**
   * `match` expression — maps the input value to the corresponding output.
   * Syntax: `match(input, label1, output1, label2, output2, ..., fallback)`.
   */
  public static match(...expressions: Expression[]): Expression<Object> {
    return new Expression<Object>('match', ...expressions);
  }

  /**
   * `coalesce` expression — returns the first non-null value.
   */
  public static coalesce(...expressions: Expression[]): Expression<Object> {
    return new Expression<Object>('coalesce', ...expressions);
  }

  // ==================== Arithmetic Operators ====================

  /**
   * Addition operator.
   */
  public static add(...expressions: Expression<number>[]): Expression<number> {
    return new Expression<number>('+', ...expressions);
  }

  /**
   * Binary subtraction.
   */
  public static subtract(first: Expression<number>, second: Expression<number>): Expression<number>;

  /**
   * Binary subtraction (numeric parameters).
   */
  public static subtract(first: number, second: number): Expression<number>;

  /**
   * Unary negation.
   */
  public static subtract(value: Expression<number>): Expression<number>;

  /**
   * Unary negation (numeric parameter).
   */
  public static subtract(value: number): Expression<number>;

  /**
   * Implementation helper for subtraction.
   */
  public static subtract(
    first: Expression<number> | number,
    second?: Expression<number> | number
  ): Expression<number> {
    if (second === undefined) {
      // unary negation
      const valueExpr = typeof first === 'number' ? Expression.literal(first) : first;
      return new Expression<number>('-', valueExpr);
    } else {
      // binary subtraction
      const firstExpr = typeof first === 'number' ? Expression.literal(first) : first;
      const secondExpr = typeof second === 'number' ? Expression.literal(second) : second;
      return new Expression<number>('-', firstExpr, secondExpr);
    }
  }

  /**
   * Multiplication operator.
   */
  public static multiply(...expressions: Expression<number>[]): Expression<number> {
    return new Expression<number>('*', ...expressions);
  }

  /**
   * Division operator.
   */
  public static divide(first: Expression<number>, second: Expression<number>): Expression<number>;

  /**
   * Division operator (numeric parameter).
   */
  public static divide(first: number, second: number): Expression<number>;

  /**
   * Implementation helper for division.
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
   * Modulo operator.
   */
  public static mod(first: Expression<number>, second: Expression<number>): Expression<number>;

  /**
   * Modulo operator (numeric parameters).
   */
  public static mod(first: number, second: number): Expression<number>;

  /**
   * Implementation helper for the modulo operator.
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
   * Power operator.
   */
  public static pow(base: Expression<number>, exponent: Expression<number>): Expression<number>;

  /**
   * Power operator (numeric parameter).
   */
  public static pow(base: number, exponent: number): Expression<number>;

  /**
   * Implementation helper for the power operator.
   */
  public static pow(
    base: Expression<number> | number,
    exponent: Expression<number> | number
  ): Expression<number> {
    const baseExpr = typeof base === 'number' ? Expression.literal(base) : base;
    const exponentExpr = typeof exponent === 'number' ? Expression.literal(exponent) : exponent;
    return new Expression<number>('^', baseExpr, exponentExpr);
  }

  // ==================== Math Functions ====================

  /**
   * Square root.
   */
  public static sqrt(value: Expression<number>): Expression<number>;

  /**
   * Square root (numeric parameter).
   */
  public static sqrt(value: number): Expression<number>;

  /**
   * Implementation helper for square root.
   */
  public static sqrt(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('sqrt', valueExpr);
  }

  /**
   * Base-10 logarithm.
   */
  public static log10(value: Expression<number>): Expression<number>;

  /**
   * Base-10 logarithm (numeric parameter).
   */
  public static log10(value: number): Expression<number>;

  /**
   * Implementation helper for the base-10 logarithm.
   */
  public static log10(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('log10', valueExpr);
  }

  /**
   * Base-2 logarithm.
   */
  public static log2(value: Expression<number>): Expression<number>;

  /**
   * Base-2 logarithm (numeric parameter).
   */
  public static log2(value: number): Expression<number>;

  /**
   * Implementation helper for the base-2 logarithm.
   */
  public static log2(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('log2', valueExpr);
  }

  /**
   * Natural logarithm.
   */
  public static ln(value: Expression<number>): Expression<number>;

  /**
   * Natural logarithm (numeric parameter).
   */
  public static ln(value: number): Expression<number>;

  /**
   * Implementation helper for the natural logarithm.
   */
  public static ln(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('ln', valueExpr);
  }

  /**
   * Absolute value.
   */
  public static abs(value: Expression<number>): Expression<number>;

  /**
   * Absolute value (numeric parameter).
   */
  public static abs(value: number): Expression<number>;

  /**
   * Implementation helper for absolute value.
   */
  public static abs(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('abs', valueExpr);
  }

  /**
   * Ceiling function.
   */
  public static ceil(value: Expression<number>): Expression<number>;

  /**
   * Ceiling function (numeric parameter).
   */
  public static ceil(value: number): Expression<number>;

  /**
   * Implementation helper for ceiling.
   */
  public static ceil(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('ceil', valueExpr);
  }

  /**
   * Floor function.
   */
  public static floor(value: Expression<number>): Expression<number>;

  /**
   * Floor function (numeric parameter).
   */
  public static floor(value: number): Expression<number>;

  /**
   * Implementation helper for floor.
   */
  public static floor(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('floor', valueExpr);
  }

  /**
   * Round function.
   */
  public static round(value: Expression<number>): Expression<number>;

  /**
   * Round function (numeric parameter).
   */
  public static round(value: number): Expression<number>;

  /**
   * Implementation helper for rounding.
   */
  public static round(value: Expression<number> | number): Expression<number> {
    const valueExpr = typeof value === 'number' ? Expression.literal(value) : value;
    return new Expression<number>('round', valueExpr);
  }

  /**
   * Minimum value.
   */
  public static min(...values: Expression<number>[]): Expression<number> {
    return new Expression<number>('min', ...values);
  }

  /**
   * Maximum value.
   */
  public static max(...values: Expression<number>[]): Expression<number> {
    return new Expression<number>('max', ...values);
  }

  /**
   * Sine function.
   */
  public static sin(value: Expression<number>): Expression<number> {
    return new Expression<number>('sin', value);
  }

  /**
   * Cosine function.
   */
  public static cos(value: Expression<number>): Expression<number> {
    return new Expression<number>('cos', value);
  }

  /**
   * Tangent function.
   */
  public static tan(value: Expression<number>): Expression<number> {
    return new Expression<number>('tan', value);
  }

  /**
   * Arcsine function.
   */
  public static asin(value: Expression<number>): Expression<number> {
    return new Expression<number>('asin', value);
  }

  /**
   * Arccos function.
   */
  public static acos(value: Expression<number>): Expression<number> {
    return new Expression<number>('acos', value);
  }

  /**
   * Arctangent function.
   */
  public static atan(value: Expression<number>): Expression<number> {
    return new Expression<number>('atan', value);
  }

  /**
   * Euler’s constant `e`.
   */
  public static e(): Expression<number> {
    return new Expression<number>('e');
  }

  /**
   * Pi constant.
   */
  public static pi(): Expression<number> {
    return new Expression<number>('pi');
  }

  // ==================== String Operators ====================

  /**
   * String concatenation.
   */
  public static concat(...strings: Expression<string>[]): Expression<string> {
    return new Expression<string>('concat', ...strings);
  }

  /**
   * Convert to upper case.
   */
  public static upcase(input: Expression<string>): Expression<string>;

  /**
   * Convert to upper case (string parameter).
   */
  public static upcase(input: string): Expression<string>;

  /**
   * Implementation helper for uppercase conversion.
   */
  public static upcase(input: Expression<string> | string): Expression<string> {
    const inputExpr = typeof input === 'string' ? Expression.literal(input) : input;
    return new Expression<string>('upcase', inputExpr);
  }

  /**
   * Convert to lower case.
   */
  public static downcase(input: Expression<string>): Expression<string>;

  /**
   * Convert to lower case (string parameter).
   */
  public static downcase(input: string): Expression<string>;

  /**
   * Implementation helper for lowercase conversion.
   */
  public static downcase(input: Expression<string> | string): Expression<string> {
    const inputExpr = typeof input === 'string' ? Expression.literal(input) : input;
    return new Expression<string>('downcase', inputExpr);
  }

  /**
   * Determine whether the input string can render correctly.
   *
   * Returns `true` when the string is expected to render clearly, and `false` when it contains
   * segments that require unsupported shaping (for example Indic scripts) or right-to-left scripts
   * without the `mapbox-gl-rtl-text` plugin.
   *
   * This check is critical for internationalization scenarios and helps verify support for:
   * - Right-to-left scripts such as Arabic or Hebrew.
   * - Complex-shaping scripts such as Hindi, Tamil, or Thai.
   * - Any other languages that need special rendering support.
   *
   * @param input String expression to validate.
   * @returns Boolean expression indicating whether rendering is supported.
   *
   * @example
   * ```typescript
   * // Validate feature text prior to displaying
   * textField(
   *   Expression.caseExpression(
   *     Expression.isSupportedScript(Expression.get('name')),
   *     Expression.get('name'),
   *     Expression.literal('N/A')
   *   )
   * )
   *
   * // Probe specific scripts
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
   * Determine whether a string literal can render correctly.
   *
   * @param text String literal to validate.
   * @returns Boolean expression indicating render support.
   *
   * @example
   * ```typescript
   * Expression.isSupportedScript('Hello')  // returns true (Latin text)
   * Expression.isSupportedScript('\u4f60\u597d')    // returns true (CJK text)
   * Expression.isSupportedScript('مرحبا')  // may return false (Arabic; needs RTL support)
   * ```
   */
  public static isSupportedScript(text: string): Expression<boolean>;

  /**
   * Implementation helper for string renderability checks.
   */
  public static isSupportedScript(input: Expression<string> | string): Expression<boolean> {
    const inputExpr = typeof input === 'string' ? Expression.literal(input) : input;
    return new Expression<boolean>('is-supported-script', inputExpr);
  }

  /**
   * Create a collator expression (Expression parameters).
   *
   * @param caseSensitive Case-sensitivity flag.
   * @param diacriticSensitive Diacritic-sensitivity flag.
   * @param locale Locale (BCP 47 language tag).
   */
  public static collator(
    caseSensitive: Expression<boolean>,
    diacriticSensitive: Expression<boolean>,
    locale: Expression<string>
  ): Expression<Object>;

  /**
   * Create a collator expression (options object).
   *
   * @param options Collator options.
   */
  public static collator(options: Record<string, boolean | string>): Expression<Object>;

  /**
   * Implementation helper for collator expressions.
   */
  public static collator(
    caseSensitiveOrOptions: Expression<boolean> | Record<string, boolean | string>,
    diacriticSensitive?: Expression<boolean>,
    locale?: Expression<string>
  ): Expression<Object> {
    const optionsMap = new Map<string, Expression>();

    // Determine whether an options object is used.
    if (diacriticSensitive === undefined && locale === undefined) {
      // Using the options object overload.
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
      // Using the overload with three Expression parameters.
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

  // ==================== Type Conversion Operators ====================

  /**
   * Convert to a string.
   * @param value Expression of any type.
   * @returns String expression.
   */
  public static toString<T = Object>(value: ExpressionLiteral): Expression<string> {
    return new Expression<string>('to-string', value);
  }

  /**
   * Convert to a number.
   * @param value Expression of any type.
   * @returns Numeric expression.
   */
  public static toNumber<T = Object>(value: ExpressionLiteral): Expression<number> {
    return new Expression<number>('to-number', value);
  }

  /**
   * Convert to a boolean.
   * @param value Expression of any type.
   * @returns Boolean expression.
   */
  public static toBoolean<T = Object>(value: ExpressionLiteral): Expression<boolean> {
    return new Expression<boolean>('to-boolean', value);
  }

  /**
   * Convert to a color.
  * @param value Expression of any type.
   * @returns Color string expression.
   */
  public static toColor<T = Object>(value: ExpressionLiteral): Expression<string> {
    return new Expression<string>('to-color', value);
  }

  /**
   * Retrieve the value type.
   * @param value Expression of any type.
   * @returns String expression containing the type name.
   */
  public static typeof<T = Object>(value: ExpressionLiteral<T>): Expression<string> {
    return new Expression<string>('typeof', value);
  }

  /**
   * Assert the value is an array.
   * @param value Expression of any type.
   * @returns Array expression.
   */
  public static array<T = Object>(value: ExpressionLiteral): Expression<Object[]> {
    return new Expression<Object[]>('array', value);
  }

  /**
   * Assert the value is a string.
   * @param value Expression of any type.
   * @returns String expression.
   */
  public static string<T = Object>(value: ExpressionLiteral): Expression<string> {
    return new Expression<string>('string', value);
  }

  /**
   * Assert the value is numeric.
   * @param value Expression of any type.
   * @returns Numeric expression.
   */
  public static number<T = Object>(value: ExpressionLiteral): Expression<number> {
    return new Expression<number>('number', value);
  }

  /**
   * Assert the value is boolean.
   * @param value Expression of any type.
   * @returns Boolean expression.
   */
  public static boolean<T = Object>(value: ExpressionLiteral): Expression<boolean> {
    return new Expression<boolean>('boolean', value);
  }

  /**
   * Assert the value is an object.
   * @param value Expression of any type.
   * @returns Object expression.
   */
  public static object<T = Object>(value: ExpressionLiteral): Expression<Object> {
    return new Expression<Object>('object', value);
  }

  // ==================== Camera Operators ====================

  /**
   * Get the current zoom level.
   */
  public static zoom(): Expression<number> {
    return new Expression<number>('zoom');
  }

  // ==================== Interpolation and Step Expressions ====================

  /**
   * Linear interpolator.
   * Used by `interpolate` to blend between stops linearly.
   */
  public static linear(): Expression<Object> {
    return new Expression<Object>('linear');
  }

  /**
   * Exponential interpolator (Expression parameter).
   *
   * Applies exponential scaling using the supplied base.
   *
   * @param base Exponent base (Expression).
   */
  public static exponential(base: Expression<number>): Expression<Object>;

  /**
   * Exponential interpolator (numeric parameter).
   *
   * @param base Exponent base (number).
   */
  public static exponential(base: number): Expression<Object>;

  /**
   * Implementation helper for exponential interpolation.
   */
  public static exponential(base: Expression<number> | number): Expression<Object> {
    const baseExpr = typeof base === 'number' ? Expression.literal(base) : base;
    return new Expression<Object>('exponential', baseExpr);
  }

  /**
   * Cubic Bézier interpolator (Expression parameters).
   *
   * Performs interpolation using four control points.
   *
   * @param x1 X coordinate of the first control point.
   * @param y1 Y coordinate of the first control point.
   * @param x2 X coordinate of the second control point.
   * @param y2 Y coordinate of the second control point.
   */
  public static cubicBezier(
    x1: Expression<number>,
    y1: Expression<number>,
    x2: Expression<number>,
    y2: Expression<number>
  ): Expression<Object>;

  /**
   * Cubic Bézier interpolator (numeric parameters).
   *
   * @param x1 X coordinate of the first control point.
   * @param y1 Y coordinate of the first control point.
   * @param x2 X coordinate of the second control point.
   * @param y2 Y coordinate of the second control point.
   */
  public static cubicBezier(x1: number, y1: number, x2: number, y2: number): Expression<Object>;

  /**
   * Implementation helper for the cubic Bézier interpolator.
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
   * Interpolate expression.
   *
   * Produces smooth, continuous results between input/output pairs.
   *
   * @param interpolator Interpolator (`linear`, `exponential`, or `cubicBezier`).
   * @param input Input expression (typically `zoom()`).
   * @param stops Stops (Expression array `[input1, output1, input2, output2, ...]`).
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
   * Step expression.
   *
   * Selects discrete outputs according to the input value.
   *
   * @param input Input expression.
   * @param defaultOutput Default output value.
   * @param stops Stops (Expression array `[input1, output1, input2, output2, ...]`).
   */
  public static step(input: Expression<number>, defaultOutput: Expression<Object>,
    ...stops: Expression[]): Expression<Object>;

  /**
   * Step expression (numeric input).
   */
  public static step(input: number, defaultOutput: Expression<Object>, ...stops: Expression[]): Expression<Object>;

  /**
   * Step expression (numeric default output).
   */
  public static step(input: Expression<number>, defaultOutput: number, ...stops: Expression[]): Expression<Object>;

  /**
   * Step expression (numeric input and default output).
   */
  public static step(input: number, defaultOutput: number, ...stops: Expression[]): Expression<Object>;

  /**
   * Implementation helper for step expressions.
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
   * Create a stop pair (convenience helper).
   * Used by `interpolate` and `step`.
   *
   * @param input Input value.
   * @param output Output value.
   * @returns Array containing two expressions.
   */
  public static stop(input: number | Expression<number>,
    output: number | string | boolean | null | Expression): Expression[] {
    const inputExpr = typeof input === 'number' ? Expression.literal(input) : input;
    const outputExpr = output instanceof Expression ? output : Expression.literal(output as number);
    return [inputExpr, outputExpr];
  }

  // ==================== Formatting Expressions ====================

  /**
   * Format text expression.
   *
   * @param entries Array of format entries.
   */
  public static format(...entries: Expression[]): Expression<string> {
    return new Expression<string>('format', ...entries);
  }

  /**
   * Number format expression.
   *
   * @param number Number to format.
   * @param options Format options.
   */
  public static numberFormat(number: Expression<number>, ...options: Expression[]): Expression<string>;

  /**
   * Number format expression (numeric parameter).
   */
  public static numberFormat(number: number, ...options: Expression[]): Expression<string>;

  /**
   * Implementation helper for number formatting.
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
   * Retrieve the actual IETF language tag used by a collator.
   *
   * Useful for determining the default system locale or verifying that a requested locale was
   * successfully loaded. When you construct a collator you may provide a preferred locale, but the
   * system can fall back to another—this helper exposes which locale is in effect.
   *
   * @param collator Collator expression.
   * @returns String expression containing the resolved IETF language tag (for example `"zh-CN"`,
   * `"en-US"`).
   *
   * @example
   * ```typescript
   * // Create a collator and inspect the resolved locale
   * const collatorExpr = Expression.collator(
   *   Expression.literal(true),   // case-sensitive
   *   Expression.literal(true),   // diacritic-sensitive
   *   Expression.literal('zh-CN') // desired locale
   * );
   * const localeExpr = Expression.resolvedLocale(collatorExpr);
   *
   * // Style differently based on the active locale
   * fillColor(
   *   Expression.caseExpression(
   *     Expression.eq(
   *       Expression.literal('zh-CN'),
   *       Expression.resolvedLocale(collatorExpr)
   *     ),
   *     Expression.literal('#FF0000'), // Chinese locale uses red
   *     Expression.literal('#0000FF')  // Other locales use blue
   *   )
   * );
   *
   * // Inspect the system default locale (pass null)
   * const defaultCollator = Expression.collator(
   *   Expression.literal(false),
   *   Expression.literal(false),
   *   Expression.literal(null)
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
   * Image expression.
   *
   * @param imageName Image name.
   */
  public static image(imageName: Expression<string>): Expression<Object>;

  /**
   * Image expression (string parameter).
   */
  public static image(imageName: string): Expression<Object>;

  /**
   * Implementation helper for image expressions.
   */
  public static image(imageName: Expression<string> | string): Expression<Object> {
    const imageNameExpr = typeof imageName === 'string' ? Expression.literal(imageName) : imageName;
    return new Expression<Object>('image', imageNameExpr);
  }

  // ==================== Spatial Operators ====================

  /**
   * Compute the distance to a GeoJSON geometry (meters).
   */
  public static distance(geoJson: Object): Expression<number> {
    const map = new Map<string, Expression<Object>>();
    map.set('json', Expression.literal(JSON.stringify(geoJson)));
    return new Expression<number>('distance', new ExpressionMap(map));
  }

  /**
   * Determine whether a feature lies within a polygon.
   */
  public static within(polygon: Object): Expression<boolean> {
    const map = new Map<string, Expression<Object>>();
    const polyObj = polygon as Record<string, Object>;
    const typeValue = polyObj['type'];
    // Choose the appropriate literal overload based on the type of typeValue.
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

  // ==================== Helper Methods ====================

  /**
   * Concatenate two arrays.
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
   * Convert from a JSON array to an Expression.
   *
   * @param json JSON array or value.
   * @return Expression object.
   */
  public static convertFromJson(json: Object | null): Expression<Object> | null {
    if (json === null || json === undefined) {
      return null;
    }

    // Literal values.
    if (typeof json === 'number') {
      return Expression.literal(json);
    } else if (typeof json === 'string') {
      return Expression.literal(json);
    } else if (typeof json === 'boolean') {
      return Expression.literal(json);
    }

    // Array expressions.
    if (Array.isArray(json)) {
      if (json.length === 0) {
        return Expression.literal([]);
      }

      const operator = json[0] as string;

      // Special handling for the literal operator.
      if (operator === 'literal') {
        if (json.length === 2) {
          return Expression.literal(json[1]);
        }
      }

      // Recursively convert arguments.
      const args: Expression[] = [];
      for (let i = 1; i < json.length; i++) {
        const converted = Expression.convertFromJson(json[i]);
        if (converted !== null) {
          args.push(converted);
        }
      }

      // Create the Expression based on the operator.
      return new Expression<Object>(operator, ...args);
    }

    // Objects (used for format, collator, etc.).
    if (typeof json === 'object') {
      // Object types are not handled yet; return null.
      return null;
    }

    return null;
  }

  /**
   * Convert from a JSON string to an Expression.
   *
   * @param jsonString JSON string.
   * @return Expression object.
   */
  public static fromJsonString(jsonString: string): Expression<Object> | null {
    try {
      const json: Object = JSON.parse(jsonString);
      return Expression.convertFromJson(json);
    } catch (e) {
      hilog.error(DOMAIN, 'Expression', '%{public}s', `Failed to parse Expression from JSON: ${e}`);
      return null;
    }
  }
}

/**
 * ExpressionLiteral - literal expression wrapper.
 * @template T Literal value type.
 */
export class ExpressionLiteral<T = ExpressionValue> extends Expression<T> {
  private literal: T;

  constructor(literal: T) {
    super('literal');
    this.literal = literal;
  }

  /**
   * Override to mark this as a value expression.
   * Employs a type guard to narrow to `ValueExpression` inside branches.
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
      // String literals return the value directly; no ["literal", "value"] wrapper is required.
      const unwrapped = this.unwrapStringLiteral(this.literal);
      if (unwrapped === this.literal) {
        return ['literal', this.literal];
      }
      return [unwrapped];
    }
    if (typeof this.literal === 'number' || typeof this.literal === 'boolean' || this.literal === null) {
      // Numbers, booleans, and null can be used as literals directly.
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
* ExpressionLiteralArray - array literal expression.
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
* ExpressionMap - map expression (used by operators such as within and distance).
* @template T Return type.
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
        // Consult the virtual method first, then cast safely.
        const val = value.toValue() as ExpressionValue;
        if (val !== null) {
          unwrappedMap[key] = val;
        }
      } else {
        unwrappedMap[key] = value.toArray() as ExpressionValue;
      }
    });
    // Use Object as an intermediary type to avoid `unknown`.
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

export type PropertyValue<T> = Expression<T> | NativePropertyValue<T>
