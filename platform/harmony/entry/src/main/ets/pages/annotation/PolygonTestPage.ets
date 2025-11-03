/**
 * Polygon Test Page
 * 多边形注解测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/annotation/PolygonActivity.kt
 * 
 * 功能:
 * - 添加多边形注解（使用 GeoJSON Source + FillLayer）
 * - 修改多边形属性（颜色、透明度、点位）
 * - 多边形孔洞支持
 * - 多边形点击事件
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapLibreMap, MapView, Polygon, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG  } from '../common/TestUtils';

@Entry
@Component
struct PolygonTestPage {
  private mapController: MapLibreMap | null = null;
  private currentPolygon: Polygon | null = null;
  private currentPolygonId: number = -1;
  
  // 存储所有随机多边形
  private randomPolygons: Polygon[] = [];
  private randomPolygonIds: number[] = [];
  
  @State private currentColor: string = '#FF0000';  // 填充颜色：红色
  @State private currentAlpha: number = 0.8;  // 填充透明度 0.8
  @State private currentStrokeColor: string = '#0000FF';  // 边框颜色：蓝色
  @State private currentStrokeWidth: number = 4.0;  // 边框宽度 4px
  @State private currentStrokeAlpha: number = 1.0;  // 边框透明度 1.0
  @State private hasHoles: boolean = false;
  @State private useFullPoints: boolean = true;
  @State private randomPolygonCount: number = 0;
  
  // 星形多边形坐标（中国区域 - 河北省大小，约4度范围）
  private starShapePoints: number[][][] = [[
    [116.0, 40.5],   // 上顶点
    [117.0, 41.0],   // 右上外角
    [115.5, 40.8],   // 右上内角
    [115.0, 42.0],   // 右顶点
    [114.5, 40.8],   // 右下内角
    [114.0, 41.0],   // 右下外角
    [114.5, 39.5],   // 下顶点
    [114.0, 39.0],   // 左下外角
    [115.0, 39.2],   // 左下内角
    [115.5, 38.0],   // 左顶点
    [116.0, 39.2],   // 左上内角
    [117.0, 39.0],   // 左上外角
    [116.0, 40.5]    // 闭合
  ]]
  
  // 部分点（用于测试更新点位）
  private brokenShapePoints: number[][][] = [[
    [116.0, 40.5],   // 上顶点
    [117.0, 41.0],   // 右上外角
    [115.5, 40.8],   // 右上内角
    [115.0, 42.0],   // 右顶点
    [114.5, 40.8],   // 右下内角
    [114.0, 41.0],   // 右下外角
    [114.5, 39.5],   // 下顶点
    [114.0, 39.0],   // 左下外角
    [115.0, 39.2],   // 左下内角
    [115.5, 38.0]    // 左顶点（未闭合）
  ]]
  
  // 多边形孔洞（相应放大）
  private starShapeHoles: number[][][][] = [
    [[
      [115.3, 40.3],
      [116.5, 40.8],
      [116.5, 40.0],
      [115.3, 40.3]
    ]],
    [[
      [114.8, 40.5],
      [114.8, 39.8],
      [114.3, 39.8],
      [114.3, 40.2],
      [114.8, 40.5]
    ]]
  ]
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[PolygonTestPage] onMapReady');
    this.mapController = map;

    // 确保地图定位到多边形中心区域
    try {
      this.mapController.easeTo({
        center: new LatLng(40.0, 115.5),  // 多边形中心位置
        zoom: 6.5  // 缩小视野以显示整个省级大小的多边形
      }, 0);  // duration: 0 立即跳转,不需要动画
      console.info('[PolygonTestPage] Map positioned to polygon center (115.5, 40.0)');
    } catch (error) {
      console.error(`[PolygonTestPage] Failed to position map: ${error}`);
    }

    // 添加初始多边形
    this.addPolygon();
  };
  
  /**
   * 添加多边形
   */
  private addPolygon = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 移除旧的多边形
      this.removePolygon();
      
      // 选择坐标点（完整或部分）
      const coordinates = this.useFullPoints ? this.starShapePoints : this.brokenShapePoints;
      
      // 转换为 LatLng 数组（注意经纬度顺序）
      const points: LatLng[] = coordinates[0].map((coord: number[]): LatLng => {
        return new LatLng(coord[1], coord[0]);  // LatLng(纬度, 经度)
      });
      
      // 处理孔洞
      let holes: LatLng[][] | undefined = undefined;
      if (this.hasHoles) {
        holes = this.starShapeHoles.map((hole: number[][][]): LatLng[] => {
          return hole[0].map((coord: number[]): LatLng => {
            return new LatLng(coord[1], coord[0]);
          });
        });
      }
      
      // 创建多边形对象
      this.currentPolygon = new Polygon({
        points: points,
        holes: holes,
        fillColor: this.currentColor,
        strokeColor: this.currentStrokeColor,
        strokeWidth: this.currentStrokeWidth,
        fillAlpha: this.currentAlpha,
        strokeAlpha: this.currentStrokeAlpha
      });
      
      // 添加多边形，获取 ID
      const ids = this.mapController.addPolygons([this.currentPolygon]);
      this.currentPolygonId = ids[0];
      this.currentPolygon.setId(this.currentPolygonId);
      
      showToast('多边形已添加');
    } catch (error) {
      console.error(`添加多边形失败: ${error}`);
      showToast(`添加失败: ${error}`);
    }
  };
  
  /**
   * 移除多边形
   */
  private removePolygon = (): void => {
    if (!this.mapController) return;
    
    try {
      // 移除多边形
      if (this.currentPolygonId !== -1) {
        this.mapController.removeAnnotations([this.currentPolygonId]);
        this.currentPolygonId = -1;
        this.currentPolygon = null;
      }
    } catch (error) {
      console.error(`移除多边形失败: ${error}`);
    }
  };
  
  /**
   * 切换填充透明度（同时更新所有多边形）
   */
  private toggleAlpha = (): void => {
    // 在 0.2、0.5、0.8 之间循环切换，变化更明显
    if (this.currentAlpha === 0.8) {
      this.currentAlpha = 0.2;
    } else if (this.currentAlpha === 0.2) {
      this.currentAlpha = 0.5;
    } else {
      this.currentAlpha = 0.8;
    }
    
    if (!this.mapController) {
      return;
    }
    
    // 更新固定多边形的透明度
    if (this.currentPolygon) {
      this.currentPolygon.setFillAlpha(this.currentAlpha);
      this.mapController.updatePolygon(this.currentPolygon);
    }
    
    // 更新所有随机多边形的透明度
    for (const polygon of this.randomPolygons) {
      polygon.setFillAlpha(this.currentAlpha);
      this.mapController.updatePolygon(polygon);
    }
    
    const totalCount = (this.currentPolygon ? 1 : 0) + this.randomPolygons.length;
    console.info(`[PolygonTestPage] ${totalCount}个多边形透明度已更新为: ${this.currentAlpha}`);
    showToast(`所有多边形透明度: ${(this.currentAlpha * 100).toFixed(0)}%`);
  };
  
  /**
   * 切换填充颜色（同时更新所有多边形）
   */
  private toggleColor = (): void => {
    // 在红色、绿色、蓝色、黄色之间循环切换，颜色差异更明显
    const colors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00'];
    const currentIndex = colors.indexOf(this.currentColor);
    this.currentColor = colors[(currentIndex + 1) % colors.length];
    
    if (!this.mapController) {
      return;
    }
    
    // 更新固定多边形的填充颜色
    if (this.currentPolygon) {
      this.currentPolygon.setFillColor(this.currentColor);
      this.mapController.updatePolygon(this.currentPolygon);
    }
    
    // 更新所有随机多边形的填充颜色
    for (const polygon of this.randomPolygons) {
      polygon.setFillColor(this.currentColor);
      this.mapController.updatePolygon(polygon);
    }
    
    const totalCount = (this.currentPolygon ? 1 : 0) + this.randomPolygons.length;
    console.info(`[PolygonTestPage] ${totalCount}个多边形填充颜色已更新为: ${this.currentColor}`);
    showToast(`所有多边形填充颜色: ${this.currentColor}`);
  };
  
  /**
   * 切换点位（完整/部分）
   */
  private togglePoints = (): void => {
    this.useFullPoints = !this.useFullPoints;
    this.addPolygon();
    showToast(`点位: ${this.useFullPoints ? '完整' : '部分'}`);
  };
  
  /**
   * 切换孔洞
   */
  private toggleHoles = (): void => {
    this.hasHoles = !this.hasHoles;
    this.addPolygon();
    showToast(`孔洞: ${this.hasHoles ? '显示' : '隐藏'}`);
  };

  /**
   * 切换边框颜色（同时更新所有多边形）
   */
  private toggleStrokeColor = (): void => {
    // 在蓝色、橙色、紫色、青色之间循环切换
    const colors = ['#0000FF', '#FFA500', '#800080', '#00FFFF'];
    const currentIndex = colors.indexOf(this.currentStrokeColor);
    this.currentStrokeColor = colors[(currentIndex + 1) % colors.length];
    
    if (!this.mapController) {
      return;
    }
    
    // 更新固定多边形的边框颜色
    if (this.currentPolygon) {
      this.currentPolygon.setStrokeColor(this.currentStrokeColor);
      this.mapController.updatePolygon(this.currentPolygon);
    }
    
    // 更新所有随机多边形的边框颜色
    for (const polygon of this.randomPolygons) {
      polygon.setStrokeColor(this.currentStrokeColor);
      this.mapController.updatePolygon(polygon);
    }
    
    const totalCount = (this.currentPolygon ? 1 : 0) + this.randomPolygons.length;
    console.info(`[PolygonTestPage] ${totalCount}个多边形边框颜色已更新为: ${this.currentStrokeColor}`);
    showToast(`所有多边形边框颜色: ${this.currentStrokeColor}`);
  };

  /**
   * 切换边框宽度（同时更新所有多边形）
   */
  private toggleStrokeWidth = (): void => {
    // 在 2px, 4px, 6px, 8px 之间循环切换
    const widths = [2.0, 4.0, 6.0, 8.0];
    const currentIndex = widths.indexOf(this.currentStrokeWidth);
    this.currentStrokeWidth = widths[(currentIndex + 1) % widths.length];
    
    if (!this.mapController) {
      return;
    }
    
    // 更新固定多边形的边框宽度
    if (this.currentPolygon) {
      this.currentPolygon.setStrokeWidth(this.currentStrokeWidth);
      this.mapController.updatePolygon(this.currentPolygon);
    }
    
    // 更新所有随机多边形的边框宽度
    for (const polygon of this.randomPolygons) {
      polygon.setStrokeWidth(this.currentStrokeWidth);
      this.mapController.updatePolygon(polygon);
    }
    
    const totalCount = (this.currentPolygon ? 1 : 0) + this.randomPolygons.length;
    console.info(`[PolygonTestPage] ${totalCount}个多边形边框宽度已更新为: ${this.currentStrokeWidth}px`);
    showToast(`所有多边形边框宽度: ${this.currentStrokeWidth}px`);
  };

  /**
   * 切换边框透明度（同时更新所有多边形）
   */
  private toggleStrokeAlpha = (): void => {
    // 在 1.0, 0.7, 0.4, 0.2 之间循环切换
    const alphas = [1.0, 0.7, 0.4, 0.2];
    const currentIndex = alphas.indexOf(this.currentStrokeAlpha);
    this.currentStrokeAlpha = alphas[(currentIndex + 1) % alphas.length];
    
    if (!this.mapController) {
      return;
    }
    
    // 更新固定多边形的边框透明度
    if (this.currentPolygon) {
      this.currentPolygon.setStrokeAlpha(this.currentStrokeAlpha);
      this.mapController.updatePolygon(this.currentPolygon);
    }
    
    // 更新所有随机多边形的边框透明度
    for (const polygon of this.randomPolygons) {
      polygon.setStrokeAlpha(this.currentStrokeAlpha);
      this.mapController.updatePolygon(polygon);
    }
    
    const totalCount = (this.currentPolygon ? 1 : 0) + this.randomPolygons.length;
    console.info(`[PolygonTestPage] ${totalCount}个多边形边框透明度已更新为: ${this.currentStrokeAlpha}`);
    showToast(`所有多边形边框透明度: ${(this.currentStrokeAlpha * 100).toFixed(0)}%`);
  };

  /**
   * 生成中国境内的随机中心点
   * 中国经纬度范围：东经 73° - 135°，北纬 18° - 53°
   */
  private generateRandomChinaCenter(): LatLng {
    const minLng = 75.0;   // 最小经度（东经），留出边界
    const maxLng = 133.0;  // 最大经度（东经），留出边界
    const minLat = 20.0;   // 最小纬度（北纬），留出边界
    const maxLat = 51.0;   // 最大纬度（北纬），留出边界
    
    const lng = minLng + Math.random() * (maxLng - minLng);
    const lat = minLat + Math.random() * (maxLat - minLat);
    
    return new LatLng(lat, lng);
  }

  /**
   * 添加随机多边形（3-6个点，省级大小，坐标落在中国范围内）
   */
  private addRandomPolygon = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 随机生成3-6个点
      const pointCount = Math.floor(Math.random() * 4) + 3; // 3-6个点
      const points: LatLng[] = [];
      
      // 随机选择一个中心点
      const center = this.generateRandomChinaCenter();
      
      // 省级大小：半径约2-3度（约200-300公里）
      const radius = 2.0 + Math.random() * 1.0; // 2-3度
      
      // 在中心点周围生成多边形顶点
      for (let i = 0; i < pointCount; i++) {
        const angle = (i / pointCount) * 2 * Math.PI; // 均匀分布角度
        // 添加随机扰动，使形状不规则
        const randomRadius = radius * (0.7 + Math.random() * 0.6); // 半径变化 70%-130%
        const randomAngleOffset = (Math.random() - 0.5) * 0.5; // 角度随机偏移
        
        const lat = center.latitude + randomRadius * Math.cos(angle + randomAngleOffset);
        const lng = center.longitude + randomRadius * Math.sin(angle + randomAngleOffset);
        
        points.push(new LatLng(lat, lng));
      }
      
      // 闭合多边形（添加第一个点作为最后一个点）
      points.push(new LatLng(points[0].latitude, points[0].longitude));
      
      // 随机选择填充颜色和边框颜色
      const fillColors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#800080'];
      const randomFillColor = fillColors[Math.floor(Math.random() * fillColors.length)];
      const randomStrokeColor = fillColors[Math.floor(Math.random() * fillColors.length)];
      
      // 创建多边形对象
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
      
      // 将新多边形添加到列表中
      this.randomPolygons.push(polygon);
      this.randomPolygonIds.push(ids[0]);
      
      this.randomPolygonCount = this.randomPolygons.length;
      
      showToast(`已添加随机多边形 (${pointCount}个点)\n当前总数: ${this.randomPolygonCount}`);
      console.info(`[PolygonTestPage] 随机多边形已添加: ${pointCount}个点`);
    } catch (error) {
      console.error(`添加随机多边形失败: ${error}`);
      showToast(`添加失败: ${error}`);
    }
  };

  /**
   * 清除所有随机多边形
   */
  private clearRandomPolygons = (): void => {
    if (!this.mapController || this.randomPolygonIds.length === 0) {
      showToast('没有随机多边形可清除');
      return;
    }
    
    try {
      // 从地图删除
      this.mapController.removeAnnotations(this.randomPolygonIds);
      
      // 清空数组
      this.randomPolygons = [];
      this.randomPolygonIds = [];
      this.randomPolygonCount = 0;
      
      showToast('已清除所有随机多边形');
      console.info('[PolygonTestPage] 随机多边形已清除');
    } catch (error) {
      console.error(`清除随机多边形失败: ${error}`);
      showToast(`清除失败: ${error}`);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Column({ space: 8 }) {
      // 多边形属性信息展示区
      Column({ space: 4 }) {
        Text('多边形属性')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%');
        
        Text(`填充: ${this.currentColor} (${(this.currentAlpha * 100).toFixed(0)}%)`)
          .fontSize(11)
          .fontColor('#666')
          .width('100%');
        
        Text(`边框: ${this.currentStrokeColor} (${(this.currentStrokeAlpha * 100).toFixed(0)}%) ${this.currentStrokeWidth}px`)
          .fontSize(11)
          .fontColor('#666')
          .width('100%');
        
        Text(`点位: ${this.useFullPoints ? '完整' : '部分'} | 孔洞: ${this.hasHoles ? '是' : '否'}`)
          .fontSize(11)
          .fontColor('#666')
          .width('100%');
        
        Text(`随机多边形数量: ${this.randomPolygonCount}`)
          .fontSize(11)
          .fontColor('#FF5722')
          .width('100%');
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(6)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
      
      // 固定多边形操作按钮 - 填充属性
      Row() {
        Button('填充透明度')
          .fontSize(11)
          .layoutWeight(1)
          .onClick(this.toggleAlpha);
        
        Button('填充颜色')
          .fontSize(11)
          .layoutWeight(1)
          .margin({ left: 6 })
          .onClick(this.toggleColor);
      }
      .width('100%')
      
      // 边框属性
      Row() {
        Button('边框颜色')
          .fontSize(11)
          .layoutWeight(1)
          .onClick(this.toggleStrokeColor);
        
        Button('边框宽度')
          .fontSize(11)
          .layoutWeight(1)
          .margin({ left: 6 })
          .onClick(this.toggleStrokeWidth);
      }
      .width('100%')
      
      Row() {
        Button('边框透明度')
          .fontSize(11)
          .layoutWeight(1)
          .onClick(this.toggleStrokeAlpha);
        
        Button('点位')
          .fontSize(11)
          .layoutWeight(1)
          .margin({ left: 6 })
          .onClick(this.togglePoints);
      }
      .width('100%')
      
      Row() {
        Button('孔洞')
          .fontSize(11)
          .layoutWeight(1)
          .onClick(this.toggleHoles);
      }
      .width('100%')
      
      Divider()
        .color('#E0E0E0')
        .strokeWidth(1)
        .margin({ top: 4, bottom: 4 })
      
      // 随机多边形操作按钮
      Row() {
        Button('新增多边形')
          .fontSize(12)
          .layoutWeight(1)
          .backgroundColor('#4CAF50')
          .onClick(this.addRandomPolygon);
        
        Button('清除随机')
          .fontSize(12)
          .layoutWeight(1)
          .margin({ left: 6 })
          .backgroundColor('#F44336')
          .onClick(this.clearRandomPolygons);
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
      initialLatitude: 40.0,
      initialLongitude: 115.5,
      initialZoom: 5
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Polygon',
        description: '多边形注解',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}

