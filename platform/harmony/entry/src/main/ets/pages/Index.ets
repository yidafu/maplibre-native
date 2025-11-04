/**
 * MapLibre Native for HarmonyOS
 * 测试页面导航首页
 *
 * 基于 Android 和 iOS 测试应用的结构重新实现
 * 包含 19 个主要分类，涵盖所有 MapLibre 功能
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { DOMAIN } from '../constants/HiLogConstants';

/**
 * 测试页面项配置
 */
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

/**
 * 测试页面分组
 */
class TestPageGroup {
  groupName: string = '';
  groupIcon: string = '';
  pages: TestPageItem[] = [];
  ;

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
  ;
  // 当前选中的分组索引
  @State private selectedGroupIndex: number = 0;

  aboutToAppear() {
    // 初始化测试页面数据，包含 19 个功能分类
    this.testPageGroups = this.initializeTestPages();
  }

  /**
   * 初始化所有测试页面，按照功能模块分类
   * 参考: platform/android/MapLibreAndroidTestApp
   */
  private initializeTestPages(): TestPageGroup[] {
    return [
      // ==================== 1. _Basic ====================
      this.createBasicGroup(),

      // ==================== 2. Annotation ====================
      this.createAnnotationGroup(),

      // ==================== 3. Camera ====================
      this.createCameraGroup(),

      // ==================== 9. Styling ====================
      this.createStylingGroup(),

      // ==================== 10. Layer ====================
      this.createLayerGroup(),

      // ==================== 6. Info Window ====================
      this.createInfoWindowGroup(),

      // ==================== 5. Fragment ====================
      this.createFragmentGroup(),

      // ==================== 11. Features ====================
      this.createFeaturesGroup(),

      // ==================== 7. Location ====================
      this.createLocationGroup(),

      // ==================== 8. Offline ====================
      this.createOfflineGroup(),


      // ==================== 12. Storage ====================
      this.createStorageGroup(),

      // ==================== 13. Events ====================
      this.createEventsGroup(),

      // ==================== 14. Image Generator ====================
      this.createImageGeneratorGroup(),

      // ==================== 15. Texture View ====================
      this.createTextureViewGroup(),

      // ==================== 16. Turf ====================
      this.createTurfGroup(),

      // ==================== 17. Map Options ====================
      this.createMapOptionsGroup(),

      // ==================== 18. Integration ====================
      this.createIntegrationGroup(),

      // ==================== 19. Performance ====================
      this.createPerformanceGroup(),

    ]
  }

  /**
   * 1. _Basic - 基础地图功能
   */
  private createBasicGroup(): TestPageGroup {
    return new TestPageGroup('Basic', '🗺️', [
      new TestPageItem('Simple Map', '简单地图显示', 'pages/basic/SimpleMapTestPage', '🗺️'),
      new TestPageItem('Debug Mode', '调试模式和性能信息', 'pages/basic/DebugModeTestPage', '🐛'),
      new TestPageItem('Double Map', '双地图实例', 'pages/basic/DoubleMapTestPage', '🗺️🗺️'),
      new TestPageItem('Map Padding', '地图内边距', 'pages/basic/MapPaddingTestPage', '📐'),
      new TestPageItem('Map Change', '地图事件监听', 'pages/basic/MapChangeTestPage', '📡'),
      new TestPageItem('Map In Dialog', '对话框中的地图', 'pages/basic/MapInDialogTestPage', '💬'),
      new TestPageItem('Overlay Map', '叠加层地图', 'pages/basic/OverlayMapTestPage', '📄'),
      new TestPageItem('Bottom Sheet', '底部抽屉', 'pages/basic/BottomSheetTestPage', '📋'),
      new TestPageItem('Visibility Change', '可见性变化', 'pages/basic/VisibilityChangeTestPage', '👁️'),
      new TestPageItem('Local Glyph', '本地字体', 'pages/basic/LocalGlyphTestPage', '🔤'),
      new TestPageItem('Map State', '地图状态管理', 'pages/basic/MapStateTestPage', '🔄'),
      new TestPageItem('Core API', '核心API测试', 'pages/basic/CoreAPITestPage', '⚙️'),
    ]);
  }

  /**
   * 2. Annotation - 标注功能
   */
  private createAnnotationGroup(): TestPageGroup {
    return new TestPageGroup('Annotation', '📍', [
      new TestPageItem('Bulk Marker', '批量标注 (1000+)', 'pages/annotation/BulkMarkerTestPage', '📍'),
      new TestPageItem('Draggable Marker', '可拖拽标记', 'pages/annotation/DraggableMarkerTestPage', '✋'),
      new TestPageItem('Dynamic Marker', '动态Marker变化', 'pages/annotation/DynamicMarkerChangeTestPage', '🔄'),
      new TestPageItem('JSON API', '从 API 获取 GeoJSON 数据', 'pages/annotation/JsonApiTestPage', '🌐'),
      new TestPageItem('Marker Click', '标记点击事件', 'pages/annotation/MarkerClickTestPage', '👆'),
      new TestPageItem('Remove Marker', '点击移除标记', 'pages/annotation/RemoveMarkerTestPage', '🗑️'),
      new TestPageItem('Annotation View', '标注视图', 'pages/annotation/AnnotationViewTestPage', '👁️'),
      new TestPageItem('Icon Test', '图标测试', 'pages/annotation/IconTestPage', '🖼️'),
      new TestPageItem('Polygon', '多边形', 'pages/annotation/PolygonTestPage', '🔶'),
      new TestPageItem('Polyline & Polygon', '线面组合', 'pages/annotation/PolylinePolygonTestPage', '📐'),
      new TestPageItem('Polyline', '折线', 'pages/annotation/PolylineTestPage', '📏'),
      new TestPageItem('Press for Marker', '长按添加标记', 'pages/annotation/PressForMarkerTestPage', '👆'),
    ]);
  }

  /**
   * 3. Camera - 相机控制
   */
  private createCameraGroup(): TestPageGroup {
    return new TestPageGroup('Camera', '📷', [
      new TestPageItem('Camera Position', '相机位置控制', 'pages/camera/CameraPositionTestPage', '📍'),
      new TestPageItem('Camera Update', '相机更新方法', 'pages/camera/CameraUpdateTestPage', '🔄'),
      new TestPageItem('Camera Animator', '相机动画器', 'pages/camera/CameraAnimatorTestPage', '🎬'),
      new TestPageItem('Animation Type', '动画类型', 'pages/camera/CameraAnimationTypeTestPage', '🎭'),
      new TestPageItem('LatLng Bounds', 'LatLng 边界', 'pages/camera/LatLngBoundsTestPage', '🗺️'),
      new TestPageItem('Bounds For Camera', '相机边界适配', 'pages/camera/LatLngBoundsForCameraTestPage', '📐'),
      new TestPageItem('Manual Zoom', '手动缩放', 'pages/camera/ManualZoomTestPage', '🔍'),
      new TestPageItem('Max Min Zoom', '缩放限制', 'pages/camera/MaxMinZoomTestPage', '🎚️'),
      new TestPageItem('Pitch', '倾斜控制', 'pages/camera/PitchTestPage', '⛰️'),
      new TestPageItem('Rotate By', '旋转控制', 'pages/camera/RotateByTestPage', '🔄'),
      new TestPageItem('Scroll By', '滚动偏移', 'pages/camera/ScrollByTestPage', '⬆️'),
      new TestPageItem('Gesture Detector', '手势检测', 'pages/camera/GestureDetectorTestPage', '👆'),
      new TestPageItem('Gesture', '手势系统', 'pages/camera/GestureTestPage', '👋'),
    ]);
  }

  /**
   * 4. Custom Layer - 自定义图层
   */
  private createCustomLayerGroup(): TestPageGroup {
    return new TestPageGroup('Custom Layer', '🎨', [
      new TestPageItem('Custom Layer', '自定义渲染图层', 'pages/customlayer/CustomLayerTestPage', '🎨'),
    ]);
  }

  /**
   * 5. Fragment - 片段和多实例
   */
  private createFragmentGroup(): TestPageGroup {
    return new TestPageGroup('Fragment', '🧩', [
      new TestPageItem('Multi Map', '多地图实例', 'pages/fragment/MultiMapTestPage', '🗺️🗺️'),
      new TestPageItem('Support Map Fragment', '支持地图片段', 'pages/fragment/SupportMapFragmentTestPage', '🧩'),
      new TestPageItem('Fragment BackStack', '片段回退栈', 'pages/fragment/FragmentBackStackTestPage', '⬅️'),
      new TestPageItem('ViewPager', 'ViewPager中的地图', 'pages/fragment/ViewPagerTestPage', '📄'),
      new TestPageItem('Nested ViewPager', '嵌套ViewPager', 'pages/fragment/NestedViewPagerTestPage', '📑'),
    ]);
  }

  /**
   * 6. Info Window - 信息窗口
   */
  private createInfoWindowGroup(): TestPageGroup {
    return new TestPageGroup('Info Window', '💬', [
      new TestPageItem('Info Window', '标准信息窗口', 'pages/infowindow/InfoWindowTestPage', '💬'),
      new TestPageItem('Info Window Adapter', '自定义信息窗口', 'pages/infowindow/InfoWindowAdapterTestPage', '🎨'),
      new TestPageItem('Dynamic Info Window', '动态自定义信息窗口', 'pages/infowindow/DynamicInfoWindowAdapterTestPage',
        '🔄'),
    ]);
  }

  /**
   * 7. Location - 定位功能
   */
  private createLocationGroup(): TestPageGroup {
    return new TestPageGroup('Location', '📍', [
      new TestPageItem('Location Map Change', '简单定位', 'pages/location/LocationMapChangeTestPage', '📍'),
      new TestPageItem('Location Modes', '定位模式', 'pages/location/LocationModesTestPage', '🎯'),
      new TestPageItem('Location Activation', '定位组件激活', 'pages/location/LocationComponentActivationTestPage',
        '⚙️'),
      new TestPageItem('Basic Pulsing Circle', '基础脉冲圆', 'pages/location/BasicLocationPulsingCircleTestPage', '⭕'),
      new TestPageItem('Customized Pulsing Circle', '自定义脉冲圆',
        'pages/location/CustomizedLocationPulsingCircleTestPage', '🎨'),
      new TestPageItem('Location Fragment', '定位片段', 'pages/location/LocationFragmentTestPage', '🧩'),
      new TestPageItem('Manual Location', '手动位置更新', 'pages/location/ManualLocationUpdatesTestPage', '✋'),
    ]);
  }

  /**
   * 8. Offline - 离线地图
   */
  private createOfflineGroup(): TestPageGroup {
    return new TestPageGroup('Offline', '💾', [
      new TestPageItem('Offline Manager', '离线管理器', 'pages/offline/OfflineManagerTestPage', '💾'),
      new TestPageItem('Offline Management', '离线管理', 'pages/offline/OfflineManagementTestPage', '⚙️'),
      new TestPageItem('Download Region', '下载区域', 'pages/offline/DownloadRegionTestPage', '⬇️'),
      new TestPageItem('Delete Region', '删除区域', 'pages/offline/DeleteRegionTestPage', '🗑️'),
      new TestPageItem('Update Metadata', '更新元数据', 'pages/offline/UpdateMetadataTestPage', '📝'),
      new TestPageItem('Merge Regions', '合并离线区域', 'pages/offline/MergeOfflineRegionsTestPage', '🔗'),
      new TestPageItem('Change Cache Path', '修改缓存路径', 'pages/offline/ChangeResourcesCachePathTestPage', '📁'),
    ]);
  }

  /**
   * 9. Styling - 样式系统
   */
  private createStylingGroup(): TestPageGroup {
    return new TestPageGroup('Styling', '🎨', [
      new TestPageItem('Runtime Style', '运行时样式', 'pages/style/RuntimeStyleTestPage', '🎨'),
      new TestPageItem('Runtime Style Timing', '样式时序测试', 'pages/style/RuntimeStyleTimingTestPage', '⏱️'),
      new TestPageItem('Style', '样式管理', 'pages/style/StyleTestPage', '🎨'),
      new TestPageItem('Style URL', '样式URL切换', 'pages/style/StyleUrlTestPage', '🔗'),
      new TestPageItem('Style File', '本地样式文件', 'pages/style/StyleFileTestPage', '📄'),
      new TestPageItem('No Style', '无样式地图', 'pages/style/NoStyleTestPage', '⚪'),
      new TestPageItem('Style Transition', '样式过渡', 'pages/style/StyleTransitionTestPage', '🎬'),
      new TestPageItem('Raster Source', '栅格数据源', 'pages/style/RasterSourceTestPage', '🖼️'),
      new TestPageItem('Vector Tile Source', '矢量瓦片数据源', 'pages/style/VectorTileTestPage', '📐'),
      new TestPageItem('Animated Image', '动画图片', 'pages/style/AnimatedImageSourceTestPage', '🎞️'),
      new TestPageItem('Real Time GeoJSON', '实时 GeoJSON', 'pages/style/RealTimeGeoJsonTestPage', '⚡'),
      new TestPageItem('GeoJSON Clustering', 'GeoJSON 聚类', 'pages/style/GeoJsonClusteringTestPage', '🎯'),
      new TestPageItem('Data Driven Style', '数据驱动样式', 'pages/style/DataDrivenStyleTestPage', '📊'),
      new TestPageItem('Distance Expression', '距离表达式', 'pages/style/DistanceExpressionTestPage', '📏'),
      new TestPageItem('Gradient Line', '渐变线', 'pages/style/GradientLineTestPage', '🌈'),
      new TestPageItem('Custom Sprite', '自定义精灵', 'pages/style/CustomSpriteTestPage', '🖼️'),
      new TestPageItem('Grid Source', '网格数据源', 'pages/style/GridSourceTestPage', '🔲'),
      new TestPageItem('Collection Update', '样式变化时集合更新', 'pages/style/CollectionUpdateOnStyleChangeTestPage',
        '🔄'),
      new TestPageItem('Stretchable Image', '可拉伸图片', 'pages/style/StretchableImageTestPage', '↔️'),
      new TestPageItem('Image In Label', '标签中的图片', 'pages/style/ImageInLabelTestPage', '🖼️'),
      new TestPageItem('Source', '数据源管理', 'pages/style/SourceTestPage', '📊'),
      new TestPageItem('Light', '光照系统', 'pages/style/LightTestPage', '💡'),
      new TestPageItem('Expression', 'Expression 测试', 'pages/style/ExpressionTestPage', '🧮'),
    ]);
  }

  /**
   * 10. Layer - 图层系统
   */
  private createLayerGroup(): TestPageGroup {
    return new TestPageGroup('Layer', '🗂️', [
      new TestPageItem('Layer', '图层管理', 'pages/style/LayerTestPage', '🔨'),
      new TestPageItem('Circle Layer', '圆形图层', 'pages/style/CircleLayerTestPage', '⭕'),
      new TestPageItem('Fill Layer', '填充图层', 'pages/style/FillLayerTestPage', '🔷'),
      new TestPageItem('Line Layer', '线条图层', 'pages/style/LineLayerTestPage', '📈'),
      new TestPageItem('Symbol Layer', '符号图层', 'pages/style/SymbolLayerTestPage', '🔤'),
      new TestPageItem('Animated Symbol Layer', '动画符号图层', 'pages/style/AnimatedSymbolLayerTestPage', '🎭'),
      new TestPageItem('Symbol Generator', '符号生成器', 'pages/style/SymbolGeneratorTestPage', '🔧'),
      new TestPageItem('Zoom Function Symbol', '缩放函数符号层', 'pages/style/ZoomFunctionSymbolLayerTestPage', '🔍'),
      new TestPageItem('Background Layer', '背景图层', 'pages/style/BackgroundLayerTestPage', '⬜'),
      new TestPageItem('Fill Extrusion', '填充拉伸', 'pages/style/FillExtrusionTestPage', '🏢'),
      new TestPageItem('Building Fill Extrusion', '建筑物填充拉伸', 'pages/style/BuildingFillExtrusionTestPage', '🏙️'),
      new TestPageItem('Heatmap Layer', '热力图', 'pages/style/HeatmapLayerTestPage', '🔥'),
      new TestPageItem('Hillshade Layer', '山体阴影', 'pages/style/HillshadeLayerTestPage', '⛰️'),
      new TestPageItem('Custom Layer', '自定义渲染图层', 'pages/customlayer/CustomLayerTestPage', '🎨'),
    ]);
  }

  /**
   * 11. Features - 要素查询
   */
  private createFeaturesGroup(): TestPageGroup {
    return new TestPageGroup('Features', '🔍', [
      new TestPageItem('Point Click Query', '点击查询', 'pages/feature/PointClickQueryTestPage', '👆'),
      new TestPageItem('Box Count', '框选计数', 'pages/feature/QueryRenderedFeaturesBoxCountTestPage', '🔢'),
      new TestPageItem('Box Highlight', '框选高亮', 'pages/feature/QueryRenderedFeaturesBoxHighlightTestPage', '✨'),
      new TestPageItem('Symbol Count', '符号计数', 'pages/feature/QueryRenderedFeaturesBoxSymbolCountTestPage', '🔤'),
      new TestPageItem('Feature Properties', '要素属性', 'pages/feature/QueryRenderedFeaturesPropertiesTestPage', '📋'),
      new TestPageItem('Source Features', '数据源要素', 'pages/feature/QuerySourceFeaturesTestPage', '📊'),
    ]);
  }

  /**
   * 12. Storage - 存储管理
   */
  private createStorageGroup(): TestPageGroup {
    return new TestPageGroup('Storage', '💿', [
      new TestPageItem('Cache Management', '缓存管理', 'pages/storage/CacheManagementTestPage', '🗑️'),
      new TestPageItem('URL Transform', 'URL转换', 'pages/storage/UrlTransformTestPage', '🔗'),
      new TestPageItem('Custom HTTP Request', '自定义HTTP请求', 'pages/storage/CustomHttpRequestTestPage', '🌐'),
    ]);
  }

  /**
   * 13. Events - 事件监听
   */
  private createEventsGroup(): TestPageGroup {
    return new TestPageGroup('Events', '📡', [
      new TestPageItem('Observer', '事件观察者', 'pages/events/ObserverTestPage', '👁️'),
      new TestPageItem('Event Listeners', '事件监听器', 'pages/listeners/EventListenersTestPage', '👂'),
    ]);
  }

  /**
   * 14. Image Generator - 图片生成
   */
  private createImageGeneratorGroup(): TestPageGroup {
    return new TestPageGroup('Image Generator', '📸', [
      new TestPageItem('Snapshot Basic', '基础快照', 'pages/snapshot/SnapshotBasicTestPage', '📸'),
      new TestPageItem('Map Snapshotter', '地图快照器', 'pages/snapshot/MapSnapshotterTestPage', '📷'),
      new TestPageItem('Snapshotter Reuse', '快照器重用', 'pages/snapshot/MapSnapshotterReuseTestPage', '♻️'),
      new TestPageItem('Bitmap Overlay', '位图叠加', 'pages/snapshot/MapSnapshotterBitmapOverlayTestPage', '🖼️'),
      new TestPageItem('Heatmap Snapshot', '热力图快照', 'pages/snapshot/MapSnapshotterHeatMapTestPage', '🔥'),
      new TestPageItem('Local Style Snapshot', '本地样式快照', 'pages/snapshot/MapSnapshotterLocalStyleTestPage', '📄'),
    ]);
  }

  /**
   * 15. Texture View - 纹理视图
   */
  private createTextureViewGroup(): TestPageGroup {
    return new TestPageGroup('Texture View', '🎬', [
      new TestPageItem('TextureView Debug', '纹理视图调试', 'pages/textureview/TextureViewDebugModeTestPage', '🐛'),
      new TestPageItem('TextureView Resize', '纹理视图调整大小', 'pages/textureview/TextureViewResizeTestPage', '📐'),
      new TestPageItem('TextureView Animation', '纹理视图动画', 'pages/textureview/TextureViewAnimationTestPage', '🎭'),
      new TestPageItem('TextureView Transparent', '纹理视图透明背景',
        'pages/textureview/TextureViewTransparentBackgroundTestPage', '⚪'),
    ]);
  }

  /**
   * 16. Turf - 地理计算
   */
  private createTurfGroup(): TestPageGroup {
    return new TestPageGroup('Turf', '🌍', [
      new TestPageItem('Physical Unit Circle', '物理单位圆', 'pages/turf/PhysicalUnitCircleTestPage', '⭕'),
      new TestPageItem('Within Expression', 'Within表达式', 'pages/turf/WithinExpressionTestPage', '📍'),
      new TestPageItem('Snapshotter Within', '快照器Within表达式', 'pages/turf/MapSnapshotterWithinExpressionTestPage',
        '📸'),
    ]);
  }

  /**
   * 17. Map Options - 地图选项
   */
  private createMapOptionsGroup(): TestPageGroup {
    return new TestPageGroup('Map Options', '⚙️', [
      new TestPageItem('Map Options Runtime', '运行时地图选项', 'pages/options/MapOptionsRuntimeTestPage', '⚙️'),
      new TestPageItem('Map Options XML', 'XML配置地图选项', 'pages/options/MapOptionsXmlTestPage', '📄'),
    ]);
  }

  /**
   * 18. Integration - 集成测试
   */
  private createIntegrationGroup(): TestPageGroup {
    return new TestPageGroup('Integration', '🔗', [
      new TestPageItem('Multi Map', '多地图实例', 'pages/fragment/MultiMapTestPage', '🗺️🗺️'),
      new TestPageItem('ViewPager', 'ViewPager地图', 'pages/fragment/ViewPagerTestPage', '📄'),
      new TestPageItem('Nested ViewPager', '嵌套ViewPager', 'pages/fragment/NestedViewPagerTestPage', '📑'),
      new TestPageItem('Fragment BackStack', '片段回退栈', 'pages/fragment/FragmentBackStackTestPage', '⬅️'),
    ]);
  }

  /**
   * 19. Performance - 性能测试
   */
  private createPerformanceGroup(): TestPageGroup {
    return new TestPageGroup('Performance', '⚡', [
      new TestPageItem('Benchmark', '性能基准测试', 'pages/other/BenchmarkTestPage', '🏁'),
      new TestPageItem('Performance Measurement', '性能测量', 'pages/other/PerformanceMeasurementTestPage', '📊'),
    ]);
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
          .padding({
            top: 10,
            bottom: 10,
            left: 4,
            right: 4
          })
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
      .padding({
        left: 10,
        right: 10,
        top: 10,
        bottom: 10
      })
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
        // const currentGroup = this.testPageGroups[this.selectedGroupIndex]

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
        .padding({
          left: 20,
          right: 20,
          top: 15,
          bottom: 10
        })
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
        .padding({
          left: 20,
          right: 20,
          top: 15,
          bottom: 10
        })
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

