/**
 * ExpressionTypes - type definitions and interfaces for the expression system.
 *
 * Re-exports core types from `libmaplibre.so`.
 */

// Re-export core expression types from libmaplibre.
export type {
  ExpressionValue, ExpressionLiteral, PropertyValue
} from 'libmaplibre.so';

/**
 * Collator options.
 */
export interface CollatorOptions {
  caseSensitive?: boolean;
  diacriticSensitive?: boolean;
  locale?: string;
}

/**
 * Format options.
 */
export interface FormatOptions {
  fontScale?: number;
  textFont?: string[];
  textColor?: string;
}

/**
 * Number format options.
 */
export interface NumberFormatOptions {
  locale?: string;
  currency?: string;
  minFractionDigits?: number;
  maxFractionDigits?: number;
}
