import { Icon } from './Icon';
import { IconFactory } from './IconFactory';
import maplibre from 'libmaplibre.so';

// 使用 NAPI Marker 和 NativeMapView 类型
type Marker = maplibre.Marker;
type NativeMapView = maplibre.NativeMapView;

/**
 * 图标引用数据
 */
interface IconRefData {
  icon: Icon;
  refCount: number;
}

/**
 * IconManager - 图标管理器
 * 
 * 负责管理地图上的图标，包括：
 * - 图标的引用计数缓存（使用图标ID字符串作为key）
 * - 图标的加载和卸载
 * - 与 Native 层的图标同步
 * - 跟踪图标尺寸（用于手势检测）
 * - 图标复用队列管理
 * 
 * 注意：HarmonyOS 版本使用字符串ID作为key，因为 NAPI Marker.getIcon() 返回 string | null
 * 
 * @example
 * ```typescript
 * const iconManager = new IconManager(nativeMapView);
 * const icon = await iconManager.loadIconForMarker(marker);
 * // ... 使用 marker
 * iconManager.iconCleanup(icon); // 引用计数减1，为0时自动清理
 * ```
 */
export class IconManager {
  // 使用字符串ID作为key，存储Icon对象和引用计数
  private iconMap: Map<string, IconRefData> = new Map();
  // 使用 reuseIdentifier 作为 key，存储可复用的图标
  private reuseIdentifierMap: Map<string, Icon> = new Map();
  private nativeMapView: NativeMapView | null = null;
  private highestIconWidth: number = 0;
  private highestIconHeight: number = 0;
  public iconFactory: IconFactory | null = null;

  /**
   * 构造函数
   * 
   * @param nativeMapView Native 地图视图实例
   * @param iconFactory 可选的 IconFactory 实例
   */
  constructor(nativeMapView: NativeMapView, iconFactory?: IconFactory) {
    this.nativeMapView = nativeMapView;
    this.iconFactory = iconFactory || IconFactory.getInstance();
  }

  /**
   * 为 Marker 加载图标
   * 
   * 如果 Marker 没有设置图标，则使用默认图标
   * 自动增加引用计数并加载到 Native 层
   * 
   * @param marker Marker 实例
   * @returns Promise<Icon> 加载的 Icon 实例
   */
  public async loadIconForMarker(marker: Marker): Promise<Icon> {
    try {
      // 尝试获取 Marker 的图标ID
      let iconId: string | null = marker.getIcon();
      let icon: Icon;
      
      if (!iconId) {
        // 如果没有图标，使用默认图标
        console.info('[IconManager] Marker has no icon, loading default marker icon');
        icon = await this.loadDefaultIconForMarker(marker);
        iconId = icon.getId();
      } else {
        // 从缓存获取或创建新的Icon对象
        const cached = this.iconMap.get(iconId);
        if (cached) {
          icon = cached.icon;
        } else {
          // 这种情况不应该发生，因为图标应该先通过addIcon添加
          throw new Error(`Icon ${iconId} not found in cache`);
        }
        // 更新最大图标尺寸
        this.updateHighestIconSize(icon);
      }
      
      // 添加图标（增加引用计数）
      await this.addIcon(icon);
      
      return icon;
    } catch (error) {
      console.error('[IconManager] Failed to load icon for marker:', error);
      throw new Error('Failed to load icon for marker: ' + error);
    }
  }

  /**
   * 加载默认图标
   * 
   * @param marker Marker 实例
   * @returns Promise<Icon> 默认 Icon 实例
   */
  private async loadDefaultIconForMarker(marker: Marker): Promise<Icon> {
    if (!this.iconFactory) {
      throw new Error('[IconManager] IconFactory is not initialized');
    }
    const icon = await this.iconFactory.defaultMarker();
    
    // 更新最大图标尺寸
    const width = icon.getWidth();
    const height = icon.getHeight() / 2; // Android 的默认图标高度除以2
    this.updateHighestIconSize(width, height);
    
    // 将默认图标ID设置到 Marker
    marker.setIcon(icon.getId());
    
    return icon;
  }

  /**
   * 添加图标到缓存
   * 
   * 增加引用计数，如果是首次添加则加载到 Native 层
   * 
   * @param icon Icon 实例
   * @param addIconToMap 是否添加到 Native 层（默认 true）
   */
  private async addIcon(icon: Icon, addIconToMap: boolean = true): Promise<void> {
    const iconId = icon.getId();
    const cached = this.iconMap.get(iconId);
    
    if (!cached) {
      // 首次添加图标
      const refData: IconRefData = { icon: icon, refCount: 1 };
      this.iconMap.set(iconId, refData);
      if (addIconToMap) {
        await this.loadIconToNative(icon);
      }
      console.debug(`[IconManager] Icon ${iconId} added with refCount=1`);
    } else {
      // 图标已存在，增加引用计数
      cached.refCount++;
      console.debug(`[IconManager] Icon ${iconId} refCount increased to ${cached.refCount}`);
    }
  }

  /**
   * 添加已有的Icon到管理器
   * 
   * 用于Marker已经设置了iconId，需要将Icon对象加入管理
   * 
   * @param icon Icon 实例
   * @throws Error 如果 Icon 已被释放
   */
  public async addIconToManager(icon: Icon): Promise<void> {
    // 检查Icon是否已释放
    if (icon.isReleased()) {
      throw new Error(
        `Cannot add released Icon '${icon.getId()}'. ` +
        'After calling markerManager.clear() or marker.remove(), ' +
        'you must create a new Icon instead of reusing the old one.'
      );
    }
    
    await this.addIcon(icon, true);
    // 同时添加到复用标识符映射
    const reuseId = icon.getReuseIdentifier();
    if (reuseId && !this.reuseIdentifierMap.has(reuseId)) {
      this.reuseIdentifierMap.set(reuseId, icon);
    }
  }

  /**
   * 通过复用标识符获取已缓存的图标
   * 
   * 类似 iOS 的 dequeueReusableAnnotationImageWithIdentifier
   * 
   * @param reuseIdentifier 复用标识符
   * @returns Icon 实例，如果不存在或已释放则返回 null
   */
  public dequeueReusableIcon(reuseIdentifier: string): Icon | null {
    const icon = this.reuseIdentifierMap.get(reuseIdentifier);
    
    // 检查图标是否存在且未被释放
    if (icon && icon.isReleased()) {
      // 如果图标已释放，从复用映射中移除并返回 null
      console.warn(`[IconManager] Reusable icon '${reuseIdentifier}' was released, removing from reuse map`);
      this.reuseIdentifierMap.delete(reuseIdentifier);
      return null;
    }
    
    return icon || null;
  }

  /**
   * 获取或加载 Marker 的图标
   * 
   * 自动处理图标复用和默认图标加载
   * 
   * @param marker Marker 实例
   * @param defaultIconProvider 可选的默认图标提供函数
   * @returns Promise<Icon> Icon 实例
   */
  public async getOrLoadIcon(marker: Marker, defaultIconProvider?: () => Promise<Icon>): Promise<Icon> {
    try {
      let iconId: string | null = marker.getIcon();
      let icon: Icon;
      
      if (!iconId) {
        // 如果没有图标，使用默认图标或提供的图标
        if (defaultIconProvider) {
          icon = await defaultIconProvider();
        } else {
          if (!this.iconFactory) {
            throw new Error('[IconManager] IconFactory is not initialized');
          }
          icon = await this.iconFactory.defaultMarker();
        }
        marker.setIcon(icon.getId());
        iconId = icon.getId();
      } else {
        // 检查缓存中是否已存在
        const cached = this.iconMap.get(iconId);
        if (cached) {
          icon = cached.icon;
        } else {
          throw new Error(`Icon ${iconId} not found in cache`);
        }
      }
      
      // 更新最大图标尺寸
      this.updateHighestIconSize(icon);
      
      return icon;
    } catch (error) {
      console.error('[IconManager] Failed to get or load icon:', error);
      throw new Error('Failed to get or load icon: ' + error);
    }
  }

  /**
   * 更新 Marker 的图标
   * 
   * 自动处理旧图标的引用计数减少和新图标的引用计数增加
   * 
   * @param marker Marker 实例
   * @param oldIcon 旧的 Icon 实例（可为 null）
   * @param newIcon 新的 Icon 实例
   */
  public async updateMarkerIcon(marker: Marker, oldIcon: Icon | null, newIcon: Icon): Promise<void> {
    try {
      // 减少旧图标的引用计数
      if (oldIcon) {
        this.iconCleanup(oldIcon);
      }
      
      // 更新 Marker 的图标 ID
      marker.setIcon(newIcon.getId());
      
      // 添加新图标（增加引用计数）
      await this.addIconToManager(newIcon);
      
      // 更新最大图标尺寸
      this.updateHighestIconSize(newIcon);
      
      console.info(`[IconManager] Updated marker icon from ${oldIcon?.getId() || 'null'} to ${newIcon.getId()}`);
    } catch (error) {
      console.error('[IconManager] Failed to update marker icon:', error);
      throw new Error('Failed to update marker icon: ' + error);
    }
  }

  /**
   * 加载图标到 Native 层
   * 
   * @param icon Icon 实例
   * @throws Error 如果 Icon 已被释放或加载失败
   */
  private async loadIconToNative(icon: Icon): Promise<void> {
    try {
      // 检查Icon是否已释放
      if (icon.isReleased()) {
        throw new Error(
          `Cannot load released Icon '${icon.getId()}' to native. ` +
          'Icon has been released and cannot be reused.'
        );
      }
      
      const iconId = icon.getId();
      const width = icon.getWidth();
      const height = icon.getHeight();
      const scale = icon.getScale();
      const bytes = await icon.toBytes();
      
      console.info(`[IconManager] Loading icon to native: id=${iconId}, size=${width}x${height}, scale=${scale}`);
      
      // 调用 Native 方法添加图标
      if (!this.nativeMapView) {
        throw new Error('[IconManager] NativeMapView is not initialized');
      }
      this.nativeMapView.addAnnotationIcon(iconId, width, height, scale, bytes);
      
      console.debug(`[IconManager] Icon ${iconId} loaded to native successfully`);
    } catch (error) {
      console.error(`[IconManager] Failed to load icon ${icon.getId()} to native:`, error);
      throw new Error(`Failed to load icon ${icon.getId()} to native: ` + error);
    }
  }

  /**
   * 清理图标
   * 
   * 减少引用计数，如果引用计数为 0 则从缓存和 Native 层删除。
   * 
   * **重要**：当引用计数降为 0 时，Icon 会被释放（调用 release()），
   * PixelMap 资源会被回收。已释放的 Icon 不能再使用，必须创建新的 Icon 实例。
   * 
   * @param iconOrId Icon 实例或图标ID字符串
   */
  public iconCleanup(iconOrId: Icon | string): void {
    const iconId = typeof iconOrId === 'string' ? iconOrId : iconOrId.getId();
    const cached = this.iconMap.get(iconId);
    
    if (!cached) {
      console.warn(`[IconManager] Icon ${iconId} not found in cache, cannot cleanup`);
      return;
    }
    
    if (cached.refCount === 1) {
      // 引用计数为1，清理后变为0，直接删除
      this.remove(cached.icon);
    } else {
      // 引用计数大于1，递减
      cached.refCount--;
      console.debug(`[IconManager] Icon ${iconId} refCount decreased to ${cached.refCount}`);
    }
  }

  /**
   * 从缓存和 Native 层删除图标
   * 
   * @param icon Icon 实例
   */
  private remove(icon: Icon): void {
    const iconId = icon.getId();
    const reuseId = icon.getReuseIdentifier();
    
    try {
      // 从 Native 层删除
      if (!this.nativeMapView) {
        throw new Error('[IconManager] NativeMapView is not initialized');
      }
      this.nativeMapView.removeAnnotationIcon(iconId);
      console.debug(`[IconManager] Icon ${iconId} removed from native`);
      
      // 从缓存中删除
      this.iconMap.delete(iconId);
      console.debug(`[IconManager] Icon ${iconId} removed from cache`);
      
      // 从复用标识符映射中删除
      if (reuseId && this.reuseIdentifierMap.get(reuseId) === icon) {
        this.reuseIdentifierMap.delete(reuseId);
        console.debug(`[IconManager] Icon ${iconId} removed from reuse map (${reuseId})`);
      }
      
      // 释放 Icon 资源
      icon.release();
    } catch (error) {
      console.error(`[IconManager] Failed to remove icon ${iconId}:`, error);
    }
  }

  /**
   * 重新加载所有图标
   * 
   * 用于地图恢复或重新初始化
   */
  public async reloadIcons(): Promise<void> {
    console.info('[IconManager] Reloading all icons...');
    
    let successCount = 0;
    let failCount = 0;
    
    for (const cached of this.iconMap.values()) {
      try {
        await this.loadIconToNative(cached.icon);
        successCount++;
      } catch (error) {
        console.error(`[IconManager] Failed to reload icon ${cached.icon.getId()}:`, error);
        failCount++;
      }
    }
    
    console.info(`[IconManager] Icons reloaded: ${successCount} success, ${failCount} failed`);
  }

  /**
   * 确保 Marker 的图标已加载
   * 
   * 用于 Marker 更新时确保图标存在
   * 
   * @param marker Marker 实例
   */
  public async ensureIconLoaded(marker: Marker): Promise<void> {
    const iconId = marker.getIcon();
    if (!iconId) {
      const icon = await this.loadDefaultIconForMarker(marker);
      marker.setIcon(icon.getId());
      await this.addIcon(icon);
    } else {
      // 图标ID存在，检查是否已加载
      const cached = this.iconMap.get(iconId);
      if (cached) {
        await this.addIcon(cached.icon);
      }
    }
  }

  /**
   * 获取图标的 Top Offset（用于锚点计算）
   * 
   * @param icon Icon 实例
   * @returns Top offset 像素值
   */
  public getTopOffsetPixelsForIcon(icon: Icon): number {
    try {
      if (!this.nativeMapView) {
        throw new Error('[IconManager] NativeMapView is not initialized');
      }
      // TODO: NativeMapView 没有 getPixelRatio() 方法，使用默认值
      const pixelRatio: number = 1.0;
      const topOffset: number = this.nativeMapView.getTopOffsetPixelsForAnnotationSymbol(icon.getId());
      return topOffset * pixelRatio;
    } catch (error) {
      console.warn(`[IconManager] Failed to get top offset for icon ${icon.getId()}:`, error);
      return 0;
    }
  }

  /**
   * 获取最大图标宽度
   * 
   * @returns 最大宽度（像素）
   */
  public getHighestIconWidth(): number {
    return this.highestIconWidth;
  }

  /**
   * 获取最大图标高度
   * 
   * @returns 最大高度（像素）
   */
  public getHighestIconHeight(): number {
    return this.highestIconHeight;
  }

  /**
   * 更新最大图标尺寸（Icon 版本）
   * 
   * @param iconOrWidth Icon 实例或宽度
   * @param height 高度（可选）
   */
  private updateHighestIconSize(iconOrWidth: Icon | number, height?: number): void {
    let width: number;
    let h: number;
    
    if (typeof iconOrWidth === 'number') {
      // 直接传入 width 和 height
      width = iconOrWidth;
      h = height!;
    } else {
      // 传入 Icon 对象
      width = iconOrWidth.getWidth();
      h = iconOrWidth.getHeight();
    }
    
    if (width > this.highestIconWidth) {
      this.highestIconWidth = width;
    }
    if (h > this.highestIconHeight) {
      this.highestIconHeight = h;
    }
  }


  /**
   * 清理所有图标
   * 
   * 释放所有缓存的图标和资源
   */
  public cleanup(): void {
    console.info('[IconManager] Cleaning up all icons...');
    
    // 遍历所有图标进行清理
    this.iconMap.forEach((cached: IconRefData, iconId: string) => {
      try {
        if (this.nativeMapView) {
          this.nativeMapView.removeAnnotationIcon(iconId);
        }
        cached.icon.release();
      } catch (error) {
        console.error(`[IconManager] Failed to cleanup icon ${iconId}:`, error);
      }
    });
    
    this.iconMap.clear();
    this.reuseIdentifierMap.clear();
    this.highestIconWidth = 0;
    this.highestIconHeight = 0;
    
    console.info('[IconManager] All icons cleaned up');
  }

  /**
   * 获取当前缓存的图标数量
   * 
   * @returns 图标数量
   */
  public getIconCount(): number {
    return this.iconMap.size;
  }

  /**
   * 获取指定图标的引用计数
   * 
   * @param icon Icon 对象
   * @returns 引用计数，如果图标不存在返回 0
   */
  public getRefCount(icon: Icon): number {
    const cached = this.iconMap.get(icon.getId());
    return cached ? cached.refCount : 0;
  }
}

