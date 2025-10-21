/**
 * LatLng - 经纬度坐标类
 */
export class LatLng {
  public latitude: number;
  public longitude: number;

  constructor(latitude: number, longitude: number) {
    this.latitude = latitude;
    this.longitude = longitude;
  }

  /**
   * 创建LatLng对象
   */
  public static fromLatLng(latitude: number, longitude: number): LatLng {
    return new LatLng(latitude, longitude);
  }

  /**
   * 检查坐标是否有效
   */
  public isValid(): boolean {
    return this.latitude >= -90 && this.latitude <= 90 && 
           this.longitude >= -180 && this.longitude <= 180;
  }

  /**
   * 计算到另一个点的距离（米）
   */
  public distanceTo(other: LatLng): number {
    const R = 6371000; // 地球半径（米）
    const dLat = this.toRadians(other.latitude - this.latitude);
    const dLon = this.toRadians(other.longitude - this.longitude);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(this.toRadians(this.latitude)) * Math.cos(this.toRadians(other.latitude)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * 角度转弧度
   */
  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `LatLng(${this.latitude}, ${this.longitude})`;
  }

  /**
   * 比较两个坐标是否相等
   */
  public equals(other: LatLng): boolean {
    return Math.abs(this.latitude - other.latitude) < 1e-10 &&
           Math.abs(this.longitude - other.longitude) < 1e-10;
  }
}
