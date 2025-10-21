/**
 * ProjectedMeters - 投影米坐标类
 */
export class ProjectedMeters {
  public northing: number;
  public easting: number;

  constructor(northing: number, easting: number) {
    this.northing = northing;
    this.easting = easting;
  }

  /**
   * 创建ProjectedMeters对象
   */
  public static fromProjectedMeters(northing: number, easting: number): ProjectedMeters {
    return new ProjectedMeters(northing, easting);
  }

  /**
   * 计算到另一个点的距离
   */
  public distanceTo(other: ProjectedMeters): number {
    const dx = this.easting - other.easting;
    const dy = this.northing - other.northing;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * 计算到另一个点的平方距离
   */
  public distanceSquaredTo(other: ProjectedMeters): number {
    const dx = this.easting - other.easting;
    const dy = this.northing - other.northing;
    return dx * dx + dy * dy;
  }

  /**
   * 计算中点
   */
  public midpoint(other: ProjectedMeters): ProjectedMeters {
    return new ProjectedMeters(
      (this.northing + other.northing) / 2,
      (this.easting + other.easting) / 2
    );
  }

  /**
   * 计算向量加法
   */
  public add(other: ProjectedMeters): ProjectedMeters {
    return new ProjectedMeters(
      this.northing + other.northing,
      this.easting + other.easting
    );
  }

  /**
   * 计算向量减法
   */
  public subtract(other: ProjectedMeters): ProjectedMeters {
    return new ProjectedMeters(
      this.northing - other.northing,
      this.easting - other.easting
    );
  }

  /**
   * 计算标量乘法
   */
  public multiply(scalar: number): ProjectedMeters {
    return new ProjectedMeters(
      this.northing * scalar,
      this.easting * scalar
    );
  }

  /**
   * 计算标量除法
   */
  public divide(scalar: number): ProjectedMeters {
    return new ProjectedMeters(
      this.northing / scalar,
      this.easting / scalar
    );
  }

  /**
   * 计算点积
   */
  public dot(other: ProjectedMeters): number {
    return this.northing * other.northing + this.easting * other.easting;
  }

  /**
   * 计算叉积
   */
  public cross(other: ProjectedMeters): number {
    return this.northing * other.easting - this.easting * other.northing;
  }

  /**
   * 计算向量的长度
   */
  public length(): number {
    return Math.sqrt(this.northing * this.northing + this.easting * this.easting);
  }

  /**
   * 计算向量的平方长度
   */
  public lengthSquared(): number {
    return this.northing * this.northing + this.easting * this.easting;
  }

  /**
   * 标准化向量
   */
  public normalize(): ProjectedMeters {
    const len = this.length();
    if (len === 0) {
      return new ProjectedMeters(0, 0);
    }
    return new ProjectedMeters(this.northing / len, this.easting / len);
  }

  /**
   * 比较两个投影米坐标是否相等
   */
  public equals(other: ProjectedMeters): boolean {
    return Math.abs(this.northing - other.northing) < 1e-10 &&
           Math.abs(this.easting - other.easting) < 1e-10;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `ProjectedMeters(northing=${this.northing}, easting=${this.easting})`;
  }
}
