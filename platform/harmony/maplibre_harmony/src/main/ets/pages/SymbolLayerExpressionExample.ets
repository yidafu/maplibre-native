/**
 * SymbolLayerExpressionExample - SymbolLayer Expression 使用示例
 * 
 * 演示如何在 SymbolLayer 中使用 Expression 实现数据驱动样式
 */

import { SymbolLayer } from '../maps/style/layers/SymbolLayer';
import { Expression, Interpolator } from '../maps/style/expressions';

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
    const layer = new SymbolLayer('poi-labels', 'poi-source');
    
    // 使用 get 表达式获取要素属性作为文本内容
    layer.setTextField(Expression.get<string>('name'));
    
    // 使用常量值设置文本大小
    layer.setTextSize(14);
    
    return '✅ 示例 1：基本 Expression - 使用 get 表达式获取要素属性';
  }

  /**
   * 示例 2：根据数据属性动态调整图标大小
   */
  private example2_DataDrivenIconSize(): string {
    const layer = new SymbolLayer('icons', 'icon-source');
    
    // 根据 importance 属性设置图标大小
    // importance 值越大，图标越大
    layer.setIconSize(
      Expression.multiply(
        Expression.get<number>('importance'),
        Expression.literal(0.5)
      )
    );
    
    layer.setIconImage('marker');
    
    return '✅ 示例 2：数据驱动图标大小 - 根据 importance 属性动态调整';
  }

  /**
   * 示例 3：根据缩放级别调整文本大小
   */
  private example3_ZoomBasedTextSize(): string {
    const layer = new SymbolLayer('city-labels', 'city-source');
    
    // 使用插值表达式根据缩放级别平滑过渡文本大小
    layer.setTextSize(
      Expression.interpolate(
        Interpolator.linear(),
        Expression.zoom(),
        Expression.literal(8), Expression.literal(10),   // zoom 8 → 10px
        Expression.literal(12), Expression.literal(14),  // zoom 12 → 14px
        Expression.literal(16), Expression.literal(18)   // zoom 16 → 18px
      )
    );
    
    layer.setTextField(Expression.get('name'));
    
    return '✅ 示例 3：缩放级别驱动 - 根据地图缩放级别调整文本大小';
  }

  /**
   * 示例 4：根据属性条件显示不同图标
   */
  private example4_ConditionalIconImage(): string {
    const layer = new SymbolLayer('poi-icons', 'poi-source');
    
    // 根据 category 属性选择不同的图标
    layer.setIconImage(
      Expression.match(
        Expression.get('category'),
        Expression.literal('restaurant'), Expression.literal('icon-restaurant'),
        Expression.literal('hotel'), Expression.literal('icon-hotel'),
        Expression.literal('park'), Expression.literal('icon-park'),
        Expression.literal('museum'), Expression.literal('icon-museum'),
        Expression.literal('icon-default')  // 默认图标
      )
    );
    
    layer.setIconSize(1.2);
    
    return '✅ 示例 4：条件图标 - 根据类别显示不同图标';
  }

  /**
   * 示例 5：根据属性值设置文本颜色
   */
  private example5_ColorByProperty(): string {
    const layer = new SymbolLayer('status-labels', 'status-source');
    
    // 根据 status 属性设置不同的文本颜色
    layer.setTextColor(
      Expression.match(
        Expression.get('status'),
        Expression.literal('active'), Expression.literal('#00ff00'),    // 绿色
        Expression.literal('inactive'), Expression.literal('#ff0000'),  // 红色
        Expression.literal('pending'), Expression.literal('#ffaa00'),   // 橙色
        Expression.literal('#808080')  // 默认灰色
      )
    );
    
    layer.setTextField(Expression.get('label'));
    layer.setTextSize(16);
    
    return '✅ 示例 5：属性驱动颜色 - 根据状态设置不同颜色';
  }

  /**
   * 示例 6：组合多个 Expression
   */
  private example6_CombinedExpressions(): string {
    const layer = new SymbolLayer('places', 'places-source');
    
    // 文本内容：名称 + 人口数量
    layer.setTextField(
      Expression.concat(
        Expression.get<string>('name'),
        Expression.literal(' ('),
        Expression.toString(Expression.get('population')),
        Expression.literal(')')
      )
    );
    
    // 文本大小：同时受缩放级别和重要性影响
    layer.setTextSize(
      Expression.multiply(
        Expression.interpolate(
          Interpolator.linear(),
          Expression.zoom(),
          Expression.literal(8), Expression.literal(1.0),
          Expression.literal(16), Expression.literal(1.5)
        ),
        Expression.add(
          Expression.literal(10),
          Expression.multiply(
            Expression.get<number>('importance'),
            Expression.literal(2)
          )
        )
      )
    );
    
    // 文本透明度：根据人口数量
    layer.setTextOpacity(
      Expression.interpolate(
        Interpolator.linear(),
        Expression.get<number>('population'),
        Expression.literal(1000), Expression.literal(0.3),
        Expression.literal(100000), Expression.literal(1.0)
      )
    );
    
    return '✅ 示例 6：组合表达式 - 多个 Expression 组合使用';
  }

  /**
   * 示例 7：高级文本格式化
   */
  private example7_TextFormatting(): string {
    const layer = new SymbolLayer('labels', 'data-source');
    
    // 根据条件显示不同的文本
    layer.setTextField(
      Expression.switchCase(
        Expression.has('name_en'),
        Expression.get<string>('name_en'),  // 如果有英文名称，使用英文
        Expression.has('name'),
        Expression.get<string>('name'),     // 否则使用默认名称
        Expression.literal('Unnamed')       // 如果都没有，显示 "Unnamed"
      )
    );
    
    // 图标旋转角度：根据方向属性
    layer.setIconRotate(
      Expression.coalesce(
        Expression.get<number>('direction'),  // 优先使用 direction 属性
        Expression.literal(0)                  // 默认为 0
      )
    );
    
    // 图标透明度：距离越远越透明
    layer.setIconOpacity(
      Expression.step(
        Expression.get<number>('distance'),
        Expression.literal(1.0),      // < 1000m: 完全不透明
        Expression.literal(1000), Expression.literal(0.8),   // 1000-5000m: 80%
        Expression.literal(5000), Expression.literal(0.5),   // 5000-10000m: 50%
        Expression.literal(10000), Expression.literal(0.2)   // > 10000m: 20%
      )
    );
    
    return '✅ 示例 7：高级格式化 - 复杂的文本和样式逻辑';
  }

  build() {
    Column() {
      Text('SymbolLayer Expression 示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
      
      Text('以下示例展示了如何在 SymbolLayer 中使用 Expression 实现各种数据驱动样式')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 20 })
      
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

