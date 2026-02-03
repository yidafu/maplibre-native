/**
 * LatLng Bounds Test Page
 * LatLng 边界测试页面
 * 
 * 功能：创建和测试 LatLngBounds 对象
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng, LatLngBounds } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct LatLngBoundsTestPage {
  private mapController: MapLibreMap | null = null;
  @State private statusMessage: string = '初始化...';
  @State private boundsApplied: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[LatLngBoundsTestPage] onMapReady');
    this.mapController = map;
    
    this.statusMessage = '地图已就绪';
    this.boundsApplied = false;
    showToast('LatLng 边界功能已激活');
  };
  
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
  
  @Builder
  actionButtonsBuilder() {
    Column({ space: 8 }) {
      Text('LatLng 边界')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor('#666')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
      
      Text('💡 创建和测试 LatLngBounds 对象')
        .fontSize(11)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 4 })
        .lineHeight(16)
      
      Button('限制到冰岛范围')
        .width('100%')
        .backgroundColor('#2196F3')
        .enabled(!this.boundsApplied)
        .onClick(() => this.applyIcelandBounds())

      Button('清除可视范围限制')
        .width('100%')
        .backgroundColor('#607D8B')
        .enabled(this.boundsApplied)
        .onClick(() => this.clearBounds())
    }
    .width('100%')
    .padding(8)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'LatLng Bounds',
        description: 'LatLng 边界',
        showActionBar: true,
        mapContent: (): void => this.mapContentBuilder(),
        actionButtons: (): void => this.actionButtonsBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }

  private applyIcelandBounds(): void {
    if (!this.mapController) {
      showToast('地图尚未就绪');
      return;
    }
    const northeast = LatLng.create(67.5, -12.0);
    const southwest = LatLng.create(63.0, -25.0);
    const bounds = LatLngBounds.fromLatLngs(northeast, southwest);
    this.mapController.setLatLngBounds(bounds);
    this.statusMessage = '已限制到冰岛区域';
    this.boundsApplied = true;
    showToast('已设置冰岛范围限制');
  }

  private clearBounds(): void {
    if (!this.mapController) {
      showToast('地图尚未就绪');
      return;
    }
    this.mapController.setLatLngBounds(null);
    this.statusMessage = '已清除经纬度边界限制';
    this.boundsApplied = false;
    showToast('已清除经纬度边界限制');
  }
}
