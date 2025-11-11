/**
 * Declarative API Test Page  
 * 声明式 API 测试页面
 */
import { router } from '@kit.ArkUI';
import {
  MapView,
  MapLibreMap,
  DEFAULT_STYLE_URLS,
  MarkerComponent,
  GeoJsonSourceComponent,
  SymbolLayerComponent,
  CircleLayerComponent,
  LineLayerComponent
} from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct DeclarativeAPITestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;

  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    showToast('地图加载成功 - 声明式 API');
  };

  private goBack = (): void => {
    router.back();
  };

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('< 返回')
          .onClick(() => this.goBack())
          .backgroundColor(Color.Transparent)
          .fontColor(Color.White)
          .fontSize(16)

        Text('声明式 API 演示')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('')
          .width(60)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#2196F3')
      .padding({ left: 10, right: 10 })
      .justifyContent(FlexAlign.SpaceBetween)

      // 地图容器
      Stack() {
        MapView({
          styleUrl: DEFAULT_STYLE_URLS.streets,
          initialLatitude: 39.9,
          initialLongitude: 116.4,
          initialZoom: 11,
          onMapReady: this.onMapReady
        }) {
          MarkerComponent({
            markerPosition: { latitude: 39.9042, longitude: 116.4074 },
            markerTitle: 'Beijing',
            markerDraggable: true
          })

          GeoJsonSourceComponent({
            sourceId: 'poi-source',
            geojson: '{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[116.4074,39.9142]},"properties":{"name":"北京大学"}}]}',
            sourceOptions: {}
          }) {
            CircleLayerComponent({
              layerId: 'poi-circle',
              circleRadius: 8,
              circleColor: '#FF5722',
              circleStrokeWidth: 2
            })
          }
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .layoutWeight(1)

      // 底部信息
      Row() {
        Text('Declarative API Demo')
          .fontSize(12)
          .fontColor('#999999')
        
        Text(`状态: ${this.isMapReady ? '已就绪' : '加载中'}`)
          .fontSize(12)
          .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
          .margin({ left: 20 })
      }
      .width('100%')
      .height(40)
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
