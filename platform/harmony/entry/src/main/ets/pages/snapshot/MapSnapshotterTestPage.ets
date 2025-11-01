/**
 * Map Snapshotter Test Page
 * 地图快照测试页面
 * 
 * 参考: platform/android/.../snapshot/MapSnapshotterActivity.kt
 * 
 * 测试功能:
 * - 使用MapSnapshotter生成地图快照
 * - 网格布局显示多个快照
 * - 测试不同位置和缩放级别的快照
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { 
  NativeMapView, 
  MapLibreMap, 
  MapLibreMapOptions, 
  MapSnapshotter,
  SnapshotOptions,
  MapSnapshot,
  CameraPosition,
  LatLng,
  MapView,
  SnapshotReadyCallback,
  SnapshotErrorHandler
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

interface LocationInfo {
  name: string;
  latitude: number;
  longitude: number;
  zoom: number;
}

@Entry
@Component
struct MapSnapshotterTestPage {
  private mapController: MapLibreMap | null = null;
  @State private snapshots: PixelMap[] = [];
  @State private snapshotCount: number = 0;
  @State private isCapturing: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 10);
  };
  
  /**
   * 捕获快照（使用MapSnapshotter）
   */
  private captureSnapshot = async (lat: number, lng: number, zoom: number, name: string): Promise<void> => {
    try {
      const cameraPosition = CameraPosition.create(
        LatLng.create(lat, lng),
        zoom,
        0,
        0
      );
      
      const options: SnapshotOptions = {
        size: { width: 400, height: 300 },
        pixelRatio: 2.0,
        styleUrl: DEFAULT_STYLE_URLS.streets,
        cameraPosition: cameraPosition,
        showLogo: true
      };
      
      const snapshotter = new MapSnapshotter(options);
      
      class ReadyCallback implements SnapshotReadyCallback {
        page: MapSnapshotterTestPage;
        snapshotter: MapSnapshotter;
        name: string;
        
        constructor(page: MapSnapshotterTestPage, snapshotter: MapSnapshotter, name: string) {
          this.page = page;
          this.snapshotter = snapshotter;
          this.name = name;
        }
        
        onSnapshotReady(snapshot: MapSnapshot): void {
          const pixelMap = snapshot.getImage();
          this.page.snapshots.push(pixelMap);
          this.page.snapshotCount++;
          showToast(`快照 ${this.page.snapshotCount} 已生成: ${this.name}`);
          this.snapshotter.cancel();
        }
      }
      
      class ErrorCallback implements SnapshotErrorHandler {
        onError(error: string): void {
          console.error('[MapSnapshotterTestPage] Snapshot failed:', error);
          showToast(`快照失败: ${error}`);
        }
      }
      
      snapshotter.start(new ReadyCallback(this, snapshotter, name) , new ErrorCallback() );
    } catch (error) {
      console.error('[MapSnapshotterTestPage] Snapshot creation failed:', error);
      showToast(`创建快照失败: ${error}`);
    }
  };
  
  /**
   * 生成当前视图快照
   */
  private captureCurrentView = async (): Promise<void> => {
    if (this.isCapturing || !this.mapController) return;
    
    this.isCapturing = true;
    const latLng = this.mapController.getLatLng();
    const zoom = this.mapController.getZoom();
    
    await this.captureSnapshot(latLng.latitude, latLng.longitude, zoom, '当前视图');
    this.isCapturing = false;
  };
  
  /**
   * 生成多个快照
   */
  private generateMultipleSnapshots = async (): Promise<void> => {
    if (this.isCapturing) return;
    
    this.isCapturing = true;
    
    const locations: LocationInfo[] = [
      { latitude: TEST_LOCATIONS.beijing.latitude, longitude: TEST_LOCATIONS.beijing.longitude, name: '北京', zoom: 12 },
      { latitude: TEST_LOCATIONS.shanghai.latitude, longitude: TEST_LOCATIONS.shanghai.longitude, name: '上海', zoom: 12 },
      { latitude: TEST_LOCATIONS.guangzhou.latitude, longitude: TEST_LOCATIONS.guangzhou.longitude, name: '广州', zoom: 12 },
      { latitude: TEST_LOCATIONS.shenzhen.latitude, longitude: TEST_LOCATIONS.shenzhen.longitude, name: '深圳', zoom: 14 }
    ];
    
    for (let loc of locations) {
      await this.captureSnapshot(loc.latitude, loc.longitude, loc.zoom, loc.name);
      await new Promise<void>(resolve => setTimeout(resolve, 500)); // 间隔500ms
    }
    
    this.isCapturing = false;
    showToast('批量快照完成');
  };
  
  /**
   * 清除所有快照
   */
  private clearSnapshots = (): void => {
    this.snapshots = [];
    this.snapshotCount = 0;
    showToast('快照已清除');
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
        Text('MapSnapshotter 快照')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Text(`已生成快照: ${this.snapshotCount}`)
          .fontSize(14)
          .fontColor('#666')
        
        Button(this.isCapturing ? '捕获中...' : '捕获当前视图')
          .width('100%')
          .enabled(!this.isCapturing)
          .onClick(() => this.captureCurrentView())
        
        Button('生成4个城市快照')
          .width('100%')
          .backgroundColor('#4CAF50')
          .enabled(!this.isCapturing)
          .onClick(() => this.generateMultipleSnapshots())
        
        Button('清除快照')
          .width('100%')
          .backgroundColor('#FF6B6B')
          .enabled(this.snapshots.length > 0)
          .onClick(() => this.clearSnapshots())
        
        Divider()
        
        Text('快照预览')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Grid() {
          ForEach(this.snapshots, (snapshot: PixelMap, index: number) => {
            GridItem() {
              Column() {
                Image(snapshot)
                  .width('100%')
                  .height(100)
                  .objectFit(ImageFit.Cover)
                  .border({ width: 1, color: '#DDD' })
                
                Text(`#${index + 1}`)
                  .fontSize(10)
                  .fontColor('#666')
              }
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        
        Text('说明: 使用MapSnapshotter后台渲染地图')
          .fontSize(12)
          .fontColor('#666')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(16)
    }
    .height('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Map Snapshotter',
        description: '地图快照',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}
