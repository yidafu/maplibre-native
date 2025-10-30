import image from '@ohos.multimedia.image';
import resourceManager from '@ohos.resourceManager';
import fs from '@ohos.file.fs';
import maplibre from 'libmaplibre.so';
import { TooManyIconsException } from '../exceptions/TooManyIconsException';

// Use NAPI Icon class
type Icon = maplibre.Icon;

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
 * 用于创建 Icon 实例的工厂类，支持从多种来源创建图标：
 * - PixelMap 对象
 * - 资源 ID
 * - 文件路径
 * - Rawfile 资源
 * 
 * 参考:
 * - Android: org.maplibre.android.annotations.IconFactory
 * 
 * @example
 * ```typescript
 * const factory = IconFactory.getInstance();
 * const icon1 = await factory.fromResource($r('app.media.marker'));
 * const icon2 = await factory.fromPath('/data/storage/el2/base/haps/entry/files/marker.png');
 * const icon3 = factory.fromPixelMap(pixelMap);
 * const defaultIcon = await factory.defaultMarker();
 * ```
 */
export class IconFactory {
  private static readonly ICON_ID_PREFIX = 'com.maplibre.icons.icon_';
  private static readonly MAX_ICONS = 1000000; // 防止 ID 溢出
  
  // 默认图标名称 - 用于SymbolLayer引用
  public static readonly DEFAULT_MARKER_ICON_ID = 'com.maplibre.marker.default';
  
  private static instance: IconFactory | null = null;
  
  private nextId: number = 0;
  private defaultMarkerIcon: Icon | null = null;
  private resourceMgr: resourceManager.ResourceManager | null = null;
  private pixelRatio: number = 1.0;

  /**
   * 私有构造函数（单例模式）
   */
  private constructor(resourceMgr?: resourceManager.ResourceManager) {
    this.resourceMgr = resourceMgr || null;
    
    // 获取屏幕像素密度
    try {
      // 注意：这里需要在实际使用时通过 context 获取正确的 display 信息
      this.pixelRatio = 1.0; // 默认值，实际应该从 display.getDefaultDisplaySync() 获取
    } catch (error) {
      console.warn('[IconFactory] Failed to get pixel ratio, using default 1.0');
      this.pixelRatio = 1.0;
    }
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
   * 从 PixelMap 创建图标
   * 
   * @param pixelMap PixelMap 对象
   * @param iconId 可选的图标ID，如果不提供则自动生成
   * @returns Icon 实例（NAPI 对象）
   * @throws Error 如果创建失败或 ID 溢出
   */
  public fromPixelMap(pixelMap: image.PixelMap, iconId?: string): Icon {
    let id: string;
    if (iconId) {
      id = iconId;
    } else {
      this.checkIdOverflow();
      id = this.generateIconId();
    }
    // Use NAPI Icon constructor - PixelMap is converted to C++ image data during construction
    return new maplibre.Icon(id, pixelMap, this.pixelRatio);
  }

  /**
   * 从 PixelMap 创建图标（带复用标识符）
   * 
   * 注意：NAPI Icon 不支持 reuseIdentifier 参数，此参数将被忽略
   * 
   * @param pixelMap PixelMap 对象
   * @param reuseIdentifier 复用标识符（忽略，为向后兼容保留）
   * @returns Icon 实例（NAPI 对象）
   * @throws Error 如果创建失败或 ID 溢出
   */
  public fromPixelMapWithIdentifier(pixelMap: image.PixelMap, reuseIdentifier: string): Icon {
    this.checkIdOverflow();
    const id = this.generateIconId();
    // NAPI Icon doesn't support reuseIdentifier, use ID as identifier
    return new maplibre.Icon(id, pixelMap, this.pixelRatio);
  }

  /**
   * 从资源 ID 创建图标
   * 
   * @param resource 资源对象 (例如 $r('app.media.marker'))
   * @param reuseIdentifier 可选的复用标识符
   * @returns Promise<Icon> Icon 实例
   * @throws Error 如果资源不存在或加载失败
   */
  public async fromResource(resource: Resource, reuseIdentifier?: string): Promise<Icon> {
    if (!this.resourceMgr) {
      throw new Error('ResourceManager not set. Call setResourceManager() first or pass it to getInstance()');
    }

    try {
      // 获取资源的 ArrayBuffer
      const buffer = await this.resourceMgr.getMediaContent(resource.id);
      
      // 创建 ImageSource
      const imageSource = image.createImageSource(buffer);
      
      // 解码为 PixelMap
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      
      // 释放 ImageSource
      imageSource.release();
      
      if (reuseIdentifier) {
        return this.fromPixelMapWithIdentifier(pixelMap, reuseIdentifier);
      }
      return this.fromPixelMap(pixelMap);
    } catch (error) {
      throw new Error(`Failed to load icon from resource: ${error}`);
    }
  }

  /**
   * 从文件路径创建图标
   * 
   * @param absolutePath 文件的绝对路径
   * @param reuseIdentifier 可选的复用标识符
   * @returns Promise<Icon> Icon 实例
   * @throws Error 如果文件不存在或加载失败
   */
  public async fromPath(absolutePath: string, reuseIdentifier?: string): Promise<Icon> {
    try {
      // 检查文件是否存在
      const stat = fs.statSync(absolutePath);
      if (!stat.isFile()) {
        throw new Error(`Path is not a file: ${absolutePath}`);
      }

      // 打开文件
      const file = fs.openSync(absolutePath, fs.OpenMode.READ_ONLY);
      
      // 读取文件内容
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      // 创建 ImageSource
      const imageSource = image.createImageSource(buffer);
      
      // 解码为 PixelMap
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      
      // 释放 ImageSource
      imageSource.release();
      
      if (reuseIdentifier) {
        return this.fromPixelMapWithIdentifier(pixelMap, reuseIdentifier);
      }
      return this.fromPixelMap(pixelMap);
    } catch (error) {
      throw new Error(`Failed to load icon from path ${absolutePath}: ${error}`);
    }
  }

  /**
   * 从 rawfile 创建图标
   * 
   * @param fileName rawfile 文件名 (例如 'marker.png')
   * @param iconId 可选的图标ID，如果不提供则自动生成
   * @returns Promise<Icon> Icon 实例
   * @throws Error 如果资源不存在或加载失败
   */
  public async fromRawfile(fileName: string, iconId?: string): Promise<Icon> {
    if (!this.resourceMgr) {
      throw new Error('ResourceManager not set. Call setResourceManager() first or pass it to getInstance()');
    }

    try {
      // 从 rawfile 获取内容
      const buffer = await this.resourceMgr.getRawFileContent(fileName);
      
      // 创建 ImageSource
      const imageSource = image.createImageSource(buffer.buffer);
      
      // 解码为 PixelMap
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      
      // 释放 ImageSource
      imageSource.release();
      
      return this.fromPixelMap(pixelMap, iconId);
    } catch (error) {
      throw new Error(`Failed to load icon from rawfile ${fileName}: ${error}`);
    }
  }

  /**
   * 获取默认的 marker 图标
   * 
   * 默认图标会被缓存，多次调用返回同一实例。
   * 如果缓存的图标已被释放（例如调用 markerManager.clear() 后），
   * 会自动重新创建新的默认图标。
   * 
   * @returns Promise<Icon> 默认 Icon 实例
   * @throws Error 如果加载默认图标失败
   */
  public async defaultMarker(): Promise<Icon> {
    // 检查缓存的默认图标是否存在且未被释放
    if (this.defaultMarkerIcon && !this.defaultMarkerIcon.isReleased()) {
      return this.defaultMarkerIcon;
    }
    
    // 如果默认图标已被释放，清除缓存并重新创建
    if (this.defaultMarkerIcon && this.defaultMarkerIcon.isReleased()) {
      console.info('[IconFactory] Cached default marker icon was released, creating new one');
      this.defaultMarkerIcon = null;
    }

    try {
      // 尝试加载默认图标资源
      // 注意：需要确保 resources/base/media/ 目录下有 maplibre_marker_icon_default.png
      if (this.resourceMgr) {
        try {
          // 使用固定的默认图标ID
          this.defaultMarkerIcon = await this.fromRawfile('maplibre_marker_icon_default.png', IconFactory.DEFAULT_MARKER_ICON_ID);
          console.info('[IconFactory] Default marker icon loaded from rawfile');
          return this.defaultMarkerIcon;
        } catch (rawfileError) {
          console.warn('[IconFactory] Failed to load default icon from rawfile, trying resource');
        }
      }

      // 如果 rawfile 加载失败，尝试从资源加载
      // 这里需要一个后备方案：创建一个简单的彩色矩形作为默认图标
      console.warn('[IconFactory] Creating fallback default marker icon');
      this.defaultMarkerIcon = await this.createFallbackMarkerIcon();
      return this.defaultMarkerIcon;
    } catch (error) {
      throw new Error(`Failed to load default marker icon: ${error}`);
    }
  }

  /**
   * 使用指定的 Icon ID 重新创建 Icon
   * 
   * 用于恢复之前创建的 Icon
   * 
   * @param iconId Icon 标识符
   * @param pixelMap PixelMap 对象
   * @param reuseIdentifier 可选的复用标识符（忽略，为向后兼容保留）
   * @returns Icon 实例（NAPI 对象）
   */
  public recreate(iconId: string, pixelMap: image.PixelMap, reuseIdentifier?: string): Icon {
    return new maplibre.Icon(iconId, pixelMap, this.pixelRatio);
  }

  /**
   * 生成唯一的 Icon ID
   * 
   * @returns Icon ID
   */
  private generateIconId(): string {
    return IconFactory.ICON_ID_PREFIX + (++this.nextId);
  }

  /**
   * 检查 ID 是否溢出
   * 
   * @throws TooManyIconsException 如果 ID 超过最大值
   */
  private checkIdOverflow(): void {
    if (this.nextId >= IconFactory.MAX_ICONS) {
      throw new TooManyIconsException(`Icon count limit reached: ${IconFactory.MAX_ICONS}`);
    }
  }

  /**
   * 创建后备的默认 marker 图标
   * 
   * 当无法加载默认图标资源时，创建一个简单的彩色矩形
   * 
   * @returns Promise<Icon> Icon 实例
   */
  private async createFallbackMarkerIcon(): Promise<Icon> {
    try {
      // 创建一个简单的红色圆形作为默认 marker
      const width = 48;
      const height = 48;
      const color: ColorInfo = { red: 255, green: 0, blue: 0, alpha: 255 }; // 红色
      
      // 创建 PixelMap
      const pixelMap = await image.createPixelMap(
        new ArrayBuffer(width * height * 4),
        {
          size: { width: width, height: height },
          pixelFormat: image.PixelMapFormat.RGBA_8888
        }
      );

      // 填充颜色（创建一个简单的圆形）
      const buffer = new ArrayBuffer(width * height * 4);
      const view = new Uint8Array(buffer);
      const centerX = width / 2;
      const centerY = height / 2;
      const radius = Math.min(width, height) / 3;

      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const dx = x - centerX;
          const dy = y - centerY;
          const distance = Math.sqrt(dx * dx + dy * dy);
          
          const index = (y * width + x) * 4;
          if (distance <= radius) {
            // 圆形内部 - 红色
            view[index] = color.red;
            view[index + 1] = color.green;
            view[index + 2] = color.blue;
            view[index + 3] = color.alpha;
          } else {
            // 圆形外部 - 透明
            view[index] = 0;
            view[index + 1] = 0;
            view[index + 2] = 0;
            view[index + 3] = 0;
          }
        }
      }

      await pixelMap.writeBufferToPixels(buffer);
      
      // 使用固定的默认图标ID
      return this.fromPixelMap(pixelMap, IconFactory.DEFAULT_MARKER_ICON_ID);
    } catch (error) {
      throw new Error(`Failed to create fallback marker icon: ${error}`);
    }
  }

  /**
   * 重置工厂状态（测试用）
   * 
   * 清除缓存的默认图标和重置 ID 计数器
   */
  public reset(): void {
    if (this.defaultMarkerIcon) {
      this.defaultMarkerIcon.release();
      this.defaultMarkerIcon = null;
    }
    this.nextId = 0;
  }
}

