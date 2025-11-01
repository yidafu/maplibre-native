/**
 * Custom Sprite Test Page
 * 自定义精灵图测试
 * 参考 Android: CustomSpriteActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { GeoJson, GeoJsonSource, MapLibreMap, MapView, SymbolLayer } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct CustomSpriteTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Custom Sprite',
        description: '自定义图标精灵',
        showActionBar: true,
        mapContent: this.buildMapContent,
        actionButtons: this.buildActionButtons
      })
    }
    .width('100%')

    .height('100%')
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 35, 105, 0, 4);
      }
    })
  }

  @Builder
  buildActionButtons() {
    Button('添加自定义图标')
      .onClick(() => {
        this.addCustomIcon();
      })
    
    Button('使用自定义图标')
      .onClick(() => {
        this.useCustomIcon();
      })
  }
  
  private addCustomIcon(): void {
    if (!this.mapController) return;
    
    try {
      // TODO: 实现添加自定义图标
      showToast('自定义图标 API 待实现');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
  }
  
  private useCustomIcon(): void {
    if (!this.mapController) return;
    
    try {
      const props: Record<string, Object> = { 'icon': 'custom-icon' };
      const geojson = GeoJson.featureCollection([
        GeoJson.pointFeature([116.4, 39.9], props)
      ]);
      
      const source = new GeoJsonSource('icon-source');
      source.setGeoJson(geojson);
      this.mapController.addSource(source);
      
      const layer = new SymbolLayer('icon-layer', 'icon-source');
      layer.setIconImage(['get', 'icon']);
      layer.setIconSize(1.5);
      this.mapController.addLayer(layer);
      
      showToast('图标图层已添加');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
  }
}

