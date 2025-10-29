/**
 * SnapshotOptions - 快照选项
 * 
 * 配置 MapSnapshotter 的参数
 */

import { CameraPosition } from '../camera/CameraPosition';
import { LatLngBounds } from '../geometry/LatLngBounds';
import { Size } from '../types/NativeTypes';

/**
 * 快照选项接口
 */
export interface SnapshotOptions {
  /**
   * 输出图像尺寸
   */
  size: Size;
  
  /**
   * 像素比（用于生成高分辨率图像）
   * 默认：1.0
   */
  pixelRatio?: number;
  
  /**
   * 样式 URL
   */
  styleUrl: string;
  
  /**
   * 样式 JSON（可选，与 styleUrl 二选一）
   */
  styleJson?: string;
  
  /**
   * 相机位置（可选）
   */
  cameraPosition?: CameraPosition;
  
  /**
   * 地理边界（可选）
   * 如果提供，将调整相机以适应此边界
   */
  region?: LatLngBounds;
  
  /**
   * 是否显示 MapLibre logo
   * 默认：true
   */
  showLogo?: boolean;
  
  /**
   * 本地字体族（可选）
   */
  localFontFamily?: string;
}

/**
 * 快照选项构建器
 */
export class SnapshotOptionsBuilder {
  private options: SnapshotOptions;
  
  /**
   * 构造函数
   * 
   * @param width 宽度
   * @param height 高度
   */
  constructor(width: number, height: number) {
    this.options = {
      size: { width, height },
      pixelRatio: 1.0,
      styleUrl: '',
      showLogo: true
    };
  }
  
  /**
   * 设置像素比
   */
  withPixelRatio(pixelRatio: number): SnapshotOptionsBuilder {
    this.options.pixelRatio = pixelRatio;
    return this;
  }
  
  /**
   * 设置样式 URL
   */
  withStyleUrl(styleUrl: string): SnapshotOptionsBuilder {
    this.options.styleUrl = styleUrl;
    return this;
  }
  
  /**
   * 设置样式 JSON
   */
  withStyleJson(styleJson: string): SnapshotOptionsBuilder {
    this.options.styleJson = styleJson;
    return this;
  }
  
  /**
   * 设置相机位置
   */
  withCameraPosition(cameraPosition: CameraPosition): SnapshotOptionsBuilder {
    this.options.cameraPosition = cameraPosition;
    return this;
  }
  
  /**
   * 设置地理边界
   */
  withRegion(region: LatLngBounds): SnapshotOptionsBuilder {
    this.options.region = region;
    return this;
  }
  
  /**
   * 设置是否显示 logo
   */
  withShowLogo(showLogo: boolean): SnapshotOptionsBuilder {
    this.options.showLogo = showLogo;
    return this;
  }
  
  /**
   * 设置本地字体族
   */
  withLocalFontFamily(localFontFamily: string): SnapshotOptionsBuilder {
    this.options.localFontFamily = localFontFamily;
    return this;
  }
  
  /**
   * 构建选项对象
   */
  build(): SnapshotOptions {
    if (!this.options.styleUrl && !this.options.styleJson) {
      throw new Error('Must specify either styleUrl or styleJson');
    }
    return this.options;
  }
}

