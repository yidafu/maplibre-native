import { Expression, FillLayer, GeoJsonSource, Interpolator, LineLayer, MapLibreMap, MapLibreMapOptions, MapView, PropertyFactory, Stop, SymbolLayer, maplibre } from 'maplibre_harmony';
/**
 * DataDrivenStyleExample - 数据驱动样式示例
 * 
 * 演示如何使用 Expression 根据数据属性动态设置样式
 */

import { router } from '@kit.ArkUI';

@Entry
@Component
struct DataDrivenStyleExample {
  @State mapReady: boolean = false;
  @State statusText: string = '初始化中...';
  @State currentExample: number = 1;
  private mapLibreMap: MapLibreMap | null = null;
  private surfaceId: string = '';

  aboutToAppear() {
    this.surfaceId = 'data_driven_xcomponent';
  }

  aboutToDisappear() {
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
      this.mapLibreMap = null;
    }
  }

  private onMapReady(map: MapLibreMap) {
    this.mapLibreMap = map;
    this.mapReady = true;
    this.statusText = '地图已加载';
    
    map.jumpTo(0, 39.9, 116.4, 0, 10);
    
    setTimeout(() => {
      this.setupExample1();
    }, 500);
  }

  /**
   * 示例 1：人口密度可视化
   * 
   * 注意：这是一个高级Expression示例，展示了如何使用Expression实现数据驱动样式。
   * 由于当前Layer的Expression API还在完善中（需要NAPI层支持），
   * 这里暂时简化实现，等待API完善后启用完整功能。
   * 
   * 完整实现包括：
   * - 使用Expression.match()根据类别设置填充颜色
   * - 使用Expression.interpolate()根据密度设置透明度
   * - 使用Expression.interpolate()根据收入设置边框宽度
   * - 使用Expression.concat()组合文本标签
   */
  private setupExample1() {
    if (!this.mapLibreMap) return;
    
    try {
      // TODO: Expression数据驱动样式示例 - 等待Layer Expression API完善后启用
      this.statusText = '⚠️ Expression数据驱动样式示例需要完善的Layer API支持\n' +
                       '请参考其他已实现的测试页面（如LayerTestPage）查看基础Layer功能';
    } catch (e) {
      this.statusText = `加载失败: ${e}`;
      console.error("Failed to setup example 1:", e);
    }
  }

  /**
   * 切换示例
   */
  private switchExample(exampleNum: number) {
    if (!this.mapLibreMap) return;
    
    // 移除现有图层
    try {
      const style = this.mapLibreMap.getStyle();
      if (style) {
        if (style.getLayer("regions-fill")) style.removeLayer("regions-fill");
        if (style.getLayer("regions-border")) style.removeLayer("regions-border");
        if (style.getLayer("regions-labels")) style.removeLayer("regions-labels");
        if (style.getSource("regions")) style.removeSource("regions");
      }
    } catch (e) {
      // 忽略错误
    }
    
    this.currentExample = exampleNum;
    
    if (exampleNum === 1) {
      this.setupExample1();
    }
  }

  build() {
    Column() {
      // 状态栏
      Row() {
        Text(this.statusText)
          .fontSize(14)
          .fontColor('#333333')
          .padding(10)
      }
      .width('100%')
      .height(40)
      .backgroundColor('#f0f0f0')
      
      // 说明面板
      Column() {
        Text('数据驱动样式示例')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })
        
        Text('演示特性：')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8, bottom: 4 })
        
        Text('✓ 颜色根据类别（match 表达式）')
          .fontSize(12)
        Text('✓ 透明度根据密度（interpolate 表达式）')
          .fontSize(12)
        Text('✓ 边框宽度根据收入（连续插值）')
          .fontSize(12)
        Text('✓ 标签显示计算结果（concat 表达式）')
          .fontSize(12)
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#ffffff')
      .alignItems(HorizontalAlign.Start)
      
      // 地图容器
      Stack() {
        MapView({
          styleUrl: 'https://demotiles.maplibre.org/style.json',
          initialLatitude: 39.9,
          initialLongitude: 116.4,
          initialZoom: 5,
          initialBearing: 0,
          initialPitch: 0,
          onMapReady: (map: MapLibreMap) => {
            if (map) {
              const options = new MapLibreMapOptions();
              this.mapLibreMap = new MapLibreMap(map, options);
              this.onMapReady(this.mapLibreMap);
            }
          }
        })
      .layoutWeight(1)
      
      // 控制按钮
      Row() {
        Button('返回')
          .onClick(() => {
            router.back();
          })
          .flexGrow(1)
          .margin({ right: 5 })
      }
      .padding(10)
      .width('100%')
      .backgroundColor('#f0f0f0')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
}

