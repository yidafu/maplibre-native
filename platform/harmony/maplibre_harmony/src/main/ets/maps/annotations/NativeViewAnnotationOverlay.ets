import type { ViewAnnotationWrappedBuilder } from './ViewAnnotationTypes';
import { ViewAnnotationBuilderContext, INFO_WINDOW_VIEW_NAME } from './ViewAnnotationTypes';
import {
  POSITION_EPSILON,
  SIZE_EPSILON,
  SCALE_EPSILON,
  ROTATION_EPSILON,
  OPACITY_EPSILON,
  toLength,
  clampOpacity,
  sanitizeScale,
  sanitizeRotation,
  numbersClose
} from './ViewAnnotationUtils';

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
  wrappedBuilder: ViewAnnotationWrappedBuilder;
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
  wrappedBuilder: ViewAnnotationWrappedBuilder;
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
    this.wrappedBuilder = params.wrappedBuilder;
    this.viewName = params.viewName;
    this.zIndex = params.zIndex;
  }
}

@Component
struct ViewAnnotationContentHost {
  @BuilderParam builder: () => void;

  build() {
    this.builder();
  }
}

@Builder
function renderAnnotationContent(wrappedBuilder: ViewAnnotationWrappedBuilder, ctx: ViewAnnotationBuilderContext) {
  wrappedBuilder.builder(ctx);
}

@Component
export struct NativeViewAnnotationOverlay {
  @Link @Watch('onFramesChanged') frames: ViewAnnotationRenderState[];
  @State private renderFrames: ViewAnnotationRenderState[] = [];
  @State private frameVersionById: Map<number, number> = new Map<number, number>();

  aboutToAppear(): void {
    this.syncRenderFrames(this.frames);
  }

  private onFramesChanged(): void {
    this.syncRenderFrames(this.frames);
  }

  private syncRenderFrames(source: ViewAnnotationRenderState[] | undefined): void {
    const nextFrames: ViewAnnotationRenderState[] = (source ?? []).map((state) => new ViewAnnotationRenderState({
      id: state.id,
      positionX: state.positionX,
      positionY: state.positionY,
      width: state.width,
      height: state.height,
      scale: state.scale,
      rotation: state.rotation,
      opacity: state.opacity,
      visible: state.visible,
      wrappedBuilder: state.wrappedBuilder,
      viewName: state.viewName,
      zIndex: state.zIndex
    }));
    const previousById: Map<number, ViewAnnotationRenderState> = new Map<number, ViewAnnotationRenderState>();
    this.renderFrames.forEach((state) => {
      previousById.set(state.id, state);
    });

    const updatedVersionMap: Map<number, number> = new Map<number, number>();
    this.frameVersionById.forEach((value, key) => {
      updatedVersionMap.set(key, value);
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
      let currentVersion = updatedVersionMap.get(state.id);
      if (currentVersion === undefined) {
        currentVersion = 0;
      }
      updatedVersionMap.set(state.id, currentVersion + 1);
      updatedFrames.push(state);
    });

    if (updatedVersionMap.size > updatedFrames.length) {
      const validIds: Set<number> = new Set<number>();
      updatedFrames.forEach((state) => {
        validIds.add(state.id);
      });

      const idsToRemove: number[] = [];
      updatedVersionMap.forEach((_value, key) => {
        if (!validIds.has(key)) {
          idsToRemove.push(key);
        }
      });

      idsToRemove.forEach((key) => {
        updatedVersionMap.delete(key);
        hasChange = true;
      });
    }

    if (!hasChange) {
      return;
    }

    this.renderFrames = updatedFrames;
    this.frameVersionById = updatedVersionMap;
  }

  private areStatesEquivalent(previous: ViewAnnotationRenderState, next: ViewAnnotationRenderState): boolean {
    return numbersClose(previous.positionX, next.positionX, POSITION_EPSILON) &&
      numbersClose(previous.positionY, next.positionY, POSITION_EPSILON) &&
      numbersClose(previous.width, next.width, SIZE_EPSILON) &&
      numbersClose(previous.height, next.height, SIZE_EPSILON) &&
      numbersClose(previous.scale, next.scale, SCALE_EPSILON) &&
      numbersClose(previous.rotation, next.rotation, ROTATION_EPSILON) &&
      numbersClose(previous.opacity, next.opacity, OPACITY_EPSILON) &&
      previous.visible === next.visible &&
      previous.wrappedBuilder === next.wrappedBuilder &&
      previous.zIndex === next.zIndex;
  }

  private createBuilderContext(state: ViewAnnotationRenderState): ViewAnnotationBuilderContext {
    let ctx: ViewAnnotationBuilderContext;
    if (state.viewName === INFO_WINDOW_VIEW_NAME) {
      // Create a basic ViewAnnotationBuilderContext for InfoWindows
      // The actual InfoWindowBuilderContext will be created by the InfoWindowManager
      ctx = new ViewAnnotationBuilderContext();
    } else {
      ctx = new ViewAnnotationBuilderContext();
    }
    ctx.annotationId = state.id;
    ctx.viewName = state.viewName;
    return ctx;
  }

  @Builder
  private renderAnnotationItem(item: ViewAnnotationRenderState): void {
    if (item.visible) {
      Column() {
        renderAnnotationContent(item.wrappedBuilder, this.createBuilderContext(item));
      }
      .width(item.width > 0 ? toLength(item.width) : 'auto')
      .height(item.height > 0 ? toLength(item.height) : 'auto')
      .position({ x: toLength(item.positionX), y: toLength(item.positionY) })
      .opacity(clampOpacity(item.opacity))
      .scale({
        x: sanitizeScale(item.scale),
        y: sanitizeScale(item.scale),
        centerX: '50%',
        centerY: '100%'
      })
      .rotate({
        angle: sanitizeRotation(item.rotation),
        centerX: '50%',
        centerY: '100%'
      })
      .zIndex(item.zIndex ?? 0)
      .hitTestBehavior(HitTestMode.Transparent);
    }
  }

  build(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.renderFrames, (item: ViewAnnotationRenderState) => {
        this.renderAnnotationItem(item);
      }, (item: ViewAnnotationRenderState) => {
        let version = this.frameVersionById.get(item.id);
        if (version === undefined) {
          version = 0;
        }
        return `view-annotation-${item.id}-v${version}`;
      });
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .hitTestBehavior(HitTestMode.Transparent);
  }
}

