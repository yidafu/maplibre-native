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
  /**
   * True when the annotation declares a fixed size (width/height options) and
   * the FrameNode should constrain its content to it. False in auto-size mode:
   * the content hugs its own size and the measured bounds are fed back to the
   * positioning engine instead.
   */
  applySize: boolean;
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
  applySize: boolean;
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
    this.applySize = params.applySize;
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
 * ComponentContent for each annotation is resolved through the per-map
 * ComponentContentRegistry (owned by that map's ViewAnnotationManager and
 * populated by its InfoWindowManager).
 *
 * FrameNodes are reused across re-renders — only position/visibility
 * properties are updated, without recreating ComponentContent.
 */
@Component
export struct NativeViewAnnotationOverlay {
  @Link @Watch('onFramesChanged') frames: ViewAnnotationRenderState[];
  @State private renderFrames: ViewAnnotationRenderState[] = [];
  private controllerMap: Map<number, AnnotationFrameNodeController> = new Map();
  // Resolved lazily so the overlay works even when the host map initializes
  // after the overlay is first built. Non-private: initialized through the
  // component constructor from NativeMapView.
  contentRegistryProvider: (() => ComponentContentRegistry | null) | null = null;
  /**
   * Receives measured content sizes (logical px) for auto-size annotations.
   * Wired to ViewAnnotationManager.handleMeasuredSize by NativeMapView.
   */
  onContentSize?: (id: number, width: number, height: number) => void;
  // Local dedup so unchanged measurements are not pushed every frame.
  private lastMeasuredSizes: Map<number, number[]> = new Map();
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
    this.lastMeasuredSizes.clear();
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
        applySize: state.applySize,
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
      this.lastMeasuredSizes.delete(key);
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
        this.attachContentIfChanged(existingCtrl, state.id);
        existingCtrl.updateProperties(state);
      }
    });

    this.renderFrames = updatedFrames;
  }

  /**
   * Attach the ComponentContent registered for the annotation when it differs
   * from what the controller currently renders. Covers both the race where a
   * controller is created before InfoWindowManager registers the content and
   * content replacement (e.g. a new adapter result on re-show).
   */
  private attachContentIfChanged(ctrl: AnnotationFrameNodeController, annotationId: number): void {
    const registry = this.contentRegistryProvider ? this.contentRegistryProvider() : null;
    if (!registry) {
      return;
    }
    const content = registry.get(annotationId);
    if (content && ctrl.getContent() !== content) {
      ctrl.attachContent(content);
    }
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
      this.controllerMap.set(state.id, ctrl);
    }
    this.attachContentIfChanged(ctrl, state.id);
    ctrl.updateProperties(state);
    return ctrl;
  }

  /**
   * Forwards a measured content size to the positioning engine. Deduped per
   * annotation so unchanged bounds are not pushed on every frame.
   */
  private reportMeasuredSize(id: number, width: number, height: number): void {
    if (!(width > 0) || !(height > 0)) {
      return;
    }
    if (!this.onContentSize) {
      return;
    }
    const previous = this.lastMeasuredSizes.get(id);
    if (previous &&
      Math.abs(previous[0] - width) <= this.SIZE_EPSILON &&
      Math.abs(previous[1] - height) <= this.SIZE_EPSILON) {
      return;
    }
    this.lastMeasuredSizes.set(id, [width, height]);
    this.onContentSize(id, width, height);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.renderFrames, (item: ViewAnnotationRenderState) => {
        Column() {
          NodeContainer(this.getOrCreateController(item))
        }
        .onAreaChange((_oldArea: Area, newArea: Area) => {
          this.reportMeasuredSize(item.id, Number(newArea.width), Number(newArea.height));
        })
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
