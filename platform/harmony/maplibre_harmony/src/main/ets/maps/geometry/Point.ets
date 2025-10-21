/**
 * Point - 2D点坐标类
 */
export class Point {
  public x: number;
  public y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }

  /**
   * 创建Point对象
   */
  public static fromPoint(x: number, y: number): Point {
    return new Point(x, y);
  }

  /**
   * 计算到另一个点的距离
   */
  public distanceTo(other: Point): number {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * 计算到另一个点的平方距离（用于性能优化）
   */
  public distanceSquaredTo(other: Point): number {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    return dx * dx + dy * dy;
  }

  /**
   * 计算中点
   */
  public midpoint(other: Point): Point {
    return new Point((this.x + other.x) / 2, (this.y + other.y) / 2);
  }

  /**
   * 计算向量加法
   */
  public add(other: Point): Point {
    return new Point(this.x + other.x, this.y + other.y);
  }

  /**
   * 计算向量减法
   */
  public subtract(other: Point): Point {
    return new Point(this.x - other.x, this.y - other.y);
  }

  /**
   * 计算标量乘法
   */
  public multiply(scalar: number): Point {
    return new Point(this.x * scalar, this.y * scalar);
  }

  /**
   * 计算标量除法
   */
  public divide(scalar: number): Point {
    return new Point(this.x / scalar, this.y / scalar);
  }

  /**
   * 计算点积
   */
  public dot(other: Point): number {
    return this.x * other.x + this.y * other.y;
  }

  /**
   * 计算叉积
   */
  public cross(other: Point): number {
    return this.x * other.y - this.y * other.x;
  }

  /**
   * 计算向量的长度
   */
  public length(): number {
    return Math.sqrt(this.x * this.x + this.y * this.y);
  }

  /**
   * 计算向量的平方长度
   */
  public lengthSquared(): number {
    return this.x * this.x + this.y * this.y;
  }

  /**
   * 标准化向量
   */
  public normalize(): Point {
    const len = this.length();
    if (len === 0) {
      return new Point(0, 0);
    }
    return new Point(this.x / len, this.y / len);
  }

  /**
   * 比较两个点是否相等
   */
  public equals(other: Point): boolean {
    return Math.abs(this.x - other.x) < 1e-10 && Math.abs(this.y - other.y) < 1e-10;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Point(${this.x}, ${this.y})`;
  }
}
