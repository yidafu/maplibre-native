import { 
  LatLng, 
  Marker,
  Icon,
  MarkerOptions, 
  OnMarkerClickListener,
  OnMarkerSelectListener,
  NativeMapView,
  MapLibreMap,
  MapLibreMapOptions,
  AnnotationViewAdapter,
  IconFactory,
  CameraOptions
} from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { MapView } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS, randomLatLng  } from '../common/TestUtils';

/**
 * AnnotationViewTestPage - AnnotationView 自定义视图测试页面
 * 
 * 测试功能：
 * 1. 基础自定义视图 - 使用自定义 Builder 创建不同样式的 Marker
 * 2. 视图复用 - 添加多个相同样式的 Marker，观察复用效果
 * 3. 可拖拽 Marker - 长按拖动，显示拖拽动画
 * 4. 视图变换：
 *    - scalesWithViewingDistance（倾斜地图观察缩放）
 *    - rotatesToMatchCamera（旋转地图观察旋转）
 * 5. 选中状态 - 点击 Marker 显示选中效果
 * 
 * 参考:
 * - iOS: MLNAnnotationView
 * - Android: Annotation View Examples
 */

interface TestMarkerData {
  lat: number;
  lng: number;
  type: string;
  title: string;
}

/**
 * Marker 点击监听器
 */
class MarkerClickListenerImpl implements OnMarkerClickListener {
  private testPage: AnnotationViewTestPage;
  
  constructor(testPage: AnnotationViewTestPage) {
    this.testPage = testPage;
  }
  
  onMarkerClick(marker: Marker): boolean {
    const title = marker.getTitle() || 'Unknown';
    const pos = marker.getPosition();
    
    this.testPage.selectedMarkerId = marker.getId();
    this.testPage.statusMessage = `🎯 点击: ${title} (${pos.latitude.toFixed(4)}, ${pos.longitude.toFixed(4)})`;
    
    hilog.info(DOMAIN, 'AnnotationViewTest', `Marker clicked: ${title}`);
    
    promptAction.showToast({
      message: `点击: ${title}`,
      duration: 2000
    });
    
    return true;
  }
}

/**
 * Marker 选中监听器
 */
class MarkerSelectListenerImpl implements OnMarkerSelectListener {
  private testPage: AnnotationViewTestPage;
  
  constructor(testPage: AnnotationViewTestPage) {
    this.testPage = testPage;
  }
  
  onMarkerSelect(marker: Marker): void {
    const title = marker.getTitle() || 'Unknown';
    this.testPage.statusMessage = `✅ 选中: ${title}`;
    hilog.info(DOMAIN, 'AnnotationViewTest', `Marker selected: ${title}`);
  }
  
  onMarkerDeselect(marker: Marker): void {
    const title = marker.getTitle() || 'Unknown';
    this.testPage.statusMessage = `⭕ 取消选中: ${title}`;
    hilog.info(DOMAIN, 'AnnotationViewTest', `Marker deselected: ${title}`);
  }
}

/**
 * 自定义 AnnotationView 适配器
 * 
 * 注意：ComponentContent API 当前不可用，暂时返回 null 使用默认图标
 * 未来可以通过此接口提供自定义视图
 */
class TestAnnotationViewAdapter implements AnnotationViewAdapter {
  getAnnotationView(marker: Marker): object | null {
    // TODO: 等待 HarmonyOS SDK 支持 ComponentContent 和 wrapBuilder
    // 当前返回 null 使用默认图标
    return null;
  }
  
  getReuseIdentifier(marker: Marker): string {
    const snippet = marker.getSnippet();
    return snippet || 'default';
  }
}

@Entry
@Component
struct AnnotationViewTestPage {
  @State statusMessage: string = '等待地图加载...';
  @State markerCount: number = 0;
  @State mapReady: boolean = false;
  @State testMode: string = 'basic'; // 'basic', 'draggable', 'transform'
  @State selectedMarkerId: number = -1;
  @State scalesEnabled: boolean = false;
  @State rotatesEnabled: boolean = false;
  @State autoFlyToMarkers: boolean = true; // 添加 Markers 后自动 flyTo
  @State currentIconTheme: string = 'all-random'; // 当前图标主题，默认为随机模式
  
  private mapLibreMap: MapLibreMap | null = null;
  private markerList: Marker[] = [];;
  private markerLocations: TestMarkerData[] = [];;
  private annotationViewAdapter: TestAnnotationViewAdapter = new TestAnnotationViewAdapter();
  private iconFactory: IconFactory | null = null;
  // 存储所有可用的图标
  private markerIcons: Map<string, Icon> = new Map();

  aboutToDisappear() {
    hilog.info(DOMAIN, 'AnnotationViewTest', 'aboutToDisappear');
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
    }
  }

  /**
   * 地图区域构建器
   */
  @Builder
  buildMapContent() {
    Stack() {
      MapView({
        styleUrl: DEFAULT_STYLE_URLS.bright,
        initialLatitude: 39.9,
        initialLongitude: 116.4,
        initialZoom: 5,
        initialBearing: 0,
        initialPitch: 0,
        onMapReady: this.onMapReady
      })
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 操作按钮构建器
   */
  @Builder
  buildActionButtons() {
    Scroll() {
      Column({ space: 12 }) {
        Text('AnnotationView 功能测试')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        Text('✨ 10 个自定义图标可选')
          .fontSize(11)
          .fontColor('#4caf50')
          .width('100%')
        
        Text('默认：蓝色图钉 + 绿色圆点 | 可切换主题或随机')
          .fontSize(11)
          .fontColor('#999')
          .width('100%')
        // 基础操作
        Text('基础操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        
        Button('添加自定义 Markers')
          .width('100%')
          .onClick(() => {
            this.addCustomMarkers();
          })
        
        Button('清除所有 Markers')
          .width('100%')
          .onClick(() => {
            this.clearMarkers();
          })
        
        Row() {
          Text('添加后自动定位')
            .fontSize(14)
          .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.autoFlyToMarkers })
            .onChange((isOn: boolean) => {
              this.autoFlyToMarkers = isOn;
            })
        }
        .width('100%')
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        .margin({ top: 8 })
        
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 自定义视图测试
        Text('自定义视图测试')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Button('添加自定义视图')
          .width('100%')
          .onClick(() => {
            this.addCustomAnnotationViews();
          })
        
        Button('切换图标主题')
          .width('100%')
          .onClick(() => {
            this.switchIconTheme();
          })
        
        Text(`当前主题：${this.getIconThemeDescription()}`)
          .fontSize(11)
          .fontColor('#666')
          .width('100%')
        
        Row({ space: 8 }) {
          Button('加载全部图标')
            .layoutWeight(1)
            .fontSize(12)
            .onClick(() => {
              this.loadAllIcons();
            })
          
          Button('随机图标')
            .layoutWeight(1)
            .fontSize(12)
            .onClick(() => {
              this.applyRandomIcons();
            })
        }
        .width('100%')
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 测试模式
        Text('测试模式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Row({ space: 8 }) {
          Button('基础模式')
            .width('30%')
            .fontSize(12)
            .type(this.testMode === 'basic' ? ButtonType.Normal : ButtonType.Capsule)
            .onClick(() => {
              this.switchMode('basic');
            })
          
          Button('拖拽模式')
            .width('30%')
            .fontSize(12)
            .type(this.testMode === 'draggable' ? ButtonType.Normal : ButtonType.Capsule)
            .onClick(() => {
              this.switchMode('draggable');
            })
          
          Button('变换模式')
            .width('30%')
            .fontSize(12)
            .type(this.testMode === 'transform' ? ButtonType.Normal : ButtonType.Capsule)
          .onClick(() => {
              this.switchMode('transform');
          })
      }
      .width('100%')
        
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 视图变换选项
        Text('视图变换选项')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Row() {
          Text('距离缩放')
            .fontSize(14)
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.scalesEnabled })
            .onChange((isOn: boolean) => {
              this.scalesEnabled = isOn;
              this.updateMarkersTransform();
            })
        }
        .width('100%')
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        
        Text('启用后，Marker 会根据倾斜角度自动缩放')
          .fontSize(11)
          .fontColor('#999')
          .width('100%')
        Row() {
          Text('跟随旋转')
            .fontSize(14)
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.rotatesEnabled })
            .onChange((isOn: boolean) => {
              this.rotatesEnabled = isOn;
              this.updateMarkersTransform();
            })
        }
        .width('100%')
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        .margin({ top: 8 })
        
        Text('启用后，Marker 会跟随地图旋转')
          .fontSize(11)
          .fontColor('#999')
          .width('100%')
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 状态信息
        Text('状态信息')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Column({ space: 8 }) {
          Row() {
            Text('Markers: ')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
            Text(`${this.markerCount}`)
              .fontSize(12)
              .fontColor('#2196F3')
          }
          .width('100%')
          Row() {
            Text('模式: ')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
            Text(this.getModeDescription())
              .fontSize(12)
              .fontColor('#2196F3')
          }
          .width('100%')
          Row() {
            Text('选中: ')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
            Text(this.selectedMarkerId >= 0 ? `ID ${this.selectedMarkerId}` : '无')
              .fontSize(12)
              .fontColor('#2196F3')
          }
          .width('100%')
        }
        .width('100%')
        .backgroundColor('#e3f2fd')
        .borderRadius(8)
        .padding(12)
        
        Text(this.statusMessage)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .maxLines(4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 功能说明
        Text('ℹ️ 功能说明')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Column({ space: 6 }) {
          Text('✅ 已实现：')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          
          Text('• 真实添加/删除 Markers')
            .fontSize(10)
            .width('100%')
          
          Text('• 点击和选中事件')
            .fontSize(10)
            .width('100%')
          
          Text('• 拖拽模式切换')
            .fontSize(10)
            .width('100%')
          
          Text('• 飞行动画和定位')
            .fontSize(10)
            .width('100%')
          
          Text('• 自定义图标（10 个可选）')
            .fontSize(10)
            .width('100%')
          
          Text('• 图标主题切换')
            .fontSize(10)
            .width('100%')
          
          Text('• 随机图标应用')
            .fontSize(10)
            .width('100%')
          
          Text('⏳ 待实现：')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 6 })
          
          Text('• 自定义视图 Builder（需要 ComponentContent API）')
            .fontSize(10)
            .width('100%')
          
          Text('• 距离缩放效果（需要自定义视图）')
            .fontSize(10)
            .width('100%')
          
          Text('• 跟随旋转效果（需要自定义视图）')
            .fontSize(10)
            .width('100%')
        }
        .width('100%')
        .backgroundColor('#f9f9f9')
        .borderRadius(8)
        .padding(16)
      }
      .padding(16)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    try {
      this.mapLibreMap = map;
      
      this.mapReady = true;
      this.statusMessage = '✅ 地图已就绪 - 正在加载自定义图标...';
      
      // 设置事件监听器
      this.setupEventListeners();
      
      // 设置 AnnotationView 适配器（已在 MapLibreMap 中设置）
      // this.setupAnnotationViewAdapter();
      
      // 加载自定义图标（异步）
      await this.loadCustomIcons();
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Map ready and listeners configured');
      
      promptAction.showToast({
        message: '地图已就绪',
        duration: 2000
      });
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to initialize: ${errorMsg}`);
      this.statusMessage = `❌ 初始化失败: ${errorMsg}`;
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    if (!this.mapLibreMap) return;
    
    // 创建监听器实例
    const markerClickListener = new MarkerClickListenerImpl(this);
    const markerSelectListener = new MarkerSelectListenerImpl(this);
    
    // 设置监听器
    this.mapLibreMap.setOnMarkerClickListener(markerClickListener);
    this.mapLibreMap.setOnMarkerSelectListener(markerSelectListener);
    
    hilog.info(DOMAIN, 'AnnotationViewTest', 'Event listeners configured');
  }

  /**
   * 设置 AnnotationView 适配器
   */
  private setupAnnotationViewAdapter(): void {
    if (!this.mapLibreMap) return;
    
    const markerManager = this.mapLibreMap.getMarkerManager();
    
    // 设置 AnnotationView 适配器
    markerManager.setAnnotationViewAdapter(this.annotationViewAdapter);
    
    hilog.info(DOMAIN, 'AnnotationViewTest', 'AnnotationView adapter configured');
  }

  /**
   * 加载自定义图标（根据主题）
   */
  private async loadCustomIcons(): Promise<void> {
    try {
      // 获取应用上下文和 ResourceManager
      const context = getContext(this) as common.UIAbilityContext;
      const resourceMgr = context.resourceManager;
      
      // 创建 IconFactory 实例
      this.iconFactory = IconFactory.getInstance(resourceMgr);
      
      // 根据当前主题加载不同的图标
      await this.loadIconsForTheme(this.currentIconTheme);
      
      this.statusMessage = '✅ 地图已就绪 - 自定义图标已加载！\n点击"添加自定义 Markers"开始测试';
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Custom icons loaded successfully (theme: ${this.currentIconTheme})`);
      
      promptAction.showToast({
        message: '自定义图标加载成功',
        duration: 2000
      });
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to load custom icons: ${errorMsg}`);
      this.statusMessage = `⚠️ 图标加载失败，使用默认图标\n${errorMsg}`;
      
      // 即使图标加载失败，也不影响其他功能
      promptAction.showToast({
        message: '图标加载失败，使用默认图标',
        duration: 2000
      });
    }
  }

  /**
   * 根据主题加载图标
   */
  private async loadIconsForTheme(theme: string): Promise<void> {
    if (!this.iconFactory) {
      throw new Error('IconFactory not initialized');
    }
    
    // 清除旧图标
    this.markerIcons.clear();
    
    if (theme === 'all-random') {
      // 加载所有图标供随机选择
      await this.loadAllIconsInternal();
    } else {
      // 加载特定主题的图标
      switch (theme) {
        case 'blue-green':
          // 蓝色图钉 + 绿色圆点
          const bluePin = await this.iconFactory.fromResource(
            $r('app.media.marker_pin_blue'),
            'custom-pin'
          );
          this.markerIcons.set('custom-pin', bluePin);
          
          const greenDot = await this.iconFactory.fromResource(
            $r('app.media.marker_dot_green'),
            'custom-dot'
          );
          this.markerIcons.set('custom-dot', greenDot);
          break;
          
        case 'red-yellow':
          // 红色图钉 + 黄色圆点
          const redPin = await this.iconFactory.fromResource(
            $r('app.media.marker_pin_red'),
            'custom-pin'
          );
          this.markerIcons.set('custom-pin', redPin);
          
          const yellowDot = await this.iconFactory.fromResource(
            $r('app.media.marker_dot_yellow'),
            'custom-dot'
          );
          this.markerIcons.set('custom-dot', yellowDot);
          break;
          
        case 'orange-cyan':
          // 橙色图钉 + 青色圆点
          const orangePin = await this.iconFactory.fromResource(
            $r('app.media.marker_pin_orange'),
            'custom-pin'
          );
          this.markerIcons.set('custom-pin', orangePin);
          
          const cyanDot = await this.iconFactory.fromResource(
            $r('app.media.marker_dot_cyan'),
            'custom-dot'
          );
          this.markerIcons.set('custom-dot', cyanDot);
          break;
          
        case 'purple-blue':
          // 紫色图钉 + 蓝色圆点
          const purplePin = await this.iconFactory.fromResource(
            $r('app.media.marker_pin_purple'),
            'custom-pin'
          );
          this.markerIcons.set('custom-pin', purplePin);
          
          const blueDot = await this.iconFactory.fromResource(
            $r('app.media.marker_dot_blue'),
            'custom-dot'
          );
          this.markerIcons.set('custom-dot', blueDot);
          break;
      }
    }
    
    hilog.info(DOMAIN, 'AnnotationViewTest', `Loaded icons for theme: ${theme}`);
  }

  /**
   * 内部方法：加载所有图标
   */
  private async loadAllIconsInternal(): Promise<void> {
    if (!this.iconFactory) return;
    
    // 加载所有 Pin 图标
    const pinColors = ['red', 'blue', 'green', 'orange', 'purple']
    for (const color of pinColors) {
      const icon = await this.iconFactory.fromResource(
        $r(`app.media.marker_pin_${color}`),
        `pin-${color}`
      );
      this.markerIcons.set(`pin-${color}`, icon);
    }
    
    // 加载所有 Dot 图标
    const dotColors = ['red', 'blue', 'green', 'yellow', 'cyan']
    for (const color of dotColors) {
      const icon = await this.iconFactory.fromResource(
        $r(`app.media.marker_dot_${color}`),
        `dot-${color}`
      );
      this.markerIcons.set(`dot-${color}`, icon);
    }
  }

  /**
   * 切换图标主题
   */
  private async switchIconTheme(): Promise<void> {
    const themes = ['all-random', 'blue-green', 'red-yellow', 'orange-cyan', 'purple-blue']
    const currentIndex = themes.indexOf(this.currentIconTheme);
    const nextIndex = (currentIndex + 1) % themes.length;
    this.currentIconTheme = themes[nextIndex]
    
    this.statusMessage = '正在切换图标主题...';
    
    try {
      // 重新加载图标
      await this.loadIconsForTheme(this.currentIconTheme);
      
      // 如果有 Markers，重新应用图标
      if (this.markerList.length > 0) {
        if (this.currentIconTheme === 'all-random') {
          // 随机主题：为每个 Marker 随机分配图标
          await this.applyRandomIconsToMarkers();
        } else {
          // 固定主题：根据类型应用图标
          await this.reapplyIcons();
        }
      }
      
      this.statusMessage = `✅ 已切换到：${this.getIconThemeDescription()}`;
      
      promptAction.showToast({
        message: `主题：${this.getIconThemeDescription()}`,
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Switched to theme: ${this.currentIconTheme}`);
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to switch theme: ${errorMsg}`);
      this.statusMessage = `❌ 切换失败: ${errorMsg}`;
    }
  }

  /**
   * 加载所有可用图标（10个）- 公开方法
   */
  private async loadAllIcons(): Promise<void> {
    if (!this.iconFactory) {
      this.statusMessage = 'IconFactory 未初始化';
      return;
    }
    
    this.statusMessage = '正在加载所有图标...';
    
    try {
      // 清除旧图标
      this.markerIcons.clear();
      
      await this.loadAllIconsInternal();
      
      // 设置为随机主题
      this.currentIconTheme = 'all-random';
      
      this.statusMessage = `✅ 已加载全部 10 个图标！\n5 个 Pin + 5 个 Dot\n主题已切换为"随机模式"`;
      
      promptAction.showToast({
        message: '已加载全部 10 个图标',
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Loaded all ${this.markerIcons.size} icons`);
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to load all icons: ${errorMsg}`);
      this.statusMessage = `❌ 加载失败: ${errorMsg}`;
    }
  }

  /**
   * 为 Markers 应用随机图标（按钮触发）
   */
  private async applyRandomIcons(): Promise<void> {
    if (this.markerList.length === 0) {
      this.statusMessage = '请先添加 Markers';
      promptAction.showToast({
        message: '请先添加 Markers',
        duration: 2000
      });
      return;
    }
    
    if (this.markerIcons.size === 0) {
      this.statusMessage = '请先加载全部图标';
      promptAction.showToast({
        message: '请先点击"加载全部图标"',
        duration: 2000
      });
      return;
    }
    
    await this.applyRandomIconsToMarkers();
  }

  /**
   * 为 Markers 应用随机图标（内部方法）
   */
  private async applyRandomIconsToMarkers(): Promise<void> {
    try {
      const availableIconIds: string[] = Array.from(this.markerIcons.values()).map((icon: Icon) => icon.getId());
      
      if (availableIconIds.length === 0) {
        hilog.warn(DOMAIN, 'AnnotationViewTest', 'No icons available for random assignment');
        return;
      }
      
      for (const marker of this.markerList as Marker[]) {
        // 随机选择一个图标 ID
        const randomIconId: string = availableIconIds[Math.floor(Math.random() * availableIconIds.length)]
        marker.setIcon(randomIconId);
      }
      
      // 通过 MapLibreMap 更新，触发视图刷新
      if (this.mapLibreMap) {
        for (const marker of this.markerList) {
          this.mapLibreMap.updateMarker(marker);
        }
      }
      
      this.statusMessage = `✅ 已为 ${this.markerList.length} 个 Markers 应用随机图标\n从 ${this.markerIcons.size} 个图标中随机选择`;
      
      promptAction.showToast({
        message: '随机图标已应用',
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Applied random icons to all markers');
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to apply random icons: ${errorMsg}`);
      this.statusMessage = `❌ 应用失败: ${errorMsg}`;
    }
  }

  /**
   * 重新应用当前主题的图标到所有 Markers
   */
  private async reapplyIcons(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      for (let i = 0; i < this.markerList.length; i++) {
        const marker: Marker = this.markerList[i]
        const loc = this.markerLocations[i]
        
        const customIcon: Icon | undefined = this.markerIcons.get(loc.type);
        if (customIcon) {
          // 设置图标 ID
          marker.setIcon(customIcon.getId());
          // 更新 Marker
          this.mapLibreMap.updateMarker(marker);
        }
      }
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Reapplied icons to all markers');
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to reapply icons: ${e}`);
    }
  }

  /**
   * 获取图标主题描述
   */
  private getIconThemeDescription(): string {
    switch (this.currentIconTheme) {
      case 'all-random':
        return '随机模式（10 个图标）';
      case 'blue-green':
        return '蓝色图钉 + 绿色圆点';
      case 'red-yellow':
        return '红色图钉 + 黄色圆点';
      case 'orange-cyan':
        return '橙色图钉 + 青色圆点';
      case 'purple-blue':
        return '紫色图钉 + 蓝色圆点';
      default:
        return '未知主题';
    }
  }

  /**
   * 添加自定义 Markers
   */
  private async addCustomMarkers(): Promise<void> {
    if (!this.mapLibreMap) {
      this.statusMessage = '地图未就绪';
      promptAction.showToast({
        message: '地图未就绪',
        duration: 2000
      });
      return;
    }
    
    // 清除现有的
    await this.clearMarkers();
    
    // 中国主要城市测试点（分布范围更大）
    this.markerLocations = [
      { lat: 39.9042, lng: 116.4074, type: 'custom-pin', title: '北京' },
      { lat: 31.2304, lng: 121.4737, type: 'custom-dot', title: '上海' },
      { lat: 23.1291, lng: 113.2644, type: 'custom-pin', title: '广州' },
      { lat: 30.5728, lng: 104.0668, type: 'custom-dot', title: '成都' },
    ]
    
    let addedCount = 0;
    
    try {
      for (const loc of this.markerLocations) {
        // 创建 MarkerOptions，根据类型设置不同的视觉属性
        const options = new MarkerOptions()
          .position(new LatLng(loc.lat, loc.lng))
          .title(loc.title)
          .snippet(loc.type)
          .draggable(this.testMode === 'draggable');
        
        // 根据主题设置图标
        if (this.currentIconTheme === 'all-random' && this.markerIcons.size > 0) {
          // 随机模式：从所有图标中随机选择
          const availableIcons: Icon[] = Array.from(this.markerIcons.values());
          const randomIcon: Icon = availableIcons[Math.floor(Math.random() * availableIcons.length)]
          options.icon(randomIcon)
            .alpha(1.0)
            .zIndex(Math.floor(Math.random() * 20));
        } else {
          // 固定主题：根据类型选择图标
          const customIcon: Icon | undefined = this.markerIcons.get(loc.type);
          if (customIcon) {
            // 使用自定义图标
            options.icon(customIcon)
              .alpha(1.0)
              .zIndex(loc.type === 'custom-pin' ? 10 : 5);
          } else {
            // 如果图标未加载，使用默认图标并通过旋转区分
            if (loc.type === 'custom-pin') {
              options.alpha(1.0).rotation(0).zIndex(10);
            } else {
              options.alpha(0.85).rotation(45).zIndex(5);
            }
          }
        }
        
        // 添加 Marker
        const marker = await this.mapLibreMap.addMarker(options);
        this.markerList.push(marker);
        addedCount++;
        
        hilog.info(DOMAIN, 'AnnotationViewTest', 
          `Added marker: ${loc.title} (${loc.type}) at (${loc.lat}, ${loc.lng}), ID=${marker.getId()}`);
      }
      
      this.markerCount = addedCount;
      const hasCustomIcons = this.markerIcons.size > 0;
      const iconStatus = hasCustomIcons ? '使用自定义图标' : '使用默认图标';
      
      let iconDescription = '';
      if (this.currentIconTheme === 'all-random') {
        iconDescription = '每个 Marker 使用随机图标';
      } else if (hasCustomIcons) {
        iconDescription = `Pin类型（北京/广州）+ Dot类型（上海/成都）`;
      } else {
        iconDescription = '使用默认红点图标';
      }
      
      this.statusMessage = `✅ 已添加 ${addedCount} 个 Markers（${iconStatus}）\n` +
                          `${iconDescription}\n` +
                          `当前主题: ${this.getIconThemeDescription()}\n` +
                          (this.testMode === 'draggable' ? '长按可拖拽' : '点击可选中');
      
      promptAction.showToast({
        message: `成功添加 ${addedCount} 个 Markers`,
        duration: 2000
      });
      
      // 自动飞到 Markers 位置
      if (this.autoFlyToMarkers && addedCount > 0) {
        setTimeout(() => {
          this.flyToAllMarkers();
        }, 500);
      }
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to add markers: ${errorMsg}`);
      this.statusMessage = `❌ 添加失败: ${errorMsg}`;
      
      promptAction.showToast({
        message: `添加失败: ${errorMsg}`,
        duration: 2000
      });
    }
  }

  /**
   * 添加自定义视图（使用 AnnotationView）
   */
  private async addCustomAnnotationViews(): Promise<void> {
    if (!this.mapLibreMap) {
      this.statusMessage = 'MapLibreMap 未初始化';
      return;
    }
    
    this.statusMessage = '正在添加自定义视图...';
    
    try {
      // TODO: 实现自定义 AnnotationView 的添加
      // 当前先使用 Marker 实现，后续可以扩展为真正的自定义视图
      
      // 暂时使用 addCustomMarkers 的实现
      await this.addCustomMarkers();
      
      this.statusMessage = '✅ 自定义视图已添加\n' +
                          '（当前使用 Marker 实现，后续将支持自定义 ArkTS 组件）';
      
      promptAction.showToast({
        message: '自定义视图已添加',
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Custom annotation views added (using Markers)');
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to add custom annotation views: ${errorMsg}`);
      this.statusMessage = `❌ 添加失败: ${errorMsg}`;
      
      promptAction.showToast({
        message: `添加失败: ${errorMsg}`,
        duration: 2000
      });
    }
  }

  /**
   * 清除所有 Markers
   */
  private async clearMarkers(): Promise<void> {
    if (!this.mapLibreMap) {
      return;
    }
    
    try {
      // 移除所有 Markers
      for (const marker of this.markerList) {
        await this.mapLibreMap.removeMarker(marker);
      }
      
      this.markerList = [];
      this.markerLocations = [];
      this.markerCount = 0;
      this.selectedMarkerId = -1;
      this.statusMessage = '已清除所有 Markers';
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Cleared all markers');
      
      promptAction.showToast({
        message: '已清除所有 Markers',
        duration: 2000
      });
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to clear markers: ${errorMsg}`);
    }
  }

  /**
   * 飞到所有 Markers（计算边界并显示所有 Markers）
   */
  private flyToAllMarkers(): void {
    if (!this.mapLibreMap || this.markerLocations.length === 0) {
      this.statusMessage = '没有可飞往的 Markers';
      promptAction.showToast({
        message: '请先添加 Markers',
        duration: 2000
      });
      return;
    }
    
    try {
      // 计算所有 Markers 的中心点
      let totalLat = 0;
      let totalLng = 0;
      
      this.markerLocations.forEach((loc: TestMarkerData) => {
        totalLat += loc.lat;
        totalLng += loc.lng;
      });
      
      const centerLat = totalLat / this.markerLocations.length;
      const centerLng = totalLng / this.markerLocations.length;
      
      // 使用 flyTo 方法飞到中心点（缩小 zoom 以显示更大范围）
      const options: CameraOptions = {
        center: LatLng.create(centerLat, centerLng),
        zoom: 5
      };
      this.mapLibreMap.flyTo(options, 2000);
      
      this.statusMessage = `飞往 ${this.markerLocations.length} 个 Markers 的中心位置\n` +
                          `中心坐标: (${centerLat.toFixed(4)}, ${centerLng.toFixed(4)})`;
      
      promptAction.showToast({
        message: '飞往所有 Markers',
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 
        `Flying to center: (${centerLat}, ${centerLng})`);
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to fly to markers: ${e}`);
      this.statusMessage = `飞行失败: ${e}`;
    }
  }

  /**
   * 飞到指定索引的 Marker
   */
  private flyToMarkerByIndex(index: number): void {
    if (!this.mapLibreMap || index < 0 || index >= this.markerLocations.length) {
      this.statusMessage = 'Marker 不存在';
      promptAction.showToast({
        message: `Marker ${index + 1} 不存在`,
        duration: 2000
      });
      return;
    }
    
    try {
      const loc = this.markerLocations[index]
      
      // 飞到指定 Marker，zoom 10，动画时长 2000ms
      const options: CameraOptions = {
        center: LatLng.create(loc.lat, loc.lng),
        zoom: 10
      };
      this.mapLibreMap.flyTo(options, 2000);
      
      // 如果有对应的 Marker 对象，选中它
      if (index < this.markerList.length) {
        const marker = this.markerList[index]
        this.selectedMarkerId = marker.getId();
      }
      
      this.statusMessage = `飞往 ${loc.title}\n` +
                          `坐标: (${loc.lat.toFixed(4)}, ${loc.lng.toFixed(4)})`;
      
      promptAction.showToast({
        message: `飞往: ${loc.title}`,
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 
        `Flying to marker ${index}: ${loc.title} at (${loc.lat}, ${loc.lng})`);
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to fly to marker: ${e}`);
      this.statusMessage = `飞行失败: ${e}`;
    }
  }

  /**
   * 逐个飞往 Markers（循环展示）
   */
  private flyToMarkersSequentially(): void {
    if (!this.mapLibreMap || this.markerLocations.length === 0) {
      this.statusMessage = '没有可飞往的 Markers';
      promptAction.showToast({
        message: '请先添加 Markers',
        duration: 2000
      });
      return;
    }
    
    this.statusMessage = '开始逐个飞行展示...';
    
    // 使用递归实现顺序飞行
    const flyToNext = (index: number) => {
      if (index >= this.markerLocations.length) {
        // 所有 Markers 飞行完成，回到中心
        setTimeout(() => {
          this.flyToAllMarkers();
        }, 3000);
        return;
      }
      
      // 飞到当前 Marker
      this.flyToMarkerByIndex(index);
      
      // 3秒后飞到下一个
      setTimeout(() => {
        flyToNext(index + 1);
      }, 3000);
    };
    
    // 从第一个 Marker 开始
    flyToNext(0);
    
    promptAction.showToast({
      message: '开始逐个飞行展示',
      duration: 2000
    });
    
    hilog.info(DOMAIN, 'AnnotationViewTest', 'Starting sequential flyTo');
  }

  /**
   * 切换测试模式
   */
  private switchMode(mode: string): void {
    this.testMode = mode;
    
    // 如果有 Markers，重新应用拖拽属性
    if (this.markerList.length > 0) {
      const isDraggable = (mode === 'draggable');
      this.markerList.forEach(marker => {
        marker.setDraggable(isDraggable);
      });
    }
    
    this.statusMessage = `已切换到${this.getModeDescription()}`;
    
    hilog.info(DOMAIN, 'AnnotationViewTest', `Switched to mode: ${mode}`);
    
    promptAction.showToast({
      message: `模式：${this.getModeDescription()}`,
      duration: 2000
    });
  }
  
  /**
   * 更新 Markers 变换
   */
  private updateMarkersTransform(): void {
    const scalesStr = this.scalesEnabled ? '启用' : '禁用';
    const rotatesStr = this.rotatesEnabled ? '启用' : '禁用';
    
    this.statusMessage = `距离缩放: ${scalesStr}\n跟随旋转: ${rotatesStr}\n` +
                        `倾斜或旋转地图查看效果`;
    
    // TODO: 更新 AnnotationView 的 transform 属性
    // 当前 AnnotationView API 还未完全集成到 Marker
    
    hilog.info(DOMAIN, 'AnnotationViewTest', 
      `Transform updated - scales: ${this.scalesEnabled}, rotates: ${this.rotatesEnabled}`);
  }

  /**
   * 设置地图倾斜角度
   */
  private setPitch(pitch: number): void {
    if (!this.mapLibreMap) {
      return;
    }
    
    try {
      this.mapLibreMap.setPitch(pitch, 500);
      
      this.statusMessage = `地图倾斜至 ${pitch}°\n` +
                          (this.scalesEnabled ? 'Marker 会根据距离自动缩放（待实现）' : '未启用距离缩放');
      
    promptAction.showToast({
        message: `倾斜: ${pitch}°`,
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Set pitch: ${pitch}`);
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to set pitch: ${e}`);
    }
  }

  /**
   * 设置地图旋转角度
   */
  private setBearing(bearing: number): void {
    if (!this.mapLibreMap) {
      return;
    }
    
    try {
      // 使用 setBearing 方法
      this.mapLibreMap.setBearing(bearing, 500);
      
      this.statusMessage = `地图旋转至 ${bearing}°\n` +
                          (this.rotatesEnabled ? 'Marker 会跟随地图旋转（待实现）' : '未启用跟随旋转');
      
      promptAction.showToast({
        message: `旋转: ${bearing}°`,
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Set bearing: ${bearing}`);
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to set bearing: ${e}`);
    }
  }

  /**
   * 恢复正常视角
   */
  private resetCamera(): void {
    if (!this.mapLibreMap) {
      return;
    }
    
    try {
      // 使用 easeTo 方法重置视角（中国中心）
      const options: CameraOptions = {
        center: LatLng.create(35.0, 105.0),
        zoom: 5,
        bearing: 0,
        pitch: 0
      };
      this.mapLibreMap.easeTo(options, 1000);
      
      this.statusMessage = '相机已恢复正常视角';
      
    promptAction.showToast({
        message: '已恢复正常视角',
      duration: 2000
    });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Camera reset');
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to reset camera: ${e}`);
    }
  }

  /**
   * 获取模式描述
   */
  private getModeDescription(): string {
    switch (this.testMode) {
      case 'basic':
        return '基础模式 - 展示自定义视图和选中效果';
      case 'draggable':
        return '拖拽模式 - 长按可拖拽 Marker';
      case 'transform':
        return '变换模式 - 观察缩放和旋转效果';
      default:
        return '未知模式';
    }
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: 'AnnotationView 测试',
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}
