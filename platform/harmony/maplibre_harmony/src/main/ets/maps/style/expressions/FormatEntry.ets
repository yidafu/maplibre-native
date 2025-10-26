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
  public static fontScale(scale: Expression<number>): FormatOption {
    return new FormatOption('font-scale', scale);
  }

  /**
   * 设置字体缩放比例
   * 
   * @param scale 缩放比例（数字）
   */
  public static fontScale(scale: number): FormatOption {
    return FormatOption.fontScale(Expression.literal(scale));
  }

  /**
   * 设置文本字体
   * 
   * @param fonts 字体数组（Expression）
   */
  public static textFont(fonts: Expression<string[]>): FormatOption {
    return new FormatOption('text-font', fonts);
  }

  /**
   * 设置文本字体
   * 
   * @param fonts 字体数组
   */
  public static textFont(fonts: string[]): FormatOption {
    return FormatOption.textFont(Expression.literal(fonts));
  }

  /**
   * 设置文本颜色
   * 
   * @param color 颜色（Expression）
   */
  public static textColor(color: Expression<string>): FormatOption {
    return new FormatOption('text-color', color);
  }

  /**
   * 设置文本颜色
   * 
   * @param color 颜色字符串
   */
  public static textColor(color: string): FormatOption {
    return FormatOption.textColor(Expression.literal(color));
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
  public static locale(locale: Expression<string>): NumberFormatOption {
    return new NumberFormatOption('locale', locale);
  }

  /**
   * 设置区域设置
   * 
   * @param locale BCP 47 语言标签
   */
  public static locale(locale: string): NumberFormatOption {
    return NumberFormatOption.locale(Expression.literal(locale));
  }

  /**
   * 设置货币代码
   * 
   * @param currency ISO 4217 货币代码（Expression）
   */
  public static currency(currency: Expression<string>): NumberFormatOption {
    return new NumberFormatOption('currency', currency);
  }

  /**
   * 设置货币代码
   * 
   * @param currency ISO 4217 货币代码
   */
  public static currency(currency: string): NumberFormatOption {
    return NumberFormatOption.currency(Expression.literal(currency));
  }

  /**
   * 设置最小小数位数
   * 
   * @param digits 最小小数位数（Expression）
   */
  public static minFractionDigits(digits: Expression<number>): NumberFormatOption {
    return new NumberFormatOption('min-fraction-digits', digits);
  }

  /**
   * 设置最小小数位数
   * 
   * @param digits 最小小数位数
   */
  public static minFractionDigits(digits: number): NumberFormatOption {
    return NumberFormatOption.minFractionDigits(Expression.literal(digits));
  }

  /**
   * 设置最大小数位数
   * 
   * @param digits 最大小数位数（Expression）
   */
  public static maxFractionDigits(digits: Expression<number>): NumberFormatOption {
    return new NumberFormatOption('max-fraction-digits', digits);
  }

  /**
   * 设置最大小数位数
   * 
   * @param digits 最大小数位数
   */
  public static maxFractionDigits(digits: number): NumberFormatOption {
    return NumberFormatOption.maxFractionDigits(Expression.literal(digits));
  }
}

