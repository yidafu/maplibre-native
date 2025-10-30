import image from '@ohos.multimedia.image';

/**
 * Icon - 图标类（NAPI 实现）
 * 
 * 表示地图标注的图标，包含图标的位图数据和元信息。
 * Icon 对象在 C++ 层持有图像数据，避免了重复的数据转换。
 * 
 * **重要提示：Icon 生命周期管理**
 * - Icon 对象由 IconManager 管理，使用引用计数跟踪使用情况
 * - 当调用 markerManager.clear() 或 marker.remove() 时，Icon 的引用计数会减少
 * - 当引用计数降为 0 时，Icon 会被自动释放（调用 release()）
 * - **已释放的 Icon 不能被复用**，必须创建新的 Icon 实例
 * - 如果需要在清除后重新添加相同的图标，请创建新的 Icon 对象
 * 
 * 此类由 C++ NAPI 层实现，ETS 层直接使用
 * 
 * 参考:
 * - Android: org.maplibre.android.annotations.Icon
 * - iOS: MLNAnnotationImage
 * 
 * @example
 * ```typescript
 * import maplibre from 'libmaplibre.so';
 * import image from '@ohos.multimedia.image';
 * 
 * // 通过 IconFactory 创建 Icon（推荐）
 * const factory = IconFactory.getInstance();
 * const icon = await factory.fromResource($r('app.media.marker'));
 * marker.setIcon(icon);
 * 
 * // 或者直接创建（不推荐，通常由 IconFactory 内部使用）
 * const pixelMap = ...; // 获取 PixelMap
 * const icon = new maplibre.Icon('my-icon-id', pixelMap, 2.0);
 * 
 * // 错误用法：清除后复用
 * markerManager.clear(); // Icon 会被释放
 * marker2.setIcon(icon); // ❌ 错误！Icon 已释放
 * 
 * // 正确用法：创建新的 Icon
 * const icon2 = await factory.fromResource($r('app.media.marker'));
 * marker2.setIcon(icon2); // ✓ 正确
 * ```
 */
export class Icon {
  /**
   * 构造函数
   * 
   * 创建一个新的 Icon 实例。PixelMap 会在构造时立即转换为 C++ 层的图像数据。
   * 
   * **注意**：通常应该使用 IconFactory 创建 Icon，而不是直接调用构造函数。
   * 
   * @param id 图标唯一标识符
   * @param pixelMap HarmonyOS PixelMap 对象（会在构造时转换为 C++ 图像数据）
   * @param scale 像素密度比例（可选，默认 1.0）
   */
  constructor(id: string, pixelMap: image.PixelMap, scale?: number);
  
  /**
   * 获取图标唯一标识符
   * 
   * @returns 图标 ID
   */
  getId(): string;
  
  /**
   * 获取图标宽度（像素）
   * 
   * @returns 宽度
   */
  getWidth(): number;
  
  /**
   * 获取图标高度（像素）
   * 
   * @returns 高度
   */
  getHeight(): number;
  
  /**
   * 获取像素密度比例
   * 
   * 用于适配不同屏幕密度的设备
   * 
   * @returns 像素密度比例
   */
  getScale(): number;
  
  /**
   * 检查 Icon 是否已被释放
   * 
   * 当 Icon 被释放后（调用 release() 或引用计数降为0），图像数据会被释放。
   * 已释放的 Icon 不能再使用，尝试使用会抛出错误。
   * 
   * @returns true 表示已释放，false 表示可用
   */
  isReleased(): boolean;
  
  /**
   * 释放资源
   * 
   * 释放 Icon 占用的 C++ 图像数据内存。此方法通常由 IconManager 自动调用，
   * 当 Icon 的引用计数降为 0 时（例如所有使用该 Icon 的 Marker 都被移除）。
   * 
   * **警告**：释放后的 Icon 不能再使用，尝试使用会抛出错误。
   * 如果需要再次使用相同的图标，必须创建新的 Icon 实例。
   */
  release(): void;
}

