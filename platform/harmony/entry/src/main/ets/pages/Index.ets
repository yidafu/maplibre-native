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
  @State private testPageGroups: TestPageGroup[] = [];
  // 当前选中的分组索引
  @State private selectedGroupIndex: number = 0;
  
  aboutToAppear() {
    // 延迟初始化数据，避免阻塞首屏加载
    this.testPageGroups = [
    // 🗺️ 地图基础
    new TestPageGroup('地图基础', '🗺️', [
      new TestPageItem(
        '基础地图测试',
        '测试地图渲染、初始化和相机基础移动（jumpTo/easeTo/flyTo）',
        'pages/BasicMapPage',
        '🗺️'
      ),
      new TestPageItem(
        '卫星影像地图',
        '测试加载卫星影像栅格图层',
        'pages/SatelliteMapPage',
        '🛰️'
      ),
      new TestPageItem(
        'OSM 栅格地图',
        '测试加载 OpenStreetMap 栅格图层',
        'pages/OSMRasterMapPage',
        '🗺️'
      ),
      new TestPageItem(
        '核心 API 测试',
        '测试内容边距、像素比例、矩形转换等新增核心 API',
        'pages/CoreAPITestPage',
        '🔧'
      ),
      new TestPageItem(
        '地图状态',
        '测试地图加载状态和重绘功能',
        'pages/MapStateTestPage',
        '🔄'
      ),
      new TestPageItem(
        '手势系统测试',
        '测试平移、缩放、旋转、倾斜等手势功能和惯性动画',
        'pages/GestureTestPage',
        '👆'
      ),
      new TestPageItem(
        '相机动画测试',
        '测试 easeTo 平滑动画和 flyTo 飞行动画',
        'pages/CameraAnimationTestPage',
        '🎬'
      ),
      new TestPageItem(
        '相机事件监听器',
        '测试相机移动、空闲等各种相机事件监听器（onMove/onIdle）',
        'pages/CameraListenerTestPage',
        '👂'
      ),
      new TestPageItem(
        '相机边界计算',
        '测试边界计算和可视区域控制功能',
        'pages/CameraBoundsTestPage',
        '📐'
      ),
      new TestPageItem(
        '相机参数限制',
        '测试缩放和倾斜角度限制功能',
        'pages/CameraLimitsTestPage',
        '🔒'
      ),
    ]),
    
    // 📍 标注与交互
    new TestPageGroup('标注与交互', '📍', [
      new TestPageItem(
        'Marker 完整功能测试',
        '测试 Marker 添加、删除、事件、动画、拖拽、InfoWindow、批量操作等所有功能',
        'pages/MarkerTestPage',
        '📍'
      ),
      new TestPageItem(
        'InfoWindow 测试',
        '测试 InfoWindow 显示、隐藏、样式定制、边界检测等功能',
        'pages/InfoWindowTestPage',
        '💬'
      ),
      new TestPageItem(
        'Icon 管理测试',
        '测试 Icon 创建、共享、引用计数和自动清理功能',
        'pages/IconTestPage',
        '🎯'
      ),
      new TestPageItem(
        'AnnotationView 测试',
        '测试自定义注解视图、视图复用、拖拽和变换功能',
        'pages/AnnotationViewTestPage',
        '🎨'
      ),
      new TestPageItem(
        '折线/多边形',
        '测试折线和多边形注解功能',
        'pages/PolylinePolygonTestPage',
        '📏'
      ),
      new TestPageItem(
        'LocationComponent 测试',
        '测试用户定位功能、追踪模式和渲染模式',
        'pages/LocationComponentTestPage',
        '🧭'
      ),
      new TestPageItem(
        '定位flyTo测试',
        '测试获取定位并使用flyTo动画移动到定位位置（zoom=6）',
        'pages/LocationFlyToTestPage',
        '🎯'
      ),
      new TestPageItem(
        '坐标转换',
        '测试各种坐标系转换计算',
        'pages/CoordinateConversionTestPage',
        '🧭'
      ),
    ]),
    
    // 🎨 样式系统
    new TestPageGroup('样式系统', '🎨', [
      new TestPageItem(
        'Source 数据源测试',
        '测试 GeoJSON、Vector、Raster 等各种数据源类型和配置',
        'pages/SourceTestPage',
        '📊'
      ),
      new TestPageItem(
        'Layer 图层测试',
        '测试 Fill、Line、Circle、Symbol、Heatmap 等各种图层类型',
        'pages/LayerTestPage',
        '🔨'
      ),
      new TestPageItem(
        'Style 地图样式测试',
        '测试地图样式切换、样式信息获取、图层可见性控制等样式相关功能',
        'pages/StyleTestPage',
        '🎨'
      ),
      new TestPageItem(
        'Style URL 切换',
        '测试不同地图样式 URL 的动态切换和样式信息获取',
        'pages/StyleUrlTestPage',
        '🔄'
      ),
      new TestPageItem(
        '光照系统',
        '测试地图光照配置和效果',
        'pages/LightTestPage',
        '💡'
      ),
      new TestPageItem(
        '样式过渡选项',
        '测试样式切换过渡动画配置',
        'pages/StyleTransitionTestPage',
        '🎬'
      ),
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
      new TestPageItem(
        'Expression 属性测试',
        '测试所有新实现的 Expression 属性方法（114个NAPI方法）',
        'pages/NewExpressionPropertiesTest',
        '🧪'
      ),
      new TestPageItem(
        'PropertyFactory 测试',
        '测试所有新增的 PropertyFactory 属性方法',
        'pages/NewPropertyFactoryTest',
        '🏭'
      ),
      new TestPageItem(
        '聚类 Expression 示例',
        '演示如何使用 Expression 实现数据聚类功能（需API完善）',
        'pages/ClusterExpressionExample',
        '🎯'
      ),
      new TestPageItem(
        '数据驱动样式示例',
        '演示如何使用 Expression 实现数据驱动样式（需API完善）',
        'pages/DataDrivenStyleExample',
        '📊'
      ),
    ]),
    
    // 🛠️ 工具与控件
    new TestPageGroup('工具与控件', '🛠️', [
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
      new TestPageItem(
        '坐标投影转换',
        '测试地理坐标和屏幕坐标互转、可见区域计算',
        'pages/ProjectionTestPage',
        '🗺️'
      ),
      new TestPageItem(
        '地图快照',
        '测试后台渲染地图生成高质量快照图像',
        'pages/MapSnapshotterTestPage',
        '📸'
      ),
      new TestPageItem(
        '特性查询',
        '测试点击和框选查询地图要素功能',
        'pages/QueryFeaturesTestPage',
        '🔍'
      ),
      new TestPageItem(
        '事件监听器集成',
        '测试所有 Android/iOS 风格的地图事件监听器',
        'pages/listeners/EventListenersTestPage',
        '📡'
      ),
      new TestPageItem(
        'TestPageLayout 使用示例',
        '展示如何使用 TestPageLayout 组件创建统一风格的测试页面',
        'pages/TestPageExample',
        '📝'
      ),
    ]),
    
    // 💾 离线与优化
    new TestPageGroup('离线与优化', '💾', [
      new TestPageItem(
        '离线地图下载测试',
        '测试离线地图区域的创建、下载、暂停、恢复和删除功能',
        'pages/OfflineMapTestPage',
        '📥'
      ),
      new TestPageItem(
        '离线缓存管理测试',
        '测试环境缓存清理、数据库压缩、重置和配置管理功能',
        'pages/OfflineCacheTestPage',
        '🗑️'
      ),
      new TestPageItem(
        '瓦片LOD配置',
        '测试瓦片细节级别参数配置',
        'pages/TileLodTestPage',
        '🎚️'
      ),
      new TestPageItem(
        '瓦片预加载',
        '测试瓦片预加载优化功能',
        'pages/TilePrefetchTestPage',
        '🚀'
      ),
    ]),
    
    // 🚀 高级功能
    new TestPageGroup('高级功能', '🚀', [
      new TestPageItem(
        '多地图实例测试',
        '测试多个地图实例的同时显示、独立交互和资源管理',
        'pages/MultiMapTestPage',
        '🗺️🗺️🗺️'
      ),
      new TestPageItem(
        '二次进入回归测试',
        '自动化测试二次进入地图的稳定性和资源管理',
        'pages/SecondEntryRegressionTestPage',
        '🔄'
      ),
    ]),
    ];
  }

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

      // 主内容区：左右分栏布局
      Row() {
        // 左侧 Tab 栏
        this.buildLeftTabBar()
        
        // 分隔线
        Column()
          .width(1)
          .height('100%')
          .backgroundColor('#E0E0E0')
        
        // 右侧内容区
        this.buildRightContent()
      }
      .width('100%')
      .layoutWeight(1)

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
  buildLeftTabBar() {
    // 左侧垂直 Tab 栏（可滚动）
    Scroll() {
      Column({ space: 6 }) {
        ForEach(this.testPageGroups, (group: TestPageGroup, index: number) => {
          Column() {
            // 图标
            Text(group.groupIcon)
              .fontSize(20)
              .margin({ bottom: 4 })
            
            // 分类名称
            Text(group.groupName)
              .fontSize(11)
              .fontWeight(this.selectedGroupIndex === index ? FontWeight.Medium : FontWeight.Regular)
              .fontColor(this.selectedGroupIndex === index ? '#2196F3' : '#666666')
              .textAlign(TextAlign.Center)
              .maxLines(2)
              .lineHeight(15)
          }
          .width('100%')
          .padding({ top: 10, bottom: 10, left: 4, right: 4 })
          .backgroundColor(this.selectedGroupIndex === index ? '#E3F2FD' : '#FAFAFA')
          .borderRadius(10)
          .border({
            width: this.selectedGroupIndex === index ? 2 : 0,
            color: '#2196F3'
          })
          .shadow({
            radius: this.selectedGroupIndex === index ? 6 : 0,
            color: this.selectedGroupIndex === index ? 'rgba(33, 150, 243, 0.2)' : Color.Transparent,
            offsetX: 0,
            offsetY: 2
          })
          .onClick(() => {
            this.selectedGroupIndex = index;
          })
        })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 10, bottom: 10 })
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .width(120)
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildRightContent() {
    // 右侧内容区
    Column() {
      if (this.testPageGroups.length > 0 && this.selectedGroupIndex < this.testPageGroups.length) {
        // 当前选中分组
        // const currentGroup = this.testPageGroups[this.selectedGroupIndex];
        
        // 分组标题栏
        Column() {
          Row() {
            Text(this.testPageGroups[this.selectedGroupIndex].groupIcon)
              .fontSize(28)
              .margin({ right: 12 })
            
            Text(this.testPageGroups[this.selectedGroupIndex].groupName)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
          }
          .width('100%')
          
          // 标题下划线
          Column()
            .width('100%')
            .height(2)
            .backgroundColor('#E3F2FD')
            .margin({ top: 10 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 15, bottom: 10 })
        .backgroundColor('#FAFAFA')
        
        // 测试页面列表
        List({ space: 12 }) {
          ForEach(this.testPageGroups[this.selectedGroupIndex].pages, (item: TestPageItem) => {
            ListItem() {
              this.buildTestPageCard(item)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 20, right: 20, top: 15, bottom: 10 })
      }
    }
    .layoutWeight(1)
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

