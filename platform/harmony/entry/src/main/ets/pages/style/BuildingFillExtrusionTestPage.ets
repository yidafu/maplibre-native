/**
 * Building Fill Extrusion Test Page
 * 建筑物填充拉伸测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct BuildingFillExtrusionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private extrusionHeight: number = 50;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(45, 39.9042, 116.4074, 60, 15);
  };
  
  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
    })
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('3D建筑拉伸')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Row() {
        Text('高度:')
          .fontSize(14)
          .width(60)
        Slider({
          value: this.extrusionHeight,
          min: 10,
          max: 200,
          step: 10
        })
        .layoutWeight(1)
        .onChange((value: number) => {
          this.extrusionHeight = value;
        })
        Text(`${this.extrusionHeight}m`)
          .fontSize(14)
          .width(60)
      }
      
      Text('TODO: 实现FillExtrusionLayer')
        .fontSize(12)
        .fontColor('#FF9800')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Building Fill Extrusion',
        description: '建筑物拉伸',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


