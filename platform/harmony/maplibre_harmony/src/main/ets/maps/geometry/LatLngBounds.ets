import { LatLng } from './LatLng';
import maplibre from 'libmaplibre.so';

/**
 * LatLngBounds - 经纬度边界类
 */
export class LatLngBounds {
  public north: number;
  public east: number;
  public south: number;
  public west: number;

  constructor(north: number, east: number, south: number, west: number) {
    this.north = north;
    this.east = east;
    this.south = south;
    this.west = west;
  }

  /**
   * 从两个点创建边界
   * 
   * @param northeast 东北角点（纬度更大、经度更大的点）
   * @param southwest 西南角点（纬度更小、经度更小的点）
   * @returns LatLngBounds 边界对象
   * 
   * @example
   * ```typescript
   * const southwest = createLatLng(30.23, 120.12);
   * const northeast = createLatLng(30.31, 120.20);
   * const bounds = LatLngBounds.fromLatLngs(northeast, southwest);
   * ```
   */
  public static fromLatLngs(northeast: LatLng, southwest: LatLng): LatLngBounds {
    // 验证参数
    if (northeast.latitude < southwest.latitude) {
      throw new Error(`Invalid bounds: northeast latitude (${northeast.latitude}) must be >= southwest latitude (${southwest.latitude})`);
    }
    if (northeast.longitude < southwest.longitude) {
      throw new Error(`Invalid bounds: northeast longitude (${northeast.longitude}) must be >= southwest longitude (${southwest.longitude})`);
    }
    
    return new LatLngBounds(northeast.latitude, northeast.longitude, southwest.latitude, southwest.longitude);
  }

  /**
   * 从点数组创建边界
   */
  public static fromLatLngArray(latLngs: LatLng[]): LatLngBounds {
    if (latLngs.length === 0) {
      throw new Error('Cannot create bounds from empty array');
    }

    let north = latLngs[0].latitude;
    let east = latLngs[0].longitude;
    let south = latLngs[0].latitude;
    let west = latLngs[0].longitude;

    for (const latLng of latLngs) {
      north = Math.max(north, latLng.latitude);
      east = Math.max(east, latLng.longitude);
      south = Math.min(south, latLng.latitude);
      west = Math.min(west, latLng.longitude);
    }

    return new LatLngBounds(north, east, south, west);
  }

  /**
   * 获取东北角
   */
  public getNortheast(): LatLng {
    return new maplibre.LatLng(this.north, this.east);
  }

  /**
   * 获取西南角
   */
  public getSouthwest(): LatLng {
    return new maplibre.LatLng(this.south, this.west);
  }

  /**
   * 获取中心点
   */
  public getCenter(): LatLng {
    return new maplibre.LatLng(
      (this.north + this.south) / 2,
      (this.east + this.west) / 2
    );
  }

  /**
   * 检查点是否在边界内
   */
  public contains(latLng: LatLng): boolean {
    return latLng.latitude >= this.south && latLng.latitude <= this.north &&
           latLng.longitude >= this.west && latLng.longitude <= this.east;
  }

  /**
   * 检查边界是否包含另一个边界
   */
  public containsBounds(other: LatLngBounds): boolean {
    return this.north >= other.north && this.south <= other.south &&
           this.east >= other.east && this.west <= other.west;
  }

  /**
   * 检查边界是否与另一个边界相交
   */
  public intersects(other: LatLngBounds): boolean {
    return !(this.south > other.north || this.north < other.south ||
             this.west > other.east || this.east < other.west);
  }

  /**
   * 扩展边界以包含点
   */
  public extend(latLng: LatLng): LatLngBounds {
    return new LatLngBounds(
      Math.max(this.north, latLng.latitude),
      Math.max(this.east, latLng.longitude),
      Math.min(this.south, latLng.latitude),
      Math.min(this.west, latLng.longitude)
    );
  }

  /**
   * 扩展边界以包含另一个边界
   */
  public extendBounds(other: LatLngBounds): LatLngBounds {
    return new LatLngBounds(
      Math.max(this.north, other.north),
      Math.max(this.east, other.east),
      Math.min(this.south, other.south),
      Math.min(this.west, other.west)
    );
  }

  /**
   * 检查边界是否有效
   */
  public isValid(): boolean {
    return this.north >= this.south && this.east >= this.west &&
           this.north >= -90 && this.north <= 90 &&
           this.south >= -90 && this.south <= 90 &&
           this.east >= -180 && this.east <= 180 &&
           this.west >= -180 && this.west <= 180;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `LatLngBounds(${this.north}, ${this.east}, ${this.south}, ${this.west})`;
  }
}
