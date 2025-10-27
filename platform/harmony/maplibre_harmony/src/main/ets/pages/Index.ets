/**
 * MapLibre Native for HarmonyOS
 * 测试页面导航首页
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { DOMAIN } from '../constants/HiLogConstants';

// 测试页面配置
class TestPageItem {
  title: string = '';
  description: string = '';
  route: string = '';
  icon: string = '';
  
  constructor(title: string, description: string, route: string, icon: string) {
    this.title = title;
    this.description = description;
    this.route = route;
    this.icon = icon;
  }
}

// 测试页面分组
class TestPageGroup {
  groupName: string = '';
  groupIcon: string = '';
  pages: TestPageItem[] = [];
  
  constructor(groupName: string, groupIcon: string, pages: TestPageItem[]) {
    this.groupName = groupName;
    this.groupIcon = groupIcon;
    this.pages = pages;
  }
}

@Entry
@Component
struct Index {
  // 按功能模块分组的测试页面
  private testPageGroups: TestPageGroup[] = [
    // 🗺️ 基础功能
    new TestPageGroup('基础功能', '🗺️', [
      new TestPageItem(
        '基础地图测试',
        '测试地图渲染、初始化、基础交互等核心功能',
        'pages/BasicMapPage',
        '🗺️'
      ),
      new TestPageItem(
        '相机监听器测试',
        '测试相机移动、空闲等各种相机事件监听器功能',
        'pages/CameraListenerTestPage',
        '📷'
      ),
    ]),
    
    // 👆 手势与交互
    new TestPageGroup('手势与交互', '👆', [
      new TestPageItem(
        '手势系统测试',
        '测试平移、缩放、旋转、倾斜等手势功能和惯性动画',
        'pages/GestureTestPage',
        '👆'
      ),
    ]),
    
    // 📍 Marker 与注解
    new TestPageGroup('Marker 与注解', '📍', [
      new TestPageItem(
        'Marker 功能测试',
        '测试 Marker 添加、删除、事件、动画、拖拽、InfoWindow 等完整功能',
        'pages/MarkerTestPage',
        '📍'
      ),
      new TestPageItem(
        'Marker 高级功能测试',
        '测试 Marker 的高级功能和复杂场景应用',
        'pages/MarkerAdvancedTestPage',
        '⭐'
      ),
      new TestPageItem(
        'Icon 管理测试',
        '测试 Icon 创建、共享、引用计数和自动清理功能',
        'pages/IconTestPage',
        '🎯'
      ),
    ]),
    
    // 🎨 样式系统
    new TestPageGroup('样式系统', '🎨', [
      new TestPageItem(
        'Style 样式综合测试',
        '测试地图样式、图层、数据源等完整 Style API 功能',
        'pages/StyleTestPage',
        '🎨'
      ),
      new TestPageItem(
        'Style URL 切换',
        '测试不同地图样式 URL 的动态切换和样式信息获取',
        'pages/StyleUrlTestPage',
        '🔄'
      ),
    ]),
    
    // 🔨 图层系统
    new TestPageGroup('图层系统', '🔨', [
      new TestPageItem(
        'Layer 图层测试',
        '测试 Fill、Line、Circle、Symbol、Heatmap 等各种图层类型',
        'pages/LayerTestPage',
        '🔨'
      ),
    ]),
    
    // 📊 数据源系统
    new TestPageGroup('数据源系统', '📊', [
      new TestPageItem(
        'Source 数据源测试',
        '测试 GeoJSON、Vector、Raster 等各种数据源类型',
        'pages/SourceTestPage',
        '📊'
      ),
    ]),
    
    // 🧮 表达式系统
    new TestPageGroup('表达式系统', '🧮', [
      new TestPageItem(
        'Expression 测试',
        '测试各种 Expression 操作符的功能',
        'pages/ExpressionTestPage',
        '🧮'
      ),
      new TestPageItem(
        'Expression 性能测试',
        '测试 Expression 系统的性能和优化效果',
        'pages/ExpressionPerformanceTest',
        '⚡'
      ),
      new TestPageItem(
        'Expression 实际案例',
        '展示 Expression 在实际场景中的应用示例',
        'pages/ExpressionRealWorldExamples',
        '💡'
      ),
      new TestPageItem(
        'SymbolLayer Expression 示例',
        '演示 Symbol 图层中 Expression 的应用',
        'pages/SymbolLayerExpressionExample',
        '🔤'
      ),
    ]),
    
    // 📍 定位功能
    new TestPageGroup('定位功能', '📍', [
      new TestPageItem(
        'LocationComponent 测试',
        '测试用户定位功能、追踪模式和渲染模式',
        'pages/LocationComponentTestPage',
        '🧭'
      ),
    ]),
    
    // 🎛️ UI 组件
    new TestPageGroup('UI 组件', '🎛️', [
      new TestPageItem(
        '指南针测试',
        '测试指南针组件的显示和交互功能',
        'pages/CompassTestPage',
        '🧭'
      ),
      new TestPageItem(
        'Logo 和比例尺测试',
        '测试地图 Logo 和比例尺组件的显示和配置',
        'pages/LogoScaleBarTestPage',
        '📏'
      ),
    ]),
  ];

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('MapLibre Native for HarmonyOS')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(80)
      .backgroundColor('#2196F3')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 20 })

      // 副标题
      Column() {
        Text('测试页面导航')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 10, bottom: 5 })

        Text('选择一个测试页面开始')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(15)

      // 测试页面列表（分组显示）
      List({ space: 10 }) {
        ForEach(this.testPageGroups, (group: TestPageGroup, groupIndex: number) => {
          ListItemGroup() {
            // 分组标题
            ListItem() {
              Row() {
                Text(group.groupIcon)
                  .fontSize(20)
                  .margin({ right: 8 })
                
                Text(group.groupName)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
              }
              .width('100%')
              .padding({ left: 5, top: 15, bottom: 8 })
            }
            
            // 分组内的测试页面
            ForEach(group.pages, (item: TestPageItem) => {
              ListItem() {
                this.buildTestPageCard(item)
              }
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 15, right: 15 })
      .sticky(StickyStyle.Header)

      // 底部信息
      Column() {
        Text('MapLibre Native v1.0.0')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 5 })

        Text('HarmonyOS 平台适配版本')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildTestPageCard(item: TestPageItem) {
    Column() {
      Row() {
        // 图标
        Text(item.icon)
          .fontSize(32)
          .margin({ right: 15 })

        // 文字信息
        Column() {
          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 5 })

          Text(item.description)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 箭头
        Text('›')
          .fontSize(28)
          .fontColor('#CCCCCC')
          .margin({ left: 10 })
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .backgroundColor('#FAFAFA')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.navigateToPage(item.route);
    })
  }

  /**
   * 导航到指定页面
   */
  private navigateToPage(route: string): void {
    hilog.info(DOMAIN, 'Index', `Attempting to navigate to: ${route}`);
    
    // 直接使用 pushUrl，不使用命名路由
    router.pushUrl({
      url: route
    }).then(() => {
      hilog.info(DOMAIN, 'Index', `Successfully navigated to: ${route}`);
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'Index', `Navigation failed: ${err.message}`);
      console.error(`Navigation error: ${err.message}`);
    });
  }
}

