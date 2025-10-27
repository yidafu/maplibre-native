import image from '@ohos.multimedia.image';

/**
 * Icon - 标注图标类
 * 
 * Icon 是 Marker 的视觉表现形式，包含图标的位图数据和元信息。
 * 可以通过 IconFactory 创建 Icon 实例。
 * 
 * **重要提示：Icon 生命周期管理**
 * - Icon 对象由 IconManager 管理，使用引用计数跟踪使用情况
 * - 当调用 markerManager.clear() 或 marker.remove() 时，Icon 的引用计数会减少
 * - 当引用计数降为 0 时，Icon 会被自动释放（调用 release()），PixelMap 资源会被回收
 * - **已释放的 Icon 不能被复用**，必须创建新的 Icon 实例
 * - 如果需要在清除后重新添加相同的图标，请创建新的 Icon 对象
 * 
 * 参考:
 * - Android: org.maplibre.android.annotations.Icon
 * - iOS: MLNAnnotationImage
 * 
 * @example
 * ```typescript
 * const factory = IconFactory.getInstance();
 * const icon = await factory.fromResource($r('app.media.marker'));
 * marker.setIcon(icon);
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
  private id: string;
  private reuseIdentifier: string;
  private pixelMap: image.PixelMap | null;
  private width: number;
  private height: number;
  private pixelRatio: number;
  private enabled: boolean = true;

  /**
   * 构造函数（内部使用，通过 IconFactory 创建）
   * 
   * @param id 图标唯一标识符
   * @param pixelMap PixelMap 图像对象
   * @param pixelRatio 像素密度比例
   * @param reuseIdentifier 复用标识符（可选，默认与 id 相同）
   */
  constructor(id: string, pixelMap: image.PixelMap | null, pixelRatio: number = 1.0, reuseIdentifier?: string) {
    this.id = id;
    this.reuseIdentifier = reuseIdentifier || id;
    this.pixelMap = pixelMap;
    this.pixelRatio = pixelRatio;
    
    if (pixelMap) {
      const imageInfo = pixelMap.getImageInfoSync();
      this.width = imageInfo.size.width;
      this.height = imageInfo.size.height;
    } else {
      this.width = 0;
      this.height = 0;
    }
  }

  /**
   * 获取图标唯一标识符
   * 
   * @returns 图标 ID
   */
  public getId(): string {
    return this.id;
  }

  /**
   * 获取复用标识符
   * 
   * 用于图标复用队列管理，相同 reuseIdentifier 的图标可以共享
   * 
   * @returns 复用标识符
   */
  public getReuseIdentifier(): string {
    return this.reuseIdentifier;
  }

  /**
   * 获取 PixelMap 对象
   * 
   * @returns PixelMap 图像对象，如果不存在则返回 null
   */
  public getPixelMap(): image.PixelMap | null {
    return this.pixelMap;
  }

  /**
   * 获取图标宽度（像素）
   * 
   * @returns 宽度
   */
  public getWidth(): number {
    return this.width;
  }

  /**
   * 获取图标高度（像素）
   * 
   * @returns 高度
   */
  public getHeight(): number {
    return this.height;
  }

  /**
   * 获取像素密度比例
   * 
   * 用于适配不同屏幕密度的设备
   * 
   * @returns 像素密度比例
   */
  public getScale(): number {
    return this.pixelRatio;
  }

  /**
   * 获取图标是否可交互
   * 
   * @returns true 表示图标可交互（响应点击等事件）
   */
  public isEnabled(): boolean {
    return this.enabled;
  }

  /**
   * 设置图标是否可交互
   * 
   * @param enabled true 表示可交互，false 表示禁用交互
   */
  public setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  /**
   * 检查 Icon 是否已被释放
   * 
   * 当 Icon 被释放后（调用 release() 或引用计数降为0），PixelMap 会被设置为 null
   * 已释放的 Icon 不能再使用，必须创建新的 Icon 实例
   * 
   * @returns true 表示已释放，false 表示可用
   */
  public isReleased(): boolean {
    return this.pixelMap === null;
  }

  /**
   * 将 PixelMap 转换为字节数组
   * 
   * 用于传递给 Native 层进行渲染
   * 
   * @returns 图像字节数组，RGBA 格式
   * @throws Error 如果 PixelMap 不存在或转换失败
   */
  public async toBytes(): Promise<Uint8Array> {
    if (!this.pixelMap) {
      throw new Error(
        `Icon '${this.id}' has been released and cannot be reused. ` +
        'After calling markerManager.clear() or marker.remove(), ' +
        'you must create a new Icon instead of reusing the old one.'
      );
    }

    try {
      // 读取 PixelMap 的像素数据
      const buffer = new ArrayBuffer(this.width * this.height * 4); // RGBA
      await this.pixelMap.readPixelsToBuffer(buffer);
      return new Uint8Array(buffer);
    } catch (error) {
      throw new Error(`Failed to convert PixelMap to bytes: ${error}`);
    }
  }

  /**
   * 同步方式将 PixelMap 转换为字节数组
   * 
   * @returns 图像字节数组，RGBA 格式
   * @throws Error 如果 PixelMap 不存在或转换失败
   */
  public toBytesSync(): Uint8Array {
    if (!this.pixelMap) {
      throw new Error(
        `Icon '${this.id}' has been released and cannot be reused. ` +
        'After calling markerManager.clear() or marker.remove(), ' +
        'you must create a new Icon instead of reusing the old one.'
      );
    }

    try {
      // 读取 PixelMap 的像素数据（同步）
      const buffer = new ArrayBuffer(this.width * this.height * 4); // RGBA
      const area: image.PositionArea = {
        pixels: buffer,
        offset: 0,
        stride: this.width * 4,
        region: { size: { height: this.height, width: this.width }, x: 0, y: 0 }
      };
      this.pixelMap.readPixelsSync(area);
      return new Uint8Array(buffer);
    } catch (error) {
      throw new Error(`Failed to convert PixelMap to bytes: ${error}`);
    }
  }

  /**
   * 比较两个 Icon 是否相等
   * 
   * 基于 ID 和 PixelMap 对象引用进行比较
   * 
   * @param other 另一个 Icon 对象
   * @returns 如果相等返回 true，否则返回 false
   */
  public equals(other: Icon | null): boolean {
    if (!other) {
      return false;
    }
    if (this === other) {
      return true;
    }
    return this.id === other.id && this.pixelMap === other.pixelMap;
  }

  /**
   * 生成哈希码
   * 
   * 用于 Map/Set 等数据结构中的快速查找
   * 
   * @returns 哈希码
   */
  public hashCode(): number {
    let hash = 0;
    for (let i = 0; i < this.id.length; i++) {
      const char = this.id.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return hash;
  }

  /**
   * 转换为字符串表示
   * 
   * @returns 字符串表示
   */
  public toString(): string {
    return `Icon(id=${this.id}, size=${this.width}x${this.height}, scale=${this.pixelRatio})`;
  }

  /**
   * 释放资源
   * 
   * 释放 PixelMap 占用的内存。此方法通常由 IconManager 自动调用，
   * 当 Icon 的引用计数降为 0 时（例如所有使用该 Icon 的 Marker 都被移除）。
   * 
   * **警告**：释放后的 Icon 不能再使用，尝试使用会抛出错误。
   * 如果需要再次使用相同的图标，必须创建新的 Icon 实例。
   */
  public release(): void {
    if (this.pixelMap) {
      this.pixelMap.release();
      this.pixelMap = null;
    }
  }
}

