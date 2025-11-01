/**
 * Map Snapshotter HeatMap Test Page
 * 地图快照热力图测试页面
 * 
 * 测试功能:
 * - 生成包含热力图的地图快照
 * - 使用MapSnapshotter渲染热力图层
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
  HeatmapLayer,
  GeoJsonSource, GeoJson,
  MapView,
  SnapshotReadyCallback,
  SnapshotErrorHandler
} from 'maplibre_harmony';
import type { IFeatureCollection, IFeature } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct MapSnapshotterHeatMapTestPage {
  private mapController: MapLibreMap | null = null;
  @State private snapshotImage: PixelMap | null = null;
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
    this.mapController.jumpTo(0, 35, 105, 0, 4);
    
    setTimeout((): void => this.addHeatmapLayer(), 1000);
  };
  
  /**
   * 生成热力图GeoJSON数据
   */
  private generateHeatmapData(): IFeatureCollection {
    const features: IFeature[] = [];
    for (let i = 0; i < 100; i++) {
      const props: Record<string, Object> = {
        'intensity': Math.random()
      };
      features.push(GeoJson.pointFeature(
        [100 + Math.random() * 20, 30 + Math.random() * 15],
        props
      ));
    }
    
    return GeoJson.featureCollection(features);
  }
  
  /**
   * 添加热力图层
   */
  private addHeatmapLayer() {
    if (!this.mapController) return;

    try {
      const geojson = this.generateHeatmapData();
      const source = new GeoJsonSource('heatmap-source', geojson);
      this.mapController.getStyle()?.addSource(source);

      const heatmapLayer = new HeatmapLayer('heatmap-layer', 'heatmap-source');
      // TODO: setProperties() not available -
      // heatmapLayer.setProperties({
      //   'heatmap-intensity': 1,
      //   'heatmap-radius': 20,
      //   'heatmap-opacity': 0.8
      // });
      this.mapController.getStyle()?.addLayer(heatmapLayer);

      showToast('热力图已添加');
    } catch (error) {
      console.error('[MapSnapshotterHeatMapTestPage] Add heatmap failed:', error);
    }
  };
  
  /**
   * 捕获热力图快照
   */
   async captureSnapshot(): Promise<void> {
    if (this.isGenerating) return;
    
    this.isGenerating = true;
    
    try {
      const cameraPosition = CameraPosition.create(
        LatLng.create(35, 105),
        4,
        0,
        0
      );
      
      // 注意：MapSnapshotter需要自己配置样式和图层
      // 这里使用当前地图的样式JSON
      const styleJson = this.mapController?.getStyle()?.getJson() || '';
      
      const options: SnapshotOptions = {
        size: { width: 800, height: 600 },
        pixelRatio: 2.0,
        styleUrl: DEFAULT_STYLE_URLS.streets,
        cameraPosition: cameraPosition,
        showLogo: true
      };
      
      const snapshotter = new MapSnapshotter(options);
      
      class ReadyCallback implements SnapshotReadyCallback {
        page: MapSnapshotterHeatMapTestPage;
        snapshotter: MapSnapshotter;
        
        constructor(page: MapSnapshotterHeatMapTestPage, snapshotter: MapSnapshotter) {
          this.page = page;
          this.snapshotter = snapshotter;
        }
        
        onSnapshotReady(snapshot: MapSnapshot): void {
          this.page.snapshotImage = snapshot.getImage();
          this.page.isGenerating = false;
          showToast('热力图快照已生成');
          this.snapshotter.cancel();
        }
      }
      
      class ErrorCallback implements SnapshotErrorHandler {
        page: MapSnapshotterHeatMapTestPage;
        
        constructor(page: MapSnapshotterHeatMapTestPage) {
          this.page = page;
        }
        
        onError(error: string): void {
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
    Column({ space: 12 }) {
      Text('热力图快照')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Button(this.isGenerating ? '生成中...' : '生成热力图快照')
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
      
      Text('说明: MapSnapshotter后台渲染热力图')
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
        title: 'Snapshotter HeatMap',
        description: '热力图快照',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}
