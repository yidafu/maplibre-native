/**
 * Map Snapshotter Bitmap Overlay Test Page
 * 地图快照Bitmap覆盖测试页面
 * 
 * 测试功能:
 * - 使用MapSnapshotter生成快照
 * - 在快照上添加覆盖物（使用Canvas绘制）
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
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct MapSnapshotterBitmapOverlayTestPage {
  private mapController: MapLibreMap | null = null;
  @State private snapshotImage: PixelMap | null = null;
  @State private overlayText: string = 'MapLibre Harmony';
  @State private isGenerating: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  /**
   * 生成带覆盖物的快照
   */
  private generateSnapshotWithOverlay = async (): Promise<void> => {
    if (this.isGenerating) return;
    
    this.isGenerating = true;
    
    try {
      const latLng = this.mapController?.getLatLng() || LatLng.create(39.9042, 116.4074);
      const zoom = this.mapController?.getZoom() || 12;
      
      const cameraPosition = CameraPosition.create(latLng, zoom, 0, 0);
      
      const options: SnapshotOptions = {
        size: { width: 800, height: 600 },
        pixelRatio: 2.0,
        styleUrl: DEFAULT_STYLE_URLS.streets,
        cameraPosition: cameraPosition,
        showLogo: true
      };
      
      const snapshotter = new MapSnapshotter(options);
    
    class ReadyCallback implements SnapshotReadyCallback {
      page: MapSnapshotterBitmapOverlayTestPage;
      snapshotter: MapSnapshotter;
      
      constructor(page: MapSnapshotterBitmapOverlayTestPage, snapshotter: MapSnapshotter) {
        this.page = page;
        this.snapshotter = snapshotter;
      }
      
      onSnapshotReady(snapshot: MapSnapshot): void {
        const pixelMap = snapshot.getImage();
        this.page.snapshotImage = pixelMap;
        this.page.isGenerating = false;
        showToast('快照已生成（含覆盖物功能待实现）');
        this.snapshotter.cancel();
      }
    }
    
    class ErrorCallback implements SnapshotErrorHandler {
      page: MapSnapshotterBitmapOverlayTestPage;
      
      constructor(page: MapSnapshotterBitmapOverlayTestPage) {
        this.page = page;
      }
      
      onError(error: string): void {
        console.error('[MapSnapshotterBitmapOverlayTestPage] Snapshot failed:', error);
        this.page.isGenerating = false;
        showToast(`快照失败: ${error}`);
      }
    }
    
    snapshotter.start(new ReadyCallback(this, snapshotter) , new ErrorCallback(this) );
    } catch (error) {
      this.isGenerating = false;
      showToast(`生成失败: ${error}`);
    }
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
        Text('覆盖物设置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        TextInput({ text: this.overlayText, placeholder: '覆盖文本' })
          .width('100%')
          .onChange((value: string) => {
            this.overlayText = value;
          })
        
        Button(this.isGenerating ? '生成中...' : '生成快照（含覆盖物）')
          .width('100%')
          .enabled(!this.isGenerating)
          .onClick(() => this.generateSnapshotWithOverlay())
        
        Divider()
        
        if (this.snapshotImage) {
          Text('快照预览')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
          
          Image(this.snapshotImage)
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Contain)
            .border({ width: 1, color: '#DDD' })
          
          Button('清除快照')
            .width('100%')
            .backgroundColor('#FF6B6B')
            .onClick(() => {
              this.snapshotImage = null;
            })
        }
        
        Text('说明: 使用MapSnapshotter生成快照')
          .fontSize(12)
          .fontColor('#666')
          .margin({ top: 8 })
        
        Text('TODO: 实现在快照上绘制自定义覆盖物')
          .fontSize(12)
          .fontColor('#FF9800')
      }
      .width('100%')
      .padding(16)
    }
    .height('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Snapshotter Bitmap Overlay',
        description: '快照Bitmap覆盖',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}
