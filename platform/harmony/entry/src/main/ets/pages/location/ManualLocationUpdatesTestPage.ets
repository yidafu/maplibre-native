/**
 * Manual Location Updates Test Page
 * 手动定位更新测试页面
 * 
 * 测试功能:
 * - 手动更新定位
 * - 强制设置定位位置
 * - 模拟定位数据
 */

import { TestPageLayout } from '../common/TestPageLayout';
import {
  NativeMapView,
  MapLibreMap,
  MapLibreMapOptions,
  LocationComponent,
  LocationComponentOptions,
  RenderMode,
  PermissionManager
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import geoLocationManager from '@ohos.geoLocationManager';
import { MapView } from 'maplibre_harmony';

@Entry
@Component
struct ManualLocationUpdatesTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private updateCount: number = 0;
  @State private currentLat: number = 39.9042;
  @State private currentLng: number = 116.4074;
  @State private heading: number = 0;
  @State private permissionGranted: boolean = false;
  
  // 预设位置
  private presetLocations: Array<Record<string, Object>> = [
    { 'name': '北京', 'lat': 39.9042, 'lng': 116.4074 },
    { 'name': '上海', 'lat': 31.2304, 'lng': 121.4737 },
    { 'name': '广州', 'lat': 23.1291, 'lng': 113.2644 },
    { 'name': '深圳', 'lat': 22.5431, 'lng': 114.0579 }
  ]
  
  aboutToDisappear() {
    if (this.locationComponent) {
      this.locationComponent.setLocationComponentEnabled(false);
    }
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = async (mapView: NativeMapView): Promise<void> => {
    if (!mapView) return;
    this.mapController = mapView as Object as MapLibreMap;
    if (!this.mapController) return;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, this.currentLat, this.currentLng, 0, 12);
    
    setTimeout(() => this.initLocationComponent(), 1500);
  };
  
  private initLocationComponent = async (): Promise<void> => {
    if (!this.mapController) return;
    
    try {
      const result = await PermissionManager.requestLocationPermission(getContext(this));
      this.permissionGranted = result.granted;
      
      if (!this.permissionGranted) {
        showToast('定位权限被拒绝');
        return;
      }
      
      this.locationComponent = this.mapController.getLocationComponent();
      const options = new LocationComponentOptions();
      this.locationComponent.activateLocationComponent(options);
      this.locationComponent.setLocationComponentEnabled(true);
      this.locationComponent.setRenderMode(RenderMode.GPS);
      
      showToast('定位组件已启用');
    } catch (error) {
      console.error('[ManualLocationUpdatesTestPage] Init failed:', error);
    }
  };
  
  /**
   * 手动更新位置
   */
  private forceLocationUpdate = (lat: number, lng: number, bearing?: number): void => {
    if (!this.locationComponent) {
      showToast('定位组件未初始化');
      return;
    }
    
    // 创建模拟定位数据
    const mockLocation: geoLocationManager.Location = {
      latitude: lat,
      longitude: lng,
      altitude: 0,
      accuracy: 10,
      speed: 0,
      timeStamp: Date.now(),
      direction: bearing || this.heading,
      timeSinceBoot: Date.now(),
      additions: [],
      additionSize: 0,
      // isFromMock: true
    };
    
    try {
      this.locationComponent.forceLocationUpdate(lat, lng, bearing);
      this.currentLat = lat;
      this.currentLng = lng;
      if (bearing !== undefined) {
        this.heading = bearing;
      }
      this.updateCount++;
      
      const centerData: Record<string, number> = {
        'latitude': lat,
        'longitude': lng
      };
      // this.mapController?.easeTo(...) 需要使用 CameraPosition
      // 简化处理：直接使用 jumpTo
      this.mapController?.jumpTo(this.heading, lat, lng, 0, 15);
      
      showToast(`位置已更新 (${this.updateCount})`);
    } catch (error) {
      console.error('[ManualLocationUpdatesTestPage] Force update failed:', error);
      showToast(`更新失败: ${error}`);
    }
  };
  
  /**
   * 模拟移动
   */
  private simulateMovement = (): void => {
    const offsetLat = (Math.random() - 0.5) * 0.01;
    const offsetLng = (Math.random() - 0.5) * 0.01;
    const newBearing = Math.random() * 360;
    
    this.forceLocationUpdate(
      this.currentLat + offsetLat,
      this.currentLng + offsetLng,
      newBearing
    );
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
    Scroll() {
      Column({ space: 12 }) {
        Text('手动定位更新')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Text(`更新次数: ${this.updateCount}`)
          .fontSize(14)
          .fontColor('#666')
        
        Text(`方向: ${this.heading.toFixed(0)}°`)
          .fontSize(14)
          .fontColor('#666')
        
        Button('模拟移动')
          .width('100%')
          .backgroundColor('#4CAF50')
          .enabled(this.permissionGranted)
          .onClick(() => this.simulateMovement())
        
        Divider()
        
        Text('跳转到预设位置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        ForEach(this.presetLocations, (preset: Record<string, Object>) => {
          Button(preset['name'] as string)
            .width('100%')
            .enabled(this.permissionGranted)
            .onClick(() => this.forceLocationUpdate(preset['lat'] as number, preset['lng'] as number))
        })
        
        Divider()
        
        Row({ space: 8 }) {
          Button('随机位置')
            .layoutWeight(1)
            .enabled(this.permissionGranted)
            .onClick(() => {
              const randomLat = 20 + Math.random() * 30;
              const randomLng = 100 + Math.random() * 30;
              this.forceLocationUpdate(randomLat, randomLng);
            })
          
          Button('重置')
            .layoutWeight(1)
            .backgroundColor('#FF6B6B')
            .onClick(() => {
              this.updateCount = 0;
              this.heading = 0;
              this.forceLocationUpdate(39.9042, 116.4074, 0);
            })
        }
        .width('100%')
        
        Text(`当前位置: ${this.currentLat.toFixed(6)}, ${this.currentLng.toFixed(6)}`)
          .fontSize(11)
          .fontColor('#999')
          .margin({ top: 8 })
        
        Text('说明: 使用forceLocationUpdate手动更新定位')
          .fontSize(12)
          .fontColor('#666')
      }
      .width('100%')
      .padding(16)
    }
    .height('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Manual Location Updates',
        description: '手动定位更新',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}
