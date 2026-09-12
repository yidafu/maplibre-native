import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import { ComponentContent } from '@kit.ArkUI';

/**
 * ComponentContentRegistry maintains the mapping from annotation ID to ComponentContent.
 *
 * Used by the rendering overlay to retrieve the correct ComponentContent for each
 * ViewAnnotation frame. Content is registered by InfoWindowManager when an InfoWindow
 * is shown, and cleaned up when it is closed.
 *
 * This decouples content creation (InfoWindowManager/Adapter) from content rendering
 * (NativeViewAnnotationOverlay).
 *
 * Each ViewAnnotationManager owns one instance: annotation IDs are allocated per
 * native map, so a process-wide registry would collide when multiple map
 * instances are alive at the same time.
 */
export class ComponentContentRegistry {
  private contentMap: Map<number, ComponentContent<Object>> = new Map();

  /**
   * Register a ComponentContent for an annotation ID.
   * Called by InfoWindowManager when a new InfoWindow is shown.
   */
  register(id: number, content: ComponentContent<Object>): void {
    if (id <= 0) {
      hilog.warn(DOMAIN, 'ComponentContentRegistry', '[ComponentContentRegistry] Ignoring invalid annotation ID: %{public}s', id);
      return;
    }
    this.contentMap.set(id, content);
  }

  /**
   * Retrieve the ComponentContent for an annotation ID.
   * Called by the overlay during rendering.
   */
  get(id: number): ComponentContent<Object> | null {
    return this.contentMap.get(id) ?? null;
  }

  /**
   * Remove the ComponentContent for an annotation ID.
   * Called when an InfoWindow is closed or annotation is removed.
   */
  remove(id: number): void {
    this.contentMap.delete(id);
  }

  /**
   * Check if content is registered for an annotation ID.
   */
  has(id: number): boolean {
    return this.contentMap.has(id);
  }

  /**
   * Clear all registered ComponentContent instances.
   * Called during cleanup.
   */
  clear(): void {
    this.contentMap.clear();
  }

  /**
   * Get the total count of registered ComponentContent instances.
   */
  get size(): number {
    return this.contentMap.size;
  }
}
