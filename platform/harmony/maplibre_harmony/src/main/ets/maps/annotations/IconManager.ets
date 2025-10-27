import { Icon } from './Icon';
import { IconFactory } from './IconFactory';
import maplibre from 'libmaplibre_native.so';

// 使用 NAPI Marker 和 NativeMapView 类型
type Marker = maplibre.Marker;
type NativeMapView = maplibre.NativeMapView;

/**
 * Icon 引用数据
 */
interface IconRefData {
  icon: Icon;
  refCount: number;
}

/**
 * IconManager - 图标管理器
 * 
 * 负责管理地图上的图标，包括：
 * - 图标的引用计数缓存
 * - 图标的加载和卸载
 * - 与 Native 层的图标同步
 * - 跟踪图标尺寸（用于手势检测）
 * 
 * 参考:
 * - Android: org.maplibre.android.maps.IconManager
 * 
 * @example
 * ```typescript
 * const iconManager = new IconManager(nativeMapView);
 * const icon = iconManager.loadIconForMarker(marker);
 * // ... 使用 marker
 * iconManager.iconCleanup(icon); // 引用计数减1，为0时自动清理
 * ```
 */
export class IconManager {
  private iconMap: Map<string, IconRefData> = new Map();
  private nativeMapView!: NativeMapView;
  private highestIconWidth: number = 0;
  private highestIconHeight: number = 0;
  private iconFactory!: IconFactory;

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
      // 尝试获取 Marker 的图标
      let icon: Icon | null = this.getMarkerIcon(marker);
      
      if (!icon) {
        // 如果没有图标，使用默认图标
        console.info('[IconManager] Marker has no icon, loading default marker icon');
        icon = await this.loadDefaultIconForMarker(marker);
      } else {
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
    const icon = await this.iconFactory.defaultMarker();
    
    // 更新最大图标尺寸
    const width = icon.getWidth();
    const height = icon.getHeight() / 2; // Android 的默认图标高度除以2
    this.updateHighestIconSize(width, height);
    
    // 将默认图标设置到 Marker（如果可能）
    // 注意：这里需要 Marker 提供 setIcon 方法
    // this.setMarkerIcon(marker, icon);
    
    return icon;
  }

  /**
   * 添加图标到缓存
   * 
   * 增加引用计数，如果是首次添加则加载到 Native 层
   * 
   * @param icon Icon 实例
   * @param addToNative 是否添加到 Native 层（默认 true）
   */
  private async addIcon(icon: Icon, addToNative: boolean = true): Promise<void> {
    const iconId = icon.getId();
    const existing = this.iconMap.get(iconId);
    
    if (existing) {
      // 图标已存在，增加引用计数
      existing.refCount++;
      console.debug(`[IconManager] Icon ${iconId} refCount increased to ${existing.refCount}`);
    } else {
      // 首次添加图标
      this.iconMap.set(iconId, {
        icon: icon,
        refCount: 1
      });
      
      if (addToNative) {
        await this.loadIconToNative(icon);
      }
      
      console.debug(`[IconManager] Icon ${iconId} added with refCount=1`);
    }
  }

  /**
   * 加载图标到 Native 层
   * 
   * @param icon Icon 实例
   */
  private async loadIconToNative(icon: Icon): Promise<void> {
    try {
      const iconId = icon.getId();
      const width = icon.getWidth();
      const height = icon.getHeight();
      const scale = icon.getScale();
      const bytes = await icon.toBytes();
      
      console.info(`[IconManager] Loading icon to native: id=${iconId}, size=${width}x${height}, scale=${scale}`);
      
      // 调用 Native 方法添加图标
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
   * 减少引用计数，如果引用计数为 0 则从缓存和 Native 层删除
   * 
   * @param icon Icon 实例
   */
  public iconCleanup(icon: Icon): void {
    const iconId = icon.getId();
    const refData = this.iconMap.get(iconId);
    
    if (!refData) {
      console.warn(`[IconManager] Icon ${iconId} not found in cache, cannot cleanup`);
      return;
    }
    
    refData.refCount--;
    console.debug(`[IconManager] Icon ${iconId} refCount decreased to ${refData.refCount}`);
    
    if (refData.refCount <= 0) {
      // 引用计数为 0，删除图标
      this.removeIcon(icon);
    }
  }

  /**
   * 从缓存和 Native 层删除图标
   * 
   * @param icon Icon 实例
   */
  private removeIcon(icon: Icon): void {
    const iconId = icon.getId();
    
    try {
      // 从 Native 层删除
      this.nativeMapView.removeAnnotationIcon(iconId);
      console.debug(`[IconManager] Icon ${iconId} removed from native`);
      
      // 从缓存中删除
      this.iconMap.delete(iconId);
      console.debug(`[IconManager] Icon ${iconId} removed from cache`);
      
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
    
    const icons = Array.from(this.iconMap.values());
    let successCount = 0;
    let failCount = 0;
    
    for (const refData of icons) {
      try {
        await this.loadIconToNative(refData.icon);
        successCount++;
      } catch (error) {
        console.error(`[IconManager] Failed to reload icon ${refData.icon.getId()}:`, error);
        failCount++;
      }
    }
    
    console.info(`[IconManager] Icons reloaded: ${successCount} success, ${failCount} failed`);
  }

  /**
   * 公开方法：添加图标
   * 
   * @param icon Icon 实例
   */
  public async addIconIfNeeded(icon: Icon): Promise<void> {
    const iconId = icon.getId();
    if (!this.iconMap.has(iconId)) {
      await this.addIcon(icon);
    }
  }

  /**
   * 确保 Marker 的图标已加载
   * 
   * 用于 Marker 更新时确保图标存在
   * 
   * @param marker Marker 实例
   */
  public async ensureIconLoaded(marker: Marker): Promise<void> {
    const icon = this.getMarkerIcon(marker);
    if (icon) {
      await this.addIconIfNeeded(icon);
    } else {
      // Marker 没有图标，加载默认图标
      await this.loadIconForMarker(marker);
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
   * 获取 Marker 的 Icon
   * 
   * @param marker Marker 实例
   * @returns Icon 实例或 null
   */
  private getMarkerIcon(marker: Marker): Icon | null {
    try {
      // 注意：这里需要 Marker 提供 getIcon() 方法
      // 由于 NAPI Marker 可能没有这个方法，我们返回 null
      // 在实际使用时需要根据 Marker 的实现来调整
      return null;
    } catch (error) {
      return null;
    }
  }

  /**
   * 清理所有图标
   * 
   * 释放所有缓存的图标和资源
   */
  public cleanup(): void {
    console.info('[IconManager] Cleaning up all icons...');
    
    this.iconMap.forEach((refData: IconRefData, iconId: string) => {
      try {
        this.nativeMapView.removeAnnotationIcon(iconId);
        refData.icon.release();
      } catch (error) {
        console.error(`[IconManager] Failed to cleanup icon ${iconId}:`, error);
      }
    });
    
    this.iconMap.clear();
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
   * @param iconId Icon ID
   * @returns 引用计数，如果图标不存在返回 0
   */
  public getRefCount(iconId: string): number {
    const refData = this.iconMap.get(iconId);
    return refData ? refData.refCount : 0;
  }
}

