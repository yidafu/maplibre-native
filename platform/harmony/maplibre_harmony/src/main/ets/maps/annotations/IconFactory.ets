import image from '@ohos.multimedia.image';
import resourceManager from '@ohos.resourceManager';
import fs from '@ohos.file.fs';
import maplibre from 'libmaplibre.so';
import { TooManyIconsException } from '../exceptions/TooManyIconsException';
import { Icon } from './Icon';

/**
 * 颜色信息接口
 */
interface ColorInfo {
  red: number;
  green: number;
  blue: number;
  alpha: number;
}

/**
 * IconFactory - 图标工厂类（单例）
 *
 * 基于 NAPI Icon 类实现的图标工厂，用于创建和管理地图图标。
 *
 * 支持的图标来源：
 * - PixelMap 对象：直接从内存中的位图创建
 * - 资源 ID：从应用资源（$r）创建
 * - 文件路径：从文件系统加载图片
 * - Rawfile 资源：从 rawfile 目录加载图片
 *
 * **核心优化**：
 * - Icon 图像数据在 C++ 层管理，避免重复的 PixelMap-to-bytes 转换
 * - 单例模式确保全局唯一的工厂实例
 * - 自动管理 Icon ID 生成，防止 ID 冲突
 * - 缓存默认图标，提高性能
 *
 * **生命周期管理**：
 * - Icon 对象由 IconManager 通过引用计数管理
 * - 当 Icon 被释放后（isReleased() == true），不能再使用
 * - 需要重新使用相同图标时，必须创建新的 Icon 实例
 *
 * 参考:
 * - Android: org.maplibre.android.annotations.IconFactory
 * - NAPI: IconNAPI C++ 实现
 *
 * @example
* ```typescript
 * const factory = IconFactory.getInstance();
 *
 * // 从资源创建
 * const icon1 = await factory.fromResource($r('app.media.marker'));
 * marker.setIcon(icon1);
 *
 * // 从文件创建
 * const icon2 = await factory.fromPath('/data/storage/el2/base/haps/entry/files/marker.png');
 *
 * // 从 PixelMap 创建
 * const icon3 = factory.fromPixelMap(pixelMap);
 *
 * // 获取默认图标
 * const defaultIcon = await factory.defaultMarker();
 *
 * // 注意：清除后重新使用需要重新创建
 * markerManager.clear(); // Icon 会被释放
 * const icon4 = await factory.fromResource($r('app.media.marker')); // 重新创建
 * ```
 */
export class IconFactory {
  private static readonly ICON_ID_PREFIX = 'com.maplibre.icons.icon_';
  private static readonly MAX_ICONS = 1000000; // 防止 ID 溢出

  // 默认图标名称 - 用于 SymbolLayer 引用
  public static readonly DEFAULT_MARKER_ICON_ID = 'com.maplibre.marker.default';
  private static instance: IconFactory | null = null;
  private nextId: number = 0;
  private defaultMarkerIcon: Icon | null = null;
  private resourceMgr: resourceManager.ResourceManager | null = null;
  private pixelRatio: number = 1.0;

  /**
   * 私有构造函数（单例模式）
   *
   * @param resourceMgr 可选的 ResourceManager，用于加载应用资源
   */
  private constructor(resourceMgr?: resourceManager.ResourceManager) {
    this.resourceMgr = resourceMgr || null;
    this.pixelRatio = 1.0; // 默认像素密度，可通过 setPixelRatio() 更新
  }

  /**
   * 获取 IconFactory 单例实例
   *
   * @param resourceMgr 可选的 ResourceManager，用于加载资源
   * @returns IconFactory 实例
   */
  public static getInstance(resourceMgr?: resourceManager.ResourceManager): IconFactory {
    if (!IconFactory.instance) {
      IconFactory.instance = new IconFactory(resourceMgr);
    } else if (resourceMgr && !IconFactory.instance.resourceMgr) {
      // 如果之前没有设置 ResourceManager，现在设置
      IconFactory.instance.resourceMgr = resourceMgr;
    }
    return IconFactory.instance;
  }

  /**
   * 设置 ResourceManager
   *
   * @param resourceMgr ResourceManager 实例
   */
  public setResourceManager(resourceMgr: resourceManager.ResourceManager): void {
    this.resourceMgr = resourceMgr;
  }

  /**
   * 设置像素密度比例
   *
   * @param pixelRatio 像素密度比例
   */
  public setPixelRatio(pixelRatio: number): void {
    this.pixelRatio = pixelRatio;
  }

  /**
   * 从 PixelMap 创建图标（Legacy 方法）
   *
   * **性能警告**：此方法需要将 PixelMap 跨 NAPI 边界复制，存在性能开销。
   * 推荐使用 fromResource() 或 fromPath() 方法，它们在 C++ 层直接解码图片，
   * 避免 PixelMap 创建和数据复制开销。
   *
   * @param pixelMap PixelMap 对象（HarmonyOS 图像对象）
   * @param iconId 可选的图标ID，如果不提供则自动生成
   * @returns Icon 封装类实例
   * @throws TooManyIconsException 如果 ID 计数器溢出
   * @throws Error 如果 PixelMap 无效或创建失败
   *
   * @deprecated 推荐使用 fromResource() 或 fromPath() 以获得更好的性能
   */
  public fromPixelMap(pixelMap: image.PixelMap, iconId?: string): Icon {
    // 性能警告：此方法存在 PixelMap 数据复制开销
    console.warn('[IconFactory] fromPixelMap has performance overhead. ' +
      'Consider using fromResource() or fromPath() for better performance.');

    const id = iconId || this.generateUniqueIconId();

    // 使用封装类的内部创建方法
    return Icon.createInternal(id, pixelMap, this.pixelRatio);
  }

  /**
   * 从 PixelMap 创建图标（带复用标识符）
   *
   * **注意**：NAPI Icon 不支持 reuseIdentifier 参数。
   * 此方法保留是为了向后兼容，实际上会忽略 reuseIdentifier。
   * 图标复用应该由 IconManager 通过 Icon ID 来管理。
   *
   * @param pixelMap PixelMap 对象
   * @param reuseIdentifier 复用标识符（已弃用，将被忽略）
   * @returns Icon 封装类实例
   * @throws TooManyIconsException 如果 ID 计数器溢出
   * @deprecated 建议直接使用 fromPixelMap()，由 IconManager 管理图标复用
   */
  public fromPixelMapWithIdentifier(pixelMap: image.PixelMap, reuseIdentifier: string): Icon {
    // reuseIdentifier 参数被忽略，NAPI Icon 通过 ID 来唯一标识
    return this.fromPixelMap(pixelMap);
  }

  /**
   * 从应用资源创建图标
   *
   * 从应用的 resources/media 目录加载图片资源并创建 Icon。
   *
   * **性能说明**：当前实现在 ETS 层创建 PixelMap 并传递给 C++。
   * 未来优化：在 C++ 层直接解码图片数据，避免 PixelMap 创建和数据复制。
   *
   * @param resource 资源对象 (使用 $r 语法，例如 $r('app.media.marker'))
   * @param reuseIdentifier 可选的复用标识符（已弃用，将被忽略）
   * @returns Promise<Icon> Icon 封装类实例
   * @throws Error 如果 ResourceManager 未设置
   * @throws Error 如果资源不存在或加载失败
   *
   * @example
  * ```typescript
   * const icon = await iconFactory.fromResource($r('app.media.marker_icon'));
   * ```
   */
  public async fromResource(resource: Resource, reuseIdentifier?: string): Promise<Icon> {
    if (!this.resourceMgr) {
      throw new Error(
        '[IconFactory] ResourceManager not set. ' +
          'Call setResourceManager() first or pass it to getInstance()'
      );
    }

    try {
      // 1. 获取资源内容 (返回 Uint8Array)
      const uint8Array = await this.resourceMgr.getMediaContent(resource);

      // 2. 创建 ImageSource
      const imageSource = image.createImageSource(uint8Array.buffer);
      if (!imageSource) {
        throw new Error('Failed to create ImageSource from resource buffer');
      }

      // 3. 解码为 PixelMap (RGBA_8888 格式，与 NAPI Icon 期望的格式一致)
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });

      // 4. 释放 ImageSource (PixelMap 已创建，不再需要)
      imageSource.release();

      // 5. 创建 Icon (reuseIdentifier 被忽略)
      return this.fromPixelMap(pixelMap);
    } catch (error) {
      throw new Error(`[IconFactory] Failed to load icon from resource: ${error}`);
    }
  }

  /**
   * 从文件路径创建图标
   *
   * 从文件系统中的图片文件加载并创建 Icon。
   *
   * **性能说明**：当前实现在 ETS 层读取文件并创建 PixelMap。
   * 未来优化：在 C++ 层直接读取文件和解码图片。
   *
   * @param absolutePath 图片文件的绝对路径
   * @param reuseIdentifier 可选的复用标识符（已弃用，将被忽略）
   * @returns Promise<Icon> Icon 封装类实例
   * @throws Error 如果文件不存在、不是文件或加载失败
   *
   * @example
  * ```typescript
   * const icon = await iconFactory.fromPath('/data/storage/el2/base/haps/entry/files/marker.png');
   * ```
   */
  public async fromPath(absolutePath: string, reuseIdentifier?: string): Promise<Icon> {
    try {
      // 1. 检查文件是否存在且为文件类型
      const stat = fs.statSync(absolutePath);
      if (!stat.isFile()) {
        throw new Error(`Path is not a file: ${absolutePath}`);
      }

      // 2. 读取文件内容
      const file = fs.openSync(absolutePath, fs.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      // 3. 创建 ImageSource
      const imageSource = image.createImageSource(buffer);
      if (!imageSource) {
        throw new Error('Failed to create ImageSource from file buffer');
      }

      // 4. 解码为 PixelMap
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });

      // 5. 释放 ImageSource
      imageSource.release();

      // 6. 创建 Icon
      return this.fromPixelMap(pixelMap);
    } catch (error) {
      throw new Error(`[IconFactory] Failed to load icon from path '${absolutePath}': ${error}`);
    }
  }

  /**
   * 从 Rawfile 创建图标
   *
   * 从应用的 resources/rawfile 目录加载图片并创建 Icon。
   * Rawfile 是 HarmonyOS 中存放原始资源文件的目录。
   *
   * @param fileName rawfile 文件名 (例如 'marker.png'，不需要路径前缀)
   * @param iconId 可选的图标ID，如果不提供则自动生成
   * @returns Promise<Icon> Icon 封装类实例
   * @throws Error 如果 ResourceManager 未设置
   * @throws Error 如果 rawfile 不存在或加载失败
   *
   * @example
  * ```typescript
   * // 加载 resources/rawfile/marker.png
   * const icon = await iconFactory.fromRawfile('marker.png');
   *
   * // 使用自定义 ID
   * const icon2 = await iconFactory.fromRawfile('marker.png', 'my-custom-marker');
   * ```
   */
  public async fromRawfile(fileName: string, iconId?: string): Promise<Icon> {

    if (!this.resourceMgr) {
      const error = '[IconFactory] ResourceManager not set. ' +
        'Call setResourceManager() first or pass it to getInstance()';
      console.error(error);
      throw new Error(error);
    }

    try {
      // 1. 从 rawfile 获取内容
      const uint8Array = await this.resourceMgr.getRawFileContent(fileName);

      // 2. 创建 ImageSource
      const imageSource = image.createImageSource(uint8Array.buffer);
      if (!imageSource) {
        throw new Error('Failed to create ImageSource from rawfile buffer');
      }

      // 3. 解码为 PixelMap
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });

      // 4. 释放 ImageSource
      imageSource.release();

      // 5. 创建 Icon（可以指定自定义 ID）
      const icon = await this.fromPixelMap(pixelMap, iconId);
      return icon;
    } catch (error) {
      const errorMsg = `[IconFactory] Failed to load icon from rawfile '${fileName}': ${error}`;
      console.error(errorMsg);
      console.error('[IconFactory] Error stack:', error?.stack);
      throw new Error(errorMsg);
    }
  }

  /**
   * 获取默认的 Marker 图标
   *
   * 默认图标会被缓存，多次调用返回同一实例。
   *
   * **性能优化**：优先使用 C++ 层程序化生成红色圆形图标（零 I/O），
   * 如果失败则使用 ETS 层后备方案。
   *
   * **生命周期管理**：
   * - 如果缓存的图标已被释放（例如调用 markerManager.clear() 后），
   *   会自动重新创建新的默认图标
   * - 默认图标使用固定 ID: {@link DEFAULT_MARKER_ICON_ID}
   *
   * @returns Promise<Icon> 默认 Icon 封装类实例
   *
   * @example
  * ```typescript
   * const defaultIcon = await iconFactory.defaultMarker();
   * marker.setIcon(defaultIcon.getId());
   * ```
   */
  public async defaultMarker(): Promise<Icon> {

    // 检查缓存的默认图标是否有效
    if (this.defaultMarkerIcon && !this.defaultMarkerIcon.isReleased()) {
      return this.defaultMarkerIcon;
    }

    // 如果默认图标已被释放，清除缓存并重新创建
    if (this.defaultMarkerIcon?.isReleased()) {
      this.defaultMarkerIcon = null;
    }

    try {
      // 策略 1: 从 rawfile 加载 Android 风格的默认图标 (推荐，视觉效果最好)
      if (this.resourceMgr) {
        try {
          this.defaultMarkerIcon = await this.fromRawfile(
            'maplibre_marker_icon_default.png',
            IconFactory.DEFAULT_MARKER_ICON_ID
          );
          return this.defaultMarkerIcon;
        } catch (rawfileError) {
          console.error('[IconFactory] ❌ Failed to load default icon from rawfile:', rawfileError);
          console.error('[IconFactory] ❌ Error details:', JSON.stringify(rawfileError));
        }
      } else {
        console.warn('[IconFactory] ⚠️ ResourceManager is null, skipping rawfile loading');
      }

      // 策略 2: 使用 C++ 层生成程序化红色 Pin 图标
      try {
        const nativeIcon: maplibre.Icon = maplibre.IconFactory.createDefaultMarker(
          IconFactory.DEFAULT_MARKER_ICON_ID,
          48  // 48x48 像素
        );
        this.defaultMarkerIcon = Icon.fromNative(nativeIcon);
        return this.defaultMarkerIcon;
      } catch (cppError) {
        console.error('[IconFactory] ❌ C++ createDefaultMarker failed:', cppError);
      }

      // 策略 3: ETS 层程序化生成后备图标（最后手段）
      this.defaultMarkerIcon = await this.createFallbackMarkerIcon();
      return this.defaultMarkerIcon;
    } catch (error) {
      throw new Error(`[IconFactory] Failed to create default marker icon: ${error}`);
    }
  }

  /**
   * 使用指定的 Icon ID 重新创建 Icon
   *
   * 这个方法用于使用已知的 Icon ID 创建 Icon，通常用于恢复场景。
   * 不会自动生成 ID，而是使用提供的 ID。
   *
   * @param iconId Icon 标识符（必须提供）
   * @param pixelMap PixelMap 对象
   * @param reuseIdentifier 可选的复用标识符（已弃用，将被忽略）
   * @returns Icon 封装类实例
   *
   * @example
  * ```typescript
   * // 重新创建之前使用过的图标
   * const icon = iconFactory.recreate('my-saved-icon-id', pixelMap);
   * ```
   */
  public recreate(iconId: string, pixelMap: image.PixelMap, reuseIdentifier?: string): Icon {
    return Icon.createInternal(iconId, pixelMap, this.pixelRatio);
  }

  /**
   * 生成唯一的 Icon ID（带溢出检查）
   *
   * 自动递增计数器并生成格式为 "com.maplibre.icons.icon_{number}" 的唯一 ID。
   *
   * @returns 唯一的 Icon ID
   * @throws TooManyIconsException 如果 ID 计数器超过最大值
   */
  private generateUniqueIconId(): string {
    if (this.nextId >= IconFactory.MAX_ICONS) {
      throw new TooManyIconsException(
        `[IconFactory] Icon count limit reached: ${IconFactory.MAX_ICONS}. ` +
          'Consider calling reset() or creating a new IconFactory instance.'
      );
    }
    return IconFactory.ICON_ID_PREFIX + (++this.nextId);
  }

  /**
   * 创建程序生成的后备默认 Marker 图标
   *
   * 当无法从 rawfile 加载默认图标时，创建一个定位针形状的图标作为后备。
   * 这确保即使没有图片资源，应用也能正常运行。
   *
   * 图标规格：
   * - 尺寸：48x48 像素
   * - 形状：Pin 形状 (圆形头部 + 三角形尖端，类似 Google Maps)
   * - 颜色：Material Blue (#2196F3)，透明背景
   * - 格式：RGBA_8888
   * - ID：使用 {@link DEFAULT_MARKER_ICON_ID}
   *
   * @returns Promise<Icon> 程序生成的后备 Icon 封装类实例
   * @throws Error 如果创建失败
   */
  private async createFallbackMarkerIcon(): Promise<Icon> {
    try {
      // 图标规格
      const width = 48;
      const height = 48;
      const color: ColorInfo = {
        red: 255,
        green: 0,
        blue: 0,
        alpha: 255
      }; // 红色 (#FF0000 - 标准地图标记颜色)

      // 1. 创建空白 PixelMap
      const pixelMap = await image.createPixelMap(
        new ArrayBuffer(width * height * 4),
        {
          size: { width, height },
          pixelFormat: image.PixelMapFormat.RGBA_8888
        }
      );

      // 2. 生成 Pin 形状图标像素数据 (类似 Google Maps 定位针)
      // Pin 由圆形头部 + 三角形尖端组成
      const buffer = new ArrayBuffer(width * height * 4);
      const pixels = new Uint8Array(buffer);
      const centerX = width / 2;
      const headCenterY = height * 0.35; // 头部圆心位置 (上部)
      const headRadius = width * 0.25; // 头部圆形半径
      const tipY = height * 0.9; // 尖端 Y 坐标 (下部)

      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const dx = x - centerX;
          const dy = y - headCenterY;
          const distance = Math.sqrt(dx * dx + dy * dy);

          const offset = (y * width + x) * 4;
          let isInside = false;

          // 1. 圆形头部
          if (distance <= headRadius) {
            isInside = true;
          }
          // 2. 三角形尖端 (从圆心向下到尖端)
          else if (y > headCenterY) {
            // 计算三角形边界 (从圆形底部到尖端的等腰三角形)
            const triangleY = y - headCenterY;
            const maxWidth = headRadius * (1.0 - (triangleY / (tipY - headCenterY)));
            if (Math.abs(dx) <= maxWidth) {
              isInside = true;
            }
          }

          if (isInside) {
            // Pin 内部 - 红色
            pixels[offset] = color.red;
            pixels[offset + 1] = color.green;
            pixels[offset + 2] = color.blue;
            pixels[offset + 3] = color.alpha;
          } else {
            // Pin 外部 - 完全透明
            pixels[offset] = 0;
            pixels[offset + 1] = 0;
            pixels[offset + 2] = 0;
            pixels[offset + 3] = 0;
          }
        }
      }

      // 3. 写入像素数据
      await pixelMap.writeBufferToPixels(buffer);

      // 4. 创建 Icon（使用固定的默认图标 ID）
      return this.fromPixelMap(pixelMap, IconFactory.DEFAULT_MARKER_ICON_ID);
    } catch (error) {
      throw new Error(`[IconFactory] Failed to create fallback marker icon: ${error}`);
    }
  }

  /**
   * 重置工厂状态
   *
   * 清除所有缓存状态并重置 ID 计数器。
   * 主要用于测试场景或需要完全重新初始化的情况。
   *
   * **操作内容**：
   * - 释放并清除缓存的默认图标
   * - 重置 Icon ID 计数器为 0
   *
   * **注意**：
   * - 调用此方法会释放默认图标，之前创建的引用将失效
   * - 已经分发到 Marker 的 Icon 不受影响（由 IconManager 管理）
   *
   * @example
  * ```typescript
   * // 测试场景中重置状态
   * iconFactory.reset();
   * ```
   */
  public reset(): void {
    // 释放默认图标
    if (this.defaultMarkerIcon && !this.defaultMarkerIcon.isReleased()) {
      this.defaultMarkerIcon.release();
    }
    this.defaultMarkerIcon = null;

    // 重置 ID 计数器
    this.nextId = 0;

  }
}

