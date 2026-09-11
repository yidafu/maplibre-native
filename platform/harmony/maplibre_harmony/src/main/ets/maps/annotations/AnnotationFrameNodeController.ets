import { ComponentContent, FrameNode, NodeController, UIContext } from '@kit.ArkUI';
import type { ViewAnnotationRenderState } from './NativeViewAnnotationOverlay';

/**
 * AnnotationFrameNodeController manages the lifecycle of a FrameNode used to render
 * a single ViewAnnotation (e.g., InfoWindow) in the overlay.
 *
 * Each controller is responsible for one annotation. The overlay creates/reuses
 * controllers as annotations appear/disappear, updating only position/visibility
 * properties when the annotation moves — without recreating the underlying
 * ComponentContent or FrameNode.
 *
 * Lifecycle:
 *   1. makeNode(uiContext)  — creates FrameNode, attaches ComponentContent
 *   2. attachContent(content) — attaches or replaces the ComponentContent
 *   3. updateProperties(state) — updates position, visibility, scale, rotation, opacity, zIndex
 *   4. dispose() — removes ComponentContent, releases FrameNode
 */
export class AnnotationFrameNodeController extends NodeController {
  private frameNode: FrameNode | null = null;
  private componentContent: ComponentContent<Object> | null = null;
  private annotationId: number = -1;
  // Store the latest render state so makeNode() can apply it after creating the FrameNode.
  // This is needed because updateProperties() may be called before the FrameNode exists
  // (the ForEach builder runs before the framework calls makeNode), and with a stable
  // ForEach key the builder is never invoked again for subsequent state updates.
  private pendingState: ViewAnnotationRenderState | null = null;

  constructor(annotationId: number) {
    super();
    this.annotationId = annotationId;
    console.info(`[AnnotationFrameNodeController] Created for annotation ${annotationId}`);
  }

  /**
   * Called by the ArkUI framework to create the FrameNode for this controller.
   * This happens once when the NodeContainer first renders.
   */
  makeNode(uiContext: UIContext): FrameNode | null {
    if (!uiContext) {
      console.error(`[AnnotationFrameNodeController] makeNode: no UIContext for annotation ${this.annotationId}`);
      return null;
    }

    try {
      this.frameNode = new FrameNode(uiContext);
      // Set initial default properties.
      // Default: the annotation subtree (window content, close button, gestures)
      // stays interactive while taps on the annotation block siblings — i.e.
      // they do not fall through to markers beneath. The full-screen overlay
      // container stays Transparent so gestures on empty areas reach the map.
      this.frameNode.commonAttribute
        .position({ x: 0, y: 0 })
        .visibility(Visibility.Hidden)
        .hitTestBehavior(HitTestMode.Default);

      // Attach ComponentContent if already available
      if (this.componentContent) {
        this.frameNode.addComponentContent(this.componentContent);
      }

      // Apply the pending render state if available (set by updateProperties
      // before the FrameNode existed — happens because the ForEach builder
      // runs before the framework calls makeNode).
      if (this.pendingState) {
        this.applyState(this.frameNode, this.pendingState);
      }

      console.info(`[AnnotationFrameNodeController] makeNode: FrameNode created for annotation ${this.annotationId}`);
      return this.frameNode;
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[AnnotationFrameNodeController] makeNode failed for annotation ${this.annotationId}: ${reason}`);
      return null;
    }
  }

  /**
   * Attach (or replace) the ComponentContent on this FrameNode.
   * Called after the FrameNode is created, or when content changes.
   */
  attachContent(content: ComponentContent<Object>): void {
    if (this.componentContent === content) {
      return; // No change
    }

    this.componentContent = content;

    // If FrameNode already exists, rebuild to apply the new content.
    // FrameNode has no removeComponentContent method, so we dispose the old
    // node (releasing its native binding) and recreate it via makeNode().
    if (this.frameNode) {
      try {
        this.disposeFrameNode();
        this.rebuild();
        console.info(`[AnnotationFrameNodeController] Rebuilt FrameNode with new content for annotation ${this.annotationId}`);
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        console.warn(`[AnnotationFrameNodeController] rebuild failed for annotation ${this.annotationId}: ${reason}`);
      }
    }
  }

  /**
   * Get the currently attached ComponentContent (may be null).
   * Used by the overlay to detect content replacement.
   */
  getContent(): ComponentContent<Object> | null {
    return this.componentContent;
  }

  /**
   * Update position, visibility, scale, rotation, and opacity properties
   * on the FrameNode. This does NOT recreate the FrameNode or rebuild the
   * ComponentContent — it only modifies attribute properties, making it
   * efficient for per-frame camera-move updates.
   *
   * If the FrameNode hasn't been created yet (makeNode hasn't been called
   * by the framework), the state is stored as pendingState and will be
   * applied inside makeNode once the FrameNode exists.
   */
  updateProperties(state: ViewAnnotationRenderState): void {
    // Always store the latest state (for later use in makeNode)
    this.pendingState = state;

    if (!this.frameNode) {
      return;
    }

    try {
      this.applyState(this.frameNode, state);
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[AnnotationFrameNodeController] updateProperties failed for annotation ${this.annotationId}: ${reason}`);
    }
  }

  /**
   * Apply the render state properties to a FrameNode.
   * Extracted as a shared helper used by both updateProperties() and makeNode().
   */
  private applyState(fn: FrameNode, state: ViewAnnotationRenderState): void {
    fn.commonAttribute
      .position({
        x: state.positionX,
        y: state.positionY
      })
      .visibility(state.visible ? Visibility.Visible : Visibility.Hidden)
      .opacity(this.sanitizeOpacity(state.opacity));

    // Apply size only in fixed-size mode. In auto-size mode the content hugs
    // its own bounds and the measured size feeds the positioning engine; an
    // explicit width here would re-constrain the measurement (circular).
    if (state.applySize) {
      if (state.width > 0) {
        fn.commonAttribute.width(state.width);
      }
      if (state.height > 0) {
        fn.commonAttribute.height(state.height);
      }
    }

    // Apply transform (scale + rotation) only when significantly different from identity
    const needsScale = Math.abs(state.scale - 1.0) > 0.01;
    const needsRotation = Math.abs(state.rotation) > 0.1;

    if (needsScale || needsRotation) {
      const safeScale = this.sanitizeScale(state.scale);
      const safeRotation = state.rotation;
      fn.commonAttribute.scale({
        x: safeScale,
        y: safeScale,
        centerX: '50%',
        centerY: '100%'
      });
      if (needsRotation) {
        fn.commonAttribute.rotate({
          angle: safeRotation,
          centerX: '50%',
          centerY: '100%'
        });
      }
    }

    // Apply zIndex if specified
    if (state.zIndex !== undefined && state.zIndex !== 0) {
      fn.commonAttribute.zIndex(state.zIndex);
    }
  }

  /**
   * Dispose: release the FrameNode's native binding and drop references.
   * Called when the annotation is removed from the overlay or when the
   * content is swapped (the node is recreated by rebuild()).
   */
  dispose(): void {
    console.info(`[AnnotationFrameNodeController] Disposing annotation ${this.annotationId}`);
    this.disposeFrameNode();
    this.componentContent = null;
    this.pendingState = null;
  }

  getAnnotationId(): number {
    return this.annotationId;
  }

  private disposeFrameNode(): void {
    const node = this.frameNode;
    this.frameNode = null;
    if (!node) {
      return;
    }
    try {
      // Release the native node binding; a node already detached by the
      // framework is a no-op.
      node.dispose();
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.warn(`[AnnotationFrameNodeController] FrameNode dispose failed for annotation ${this.annotationId}: ${reason}`);
    }
  }

  private sanitizeOpacity(value: number): number {
    if (!Number.isFinite(value)) {
      return 1;
    }
    if (value <= 0) {
      return 0;
    }
    if (value >= 1) {
      return 1;
    }
    return value;
  }

  private sanitizeScale(value: number): number {
    if (!Number.isFinite(value) || value <= 0) {
      return 1;
    }
    return value;
  }
}
