/**
 * Dynamic Marker Change Test Page
 * 动态Marker变化测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, Marker, MarkerOptions, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct DynamicMarkerChangeTestPage {
  private mapController: MapLibreMap | null = null;
  private marker: Marker | null = null;
  @State private markerPosition: LatLng = LatLng.create(39.9042, 116.4074);
  @State private markerTitle: string = '动态Marker';
  @State private changeCount: number = 0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.bright);
    map.jumpTo(0, 39.9042, 116.4074, 0, 12);
    
    await this.addMarker();
  };
  
  private addMarker = async (): Promise<void> => {
    if (!this.mapController) return;
    
    const markerOptions = new MarkerOptions()
      .position(this.markerPosition)
      .title(this.markerTitle)
      .snippet(`变更次数: ${this.changeCount}`);
    
    this.marker = await this.mapController.addMarker(markerOptions);
    showToast('Marker已添加');
  };
  
  private changePosition = (): void => {
    if (!this.marker) return;
    
    const newLat = 39.85 + Math.random() * 0.1;
    const newLng = 116.35 + Math.random() * 0.1;
    this.markerPosition = LatLng.create(newLat, newLng);
    
    this.marker.setPosition(this.markerPosition);
    this.changeCount++;
    this.marker.setSnippet(`变更次数: ${this.changeCount}`);
    
    if (this.mapController) {
      this.mapController.easeTo({ center: this.markerPosition }, 500);
    }
    
    showToast('位置已更新');
  };
  
  private changeTitle = (): void => {
    if (!this.marker) return;
    
    const titles = ['Marker A', 'Marker B', 'Marker C', 'Marker D']
    this.markerTitle = titles[Math.floor(Math.random() * titles.length)]
    this.marker.setTitle(this.markerTitle);
    this.changeCount++;
    this.marker.setSnippet(`变更次数: ${this.changeCount}`);
    
    showToast(`标题已更新: ${this.markerTitle}`);
  };
  
  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10,
      onMapReady: this.onMapReady
    })
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('动态Marker属性')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`标题: ${this.markerTitle}`)
        .fontSize(14)
        .fontColor('#666')
      
      Text(`位置: ${this.markerPosition.latitude.toFixed(4)}, ${this.markerPosition.longitude.toFixed(4)}`)
        .fontSize(12)
        .fontColor('#666')
      
      Text(`变更次数: ${this.changeCount}`)
        .fontSize(12)
        .fontColor('#666')
      
      Button('随机改变位置')
        .width('100%')
        .onClick(() => this.changePosition())
      
      Button('随机改变标题')
        .width('100%')
        .onClick(() => this.changeTitle())
      
      Button('同时改变')
        .width('100%')
        .backgroundColor('#4CAF50')
        .onClick(() => {
          this.changePosition();
          this.changeTitle();
        })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Dynamic Marker Change',
        description: '动态Marker变化',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


