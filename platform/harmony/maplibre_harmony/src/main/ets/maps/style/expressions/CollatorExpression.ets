/**
 * CollatorExpression - 字符串比较器表达式
 * 
 * 用于在字符串比较操作中指定区域设置特定的比较规则
 */

import { Expression } from './Expression';
import { CollatorOptions } from './ExpressionTypes';

/**
 * Collator 表达式类
 */
export class CollatorExpression extends Expression<any> {
  /**
   * 创建 Collator 表达式
   * 
   * @param caseSensitive 是否区分大小写
   * @param diacriticSensitive 是否区分变音符号
   * @param locale 区域设置（BCP 47 语言标签）
   */
  public static collator(
    caseSensitive: Expression<boolean>,
    diacriticSensitive: Expression<boolean>,
    locale: Expression<string>
  ): CollatorExpression {
    const options = new Map<string, Expression>();
    options.set('case-sensitive', caseSensitive);
    options.set('diacritic-sensitive', diacriticSensitive);
    options.set('locale', locale);
    
    return new CollatorExpression('collator', new CollatorOptionsExpression(options));
  }

  /**
   * 创建 Collator 表达式（使用选项对象）
   * 
   * @param options Collator 选项
   */
  public static collator(options: CollatorOptions): CollatorExpression {
    const optionsMap = new Map<string, Expression>();
    
    if (options.caseSensitive !== undefined) {
      optionsMap.set('case-sensitive', Expression.literal(options.caseSensitive));
    }
    if (options.diacriticSensitive !== undefined) {
      optionsMap.set('diacritic-sensitive', Expression.literal(options.diacriticSensitive));
    }
    if (options.locale !== undefined) {
      optionsMap.set('locale', Expression.literal(options.locale));
    }
    
    return new CollatorExpression('collator', new CollatorOptionsExpression(optionsMap));
  }
}

/**
 * CollatorOptionsExpression - Collator 选项表达式
 */
class CollatorOptionsExpression extends Expression<Object> {
  private options: Map<string, Expression>;

  constructor(options: Map<string, Expression>) {
    super('collator-options');
    this.options = options;
  }

  public toArray(): Object[] {
    const result: Record<string, Object | null> = {};
    this.options.forEach((value: Expression, key: string) => {
      if (this.isValueExpression(value)) {
        result[key] = (value as any).toValue();
      } else {
        result[key] = value.toArray();
      }
    });
    return [result];
  }
}

