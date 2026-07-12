import { InfoWindowAdapter, LatLng, MapLibreMap, Marker, MarkerOptions, MapView, OnInfoWindowClickListener, OnInfoWindowCloseListener } from 'maplibre_harmony';
import { ComponentContent, UIContext } from '@kit.ArkUI';
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast, DEFAULT_MAP_CONFIG } from '../common/TestUtils';

// Define category type
type CategoryType = 'restaurant' | 'hotel' | 'attraction' | 'shopping';

// Define custom builder types for better type safety
type CustomBuilderType = 'card' | 'bubble' | 'minimal' | 'detailed' | 'interactive';

// Custom data interface for rich content
interface CustomMarkerData {
  id: string;
  title: string;
  description: string;
  category: CategoryType;
  rating?: number;
  price?: string;
  imageUrl?: ResourceStr;
  tags?: string[];
}

@Entry
@Component
struct CustomInfoWindowTestPage {
  private mapController: MapLibreMap | null = null;
  private markers: Marker[] = [];
  private customMarkerData: Map<string, CustomMarkerData> = new Map();

  // State management
  @State private currentBuilderType: CustomBuilderType = 'card';
  @State private eventLog: string[] = [];
  @State private showEventLog: boolean = false;
  @State private animationEnabled: boolean = true;
  @State private lastWindowSize: WindowSize = { width: 0, height: 0 };

  // Color schemes for different categories
  private readonly CATEGORY_COLORS: Record<CategoryType, string> = {
    "restaurant": '#FF6B6B',
    "hotel": '#4ECDC4',
    "attraction": '#45B7D1',
    "shopping": '#96CEB4'
  };

  // Builder type display names
  private readonly BUILDER_TYPE_NAMES: Record<CustomBuilderType, string> = {
    "card": '卡片样式',
    "bubble": '气泡样式',
    "minimal": '极简样式',
    "detailed": '详细样式',
    "interactive": '交互样式'
  };

  aboutToAppear() {
    // Initialize custom marker data
    this.initializeCustomMarkerData();
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'Custom InfoWindow Builders',
        description: '自定义信息窗口构建器演示',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 11,
      onMapReady: async (map: MapLibreMap) => {
        this.mapController = map;
        await this.setupMarkers(map);
        this.setupCustomAdapter(map);
        this.setupEventListeners(map);
        showToast('地图加载完成，点击标记查看自定义 InfoWindow');
      }
    })
  }

  @Builder
  buildControlPanel() {
    Column({ space: 16 }) {
      // Builder Type Selector
      Column({ space: 8 }) {
        Text('切换构建器样式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(Object.keys(this.BUILDER_TYPE_NAMES) as CategoryType[], (type: CustomBuilderType) => {
            Button(this.BUILDER_TYPE_NAMES[type])
              .type(ButtonType.Normal)
              .fontSize(12)
              .height(32)
              .backgroundColor(this.currentBuilderType === type ? '#2196F3' : '#F0F0F0')
              .fontColor(this.currentBuilderType === type ? Color.White : Color.Black)
              .onClick(() => {
                this.switchBuilderType(type);
              })
          })
        }
      }

      // Options Section
      Column({ space: 8 }) {
        Text('选项')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        Row({ space: 12 }) {
          Checkbox({ name: 'enableAnimation', group: 'options' })
            .select(this.animationEnabled)
            .onChange((checked: boolean) => {
              this.animationEnabled = checked;
            })

          Text('启用动画')
            .fontSize(14)
        }

        Button('清除所有 InfoWindow')
          .type(ButtonType.Normal)
          .fontSize(14)
          .height(36)
          .backgroundColor('#FF5722')
          .fontColor(Color.White)
          .onClick(() => {
            this.clearAllInfoWindows();
          })
      }

      // Size Information
      if (this.lastWindowSize.width > 0) {
        Column({ space: 4 }) {
          Text('窗口尺寸信息')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)

          Text(`宽度: ${this.lastWindowSize.width}px, 高度: ${this.lastWindowSize.height}px`)
            .fontSize(12)
            .fontColor('#666666')
        }
      }

      // Event Log Toggle
      Button(this.showEventLog ? '隐藏事件日志' : '显示事件日志')
        .type(ButtonType.Normal)
        .fontSize(14)
        .height(36)
        .backgroundColor('#607D8B')
        .fontColor(Color.White)
        .onClick(() => {
          this.showEventLog = !this.showEventLog;
        })
    }
  }

  @Builder
  buildActionButtons() {
    Column({ space: 12 }) {
      if (this.showEventLog && this.eventLog.length > 0) {
        // Event Log Display
        Column({ space: 8 }) {
          Text('事件日志')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Scroll() {
            Column({ space: 4 }) {
              ForEach(this.eventLog.slice(-10), (log: string, index: number) => {
                Text(`[${this.eventLog.length - 10 + index + 1}] ${log}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .width('100%')
              })
            }
            .width('100%')
          }
          .height(120)
          .backgroundColor('#F5F5F5')
          .borderRadius(4)
          .padding(8)
          .width('100%')
        }
      }

      // Code Examples Section
      Column({ space: 8 }) {
        Text('代码示例')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Text(`
// 自定义 InfoWindow 适配器示例 (ComponentContent)
import { ComponentContent, UIContext } from '@kit.ArkUI';

map.setInfoWindowAdapter({
  getInfoWindow: (marker: Marker, uiContext: UIContext) => {
    const content = new ComponentContent(uiContext);
    content.update(() => {
      Column() {
        Text(marker.getTitle())
        Text(marker.getSnippet())
      }
      .padding(12)
      .backgroundColor('#2196F3')
      .borderRadius(8)
    });
    return content;
  }
});

// 监听 InfoWindow 事件
map.setOnInfoWindowClickListener({
  onInfoWindowClick: (marker: Marker) => {
    console.log('InfoWindow clicked:', marker.getTitle());
  }
});
        `.trim())
          .fontSize(10)
          .fontColor('#333333')
          .backgroundColor('#F8F8F8')
          .borderRadius(4)
          .padding(8)
          .width('100%')
          .copyOption(CopyOptions.InApp)
      }

      // Best Practices
      Column({ space: 8 }) {
        Text('最佳实践')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Column({ space: 4 }) {
          Text('• 使用 ComponentContent 创建动态 InfoWindow')
            .fontSize(12)
            .fontColor('#666666')

          Text('• 在 content.update() 中构建自定义 UI')
            .fontSize(12)
            .fontColor('#666666')

          Text('• 避免在构建器中使用重量级操作')
            .fontSize(12)
            .fontColor('#666666')

          Text('• 合理使用动画提升用户体验')
            .fontSize(12)
            .fontColor('#666666')

          Text('• 及时清理不需要的事件监听器')
            .fontSize(12)
            .fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .padding(12)
  }

  // Initialize custom marker data with rich content
  private initializeCustomMarkerData(): void {
    const locations: TestLocation[] = [
      {
        id: 'restaurant1',
        title: '全聚德烤鸭店',
        description: '北京著名的烤鸭老字号，历史悠久',
        category: 'restaurant',
        rating: 4.5,
        price: '¥¥¥',
        tags: ['烤鸭', '传统', '老字号']
      },
      {
        id: 'hotel1',
        title: '北京饭店',
        description: '五星级酒店，位于市中心黄金地段',
        category: 'hotel',
        rating: 4.8,
        price: '¥¥¥¥',
        tags: ['五星级', '市中心', '商务']
      },
      {
        id: 'attraction1',
        title: '故宫博物院',
        description: '中国古代皇家宫殿，世界文化遗产',
        category: 'attraction',
        rating: 4.9,
        price: '¥¥',
        tags: ['历史', '文化', '必游']
      },
      {
        id: 'shopping1',
        title: '王府井大街',
        description: '北京著名商业街，购物天堂',
        category: 'shopping',
        price: '¥¥',
        tags: ['购物', '美食', '步行街']
      }
    ];

    locations.forEach((data: TestLocation) => {
      this.customMarkerData.set(data.id, data as CustomMarkerData);
    });
  }

  // Setup markers on the map
  private async setupMarkers(map: MapLibreMap): Promise<void> {
    const markerPositions: MarkerPosition[] = [
      { id: 'restaurant1', latLng: TEST_LOCATIONS.beijing },
      { id: 'hotel1', latLng: new LatLng(39.915, 116.405) },
      { id: 'attraction1', latLng: new LatLng(39.916, 116.397) },
      { id: 'shopping1', latLng: new LatLng(39.913, 116.407) }
    ];

    const options: MarkerOptions[] = markerPositions.map((pos: MarkerPosition) => {
      const data = this.customMarkerData.get(pos.id);
      if (!data) {
        return new MarkerOptions();
      }
      return new MarkerOptions()
        .position(pos.latLng)
        .title(data.title)
        .snippet(`${data.category} - 点击查看详情`);
    });

    this.markers = await map.addMarkersBatch(options);
  }

  // Setup custom InfoWindow adapter with multiple builder types using ComponentContent
  private setupCustomAdapter(map: MapLibreMap): void {
    class CustomInfoWindowBuilderAdapter implements InfoWindowAdapter {
      page: CustomInfoWindowTestPage;

      constructor(page: CustomInfoWindowTestPage) {
        this.page = page;
      }

      getInfoWindow(marker: Marker, uiContext: UIContext): ComponentContent | null {
        const title = marker.getTitle();
        const markerData = title ?
          Array.from(this.page.customMarkerData.values()).find((d: CustomMarkerData) => d.title === title) : null;

        if (!markerData) {
          return null; // Use default InfoWindow for unknown markers
        }

        // Create ComponentContent that uses the pre-defined @Builder functions
        const content = new ComponentContent(uiContext);
        content.update(() => {
          this.page.renderCustomInfoWindow(marker, markerData);
        });
        return content;
      }
    }

    map.setInfoWindowAdapter(new CustomInfoWindowBuilderAdapter(this));
  }

  // Setup event listeners for InfoWindow interactions
  private setupEventListeners(map: MapLibreMap): void {
    // InfoWindow click listener
    class InfoWindowClickHandler implements OnInfoWindowClickListener {
      page: CustomInfoWindowTestPage;

      constructor(page: CustomInfoWindowTestPage) {
        this.page = page;
      }

      onInfoWindowClick(marker: Marker): void {
        this.page.logEvent(`InfoWindow 点击: ${marker.getTitle()}`);

        // For interactive builder type, show additional actions
        if (this.page.currentBuilderType === 'interactive') {
          this.page.showInteractiveActions(marker);
        }
      }
    }

    // InfoWindow close listener
    class InfoWindowCloseHandler implements OnInfoWindowCloseListener {
      page: CustomInfoWindowTestPage;

      constructor(page: CustomInfoWindowTestPage) {
        this.page = page;
      }

      onInfoWindowClose(marker: Marker): void {
        this.page.logEvent(`InfoWindow 关闭: ${marker.getTitle()}`);
      }
    }

    map.setOnInfoWindowClickListener(new InfoWindowClickHandler(this));
    map.setOnInfoWindowCloseListener(new InfoWindowCloseHandler(this));
  }

  // Main renderer that delegates to specific builder types
  @Builder
  private renderCustomInfoWindow(marker: Marker, data: CustomMarkerData) {
    if (this.currentBuilderType === 'card') {
      this.renderCardStyleInfoWindow(marker, data);
    } else if (this.currentBuilderType === 'bubble') {
      this.renderBubbleStyleInfoWindow(marker, data);
    } else if (this.currentBuilderType === 'minimal') {
      this.renderMinimalStyleInfoWindow(marker, data);
    } else if (this.currentBuilderType === 'detailed') {
      this.renderDetailedStyleInfoWindow(marker, data);
    } else if (this.currentBuilderType === 'interactive') {
      this.renderInteractiveStyleInfoWindow(marker, data);
    } else {
      this.renderCardStyleInfoWindow(marker, data);
    }
  }

  // Card Style Builder
  @Builder
  private renderCardStyleInfoWindow(marker: Marker, data: CustomMarkerData) {
    Column({ space: 8 }) {
      // Header with category icon and title
      Row({ space: 8 }) {
        Text(this.getCategoryIcon(data.category))
          .fontSize(24)

        Column({ space: 2 }) {
          Text(data.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.getCategoryName(data.category))
            .fontSize(12)
            .fontColor('#E0E0E0')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }

      // Description
      Text(data.description)
        .fontSize(14)
        .fontColor('#F0F0F0')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // Footer with price and rating
      Row({ space: 12 }) {
        if (data.price) {
          Text(data.price)
            .fontSize(12)
            .fontColor('#FFE082')
        }

        if (data.rating) {
          Row({ space: 4 }) {
            Text('⭐')
              .fontSize(12)

            Text(data.rating.toFixed(1))
              .fontSize(12)
              .fontColor('#FFE082')
          }
        }

        Blank()

        Text('点击查看更多')
          .fontSize(12)
          .fontColor('#B3E5FC')
          .opacity(0.8)
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(this.getCategoryColor(data.category))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.3)',
      offsetX: 0,
      offsetY: 4
    })
    .animation({
      duration: this.animationEnabled ? 300 : 0,
      curve: Curve.EaseInOut
    })
  }

  // Bubble Style Builder
  @Builder
  private renderBubbleStyleInfoWindow(marker: Marker, data: CustomMarkerData) {
    Column({ space: 6 }) {
      // Triangle pointer at the top
      Row() {
        Blank()
        Polygon({ width: 20, height: 10 })
          .points([[10, 0], [0, 10], [20, 10]])
          .fill(this.getCategoryColor(data.category))
        Blank()
      }
      .margin({ bottom: -2 })

      // Main content
      Column({ space: 8 }) {
        Text(this.getCategoryIcon(data.category) + ' ' + data.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)

        if (data.tags && data.tags.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
            ForEach(data.tags.slice(0, 3), (tag: string) => {
              Text(tag)
                .fontSize(10)
                .fontColor(this.getCategoryColor(data.category))
                .backgroundColor('#FFFFFF')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(8)
                .margin({ right: 4, bottom: 2 })
            })
          }
        }
      }
      .padding(12)
      .backgroundColor(this.getCategoryColor(data.category))
      .borderRadius(16)
    }
    .shadow({
      radius: 6,
      color: 'rgba(0, 0, 0, 0.25)',
      offsetX: 0,
      offsetY: 3
    })
    .animation({
      duration: this.animationEnabled ? 250 : 0,
      curve: Curve.EaseOut
    })
  }

  // Minimal Style Builder
  @Builder
  private renderMinimalStyleInfoWindow(marker: Marker, data: CustomMarkerData) {
    Row({ space: 8 }) {
      Text(this.getCategoryIcon(data.category))
        .fontSize(20)

      Column({ space: 2 }) {
        Text(data.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (data.rating) {
          Text(`⭐ ${data.rating.toFixed(1)}`)
            .fontSize(10)
            .fontColor('#FFE082')
        }
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#333333')
    .borderRadius(20)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: 2
    })
    .animation({
      duration: this.animationEnabled ? 200 : 0,
      curve: Curve.EaseInOut
    })
  }

  // Detailed Style Builder
  @Builder
  private renderDetailedStyleInfoWindow(marker: Marker, data: CustomMarkerData) {
    Column({ space: 12 }) {
      // Header
      Row({ space: 8 }) {
        Column({ space: 4 }) {
          Text(data.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: 8 }) {
            Text(this.getCategoryName(data.category))
              .fontSize(12)
              .fontColor(this.getCategoryColor(data.category))
              .backgroundColor(this.getCategoryColor(data.category) + '20')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)

            if (data.rating) {
              Row({ space: 2 }) {
                Text('⭐')
                  .fontSize(12)

                Text(data.rating.toFixed(1))
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
              }
            }
          }
        }
        .layoutWeight(1)

        if (data.price) {
          Text(data.price)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
        }
      }
      .width('100%')

      // Description
      Text(data.description)
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(20)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // Tags
      if (data.tags && data.tags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(data.tags, (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor('#757575')
              .backgroundColor('#F5F5F5')
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .borderRadius(6)
              .margin({ right: 6, bottom: 4 })
          })
        }
        .width('100%')
      }

      // Action hint
      Row() {
        Blank()
        Text('点击查看详情 →')
          .fontSize(12)
          .fontColor('#2196F3')
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E0E0E0' })
    .shadow({
      radius: 12,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 6
    })
    .onAppear(() => {
      // Notify size change when the window appears
      this.notifySizeChange(280, 180);
    })
    .animation({
      duration: this.animationEnabled ? 350 : 0,
      curve: Curve.EaseOut
    })
  }

  // Interactive Style Builder with buttons
  @Builder
  private renderInteractiveStyleInfoWindow(marker: Marker, data: CustomMarkerData) {
    Column({ space: 12 }) {
      // Content area
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text(this.getCategoryIcon(data.category))
            .fontSize(24)

          Column({ space: 2 }) {
            Text(data.title)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (data.rating) {
              Row({ space: 4 }) {
                ForEach(Array(5).fill(0), (_: ESObject, i: number) => {
                  Text('⭐')
                    .fontSize(10)
                    .fontColor(i < Math.floor(data.rating!) ? '#FFD700' : '#666666')
                })

                Text(`(${data.rating.toFixed(1)})`)
                  .fontSize(10)
                  .fontColor('#E0E0E0')
                  .margin({ left: 4 })
              }
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }

        Text(data.description)
          .fontSize(13)
          .fontColor('#F0F0F0')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }

      // Interactive buttons
      Row({ space: 8 }) {
        Button('导航')
          .type(ButtonType.Normal)
          .fontSize(12)
          .height(32)
          .backgroundColor('#4CAF50')
          .fontColor(Color.White)
          .onClick(() => {
            this.logEvent(`导航到: ${data.title}`);
            showToast(`开始导航到 ${data.title}`);
          })

        Button('收藏')
          .type(ButtonType.Normal)
          .fontSize(12)
          .height(32)
          .backgroundColor('#FF9800')
          .fontColor(Color.White)
          .onClick(() => {
            this.logEvent(`收藏: ${data.title}`);
            showToast(`已收藏 ${data.title}`);
          })

        Button('分享')
          .type(ButtonType.Normal)
          .fontSize(12)
          .height(32)
          .backgroundColor('#2196F3')
          .fontColor(Color.White)
          .onClick(() => {
            this.logEvent(`分享: ${data.title}`);
            showToast(`分享 ${data.title}`);
          })
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(this.getCategoryColor(data.category))
    .borderRadius(12)
    .shadow({
      radius: 10,
      color: 'rgba(0, 0, 0, 0.35)',
      offsetX: 0,
      offsetY: 5
    })
    .onAppear(() => {
      // Notify size change for interactive windows
      this.notifySizeChange(300, 160);
    })
    .animation({
      duration: this.animationEnabled ? 400 : 0,
      curve: Curve.EaseOut
    })
  }

  // Switch builder type at runtime
  private switchBuilderType(type: CustomBuilderType): void {
    this.currentBuilderType = type;
    this.logEvent(`切换构建器类型: ${this.getBuilderTypeName(type)}`);

    // Refresh all visible InfoWindows
    if (this.mapController && this.markers.length > 0) {
      this.markers.forEach((marker: Marker) => {
        if (marker.isInfoWindowShown()) {
          this.mapController!.hideInfoWindow(marker);
          setTimeout(() => {
            this.mapController!.showInfoWindow(marker);
          }, 100);
        }
      });
    }

    showToast(`已切换到${this.getBuilderTypeName(type)}`);
  }

  // Show interactive actions for marker
  private showInteractiveActions(marker: Marker): void {
    const title = marker.getTitle();
    if (title) {
      const actions = [
        '查看详情',
        '添加到行程',
        '查看附近',
        '用户评价'
      ];

      // For demo purposes, just show a toast
      // In a real app, you could show a custom action sheet or dialog
      showToast(`可用操作: ${actions.join(', ')}`);
    }
  }

  // Clear all InfoWindows
  private clearAllInfoWindows(): void {
    if (this.mapController && this.markers.length > 0) {
      this.markers.forEach((marker: Marker) => {
        if (marker.isInfoWindowShown()) {
          this.mapController!.hideInfoWindow(marker);
        }
      });
      this.logEvent('清除所有 InfoWindow');
      showToast('已清除所有 InfoWindow');
    }
  }

  // Log events for debugging
  private logEvent(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    this.eventLog.push(`[${timestamp}] ${message}`);

    // Keep only last 50 events
    if (this.eventLog.length > 50) {
      this.eventLog = this.eventLog.slice(-50);
    }
  }

  // Notify size change (for layout optimization)
  private notifySizeChange(width: number, height: number): void {
    this.lastWindowSize = { width: width, height: height };
    this.logEvent(`InfoWindow 尺寸变化: ${width}x${height}`);
  }

  // Helper methods
  private getCategoryIcon(category: CategoryType): string {
    const icons: Record<CategoryType, string> = {
      "restaurant": '🍽️',
      "hotel": '🏨',
      "attraction": '🎯',
      "shopping": '🛍️'
    };
    return icons[category];
  }

  private getCategoryName(category: CategoryType): string {
    const names: Record<CategoryType, string> = {
      "restaurant": '餐厅',
      "hotel": '酒店',
      "attraction": '景点',
      "shopping": '购物'
    };
    return names[category];
  }

  private getCategoryColor(category: CategoryType): string {
    return this.CATEGORY_COLORS[category];
  }

  private getBuilderTypeName(type: CustomBuilderType): string {
    return this.BUILDER_TYPE_NAMES[type];
  }
}

// Define interfaces used in the struct
interface WindowSize {
  width: number;
  height: number;
}

interface MarkerPosition {
  id: string;
  latLng: LatLng;
}

interface TestLocation {
  id: string;
  title: string;
  description: string;
  category: CategoryType;
  rating?: number;
  price?: string;
  tags?: string[];
}
