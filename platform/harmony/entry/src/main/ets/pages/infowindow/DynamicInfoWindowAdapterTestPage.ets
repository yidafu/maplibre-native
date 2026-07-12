import { InfoWindowAdapter, LatLng, MapLibreMap, MarkerOptions, MapView, OnInfoWindowClickListener, Marker } from 'maplibre_harmony';
import { ComponentContent, UIContext } from '@kit.ArkUI';
/**
 * Dynamic Info Window Adapter Activity
 * Dynamic custom InfoWindow test using ComponentContent
 * References: Android - DynamicInfoWindowAdapterActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

/**
 * Data passed to the dynamic InfoWindow @Builder via ComponentContent.
 */
interface DynamicInfoWindowData {
  title: string;
  updateCount: number;
  backgroundColor: string;
}

/**
 * @Builder for the dynamic InfoWindow UI.
 * Receives DynamicInfoWindowData via ComponentContent's WrappedBuilder parameter.
 */
@Builder
function dynamicInfoWindowBuilder(params: DynamicInfoWindowData) {
  Column({ space: 6 }) {
    Text(`${params.title} [${params.updateCount}]`)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor('#FFFFFF')
      .maxLines(1)

    Text(`更新次数: ${params.updateCount}`)
      .fontSize(12)
      .fontColor('#E0E0E0')

    Text('点击窗口更改颜色')
      .fontSize(10)
      .fontColor('#B3E5FC')
      .margin({ top: 4 })
  }
  .padding(12)
  .backgroundColor(params.backgroundColor)
  .borderRadius(8)
  .shadow({
    radius: 6,
    color: 'rgba(0, 0, 0, 0.25)',
    offsetX: 0,
    offsetY: 2
  })
}

@Entry
@Component
struct DynamicInfoWindowAdapterTestPage {
  private mapController: MapLibreMap | null = null;
  @State private updateCount: number = 0;

  build() {
    Column() {
    TestPageLayout({
      title: 'Dynamic InfoWindow',
      description: '动态更新信息窗口内容 (ComponentContent)',
      showActionBar: true,
      mapContent: (): void => this.buildMapContent(),
      actionButtons: (): void => this.buildActionButtons()
    })
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      onMapReady: async (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 12);

        // Add marker
        await map.addMarker(new MarkerOptions()
          .position(TEST_LOCATIONS.beijing)
          .title('动态窗口')
          .snippet('点击窗口更新内容')
        );

        this.setupAdapter(map);
        this.setupListeners(map);
      }
    })
  }

  private setupAdapter(map: MapLibreMap): void {
    class DynamicAdapter implements InfoWindowAdapter {
      page: DynamicInfoWindowAdapterTestPage;

      constructor(page: DynamicInfoWindowAdapterTestPage) {
        this.page = page;
      }

      getInfoWindow(marker: Marker, uiContext: UIContext): ComponentContent<Object> | null {
        const colors = ['#6200EE', '#03DAC5', '#BB86FC', '#018786']
        const randomColor = colors[this.page.updateCount % colors.length]

        const data: DynamicInfoWindowData = {
          title: marker.getTitle() || '',
          updateCount: this.page.updateCount,
          backgroundColor: randomColor,
        };

        const content = new ComponentContent<DynamicInfoWindowData>(
          uiContext,
          wrapBuilder<[DynamicInfoWindowData]>(dynamicInfoWindowBuilder),
          data
        );
        return content;
      }
    }

    map.setInfoWindowAdapter(new DynamicAdapter(this));
  }

  private setupListeners(map: MapLibreMap): void {
    class InfoWindowClickListener implements OnInfoWindowClickListener {
      page: DynamicInfoWindowAdapterTestPage;
      map: MapLibreMap;

      constructor(page: DynamicInfoWindowAdapterTestPage, map: MapLibreMap) {
        this.page = page;
        this.map = map;
      }

      onInfoWindowClick(marker: Marker): boolean {
        this.page.updateCount++;
        // Re-show InfoWindow to refresh content with new ComponentContent
        this.map.hideInfoWindow(marker);
        setTimeout(() => {
          this.map.showInfoWindow(marker);
        }, 100);
        showToast(`InfoWindow 已更新 ${this.page.updateCount} 次`);
        return true;
      }
    }

    map.setOnInfoWindowClickListener(new InfoWindowClickListener(this, map));
  }

  @Builder
  buildActionButtons() {
    Button('重置计数')
      .onClick(() => {
        this.updateCount = 0;
        showToast('计数已重置');
      })
  }
}
