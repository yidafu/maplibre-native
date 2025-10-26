/**
 * ExpressionTypes - Expression 系统的类型定义和接口
 */

/**
 * ValueExpression 接口
 * 用于可以直接转换为值的表达式
 */
export interface ValueExpression {
  /**
   * 将表达式转换为原始值
   */
  toValue(): Object | null;
}

/**
 * Expression 支持的值类型
 */
export type ExpressionValue = number | string | boolean | null | Object | ExpressionValue[];

/**
 * Collator 选项
 */
export interface CollatorOptions {
  caseSensitive?: boolean;
  diacriticSensitive?: boolean;
  locale?: string;
}

/**
 * Format 选项
 */
export interface FormatOptions {
  fontScale?: number;
  textFont?: string[];
  textColor?: string;
}

/**
 * Number Format 选项
 */
export interface NumberFormatOptions {
  locale?: string;
  currency?: string;
  minFractionDigits?: number;
  maxFractionDigits?: number;
}

