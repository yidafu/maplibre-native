import { AnnotationType } from './AnnotationType';
import { MapLibreMap } from '../MapLibreMap';

/**
 * Annotation - 标注基类
 * 
 * 所有地图标注的抽象基类，管理标注的 ID、与地图的关联等基础功能。
 * 
 * 参考:
 * - Android: org.maplibre.android.annotations.Annotation
 * 
 * @abstract
 */
export abstract class Annotation {
  /**
   * 标注的唯一 ID
   * -1 表示尚未添加到地图
   * 由 MapLibreMap 在添加标注时分配
   */
  private id: number = -1;
  
  /**
   * 关联的 MapLibreMap 实例
   */
  protected mapLibreMap: MapLibreMap | null = null;
  
  /**
   * 构造函数
   */
  protected constructor() {
  }
  
  /**
   * 获取标注的唯一 ID
   * 
   * @returns 标注 ID，-1 表示尚未添加到地图
   */
  public getId(): number {
    return this.id;
  }
  
  /**
   * 设置标注的 ID
   * 
   * 内部使用，由 MapLibreMap 调用
   * 
   * @param id 标注 ID
   */
  public setId(id: number): void {
    this.id = id;
  }
  
  /**
   * 从地图上移除此标注
   */
  public remove(): void {
    if (this.mapLibreMap === null) {
      return;
    }
    this.mapLibreMap.removeAnnotation(this);
  }
  
  /**
   * 设置关联的 MapLibreMap
   * 
   * 内部使用，由 MapLibreMap 调用
   * 
   * @param map MapLibreMap 实例
   */
  public setMapLibreMap(map: MapLibreMap): void {
    this.mapLibreMap = map;
  }
  
  /**
   * 获取关联的 MapLibreMap
   * 
   * @returns MapLibreMap 实例，如果未添加到地图则返回 null
   */
  public getMapLibreMap(): MapLibreMap | null {
    return this.mapLibreMap;
  }
  
  /**
   * 获取标注类型
   * 
   * 子类必须实现此方法
   * 
   * @returns 标注类型
   */
  public abstract getType(): AnnotationType;
  
  /**
   * 比较两个标注是否相同
   * 
   * @param other 另一个标注
   * @returns true 如果 ID 相同
   */
  public equals(other: Annotation | null): boolean {
    if (this === other) {
      return true;
    }
    if (other === null) {
      return false;
    }
    return this.id === other.getId();
  }
  
  /**
   * 比较两个标注的顺序
   * 
   * @param other 另一个标注
   * @returns -1, 0, 或 1
   */
  public compareTo(other: Annotation): number {
    if (this.id < other.getId()) {
      return -1;
    } else if (this.id > other.getId()) {
      return 1;
    }
    return 0;
  }
  
  /**
   * 获取哈希码
   * 
   * @returns 哈希码
   */
  public hashCode(): number {
    return this.id;
  }
}

