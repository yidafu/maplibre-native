/**
 * SymbolLayerExpressionExample - SymbolLayer Expression 使用示例
 * 
 * 演示如何在 SymbolLayer 中使用 Expression 实现数据驱动样式
 */

import { router } from '@kit.ArkUI';
import { SymbolLayer } from 'maplibre_harmony/src/main/ets/maps/style/layers/SymbolLayer';
import { Expression, Interpolator } from 'maplibre_harmony/src/main/ets/maps/style/expressions';

@Entry
@Component
struct SymbolLayerExpressionExample {
  @State examples: string[] = [];

  aboutToAppear() {
    this.generateExamples();
  }

  /**
   * 生成各种 Expression 使用示例
   */
  private generateExamples() {
    this.examples = [
      this.example1_BasicExpression(),
      this.example2_DataDrivenIconSize(),
      this.example3_ZoomBasedTextSize(),
      this.example4_ConditionalIconImage(),
      this.example5_ColorByProperty(),
      this.example6_CombinedExpressions(),
      this.example7_TextFormatting()
    ];
  }

  /**
   * 示例 1：基本 Expression 使用
   */
  private example1_BasicExpression(): string {
    // 注意：SymbolLayer 现在只是 NAPI 类型别名，需要通过地图 API 创建
    // 这里只展示 Expression 的创建
    
    // 创建 Expression：获取要素属性作为文本内容
    const textFieldExpr = Expression.get('name');
    
    return `✅ 示例 1：基本 Expression - 使用 get('name') 获取要素属性`;
  }

  /**
   * 示例 2：根据数据属性动态调整图标大小
   */
  private example2_DataDrivenIconSize(): string {
    // 创建 Expression：图标大小根据 importance 属性动态调整
    const iconSizeExpr = Expression.multiply(
      Expression.get('importance'),
      Expression.literal(0.5)
    );
    
    return `✅ 示例 2：数据驱动图标大小 - multiply(get('importance'), 0.5)`;
  }

  /**
   * 示例 3：根据缩放级别调整文本大小
   */
  private example3_ZoomBasedTextSize(): string {
    // 创建 Expression：文本大小根据缩放级别插值
    const textSizeExpr = Expression.interpolate(
      Interpolator.linear(),
      Expression.zoom(),
      Expression.literal(8), Expression.literal(10),
      Expression.literal(12), Expression.literal(14),
      Expression.literal(16), Expression.literal(18)
    );
    
    return `✅ 示例 3：缩放级别驱动 - interpolate(zoom(), 8→10px, 12→14px, 16→18px)`;
  }

  /**
   * 示例 4：根据属性条件显示不同图标
   */
  private example4_ConditionalIconImage(): string {
    // 创建 Expression：根据类别选择不同图标
    const iconImageExpr = Expression.match(
      Expression.get('category'),
      Expression.literal('restaurant'), Expression.literal('icon-restaurant'),
      Expression.literal('hotel'), Expression.literal('icon-hotel'),
      Expression.literal('park'), Expression.literal('icon-park'),
      Expression.literal('museum'), Expression.literal('icon-museum'),
      Expression.literal('icon-default')
    );
    
    return `✅ 示例 4：条件图标 - match(category, restaurant→icon-restaurant, ...)`;
  }

  /**
   * 示例 5：根据属性值设置文本颜色
   */
  private example5_ColorByProperty(): string {
    // 创建 Expression：根据状态设置文本颜色
    const textColorExpr = Expression.match(
      Expression.get('status'),
      Expression.literal('active'), Expression.literal('#00ff00'),
      Expression.literal('inactive'), Expression.literal('#ff0000'),
      Expression.literal('pending'), Expression.literal('#ffaa00'),
      Expression.literal('#808080')
    );
    
    return `✅ 示例 5：属性驱动颜色 - match(status, active→绿色, inactive→红色, ...)`;
  }

  /**
   * 示例 6：组合多个 Expression
   */
  private example6_CombinedExpressions(): string {
    // 创建组合 Expression：文本内容 = 名称 + 人口数量
    const textFieldExpr = Expression.concat(
      Expression.get('name'),
      Expression.literal(' ('),
      Expression.toString(Expression.get('population')),
      Expression.literal(')')
    );
    
    // 文本大小：缩放级别 × (10 + importance × 2)
    const textSizeExpr = Expression.multiply(
      Expression.interpolate(
        Interpolator.linear(),
        Expression.zoom(),
        Expression.literal(8), Expression.literal(1.0),
        Expression.literal(16), Expression.literal(1.5)
      ),
      Expression.add(
        Expression.literal(10),
        Expression.multiply(
          Expression.get('importance'),
          Expression.literal(2)
        )
      )
    );
    
    return `✅ 示例 6：组合表达式 - concat + multiply + interpolate 组合使用`;
  }

  /**
   * 示例 7：高级文本格式化
   */
  private example7_TextFormatting(): string {
    // 创建 Expression：条件文本
    const textFieldExpr = Expression.switchCase(
      Expression.has('name_en'),
      Expression.get('name_en'),
      Expression.has('name'),
      Expression.get('name'),
      Expression.literal('Unnamed')
    );
    
    // 创建 Expression：图标旋转角度
    const iconRotateExpr = Expression.coalesce(
      Expression.get('direction'),
      Expression.literal(0)
    );
    
    // 创建 Expression：图标透明度阶梯
    const iconOpacityExpr = Expression.step(
      Expression.get('distance'),
      Expression.literal(1.0),
      Expression.literal(1000), Expression.literal(0.8),
      Expression.literal(5000), Expression.literal(0.5),
      Expression.literal(10000), Expression.literal(0.2)
    );
    
    return `✅ 示例 7：高级格式化 - switchCase + coalesce + step 组合`;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#2196F3')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 5 })
        
        Text('SymbolLayer Expression 示例')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F5F5F5')
      
      Text('以下示例展示了如何在 SymbolLayer 中使用 Expression 实现各种数据驱动样式')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10, bottom: 10 })
        .padding({ left: 16, right: 16 })
      
      List() {
        ForEach(this.examples, (example: string, index: number) => {
          ListItem() {
            Text(example)
              .fontSize(13)
              .padding(15)
              .width('100%')
              .backgroundColor('#f0f8ff')
              .borderRadius(8)
          }
          .margin({ bottom: 10 })
        }, (example: string, index: number) => index.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20 })
      
      Text('说明')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })
        .alignSelf(ItemAlign.Start)
        .margin({ left: 20 })
      
      Column() {
        Text('• Expression 支持所有 SymbolLayer 属性')
          .fontSize(12)
          .margin({ bottom: 5 })
          .alignSelf(ItemAlign.Start)
        
        Text('• 可以根据要素属性、缩放级别等动态调整样式')
          .fontSize(12)
          .margin({ bottom: 5 })
          .alignSelf(ItemAlign.Start)
        
        Text('• 支持插值、条件判断、数学运算等高级操作')
          .fontSize(12)
          .margin({ bottom: 5 })
          .alignSelf(ItemAlign.Start)
        
        Text('• Expression 可以组合使用实现复杂的样式逻辑')
          .fontSize(12)
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#fffacd')
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}

