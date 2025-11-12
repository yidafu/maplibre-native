/**
 * FormatEntry - helper for format expression entries.
 *
 * Used to configure text segments in `format` expressions.
 */

import { Expression } from './Expression';

/**
 * FormatEntry - represents a formatted text segment.
 */
export class FormatEntry {
  private text: Expression<string>;
  private options: FormatOption[] | null;

  /**
   * Create a formatted entry.
   *
   * @param text Text expression.
   * @param options Formatting options.
   */
  constructor(text: Expression<string>, options: FormatOption[] | null = null) {
    this.text = text;
    this.options = options;
  }

  /**
   * Get the text expression.
   */
  public getText(): Expression<string> {
    return this.text;
  }

  /**
   * Get the formatting options.
   */
  public getOptions(): FormatOption[] | null {
    return this.options;
  }

  /**
   * Factory for a formatted entry.
   */
  public static formatEntry(text: Expression<string>, ...options: FormatOption[]): FormatEntry {
    return new FormatEntry(text, options.length > 0 ? options : null);
  }
}

/**
 * Option - base option class.
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
 * FormatOption - text formatting option.
 */
export class FormatOption extends Option {
  constructor(type: string, value: Expression) {
    super(type, value);
  }

  /**
   * Configure font scale.
   *
   * @param scale Scale expression.
   */
  public static fontScale(scale: Expression<number>): FormatOption;

  /**
   * Configure font scale.
   *
   * @param scale Numeric scale.
   */
  public static fontScale(scale: number): FormatOption;

  /**
   * Implementation helper for font scale.
   */
  public static fontScale(scale: Expression<number> | number): FormatOption {
    const scaleExpr = typeof scale === 'number' ? Expression.literal(scale) : scale;
    return new FormatOption('font-scale', scaleExpr);
  }

  /**
   * Configure text font.
   *
   * @param fonts Font array expression.
   */
  public static textFont(fonts: Expression<string[]>): FormatOption;

  /**
   * Configure text font.
   *
   * @param fonts Font array.
   */
  public static textFont(fonts: string[]): FormatOption;

  /**
   * Implementation helper for text font.
   */
  public static textFont(fonts: Expression<string[]> | string[]): FormatOption {
    const fontsExpr = Array.isArray(fonts) ? Expression.literal(fonts) : fonts;
    return new FormatOption('text-font', fontsExpr);
  }

  /**
   * Configure text color.
   *
   * @param color Color expression.
   */
  public static textColor(color: Expression<string>): FormatOption;

  /**
   * Configure text color.
   *
   * @param color Color string.
   */
  public static textColor(color: string): FormatOption;

  /**
   * Implementation helper for text color.
   */
  public static textColor(color: Expression<string> | string): FormatOption {
    const colorExpr = typeof color === 'string' ? Expression.literal(color) : color;
    return new FormatOption('text-color', colorExpr);
  }
}

/**
 * NumberFormatOption - numeric formatting option.
 */
export class NumberFormatOption extends Option {
  constructor(type: string, value: Expression) {
    super(type, value);
  }

  /**
   * Configure locale.
   *
   * @param locale BCP 47 language tag expression.
   */
  public static locale(locale: Expression<string>): NumberFormatOption;

  /**
   * Configure locale.
   *
   * @param locale BCP 47 language tag.
   */
  public static locale(locale: string): NumberFormatOption;

  /**
   * Implementation helper for locale.
   */
  public static locale(locale: Expression<string> | string): NumberFormatOption {
    const localeExpr = typeof locale === 'string' ? Expression.literal(locale) : locale;
    return new NumberFormatOption('locale', localeExpr);
  }

  /**
   * Configure currency code.
   *
   * @param currency ISO 4217 code expression.
   */
  public static currency(currency: Expression<string>): NumberFormatOption;

  /**
   * Configure currency code.
   *
   * @param currency ISO 4217 code.
   */
  public static currency(currency: string): NumberFormatOption;

  /**
   * Implementation helper for currency.
   */
  public static currency(currency: Expression<string> | string): NumberFormatOption {
    const currencyExpr = typeof currency === 'string' ? Expression.literal(currency) : currency;
    return new NumberFormatOption('currency', currencyExpr);
  }

  /**
   * Configure minimum fraction digits.
   *
   * @param digits Digits expression.
   */
  public static minFractionDigits(digits: Expression<number>): NumberFormatOption;

  /**
   * Configure minimum fraction digits.
   *
   * @param digits Digits value.
   */
  public static minFractionDigits(digits: number): NumberFormatOption;

  /**
   * Implementation helper for minimum fraction digits.
   */
  public static minFractionDigits(digits: Expression<number> | number): NumberFormatOption {
    const digitsExpr = typeof digits === 'number' ? Expression.literal(digits) : digits;
    return new NumberFormatOption('min-fraction-digits', digitsExpr);
  }

  /**
   * Configure maximum fraction digits.
   *
   * @param digits Digits expression.
   */
  public static maxFractionDigits(digits: Expression<number>): NumberFormatOption;

  /**
   * Configure maximum fraction digits.
   *
   * @param digits Digits value.
   */
  public static maxFractionDigits(digits: number): NumberFormatOption;

  /**
   * Implementation helper for maximum fraction digits.
   */
  public static maxFractionDigits(digits: Expression<number> | number): NumberFormatOption {
    const digitsExpr = typeof digits === 'number' ? Expression.literal(digits) : digits;
    return new NumberFormatOption('max-fraction-digits', digitsExpr);
  }
}

