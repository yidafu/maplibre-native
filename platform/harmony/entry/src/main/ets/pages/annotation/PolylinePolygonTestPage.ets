import { Polygon, Polyline, MapView, MapLibreMap, LatLng } from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

/**
 * PolylinePolygonTestPage - 折线/多边形注解测试页面
 * 
 * 测试接口：
 * - addPolylines() - 添加折线
 * - addPolygons() - 添加多边形
 * - updatePolyline() - 更新折线
 * - updatePolygon() - 更新多边形
 * - removeAnnotations() - 删除注解
 * 
 * C++ 层已完全实现
 */

@Entry
@Component
struct PolylinePolygonTestPage {
  @State statusMessage: string = '地图初始化中...';
  @State mapReady: boolean = false;
  @State polylineCount: number = 0;
  @State polygonCount: number = 0;
  
  private mapController: MapLibreMap | null = null;
  private polylines: Polyline[] = [];
  private polygons: Polygon[] = [];

  /**
   * 地图就绪回调
   */
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[PolylinePolygonTestPage] onMapReady');
    this.mapController = map;
    this.mapReady = true;
    
    // 设置初始位置（中国中心）
    map.jumpTo(0, 35.0, 110.0, 0, 4);
    
    this.statusMessage = '✅ 地图已就绪';
    showToast('地图已就绪');
  };

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 35.0,
      initialLongitude: 110.0,
      initialZoom: 4,
      initialBearing: 0,
      initialPitch: 0,
      onMapReady: this.onMapReady
    })
  }

  /**
   * 操作按钮构建器
   */
  @Builder
  buildActionButtons() {
    // 状态信息
    Column() {
      Text(this.statusMessage)
        .fontSize(12)
        .margin({ bottom: 2 })
      
      Text(`折线: ${this.polylineCount} | 多边形: ${this.polygonCount}`)
        .fontSize(12)
        .fontColor('#666')
    }
    .width('100%')
    .backgroundColor('#F8F8F8')
    .padding(8)
    .borderRadius(4)
    .margin({ bottom: 8 })
    
    // 折线操作按钮
    Row() {
      Button('添加折线')
        .fontSize(12)
        .layoutWeight(1)
        .backgroundColor('#2196F3')
        .onClick(() => {
          this.addPolyline();
        })
        .enabled(this.mapReady)
      
      Button('更新折线')
        .fontSize(12)
        .layoutWeight(1)
        .margin({ left: 8 })
        .backgroundColor('#FF9800')
        .onClick(() => {
          this.updatePolyline();
        })
        .enabled(this.mapReady && this.polylines.length > 0)
      
      Button('清除折线')
        .fontSize(12)
        .layoutWeight(1)
        .margin({ left: 8 })
        .backgroundColor('#F44336')
        .onClick(() => {
          this.clearPolylines();
        })
        .enabled(this.mapReady && this.polylines.length > 0)
    }
    .width('100%')
    .margin({ bottom: 8 })
    
    // 多边形操作按钮
    Row() {
      Button('添加多边形')
        .fontSize(12)
        .layoutWeight(1)
        .backgroundColor('#4CAF50')
        .onClick(() => {
          this.addPolygon();
        })
        .enabled(this.mapReady)
      
      Button('更新多边形')
        .fontSize(12)
        .layoutWeight(1)
        .margin({ left: 8 })
        .backgroundColor('#FFC107')
        .onClick(() => {
          this.updatePolygon();
        })
        .enabled(this.mapReady && this.polygons.length > 0)
      
      Button('清除多边形')
        .fontSize(12)
        .layoutWeight(1)
        .margin({ left: 8 })
        .backgroundColor('#F44336')
        .onClick(() => {
          this.clearPolygons();
        })
        .enabled(this.mapReady && this.polygons.length > 0)
    }
    .width('100%')
    .margin({ bottom: 8 })
    
    // 清除全部按钮
    Button('清除全部')
      .fontSize(12)
      .width('100%')
      .backgroundColor('#9E9E9E')
      .onClick(() => {
        this.clearAllAnnotations();
      })
      .enabled(this.mapReady && (this.polylines.length > 0 || this.polygons.length > 0))
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: '折线/多边形注解',
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 生成中国境内的随机坐标
   * 中国经纬度范围：东经 73° - 135°，北纬 18° - 53°
   */
  private generateRandomChinaCoordinate(): LatLng {
    const minLng = 73.0;   // 最小经度（东经）
    const maxLng = 135.0;  // 最大经度（东经）
    const minLat = 18.0;   // 最小纬度（北纬）
    const maxLat = 53.0;   // 最大纬度（北纬）
    
    const lng = minLng + Math.random() * (maxLng - minLng);
    const lat = minLat + Math.random() * (maxLat - minLat);
    
    return new LatLng(lat, lng);
  }

  /**
   * 添加随机折线（3-6个点，坐标落在中国范围内）
   */
  private addPolyline(): void {
    if (!this.mapController) return;
    
    try {
      // 随机生成3-6个点
      const pointCount = Math.floor(Math.random() * 4) + 3; // 3-6个点
      const points: LatLng[] = [];
      
      for (let i = 0; i < pointCount; i++) {
        points.push(this.generateRandomChinaCoordinate());
      }
      
      // 随机选择颜色
      const colors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#800080'];
      const randomColor = colors[Math.floor(Math.random() * colors.length)];
      
      const polyline = new Polyline({
        points: points,
        color: randomColor,
        width: 5.0,
        alpha: 0.8,
        visible: true
      });
      
      // 添加到地图，获取 ID
      const ids = this.mapController.addPolylines([polyline]);
      polyline.setId(ids[0]);
      
      this.polylines.push(polyline);
      this.polylineCount = this.polylines.length;
      this.statusMessage = `✅ 已添加随机折线 (${pointCount}个点，共 ${this.polylineCount} 条)`;
      showToast(`已添加折线 (${pointCount}个点)`);
      
      console.info(`[PolylinePolygonTestPage] 折线已添加: ${pointCount}个点`);
    } catch (error) {
      console.error(`[PolylinePolygonTestPage] 添加折线失败: ${error}`);
      this.statusMessage = `❌ 添加折线失败: ${error}`;
      showToast(`添加失败: ${error}`);
    }
  }

  /**
   * 更新折线（修改颜色和宽度）
   */
  private updatePolyline(): void {
    if (!this.mapController || this.polylines.length === 0) return;
    
    try {
      // 更新最后一条折线
      const lastPolyline = this.polylines[this.polylines.length - 1];
      
      // 随机改变颜色
      const colors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF'];
      const randomColor = colors[Math.floor(Math.random() * colors.length)];
      
      lastPolyline.setColor(randomColor);
      lastPolyline.setWidth(8.0);
      
      // 更新到地图
      this.mapController.updatePolyline(lastPolyline);
      
      this.statusMessage = `✅ 已更新折线颜色为 ${randomColor}`;
      showToast('折线已更新');
      
      console.info('[PolylinePolygonTestPage] 折线已更新');
    } catch (error) {
      console.error(`[PolylinePolygonTestPage] 更新折线失败: ${error}`);
      this.statusMessage = `❌ 更新折线失败: ${error}`;
      showToast(`更新失败: ${error}`);
    }
  }

  /**
   * 清除所有折线
   */
  private clearPolylines(): void {
    if (!this.mapController || this.polylines.length === 0) return;
    
    try {
      // 获取所有折线的 ID
      const ids: number[] = this.polylines.map(polyline => polyline.getId());
      
      // 从地图删除
      this.mapController.removeAnnotations(ids);
      
      // 清空数组
      this.polylines = [];
      this.polylineCount = 0;
      
      this.statusMessage = '✅ 已清除所有折线';
      showToast('已清除折线');
      
      console.info('[PolylinePolygonTestPage] 折线已清除');
    } catch (error) {
      console.error(`[PolylinePolygonTestPage] 清除折线失败: ${error}`);
      this.statusMessage = `❌ 清除折线失败: ${error}`;
      showToast(`清除失败: ${error}`);
    }
  }

  /**
   * 添加随机多边形（3-6个点，坐标落在中国范围内）
   */
  private addPolygon(): void {
    if (!this.mapController) return;
    
    try {
      // 随机生成3-6个点
      const pointCount = Math.floor(Math.random() * 4) + 3; // 3-6个点
      const points: LatLng[] = [];
      
      for (let i = 0; i < pointCount; i++) {
        points.push(this.generateRandomChinaCoordinate());
      }
      
      // 闭合多边形（添加第一个点作为最后一个点）
      points.push(new LatLng(points[0].latitude, points[0].longitude));
      
      // 随机选择填充颜色和边框颜色
      const fillColors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#800080'];
      const randomFillColor = fillColors[Math.floor(Math.random() * fillColors.length)];
      const randomStrokeColor = fillColors[Math.floor(Math.random() * fillColors.length)];
      
      const polygon = new Polygon({
        points: points,
        fillColor: randomFillColor,
        strokeColor: randomStrokeColor,
        strokeWidth: 2.0,
        fillAlpha: 0.4,
        strokeAlpha: 1.0,
        visible: true
      });
      
      // 添加到地图，获取 ID
      const ids = this.mapController.addPolygons([polygon]);
      polygon.setId(ids[0]);
      
      this.polygons.push(polygon);
      this.polygonCount = this.polygons.length;
      this.statusMessage = `✅ 已添加随机多边形 (${pointCount}个点，共 ${this.polygonCount} 个)`;
      showToast(`已添加多边形 (${pointCount}个点)`);
      
      console.info(`[PolylinePolygonTestPage] 多边形已添加: ${pointCount}个点`);
    } catch (error) {
      console.error(`[PolylinePolygonTestPage] 添加多边形失败: ${error}`);
      this.statusMessage = `❌ 添加多边形失败: ${error}`;
      showToast(`添加失败: ${error}`);
    }
  }

  /**
   * 更新多边形（修改颜色和透明度）
   */
  private updatePolygon(): void {
    if (!this.mapController || this.polygons.length === 0) return;
    
    try {
      // 更新最后一个多边形
      const lastPolygon = this.polygons[this.polygons.length - 1];
      
      // 随机改变填充颜色和透明度
      const fillColors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF'];
      const randomColor = fillColors[Math.floor(Math.random() * fillColors.length)];
      const randomAlpha = 0.3 + Math.random() * 0.5; // 0.3 - 0.8
      
      lastPolygon.setFillColor(randomColor);
      lastPolygon.setFillAlpha(randomAlpha);
      
      // 更新到地图
      this.mapController.updatePolygon(lastPolygon);
      
      this.statusMessage = `✅ 已更新多边形颜色为 ${randomColor}, 透明度: ${(randomAlpha * 100).toFixed(0)}%`;
      showToast('多边形已更新');
      
      console.info('[PolylinePolygonTestPage] 多边形已更新');
    } catch (error) {
      console.error(`[PolylinePolygonTestPage] 更新多边形失败: ${error}`);
      this.statusMessage = `❌ 更新多边形失败: ${error}`;
      showToast(`更新失败: ${error}`);
    }
  }

  /**
   * 清除所有多边形
   */
  private clearPolygons(): void {
    if (!this.mapController || this.polygons.length === 0) return;
    
    try {
      // 获取所有多边形的 ID
      const ids: number[] = this.polygons.map(polygon => polygon.getId());
      
      // 从地图删除
      this.mapController.removeAnnotations(ids);
      
      // 清空数组
      this.polygons = [];
      this.polygonCount = 0;
      
      this.statusMessage = '✅ 已清除所有多边形';
      showToast('已清除多边形');
      
      console.info('[PolylinePolygonTestPage] 多边形已清除');
    } catch (error) {
      console.error(`[PolylinePolygonTestPage] 清除多边形失败: ${error}`);
      this.statusMessage = `❌ 清除多边形失败: ${error}`;
      showToast(`清除失败: ${error}`);
    }
  }

  /**
   * 清除所有注解
   */
  private clearAllAnnotations(): void {
    if (!this.mapController) return;
    
    try {
      // 获取所有注解的 ID
      const allIds: number[] = [
        ...this.polylines.map(p => p.getId()),
        ...this.polygons.map(p => p.getId())
      ];
      
      if (allIds.length > 0) {
        this.mapController.removeAnnotations(allIds);
      }
      
      // 清空数组
      this.polylines = [];
      this.polygons = [];
      this.polylineCount = 0;
      this.polygonCount = 0;
      
      this.statusMessage = '✅ 已清除所有注解';
      showToast('已清除所有注解');
      
      console.info('[PolylinePolygonTestPage] 所有注解已清除');
    } catch (error) {
      console.error(`[PolylinePolygonTestPage] 清除注解失败: ${error}`);
      this.statusMessage = `❌ 清除注解失败: ${error}`;
      showToast(`清除失败: ${error}`);
    }
  }
  
  aboutToDisappear() {
    // 清理资源
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
}
