/**
 * Real Time GeoJson Test Page
 * 实时 GeoJSON 数据更新测试
 * 参考 Android: RealTimeGeoJsonActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { CircleLayer, GeoJson, GeoJsonSource, LatLng, MapLibreMap, MapView, ScreenPoint } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct RealTimeGeoJsonTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  private updateTimer: number | null = null;
  @State private isUpdating: boolean = false;
  @State private updateCount: number = 0;
  private currentLat: number = 39.9;
  private currentLng: number = 116.4;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Real Time GeoJSON',
        description: '实时数据流更新',
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
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 6);
        this.initRealtimeLayer(map);
      }
    })
  }

  @Builder
  buildActionButtons() {
    Scroll(this.scroller) {
      Column({ space: 8 }) {
        Text(`更新${this.isUpdating ? '中' : '已停止'}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text(`更新次数: ${this.updateCount}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
        
        Button(this.isUpdating ? '停止更新' : '开始更新')
          .width('100%')
          .onClick(() => {
            if (this.isUpdating) {
              this.stopRealTimeUpdate();
            } else {
              this.startRealTimeUpdate();
            }
          })
      }
      .width('100%')
      .padding(8)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  }
  
  private initRealtimeLayer(map: MapLibreMap): void {
    try {
      const geojson = GeoJson.featureCollection([
        GeoJson.pointFeature([this.currentLng, this.currentLat])
      ]);
      
      const source = new GeoJsonSource('realtime-source');
      source.setGeoJson(geojson);
      map.addSource(source);
      
      const layer = new CircleLayer('realtime-layer', 'realtime-source');
      layer.setCircleRadius(15);
      layer.setCircleColor('#FF5722');
      layer.setCircleOpacity(0.9);
      layer.setCircleStrokeWidth(3);
      layer.setCircleStrokeColor('#FFFFFF');
      map.addLayer(layer);
    } catch (error) {
      console.error(`初始化失败: ${error}`);
    }
  }
  
  private startRealTimeUpdate(): void {
    if (!this.mapController) return;
    
    this.isUpdating = true;
    this.updateTimer = setInterval(() => {
      // 模拟位置移动
      this.currentLat += (Math.random() - 0.5) * 0.01;
      this.currentLng += (Math.random() - 0.5) * 0.01;
      
      const geojson = GeoJson.featureCollection([
        GeoJson.pointFeature([this.currentLng, this.currentLat])
      ]);
      
      try {
        const source = this.mapController?.getSource('realtime-source');
        if (source) {
          (source as GeoJsonSource).setGeoJson(geojson);
          this.updateCount++;
        }
      } catch (error) {
        console.error(`更新失败: ${error}`);
      }
    }, 100);
    
    showToast('实时更新已开始');
  }
  
  private stopRealTimeUpdate(): void {
    if (this.updateTimer !== null) {
      clearInterval(this.updateTimer);
      this.updateTimer = null;
    }
    this.isUpdating = false;
    showToast('实时更新已停止');
  }
  
  aboutToDisappear() {
    this.stopRealTimeUpdate();
  }
}

