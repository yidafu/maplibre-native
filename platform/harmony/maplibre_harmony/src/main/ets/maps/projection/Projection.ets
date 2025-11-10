/**
 * Projection - 坐标投影工具类
 *
 * 用于在屏幕坐标和地理坐标之间进行转换。屏幕坐标以屏幕像素（而非显示像素）表示，
 * 相对于地图的左上角（而非整个屏幕的左上角）。
 * 
 * **平台对照**：
 * - Android: `Projection` 类 - `map.getProjection()`
 * - iOS: `MLNMapView` 的坐标转换方法（如 `convertCoordinate:toPointToView:`）
 * 
 * **主要功能**：
 * 1. 屏幕坐标 ↔ 地理坐标转换（单点和批量）
 * 2. 地理坐标 ↔ 投影米坐标转换
 * 3. 可见区域查询
 * 4. 距离和比例计算
 * 
 * @example
 * ```typescript
 * // 获取 Projection 实例
 * const projection = map.getProjection();
 * 
 * // 地理坐标转屏幕坐标
 * const latLng = new LatLng(39.9, 116.4);
 * const screenPoint = projection.toScreenLocation(latLng);
 * 
 * // 屏幕坐标转地理坐标
 * const location = projection.fromScreenLocation(new Point(100, 100));
 * 
 * // 获取可见区域
 * const visibleRegion = projection.getVisibleRegion();
 * ```
 * 
 * @see {@link https://docs.maplibre.org/android/api/ | MapLibre Android API}
 */
import { NativeMapView } from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import { IPixelCoordinate, PixelCoordinate, Point } from '../geometry/Point';
import { IProjectedMeters, ProjectedMeters } from '../geometry/ProjectedMeters';
import { VisibleRegion } from './VisibleRegion';
import { LatLngBounds } from '../geometry/LatLngBounds';

/**
 * GeometryConstants - 几何常量
 * 参考 Android 实现
 */
class GeometryConstants {
  static readonly MIN_LATITUDE: number = -90.0;
  static readonly MAX_LATITUDE: number = 90.0;
  static readonly MIN_LONGITUDE: number = -180.0;
  static readonly MAX_LONGITUDE: number = 180.0;
  static readonly LONGITUDE_SPAN: number = 360.0;
}

/**
 * Projection 类
 *
 * 提供地图投影相关的工具方法，对齐 Android API
 */
export class Projection {
  private nativeMapView: NativeMapView;
  private viewWidth: number = 0;
  private viewHeight: number = 0;
  private contentPadding: number[] = [0, 0, 0, 0]; // [left, top, right, bottom]
  private static readonly DEFAULT_PIXEL_RATIO: number = 1;

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

  private getPixelRatio(): number {
    try {
      const ratioCandidate = this.nativeMapView.getPixelRatio?.();
      if (typeof ratioCandidate === 'number' && Number.isFinite(ratioCandidate) && ratioCandidate > 0) {
        return ratioCandidate;
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.warn(`[Projection] Failed to read pixel ratio, fallback to 1: ${reason}`);
    }
    return Projection.DEFAULT_PIXEL_RATIO;
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
   * 对应 Android: `toScreenLocation(LatLng)`
   * 对应 iOS: `convertCoordinate:toPointToView:`
   *
   * @param location 地理坐标
   * @returns 屏幕坐标（像素）
   */
  public toScreenLocation(location: LatLng): Point {
    const physical: IPixelCoordinate = this.nativeMapView.pixelForLatLng(location.latitude, location.longitude);
    const pixelRatio = this.getPixelRatio();
    return PixelCoordinate.create(physical.x / pixelRatio, physical.y / pixelRatio);
  }

  /**
   * 将屏幕坐标转换为地理坐标
   * 
   * 对应 Android: `fromScreenLocation(PointF)`
   * 对应 iOS: `convertPoint:toCoordinateFromView:`
   *
   * @param point 屏幕坐标（像素）
   * @returns 地理坐标
   */
  public fromScreenLocation(point: Point): LatLng {
    const pixelRatio = this.getPixelRatio();
    const physicalX = point.x * pixelRatio;
    const physicalY = point.y * pixelRatio;
    return LatLng.fromNative(this.nativeMapView.latLngForPixel(physicalX, physicalY));
  }

  /**
   * 将地理坐标转换为屏幕坐标（旧方法名，保持向后兼容）
   * @deprecated 使用 toScreenLocation 替代
   *
   * @param latLng 地理坐标
   * @returns 屏幕坐标（像素）
   */
  public latLngToScreenLocation(latLng: LatLng): Point {
    return this.toScreenLocation(latLng);
  }

  /**
   * 将屏幕坐标转换为地理坐标（旧方法名，保持向后兼容）
   * @deprecated 使用 fromScreenLocation 替代
   *
   * @param point 屏幕坐标（像素）
   * @returns 地理坐标
   */
  public screenLocationToLatLng(point: Point): LatLng {
    return this.fromScreenLocation(point);
  }

  // ========== 批量坐标转换 ==========

  /**
   * 批量将地理坐标转换为屏幕坐标（Android 风格）
   * 
   * 对应 Android: `toScreenLocations(double[], double[])`
   * 
   * @param input 输入数组，格式为 [lat1, lng1, lat2, lng2, ...]
   * @param output 输出数组，格式为 [x1, y1, x2, y2, ...]
   */
  public toScreenLocations(input: number[], output: number[]): void {
    if (input.length % 2 !== 0) {
      throw new Error('Input array length must be even (lat/lng pairs)');
    }
    
    if (output.length < input.length) {
      throw new Error('Output array must be at least as long as input array');
    }
    
    const pixelRatio = this.getPixelRatio();
    for (let i = 0; i < input.length; i += 2) {
      const lat = input[i];
      const lng = input[i + 1];
      const physical: IPixelCoordinate = this.nativeMapView.pixelForLatLng(lat, lng);
      output[i] = physical.x / pixelRatio;
      output[i + 1] = physical.y / pixelRatio;
    }
  }

  /**
   * 批量将屏幕坐标转换为地理坐标（Android 风格）
   * 
   * 对应 Android: `fromScreenLocations(double[], double[])`
   * 
   * @param input 输入数组，格式为 [x1, y1, x2, y2, ...]
   * @param output 输出数组，格式为 [lat1, lng1, lat2, lng2, ...]
   */
  public fromScreenLocations(input: number[], output: number[]): void {
    if (input.length % 2 !== 0) {
      throw new Error('Input array length must be even (x/y pairs)');
    }
    
    if (output.length < input.length) {
      throw new Error('Output array must be at least as long as input array');
    }
    
    const pixelRatio = this.getPixelRatio();
    for (let i = 0; i < input.length; i += 2) {
      const physicalX = input[i] * pixelRatio;
      const physicalY = input[i + 1] * pixelRatio;
      const latLng = this.nativeMapView.latLngForPixel(physicalX, physicalY);
      output[i] = latLng.latitude;
      output[i + 1] = latLng.longitude;
    }
  }

  /**
   * 批量将地理坐标转换为屏幕坐标（旧方法名，保持向后兼容）
   * @deprecated 使用数组版本的 toScreenLocations 或遍历调用 toScreenLocation
   *
   * @param latLngs 地理坐标数组
   * @returns 屏幕坐标数组
   */
  public latLngsToScreenLocations(latLngs: LatLng[]): Point[] {
    const points: Point[] = [];
    for (const latLng of latLngs) {
      points.push(this.toScreenLocation(latLng));
    }
    return points;
  }

  /**
   * 批量将屏幕坐标转换为地理坐标（旧方法名，保持向后兼容）
   * @deprecated 使用数组版本的 fromScreenLocations 或遍历调用 fromScreenLocation
   *
   * @param points 屏幕坐标数组
   * @returns 地理坐标数组
   */
  public screenLocationsToLatLngs(points: Point[]): LatLng[] {
    const latLngs: LatLng[] = [];
    for (const point of points) {
      latLngs.push(this.fromScreenLocation(point));
    }
    return latLngs;
  }

  // ========== 可见区域 ==========

  /**
   * 获取当前地图的可见区域
   * 
   * 返回屏幕四个角对应的地理坐标和包含整个区域的边界。
   * 
   * 对应 Android: `getVisibleRegion()` / `getVisibleRegion(boolean)`
   * 对应 iOS: `visibleCoordinateBounds`
   *
   * @param ignorePadding 是否忽略内容边距。
   *                      - true: 返回整个地图视图的可见区域（默认）
   *                      - false: 返回扣除内容边距后的可见区域
   * @returns 可见区域对象
   * 
   * @example
   * ```typescript
   * // 获取整个地图的可见区域（忽略边距）
   * const fullRegion = projection.getVisibleRegion();
   * 
   * // 获取扣除边距后的可见区域
   * const paddedRegion = projection.getVisibleRegion(false);
   * ```
   */
  public getVisibleRegion(ignorePadding: boolean = true): VisibleRegion {
    let left: number, right: number, top: number, bottom: number;
    
    if (ignorePadding) {
      // 忽略边距，使用完整视图尺寸
      left = 0;
      right = this.viewWidth;
      top = 0;
      bottom = this.viewHeight;
    } else {
      // 考虑内容边距
      // contentPadding: [left, top, right, bottom]
      left = this.contentPadding[0];
      right = this.viewWidth - this.contentPadding[2];
      top = this.contentPadding[1];
      bottom = this.viewHeight - this.contentPadding[3];
    }
    
    // 计算中心点
    const centerX = left + (right - left) / 2;
    const centerY = top + (bottom - top) / 2;
    const center = this.fromScreenLocation(PixelCoordinate.create(centerX, centerY));
    
    // 获取四个角点的地理坐标
    // 注意：屏幕坐标系原点在左上角
    const topLeft = this.fromScreenLocation(PixelCoordinate.create(left, top));
    const topRight = this.fromScreenLocation(PixelCoordinate.create(right, top));
    const bottomRight = this.fromScreenLocation(PixelCoordinate.create(right, bottom));
    const bottomLeft = this.fromScreenLocation(PixelCoordinate.create(left, bottom));
    
    // 计算包含所有角点的边界（参考 Android 实现）
    const latLngs = [topRight, bottomRight, bottomLeft, topLeft];
    
    let maxEastLonSpan = 0;
    let maxWestLonSpan = 0;
    
    let east = 0;
    let west = 0;
    let north = GeometryConstants.MIN_LATITUDE;
    let south = GeometryConstants.MAX_LATITUDE;
    
    for (const latLng of latLngs) {
      const bearingValue = Projection.bearing(center, latLng);
      
      if (bearingValue >= 0) {
        const span = Projection.getLongitudeSpan(latLng.longitude, center.longitude);
        if (span > maxEastLonSpan) {
          maxEastLonSpan = span;
          east = latLng.longitude;
        }
      } else {
        const span = Projection.getLongitudeSpan(center.longitude, latLng.longitude);
        if (span > maxWestLonSpan) {
          maxWestLonSpan = span;
          west = latLng.longitude;
        }
      }
      
      if (north < latLng.latitude) {
        north = latLng.latitude;
      }
      if (south > latLng.latitude) {
        south = latLng.latitude;
      }
    }
    
    let bounds: LatLngBounds;
    if (east < west) {
      // 边界跨越本初子午线
      const ne = new LatLng(north, east + GeometryConstants.LONGITUDE_SPAN);
      const sw = new LatLng(south, west);
      bounds = LatLngBounds.fromLatLngs(ne, sw);
    } else {
      const ne = new LatLng(north, east);
      const sw = new LatLng(south, west);
      bounds = LatLngBounds.fromLatLngs(ne, sw);
    }
    
    return new VisibleRegion(topLeft, topRight, bottomLeft, bottomRight, bounds);
  }

  /**
   * 获取当前地图的可见坐标边界
   * 
   * 对应 Android: `getVisibleCoordinateBounds(double[])`
   * 
   * 此方法忽略内容边距。
   * 
   * @returns 可见坐标边界 (LatLngBounds)
   */
  public getVisibleCoordinateBounds(): LatLngBounds {
    // 直接从 Native 获取
    const latLngs = this.nativeMapView.getVisibleCoordinateBounds();
    if (latLngs && latLngs.length >= 4) {
      // 返回格式：[topLeft, topRight, bottomRight, bottomLeft]
      // 我们需要构建 LatLngBounds
      const north = Math.max(latLngs[0].latitude, latLngs[1].latitude, 
                             latLngs[2].latitude, latLngs[3].latitude);
      const south = Math.min(latLngs[0].latitude, latLngs[1].latitude,
                             latLngs[2].latitude, latLngs[3].latitude);
      const east = Math.max(latLngs[0].longitude, latLngs[1].longitude,
                            latLngs[2].longitude, latLngs[3].longitude);
      const west = Math.min(latLngs[0].longitude, latLngs[1].longitude,
                            latLngs[2].longitude, latLngs[3].longitude);
      const ne = new LatLng(north, east);
      const sw = new LatLng(south, west);
      return LatLngBounds.fromLatLngs(ne, sw);
    }
    
    // 如果 Native 方法失败，使用 getVisibleRegion 作为后备
    return this.getVisibleRegion(true).latLngBounds;
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
    const zoom: number = this.nativeMapView.getZoom();
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
   * 将地理坐标转换为投影米坐标（Spherical Mercator 投影）
   * 
   * 对应 Android: `getProjectedMetersForLatLng(LatLng)`
   *
   * @param latLng 地理坐标
   * @returns 投影米坐标
   */
  public getProjectedMetersForLatLng(latLng: LatLng): ProjectedMeters {
    const result: IProjectedMeters = this.nativeMapView.projectedMetersForLatLng(latLng.latitude, latLng.longitude);
    return ProjectedMeters.fromObject(result);
  }

  /**
   * 将投影米坐标转换为地理坐标
   * 
   * 对应 Android: `getLatLngForProjectedMeters(ProjectedMeters)`
   *
   * @param projectedMeters 投影米坐标
   * @returns 地理坐标
   */
  public getLatLngForProjectedMeters(projectedMeters: ProjectedMeters): LatLng {
    return LatLng.fromNative(this.nativeMapView.latLngForProjectedMeters(projectedMeters.northing,
      projectedMeters.easting));
  }

  /**
   * 将地理坐标转换为投影米坐标（旧方法名，保持向后兼容）
   * @deprecated 使用 getProjectedMetersForLatLng 替代
   *
   * @param latLng 地理坐标
   * @returns 投影米坐标
   */
  public toProjectedMeters(latLng: LatLng): ProjectedMeters {
    return this.getProjectedMetersForLatLng(latLng);
  }

  /**
   * 将投影米坐标转换为地理坐标（旧方法名，保持向后兼容）
   * @deprecated 使用 getLatLngForProjectedMeters 替代
   *
   * @param projectedMeters 投影米坐标
   * @returns 地理坐标
   */
  public fromProjectedMeters(projectedMeters: ProjectedMeters): LatLng {
    return this.getLatLngForProjectedMeters(projectedMeters);
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

  // ========== 内容边距 (Content Padding) ==========

  /**
   * 设置内容边距
   * 影响地图中心点的计算，使地图逻辑中心偏移
   *
   * 参考 Android: Projection.setContentPadding()
   *
   * @param left 左边距（像素）
   * @param top 上边距（像素）
   * @param right 右边距（像素）
   * @param bottom 下边距（像素）
   */
  public setContentPadding(left: number, top: number, right: number, bottom: number): void {
    // 存储边距值
    this.contentPadding = [left, top, right, bottom];

    // 调用 Native 方法设置边距
    // Native 层期望数组格式: [left, top, right, bottom]
    this.nativeMapView.setContentPadding(this.contentPadding);
  }

  /**
   * 获取当前内容边距
   *
   * 参考 Android: Projection.getContentPadding()
   *
   * @returns [left, top, right, bottom] 边距数组
   */
  public getContentPadding(): number[] {
    // 从 Native 层获取最新的边距值
    try {
      const padding: number[] = this.nativeMapView.getContentPadding();
      if (padding && padding.length === 4) {
        this.contentPadding = padding;
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[Projection] Failed to get content padding from native: ${reason}`);
    }

    // 返回副本，防止外部修改
    return [...this.contentPadding];
  }

  // ========== 静态工具方法 (参考 Android 实现) ==========

  /**
   * 计算两个地理坐标之间的方位角（bearing）
   * 
   * 对应 Android: `Projection.bearing(LatLng, LatLng)`
   * 
   * @param latLng1 起点坐标
   * @param latLng2 终点坐标
   * @returns 方位角（单位：度）
   */
  public static bearing(latLng1: LatLng, latLng2: LatLng): number {
    const lon1 = Projection.degreesToRadians(latLng1.longitude);
    const lon2 = Projection.degreesToRadians(latLng2.longitude);
    const lat1 = Projection.degreesToRadians(latLng1.latitude);
    const lat2 = Projection.degreesToRadians(latLng2.latitude);

    const value1 = Math.sin(lon2 - lon1) * Math.cos(lat2);
    const value2 = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1)
      * Math.cos(lat2) * Math.cos(lon2 - lon1);

    return Projection.radiansToDegrees(Math.atan2(value1, value2));
  }

  /**
   * 将角度转换为弧度
   * 
   * 对应 Android: `Projection.degreesToRadians(double)`
   * 
   * @param degrees 角度（0-360）
   * @returns 弧度
   */
  public static degreesToRadians(degrees: number): number {
    const radians = degrees % 360;
    return radians * Math.PI / 180;
  }

  /**
   * 将弧度转换为角度
   * 
   * 对应 Android: `Projection.radiansToDegrees(double)`
   * 
   * @param radians 弧度
   * @returns 角度（0-360）
   */
  public static radiansToDegrees(radians: number): number {
    const degrees = radians % (2 * Math.PI);
    return degrees * 180 / Math.PI;
  }

  /**
   * 计算东西边界之间的绝对距离（以度为单位）
   * 
   * 对应 Android: `Projection.getLongitudeSpan(double, double)`
   * 
   * @param east 东经
   * @param west 西经
   * @returns 跨度距离（度）
   */
  public static getLongitudeSpan(east: number, west: number): number {
    const longSpan = Math.abs(east - west);
    if (east > west) {
      return longSpan;
    }

    // 最短跨度包含本初子午线
    return GeometryConstants.LONGITUDE_SPAN - longSpan;
  }

  /**
   * 基于最小比例和当前比例计算缩放级别
   * 
   * 对应 Android: `Projection.calculateZoom(float)`
   * 
   * @param minScale 最小比例
   * @returns 适合 MapView 的缩放级别
   */
  public calculateZoom(minScale: number): number {
    return this.nativeMapView.getZoom() + Math.log(minScale) / Math.log(2);
  }
}