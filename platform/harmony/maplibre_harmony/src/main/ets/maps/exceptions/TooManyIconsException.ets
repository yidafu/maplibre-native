/**
 * TooManyIconsException - 图标数量超限异常
 *
 * 当创建的图标数量超过系统允许的最大值时抛出此异常。
 * 这通常发生在 Icon ID 计数器溢出时。
 *
 * 参考:
 * - Android: org.maplibre.android.exceptions.TooManyIconsException
 *
 * @example
* ```typescript
 * try {
 *   const icon = iconFactory.fromPixelMap(pixelMap);
 * } catch (error) {
 *   if (error instanceof TooManyIconsException) {
 *     console.error('Too many icons created!');
 *   }
 * }
 * ```
 */
export class TooManyIconsException extends Error {
  /**
   * 构造函数
   *
   * @param message 错误消息（可选）
   */
  constructor(message?: string) {
    super(message || 'Too many icons created. Maximum icon count exceeded.');
    this.name = 'TooManyIconsException';
  }
}

