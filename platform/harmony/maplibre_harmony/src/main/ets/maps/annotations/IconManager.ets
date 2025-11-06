import { IconFactory } from './IconFactory';
import { Icon } from './Icon';
import maplibre, { NativeMapView } from 'libmaplibre.so';

/**
 * 图标引用计数数据
 *
 * 存储 Icon 对象及其被 Marker 引用的次数
 */
interface IconRefData {
  icon: Icon;
  refCount: number;
}

/**
 * IconManager - 图标生命周期管理器
 *
 * 基于 NAPI Icon 类实现的图标管理器，负责图标的完整生命周期管理。
 *
 * **核心职责**：
 * 1. **引用计数管理**：跟踪每个图标被多少个 Marker 使用
 * 2. **Native 层同步**：自动加载/卸载图标到 Native 地图
 * 3. **资源自动释放**：引用计数为 0 时自动释放 Icon（调用 release()）
 * 4. **图标复用**：支持通过 ID 复用已加载的图标
 * 5. **尺寸跟踪**：记录最大图标尺寸（用于手势检测范围）
 *
 * **架构设计**：
 * ```
 * IconFactory (创建) → Icon → IconManager (管理) → NativeMapView (渲染)
 *                         ↓
 *                    引用计数跟踪
 *                         ↓
 *                   自动 release()
 * ```
 *
 * **生命周期管理**：
 * - `addIconToManager()`: 添加图标，引用计数 +1，首次添加时加载到 Native
 * - `iconCleanup()`: 减少引用计数 -1，降为 0 时自动释放
 * - `cleanup()`: 清理所有图标，释放所有资源
 *
 * **重要提示**：
 * - 使用 Icon ID（字符串）作为唯一标识符
 * - Icon 一旦释放（isReleased() == true）不能再使用
 * - 需要重新使用相同图标时，必须通过 IconFactory 创建新实例
 *
 * 参考:
 * - Android: org.maplibre.android.annotations.AnnotationManager
 * - iOS: MLNAnnotationController
 *
 * @example
* ```typescript
 * // 基本使用
 * const iconManager = new IconManager(nativeMapView);
 *
 * // 创建并添加图标
 * const icon = await iconFactory.fromResource($r('app.media.marker'));
 * await iconManager.addIconToManager(icon);  // 引用计数 = 1
 * marker.setIcon(icon.getId());
 *
 * // 图标被多个 Marker 使用
 * marker2.setIcon(icon.getId());  // 引用计数 = 2
 *
 * // 清理图标
 * iconManager.iconCleanup(icon);  // 引用计数 = 1
 * iconManager.iconCleanup(icon);  // 引用计数 = 0，自动 release()
 * ```
 */
export class IconManager {
  // Icon ID → 引用计数数据映射
  private iconMap: Map<string, IconRefData> = new Map();
  // 复用标识符 → Icon 映射（用于图标复用）
  private reuseIdentifierMap: Map<string, Icon> = new Map();
  // Native 地图视图引用
  private nativeMapView: NativeMapView | null = null;
  // 最大图标尺寸（用于手势检测）
  private highestIconWidth: number = 0;
  private highestIconHeight: number = 0;
  // Icon 工厂引用
  public iconFactory: IconFactory | null = null;

  /**
   * 构造函数
   *
   * @param nativeMapView Native 地图视图实例（用于与 C++ 层交互）
   * @param iconFactory 可选的 IconFactory 实例（如果不提供，使用全局单例）
   */
  constructor(nativeMapView: NativeMapView, iconFactory?: IconFactory) {
    this.nativeMapView = nativeMapView;
    this.iconFactory = iconFactory || IconFactory.getInstance();
  }

  /**
   * 为 Marker 加载图标
   *
   * 自动处理图标加载流程：
   * 1. 如果 Marker 已有图标 ID，从缓存获取
   * 2. 如果 Marker 没有图标，加载默认图标
   * 3. 增加图标的引用计数
   * 4. 首次使用时自动加载到 Native 层
   *
   * @param marker Marker 实例
   * @returns Promise<Icon> 加载的 Icon 封装类实例
   * @throws Error 如果图标不在缓存中或加载失败
   */
  public async loadIconForMarker(marker: maplibre.Marker): Promise<Icon> {
    try {
      // 获取 Marker 的图标 ID
      let iconId: string | null = marker.getIcon();
      let icon: Icon;

      if (!iconId) {
        // Marker 没有图标，加载默认图标
        icon = await this.loadDefaultIconForMarker(marker);
        iconId = icon.getId();
      } else {
        // 从缓存获取已有的 Icon
        const cached = this.iconMap.get(iconId);
        if (cached) {
          icon = cached.icon;
        } else {
          // 图标不在缓存中，这通常表示使用错误
          throw new Error(
            `[IconManager] Icon '${iconId}' not found in cache. ` +
              'Make sure to call addIconToManager() before using the icon.'
          );
        }
        // 更新最大图标尺寸
        this.updateHighestIconSize(icon);
      }

      // 添加图标（增加引用计数，首次添加时加载到 Native）
      await this.addIcon(icon);

      return icon;
    } catch (error) {
      console.error('[IconManager] Failed to load icon for marker:', error);
      throw new Error(`[IconManager] Failed to load icon for marker: ${error}`);
    }
  }

  /**
   * 加载默认图标（私有方法）
   *
   * 从 IconFactory 获取默认图标并设置到 Marker。
   *
   * @param marker Marker 实例
   * @returns Promise<Icon> 默认 Icon 封装类实例
   * @throws Error 如果 IconFactory 未初始化或加载失败
   */
  private async loadDefaultIconForMarker(marker: maplibre.Marker): Promise<Icon> {
    if (!this.iconFactory) {
      throw new Error('[IconManager] IconFactory is not initialized');
    }

    // 从 IconFactory 获取默认图标
    const icon = await this.iconFactory.defaultMarker();

    // 更新最大图标尺寸（Android 兼容：高度除以 2）
    const width = icon.getWidth();
    const height = icon.getHeight() / 2;
    this.updateHighestIconSize(width, height);

    // 将默认图标 ID 设置到 Marker
    marker.setIcon(icon.getId());

    return icon;
  }

  /**
   * 添加图标到缓存（私有方法）
   *
   * **引用计数管理**：
   * - 首次添加：refCount = 1，同时加载到 Native 层
   * - 重复添加：refCount++，不重复加载
   *
   * @param icon Icon 封装类实例
   * @param addIconToMap 是否加载到 Native 层（默认 true）
   */
  private async addIcon(icon: Icon, addIconToMap: boolean = true): Promise<void> {
    const iconId = icon.getId();
    const cached = this.iconMap.get(iconId);

    if (!cached) {
      // 首次添加图标
      const refData: IconRefData = { icon, refCount: 1 };
      this.iconMap.set(iconId, refData);

      if (addIconToMap) {
        await this.loadIconToNative(icon);
      } else {
      }

    } else {
      // 图标已存在，增加引用计数
      cached.refCount++;
    }
  }

  /**
   * 添加 Icon 到管理器
   *
   * 这是主要的公共 API，用于将 Icon 纳入生命周期管理。
   *
   * **使用场景**：
   * - Marker 设置了自定义图标后，需要将 Icon 加入管理
   * - 多个 Marker 共享同一个图标
   *
   * **自动处理**：
   * - 首次添加时自动加载到 Native 层
   * - 自动管理引用计数
   * - 检查 Icon 是否已释放
   *
   * @param icon Icon 封装类实例（必须是有效的，未释放的）
   * @throws Error 如果 Icon 已被释放
   *
   * @example
  * ```typescript
   * const icon = await iconFactory.fromResource($r('app.media.marker'));
   * marker.setIcon(icon.getId());
   * await iconManager.addIconToManager(icon);  // 纳入管理
   * ```
   */
  public async addIconToManager(icon: Icon): Promise<void> {
    // 检查 Icon 是否已释放
    if (icon.isReleased()) {
      throw new Error(
        `[IconManager] Cannot add released Icon '${icon.getId()}'. ` +
          'After calling markerManager.clear() or marker.remove(), ' +
          'the Icon is released and cannot be reused. ' +
          'You must create a new Icon through IconFactory.'
      );
    }

    // 添加到缓存并加载到 Native
    await this.addIcon(icon, true);
  }

  /**
   * 通过复用标识符获取已缓存的图标
   *
   * 类似 iOS 的 dequeueReusableAnnotationImageWithIdentifier
   *
   * @param reuseIdentifier 复用标识符
   * @returns Icon 封装类实例，如果不存在或已释放则返回 null
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
   * @returns Promise<Icon> Icon 封装类实例
   */
  public async getOrLoadIcon(marker: maplibre.Marker, defaultIconProvider?: () => Promise<Icon>): Promise<Icon> {
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
   * @param oldIcon 旧的 Icon 封装类实例（可为 null）
   * @param newIcon 新的 Icon 封装类实例
   */
  public async updateMarkerIcon(marker: maplibre.Marker, oldIcon: Icon | null, newIcon: Icon): Promise<void> {
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

    } catch (error) {
      console.error('[IconManager] Failed to update marker icon:', error);
      throw new Error('Failed to update marker icon: ' + error);
    }
  }

  /**
   * 加载图标到 Native 层（私有方法）
   *
   * 将 Icon 上传到 Native 地图样式中，使其可以被 SymbolLayer 引用。
   *
   * **NAPI Icon 优势**：
   * - 直接传递 Icon 对象引用，无需 PixelMap-to-bytes 转换
   * - C++ 层直接访问 PremultipliedImage 数据
   * - 避免了数据复制和序列化开销
   *
   * @param icon Icon 封装类实例
   * @throws Error 如果 Icon 已被释放或 NativeMapView 未初始化
   */
  private async loadIconToNative(icon: Icon): Promise<void> {
    try {
      // 1. 检查 Icon 状态
      if (icon.isReleased()) {
        throw new Error(
          `Cannot load released Icon '${icon.getId()}' to native. ` +
            'Icon has been released and cannot be reused.'
        );
      }

      // 2. 检查 NativeMapView
      if (!this.nativeMapView) {
        throw new Error('[IconManager] NativeMapView is not initialized');
      }

      // 3. 获取 Icon 信息（用于日志）
      const iconId = icon.getId();
      const width = icon.getWidth();
      const height = icon.getHeight();
      const scale = icon.getScale();

      // 4. 调用 Native API - 传递 NAPI Icon 对象
      // 优势：C++ 层直接访问 PremultipliedImage，无需数据转换
      this.nativeMapView.addAnnotationIcon(icon.getNative());

    } catch (error) {
      const iconId = icon.getId();
      console.error(`[IconManager] Failed to load icon '${iconId}' to native:`, error);
      throw new Error(`[IconManager] Failed to load icon '${iconId}' to native: ${error}`);
    }
  }

  /**
   * 清理图标（减少引用计数）
   *
   * 这是资源管理的核心方法，实现自动内存回收。
   *
   * **引用计数机制**：
   * - refCount > 1: 减少计数，继续保持在缓存中
   * - refCount == 1: 减少计数至 0，自动释放资源
   *
   * **自动释放流程**（refCount 降为 0 时）：
   * 1. 从 Native 层移除图标
   * 2. 从缓存中移除
   * 3. 调用 icon.release() 释放 C++ 层图像数据
   *
   * **重要提示**：
   * - Icon 一旦释放，不能再使用（isReleased() == true）
   * - 需要重新使用时，必须通过 IconFactory 创建新实例
   *
   * @param iconOrId Icon 封装类实例或图标 ID 字符串
   *
   * @example
  * ```typescript
   * // 方式 1: 传入 Icon 对象
   * iconManager.iconCleanup(icon);
   *
   * // 方式 2: 传入 Icon ID
   * iconManager.iconCleanup('com.maplibre.icons.icon_1');
   * ```
   */
  public iconCleanup(iconOrId: Icon | string): void {
    const iconId = typeof iconOrId === 'string' ? iconOrId : iconOrId.getId();
    const cached = this.iconMap.get(iconId);

    if (!cached) {
      console.warn(`[IconManager] Icon '${iconId}' not found in cache, cannot cleanup`);
      return;
    }

    if (cached.refCount === 1) {
      // 引用计数为 1，清理后变为 0，执行完全移除
      this.remove(cached.icon);
    } else {
      // 引用计数 > 1，仅递减计数
      cached.refCount--;
    }
  }

  /**
   * 从缓存和 Native 层完全删除图标（私有方法）
   *
   * 执行完整的图标移除流程：
   * 1. 从 Native 地图样式中移除
   * 2. 从本地缓存中移除
   * 3. 调用 icon.release() 释放 C++ 层资源
   *
   * @param icon Icon 封装类实例
   */
  private remove(icon: Icon): void {
    const iconId = icon.getId();

    try {
      // 1. 从 Native 层移除图标
      if (!this.nativeMapView) {
        throw new Error('[IconManager] NativeMapView is not initialized');
      }
      this.nativeMapView.removeAnnotationIcon(iconId);

      // 2. 从缓存中移除
      this.iconMap.delete(iconId);

      // 3. 释放 Icon 资源（C++ 层的 PremultipliedImage）
      if (!icon.isReleased()) {
        icon.release();
      }
    } catch (error) {
      console.error(`[IconManager] Failed to remove icon '${iconId}':`, error);
    }
  }

  /**
   * 重新加载所有图标
   *
   * 用于地图恢复或重新初始化
   */
  public async reloadIcons(): Promise<void> {

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

  }

  /**
   * 确保 Marker 的图标已加载
   *
   * 用于 Marker 更新时确保图标存在
   *
   * @param marker Marker 实例
   */
  public async ensureIconLoaded(marker: maplibre.Marker): Promise<void> {
    const iconId: string | null = marker.getIcon();
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
   * @param icon Icon 封装类实例
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
   * 获取指定 Icon 的高度
   *
   * @param iconId Icon ID
   * @returns Icon 的高度（逻辑像素），如果不存在返回 0
   */
  public getIconHeight(iconId: string): number {
    const iconRefData = this.iconMap.get(iconId);
    if (iconRefData) {
      return iconRefData.icon.getHeight();
    }
    return 0;
  }

  /**
   * 获取指定 Icon 的宽度
   *
   * @param iconId Icon ID
   * @returns Icon 的宽度（逻辑像素），如果不存在返回 0
   */
  public getIconWidth(iconId: string): number {
    const iconRefData = this.iconMap.get(iconId);
    if (iconRefData) {
      return iconRefData.icon.getWidth();
    }
    return 0;
  }

  /**
   * 更新最大图标尺寸（Icon 版本）
   *
   * @param iconOrWidth Icon 封装类实例或宽度
   * @param height 高度（可选）
   */
  private updateHighestIconSize(iconOrWidth: Icon | number, height?: number): void {
    let width: number;
    let h: number;
    let iconId = '';

    if (typeof iconOrWidth === 'number') {
      // 直接传入 width 和 height
      width = iconOrWidth;
      h = height!;
    } else {
      // 传入 Icon 对象
      width = iconOrWidth.getWidth();
      h = iconOrWidth.getHeight();
      iconId = iconOrWidth.getId();
    }

    let updated = false;
    if (width > this.highestIconWidth) {
      this.highestIconWidth = width;
      updated = true;
    }
    if (h > this.highestIconHeight) {
      this.highestIconHeight = h;
      updated = true;
    }

    if (updated || width === 0 || h === 0) {
    }
  }

  /**
   * 清理所有图标
   *
   * 完全清空 IconManager 的所有状态，释放所有资源。
   * 通常在地图销毁或重置时调用。
   *
   * **清理流程**：
   * 1. 遍历所有缓存的图标
   * 2. 从 Native 层移除每个图标
   * 3. 释放每个 Icon 的 C++ 资源
   * 4. 清空所有缓存和状态
   *
   * **注意**：
   * - 清理后所有 Icon 都会被释放，不能再使用
   * - 已释放的 Icon 引用会变为无效状态
   *
   * @example
  * ```typescript
   * // 地图销毁时清理
   * onDestroy() {
   *   iconManager.cleanup();
   * }
   * ```
   */
  public cleanup(): void {

    let successCount = 0;
    let failCount = 0;

    // 遍历所有图标进行清理
    this.iconMap.forEach((cached: IconRefData, iconId: string) => {
      try {
        // 从 Native 层移除
        if (this.nativeMapView) {
          this.nativeMapView.removeAnnotationIcon(iconId);
        }

        // 释放 Icon 资源
        if (!cached.icon.isReleased()) {
          cached.icon.release();
        }

        successCount++;
      } catch (error) {
        console.error(`[IconManager] Failed to cleanup icon '${iconId}':`, error);
        failCount++;
      }
    });

    // 清空所有缓存
    this.iconMap.clear();
    this.reuseIdentifierMap.clear();

    // 重置尺寸跟踪
    this.highestIconWidth = 0;
    this.highestIconHeight = 0;

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
   * @param icon Icon 封装类对象
   * @returns 引用计数，如果图标不存在返回 0
   */
  public getRefCount(icon: Icon): number {
    const cached = this.iconMap.get(icon.getId());
    return cached ? cached.refCount : 0;
  }
}

