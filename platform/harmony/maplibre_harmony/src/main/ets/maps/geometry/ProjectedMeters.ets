/**
 * ProjectedMeters - 投影米坐标
 * ETS 类实现
 */

/**
 * IProjectedMeters - 投影米坐标接口
 * 用于对象字面量
 */
export interface IProjectedMeters {
  northing: number;
  easting: number;
}

/**
 * ProjectedMeters - 投影米坐标类
 * 表示投影坐标系中的坐标（单位：米）
 */
export class ProjectedMeters implements IProjectedMeters {
  northing: number;
  easting: number;

  constructor(northing: number = 0, easting: number = 0) {
    this.northing = northing;
    this.easting = easting;
  }

  /**
   * 从对象字面量创建 ProjectedMeters 实例
   */
  static fromObject(obj: IProjectedMeters): ProjectedMeters {
    return new ProjectedMeters(obj.northing, obj.easting);
  }

  /**
   * 转换为对象字面量
   */
  toObject(): IProjectedMeters {
    return {
      northing: this.northing,
      easting: this.easting
    };
  }

  /**
   * 创建投影米坐标（静态工厂方法）
   */
  static create(northing: number, easting: number): ProjectedMeters {
    return new ProjectedMeters(northing, easting);
  }

  /**
   * 计算到另一个点的距离
   */
  distanceTo(other: ProjectedMeters): number {
    const dx = this.easting - other.easting;
    const dy = this.northing - other.northing;
    return Math.sqrt(dx * dx + dy * dy);
  }
}

