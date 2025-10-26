import { Geometry, Coordinates } from './Geometry';

/**
 * Point - GeoJSON Point 几何体
 */
export class Point extends Geometry {
  constructor(coordinates: number[]) {
    super('Point', coordinates);
    if (coordinates.length < 2) {
      throw new Error('Point coordinates must have at least 2 elements [lng, lat]');
    }
  }

  /**
   * 从经纬度创建 Point
   */
  static fromLngLat(lng: number, lat: number, altitude?: number): Point {
    const coordinates = altitude !== undefined ? [lng, lat, altitude] : [lng, lat];
    return new Point(coordinates);
  }

  /**
   * 获取经度
   */
  getLongitude(): number {
    return (this.coordinates as number[])[0];
  }

  /**
   * 获取纬度
   */
  getLatitude(): number {
    return (this.coordinates as number[])[1];
  }

  /**
   * 获取高度（如果存在）
   */
  getAltitude(): number | undefined {
    const coords = this.coordinates as number[];
    return coords.length > 2 ? coords[2] : undefined;
  }

  /**
   * 设置经度
   */
  setLongitude(lng: number): void {
    (this.coordinates as number[])[0] = lng;
  }

  /**
   * 设置纬度
   */
  setLatitude(lat: number): void {
    (this.coordinates as number[])[1] = lat;
  }
}

