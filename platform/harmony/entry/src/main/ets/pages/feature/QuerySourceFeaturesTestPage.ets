/**
 * Query Source Features Test Page
 * 查询数据源要素
 * 参考 Android: QuerySourceFeaturesActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { GeoJson, GeoJsonSource, LatLng, MapLibreMap, MapView, ScreenPoint, CircleLayer } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';
import type { IFeature } from 'maplibre_harmony/src/main/ets/maps/geojson/types';

@Entry
@Component
struct QuerySourceFeaturesTestPage {
  private mapController: MapLibreMap | null = null;
  @State private sourceFeatureCount: number = 0;
  @State private queriedFeatures: IFeature[] = [];
  @State private queryInfo: string = '点击按钮查询数据源';
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Query Source Features',
      description: '查询数据源中的要素',
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
      initialZoom: 5,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 6);
        this.addTestSource(map);
      }
    })
  }

  private addTestSource(map: MapLibreMap): void {
    // 添加测试 GeoJSON 数据源，包含多个测试点
    const props1: Record<string, Object> = { 'name': '北京', 'type': 'city', 'population': 21540000 };
    const props2: Record<string, Object> = { 'name': '天津', 'type': 'city', 'population': 13870000 };
    const props3: Record<string, Object> = { 'name': '石家庄', 'type': 'city', 'population': 11040000 };
    const props4: Record<string, Object> = { 'name': '太原', 'type': 'city', 'population': 5300000 };
    
    const geojsonData = GeoJson.featureCollection([
      GeoJson.pointFeature([116.4074, 39.9042], props1),
      GeoJson.pointFeature([117.2008, 39.0842], props2),
      GeoJson.pointFeature([114.5149, 38.0428], props3),
      GeoJson.pointFeature([112.5489, 37.8706], props4)
    ]);
    
    try {
      const source = new GeoJsonSource('test-source');
      source.setGeoJson(geojsonData);
      map.addSource(source);
      
      // 添加一个圆形图层来可视化这些点
      const layer = new CircleLayer('test-layer', 'test-source');
      layer.setCircleRadius(8);
      layer.setCircleColor('#FF5722');
      layer.setCircleOpacity(0.8);
      layer.setCircleStrokeWidth(2);
      layer.setCircleStrokeColor('#FFFFFF');
      map.addLayer(layer);
      
      this.sourceFeatureCount = 4;
      console.info(`[QuerySourceFeatures] Added ${this.sourceFeatureCount} features to test-source`);
    } catch (error) {
      console.error(`添加数据源失败: ${error}`);
    }
  }

  @Builder
  buildActionButtons() {
    Column({ space: 8 }) {
      // 数据源信息展示
      Column({ space: 4 }) {
        Text('数据源信息')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Row({ space: 16 }) {
          Text(`数据源: ${this.sourceFeatureCount}`)
            .fontSize(12)
            .fontColor('#666')
          
          Text(`查询: ${this.queriedFeatures.length}`)
            .fontSize(12)
            .fontColor('#2196F3')
        }
        .width('100%')
        
        Text(this.queryInfo)
          .fontSize(11)
          .fontColor('#999')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 4 })
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#f5f5f5')
      .borderRadius(4)
      .margin({ bottom: 8 })
      
      // GeoJSON 数据源测试
      Text('GeoJSON 数据源测试')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 4, bottom: 4 })
      
      Button('查询 GeoJSON 所有要素')
        .width('100%')
        .fontSize(12)
        .onClick(() => {
          this.queryAllFeatures();
        })
      
      Button('查询 GeoJSON 城市类型')
        .width('100%')
        .fontSize(12)
        .onClick(() => {
          this.queryGeoJsonWithFilter();
        })
      
      // Vector Tile 数据源测试
      Text('Vector Tile 数据源测试')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Button('查询 place 图层城市')
        .width('100%')
        .fontSize(12)
        .onClick(() => {
          this.queryPlaceCities();
        })
      
      Button('查询 place 图层城镇')
        .width('100%')
        .fontSize(12)
        .onClick(() => {
          this.queryPlaceTowns();
        })
      
      Button('查询 poi 图层')
        .width('100%')
        .fontSize(12)
        .onClick(() => {
          this.queryPOIs();
        })
      
      Button('清除查询结果')
        .width('100%')
        .fontSize(12)
        .onClick(() => {
          this.clearQueryResults();
        })
      
      // 要素列表展示
      if (this.queriedFeatures.length > 0) {
        Divider()
          .margin({ top: 8, bottom: 8 })
        
        Text('要素列表')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Column({ space: 4 }) {
          ForEach(this.queriedFeatures.slice(0, 20), (feature: IFeature, index: number) => {
            Column({ space: 4 }) {
              Text(`Feature ${index + 1}`)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
              
              Text(`几何类型: ${feature.geometry.type}`)
                .fontSize(11)
                .fontColor('#666')
              
              if (feature.properties) {
                // 显示 name 属性
                if (feature.properties['name']) {
                  Text(`名称: ${feature.properties['name']}`)
                    .fontSize(11)
                    .fontColor('#666')
                }
                
                // 显示 class 属性
                if (feature.properties['class']) {
                  Text(`类别: ${feature.properties['class']}`)
                    .fontSize(11)
                    .fontColor('#666')
                }
                
                // 显示 type 属性
                if (feature.properties['type']) {
                  Text(`类型: ${feature.properties['type']}`)
                    .fontSize(11)
                    .fontColor('#666')
                }
                
                // 显示 rank 属性
                if (feature.properties['rank'] !== undefined) {
                  Text(`等级: ${feature.properties['rank']}`)
                    .fontSize(11)
                    .fontColor('#666')
                }
                
                // 显示 population 属性
                if (feature.properties['population']) {
                  Text(`人口: ${feature.properties['population']}`)
                    .fontSize(11)
                    .fontColor('#666')
                }
              }
              
              if (feature.id !== undefined) {
                Text(`ID: ${feature.id}`)
                  .fontSize(11)
                  .fontColor('#999')
              }
            }
            .width('100%')
            .padding(8)
            .backgroundColor('#f5f5f5')
            .borderRadius(4)
          }, (feature: IFeature, index: number) => `feature-${index}`)
        }
        .width('100%')
        .height(300)
        
        if (this.queriedFeatures.length > 20) {
          Text(`显示前 20 条，共 ${this.queriedFeatures.length} 条`)
            .fontSize(11)
            .fontColor('#999')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 8 })
        }
      }
    }
    .width('100%')
  }

  /**
   * 查询所有要素
   */
  private queryAllFeatures(): void {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 使用 MapLibreMap.querySourceFeatures 查询所有要素
      const features = this.mapController.querySourceFeatures('test-source');
      this.queriedFeatures = features;
      this.queryInfo = `成功查询到 ${features.length} 个要素`;
      
      showToast(`查询到 ${features.length} 个要素`);
      console.info(`[QuerySourceFeatures] Queried ${features.length} features`);
      
      // 打印详细信息
      features.forEach((feature: IFeature, index: number) => {
        console.info(`[QuerySourceFeatures] Feature ${index}:`, JSON.stringify(feature.properties));
      });
    } catch (error) {
      const errorMsg = `查询失败: ${error}`;
      showToast(errorMsg);
      this.queryInfo = errorMsg;
      console.error(`[QuerySourceFeatures] Query failed: ${error}`);
    }
  }

  /**
   * 使用过滤器查询 GeoJSON 要素
   */
  private queryGeoJsonWithFilter(): void {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 使用 filter 参数查询符合条件的要素
      // filter 格式: ["==", ["get", "type"], "city"]
      const features = this.mapController.querySourceFeatures('test-source', undefined, ["==", ["get", "type"], "city"]);
      
      this.queriedFeatures = features;
      this.queryInfo = `GeoJSON: 使用 filter 成功查询到 ${features.length} 个城市类型要素`;
      
      showToast(`查询到 ${features.length} 个城市`);
      console.info(`[QuerySourceFeatures] Queried ${features.length} city features with filter`);
      
      // 打印详细信息
      features.forEach((feature: IFeature, index: number) => {
        console.info(`[QuerySourceFeatures] Filtered Feature ${index}:`, JSON.stringify(feature.properties));
      });
    } catch (error) {
      const errorMsg = `过滤查询失败: ${error}`;
      showToast(errorMsg);
      this.queryInfo = errorMsg;
      console.error(`[QuerySourceFeatures] Filtered query failed: ${error}`);
    }
  }

  /**
   * 查询 place 图层中的城市
   */
  private queryPlaceCities(): void {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 查询 openmaptiles 数据源的 place 图层中 class=city 的要素
      const features = this.mapController.querySourceFeatures(
        'openmaptiles',
        ['place'],  // 指定 source-layer
        ["==", ["get", "class"], "city"]
      );
      
      this.queriedFeatures = features;
      this.queryInfo = `Vector Tile: 在 place 图层查询到 ${features.length} 个城市`;
      
      showToast(`查询到 ${features.length} 个城市`);
      console.info(`[QuerySourceFeatures] Queried ${features.length} cities from place layer`);
      
      // 打印详细信息（前 10 个）
      features.slice(0, 10).forEach((feature: IFeature, index: number) => {
        const name = feature.properties?.['name'] || feature.properties?.['name_en'] || 'Unknown';
        const classType = feature.properties?.['class'];
        console.info(`[QuerySourceFeatures] City ${index}: ${name} (class: ${classType})`);
      });
    } catch (error) {
      const errorMsg = `查询城市失败: ${error}`;
      showToast(errorMsg);
      this.queryInfo = errorMsg;
      console.error(`[QuerySourceFeatures] Query cities failed: ${error}`);
    }
  }

  /**
   * 查询 place 图层中的城镇
   */
  private queryPlaceTowns(): void {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 查询 openmaptiles 数据源的 place 图层中 class=town 的要素
      const features = this.mapController.querySourceFeatures(
        'openmaptiles',
        ['place'],
        ["==", ["get", "class"], "town"]
      );
      
      this.queriedFeatures = features;
      this.queryInfo = `Vector Tile: 在 place 图层查询到 ${features.length} 个城镇`;
      
      showToast(`查询到 ${features.length} 个城镇`);
      console.info(`[QuerySourceFeatures] Queried ${features.length} towns from place layer`);
      
      // 打印详细信息（前 10 个）
      features.slice(0, 10).forEach((feature: IFeature, index: number) => {
        const name = feature.properties?.['name'] || feature.properties?.['name_en'] || 'Unknown';
        console.info(`[QuerySourceFeatures] Town ${index}: ${name}`);
      });
    } catch (error) {
      const errorMsg = `查询城镇失败: ${error}`;
      showToast(errorMsg);
      this.queryInfo = errorMsg;
      console.error(`[QuerySourceFeatures] Query towns failed: ${error}`);
    }
  }

  /**
   * 查询 POI 图层
   */
  private queryPOIs(): void {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 查询 openmaptiles 数据源的 poi 图层中 rank >= 7 的要素
      const features = this.mapController.querySourceFeatures(
        'openmaptiles',
        ['poi'],
        [">=", ["get", "rank"], 7]
      );
      
      this.queriedFeatures = features;
      this.queryInfo = `Vector Tile: 在 poi 图层查询到 ${features.length} 个 POI (rank >= 7)`;
      
      showToast(`查询到 ${features.length} 个 POI`);
      console.info(`[QuerySourceFeatures] Queried ${features.length} POIs from poi layer`);
      
      // 打印详细信息（前 10 个）
      features.slice(0, 10).forEach((feature: IFeature, index: number) => {
        const name = feature.properties?.['name'] || 'Unknown';
        const classType = feature.properties?.['class'];
        const rank = feature.properties?.['rank'];
        console.info(`[QuerySourceFeatures] POI ${index}: ${name} (class: ${classType}, rank: ${rank})`);
      });
    } catch (error) {
      const errorMsg = `查询 POI 失败: ${error}`;
      showToast(errorMsg);
      this.queryInfo = errorMsg;
      console.error(`[QuerySourceFeatures] Query POIs failed: ${error}`);
    }
  }

  /**
   * 清除查询结果
   */
  private clearQueryResults(): void {
    this.queriedFeatures = [];
    this.queryInfo = '已清除查询结果';
    showToast('查询结果已清除');
    console.info('[QuerySourceFeatures] Query results cleared');
  }
}
