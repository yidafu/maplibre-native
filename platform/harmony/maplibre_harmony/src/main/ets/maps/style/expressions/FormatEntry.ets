/**
 * FormatEntry - 格式化入口类
 * 
 * 用于 format 表达式中的文本格式化
 */

import { Expression } from './Expression';

/**
 * FormatEntry - 格式化入口
 */
export class FormatEntry {
  private text: Expression<string>;
  private options: FormatOption[] | null;

  /**
   * 创建格式化入口
   * 
   * @param text 文本表达式
   * @param options 格式化选项
   */
  constructor(text: Expression<string>, options: FormatOption[] | null = null) {
    this.text = text;
    this.options = options;
  }

  /**
   * 获取文本表达式
   */
  public getText(): Expression<string> {
    return this.text;
  }

  /**
   * 获取格式化选项
   */
  public getOptions(): FormatOption[] | null {
    return this.options;
  }

  /**
   * 创建格式化入口（工厂方法）
   */
  public static formatEntry(text: Expression<string>, ...options: FormatOption[]): FormatEntry {
    return new FormatEntry(text, options.length > 0 ? options : null);
  }
}

/**
 * Option - 选项基类
 */
class Option {
  protected type: string;
  protected value: Expression;

  constructor(type: string, value: Expression) {
    this.type = type;
    this.value = value;
  }

  public getType(): string {
    return this.type;
  }

  public getValue(): Expression {
    return this.value;
  }
}

/**
 * FormatOption - 格式化选项
 */
export class FormatOption extends Option {
  constructor(type: string, value: Expression) {
    super(type, value);
  }

  /**
   * 设置字体缩放比例
   * 
   * @param scale 缩放比例（Expression）
   */
  public static fontScale(scale: Expression<number>): FormatOption;

  /**
   * 设置字体缩放比例
   * 
   * @param scale 缩放比例（数字）
   */
  public static fontScale(scale: number): FormatOption;

  /**
   * 设置字体缩放比例的实现
   */
  public static fontScale(scale: Expression<number> | number): FormatOption {
    const scaleExpr = typeof scale === 'number' ? Expression.literal(scale) : scale;
    return new FormatOption('font-scale', scaleExpr);
  }

  /**
   * 设置文本字体
   * 
   * @param fonts 字体数组（Expression）
   */
  public static textFont(fonts: Expression<string[]>): FormatOption;

  /**
   * 设置文本字体
   * 
   * @param fonts 字体数组
   */
  public static textFont(fonts: string[]): FormatOption;

  /**
   * 设置文本字体的实现
   */
  public static textFont(fonts: Expression<string[]> | string[]): FormatOption {
    const fontsExpr = Array.isArray(fonts) ? Expression.literal(fonts) : fonts;
    return new FormatOption('text-font', fontsExpr);
  }

  /**
   * 设置文本颜色
   * 
   * @param color 颜色（Expression）
   */
  public static textColor(color: Expression<string>): FormatOption;

  /**
   * 设置文本颜色
   * 
   * @param color 颜色字符串
   */
  public static textColor(color: string): FormatOption;

  /**
   * 设置文本颜色的实现
   */
  public static textColor(color: Expression<string> | string): FormatOption {
    const colorExpr = typeof color === 'string' ? Expression.literal(color) : color;
    return new FormatOption('text-color', colorExpr);
  }
}

/**
 * NumberFormatOption - 数字格式化选项
 */
export class NumberFormatOption extends Option {
  constructor(type: string, value: Expression) {
    super(type, value);
  }

  /**
   * 设置区域设置
   * 
   * @param locale BCP 47 语言标签（Expression）
   */
  public static locale(locale: Expression<string>): NumberFormatOption;

  /**
   * 设置区域设置
   * 
   * @param locale BCP 47 语言标签
   */
  public static locale(locale: string): NumberFormatOption;

  /**
   * 设置区域设置的实现
   */
  public static locale(locale: Expression<string> | string): NumberFormatOption {
    const localeExpr = typeof locale === 'string' ? Expression.literal(locale) : locale;
    return new NumberFormatOption('locale', localeExpr);
  }

  /**
   * 设置货币代码
   * 
   * @param currency ISO 4217 货币代码（Expression）
   */
  public static currency(currency: Expression<string>): NumberFormatOption;

  /**
   * 设置货币代码
   * 
   * @param currency ISO 4217 货币代码
   */
  public static currency(currency: string): NumberFormatOption;

  /**
   * 设置货币代码的实现
   */
  public static currency(currency: Expression<string> | string): NumberFormatOption {
    const currencyExpr = typeof currency === 'string' ? Expression.literal(currency) : currency;
    return new NumberFormatOption('currency', currencyExpr);
  }

  /**
   * 设置最小小数位数
   * 
   * @param digits 最小小数位数（Expression）
   */
  public static minFractionDigits(digits: Expression<number>): NumberFormatOption;

  /**
   * 设置最小小数位数
   * 
   * @param digits 最小小数位数
   */
  public static minFractionDigits(digits: number): NumberFormatOption;

  /**
   * 设置最小小数位数的实现
   */
  public static minFractionDigits(digits: Expression<number> | number): NumberFormatOption {
    const digitsExpr = typeof digits === 'number' ? Expression.literal(digits) : digits;
    return new NumberFormatOption('min-fraction-digits', digitsExpr);
  }

  /**
   * 设置最大小数位数
   * 
   * @param digits 最大小数位数（Expression）
   */
  public static maxFractionDigits(digits: Expression<number>): NumberFormatOption;

  /**
   * 设置最大小数位数
   * 
   * @param digits 最大小数位数
   */
  public static maxFractionDigits(digits: number): NumberFormatOption;

  /**
   * 设置最大小数位数的实现
   */
  public static maxFractionDigits(digits: Expression<number> | number): NumberFormatOption {
    const digitsExpr = typeof digits === 'number' ? Expression.literal(digits) : digits;
    return new NumberFormatOption('max-fraction-digits', digitsExpr);
  }
}

