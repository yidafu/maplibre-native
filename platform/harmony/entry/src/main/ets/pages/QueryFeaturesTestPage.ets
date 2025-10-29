/**
 * QueryFeaturesTestPage - 特性查询测试页面
 * 
 * 测试接口：
 * - queryRenderedFeaturesForPoint() - 点查询
 * - queryRenderedFeaturesForBox() - 矩形查询
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { maplibre } from 'maplibre_harmony';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';

@Entry
@Component
struct QueryFeaturesTestPage {
  @State statusMessage: string = '点击地图或使用按钮查询要素';
  @State mapReady: boolean = false;
  @State queryResult: string = '';
  @State featureCount: number = 0;
  
  private mapView: maplibre.NativeMapView | null = null;
  private map: MapLibreMap | null = null;

  /**
   * 地图区域构建器
   */
  @Builder
  MapAreaBuilder() {
    NativeMapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 12,
      initialBearing: 0,
      initialPitch: 0,
      onMapReady: (mapView?: maplibre.NativeMapView, map?: MapLibreMap) => {
        this.onMapReady(mapView, map);
      }
    })
    .width('100%')
    .height('100%')
  }

  /**
   * 控制区域构建器
   */
  @Builder
  ControlAreaBuilder() {
    // 状态信息
    Text(this.statusMessage)
      .fontSize(14)
      .width('100%')
      .padding(12)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
    
    // 查询结果
    if (this.queryResult) {
      Text(this.queryResult)
        .fontSize(12)
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF3E0')
        .borderRadius(4)
        .fontColor('#E65100')
        .maxLines(8)
    }
    
    // 功能说明
    Text('功能说明')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Text('• 使用按钮查询地图中心和全屏区域的要素')
      .fontSize(13)
      .width('100%')
      .fontColor('#666666')
    
    Divider()
    
    // 查询测试
    Text('区域查询测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('查询中心区域')
        .width('48%')
        .onClick(() => {
          this.handleQueryCenterBox();
        })
        .enabled(this.mapReady)
      
      Button('查询全屏')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.handleQueryFullScreen();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Button('清除结果')
      .width('100%')
      .onClick(() => {
        this.handleClearResults();
      })
  }
  
  /**
   * 处理查询中心区域（包装方法）
   */
  private handleQueryCenterBox(): void {
    this.queryCenterBox();
  }
  
  /**
   * 处理查询全屏（包装方法）
   */
  private handleQueryFullScreen(): void {
    this.queryFullScreen();
  }
  
  /**
   * 处理清除结果（包装方法）
   */
  private handleClearResults(): void {
    this.clearResults();
  }

  build() {
    Column() {
      TestPageLayout({
        title: '特性查询测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 地图就绪回调
   */
  private onMapReady(mapView?: maplibre.NativeMapView, map?: MapLibreMap): void {
    if (mapView && map) {
      this.mapView = mapView;
      this.map = map;
      this.mapReady = true;
      this.statusMessage = '✅ 地图加载成功，使用按钮查询要素';
      hilog.info(DOMAIN, 'QueryFeaturesTestPage', 'Map ready');
    }
  }

  /**
   * 查询中心区域
   */
  private queryCenterBox(): void {
    if (!this.map || !this.mapView) return;
    
    try {
      // 获取地图中心点像素坐标
      const centerLatLng: maplibre.LatLng = this.mapView.getLatLng();
      const zoom: number = this.mapView.getZoom();
      
      // 获取地图尺寸（假设是 400x400 的中心区域）
      const centerX: number = 200; // 屏幕中心 X
      const centerY: number = 200; // 屏幕中心 Y
      const boxSize = 100; // 查询区域半径
      
      // 查询中心区域的要素
      const features = this.map.queryRenderedFeaturesForBox(
        centerX - boxSize,
        centerY - boxSize,
        centerX + boxSize,
        centerY + boxSize
      );
      
      this.featureCount = features.length;
      
      if (features.length > 0) {
        // 显示前 5 个要素的信息
        const featureInfo = features.slice(0, 5).map((feature, index) => {
          const props = feature.getProperties();
          const propKeys = Object.keys(props);
          const firstProp = propKeys.length > 0 ? `${propKeys[0]}: ${props[propKeys[0]]}` : 'No properties';
          const geometry = feature.getGeometry();
          const geomType = geometry ? 'Feature' : 'Unknown';
          return `${index + 1}. ${geomType} - ${firstProp}`;
        }).join('\n');
        
        this.queryResult = `✅ 找到 ${features.length} 个要素\n\n` +
          `中心位置: ${centerLatLng.latitude.toFixed(4)}°, ${centerLatLng.longitude.toFixed(4)}°\n` +
          `缩放级别: ${zoom.toFixed(2)}\n\n` +
          `前 ${Math.min(5, features.length)} 个要素:\n${featureInfo}`;
      } else {
        this.queryResult = `⚠️ 未找到要素\n\n` +
          `中心位置: ${centerLatLng.latitude.toFixed(4)}°, ${centerLatLng.longitude.toFixed(4)}°\n` +
          `缩放级别: ${zoom.toFixed(2)}\n\n` +
          `提示: 尝试缩放地图或移动到有要素的区域`;
      }
      
      this.statusMessage = `✅ 查询完成，找到 ${features.length} 个要素`;
      
      hilog.info(DOMAIN, 'QueryFeaturesTestPage', 
        `Center box query - Found ${features.length} features`);
    } catch (error) {
      this.statusMessage = `❌ 查询失败: ${error.message}`;
      this.queryResult = `❌ 错误: ${error.message}`;
      hilog.error(DOMAIN, 'QueryFeaturesTestPage', `Query failed: ${error.message}`);
    }
  }

  /**
   * 查询全屏
   */
  private queryFullScreen(): void {
    if (!this.map || !this.mapView) return;
    
    try {
      // 查询全屏区域的要素（假设屏幕尺寸）
      // 在实际应用中，应该从组件获取实际的屏幕尺寸
      const screenWidth = 400;
      const screenHeight = 800;
      
      const features = this.map.queryRenderedFeaturesForBox(
        0, 0, screenWidth, screenHeight
      );
      
      this.featureCount = features.length;
      
      const centerLatLng: maplibre.LatLng = this.mapView.getLatLng();
      const zoom: number = this.mapView.getZoom();
      const bearing: number = this.mapView.getBearing();
      const pitch: number = this.mapView.getPitch();
      
      if (features.length > 0) {
        // 统计要素类型
        const typeCount: Record<string, number> = {};
        features.forEach(feature => {
          const geometry = feature.getGeometry();
          const type = geometry ? 'Feature' : 'Unknown';
          typeCount[type] = (typeCount[type] || 0) + 1;
        });
        
        const typeInfo = Object.entries(typeCount)
          .map((entry) => {
            const type = entry[0];
            const count = entry[1];
            return `  ${type}: ${count}`;
          })
          .join('\n');
        
        this.queryResult = `✅ 全屏查询结果\n\n` +
          `总要素数: ${features.length}\n\n` +
          `要素类型分布:\n${typeInfo}\n\n` +
          `地图状态:\n` +
          `  中心: ${centerLatLng.latitude.toFixed(4)}°, ${centerLatLng.longitude.toFixed(4)}°\n` +
          `  缩放: ${zoom.toFixed(2)}\n` +
          `  方位: ${bearing.toFixed(1)}°\n` +
          `  倾斜: ${pitch.toFixed(1)}°`;
      } else {
        this.queryResult = `⚠️ 全屏未找到要素\n\n` +
          `地图状态:\n` +
          `  中心: ${centerLatLng.latitude.toFixed(4)}°, ${centerLatLng.longitude.toFixed(4)}°\n` +
          `  缩放: ${zoom.toFixed(2)}\n` +
          `  方位: ${bearing.toFixed(1)}°\n` +
          `  倾斜: ${pitch.toFixed(1)}°\n\n` +
          `提示: 等待地图加载完成或缩放到合适级别`;
      }
      
      this.statusMessage = `✅ 全屏查询完成，找到 ${features.length} 个要素`;
      
      hilog.info(DOMAIN, 'QueryFeaturesTestPage', 
        `Full screen query - Found ${features.length} features`);
    } catch (error) {
      this.statusMessage = `❌ 查询失败: ${error.message}`;
      this.queryResult = `❌ 错误: ${error.message}`;
      hilog.error(DOMAIN, 'QueryFeaturesTestPage', `Query failed: ${error.message}`);
    }
  }

  /**
   * 清除查询结果
   */
  private clearResults(): void {
    this.queryResult = '';
    this.featureCount = 0;
    this.statusMessage = '已清除结果，点击地图继续查询';
  }
}

