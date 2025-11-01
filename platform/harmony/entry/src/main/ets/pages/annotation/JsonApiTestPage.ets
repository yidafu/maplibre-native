/**
 * JSON API Test Page
 * JSON API测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/annotation/JsonApiActivity.kt
 * 
 * 功能:
 * - 从 USGS 地震 API 获取真实 GeoJSON 数据
 * - 使用 Marker 显示地震位置
 * - 根据震级显示不同颜色的图标
 * - 自动调整相机到合适位置
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, Marker, MarkerOptions, LatLng, LatLngBounds } from 'maplibre_harmony';
import type { IFeatureCollection, IPoint } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';
import { http } from '@kit.NetworkKit';
import type { PropertiesMap } from '../../types/EntryTypes';

/**
 * 地震属性接口
 */
interface EarthquakeProperties {
  mag: number;
  place: string;
  time: number;
  title?: string;
}

/**
 * GeoJSON Geometry 接口
 */
interface PointGeometry {
  type: string;
  coordinates: number[]
}

/**
 * GeoJSON Feature 接口
 */
interface EarthquakeFeature {
  type: string;
  properties: EarthquakeProperties;
  geometry: PointGeometry;
}

/**
 * GeoJSON FeatureCollection 接口
 */
interface FeatureCollection {
  type: string;
  features: EarthquakeFeature[]
}

@Entry
@Component
struct JsonApiTestPage {
  private mapController: MapLibreMap | null = null;
  private markers: Marker[] = [];;
  @State private earthquakeCount: number = 0;
  @State private isLoading: boolean = false;
  @State private statusMessage: string = '点击按钮获取地震数据';
  
  aboutToDisappear() {
    this.clearMarkers();
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[JsonApiTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.bright);
    
    // 设置初始位置（台湾地区）
    map.jumpTo(0, 24.0, 121.0, 0, 6);
    
    // 自动获取数据
    this.fetchEarthquakeData();
  };
  
  /**
   * 从 USGS API 获取地震数据
   */
  private fetchEarthquakeData = async (): Promise<void> => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    this.isLoading = true;
    this.statusMessage = '正在获取地震数据...';
    
    // 构建 USGS API URL
    const baseUrl = 'https://earthquake.usgs.gov/fdsnws/event/1/query';
    const params = [
      'format=geojson',
      'starttime=2022-01-01',
      'endtime=2022-12-31',
      'minmagnitude=5.8',
      'latitude=24',
      'longitude=121',
      'maxradius=1.5'
    ]
    const url = `${baseUrl}?${params.join('&')}`;
    
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 60000,
        readTimeout: 60000
      });
      
      if (response.responseCode === 200) {
        const featureCollection = JSON.parse(response.result as string) as IFeatureCollection;
        this.addMarkersToMap(featureCollection);
        this.statusMessage = `成功获取 ${this.earthquakeCount} 条地震记录`;
        showToast(`获取到 ${this.earthquakeCount} 条地震数据`);
      } else {
        this.statusMessage = `请求失败: ${response.responseCode}`;
        showToast(`请求失败: ${response.responseCode}`);
      }
      
      httpRequest.destroy();
    } catch (error) {
      console.error(`[JsonApiTestPage] 获取数据失败: ${error}`);
      this.statusMessage = `获取失败: ${error}`;
      showToast(`获取失败: ${error}`);
    } finally {
      this.isLoading = false;
    }
  };
  
  /**
   * 将地震数据添加到地图
   */
  private addMarkersToMap = async (featureCollection: IFeatureCollection): Promise<void> => {
    if (!this.mapController) return;
    
    // 清除现有标记
    this.clearMarkers();
    
    const bounds: LatLng[] = [];;
    
    // 遍历所有地震事件
    for (const feature of featureCollection.features) {
      const geometry = feature.geometry as IPoint;
      const properties: PropertiesMap = feature.properties;
      
      if (geometry.type !== 'Point') continue;
      
      // ArkTS 不支持解构赋值，使用索引访问
      const lng = geometry.coordinates[0]
      const lat = geometry.coordinates[1]
      const depth = geometry.coordinates[2]
      const latLng = LatLng.create(lat, lng);
      bounds.push(latLng);
      
      // 格式化时间
      const date = new Date(properties.time as number);
      const dateString = this.formatDate(date);
      
      // 格式化标题
      const title = (properties.title || properties.place || '未知位置') as string;
      const magnitude = properties.mag as number;
      
      // 根据震级决定图标颜色
      const iconColor = magnitude > 6.0 ? '#FF0000' : '#3bb2d0';
      
      // 创建 Marker
      const markerOptions = new MarkerOptions()
        .position(latLng)
        .title(dateString)
        .snippet(`${title} (震级: ${magnitude.toFixed(1)})`);
      
      try {
        const marker = await this.mapController.addMarker(markerOptions);
        this.markers.push(marker);
      } catch (error) {
        console.error(`[JsonApiTestPage] 添加标记失败: ${error}`);
      }
    }
    
    this.earthquakeCount = this.markers.length;
    
    // 调整相机到合适位置
    if (bounds.length > 0) {
      this.adjustCameraToMarkers(bounds);
    }
  };
  
  /**
   * 调整相机到所有标记
   */
  private adjustCameraToMarkers = (bounds: LatLng[]): void => {
    if (!this.mapController || bounds.length === 0) return;
    
    try {
      // 计算边界
      let minLat = bounds[0].latitude;
      let maxLat = bounds[0].latitude;
      let minLng = bounds[0].longitude;
      let maxLng = bounds[0].longitude;
      
      for (const point of bounds) {
        minLat = Math.min(minLat, point.latitude);
        maxLat = Math.max(maxLat, point.latitude);
        minLng = Math.min(minLng, point.longitude);
        maxLng = Math.max(maxLng, point.longitude);
      }
      
      // 计算中心点和缩放级别
      const centerLat = (minLat + maxLat) / 2;
      const centerLng = (minLng + maxLng) / 2;
      
      // 计算合适的缩放级别（简单实现）
      const latDiff = maxLat - minLat;
      const lngDiff = maxLng - minLng;
      const maxDiff = Math.max(latDiff, lngDiff);
      
      let zoom = 10;
      if (maxDiff > 10) zoom = 4;
      else if (maxDiff > 5) zoom = 5;
      else if (maxDiff > 2) zoom = 6;
      else if (maxDiff > 1) zoom = 7;
      else if (maxDiff > 0.5) zoom = 8;
      
      // 调整相机位置
      this.mapController.easeTo({
        center: LatLng.create(centerLat, centerLng),
        zoom: zoom - 0.5
      }, 1000);
    } catch (error) {
      console.error(`[JsonApiTestPage] 调整相机失败: ${error}`);
    }
  };
  
  /**
   * 清除所有标记
   */
  private clearMarkers = (): void => {
    if (!this.mapController) return;
    
    for (const marker of this.markers) {
      this.mapController.removeMarker(marker);
    }
    this.markers = [];
    this.earthquakeCount = 0;
  };
  
  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}/${month}/${day} ${hours}:${minutes}`;
  }
  
  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: this.onMapReady,
      initialLatitude: 24.0,
      initialLongitude: 121.0,
      initialZoom: 6
    })
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('JSON API - 地震数据')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`地震记录数: ${this.earthquakeCount}`)
        .fontSize(14)
        .fontColor('#666')
      
      Text(this.statusMessage)
        .fontSize(12)
        .fontColor('#999')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      
      Button('获取地震数据')
        .width('100%')
        .enabled(!this.isLoading)
        .onClick(() => this.fetchEarthquakeData())
      
      Button('清除标记')
        .width('100%')
        .enabled(this.earthquakeCount > 0)
        .onClick(() => {
          this.clearMarkers();
          this.statusMessage = '已清除所有标记';
          showToast('已清除所有标记');
        })
      
      Text('说明: 从 USGS API 获取台湾地区地震数据（2022年，震级≥5.8）')
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
        title: 'JSON API',
        description: '从网络 API 获取 GeoJSON 数据',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}
