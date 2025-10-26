/**
 * ExpressionPerformanceTest - Expression 性能测试页面
 * 
 * 测试各种 Expression 的性能和转换效率
 */

import { Expression, Interpolator, Stop } from '../maps/style/expressions';
import { CircleLayer } from '../maps/style/layers/CircleLayer';
import { PropertyFactory } from '../maps/style/layers/PropertyFactory';

interface PerformanceResult {
  name: string;
  operations: number;
  duration: number;
  opsPerSecond: number;
  status: 'success' | 'warning' | 'error';
}

@Entry
@Component
struct ExpressionPerformanceTest {
  @State testResults: PerformanceResult[] = [];
  @State isRunning: boolean = false;
  @State totalTime: number = 0;

  /**
   * 运行所有性能测试
   */
  private async runAllTests() {
    this.isRunning = true;
    this.testResults = [];
    this.totalTime = 0;
    
    const startTime = Date.now();
    
    // 基础操作测试
    await this.testLiteralCreation();
    await this.testGetExpression();
    await this.testMathOperations();
    
    // 复杂表达式测试
    await this.testInterpolateExpression();
    await this.testMatchExpression();
    await this.testNestedExpressions();
    
    // 转换测试
    await this.testToArrayConversion();
    await this.testConverterParsing();
    
    // Layer 集成测试
    await this.testLayerIntegration();
    
    this.totalTime = Date.now() - startTime;
    this.isRunning = false;
  }

  /**
   * 测试字面量创建性能
   */
  private async testLiteralCreation() {
    const iterations = 10000;
    const startTime = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      Expression.literal(i);
      Expression.literal(`string_${i}`);
      Expression.literal(true);
      Expression.literal([1, 2, 3]);
    }
    
    const duration = Date.now() - startTime;
    this.addResult('字面量创建', iterations * 4, duration);
  }

  /**
   * 测试 get 表达式性能
   */
  private async testGetExpression() {
    const iterations = 10000;
    const startTime = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      Expression.get('name');
      Expression.get<number>('value');
      Expression.has('property');
      Expression.id();
    }
    
    const duration = Date.now() - startTime;
    this.addResult('数据访问表达式', iterations * 4, duration);
  }

  /**
   * 测试数学运算性能
   */
  private async testMathOperations() {
    const iterations = 5000;
    const startTime = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      Expression.add(
        Expression.literal(10),
        Expression.literal(20)
      );
      
      Expression.multiply(
        Expression.get<number>('value'),
        Expression.literal(2)
      );
      
      Expression.divide(
        Expression.get<number>('total'),
        Expression.get<number>('count')
      );
    }
    
    const duration = Date.now() - startTime;
    this.addResult('数学运算', iterations * 3, duration);
  }

  /**
   * 测试插值表达式性能
   */
  private async testInterpolateExpression() {
    const iterations = 1000;
    const startTime = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      Expression.interpolate(
        Interpolator.linear(),
        Expression.zoom(),
        Expression.literal(5), Expression.literal(2),
        Expression.literal(10), Expression.literal(8),
        Expression.literal(15), Expression.literal(16)
      );
    }
    
    const duration = Date.now() - startTime;
    this.addResult('插值表达式', iterations, duration);
  }

  /**
   * 测试 match 表达式性能
   */
  private async testMatchExpression() {
    const iterations = 1000;
    const startTime = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      Expression.match(
        Expression.get('type'),
        Expression.literal('A'), Expression.literal('#ff0000'),
        Expression.literal('B'), Expression.literal('#00ff00'),
        Expression.literal('C'), Expression.literal('#0000ff'),
        Expression.literal('#808080')
      );
    }
    
    const duration = Date.now() - startTime;
    this.addResult('Match 表达式', iterations, duration);
  }

  /**
   * 测试嵌套表达式性能
   */
  private async testNestedExpressions() {
    const iterations = 500;
    const startTime = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      // 创建深度嵌套的表达式
      Expression.multiply(
        Expression.add(
          Expression.get<number>('a'),
          Expression.multiply(
            Expression.get<number>('b'),
            Expression.literal(2)
          )
        ),
        Expression.interpolate(
          Interpolator.linear(),
          Expression.zoom(),
          Expression.literal(5), Expression.literal(1),
          Expression.literal(15), Expression.literal(2)
        )
      );
    }
    
    const duration = Date.now() - startTime;
    this.addResult('嵌套表达式', iterations, duration);
  }

  /**
   * 测试 toArray 转换性能
   */
  private async testToArrayConversion() {
    const iterations = 5000;
    
    // 创建测试表达式
    const expressions = [
      Expression.get('name'),
      Expression.interpolate(
        Interpolator.linear(),
        Expression.zoom(),
        Expression.literal(5), Expression.literal(10),
        Expression.literal(15), Expression.literal(20)
      ),
      Expression.match(
        Expression.get('type'),
        Expression.literal('A'), Expression.literal(1),
        Expression.literal('B'), Expression.literal(2),
        Expression.literal(0)
      )
    ];
    
    const startTime = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      for (const expr of expressions) {
        expr.toArray();
      }
    }
    
    const duration = Date.now() - startTime;
    this.addResult('toArray 转换', iterations * expressions.length, duration);
  }

  /**
   * 测试 Converter 解析性能
   */
  private async testConverterParsing() {
    const iterations = 1000;
    
    // 测试 JSON 数据
    const jsonExamples = [
      ['get', 'name'],
      ['interpolate', ['linear'], ['zoom'], 5, 10, 15, 20],
      ['match', ['get', 'type'], 'A', 1, 'B', 2, 0],
      ['+', ['get', 'value'], 10]
    ];
    
    const startTime = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      for (const json of jsonExamples) {
        Expression.Converter.convert(json);
      }
    }
    
    const duration = Date.now() - startTime;
    this.addResult('Converter 解析', iterations * jsonExamples.length, duration);
  }

  /**
   * 测试 Layer 集成性能
   */
  private async testLayerIntegration() {
    const iterations = 1000;
    const startTime = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      const layer = new CircleLayer(`layer_${i}`, 'source');
      
      layer.withCircleRadius(
        Expression.interpolate(
          Interpolator.linear(),
          Expression.zoom(),
          Expression.literal(5), Expression.literal(2),
          Expression.literal(15), Expression.literal(10)
        )
      );
      
      layer.withCircleColor(
        Expression.match(
          Expression.get('category'),
          Expression.literal('A'), Expression.literal('#ff0000'),
          Expression.literal('#0000ff')
        )
      );
      
      layer.withCircleOpacity(Expression.literal(0.8));
    }
    
    const duration = Date.now() - startTime;
    this.addResult('Layer 集成', iterations, duration);
  }

  /**
   * 添加测试结果
   */
  private addResult(name: string, operations: number, duration: number) {
    const opsPerSecond = Math.round(operations / (duration / 1000));
    
    let status: 'success' | 'warning' | 'error' = 'success';
    if (opsPerSecond < 1000) {
      status = 'error';
    } else if (opsPerSecond < 5000) {
      status = 'warning';
    }
    
    this.testResults.push({
      name,
      operations,
      duration,
      opsPerSecond,
      status
    });
  }

  build() {
    Column() {
      Text('Expression 性能测试')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
      
      if (!this.isRunning) {
        Button('开始测试')
          .width('80%')
          .height(50)
          .onClick(() => {
            this.runAllTests();
          })
          .margin({ bottom: 20 })
      } else {
        Row() {
          LoadingProgress()
            .width(30)
            .height(30)
            .margin({ right: 10 })
          
          Text('测试中...')
            .fontSize(16)
        }
        .margin({ bottom: 20 })
      }
      
      if (this.testResults.length > 0) {
        Column() {
          Text(`总耗时: ${this.totalTime}ms`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10 })
          
          List() {
            ForEach(this.testResults, (result: PerformanceResult) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(result.status === 'success' ? '✅' : result.status === 'warning' ? '⚠️' : '❌')
                      .fontSize(20)
                      .margin({ right: 10 })
                    
                    Text(result.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .margin({ bottom: 5 })
                  
                  Text(`操作数: ${result.operations.toLocaleString()}`)
                    .fontSize(12)
                    .fontColor('#666666')
                  
                  Text(`耗时: ${result.duration}ms`)
                    .fontSize(12)
                    .fontColor('#666666')
                  
                  Text(`速度: ${result.opsPerSecond.toLocaleString()} ops/s`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(
                      result.status === 'success' ? '#00aa00' :
                      result.status === 'warning' ? '#ff8800' : '#ff0000'
                    )
                }
                .width('100%')
                .padding(15)
                .backgroundColor(
                  result.status === 'success' ? '#e8f5e9' :
                  result.status === 'warning' ? '#fff8e1' : '#ffebee'
                )
                .borderRadius(8)
              }
              .margin({ bottom: 10 })
            }, (result: PerformanceResult) => result.name)
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 20, right: 20 })
      }
      
      Column() {
        Text('性能评级标准')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Text('✅ 优秀: > 5000 ops/s')
          .fontSize(12)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 5 })
        
        Text('⚠️ 一般: 1000 - 5000 ops/s')
          .fontSize(12)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 5 })
        
        Text('❌ 需优化: < 1000 ops/s')
          .fontSize(12)
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#f0f0f0')
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}

