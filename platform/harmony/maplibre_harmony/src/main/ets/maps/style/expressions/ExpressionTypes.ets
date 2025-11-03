/**
 * ExpressionTypes - Expression 系统的类型定义和接口
 *
 * 直接从 libmaplibre.so 重新导出类型
 */

// 从 libmaplibre.so 重新导出核心表达式类型
export type {
  ExpressionValue, ExpressionLiteral, PropertyValue
} from 'libmaplibre.so';

/**
 * ExpressionType - Expression 类型（向后兼容别名）
 * @deprecated 请使用 PropertyValue<T> 替代
 */
export type ExpressionType<T> = import('libmaplibre.so').PropertyValue<T>;

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
