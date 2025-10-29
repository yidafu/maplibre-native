/**
 * Projection - 坐标投影工具类
 * 
 * 提供地图坐标和屏幕坐标之间的转换功能
 * 对应 Android 的 Projection 类和 iOS 的 MLNMapView coordinate conversion 方法
 */
import maplibre from 'libmaplibre.so';
import { LatLng, createLatLng } from '../geometry/LatLng';
import { Point, createPoint } from '../geometry/Point';
import { VisibleRegion } from './VisibleRegion';
import { LatLngBounds } from '../geometry/LatLngBounds';

type NativeMapView = maplibre.NativeMapView;

/**
 * Projection 类
 * 
 * 提供地图投影相关的工具方法
 * 
 * 使用示例：
 * ```typescript
 * const projection = mapLibreMap.getProjection();
 * const screenPoint = projection.latLngToScreenLocation(latLng);
 * const latLng = projection.screenLocationToLatLng(screenPoint);
 * ```
 */
export class Projection {
  private nativeMapView: NativeMapView;
  private viewWidth: number = 0;
  private viewHeight: number = 0;
  
  /**
   * 构造函数
   * 
   * @param nativeMapView NativeMapView 实例
   * @param viewWidth 视图宽度（逻辑像素）
   * @param viewHeight 视图高度（逻辑像素）
   */
  constructor(nativeMapView: NativeMapView, viewWidth: number, viewHeight: number) {
    this.nativeMapView = nativeMapView;
    this.viewWidth = viewWidth;
    this.viewHeight = viewHeight;
  }
  
  /**
   * 更新视图尺寸
   * 
   * @param width 新的视图宽度
   * @param height 新的视图高度
   */
  public updateViewSize(width: number, height: number): void {
    this.viewWidth = width;
    this.viewHeight = height;
  }
  
  // ========== 单点坐标转换 ==========
  
  /**
   * 将地理坐标转换为屏幕坐标
   * 
   * @param latLng 地理坐标
   * @returns 屏幕坐标（像素）
   */
  public latLngToScreenLocation(latLng: LatLng): Point {
    return this.nativeMapView.pixelForLatLng(latLng.latitude, latLng.longitude);
  }
  
  /**
   * 将屏幕坐标转换为地理坐标
   * 
   * @param point 屏幕坐标（像素）
   * @returns 地理坐标
   */
  public screenLocationToLatLng(point: Point): LatLng {
    return this.nativeMapView.latLngForPixel(point.x, point.y);
  }
  
  // ========== 批量坐标转换 ==========
  
  /**
   * 批量将地理坐标转换为屏幕坐标
   * 
   * @param latLngs 地理坐标数组
   * @returns 屏幕坐标数组
   */
  public latLngsToScreenLocations(latLngs: LatLng[]): Point[] {
    const points: Point[] = [];
    for (const latLng of latLngs) {
      points.push(this.latLngToScreenLocation(latLng));
    }
    return points;
  }
  
  /**
   * 批量将屏幕坐标转换为地理坐标
   * 
   * @param points 屏幕坐标数组
   * @returns 地理坐标数组
   */
  public screenLocationsToLatLngs(points: Point[]): LatLng[] {
    const latLngs: LatLng[] = [];
    for (const point of points) {
      latLngs.push(this.screenLocationToLatLng(point));
    }
    return latLngs;
  }
  
  // ========== 可见区域 ==========
  
  /**
   * 获取当前地图的可见区域
   * 
   * 返回屏幕四个角对应的地理坐标和边界
   * 
   * @returns 可见区域对象
   */
  public getVisibleRegion(): VisibleRegion {
    // 获取屏幕四个角的坐标
    // 注意：屏幕坐标系原点在左上角
    const nearLeft = this.screenLocationToLatLng(createPoint(0, this.viewHeight));
    const nearRight = this.screenLocationToLatLng(createPoint(this.viewWidth, this.viewHeight));
    const farLeft = this.screenLocationToLatLng(createPoint(0, 0));
    const farRight = this.screenLocationToLatLng(createPoint(this.viewWidth, 0));
    
    // 计算包含所有角点的边界
    // 找出最北、最东、最南、最西的点
    const latitudes = [nearLeft.latitude, nearRight.latitude, farLeft.latitude, farRight.latitude];
    const longitudes = [nearLeft.longitude, nearRight.longitude, farLeft.longitude, farRight.longitude];
    
    const north = Math.max(...latitudes);
    const south = Math.min(...latitudes);
    const east = Math.max(...longitudes);
    const west = Math.min(...longitudes);
    
    const northeast = new LatLng(north, east);
    const southwest = new LatLng(south, west);
    const bounds = LatLngBounds.fromLatLngs(northeast, southwest);
    
    return new VisibleRegion(nearLeft, nearRight, farLeft, farRight, bounds);
  }
  
  // ========== 工具方法 ==========
  
  /**
   * 获取指定纬度下每像素代表的米数
   * 
   * 使用当前地图的缩放级别
   * 
   * @param latitude 纬度
   * @returns 每像素米数
   */
  public getMetersPerPixelAtLatitude(latitude: number): number {
    // 使用 NativeMapView 的方法，它会使用当前的 zoom level
    const zoom = this.nativeMapView.getZoom();
    return this.nativeMapView.getMetersPerPixelAtLatitude(latitude, zoom);
  }
  
  /**
   * 获取指定纬度和缩放级别下每像素代表的米数
   * 
   * @param latitude 纬度
   * @param zoom 缩放级别
   * @returns 每像素米数
   */
  public getMetersPerPixelAtLatitudeAndZoom(latitude: number, zoom: number): number {
    return this.nativeMapView.getMetersPerPixelAtLatitude(latitude, zoom);
  }
  
  /**
   * 将地理坐标转换为投影米坐标
   * 
   * @param latLng 地理坐标
   * @returns 投影米坐标
   */
  public toProjectedMeters(latLng: LatLng): maplibre.ProjectedMeters {
    return this.nativeMapView.projectedMetersForLatLng(latLng.latitude, latLng.longitude);
  }
  
  /**
   * 将投影米坐标转换为地理坐标
   * 
   * @param projectedMeters 投影米坐标
   * @returns 地理坐标
   */
  public fromProjectedMeters(projectedMeters: maplibre.ProjectedMeters): LatLng {
    return this.nativeMapView.latLngForProjectedMeters(projectedMeters.northing, projectedMeters.easting);
  }
  
  /**
   * 获取视图宽度
   */
  public getViewWidth(): number {
    return this.viewWidth;
  }
  
  /**
   * 获取视图高度
   */
  public getViewHeight(): number {
    return this.viewHeight;
  }
}

