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
 */
export class ComponentContentRegistry {
  private static instance: ComponentContentRegistry | null = null;
  private contentMap: Map<number, ComponentContent<Object>> = new Map();

  static getInstance(): ComponentContentRegistry {
    if (!ComponentContentRegistry.instance) {
      ComponentContentRegistry.instance = new ComponentContentRegistry();
    }
    return ComponentContentRegistry.instance;
  }

  /**
   * Register a ComponentContent for an annotation ID.
   * Called by InfoWindowManager when a new InfoWindow is shown.
   */
  register(id: number, content: ComponentContent<Object>): void {
    if (id <= 0) {
      console.warn('[ComponentContentRegistry] Ignoring invalid annotation ID:', id);
      return;
    }
    this.contentMap.set(id, content);
    console.info(`[ComponentContentRegistry] Registered content for annotation ${id}, total: ${this.contentMap.size}`);
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
    const existed = this.contentMap.delete(id);
    if (existed) {
      console.info(`[ComponentContentRegistry] Removed content for annotation ${id}, remaining: ${this.contentMap.size}`);
    }
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
    const count = this.contentMap.size;
    this.contentMap.clear();
    console.info(`[ComponentContentRegistry] Cleared all ${count} registered contents`);
  }

  /**
   * Get the total count of registered ComponentContent instances.
   */
  get size(): number {
    return this.contentMap.size;
  }
}
