/**
 * CollatorExpression - 字符串比较器表达式
 * 
 * 用于在字符串比较操作中指定区域设置特定的比较规则
 */

import { Expression, ExpressionLiteral } from './Expression';
import { CollatorOptions, ValueExpression } from './ExpressionTypes';

/**
 * Collator 表达式类
 */
export class CollatorExpression<T extends  Object> extends Expression<T> {
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
  ): CollatorExpression<boolean>;

  /**
   * 创建 Collator 表达式（使用选项对象）
   * 
   * @param options Collator 选项
   */
  public static collator(options: CollatorOptions): CollatorExpression<boolean>;

  /**
   * 创建 Collator 表达式的实现
   */
  public static collator(
    caseSensitiveOrOptions: Expression<boolean> | CollatorOptions,
    diacriticSensitive?: Expression<boolean>,
    locale?: Expression<string>
  ): CollatorExpression<boolean> {
    const optionsMap = new Map<string, Expression>();
    
    // 判断是否使用选项对象
    if (diacriticSensitive === undefined && locale === undefined) {
      // 使用选项对象
      const options = caseSensitiveOrOptions as CollatorOptions;
      
      if (options.caseSensitive !== undefined) {
        optionsMap.set('case-sensitive', Expression.literal(options.caseSensitive));
      }
      if (options.diacriticSensitive !== undefined) {
        optionsMap.set('diacritic-sensitive', Expression.literal(options.diacriticSensitive));
      }
      if (options.locale !== undefined) {
        optionsMap.set('locale', Expression.literal(options.locale));
      }
    } else {
      // 使用三个 Expression 参数
      optionsMap.set('case-sensitive', caseSensitiveOrOptions as Expression<boolean>);
      optionsMap.set('diacritic-sensitive', diacriticSensitive!);
      optionsMap.set('locale', locale!);
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

  public toArray(): (Object | null)[] {
    const result: Record<string, Object | null> = {};
    this.options.forEach((value: Expression, key: string) => {
      if (value.isValue()) {
        // 使用虚方法判断，然后安全转换
        result[key] = (value as ExpressionLiteral).toValue();
      } else {
        result[key] = value.toArray() as Object;
      }
    });
    return [result];
  }
}

