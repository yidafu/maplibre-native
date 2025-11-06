import maplibre from 'libmaplibre.so';
import { Marker } from './Marker';
import { AnnotationViewConfig, AnnotationViewDelegate } from './AnnotationViewDelegate';

/**
 * AnnotationViewAdapter - 自定义 Annotation 视图适配器（兼容层）
 *
 * **注意**: 此接口已废弃，建议使用 {@link AnnotationViewDelegate} 替代
 * 
 * 该接口保留用于向后兼容，新代码应使用功能更完整的 AnnotationViewDelegate
 *
 * @deprecated 使用 {@link AnnotationViewDelegate} 替代
 * 
 * @example 旧用法（不推荐）：
 * ```typescript
 * class MyAdapter implements AnnotationViewAdapter {
 *   getAnnotationView(marker: Marker): object | null {
 *     return someCustomView;
 *   }
 * }
 * ```
 * 
 * @example 新用法（推荐）：
 * ```typescript
 * const delegate: AnnotationViewDelegate = {
 *   viewForAnnotation: (marker: Marker) => {
 *     return {
 *       reuseIdentifier: 'custom',
 *       contentBuilder: () => {
 *         Column() {
 *           Image($r('app.media.marker')).width(32).height(32)
 *         }
 *       }
 *     };
 *   }
 * };
 * mapLibreMap.setAnnotationViewDelegate(delegate);
 * ```
 */
export interface AnnotationViewAdapter {
  /**
   * 为 Marker 创建自定义视图
   *
   * @param marker 要显示的 Marker
   * @returns 自定义视图组件内容，返回 null 使用默认图标
   * 
   * @deprecated 使用 AnnotationViewDelegate.viewForAnnotation 替代
   */
  getAnnotationView(marker: Marker): object | null;

  /**
   * 获取视图复用标识符（可选，用于性能优化）
   *
   * 具有相同标识符的视图可以被复用，减少视图创建开销
   *
   * @param marker 要显示的 Marker
   * @returns 复用标识符，默认使用 marker.getIcon()
   * 
   * @deprecated 使用 AnnotationViewDelegate.getReuseIdentifier 替代
   */
  getReuseIdentifier?(marker: Marker): string;
}

/**
 * 从 AnnotationViewAdapter 创建 AnnotationViewDelegate（兼容层）
 * 
 * 将旧的 Adapter 接口转换为新的 Delegate 接口
 * 
 * @param adapter 旧的 AnnotationViewAdapter 实例
 * @returns 转换后的 AnnotationViewDelegate 实例
 * 
 * @example
 * ```typescript
 * const oldAdapter: AnnotationViewAdapter = { ... };
 * const delegate = createDelegateFromAdapter(oldAdapter);
 * mapLibreMap.setAnnotationViewDelegate(delegate);
 * ```
 */
class DelegateAdapter implements AnnotationViewDelegate {
  private adapter: AnnotationViewAdapter;

  constructor(adapter: AnnotationViewAdapter) {
    this.adapter = adapter;
  }

  viewForAnnotation(marker: Marker): AnnotationViewConfig | null {
    const customView = this.adapter.getAnnotationView(marker);
    if (!customView) {
      return null;
    }

    // 获取复用标识符
    const reuseIdentifier = this.adapter.getReuseIdentifier?.(marker) ?? marker.getIcon() ?? 'default';

    // 注意：由于 adapter 返回的是 object，我们无法直接转换为 Builder
    // 这里返回一个基本配置，实际内容需要通过其他方式处理
    const config: AnnotationViewConfig = {
      reuseIdentifier: reuseIdentifier,
      // customView 暂时无法直接转换为 contentBuilder
      // 这是为什么建议直接使用 Delegate 的原因
    };
    return config;
  }

  getReuseIdentifier?(marker: Marker): string | undefined {
    return this.adapter.getReuseIdentifier?.(marker);
  }
}

export function createDelegateFromAdapter(adapter: AnnotationViewAdapter): AnnotationViewDelegate {
  return new DelegateAdapter(adapter);
}

