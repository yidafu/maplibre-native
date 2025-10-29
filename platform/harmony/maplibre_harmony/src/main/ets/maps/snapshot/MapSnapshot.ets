/**
 * MapSnapshot - 地图快照结果
 * 
 * 包含生成的快照图像和元数据
 */

import image from '@ohos.multimedia.image';
import { LatLng } from '../geometry/LatLng';
import { Point } from '../geometry/Point';

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
   * 构造函数
   */
  constructor(
    image: image.PixelMap,
    width: number,
    height: number,
    attributions: string[] = [],
    showLogo: boolean = true
  ) {
    this.image = image;
    this.width = width;
    this.height = height;
    this.attributions = attributions;
    this.showLogo = showLogo;
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
   * 转换为字符串
   */
  public toString(): string {
    return `MapSnapshot{size=${this.width}x${this.height}, ` +
           `attributions=${this.attributions.length}, ` +
           `showLogo=${this.showLogo}}`;
  }
}

