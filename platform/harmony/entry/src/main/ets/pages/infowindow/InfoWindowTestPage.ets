import { ComponentContent, UIContext } from '@kit.ArkUI';
import { InfoWindowAdapter, LatLng, MapLibreMap, Marker, MarkerOptions, MapView, OnInfoWindowClickListener, OnMarkerClickListener } from 'maplibre_harmony';
/**
 * Info Window Activity
 * 标准 & 自定义 InfoWindow 测试
 * 参考 Android: InfoWindowActivity
 *
 * Features:
 * - Standard InfoWindow with title/snippet (default)
 * - Custom InfoWindow via InfoWindowAdapter + ComponentContent
 * - Toggle between standard and custom modes at runtime
 * - Per-marker custom content with distinct styles
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast } from '../common/TestUtils';

/**
 * Params for the custom InfoWindow @Builder.
 */
interface CustomInfoWindowParams {
  title: string;
  subtitle: string;
  accentColor: ResourceColor;
  badgeText: string;
  markerIndex: number;
  onClose?: () => void;
}

/**
 * Color palettes for custom InfoWindows.
 */
const CUSTOM_COLORS: ResourceColor[] = [
  '#FF6B6B', // 北京 - 红色
  '#4ECDC4', // 上海 - 青色
  '#45B7D1', // 广州 - 蓝色
  '#96CEB4', // 深圳 - 绿色
  '#FFB74D', // 成都 - 橙色
  '#CE93D8', // 杭州 - 紫色
];

/**
 * Coordinate + metadata for each marker.
 */
interface TestMarkerInfo {
  name: string;
  latLng: LatLng;
  snippet: string;
}

const CITIES: TestMarkerInfo[] = [
  { name: '北京', latLng: TEST_LOCATIONS.beijing, snippet: '中国首都' },
  { name: '上海', latLng: TEST_LOCATIONS.shanghai, snippet: '经济中心' },
  { name: '广州', latLng: TEST_LOCATIONS.guangzhou, snippet: '南方门户' },
  { name: '深圳', latLng: TEST_LOCATIONS.shenzhen, snippet: '科技之都' },
  { name: '成都', latLng: new LatLng(30.572, 104.066), snippet: '天府之国' },
  { name: '杭州', latLng: new LatLng(30.274, 120.155), snippet: '人间天堂' },
];

/**
 * @Builder for the custom InfoWindow UI.
 *
 * Renders a rich card-style layout with an accent-color header,
 * subtitle, and a close button.
 *
 * Invoked via wrapBuilder<[CustomInfoWindowParams]> and passed
 * to ComponentContent so it participates in the ViewAnnotation pipeline.
 */
@Builder
function customInfoWindowBuilder(params: CustomInfoWindowParams) {
  Column({ space: 0 }) {
    // ── Header bar with accent colour ──
    Row({ space: 8 }) {
      Text(params.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      if (params.badgeText.length > 0) {
        Text(params.badgeText)
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.9)')
          .backgroundColor('rgba(255,255,255,0.25)')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(10)
      }

      Text('✕')
        .fontSize(16)
        .fontColor('rgba(255,255,255,0.8)')
        .width(24)
        .height(24)
        .textAlign(TextAlign.Center)
        .borderRadius(12)
        .backgroundColor('rgba(0,0,0,0.15)')
        .onClick(() => {
          if (params.onClose) {
            params.onClose();
          }
        })
    }
    .padding({ left: 14, right: 10, top: 10, bottom: 10 })
    .backgroundColor(params.accentColor)
    .width('100%')

    // ── Body ──
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        Text('📍')
          .fontSize(16)

        Text(params.subtitle)
          .fontSize(14)
          .fontColor('#555555')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(VerticalAlign.Center)

      Text(`#${params.markerIndex} 自定义组件`)
        .fontSize(11)
        .fontColor('#999999')
    }
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .width('100%')

    // ── Bottom arrow ──
    Row() {
      Polygon()
        .points([[0, 0], [10, 10], [20, 0]])
        .fill(params.accentColor)
        .width(20)
        .height(10)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
  .width(220)
  .backgroundColor(Color.White)
  .borderRadius({ topLeft: 10, topRight: 10 })
  .shadow({
    radius: 10,
    color: 'rgba(0, 0, 0, 0.25)',
    offsetX: 0,
    offsetY: 4
  })
  .onClick(() => {
    showToast(`点击 InfoWindow: ${params.title}`);
  })
}

@Entry
@Component
struct InfoWindowTestPage {
  private mapController: MapLibreMap | null = null;
  @State private infoWindowCount: number = 0;
  @State private useCustomInfoWindow: boolean = false;
  private markers: Marker[] = [];
  private adapter: CustomInfoWindowAdapterImpl | null = null;

  aboutToDisappear(): void {
    // Clean up adapter reference
    this.adapter = null;
    this.markers = [];
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'InfoWindow Test',
        description: '标准 & 自定义信息窗口',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
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
      initialZoom: 5,
      onMapReady: async (map: MapLibreMap) => {
        console.info('[InfoWindowTest] onMapReady called');
        this.mapController = map;
        map.jumpTo(0, 35, 105, 0, 4);

        await this.addMarkersWithInfoWindow(map);
        this.setupListeners(map);

        console.info('[InfoWindowTest] Setup complete');
      }
    })
  }

  private async addMarkersWithInfoWindow(map: MapLibreMap): Promise<void> {
    const options: MarkerOptions[] = CITIES.map(city =>
      new MarkerOptions()
        .position(city.latLng)
        .title(city.name)
        .snippet(city.snippet)
    );

    this.markers = await map.addMarkersBatch(options);
    console.info(`[InfoWindowTest] Added ${this.markers.length} markers`);
  }

  private setupListeners(map: MapLibreMap): void {
    // 标记点击监听（显示 InfoWindow）
    class MarkerClickListenerImpl implements OnMarkerClickListener {
      onMarkerClick(marker: Marker): boolean {
        console.info(`[InfoWindowTest] Marker clicked: ${marker.getTitle()}`);
        return false; // false = default behavior: select + show InfoWindow
      }
    }

    // InfoWindow 点击监听
    class InfoWindowClickListenerImpl implements OnInfoWindowClickListener {
      component: InfoWindowTestPage;

      constructor(component: InfoWindowTestPage) {
        this.component = component;
      }

      onInfoWindowClick(marker: Marker): boolean {
        this.component.infoWindowCount++;
        showToast(`InfoWindow 被点击 ${this.component.infoWindowCount} 次`);
        return true;
      }
    }

    const markerClickListener = new MarkerClickListenerImpl();
    const infoWindowClickListener = new InfoWindowClickListenerImpl(this);

    map.setOnMarkerClickListener(markerClickListener);
    map.setOnInfoWindowClickListener(infoWindowClickListener);
  }

  /**
   * Apply or remove the custom InfoWindow adapter based on the current toggle.
   *
   * NOTE: InfoWindows are cached per marker ID by InfoWindowManager. Markers
   * that were already shown in a previous mode retain their old ComponentContent
   * until the page is reloaded. This is a known limitation of the current SDK:
   * the adapter is only consulted when an InfoWindow is first created for a
   * given marker ID. Switching the adapter after creation does NOT
   * retroactively update already-cached InfoWindows.
   *
   * Click on a marker that hasn't been shown yet in this session to see the
   * new mode in action.
   */
  private applyCustomAdapter(): void {
    if (!this.mapController) {
      return;
    }

    // Close all visible InfoWindows first
    this.mapController.deselectMarkers();

    if (this.useCustomInfoWindow) {
      if (!this.adapter) {
        this.adapter = new CustomInfoWindowAdapterImpl(this.markers, this.mapController);
      }
      this.mapController.setInfoWindowAdapter(this.adapter);
      showToast('自定义 InfoWindow 模式 - 点击标记查看');
    } else {
      this.mapController.setInfoWindowAdapter(null);
      showToast('标准 InfoWindow 模式 - 点击标记查看');
    }
  }

  @Builder
  buildActionButtons() {
    Button(this.useCustomInfoWindow ? '标准模式' : '自定义模式')
      .type(ButtonType.Normal)
      .fontSize(14)
      .backgroundColor(this.useCustomInfoWindow ? '#4CAF50' : '#2196F3')
      .fontColor(Color.White)
      .onClick(() => {
        this.useCustomInfoWindow = !this.useCustomInfoWindow;
        this.applyCustomAdapter();
      })

    Button('关闭所有窗口')
      .type(ButtonType.Normal)
      .fontSize(14)
      .onClick(() => {
        if (this.mapController) {
          this.mapController.deselectMarkers();
          showToast('已关闭所有 InfoWindow');
        }
      })

    Button('重置计数')
      .type(ButtonType.Normal)
      .fontSize(14)
      .onClick(() => {
        this.infoWindowCount = 0;
        showToast('计数已重置');
      })
  }
}

/**
 * InfoWindowAdapter implementation that returns a custom ComponentContent
 * per marker, differentiated by the marker's index in the markers array.
 *
 * Each marker receives a distinct accent colour derived from CUSTOM_COLORS.
 */
class CustomInfoWindowAdapterImpl implements InfoWindowAdapter {
  private markers: Marker[];
  private mapController: MapLibreMap | null;

  constructor(markers: Marker[], mapController: MapLibreMap | null) {
    this.markers = markers;
    this.mapController = mapController;
  }

  getInfoWindow(marker: Marker, uiContext: UIContext): ComponentContent<Object> | null {
    const title = marker.getTitle() || '';
    const snippet = marker.getSnippet() || '';

    // Determine marker index (for colour selection)
    const index = this.markers.findIndex((m: Marker) => m.getId() === marker.getId());
    const colorIndex = index >= 0 ? index % CUSTOM_COLORS.length : 0;

    // Build badge text from the marker's position in the list
    const badgeText = index >= 0 ? `#${index + 1}` : '';

    const params: CustomInfoWindowParams = {
      title: title,
      subtitle: snippet,
      accentColor: CUSTOM_COLORS[colorIndex],
      badgeText: badgeText,
      markerIndex: index >= 0 ? index + 1 : 0,
      onClose: () => {
        if (this.mapController) {
          this.mapController.deselectMarkers();
        }
      },
    };

    const content = new ComponentContent<CustomInfoWindowParams>(
      uiContext,
      wrapBuilder<[CustomInfoWindowParams]>(customInfoWindowBuilder),
      params
    );

    return content;
  }
}
