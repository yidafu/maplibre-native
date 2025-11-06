/**
 * MapSnapshotter - 地图快照器
 *
 * 用于在后台渲染地图并生成图像
 * 对应 Android 的 MapSnapshotter 和 iOS 的 MLNMapSnapshotter
 */

import maplibre, {
  MapSnapshotterNAPI,
  SnapshotOptionsNAPI,
  SnapshotResultNAPI
} from 'libmaplibre.so';
import type { 
  Layer, 
  Source,
  CameraPositionLike,
  LatLngBoundsLike,
  MapSnapshotterObserver as NativeMapSnapshotterObserver
} from 'libmaplibre.so';
import image from '@ohos.multimedia.image';
import { SnapshotOptions } from './SnapshotOptions';
import { MapSnapshot } from './MapSnapshot';
import { CameraPosition } from '../camera/CameraPosition';
import { LatLngBounds } from '../geometry/LatLngBounds';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

export type { MapSnapshotterObserver } from 'libmaplibre.so';

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
  private nativeSnapshotter: MapSnapshotterNAPI | null = null;
  private options: SnapshotOptions;
  private cancelled: boolean = false;
  private observer: NativeMapSnapshotterObserver | null = null;

  /**
   * 构造函数
   *
   * @param options 快照选项
   */
  constructor(options: SnapshotOptions) {
    this.options = options;

    try {
      // 准备 NAPI 选项对象
      const napiOptions: SnapshotOptionsNAPI = {
        width: options.size.width,
        height: options.size.height,
        pixelRatio: options.pixelRatio || 1.0,
        styleUrl: options.styleUrl,
        styleJson: options.styleJson,
        showLogo: options.showLogo !== false,
        localFontFamily: options.localFontFamily || ''
      };

      // 如果提供了相机位置，转换为普通对象并添加到选项中
      if (options.cameraPosition) {
        const cameraData: CameraPositionLike = {
          target: {
            latitude: options.cameraPosition.target.latitude,
            longitude: options.cameraPosition.target.longitude
          },
          zoom: options.cameraPosition.zoom,
          bearing: options.cameraPosition.bearing,
          tilt: options.cameraPosition.tilt
        };
        napiOptions.camera = cameraData;
      }

      // 如果提供了区域，转换为普通对象并添加到选项中
      if (options.region) {
        const regionData: LatLngBoundsLike = {
          north: options.region.north,
          south: options.region.south,
          east: options.region.east,
          west: options.region.west
        };
        napiOptions.region = regionData;
      }

      // 创建 native snapshotter
      this.nativeSnapshotter = maplibre.createMapSnapshotter(napiOptions);

    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to create snapshotter: ${error}`);
      throw new Error(`Failed to create snapshotter: ${error}`);
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

    try {
      // 包装回调以处理单参数回调（ThreadSafeCallback 的限制）
      // Native 层使用 ThreadSafeCallback 会传递单个参数：
      // - 错误时传递 error 字符串
      // - 成功时传递 result 对象
      this.nativeSnapshotter.start((param: string | SnapshotResultNAPI | null) => {
        // 判断参数类型
        if (typeof param === 'string') {
          // 错误：param 是错误消息字符串
          hilog.error(DOMAIN, 'MapSnapshotter', `Snapshot error: ${param}`);
          if (errorHandler) {
            errorHandler.onError(param);
          }
          return;
        }

        const result = param as SnapshotResultNAPI | null;
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
            // 创建 MapSnapshot 对象，传递 native 对象以支持坐标转换
            const snapshot = new MapSnapshot(
              pixelMap,
              result.width,
              result.height,
              result.attributions || [],
              this.options.showLogo !== false,
              result  // 传递 native 快照对象
            );

            callback.onSnapshotReady(snapshot);
          })
          .catch((err: Error) => {
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
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      this.nativeSnapshotter.setStyleUrl(styleUrl);
      this.options.styleUrl = styleUrl;
      hilog.info(DOMAIN, 'MapSnapshotter', `Style URL set: ${styleUrl}`);
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set style URL: ${error}`);
      throw new Error(`Failed to set style URL: ${error}`);
    }
  }

  /**
   * 设置样式 JSON
   */
  public setStyleJson(styleJson: string): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      this.nativeSnapshotter.setStyleJson(styleJson);
      this.options.styleJson = styleJson;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Style JSON set');
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set style JSON: ${error}`);
      throw new Error(`Failed to set style JSON: ${error}`);
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
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      // 将 CameraPosition 转换为普通对象以传递给 native 代码
      const cameraData: CameraPositionLike = {
        target: {
          latitude: cameraPosition.target.latitude,
          longitude: cameraPosition.target.longitude
        },
        zoom: cameraPosition.zoom,
        bearing: cameraPosition.bearing,
        tilt: cameraPosition.tilt
      };
      this.nativeSnapshotter.setCameraPosition(cameraData);
      this.options.cameraPosition = cameraPosition;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Camera position set');
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set camera position: ${error}`);
      throw new Error(`Failed to set camera position: ${error}`);
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
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      // 将 LatLngBounds 转换为普通对象
      const regionData: LatLngBoundsLike = {
        north: region.north,
        south: region.south,
        east: region.east,
        west: region.west
      };
      this.nativeSnapshotter.setRegion(regionData);
      this.options.region = region;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Region set');
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set region: ${error}`);
      throw new Error(`Failed to set region: ${error}`);
    }
  }

  /**
   * 设置快照尺寸
   */
  public setSize(width: number, height: number): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      this.nativeSnapshotter.setSize(width, height);
      this.options.size = { width, height };
      hilog.info(DOMAIN, 'MapSnapshotter', `Size set: ${width}x${height}`);
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set size: ${error}`);
      throw new Error(`Failed to set size: ${error}`);
    }
  }

  /**
   * 设置观察者
   * @param observer 观察者对象，传 null 可清除观察者
   */
  public setObserver(observer: NativeMapSnapshotterObserver | null): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    this.observer = observer;

    try {
      if (observer) {
        this.nativeSnapshotter.setObserver(observer);
        hilog.info(DOMAIN, 'MapSnapshotter', 'Observer set');
      } else {
        this.nativeSnapshotter.setObserver(null);
        hilog.info(DOMAIN, 'MapSnapshotter', 'Observer cleared');
      }
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set observer: ${error}`);
      throw new Error(`Failed to set observer: ${error}`);
    }
  }

  /**
   * 获取区域
   */
  public getRegion(): LatLngBounds | undefined {
    return this.options.region;
  }

  /**
   * 获取图层（样式加载完成后可用）
   * 
   * 对应 Android: `MapSnapshotter.getLayer(String)`
   * 
   * @param layerId 图层ID
   * @returns 图层对象，如果不存在则返回 null
   */
  public getLayer(layerId: string): Layer | null {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return null;
    }

    try {
      return this.nativeSnapshotter.getLayer(layerId) || null;
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to get layer: ${error}`);
      return null;
    }
  }

  /**
   * 获取数据源（样式加载完成后可用）
   * 
   * 对应 Android: `MapSnapshotter.getSource(String)`
   * 
   * @param sourceId 数据源ID
   * @returns 数据源对象，如果不存在则返回 null
   */
  public getSource(sourceId: string): Source | null {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return null;
    }

    try {
      return this.nativeSnapshotter.getSource(sourceId) || null;
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to get source: ${error}`);
      return null;
    }
  }

  /**
   * 添加图片到快照样式
   * 
   * 对应 Android: `MapSnapshotter.addImage(String, Bitmap, boolean)`
   * 
   * 应在 onDidFinishLoadingStyle 回调中调用
   * 
   * @param name 图片名称
   * @param imageData 图片数据（ImageBitmap 或 ArrayBuffer）
   * @param sdf 是否为 SDF（Signed Distance Field）图片
   * 
   * @example
   * ```typescript
   * snapshotter.setObserver({
   *   onDidFinishLoadingStyle: () => {
   *     snapshotter.addImage('custom-marker', imageData, false);
   *   },
   *   onStyleImageMissing: (imageName) => {
   *     console.log('Missing image:', imageName);
   *   }
   * });
   * ```
   */
  public addImage(name: string, imageData: ArrayBuffer | Uint8Array, sdf: boolean = false): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      this.nativeSnapshotter.addImage(name, imageData, sdf);
      hilog.info(DOMAIN, 'MapSnapshotter', `Image added: ${name}`);
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to add image: ${error}`);
      throw new Error(`Failed to add image: ${error}`);
    }
  }

  /**
   * 从 native 结果创建 PixelMap
   *
   * @param result Native 返回的结果对象
   * @returns Promise<PixelMap>
   */
  private async createPixelMapFromNativeResult(result: SnapshotResultNAPI): Promise<image.PixelMap> {
    return new Promise((resolve, reject) => {
      try {
        const imageInfo: image.ImageInfo = {
          size: { height: result.height, width: result.width },
          pixelFormat: image.PixelMapFormat.RGBA_8888,
          alphaType: image.AlphaType.PREMUL,
          density: 160,
          stride: result.width * 4,
          mimeType: 'image/png',
          isHdr: false
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

