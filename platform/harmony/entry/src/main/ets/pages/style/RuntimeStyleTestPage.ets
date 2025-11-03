/**
 * Runtime Style Test Page
 * 运行时样式测试 - 完整功能实现
 * 参考 Android: RuntimeStyleActivity
 * 
 * 实现了以下功能:
 * 1. 列出所有图层和数据源
 * 2. 设置水体颜色（带过渡动画）
 * 3. 设置背景透明度
 * 4. 设置图层可见性
 * 5. 移除建筑图层
 * 6. 添加公园图层（带过滤器）
 * 7. 添加栅格图层
 * 8. 基于缩放的颜色插值
 * 9. 图层顺序调整
 * 10. 更多样式操作...
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { 
  BackgroundLayer,
  FillLayer, 
  GeoJson, 
  GeoJsonSource, 
  MapLibreMap, 
  MapView,
  RasterLayer,
  RasterSource,
  Expression,
  LineLayer,
  VectorSource
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';
import resourceManager from '@ohos.resourceManager';

@Entry
@Component
struct RuntimeStyleTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentZoom: number = 10;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Runtime Style',
        description: '运行时样式操作 - 完整功能演示',
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
      initialLatitude: 52.379189,
      initialLongitude: 4.899431,
      initialZoom: 8,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 52.379189, 4.899431, 0, 8);
        showToast('地图已加载，开始测试样式功能');
      }
    })
  }

  @Builder
  buildActionButtons() {
    Column({ space: 8 }) {
      Text('图层和数据源操作')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 4, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('列出图层')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.listLayers())
        
        Button('列出数据源')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.listSources())
      }
      
      Text('样式修改')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('水体变红')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.setWaterColor())
        
        Button('背景透明')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.setBackgroundOpacity())
      }
      
      Row({ space: 8 }) {
        Button('隐藏水体')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.setLayerInvisible())
        
        Button('移除建筑')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.removeBuildings())
      }
      
      Text('添加图层')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('添加公园')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.addParksLayer())
        
        Button('添加栅格')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.addRasterSourceLayer())
        
        Button('移除栅格')
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor('#FF5722')
          .onClick(() => {
            try {
              this.mapController?.removeLayer('osm-layer');
              this.mapController?.removeSource('osm');
              showToast('栅格图层已移除');
            } catch (error) {
              showToast(`移除失败: ${error}`);
            }
          })
      }
      
      Row({ space: 8 }) {
        Button('添加地形线')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.addTerrainLayer())
        
        Button('自定义瓦片')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.addCustomTileSource())
      }
      
      Text('高级功能')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Button('缩放颜色插值')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.updateWaterColorOnZoom())
      
      Button('水体置顶')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.bringWaterToFront())
      
      Button('测试图层(添加/删除)')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.toggleTestLayer())
    }
    .width('100%')
  }

  // 列出所有图层
  private listLayers(): void {
    if (!this.mapController) return;
    
    try {
      const layers = this.mapController.getLayers();
      let layerNames = '图层列表:\n';
      layers.forEach((layer) => {
        layerNames += `- ${layer.getId()}\n`;
      });
      showToast(layerNames);
      console.info(`图层列表: ${layerNames}`);
    } catch (error) {
      showToast(`获取图层失败: ${error}`);
    }
  }

  // 列出所有数据源
  private listSources(): void {
    if (!this.mapController) return;
    
    try {
      const sources = this.mapController.getSources();
      let sourceNames = '数据源列表:\n';
      sources.forEach((source: ESObject) => {
        sourceNames += `- ${JSON.stringify(source)}\n`;
      });
      showToast(sourceNames);
      console.info(`数据源列表: ${sourceNames}`);
    } catch (error) {
      showToast(`获取数据源失败: ${error}`);
    }
  }

  // 设置水体颜色（带过渡动画）
  private setWaterColor(): void {
    if (!this.mapController) return;
    
    try {
      // OpenFreeMap bright 样式中的水体图层（LineLayer类型）
      const waterLayerIds = [
        "waterway_tunnel",
        'waterway-stream-canal',
        'waterway-other',
        'waterway_tunnel',
        "water-intermittent",
        'water'  // 兜底，某些样式可能有
      ];
      let found = false;
      
      for (const layerId of waterLayerIds) {
        const waterLayer = this.mapController.getLayer(layerId);
        console.info(`[RuntimeStyle] 查找图层 "${layerId}":`, waterLayer ? `找到，类型=${waterLayer.constructor.name}` : '未找到');
        
        // 支持 FillLayer 和 LineLayer
        if (waterLayer instanceof FillLayer) {
          waterLayer.setFillColor('#FF0000'); // 红色（CSS 格式）
          showToast(`水体图层 "${layerId}" (Fill) 已变红`);
          // found = true;
          // break;
        } else if (waterLayer instanceof LineLayer) {
          waterLayer.setLineColor('#FF0000'); // 红色（CSS 格式）
          showToast(`水体图层 "${layerId}" (Line) 已变红`);
          // found = true;
          // break;
        }
      }
      
    } catch (error) {
      showToast(`设置水体颜色失败: ${error}`);
    }
  }

  // 设置背景透明度
  private setBackgroundOpacity(): void {
    if (!this.mapController) return;
    
    try {
      const bgLayer = this.mapController.getLayer('background');
      if (bgLayer && bgLayer instanceof BackgroundLayer) {
        bgLayer.setBackgroundOpacity(0.2);
        showToast('背景透明度已设置为 0.2');
      } else {
        showToast('未找到背景图层');
      }
    } catch (error) {
      showToast(`设置背景透明度失败: ${error}`);
    }
  }

  // 设置图层不可见
  private setLayerInvisible(): void {
    if (!this.mapController) return;
    
    try {
      // OpenFreeMap bright 样式中的水体图层（LineLayer类型）
      const waterLayerIds = [
        "waterway_tunnel",
        'waterway-stream-canal',
        'waterway-other',
        'waterway_tunnel',
        "water-intermittent",
        'water'
      ];
      let found = false;
      
      for (const layerId of waterLayerIds) {
        const waterLayer = this.mapController.getLayer(layerId);
        
        // 支持 FillLayer 和 LineLayer
        if (waterLayer instanceof FillLayer || waterLayer instanceof LineLayer) {
          waterLayer.setVisibility('none');
          showToast(`水体图层 "${layerId}" 已隐藏`);
          // found = true;
          // break;
        }
      }
      
      // if (!found) {
      //   showToast('未找到水体图层（water/waterway）');
      // }
    } catch (error) {
      showToast(`隐藏图层失败: ${error}`);
    }
  }

  // 移除建筑图层
  private removeBuildings(): void {
    if (!this.mapController) return;
    
    try {
      this.mapController.removeLayer('building');
      showToast('建筑图层已移除');
    } catch (error) {
      showToast(`移除建筑图层失败: ${error}`);
    }
  }

  // 添加公园图层（带过滤器）
  private addParksLayer(): void {
    if (!this.mapController) return;
    
    try {
      // 加载 amsterdam.geojson
      const context = getContext(this);
      context.resourceManager.getRawFileContent('amsterdam.geojson', (error, value) => {
        if (error) {
          showToast('加载数据失败');
          return;
        }
        
        const uint8Array = new Uint8Array(value.buffer);
        const geojsonStr = String.fromCharCode(...Array.from(uint8Array));
        
        // 添加数据源
        const source = new GeoJsonSource('amsterdam-spots');
        const geojson: object = JSON.parse(geojsonStr);
        source.setGeoJson(geojson);
        this.mapController!.addSource(source);
        
        // 添加填充图层
        const layer = new FillLayer('parksLayer', 'amsterdam-spots');
        layer.setFillColor('#FF0000'); // 红色（CSS 格式）
        layer.setFillOutlineColor('#0000FF'); // 蓝色边框（CSS 格式）
        layer.setFillOpacity(0.3);
        
        // 设置过滤器：只显示公园
        const filterExpr = Expression.all(
          Expression.eq(Expression.get('type'), Expression.literal('park')),
          Expression.eq(Expression.get('stroke-width'), Expression.literal(3))
        );
        layer.setFilter(filterExpr);
        
        this.mapController!.addLayer(layer);
        showToast('公园图层已添加');
        
        // 移动相机到阿姆斯特丹
        this.mapController!.jumpTo(0, 52.379189, 4.899431, 0, 6);
      });
    } catch (error) {
      showToast(`添加公园图层失败: ${error}`);
    }
  }

  // 添加栅格图层
  private addRasterSourceLayer(): void {
    if (!this.mapController) return;
    
    console.info('🔵 [RuntimeStyleTestPage] addRasterSourceLayer: START');
    
    try {
      // 先移除已存在的图层和数据源（避免重复添加）
      try {
        console.info('🔵 [RuntimeStyleTestPage] Removing existing osm-layer and osm source');
        this.mapController.removeLayer('osm-layer');
        this.mapController.removeSource('osm');
      } catch (e) {
        console.info('🔵 [RuntimeStyleTestPage] Remove failed (expected for first time):', e);
      }
      
      // 添加 OSM 栅格源（在构造时传入所有配置）
      // 注意：如果 HTTPS 超时，可以尝试 HTTP 或其他瓦片源
      // 备选方案：
      // - 'http://tile.openstreetmap.org/{z}/{x}/{y}.png' (HTTP，可能被阻止)
      // - 'https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.png' (需要 API key)
      // - 'https://tiles.wikimedia.org/osm-intl/{z}/{x}/{y}.png' (可能需要不同格式)
      console.info('🔵 [RuntimeStyleTestPage] Creating RasterSource with:', {
        id: 'osm',
        url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        tileSize: 256
      });
      
      // 使用 tiles 数组而非 url（直接指定瓦片模板）
      // ArcGIS 需要使用 tiles 数组，因为它的 REST API 返回的是元数据而非 TileJSON
      const source = new RasterSource('osm', {
        tiles: [
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}'
          // 'https://webst01.is.autonavi.com/appmaptile?style=6&x={x}&y={y}&z={z}'
        ],
        tileSize: 256,
        minzoom: 0,
        maxzoom: 18
      });
      
      console.info('🔵 [RuntimeStyleTestPage] RasterSource created, calling addSource');
      this.mapController.addSource(source);
      console.info('🔵 [RuntimeStyleTestPage] addSource completed');
      
      // 添加栅格图层（设置半透明以避免完全遮盖底图）
      console.info('🔵 [RuntimeStyleTestPage] Creating RasterLayer');
      const layer = new RasterLayer('osm-layer', 'osm');
      
      // 设置透明度为 0.5，这样可以同时看到栅格图层和底图
      layer.setRasterOpacity(0.5);
      
      console.info('🔵 [RuntimeStyleTestPage] RasterLayer created, calling addLayer');
      this.mapController.addLayer(layer);
      console.info('🔵 [RuntimeStyleTestPage] addLayer completed');
      
      showToast('OSM 栅格图层已添加（透明度 50%）');
    } catch (error) {
      console.error('🔴 [RuntimeStyleTestPage] addRasterSourceLayer failed:', error);
      showToast(`添加栅格图层失败: ${error}`);
    }
  }

  // 添加地形线图层
  private addTerrainLayer(): void {
    if (!this.mapController) return;
    
    try {
      // 添加矢量源
      const source = new VectorSource('my-terrain-source');
      source.setUrl('maptiler://sources/hillshades');
      this.mapController.addSource(source);
      
      // 添加线图层
      const layer = new LineLayer('terrainLayer', 'my-terrain-source');
      layer.setSourceLayer('contour');
      layer.setLineColor('#FF0000'); // 红色（CSS 格式）
      layer.setLineWidth(2);
      
      this.mapController.addLayer(layer);
      showToast('地形线图层已添加');
    } catch (error) {
      showToast(`添加地形线失败: ${error}`);
    }
  }

  // 基于缩放的颜色插值
  private updateWaterColorOnZoom(): void {
    if (!this.mapController) return;
    
    try {
      // OpenFreeMap bright 样式中的水体图层（LineLayer类型）
      const waterLayerIds = [
        'waterway-stream-canal',
        'waterway-other',
        'waterway_tunnel',
        'water'
      ];
      let found = false;
      
      for (const layerId of waterLayerIds) {
        const waterLayer = this.mapController.getLayer(layerId);
        
        // 创建基于缩放的颜色插值表达式
        const colorExpr = Expression.interpolate(
          Expression.linear(),
          Expression.zoom(),
          Expression.literal(1), Expression.literal('#00FF00'),  // 绿色
          Expression.literal(4), Expression.literal('#0000FF'),  // 蓝色
          Expression.literal(12), Expression.literal('#FF0000'), // 红色
          Expression.literal(20), Expression.literal('#000000')  // 黑色
        ) as Expression<string>;
        
        if (waterLayer instanceof FillLayer) {
          waterLayer.setFillColor(colorExpr);
          showToast(`水体图层 "${layerId}" (Fill) 颜色随缩放变化`);
          this.mapController.jumpTo(0, 52.379189, 4.899431, 0, 1);
          found = true;
          break;
        } else if (waterLayer instanceof LineLayer) {
          waterLayer.setLineColor(colorExpr);
          showToast(`水体图层 "${layerId}" (Line) 颜色随缩放变化`);
          this.mapController.jumpTo(0, 52.379189, 4.899431, 0, 1);
          found = true;
          break;
        }
      }
      
      if (!found) {
        showToast('未找到水体图层（water/waterway）');
      }
    } catch (error) {
      showToast(`设置颜色插值失败: ${error}`);
    }
  }

  // 添加自定义瓦片数据源
  private addCustomTileSource(): void {
    if (!this.mapController) return;
    
    try {
      // 添加自定义矢量瓦片源
      const source = new VectorSource('custom-tile-source');
      source.setUrl('https://d25uarhxywzl1j.cloudfront.net/v0.1/{z}/{x}/{y}.mvt');
      this.mapController.addSource(source);
      
      // 添加线图层
      const layer = new LineLayer('custom-tile-layers', 'custom-tile-source');
      layer.setSourceLayer('mapillary-sequences');
      layer.setLineColor('#00FF00'); // 绿色（CSS 格式）
      layer.setLineWidth(2);
      layer.setLineOpacity(0.6);
      
      this.mapController.addLayer(layer);
      showToast('自定义瓦片图层已添加');
    } catch (error) {
      showToast(`添加自定义瓦片失败: ${error}`);
    }
  }

  // 将水体图层移到最前面
  private bringWaterToFront(): void {
    if (!this.mapController) return;
    
    try {
      // OpenFreeMap bright 样式中的水体图层（LineLayer类型）
      const waterLayerIds = [
        'waterway-stream-canal',
        'waterway-other',
        'waterway_tunnel',
        'water'
      ];
      let found = false;
      
      for (const layerId of waterLayerIds) {
        const waterLayer = this.mapController.getLayer(layerId);
        if (waterLayer) {
          // 移除后重新添加到顶部
          this.mapController.removeLayer(layerId);
          this.mapController.addLayer(waterLayer);
          showToast(`水体图层 "${layerId}" 已置顶`);
          found = true;
          break;
        }
      }
      
      if (!found) {
        showToast('未找到水体图层（water/waterway）');
      }
    } catch (error) {
      showToast(`置顶图层失败: ${error}`);
    }
  }

  // 切换测试图层
  private toggleTestLayer(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('test-fill-layer');
      if (layer) {
        // 如果存在则删除
        this.mapController.removeLayer('test-fill-layer');
        this.mapController.removeSource('test-fill-source');
        showToast('测试图层已移除');
      } else {
        // 不存在则添加
        const source = new GeoJsonSource('test-fill-source');
        const geojson = GeoJson.featureCollection([
          GeoJson.polygonFeature([[
            [4.8, 52.3],
            [4.9, 52.3],
            [4.9, 52.4],
            [4.8, 52.4],
            [4.8, 52.3]
          ]])
        ]);
        source.setGeoJson(geojson);
        this.mapController.addSource(source);
        
        const fillLayer = new FillLayer('test-fill-layer', 'test-fill-source');
        fillLayer.setFillColor('#33B5E5'); // 青蓝色（CSS 格式）
        fillLayer.setFillOpacity(0.5); // 透明度 0.5（对应 ARGB 的 0x80）
        this.mapController.addLayer(fillLayer);
        
        showToast('测试图层已添加');
      }
    } catch (error) {
      showToast(`切换测试图层失败: ${error}`);
    }
  }
}

