import { MapLibreMap, MapView, GeoJsonSource, FillLayer, GeoJson, IFeature } from 'maplibre_harmony';
/**
 * Query Rendered Features Box Highlight Test Page  
 * 框选高亮要素
 * 参考 Android: QueryRenderedFeaturesBoxHighlightActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct QueryRenderedFeaturesBoxHighlightTestPage {
  private mapController: MapLibreMap | null = null;
  @State private highlightedCount: number = 0;
  private readonly HIGHLIGHT_SOURCE_ID = 'highlight-source';
  private readonly HIGHLIGHT_LAYER_ID = 'highlight-layer';
  private isHighlightLayerAdded: boolean = false;
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Box Highlight Features',
      description: '框选高亮显示要素',
      showActionBar: true,
      mapContent: (): void => this.buildMapContent(),
      actionButtons: (): void => this.buildActionButtons()
    })
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 14);
      }
    })
  }

  @Builder
  buildActionButtons() {
    Button('查询并高亮')
      .onClick(() => {
        this.queryAndHighlight();
      })
    
    Button('清除高亮')
      .onClick(() => {
        this.clearHighlight();
      })
  }

  private queryAndHighlight(): void {
    if (!this.mapController) return;
    
    try {
      // 查询屏幕中心区域
      const features = this.mapController.queryRenderedFeaturesForBox(300, 400, 780, 1200, ['building']);
      
      this.highlightedCount = features.length;
      showToast(`查询到 ${features.length} 个建筑物`);
      
      if (features.length > 0) {
        this.highlightFeatures(features);
      } else {
        this.clearHighlight();
      }
    } catch (error) {
      showToast(`查询失败: ${error}`);
      console.error(`Query and highlight failed: ${error}`);
    }
  }

  /**
   * 高亮显示查询到的要素
   */
  private highlightFeatures(features: IFeature[]): void {
    if (!this.mapController) return;
    
    try {
      // 创建 GeoJSON FeatureCollection
      const featureCollection = GeoJson.featureCollection(features);
      
      // 如果高亮图层还没有添加，先添加
      if (!this.isHighlightLayerAdded) {
        this.addHighlightLayer();
      }
      
      // 更新高亮数据源
      const source = this.mapController.getSource(this.HIGHLIGHT_SOURCE_ID);
      if (source && source instanceof GeoJsonSource) {
        source.setGeoJson(featureCollection);
        console.info(`[QueryRenderedFeaturesBoxHighlight] Highlighted ${features.length} features`);
      }
    } catch (error) {
      console.error(`Highlight features failed: ${error}`);
      showToast(`高亮失败: ${error}`);
    }
  }

  /**
   * 添加高亮图层
   */
  private addHighlightLayer(): void {
    if (!this.mapController) return;
    
    try {
      // 创建空的 GeoJSON 数据源
      const emptyCollection = GeoJson.featureCollection([]);
      const source = new GeoJsonSource(this.HIGHLIGHT_SOURCE_ID);
      source.setGeoJson(emptyCollection);
      this.mapController.addSource(source);
      
      // 创建高亮填充图层
      const layer = new FillLayer(this.HIGHLIGHT_LAYER_ID, this.HIGHLIGHT_SOURCE_ID);
      layer.setFillColor('#FFD700'); // 金色
      layer.setFillOpacity(0.5);
      layer.setFillOutlineColor('#FF6B00'); // 橙色轮廓
      
      this.mapController.addLayer(layer);
      this.isHighlightLayerAdded = true;
      
      console.info('[QueryRenderedFeaturesBoxHighlight] Highlight layer added');
    } catch (error) {
      console.error(`Add highlight layer failed: ${error}`);
      showToast(`添加高亮图层失败: ${error}`);
    }
  }

  /**
   * 清除高亮显示
   */
  private clearHighlight(): void {
    if (!this.mapController || !this.isHighlightLayerAdded) return;
    
    try {
      // 清空高亮数据源
      const source = this.mapController.getSource(this.HIGHLIGHT_SOURCE_ID);
      if (source && source instanceof GeoJsonSource) {
        const emptyCollection = GeoJson.featureCollection([]);
        source.setGeoJson(emptyCollection);
      }
      
      this.highlightedCount = 0;
      showToast('高亮已清除');
      console.info('[QueryRenderedFeaturesBoxHighlight] Highlight cleared');
    } catch (error) {
      console.error(`Clear highlight failed: ${error}`);
      showToast(`清除高亮失败: ${error}`);
    }
  }
}

