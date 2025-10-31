/**
 * Map Snapshotter Reuse Test Page
 * 快照器重用测试页面
 * 
 * 测试功能:
 * - 快速连续生成多个快照
 * - 测试MapSnapshotter的性能和重用
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
  LatLng
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct MapSnapshotterReuseTestPage {
  private mapController: MapLibreMap | null = null;
  @State private snapshots: PixelMap[] = [];
  @State private isCapturing: boolean = false;
  @State private captureCount: number = 0;
  @State private totalTime: number = 0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (mapView: NativeMapView): void => {
    const options = new MapLibreMapOptions();
    this.mapController = new MapLibreMap(mapView, options);
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 10);
  };
  
  /**
   * 快速捕获多个快照（重用测试）
   */
  private captureMultiple = async (): Promise<void> => {
    if (this.isCapturing) return;
    
    this.isCapturing = true;
    const startTime = Date.now();
    
    const locations = [
      { name: '北京', ...TEST_LOCATIONS.beijing },
      { name: '上海', ...TEST_LOCATIONS.shanghai },
      { name: '广州', ...TEST_LOCATIONS.guangzhou }
    ];
    
    // 并行生成快照（测试性能）
    const promises = locations.map((loc, index) => {
      return new Promise<void>((resolve) => {
        const cameraPosition = new CameraPosition(
          LatLng.create(loc.latitude, loc.longitude),
          12,
          0,
          0
        );
        
        const options: SnapshotOptions = {
          size: { width: 400, height: 300 },
          pixelRatio: 1.5,
          styleUrl: DEFAULT_STYLE_URLS.streets,
          cameraPosition: cameraPosition,
          showLogo: false
        };
        
        const snapshotter = new MapSnapshotter(options);
        
        snapshotter.start(
          {
            onSnapshotReady: (snapshot: MapSnapshot) => {
              this.snapshots.push(snapshot.getImage());
              this.captureCount++;
              snapshotter.cancel();
              resolve();
            }
          },
          {
            onError: (error: string) => {
              console.error(`[MapSnapshotterReuseTestPage] Snapshot ${index} failed:`, error);
              resolve();
            }
          }
        );
      });
    });
    
    await Promise.all(promises);
    
    this.totalTime = Date.now() - startTime;
    this.isCapturing = false;
    showToast(`完成3个快照，耗时${this.totalTime}ms，平均${(this.totalTime/3).toFixed(0)}ms/个`);
  };
  
  /**
   * 清除快照
   */
  private clearSnapshots = (): void => {
    this.snapshots = [];
    this.captureCount = 0;
    this.totalTime = 0;
    showToast('快照已清除');
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
    Scroll() {
      Column({ space: 12 }) {
        Text('快照器性能测试')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Text(`已捕获: ${this.captureCount}个`)
          .fontSize(14)
          .fontColor('#666')
        
        if (this.totalTime > 0) {
          Text(`总耗时: ${this.totalTime}ms`)
            .fontSize(14)
            .fontColor('#666')
          
          Text(`平均: ${(this.totalTime / Math.max(this.captureCount, 1)).toFixed(0)}ms/个`)
            .fontSize(14)
            .fontColor('#4CAF50')
            .fontWeight(FontWeight.Bold)
        }
        
        Button(this.isCapturing ? '捕获中...' : '快速捕获3个')
          .width('100%')
          .backgroundColor('#4CAF50')
          .enabled(!this.isCapturing)
          .onClick(() => this.captureMultiple())
        
        Button('清除快照')
          .width('100%')
          .backgroundColor('#FF6B6B')
          .enabled(this.snapshots.length > 0)
          .onClick(() => this.clearSnapshots())
        
        Divider()
        
        Text('快照预览')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Grid() {
          ForEach(this.snapshots, (snapshot: PixelMap, index: number) => {
            GridItem() {
              Column() {
                Image(snapshot)
                  .width('100%')
                  .height(80)
                  .objectFit(ImageFit.Cover)
                  .border({ width: 1, color: '#DDD' })
                
                Text(`#${index + 1}`)
                  .fontSize(10)
              }
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(4)
        .columnsGap(4)
        .width('100%')
        
        Text('说明: 并行生成多个快照测试性能')
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
        title: 'Snapshotter Reuse',
        description: '快照器重用',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}
