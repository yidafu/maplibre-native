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
import { MapLibreMap, MapView, GeoJson, GeoJsonSource, FillLayer, LineLayer } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG  } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

interface PolygonGeometry {
  type: string;
  coordinates: number[][][]
}

interface PolygonFeature {
  type: string;
  properties: Record<string, Object>;
  geometry: PolygonGeometry;
}

interface PolygonFeatureCollection {
  type: string;
  features: PolygonFeature[]
}

@Entry
@Component
struct PolygonTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentColor: string = '#3bb2d0';
  @State private currentAlpha: number = 1.0;
  @State private hasHoles: boolean = false;
  @State private useFullPoints: boolean = true;
  
  // 星形多边形坐标（波特兰地区）
  private starShapePoints: number[][][] = [[
    [-122.685699, 45.522585],
    [-122.708873, 45.534611],
    [-122.678833, 45.530883],
    [-122.667503, 45.547115],
    [-122.660121, 45.530643],
    [-122.636260, 45.533529],
    [-122.659091, 45.521743],
    [-122.648792, 45.510677],
    [-122.664070, 45.515008],
    [-122.669048, 45.502496],
    [-122.678489, 45.515369],
    [-122.702007, 45.506346],
    [-122.685699, 45.522585]
  ]]
  
  // 部分点（用于测试更新点位）
  private brokenShapePoints: number[][][] = [[
    [-122.685699, 45.522585],
    [-122.708873, 45.534611],
    [-122.678833, 45.530883],
    [-122.667503, 45.547115],
    [-122.660121, 45.530643],
    [-122.636260, 45.533529],
    [-122.659091, 45.521743],
    [-122.648792, 45.510677],
    [-122.664070, 45.515008],
    [-122.669048, 45.502496]
  ]]
  
  // 多边形孔洞
  private starShapeHoles: number[][][][] = [
    [[
      [-122.669091, 45.521743],
      [-122.676833, 45.530483],
      [-122.676833, 45.520483],
      [-122.669091, 45.521743]
    ]],
    [[
      [-122.662791, 45.529743],
      [-122.662791, 45.525543],
      [-122.660, 45.525543],
      [-122.660, 45.527743],
      [-122.662791, 45.529743]
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
    map.setStyleUrl(DEFAULT_STYLE_URLS.bright);
    
    // 设置初始位置（波特兰地区）
    map.jumpTo(0, 45.520486, -122.673541, 0, 12);
    
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
      // 移除旧的图层和数据源
      this.removePolygon();
      
      // 创建 GeoJSON 数据
      const coordinates = this.useFullPoints ? this.starShapePoints : this.brokenShapePoints;
      
      // 如果有孔洞，添加孔洞坐标
      let finalCoordinates = coordinates;
      if (this.hasHoles) {
        finalCoordinates = [coordinates[0], ...this.starShapeHoles.map(hole => hole[0])]
      }
      
      const props: Record<string, Object> = {};
      // 将finalCoordinates转换为正确的Position[][]类型
      const coords3d = finalCoordinates.map((ring: number[][]) => 
        ring.map((coord: number[]) => [coord[0], coord[1], coord[2] || 0] as Position)
      ) as Position[][];
      const feature = GeoJson.polygonFeature(coords3d, props);
      
      const geojson = GeoJson.featureCollection([feature]);
      
      // 添加数据源
      const source = new GeoJsonSource('polygon-source');
      source.setGeoJson(geojson);
      this.mapController.addSource(source);
      
      // 添加填充图层
      const fillLayer = new FillLayer('polygon-fill', 'polygon-source');
      const alphaHex = Math.round(this.currentAlpha * 255).toString(16).padStart(2, '0');
      fillLayer.setFillColor(`${alphaHex}${this.currentColor.substring(1)}`);
      this.mapController.addLayer(fillLayer);
      
      // 添加边框图层
      const lineLayer = new LineLayer('polygon-line', 'polygon-source');
      lineLayer.setLineColor(this.currentColor);
      lineLayer.setLineWidth(2);
      this.mapController.addLayer(lineLayer);
      
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
      // 移除图层
      const fillLayer = this.mapController.getLayer('polygon-fill');
      if (fillLayer) {
        this.mapController.removeLayer('polygon-fill');
      }
      
      const lineLayer = this.mapController.getLayer('polygon-line');
      if (lineLayer) {
        this.mapController.removeLayer('polygon-line');
      }
      
      // 移除数据源
      const source = this.mapController.getSource('polygon-source');
      if (source) {
        this.mapController.removeSource('polygon-source');
      }
    } catch (error) {
      console.error(`移除多边形失败: ${error}`);
    }
  };
  
  /**
   * 切换透明度
   */
  private toggleAlpha = (): void => {
    this.currentAlpha = this.currentAlpha === 1.0 ? 0.5 : 1.0;
    this.addPolygon();
    showToast(`透明度: ${(this.currentAlpha * 100).toFixed(0)}%`);
  };
  
  /**
   * 切换颜色
   */
  private toggleColor = (): void => {
    this.currentColor = this.currentColor === '#3bb2d0' ? '#AF0000' : '#3bb2d0';
    this.addPolygon();
    showToast(`颜色已更改`);
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
  
  @Builder
  actionButtonsBuilder() {
    Button('切换透明度')
      .fontSize(14)
      .onClick(this.toggleAlpha);
    
    Button('切换颜色')
      .fontSize(14)
      .onClick(this.toggleColor);
    
    Button('切换点位')
      .fontSize(14)
      .onClick(this.togglePoints);
    
    Button('切换孔洞')
      .fontSize(14)
      .onClick(this.toggleHoles);
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('多边形属性')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 });
      
      Text(`颜色: ${this.currentColor}`)
        .fontSize(12)
        .fontColor('#666');
      
      Text(`透明度: ${(this.currentAlpha * 100).toFixed(0)}%`)
        .fontSize(12)
        .fontColor('#666');
      
      Text(`点位: ${this.useFullPoints ? '完整' : '部分'}`)
        .fontSize(12)
        .fontColor('#666');
      
      Text(`孔洞: ${this.hasHoles ? '显示' : '隐藏'}`)
        .fontSize(12)
        .fontColor('#666');
    }
    .alignItems(HorizontalAlign.Start);
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: this.onMapReady,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
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
        controlPanel: (): void => this.controlPanelBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}

