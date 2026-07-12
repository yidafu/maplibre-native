import { AnnotationFrameNodeController } from './AnnotationFrameNodeController';
import { ComponentContentRegistry } from './ComponentContentRegistry';

/**
 * ViewAnnotationRenderState represents the computed render state for a single
 * ViewAnnotation frame, produced by ViewAnnotationManager and consumed by
 * NativeViewAnnotationOverlay for rendering via NodeContainer + FrameNode.
 */
export interface ViewAnnotationRenderStateParams {
  id: number;
  positionX: number;
  positionY: number;
  width: number;
  height: number;
  scale: number;
  rotation: number;
  opacity: number;
  visible: boolean;
  viewName: string;
  zIndex?: number;
}

export class ViewAnnotationRenderState {
  id: number;
  positionX: number;
  positionY: number;
  width: number;
  height: number;
  scale: number;
  rotation: number;
  opacity: number;
  visible: boolean;
  viewName: string;
  zIndex?: number;

  constructor(params: ViewAnnotationRenderStateParams) {
    this.id = params.id;
    this.positionX = params.positionX;
    this.positionY = params.positionY;
    this.width = params.width;
    this.height = params.height;
    this.scale = params.scale;
    this.rotation = params.rotation;
    this.opacity = params.opacity;
    this.visible = params.visible;
    this.viewName = params.viewName;
    this.zIndex = params.zIndex;
  }
}

/**
 * NativeViewAnnotationOverlay renders ViewAnnotation frames as positioned
 * FrameNodes via NodeContainer + AnnotationFrameNodeController.
 *
 * Each frame gets a NodeController that manages a FrameNode. The
 * ComponentContent for each annotation is retrieved from
 * ComponentContentRegistry (populated by InfoWindowManager).
 *
 * FrameNodes are reused across re-renders — only position/visibility
 * properties are updated, without recreating ComponentContent.
 */
@Component
export struct NativeViewAnnotationOverlay {
  @Link @Watch('onFramesChanged') frames: ViewAnnotationRenderState[];
  @State private renderFrames: ViewAnnotationRenderState[] = [];
  private controllerMap: Map<number, AnnotationFrameNodeController> = new Map();
  private readonly POSITION_EPSILON: number = 0.1;
  private readonly SIZE_EPSILON: number = 0.1;
  private readonly SCALE_EPSILON: number = 0.01;
  private readonly ROTATION_EPSILON: number = 0.01;
  private readonly OPACITY_EPSILON: number = 0.01;

  aboutToAppear(): void {
    this.syncRenderFrames(this.frames);
  }

  aboutToDisappear(): void {
    // Dispose all controllers to clean up FrameNode resources
    this.controllerMap.forEach((ctrl) => {
      ctrl.dispose();
    });
    this.controllerMap.clear();
  }

  private onFramesChanged(): void {
    this.syncRenderFrames(this.frames);
  }

  private syncRenderFrames(source: ViewAnnotationRenderState[] | undefined): void {
    const nextFrames: ViewAnnotationRenderState[] = (source ?? []).map((state) =>
      new ViewAnnotationRenderState({
        id: state.id,
        positionX: state.positionX,
        positionY: state.positionY,
        width: state.width,
        height: state.height,
        scale: state.scale,
        rotation: state.rotation,
        opacity: state.opacity,
        visible: state.visible,
        viewName: state.viewName,
        zIndex: state.zIndex
      })
    );

    const previousById: Map<number, ViewAnnotationRenderState> = new Map();
    this.renderFrames.forEach((state) => {
      previousById.set(state.id, state);
    });

    let hasChange: boolean = nextFrames.length !== this.renderFrames.length;
    const updatedFrames: ViewAnnotationRenderState[] = [];

    nextFrames.forEach((state) => {
      const previous = previousById.get(state.id);
      if (previous && this.areStatesEquivalent(previous, state)) {
        updatedFrames.push(previous);
        return;
      }

      hasChange = true;
      updatedFrames.push(state);
    });

    // Clean up controllers for removed annotations
    const nextIds: Set<number> = new Set(nextFrames.map(s => s.id));
    const idsToRemove: number[] = [];
    this.controllerMap.forEach((_ctrl, key) => {
      if (!nextIds.has(key)) {
        idsToRemove.push(key);
      }
    });
    idsToRemove.forEach((key) => {
      const ctrl = this.controllerMap.get(key);
      if (ctrl) {
        ctrl.dispose();
        this.controllerMap.delete(key);
      }
      hasChange = true;
    });

    if (!hasChange) {
      return;
    }

    // Explicitly push updated state to existing controllers.
    // ForEach with stable keys skips the builder function on state updates,
    // so getOrCreateController() — which calls updateProperties() — would
    // not be called for existing annotations. We do it here instead.
    nextFrames.forEach((state) => {
      const existingCtrl = this.controllerMap.get(state.id);
      if (existingCtrl) {
        // Check if this controller was created without content (race condition:
        // addViewAnnotation's internal refreshRenderStates runs before
        // InfoWindowManager registers the ComponentContent). If so, look up
        // the content now that it should be available.
        if (!existingCtrl.hasContent()) {
          const registry = ComponentContentRegistry.getInstance();
          const content = registry.get(state.id);
          if (content) {
            existingCtrl.attachContent(content);
            console.info(`[NativeViewAnnotationOverlay] Late-attached ComponentContent for annotation ${state.id}`);
          }
        }
        existingCtrl.updateProperties(state);
      }
    });

    this.renderFrames = updatedFrames;
  }

  private numbersClose(first: number, second: number, epsilon: number): boolean {
    if (!Number.isFinite(first) || !Number.isFinite(second)) {
      return first === second;
    }
    return Math.abs(first - second) <= epsilon;
  }

  private areStatesEquivalent(previous: ViewAnnotationRenderState, next: ViewAnnotationRenderState): boolean {
    return this.numbersClose(previous.positionX, next.positionX, this.POSITION_EPSILON) &&
      this.numbersClose(previous.positionY, next.positionY, this.POSITION_EPSILON) &&
      this.numbersClose(previous.width, next.width, this.SIZE_EPSILON) &&
      this.numbersClose(previous.height, next.height, this.SIZE_EPSILON) &&
      this.numbersClose(previous.scale, next.scale, this.SCALE_EPSILON) &&
      this.numbersClose(previous.rotation, next.rotation, this.ROTATION_EPSILON) &&
      this.numbersClose(previous.opacity, next.opacity, this.OPACITY_EPSILON) &&
      previous.visible === next.visible &&
      previous.zIndex === next.zIndex;
  }

  /**
   * Get or create an AnnotationFrameNodeController for the given render state.
   *
   * On first creation, looks up the ComponentContent from the registry and
   * attaches it. On subsequent calls, updates only the position/visibility
   * properties — ComponentContent is NOT recreated.
   */
  private getOrCreateController(state: ViewAnnotationRenderState): AnnotationFrameNodeController {
    let ctrl = this.controllerMap.get(state.id);
    if (!ctrl) {
      ctrl = new AnnotationFrameNodeController(state.id);
      // Look up ComponentContent from the registry
      const registry = ComponentContentRegistry.getInstance();
      const content = registry.get(state.id);
      if (content) {
        ctrl.attachContent(content);
        console.info(`[NativeViewAnnotationOverlay] Attached ComponentContent for annotation ${state.id}`);
      } else {
        console.warn(`[NativeViewAnnotationOverlay] No ComponentContent found for annotation ${state.id}`);
      }
      this.controllerMap.set(state.id, ctrl);
    }
    ctrl.updateProperties(state);
    return ctrl;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.renderFrames, (item: ViewAnnotationRenderState) => {
        NodeContainer(this.getOrCreateController(item))
      }, (item: ViewAnnotationRenderState) => {
        // Use a stable key (annotation ID only) so ForEach reuses existing
        // NodeContainer + FrameNode. State updates flow through updateProperties()
        // on the existing controller — no need to recreate the FrameNode.
        return `view-annotation-${item.id}`;
      })
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .hitTestBehavior(HitTestMode.Transparent);
  }
}
