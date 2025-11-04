/**
 * Press For Marker Test Page
 * 点击添加标注测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/annotation/PressForMarkerActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng, Marker, MarkerOptions,
  OnMapClickListener,
  OnMapLongClickListener} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS, formatLatLng , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct PressForMarkerTestPage {
  private mapController: MapLibreMap | null = null;
  private markers: Marker[] = [];;
  @State private markerCount: number = 0;
  @State private lastClickType: string = '';
  
  aboutToDisappear() {
    this.clearAllMarkers();
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[PressForMarkerTestPage] onMapReady');
    this.mapController = map;
    
    // 设置初始相机位置
    map.jumpTo(0, 39.9, 116.4, 0, 10);
    
    // 添加点击监听器
    this.setupClickListeners(map);
    
    showToast('点击地图添加标注');
  };
  
  /**
   * 设置点击监听器
   */
  private setupClickListeners(map: MapLibreMap): void {
    // 单击添加标注
    class MapClickListenerImpl implements OnMapClickListener {
      private page: PressForMarkerTestPage;
      
      constructor(page: PressForMarkerTestPage) {
        this.page = page;
      }
      
      onMapClick(x: number, y: number): boolean {
        if (!this.page.mapController) return false;
        const latLng = this.page.mapController.latLngForPixel(x, y);
        this.page.addMarker(latLng, '单击');
        return true;
      }
    }
    
    // 长按添加标注
    class MapLongClickListenerImpl implements OnMapLongClickListener {
      private page: PressForMarkerTestPage;
      
      constructor(page: PressForMarkerTestPage) {
        this.page = page;
      }
      
      onMapLongClick(x: number, y: number): boolean {
        if (!this.page.mapController) return false;
        const latLng = this.page.mapController.latLngForPixel(x, y);
        this.page.addMarker(latLng, '长按');
        return true;
      }
    }
    
    map.addOnMapClickListener(new MapClickListenerImpl(this));
    map.addOnMapLongClickListener(new MapLongClickListenerImpl(this));
  };
  
  /**
   * 添加标注
   */
  private addMarker(position: LatLng, clickType: string): void {
    if (!this.mapController) return;
    
    this.lastClickType = clickType;
    
    // 获取屏幕坐标（用于调试）
    const screenPoint = this.mapController.pixelForLatLng(position.latitude, position.longitude);
    console.info(`[PressForMarkerTestPage] Screen point: (${screenPoint.x}, ${screenPoint.y})`);
    
    const markerOptions = new MarkerOptions()
      .position(position)
      .title(formatLatLng(position.latitude, position.longitude, 5))
      .snippet(`通过${clickType}添加`);
    
    this.mapController.addMarker(markerOptions).then((marker: Marker) => {
      this.markers.push(marker);
      this.markerCount = this.markers.length;
      showToast(`已添加第 ${this.markerCount} 个标注`);
    });
  };
  
  /**
   * 清除所有标注
   */
  private clearAllMarkers = (): void => {
    if (!this.mapController) return;
    
    for (const marker of this.markers) {
      this.mapController.removeMarker(marker);
    }
    this.markers = [];
    this.markerCount = 0;
    showToast('已清除所有标注');
  };
  
  /**
   * 撤销最后一个标注
   */
  private undoLastMarker = (): void => {
    if (!this.mapController || this.markers.length === 0) {
      showToast('没有可撤销的标注');
      return;
    }
    
    const lastMarker = this.markers.pop();
    if (lastMarker) {
      this.mapController.removeMarker(lastMarker);
      this.markerCount = this.markers.length;
      showToast('已撤销最后一个标注');
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('清除全部')
      .fontSize(14)
      .backgroundColor('#F44336')
      .onClick(this.clearAllMarkers);
    
    Button('撤销')
      .fontSize(14)
      .backgroundColor('#FF9800')
      .onClick(this.undoLastMarker);
    
    Text(`标注数: ${this.markerCount}`)
      .fontSize(14)
      .padding(12)
      .fontWeight(FontWeight.Bold);
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('点击添加标注')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 });
      
      Text(`当前标注数: ${this.markerCount}`)
        .fontSize(14)
        .margin({ bottom: 8 });
      
      if (this.lastClickType) {
        Text(`最后操作: ${this.lastClickType}`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 8 });
      }
      
      Divider().margin({ top: 8, bottom: 8 });
      
      Text('使用说明:')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 });
      
      Text('• 单击地图添加标注')
        .fontSize(12)
        .fontColor('#666666')
        .margin({ bottom: 4 });
      
      Text('• 长按地图添加标注')
        .fontSize(12)
        .fontColor('#666666')
        .margin({ bottom: 4 });
      
      Text('• 点击标注查看详情')
        .fontSize(12)
        .fontColor('#666666');
    }
    .alignItems(HorizontalAlign.Start);
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Press For Marker',
        description: '点击添加标注',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        controlPanel: (): void => this.controlPanelBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
