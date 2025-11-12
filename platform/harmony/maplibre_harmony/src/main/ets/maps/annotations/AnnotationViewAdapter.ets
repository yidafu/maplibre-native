import maplibre from 'libmaplibre.so';
import { Marker } from './Marker';
import { AnnotationViewConfig, AnnotationViewDelegate } from './AnnotationViewDelegate';

/**
 * AnnotationViewAdapter - Legacy annotation view adapter (compatibility layer)
 *
 * **Note**: This interface is deprecated; prefer {@link AnnotationViewDelegate}.
 *
 * Retained for backward compatibility. New code should use the richer AnnotationViewDelegate.
 *
 * @deprecated Use {@link AnnotationViewDelegate} instead.
 *
 * @example Legacy usage (not recommended):
 * ```typescript
 * class MyAdapter implements AnnotationViewAdapter {
 *   getAnnotationView(marker: Marker): object | null {
 *     return someCustomView;
 *   }
 * }
 * ```
 * 
 * @example Recommended delegate usage:
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
   * Create a custom view for a marker
   *
   * @param marker Marker to render
   * @returns Custom view component or null to use default icon
   *
   * @deprecated Use AnnotationViewDelegate.viewForAnnotation
   */
  getAnnotationView(marker: Marker): object | null;

  /**
   * Optional reuse identifier (performance optimization)
   *
   * Views sharing the same identifier can be reused to avoid extra creation cost.
   *
   * @param marker Marker being displayed
   * @returns Reuse identifier (defaults to marker.getIcon())
   *
   * @deprecated Use AnnotationViewDelegate.getReuseIdentifier
   */
  getReuseIdentifier?(marker: Marker): string;
}

/**
 * Create AnnotationViewDelegate from AnnotationViewAdapter (compat layer)
 *
 * Converts the legacy adapter interface into the delegate interface.
 *
 * @param adapter Legacy AnnotationViewAdapter instance
 * @returns Converted AnnotationViewDelegate
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

    // Determine reuse identifier
    const reuseIdentifier = this.adapter.getReuseIdentifier?.(marker) ?? marker.getIcon() ?? 'default';

    // Note: adapter returns plain object; cannot convert to Builder directly
    // Provide minimal config—actual rendering handled elsewhere
    const config: AnnotationViewConfig = {
      reuseIdentifier: reuseIdentifier,
      // customView cannot currently be converted into a contentBuilder
      // Hence the recommendation to rely on the Delegate API
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

