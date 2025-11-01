import { 
  FillLayer,
  LineLayer,
  CircleLayer,
  SymbolLayer,
  Expression,
  GeoJsonSource,
  MapLibreMap,
  NativeMapView
,  Interpolator} from 'maplibre_harmony';
import { router } from '@kit.ArkUI';

/**
 * ExpressionRealWorldExamples - Expression 真实场景示例
 * 
 * 展示 Expression 在实际地图应用中的典型使用场景
 */

// 示例项接口
interface ExampleItem {
  title: string;
  description: string;
}

@Entry
@Component
struct ExpressionRealWorldExamples {
  @State selectedExample: number = 0;
  @State exampleCode: string = '';

  private examples: ExampleItem[] = [
    { title: '🏙️ 城市人口地图', description: '根据人口数量显示不同大小和颜色的城市标记' },
    { title: '🚗 实时交通状态', description: '根据交通状况显示不同颜色的道路' },
    { title: '🏪 POI 分类显示', description: '根据类型显示不同图标和样式的兴趣点' },
    { title: '🏘️ 房价热力图', description: '根据房价区间显示不同颜色的区域' },
    { title: '🌡️ 温度可视化', description: '根据温度值显示渐变颜色' },
    { title: '📊 数据统计图', description: '根据统计数据动态调整标记大小' },
    { title: '🚇 地铁线路图', description: '不同线路显示不同颜色和宽度' },
    { title: '⭐ 评分展示', description: '根据评分显示星级和颜色' }
  ]

  aboutToAppear() {
    this.generateExampleCode(0);
  }

  /**
   * 生成示例代码
   */
  private generateExampleCode(index: number) {
    this.selectedExample = index;
    
    switch (index) {
      case 0:
        this.exampleCode = this.getCityPopulationExample();
        break;
      case 1:
        this.exampleCode = this.getTrafficExample();
        break;
      case 2:
        this.exampleCode = this.getPOIExample();
        break;
      case 3:
        this.exampleCode = this.getHousePriceExample();
        break;
      case 4:
        this.exampleCode = this.getTemperatureExample();
        break;
      case 5:
        this.exampleCode = this.getDataVisualizationExample();
        break;
      case 6:
        this.exampleCode = this.getSubwayLineExample();
        break;
      case 7:
        this.exampleCode = this.getRatingExample();
        break;
    }
  }

  /**
   * 场景 1：城市人口地图
   */
  private getCityPopulationExample(): string {
    // 注意：CircleLayer 现在只是 NAPI 类型别名，需要通过地图 API 创建
    // 这里只返回示例代码字符串
    
    return `// 🏙️ 城市人口地图示例
// 根据人口数量动态调整标记大小、颜色和透明度

const layer = new CircleLayer('cities', 'cities-source');

// 1. 圆圈大小：指数插值（人口越多，增长越快）
layer.withCircleRadius(
  Expression.interpolate(
    Interpolator.exponential(1.5),  // 指数基数 1.5
    Expression.get('population'),
    10000, 4,        // 1万人 → 4px
    100000, 8,       // 10万人 → 8px
    1000000, 16,     // 100万人 → 16px
    10000000, 32     // 1000万人 → 32px
  )
);

// 2. 颜色：阶梯式分级
layer.withCircleColor(
  Expression.step(
    Expression.get('population'),
    '#ffffb2',       // 默认：浅黄
    100000, '#fecc5c',    // 10万+：黄色
    500000, '#fd8d3c',    // 50万+：橙色
    1000000, '#f03b20',   // 100万+：红色
    5000000, '#bd0026'    // 500万+：深红
  )
);

// 3. 透明度：随缩放级别线性变化
layer.withCircleOpacity(
  Expression.interpolate(
    Interpolator.linear(),
    Expression.zoom(),
    4, 0.3,    // 小缩放级别：半透明
    8, 0.8,
    12, 1.0    // 大缩放级别：不透明
  )
);`;
  }

  /**
   * 场景 2：实时交通状态
   */
  private getTrafficExample(): string {
    return `// 🚗 实时交通状态地图
// 根据交通拥堵程度显示不同颜色和宽度的道路

const roadLayer = new LineLayer('roads', 'roads-source');

// 1. 道路颜色：根据拥堵等级
roadLayer.withLineColor(
  Expression.match(
    Expression.get('traffic_level'),
    'smooth', '#00ff00',      // 畅通：绿色
    'slow', '#ffff00',        // 缓慢：黄色
    'congested', '#ff8800',   // 拥堵：橙色
    'jam', '#ff0000',         // 严重拥堵：红色
    '#808080'                 // 默认：灰色
  )
);

// 2. 道路宽度：根据道路等级和缩放级别
roadLayer.withLineWidth(
  Expression.multiply(
    // 基础宽度（根据缩放级别）
    Expression.interpolate(
      Interpolator.linear(),
      Expression.zoom(),
      8, 0.5,
      12, 2,
      16, 6
    ),
    // 道路等级系数
    Expression.match(
      Expression.get('road_class'),
      'highway', 2.0,      // 高速：2倍
      'main', 1.5,         // 主干道：1.5倍
      'secondary', 1.0,    // 次干道：1倍
      'local', 0.7,        // 支路：0.7倍
      1.0                  // 默认
    )
  )
);

// 3. 不透明度：拥堵时更显眼
roadLayer.withLineOpacity(
  Expression.match(
    Expression.get('traffic_level'),
    'jam', 1.0,          // 拥堵：完全不透明
    'congested', 0.9,    // 较堵：90%
    'slow', 0.7,         // 缓慢：70%
    'smooth', 0.5,       // 畅通：50%
    0.6                  // 默认
  )
);`;
  }

  /**
   * 场景 3：POI 分类显示
   */
  private getPOIExample(): string {
    return `// 🏪 POI 兴趣点分类显示
// 根据类型显示不同图标、大小和标签样式

const poiLayer = new SymbolLayer('poi', 'poi-source');

// 1. 图标选择：根据 POI 类型
poiLayer.setIconImage(
  Expression.match(
    Expression.get('category'),
    'restaurant', 'icon-restaurant',
    'hotel', 'icon-hotel',
    'hospital', 'icon-hospital',
    'school', 'icon-school',
    'bank', 'icon-bank',
    'park', 'icon-park',
    'shopping', 'icon-shopping',
    'gas_station', 'icon-gas',
    'icon-default'  // 默认图标
  )
);

// 2. 图标大小：根据重要性和缩放级别
poiLayer.setIconSize(
  Expression.multiply(
    // 基础大小（随缩放级别变化）
    Expression.interpolate(
      Interpolator.linear(),
      Expression.zoom(),
      10, 0.6,
      14, 1.0,
      18, 1.4
    ),
    // 重要性系数
    Expression.coalesce(
      Expression.get('importance'),  // 优先使用 importance 属性
      1.0                            // 默认系数
    )
  )
);

// 3. 文本标签：组合名称和评分
poiLayer.setTextField(
  Expression.switchCase(
    // 如果有评分，显示名称+评分
    Expression.has('rating'),
    Expression.concat(
      Expression.get('name'),
      ' ⭐',
      Expression.toString(Expression.get('rating'))
    ),
    // 否则只显示名称
    Expression.get('name')
  )
);

// 4. 文本颜色：根据营业状态
poiLayer.setTextColor(
  Expression.match(
    Expression.get('status'),
    'open', '#00aa00',        // 营业中：绿色
    'closed', '#999999',      // 已关闭：灰色
    'opening_soon', '#ff8800', // 即将营业：橙色
    '#000000'                 // 默认：黑色
  )
);`;
  }

  /**
   * 场景 4：房价热力图
   */
  private getHousePriceExample(): string {
    return `// 🏘️ 房价热力图
// 根据房价区间显示不同颜色的区域，并动态调整透明度

const priceLayer = new FillLayer('house-price', 'districts-source');

// 1. 填充颜色：房价梯度
priceLayer.withFillColor(
  Expression.interpolate(
    Interpolator.linear(),
    Expression.get('avg_price'),  // 平均房价（元/平米）
    5000, '#f7fbff',    // 5k：浅蓝
    10000, '#deebf7',   // 1万：蓝
    20000, '#9ecae1',   // 2万：深蓝
    30000, '#6baed6',   // 3万：更深蓝
    50000, '#3182bd',   // 5万：蓝紫
    80000, '#08519c',   // 8万：深紫
    100000, '#08306b'   // 10万+：最深紫
  )
);

// 2. 透明度：根据数据完整性
priceLayer.withFillOpacity(
  Expression.multiply(
    // 基础透明度
    0.7,
    // 数据置信度系数
    Expression.coalesce(
      Expression.divide(
        Expression.get('sample_count'),  // 样本数
        100                              // 期望样本数
      ),
      0.5  // 默认 50%
    )
  )
);

// 3. 边框颜色：突出高价区
priceLayer.withFillOutlineColor(
  Expression.switchCase(
    Expression.gte(Expression.get('avg_price'), 80000),
    '#ff0000',  // 高价区：红色边框
    Expression.gte(Expression.get('avg_price'), 50000),
    '#ff8800',  // 较高价区：橙色边框
    '#ffffff'   // 其他：白色边框
  )
);`;
  }

  /**
   * 场景 5：温度可视化
   */
  private getTemperatureExample(): string {
    return `// 🌡️ 温度可视化地图
// 根据温度值显示冷暖色调渐变

const tempLayer = new CircleLayer('temperature', 'weather-source');

// 1. 颜色：温度色谱（蓝→绿→黄→红）
tempLayer.withCircleColor(
  Expression.interpolate(
    Interpolator.linear(),
    Expression.get('temperature'),  // 温度（℃）
    -20, '#0000ff',   // -20℃：蓝色
    -10, '#00aaff',   // -10℃：浅蓝
    0, '#00ffff',     // 0℃：青色
    10, '#00ff00',    // 10℃：绿色
    20, '#ffff00',    // 20℃：黄色
    30, '#ff8800',    // 30℃：橙色
    40, '#ff0000'     // 40℃：红色
  )
);

// 2. 半径：温度绝对值越大，圆圈越大
tempLayer.withCircleRadius(
  Expression.add(
    Expression.literal(5),  // 基础半径
    Expression.multiply(
      Expression.abs(Expression.get('temperature')),
      Expression.literal(0.3)
    )
  )
);

// 3. 模糊效果：创建热力图效果
tempLayer.withCircleBlur(
  Expression.interpolate(
    Interpolator.linear(),
    Expression.zoom(),
    6, 1.0,    // 小缩放：模糊
    10, 0.5,   // 中等缩放：半模糊
    14, 0.2    // 大缩放：清晰
  )
);`;
  }

  /**
   * 场景 6：数据统计图
   */
  private getDataVisualizationExample(): string {
    return `// 📊 数据统计可视化
// 根据统计数据动态调整标记大小和颜色

const statsLayer = new CircleLayer('statistics', 'data-source');

// 1. 大小：正比于数值
statsLayer.withCircleRadius(
  Expression.multiply(
    Expression.sqrt(Expression.get('value')),  // 平方根缩放（避免过大）
    Expression.literal(2)
  )
);

// 2. 颜色：正值绿色，负值红色
statsLayer.withCircleColor(
  Expression.switchCase(
    Expression.gt(Expression.get('value'), 0),
    // 正值：绿色渐变
    Expression.interpolate(
      Interpolator.linear(),
      Expression.get('value'),
      0, '#ccffcc',
      100, '#00ff00',
      500, '#00aa00'
    ),
    // 负值：红色渐变
    Expression.interpolate(
      Interpolator.linear(),
      Expression.get('value'),
      -500, '#aa0000',
      -100, '#ff0000',
      0, '#ffcccc'
    )
  )
);

// 3. 边框：突出异常值
statsLayer.withCircleStrokeColor(
  Expression.switchCase(
    // 异常高值
    Expression.gt(Expression.get('value'), 1000),
    '#ffff00',  // 黄色警告
    // 异常低值
    Expression.lt(Expression.get('value'), -1000),
    '#ff00ff',  // 紫色警告
    // 正常值
    '#ffffff'   // 白色
  )
);

statsLayer.withCircleStrokeWidth(
  Expression.switchCase(
    Expression.or(
      Expression.gt(Expression.get('value'), 1000),
      Expression.lt(Expression.get('value'), -1000)
    ),
    3,  // 异常值：粗边框
    1   // 正常值：细边框
  )
);`;
  }

  /**
   * 场景 7：地铁线路图
   */
  private getSubwayLineExample(): string {
    return `// 🚇 地铁线路图
// 不同线路显示不同颜色和宽度

const subwayLayer = new LineLayer('subway', 'subway-source');

// 1. 线路颜色：预定义线路色
subwayLayer.withLineColor(
  Expression.match(
    Expression.get('line_number'),
    '1', '#c23a30',   // 1号线：红色
    '2', '#0091c7',   // 2号线：蓝色
    '3', '#ffc82c',   // 3号线：黄色
    '4', '#009f5d',   // 4号线：绿色
    '5', '#a12a7d',   // 5号线：紫色
    '#808080'         // 默认：灰色
  )
);

// 2. 线路宽度：根据缩放级别和客流量
subwayLayer.withLineWidth(
  Expression.multiply(
    // 基础宽度
    Expression.interpolate(
      Interpolator.linear(),
      Expression.zoom(),
      10, 2,
      14, 4,
      18, 8
    ),
    // 客流量系数
    Expression.interpolate(
      Interpolator.linear(),
      Expression.get('passenger_flow'),
      10000, 0.8,    // 低客流
      50000, 1.0,    // 正常客流
      100000, 1.5    // 高客流
    )
  )
);

// 3. 虚线：在建线路
subwayLayer.withLineDasharray(
  Expression.switchCase(
    Expression.eq(Expression.get('status'), 'construction'),
    Expression.literal([2, 2]),  // 虚线
    Expression.literal([])       // 实线
  )
);

// 4. 透明度：运营状态
subwayLayer.withLineOpacity(
  Expression.match(
    Expression.get('status'),
    'operating', 1.0,        // 运营中：不透明
    'construction', 0.5,     // 在建：半透明
    'planned', 0.3,          // 规划中：很透明
    0.7                      // 默认
  )
);`;
  }

  /**
   * 场景 8：评分展示
   */
  private getRatingExample(): string {
    return `// ⭐ 评分展示系统
// 根据评分显示星级颜色和大小

const ratingLayer = new SymbolLayer('ratings', 'reviews-source');

// 1. 文本内容：评分 + 评论数
ratingLayer.setTextField(
  Expression.concat(
    '⭐ ',
    Expression.toString(
      Expression.round(
        Expression.multiply(
          Expression.get('rating'),
          Expression.literal(10)
        )
      )
    ),
    ' (',
    Expression.toString(Expression.get('review_count')),
    ')'
  )
);

// 2. 文本颜色：评分等级
ratingLayer.setTextColor(
  Expression.step(
    Expression.get('rating'),
    '#999999',           // < 3.0：灰色（差评）
    3.0, '#ff8800',      // 3.0-3.5：橙色（一般）
    3.5, '#ffcc00',      // 3.5-4.0：黄色（良好）
    4.0, '#99cc00',      // 4.0-4.5：黄绿色（优秀）
    4.5, '#00aa00'       // 4.5+：绿色（极好）
  )
);

// 3. 文本大小：评论数越多，字体越大
ratingLayer.setTextSize(
  Expression.add(
    Expression.literal(12),  // 基础字号
    Expression.min(
      Expression.divide(
        Expression.get('review_count'),
        Expression.literal(100)
      ),
      Expression.literal(8)  // 最多增加 8px
    )
  )
);

// 4. 图标大小：高评分更显眼
ratingLayer.setIconSize(
  Expression.interpolate(
    Interpolator.linear(),
    Expression.get('rating'),
    0, 0.5,     // 低分：小图标
    3, 0.8,
    4, 1.2,
    5, 1.5      // 高分：大图标
  )
);`;
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
        
        Text('Expression 真实场景示例')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F5F5F5')
      .margin({ bottom: 10 })
      
      // 场景选择列表
      List() {
        ForEach(this.examples, (example: ExampleItem, index: number) => {
          ListItem() {
            Column() {
              Text(example.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .margin({ bottom: 5 })
              
              Text(example.description)
                .fontSize(12)
                .fontColor('#666666')
                .width('100%')
            }
            .width('100%')
            .padding(15)
            .backgroundColor(this.selectedExample === index ? '#e3f2fd' : '#ffffff')
            .borderRadius(8)
            .border({
              width: this.selectedExample === index ? 2 : 1,
              color: this.selectedExample === index ? '#2196f3' : '#e0e0e0'
            })
          }
          .onClick(() => {
            this.generateExampleCode(index);
          })
          .margin({ bottom: 10 })
        }, (example: ExampleItem, index: number) => `${index}`)
      }
      .width('100%')
      .height('40%')
      .padding({ left: 20, right: 20 })
      
      // 代码展示区
      Column() {
        Text('代码示例')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
          .alignSelf(ItemAlign.Start)
        
        Scroll() {
          Text(this.exampleCode)
            .fontSize(11)
            .fontFamily('monospace')
            .fontColor('#333333')
            .width('100%')
            .padding(15)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .padding(20)
      .backgroundColor('#ffffff')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}

