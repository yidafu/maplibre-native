/**
 * MapSnapshotter - 地图快照器
 * 
 * 用于在后台渲染地图并生成图像
 * 对应 Android 的 MapSnapshotter 和 iOS 的 MLNMapSnapshotter
 */

import maplibre from 'libmaplibre_native.so';
import image from '@ohos.multimedia.image';
import { SnapshotOptions } from './SnapshotOptions';
import { MapSnapshot } from './MapSnapshot';
import { CameraPosition } from '../camera/CameraPosition';
import { LatLngBounds } from '../geometry/LatLngBounds';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * 快照就绪回调
 */
export interface SnapshotReadyCallback {
  /**
   * 快照完成时调用
   * 
   * @param snapshot 快照对象
   */
  onSnapshotReady(snapshot: MapSnapshot): void;
}

/**
 * 错误处理回调
 */
export interface SnapshotErrorHandler {
  /**
   * 发生错误时调用
   * 
   * @param error 错误消息
   */
  onError(error: string): void;
}

/**
 * MapSnapshotter 类
 * 
 * 使用示例：
 * ```typescript
 * // 1. 创建选项
 * const options: SnapshotOptions = {
 *   size: { width: 1080, height: 1920 },
 *   pixelRatio: 3.0,
 *   styleUrl: 'https://demotiles.maplibre.org/style.json',
 *   cameraPosition: {
 *     target: createLatLng(30.27, 120.15),
 *     zoom: 12,
 *     bearing: 0,
 *     tilt: 0
 *   },
 *   showLogo: true
 * };
 * 
 * // 2. 创建快照器
 * const snapshotter = new MapSnapshotter(options);
 * 
 * // 3. 开始生成快照
 * snapshotter.start({
 *   onSnapshotReady: (snapshot) => {
 *     console.log('快照完成！');
 *     const pixelMap = snapshot.getImage();
 *     // 使用 pixelMap
 *   }
 * }, {
 *   onError: (error) => {
 *     console.error(`快照失败: ${error}`);
 *   }
 * });
 * ```
 */
export class MapSnapshotter {
  private nativeSnapshotter: any | null = null;
  private options: SnapshotOptions;
  private cancelled: boolean = false;
  
  /**
   * 构造函数
   * 
   * @param options 快照选项
   */
  constructor(options: SnapshotOptions) {
    this.options = options;
    
    try {
      // 准备 NAPI 选项对象
      const napiOptions = {
        width: options.size.width,
        height: options.size.height,
        pixelRatio: options.pixelRatio || 1.0,
        styleUrl: options.styleUrl,
        styleJson: options.styleJson,
        showLogo: options.showLogo !== false,
        localFontFamily: options.localFontFamily || ''
      };
      
      // 创建 native snapshotter
      // 注意：这需要在 NAPI 模块中实现 createMapSnapshotter
      this.nativeSnapshotter = maplibre.createMapSnapshotter(napiOptions);
      
      hilog.info(DOMAIN, 'MapSnapshotter', 
        `Created snapshotter: ${options.size.width}x${options.size.height} @ ${napiOptions.pixelRatio}x`);
      
      // 设置相机位置（如果提供）
      if (options.cameraPosition) {
        this.setCameraPosition(options.cameraPosition);
      }
      
      // 设置区域（如果提供）
      if (options.region) {
        this.setRegion(options.region);
      }
      
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to create snapshotter: ${error}`);
      throw error;
    }
  }
  
  /**
   * 开始生成快照
   * 
   * @param callback 完成回调
   * @param errorHandler 错误处理回调（可选）
   */
  public start(
    callback: SnapshotReadyCallback,
    errorHandler?: SnapshotErrorHandler
  ): void {
    if (!this.nativeSnapshotter) {
      const error = 'Snapshotter not initialized';
      hilog.error(DOMAIN, 'MapSnapshotter', error);
      if (errorHandler) {
        errorHandler.onError(error);
      }
      return;
    }
    
    if (this.cancelled) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Snapshotter was cancelled');
      return;
    }
    
    hilog.info(DOMAIN, 'MapSnapshotter', 'Starting snapshot generation');
    
    try {
      // 调用 native start 方法
      this.nativeSnapshotter.start((error: string | null, result: any) => {
        if (error) {
          hilog.error(DOMAIN, 'MapSnapshotter', `Snapshot error: ${error}`);
          if (errorHandler) {
            errorHandler.onError(error);
          }
          return;
        }
        
        if (!result) {
          const errorMsg = 'No result returned from native snapshotter';
          hilog.error(DOMAIN, 'MapSnapshotter', errorMsg);
          if (errorHandler) {
            errorHandler.onError(errorMsg);
          }
          return;
        }
        
        // 从 native 结果创建 PixelMap
        this.createPixelMapFromNativeResult(result)
          .then(pixelMap => {
            const snapshot = new MapSnapshot(
              pixelMap,
              result.width,
              result.height,
              result.attributions || [],
              this.options.showLogo !== false
            );
            
            hilog.info(DOMAIN, 'MapSnapshotter', `Snapshot ready: ${result.width}x${result.height}`);
            callback.onSnapshotReady(snapshot);
          })
          .catch(err => {
            hilog.error(DOMAIN, 'MapSnapshotter', `Failed to create PixelMap: ${err}`);
            if (errorHandler) {
              errorHandler.onError(`Failed to create PixelMap: ${err}`);
            }
          });
      });
      
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Start failed: ${error}`);
      if (errorHandler) {
        errorHandler.onError(`${error}`);
      }
    }
  }
  
  /**
   * 取消快照生成
   */
  public cancel(): void {
    if (!this.nativeSnapshotter) {
      return;
    }
    
    hilog.info(DOMAIN, 'MapSnapshotter', 'Cancelling snapshot');
    this.cancelled = true;
    
    try {
      this.nativeSnapshotter.cancel();
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Cancel failed: ${error}`);
    }
  }
  
  /**
   * 设置样式 URL
   */
  public setStyleUrl(styleUrl: string): void {
    if (!this.nativeSnapshotter) {
      return;
    }
    
    try {
      this.nativeSnapshotter.setStyleUrl(styleUrl);
      this.options.styleUrl = styleUrl;
      hilog.info(DOMAIN, 'MapSnapshotter', `Style URL set: ${styleUrl}`);
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set style URL: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取样式 URL
   */
  public getStyleUrl(): string {
    return this.options.styleUrl;
  }
  
  /**
   * 设置相机位置
   */
  public setCameraPosition(cameraPosition: CameraPosition): void {
    if (!this.nativeSnapshotter) {
      return;
    }
    
    try {
      this.nativeSnapshotter.setCameraPosition(cameraPosition);
      this.options.cameraPosition = cameraPosition;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Camera position set');
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set camera position: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取相机位置
   */
  public getCameraPosition(): CameraPosition | undefined {
    return this.options.cameraPosition;
  }
  
  /**
   * 设置区域
   */
  public setRegion(region: LatLngBounds): void {
    if (!this.nativeSnapshotter) {
      return;
    }
    
    try {
      this.nativeSnapshotter.setRegion(region);
      this.options.region = region;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Region set');
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set region: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取区域
   */
  public getRegion(): LatLngBounds | undefined {
    return this.options.region;
  }
  
  /**
   * 从 native 结果创建 PixelMap
   * 
   * @param result Native 返回的结果对象
   * @returns Promise<PixelMap>
   */
  private async createPixelMapFromNativeResult(result: any): Promise<image.PixelMap> {
    return new Promise((resolve, reject) => {
      try {
        const imageInfo: image.ImageInfo = {
          size: { height: result.height, width: result.width },
          pixelFormat: image.PixelMapFormat.RGBA_8888,
          alphaType: image.AlphaType.PREMUL
        };
        
        // 从 ArrayBuffer 创建 PixelMap
        image.createPixelMap(result.data, imageInfo, (err, pixelMap) => {
          if (err) {
            reject(err);
          } else {
            resolve(pixelMap);
          }
        });
      } catch (error) {
        reject(error);
      }
    });
  }
}

