/**
 * Polyline Test Page
 * 折线注解测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/annotation/PolylineActivity.kt
 * 
 * 功能:
 * - 添加折线注解（使用 GeoJSON Source + LineLayer）
 * - 修改折线属性（颜色、宽度、透明度）
 * - 批量添加/删除折线
 * - 折线点击事件
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { 
  MapLibreMap, 
  MapView, 
  Polyline,
  LatLng
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG  } from '../common/TestUtils';

interface PolylineConfig {
  start: number[]
  end: number[]
  color: string;
  id: string;
}

@Entry
@Component
struct PolylineTestPage {
  private mapController: MapLibreMap | null = null;
  private currentPolylines: Polyline[] = [];
  private currentPolylineIds: number[] = [];
  
  @State private currentColor: string = '#F44336';
  @State private currentWidth: number = 3.0;
  @State private currentAlpha: number = 1.0;
  @State private polylineCount: number = 0;
  
  // 欧洲小国坐标
  private readonly ANDORRA: number[] = [1.52529, 42.505777]
  private readonly LUXEMBOURG: number[] = [6.129583, 49.815273]
  private readonly MONACO: number[] = [7.424616, 43.738418]
  private readonly VATICAN_CITY: number[] = [12.453389, 41.902916]
  private readonly SAN_MARINO: number[] = [12.457777, 43.942360]
  private readonly LIECHTENSTEIN: number[] = [9.555373, 47.166000]
  
  // 所有折线配置
  private polylines: PolylineConfig[] = [
    { start: this.ANDORRA, end: this.LUXEMBOURG, color: '#F44336', id: 'line-1' } as PolylineConfig,
    { start: this.ANDORRA, end: this.MONACO, color: '#FF5722', id: 'line-2' } as PolylineConfig,
    { start: this.MONACO, end: this.VATICAN_CITY, color: '#673AB7', id: 'line-3' } as PolylineConfig,
    { start: this.VATICAN_CITY, end: this.SAN_MARINO, color: '#009688', id: 'line-4' } as PolylineConfig,
    { start: this.SAN_MARINO, end: this.LIECHTENSTEIN, color: '#795548', id: 'line-5' } as PolylineConfig,
    { start: this.LIECHTENSTEIN, end: this.LUXEMBOURG, color: '#3F51B5', id: 'line-6' } as PolylineConfig
  ]
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[PolylineTestPage] onMapReady');
    this.mapController = map;
    
    // 设置初始位置（欧洲中心）
    // map.jumpTo(0, 39.9, 116.4, 0, 6);
    
    // 添加所有折线
    this.addAllPolylines();
  };
  
  /**
   * 添加所有折线
   */
  private addAllPolylines = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 清除现有折线
      this.clearAllPolylines();
      
      // 创建折线对象数组
      this.currentPolylines = this.polylines.map((line: PolylineConfig): Polyline => {
        return new Polyline({
          points: [
            new LatLng(line.start[1], line.start[0]),
            new LatLng(line.end[1], line.end[0])
          ],
          color: line.color,
          width: this.currentWidth,
          alpha: this.currentAlpha
        });
      });
      
      // 批量添加折线，获取 ID 数组
      this.currentPolylineIds = this.mapController.addPolylines(this.currentPolylines);
      
      // 为每个 Polyline 设置 ID
      for (let i = 0; i < this.currentPolylines.length; i++) {
        this.currentPolylines[i].setId(this.currentPolylineIds[i]);
      }
      
      this.polylineCount = this.currentPolylines.length;
      showToast(`已添加 ${this.polylineCount} 条折线`);
    } catch (error) {
      console.error(`添加折线失败: ${error}`);
      showToast(`添加失败: ${error}`);
    }
  };
  
  /**
   * 生成中国范围内的随机坐标
   * 中国经纬度范围：东经 73° - 135°，北纬 18° - 53°
   */
  private generateRandomChinaCoordinate = (): number[] => {
    const minLng = 73.0;   // 最小经度（东经）
    const maxLng = 135.0;  // 最大经度（东经）
    const minLat = 18.0;   // 最小纬度（北纬）
    const maxLat = 53.0;   // 最大纬度（北纬）
    
    const lng = minLng + Math.random() * (maxLng - minLng);
    const lat = minLat + Math.random() * (maxLat - minLat);
    
    return [lng, lat];
  };
  
  /**
   * 添加随机折线（坐标落在中国范围内，2-5个点）
   */
  private addRandomPolyline = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 随机生成2-5个点
      const pointCount = Math.floor(Math.random() * 4) + 2; // 2-5个点
      const points: LatLng[] = [];
      
      for (let i = 0; i < pointCount; i++) {
        const coord = this.generateRandomChinaCoordinate();
        points.push(new LatLng(coord[1], coord[0])); // LatLng(纬度, 经度)
      }
      
      // 随机选择颜色
      const colors = ['#F44336', '#FF5722', '#673AB7', '#009688', '#795548', '#3F51B5', '#FFC107', '#00BCD4'];
      const randomColor = colors[Math.floor(Math.random() * colors.length)];
      
      // 创建折线对象
      const polyline = new Polyline({
        points: points,
        color: randomColor,
        width: this.currentWidth,
        alpha: this.currentAlpha
      });
      
      // 添加折线，获取 ID
      const newPolylineIds = this.mapController.addPolylines([polyline]);
      polyline.setId(newPolylineIds[0]);
      
      // 将新折线添加到现有列表中（不清除原有的）
      this.currentPolylines.push(polyline);
      this.currentPolylineIds.push(newPolylineIds[0]);
      
      this.polylineCount = this.currentPolylines.length;
      
      // 格式化点坐标信息
      let pointsInfo = '';
      for (let i = 0; i < points.length; i++) {
        pointsInfo += `点${i + 1}: (${points[i].longitude.toFixed(2)}, ${points[i].latitude.toFixed(2)})\n`;
      }
      
      showToast(`已添加随机折线 (${pointCount}个点)\n${pointsInfo}当前总数: ${this.polylineCount}`);
    } catch (error) {
      console.error(`添加折线失败: ${error}`);
      showToast(`添加失败: ${error}`);
    }
  };
  
  /**
   * 清除所有折线
   */
  private clearAllPolylines = (): void => {
    if (!this.mapController) return;
    
    try {
      // 移除所有折线
      if (this.currentPolylineIds.length > 0) {
        this.mapController.removeAnnotations(this.currentPolylineIds);
        this.currentPolylineIds = [];
        this.currentPolylines = [];
      }
      
      this.polylineCount = 0;
    } catch (error) {
      console.error(`清除折线失败: ${error}`);
    }
  };
  
  /**
   * 切换透明度
   */
  private toggleAlpha = (): void => {
    this.currentAlpha = this.currentAlpha === 1.0 ? 0.5 : 1.0;
    
    // 更新所有当前折线的透明度
    if (this.mapController && this.currentPolylines.length > 0) {
      try {
        for (const polyline of this.currentPolylines) {
          console.info(`[PolylineTestPage] Updating polyline alpha, id=${polyline.getId()}`);
          polyline.setAlpha(this.currentAlpha);
          this.mapController.updatePolyline(polyline);
        }
        showToast(`透明度: ${(this.currentAlpha * 100).toFixed(0)}%`);
      } catch (error) {
        console.error(`[PolylineTestPage] toggleAlpha failed: ${error}`);
        showToast(`更新失败: ${error}`);
      }
    } else {
      showToast(`透明度: ${(this.currentAlpha * 100).toFixed(0)}%`);
    }
  };
  
  /**
   * 切换颜色
   */
  private toggleColor = (): void => {
    if (!this.mapController || this.currentPolylines.length === 0) return;
    
    try {
      this.currentColor = this.currentColor === '#F44336' ? '#2196F3' : '#F44336';
      
      // 更新所有当前折线的颜色
      for (const polyline of this.currentPolylines) {
        console.info(`[PolylineTestPage] Updating polyline color, id=${polyline.getId()}`);
        polyline.setColor(this.currentColor);
        this.mapController.updatePolyline(polyline);
      }
      
      showToast(`颜色已更改`);
    } catch (error) {
      console.error(`[PolylineTestPage] toggleColor failed: ${error}`);
      showToast(`更新失败: ${error}`);
    }
  };
  
  /**
   * 切换宽度
   */
  private toggleWidth = (): void => {
    if (!this.mapController || this.currentPolylines.length === 0) return;
    
    try {
      this.currentWidth = this.currentWidth === 3.0 ? 5.0 : 3.0;
      
      // 更新所有当前折线的宽度
      for (const polyline of this.currentPolylines) {
        console.info(`[PolylineTestPage] Updating polyline width, id=${polyline.getId()}`);
        polyline.setWidth(this.currentWidth);
        this.mapController.updatePolyline(polyline);
      }
      
      showToast(`宽度: ${this.currentWidth}px`);
    } catch (error) {
      console.error(`[PolylineTestPage] toggleWidth failed: ${error}`);
      showToast(`更新失败: ${error}`);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Column({ space: 8 }) {
      // 折线属性信息展示区
      Column({ space: 4 }) {
        Text('折线属性')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%');
        
        Text(`数量: ${this.polylineCount}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%');
        
        Text(`颜色: ${this.currentColor}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%');
        
        Text(`宽度: ${this.currentWidth}px`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%');
        
        Text(`透明度: ${(this.currentAlpha * 100).toFixed(0)}%`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%');
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(8)
      .backgroundColor('#FFFFFF')
      .borderRadius(4)
      
      // 分隔线
      Divider()
        .color('#E0E0E0')
        .strokeWidth(1)
      
      // 操作按钮区
      Column({ space: 8 }) {
        Button('所有折线')
          .fontSize(14)
          .width('100%')
          .onClick(this.addAllPolylines);
        
        Button('随机折线')
          .fontSize(14)
          .width('100%')
          .onClick(this.addRandomPolyline);
        
        Button('透明度')
          .fontSize(14)
          .width('100%')
          .onClick(this.toggleAlpha);
        
        Button('颜色')
          .fontSize(14)
          .width('100%')
          .onClick(this.toggleColor);
        
        Button('宽度')
          .fontSize(14)
          .width('100%')
          .onClick(this.toggleWidth);
        
        Button('清除')
          .fontSize(14)
          .width('100%')
          .backgroundColor('#F44336')
          .onClick(() => {
            this.clearAllPolylines();
            showToast('已清除所有折线');
          });
      }
      .width('100%')
    }
    .width('100%')
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: this.onMapReady,
      initialLatitude: 30.9,
      initialLongitude: 120.4,
      initialZoom: 5
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Polyline',
        description: '折线注解',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}

