import type { ComponentContent } from '@kit.ArkUI';
import type { ViewAnnotationManager } from './ViewAnnotationManager';
import type { ViewAnnotationUpdateOptions } from './ViewAnnotationManager';

/**
 * ViewAnnotationHandle - stable reference to a ViewAnnotation added to the map.
 *
 * Returned by ViewAnnotationManager.addViewAnnotation(). It bundles the
 * annotation id with the manager that owns it, so callers never handle raw
 * numeric ids or reach into internal registries. The underlying annotation is
 * removed from the map when the handle's owning MapLibreMap is destroyed.
 */
export class ViewAnnotationHandle {
  private readonly annotationId: number;
  private readonly owner: ViewAnnotationManager | null;

  constructor(annotationId: number, owner: ViewAnnotationManager | null) {
    this.annotationId = annotationId;
    this.owner = owner;
  }

  /**
   * Numeric annotation id. Only needed when calling legacy id-based manager
   * methods; prefer the handle methods below.
   */
  getId(): number {
    return this.annotationId;
  }

  /**
   * Apply a partial update (anchor, size constraint, visibility, zoom range,
   * anchor, zIndex, ...).
   *
   * @returns true when the update reached the native layer.
   */
  update(options: ViewAnnotationUpdateOptions): boolean {
    return this.owner?.updateViewAnnotation(this.annotationId, options) ?? false;
  }

  /**
   * Convenience wrapper for update({ visible }).
   */
  setVisible(visible: boolean): boolean {
    return this.update({ visible: visible });
  }

  /**
   * Replace the rendered content (ComponentContent) of this annotation.
   *
   * @returns true when the content was replaced and re-rendered.
   */
  setContent(content: ComponentContent<Object> | null): boolean {
    return this.owner?.setAnnotationContent(this.annotationId, content) ?? false;
  }

  /**
   * Remove this annotation from the map. The handle becomes inert afterwards;
   * calling update/remove again is a harmless no-op returning false.
   */
  remove(): boolean {
    return this.owner?.removeViewAnnotation(this.annotationId) ?? false;
  }
}
