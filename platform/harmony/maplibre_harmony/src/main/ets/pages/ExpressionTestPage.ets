/**
 * ExpressionTestPage - Expression 系统测试页面
 * 
 * 测试各种 Expression 操作符的功能
 */

import { router } from '@kit.ArkUI';
import { Expression, Interpolator, Stop } from '../maps/style/expressions';
import { CircleLayer } from '../maps/style/layers/CircleLayer';
import { PropertyFactory } from '../maps/style/layers/PropertyFactory';

@Entry
@Component
struct ExpressionTestPage {
  @State testResults: string[] = [];

  aboutToAppear() {
    this.runTests();
  }

  /**
   * 运行所有测试
   */
  private runTests() {
    this.testResults = [];
    
    this.testLiteralExpressions();
    this.testColorExpressions();
    this.testDataAccessExpressions();
    this.testComparisonExpressions();
    this.testLogicalExpressions();
    this.testMathExpressions();
    this.testStringExpressions();
    this.testInterpolationExpressions();
    this.testConditionalExpressions();
    this.testLayerIntegration();
  }

  /**
   * 测试字面量表达式
   */
  private testLiteralExpressions() {
    this.addTest('Literal Expressions', () => {
      const numLiteral = Expression.literal(42);
      const strLiteral = Expression.literal('hello');
      const boolLiteral = Expression.literal(true);
      const arrayLiteral = Expression.literal([1, 2, 3]);
      
      return `Number: ${JSON.stringify(numLiteral.toArray())}, ` +
             `String: ${JSON.stringify(strLiteral.toArray())}, ` +
             `Boolean: ${JSON.stringify(boolLiteral.toArray())}, ` +
             `Array: ${JSON.stringify(arrayLiteral.toArray())}`;
    });
  }

  /**
   * 测试颜色表达式
   */
  private testColorExpressions() {
    this.addTest('Color Expressions', () => {
      const rgbColor = Expression.rgb(255, 0, 0);
      const rgbaColor = Expression.rgba(0, 255, 0, 0.5);
      
      return `RGB: ${JSON.stringify(rgbColor.toArray())}, ` +
             `RGBA: ${JSON.stringify(rgbaColor.toArray())}`;
    });
  }

  /**
   * 测试数据访问表达式
   */
  private testDataAccessExpressions() {
    this.addTest('Data Access Expressions', () => {
      const getName = Expression.get<string>('name');
      const hasName = Expression.has('name');
      const getId = Expression.id();
      const getType = Expression.geometryType();
      
      return `get: ${JSON.stringify(getName.toArray())}, ` +
             `has: ${JSON.stringify(hasName.toArray())}, ` +
             `id: ${JSON.stringify(getId.toArray())}, ` +
             `type: ${JSON.stringify(getType.toArray())}`;
    });
  }

  /**
   * 测试比较表达式
   */
  private testComparisonExpressions() {
    this.addTest('Comparison Expressions', () => {
      const eq = Expression.eq(Expression.get('value'), 100);
      const gt = Expression.gt(Expression.get('value'), 50);
      const lt = Expression.lt(Expression.get('value'), 150);
      
      return `eq: ${JSON.stringify(eq.toArray())}, ` +
             `gt: ${JSON.stringify(gt.toArray())}, ` +
             `lt: ${JSON.stringify(lt.toArray())}`;
    });
  }

  /**
   * 测试逻辑表达式
   */
  private testLogicalExpressions() {
    this.addTest('Logical Expressions', () => {
      const and = Expression.all(
        Expression.gt(Expression.get('value'), 10),
        Expression.lt(Expression.get('value'), 100)
      );
      const or = Expression.any(
        Expression.eq(Expression.get('type'), 'A'),
        Expression.eq(Expression.get('type'), 'B')
      );
      const not = Expression.not(Expression.has('disabled'));
      
      return `and: ${JSON.stringify(and.toArray())}, ` +
             `or: ${JSON.stringify(or.toArray())}, ` +
             `not: ${JSON.stringify(not.toArray())}`;
    });
  }

  /**
   * 测试数学表达式
   */
  private testMathExpressions() {
    this.addTest('Math Expressions', () => {
      const add = Expression.add(Expression.literal(10), Expression.literal(20));
      const multiply = Expression.multiply(Expression.literal(5), Expression.literal(3));
      const sqrt = Expression.sqrt(Expression.literal(16));
      
      return `add: ${JSON.stringify(add.toArray())}, ` +
             `multiply: ${JSON.stringify(multiply.toArray())}, ` +
             `sqrt: ${JSON.stringify(sqrt.toArray())}`;
    });
  }

  /**
   * 测试字符串表达式
   */
  private testStringExpressions() {
    this.addTest('String Expressions', () => {
      const concat = Expression.concat(
        Expression.literal('Hello '),
        Expression.literal('World')
      );
      const upcase = Expression.upcase(Expression.literal('hello'));
      const downcase = Expression.downcase(Expression.literal('WORLD'));
      
      return `concat: ${JSON.stringify(concat.toArray())}, ` +
             `upcase: ${JSON.stringify(upcase.toArray())}, ` +
             `downcase: ${JSON.stringify(downcase.toArray())}`;
    });
  }

  /**
   * 测试插值表达式
   */
  private testInterpolationExpressions() {
    this.addTest('Interpolation Expressions', () => {
      // 线性插值：根据缩放级别改变半径
      const interpolate = Expression.interpolate(
        Interpolator.linear(),
        Expression.zoom(),
        Expression.literal(5), Expression.literal(2),
        Expression.literal(10), Expression.literal(8),
        Expression.literal(15), Expression.literal(16)
      );
      
      // 阶梯表达式：根据值选择颜色
      const step = Expression.step(
        Expression.get<number>('population'),
        Expression.literal('#ffffcc'),
        Expression.literal(10000), Expression.literal('#c7e9b4'),
        Expression.literal(50000), Expression.literal('#41b6c4'),
        Expression.literal(100000), Expression.literal('#253494')
      );
      
      return `interpolate: ${JSON.stringify(interpolate.toArray()).substring(0, 100)}..., ` +
             `step: ${JSON.stringify(step.toArray()).substring(0, 100)}...`;
    });
  }

  /**
   * 测试条件表达式
   */
  private testConditionalExpressions() {
    this.addTest('Conditional Expressions', () => {
      // Match 表达式：根据类型选择颜色
      const match = Expression.match(
        Expression.get('type'),
        Expression.literal('park'), Expression.literal('#00ff00'),
        Expression.literal('water'), Expression.literal('#0000ff'),
        Expression.literal('#808080') // default
      );
      
      // Case 表达式
      const caseExpr = Expression.switchCase(
        Expression.gt(Expression.get('value'), 100), Expression.literal('high'),
        Expression.gt(Expression.get('value'), 50), Expression.literal('medium'),
        Expression.literal('low')
      );
      
      return `match: ${JSON.stringify(match.toArray()).substring(0, 80)}..., ` +
             `case: ${JSON.stringify(caseExpr.toArray()).substring(0, 80)}...`;
    });
  }

  /**
   * 测试 Layer 集成
   */
  private testLayerIntegration() {
    this.addTest('Layer Integration', () => {
      // 注意：CircleLayer 现在只是 NAPI 类型别名，需要通过 NAPI 创建
      // 这里只测试 Expression 和 PropertyFactory 的功能
      
      // 创建半径 Expression（根据缩放级别插值）
      const radiusExpression = Expression.interpolate(
        Interpolator.linear(),
        Expression.zoom(),
        Expression.literal(5), Expression.literal(2),
        Expression.literal(10), Expression.literal(8)
      );
      
      // 创建颜色 Expression（根据属性值）
      const colorExpression = Expression.match(
        Expression.get('type'),
        Expression.literal('A'), Expression.literal('#ff0000'),
        Expression.literal('B'), Expression.literal('#00ff00'),
        Expression.literal('#0000ff')
      );
      
      // 使用 PropertyFactory 创建属性
      const radiusProperty = PropertyFactory.circleRadius(
        Expression.multiply(Expression.get('size'), Expression.literal(10))
      );
      
      const colorProperty = PropertyFactory.circleColor(
        Expression.rgb(
          Expression.get('red'),
          Expression.get('green'),
          Expression.get('blue')
        )
      );
      
      return `Expression 属性创建成功. ` +
             `radiusProperty: ${radiusProperty.toString()}, ` +
             `colorProperty: ${colorProperty.toString()}`;
    });
  }

  /**
   * 添加测试结果
   */
  private addTest(name: string, testFn: () => string) {
    try {
      const result = testFn();
      this.testResults.push(`✅ ${name}: ${result}`);
    } catch (e) {
      this.testResults.push(`❌ ${name}: ${e.message}`);
    }
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
        
        Text('Expression 系统测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F5F5F5')
      
      Button('重新运行测试')
        .onClick(() => {
          this.runTests();
        })
        .margin({ top: 10, bottom: 10 })
      
      List() {
        ForEach(this.testResults, (result: string, index: number) => {
          ListItem() {
            Text(result)
              .fontSize(12)
              .padding(10)
              .width('100%')
              .backgroundColor(result.startsWith('✅') ? '#e8f5e9' : '#ffebee')
          }
        }, (result: string, index: number) => index.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 1, color: '#e0e0e0' })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#f5f5f5')
  }
}

