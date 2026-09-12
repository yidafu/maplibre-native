import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
/**
 * TooManyIconsException - icon count overflow exception.
 *
 * Thrown when the number of created icons exceeds the system limit.
 * Typically occurs when the icon ID counter overflows.
 *
 * Reference:
 * - Android: org.maplibre.android.exceptions.TooManyIconsException
 *
 * @example
 * ```typescript
 * try {
 *   const icon = iconFactory.fromPixelMap(pixelMap);
 * } catch (error) {
 *   if (error instanceof TooManyIconsException) {
 *     hilog.error(DOMAIN, 'TooManyIconsException', '%{public}s', 'Too many icons created!');
 *   }
 * }
 * ```
 */
export class TooManyIconsException extends Error {
  /**
   * Constructor.
   *
   * @param message Optional error message.
   */
  constructor(message?: string) {
    super(message || 'Too many icons created. Maximum icon count exceeded.');
    this.name = 'TooManyIconsException';
  }
}

