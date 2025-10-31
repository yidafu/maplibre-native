/**
 * Collection Update On Style Change Test Page
 * 样式切换时集合更新测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions, Marker, MarkerOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct CollectionUpdateOnStyleChangeTestPage {
  private mapController: MapLibreMap | null = null;
  private markers: Marker[] = [];
  @State private currentStyle: string = 'Streets';
  @State private markerCount: number = 0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = async (mapView: NativeMapView): Promise<void> => {
    const options = new MapLibreMapOptions();
    this.mapController = new MapLibreMap(mapView, options);
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 35, 105, 0, 4);
    
    await this.addMarkers();
  };
  
  private addMarkers = async (): Promise<void> => {
    if (!this.mapController) return;
    
    const locations = [TEST_LOCATIONS.beijing, TEST_LOCATIONS.shanghai, TEST_LOCATIONS.guangzhou];
    
    for (let loc of locations) {
      const markerOptions = new MarkerOptions()
        .position(loc)
        .title('Marker');
      const marker = await this.mapController.addMarker(markerOptions);
      this.markers.push(marker);
    }
    
    this.markerCount = this.markers.length;
    showToast(`已添加${this.markerCount}个标记`);
  };
  
  private switchStyle = (styleName: string, styleUrl: string): void => {
    if (!this.mapController) return;
    
    this.currentStyle = styleName;
    this.mapController.setStyleUrl(styleUrl);
    showToast(`样式已切换: ${styleName}`);
  };
  
  @Builder
  buildMapContent() {
    NativeMapView({
      onMapReady: this.onMapReady
    })
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text(`标记数: ${this.markerCount}`)
        .fontSize(14)
      
      Button('Streets')
        .width('100%')
        .backgroundColor(this.currentStyle === 'Streets' ? '#2196F3' : '#9E9E9E')
        .onClick(() => this.switchStyle('Streets', DEFAULT_STYLE_URLS.streets))
      
      Button('Satellite')
        .width('100%')
        .backgroundColor(this.currentStyle === 'Satellite' ? '#2196F3' : '#9E9E9E')
        .onClick(() => this.switchStyle('Satellite', DEFAULT_STYLE_URLS.satellite))
      
      Text('说明: 样式切换后标记集合应保持')
        .fontSize(12)
        .fontColor('#666')
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Collection Update on Style Change',
        description: '样式切换集合更新',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


