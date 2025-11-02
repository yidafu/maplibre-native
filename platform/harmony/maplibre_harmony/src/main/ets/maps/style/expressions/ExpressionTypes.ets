/**
 * ExpressionTypes - Expression 系统的类型定义和接口
 */

// 从 libmaplibre.so 重新导出核心表达式类型
export type { ExpressionValue, ExpressionLiteral } from 'libmaplibre.so';

/**
 * ValueExpression 接口
 * 用于可以直接转换为值的表达式
 * @template T 表达式返回值的类型
 */
export interface ValueExpression<T = Object> {
  /**
   * 将表达式转换为原始值
   */
  toValue(): T | null;
}

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

