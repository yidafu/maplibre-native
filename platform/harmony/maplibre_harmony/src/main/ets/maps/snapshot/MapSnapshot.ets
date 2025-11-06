/**
 * MapSnapshot - 地图快照结果
 *
 * 包含生成的快照图像和元数据
 * 
 * **平台对照**：
 * - Android: `MapSnapshot` 类
 * - iOS: `MLNMapSnapshot` 类
 * 
 * **坐标转换功能**：
 * - `pixelForLatLng()` - 在快照图像上定位地理坐标（新增）
 * - `latLngForPixel()` - 从快照图像坐标获取地理坐标（新增）
 */

import image from '@ohos.multimedia.image';
import type {
  SnapshotResultNAPI,
  PixelCoordinateResult,
  LatLngResult
} from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import { Point, PixelCoordinate } from '../geometry/Point';

/**
 * 地图快照类
 *
 * 对应 Android 的 MapSnapshot 和 iOS 的快照结果
 */
export class MapSnapshot {
  /**
   * 快照图像
   */
  public readonly image: image.PixelMap;
  /**
   * 图像宽度（像素）
   */
  public readonly width: number;
  /**
   * 图像高度（像素）
   */
  public readonly height: number;
  /**
   * 归属信息列表
   */
  public readonly attributions: string[];
  /**
   * 是否显示 logo
   */
  public readonly showLogo: boolean;
  
  /**
   * Native 快照对象（用于坐标转换）
   * @private
   */
  private nativeSnapshot: SnapshotResultNAPI | null = null;

  /**
   * 构造函数
   */
  constructor(
    image: image.PixelMap,
    width: number,
    height: number,
    attributions: string[] = [],
    showLogo: boolean = true,
    nativeSnapshot?: SnapshotResultNAPI
  ) {
    this.image = image;
    this.width = width;
    this.height = height;
    this.attributions = attributions;
    this.showLogo = showLogo;
    this.nativeSnapshot = nativeSnapshot || null;
  }

  /**
   * 获取图像
   */
  public getImage(): image.PixelMap {
    return this.image;
  }

  /**
   * 获取归属信息
   */
  public getAttributions(): string[] {
    return this.attributions;
  }

  /**
   * 计算地理坐标在快照图像上的像素位置
   * 
   * 对应 Android: `MapSnapshot.pixelForLatLng(LatLng)`
   * 
   * 用于在快照图像上绘制覆盖物（如标记、文字等）时定位元素位置。
   * 
   * @param latLng 地理坐标
   * @returns 快照图像上的像素坐标
   * 
   * @example
   * ```typescript
   * const snapshot = await getSnapshot();
   * const markerPos = new LatLng(39.9, 116.4);
   * const pixelPos = snapshot.pixelForLatLng(markerPos);
   * // 在 pixelPos 位置绘制标记
   * ```
   */
  public pixelForLatLng(latLng: LatLng): Point {
    if (!this.nativeSnapshot) {
      throw new Error('Native snapshot object not available for coordinate conversion');
    }

    try {
      // 调用 native 方法
      const result: PixelCoordinateResult = this.nativeSnapshot.pixelForLatLng(latLng.latitude, latLng.longitude);
      return new PixelCoordinate(result.x, result.y);
    } catch (err) {
      const error = err as Error;
      console.error('[MapSnapshot] pixelForLatLng failed:', error.message);
      throw new Error(`Coordinate conversion failed: ${error.message}`);
    }
  }

  /**
   * 计算快照图像上的像素位置对应的地理坐标
   * 
   * 对应 Android: `MapSnapshot.latLngForPixel(PointF)`
   * 
   * 用于识别用户在快照图像上点击的位置对应的地理坐标。
   * 
   * @param point 快照图像上的像素坐标
   * @returns 地理坐标
   * 
   * @example
   * ```typescript
   * const snapshot = await getSnapshot();
   * const clickPoint = new Point(100, 200);
   * const latLng = snapshot.latLngForPixel(clickPoint);
   * console.log('点击位置:', latLng.latitude, latLng.longitude);
   * ```
   */
  public latLngForPixel(point: Point): LatLng {
    if (!this.nativeSnapshot) {
      throw new Error('Native snapshot object not available for coordinate conversion');
    }

    try {
      // 调用 native 方法
      const result: LatLngResult = this.nativeSnapshot.latLngForPixel(point.x, point.y);
      return new LatLng(result.latitude, result.longitude);
    } catch (err) {
      const error = err as Error;
      console.error('[MapSnapshot] latLngForPixel failed:', error.message);
      throw new Error(`Coordinate conversion failed: ${error.message}`);
    }
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `MapSnapshot{size=${this.width}x${this.height}, ` +
      `attributions=${this.attributions.length}, ` +
      `showLogo=${this.showLogo}}`;
  }
}

