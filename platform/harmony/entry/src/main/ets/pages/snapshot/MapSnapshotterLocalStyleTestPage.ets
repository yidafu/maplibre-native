/**
 * Map Snapshotter Local Style Test Page
 * 本地样式快照测试页面
 * 
 * 测试功能:
 * - 使用本地样式JSON生成快照
 * - 测试MapSnapshotter的styleJson选项
 */

import { TestPageLayout } from '../common/TestPageLayout';
import {
  NativeMapView,
  MapLibreMap,
  MapLibreMapOptions,
  MapSnapshotter,
  SnapshotOptions,
  MapSnapshot,
  LatLng,
  CameraPosition,
  MapView,
  SnapshotReadyCallback,
  SnapshotErrorHandler
} from 'maplibre_harmony';
import { showToast , DEFAULT_MAP_CONFIG, DEFAULT_STYLE_URLS } from '../common/TestUtils';
import { util } from '@kit.ArkTS';

class ReadyCallback implements SnapshotReadyCallback {
  page: MapSnapshotterLocalStyleTestPage;
  snapshotter: MapSnapshotter;

  constructor(page: MapSnapshotterLocalStyleTestPage, snapshotter: MapSnapshotter) {
    this.page = page;
    this.snapshotter = snapshotter;
  }

  onSnapshotReady(snapshot: MapSnapshot): void {
    this.page.snapshotImage = snapshot.getImage();
    this.page.isGenerating = false;
    showToast('本地样式快照已生成');
    this.snapshotter.cancel();
  }
}

class ErrorCallback implements SnapshotErrorHandler {
  page: MapSnapshotterLocalStyleTestPage;

  constructor(page: MapSnapshotterLocalStyleTestPage) {
    this.page = page;
  }

  onError(error: string): void {
    this.page.isGenerating = false;
    showToast(`快照失败: ${error}`);
  }
}

@Entry
@Component
struct MapSnapshotterLocalStyleTestPage {
  private mapController: MapLibreMap | null = null;
  @State snapshotImage: PixelMap | null = null;  // 改为公开，供回调类访问
  @State isGenerating: boolean = false;
  @State private styleJson: string = '';
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.loadLocalStyle();
  };
  
  /**
   * 加载本地样式
   */
  private loadLocalStyle = async (): Promise<void> => {
    try {
      const context = getContext(this);
      const mgr = context.resourceManager;
      const fileData = await mgr.getRawFileContent('styles-simple.json');
      const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
      this.styleJson = decoder.decodeWithStream(fileData);
      
      this.mapController?.setStyleJson(this.styleJson);
      showToast('本地样式已加载');
    } catch (error) {
      showToast(`加载样式失败: ${error}`);
    }
  };
  
  /**
   * 生成快照（使用本地样式JSON）
   */
  private captureSnapshot = async (): Promise<void> => {
    if (this.isGenerating || !this.styleJson) {
      showToast('样式未加载');
      return;
    }
    
    this.isGenerating = true;
    
    try {
      const cameraPosition = CameraPosition.create(
        LatLng.create(30, 120),
        5,
        0,
        0
      );
      
      const options: SnapshotOptions = {
        size: { width: 800, height: 600 },
        pixelRatio: 2.0,
        styleUrl: '',
        styleJson: this.styleJson,
        cameraPosition: cameraPosition,
        showLogo: true
      };
      
      const snapshotter = new MapSnapshotter(options);

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
    Column({ space: 12 }) {
      Text('本地样式快照')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Button(this.isGenerating ? '生成中...' : '生成快照')
        .width('100%')
        .enabled(!this.isGenerating)
        .onClick(() => this.captureSnapshot())
      
      if (this.snapshotImage) {
        Image(this.snapshotImage)
          .width('100%')
          .height(250)
          .objectFit(ImageFit.Contain)
          .border({ width: 1, color: '#DDD' })
          .margin({ top: 8 })
      }
      
      Text('说明: 使用styleJson选项加载本地样式')
        .fontSize(12)
        .fontColor('#666')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Snapshotter Local Style',
        description: '本地样式快照',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}
