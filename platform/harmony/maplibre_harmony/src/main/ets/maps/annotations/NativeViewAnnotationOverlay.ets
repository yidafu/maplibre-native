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
  builder: () => void;
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
  builder: () => void;
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
    this.builder = params.builder;
    this.zIndex = params.zIndex;
  }
}

@Builder
function renderAnnotationContent(builder: () => void): void {
  builder();
}

@Component
export struct NativeViewAnnotationOverlay {
  @Link @Watch('onFramesChanged') frames: ViewAnnotationRenderState[];

  private onFramesChanged(): void {
    console.info(`[NativeViewAnnotationOverlay] frames changed, count: ${this.frames?.length ?? 0}`);
  }

  private clampOpacity(value: number): number {
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

  private sanitizeRotation(value: number): number {
    if (!Number.isFinite(value)) {
      return 0;
    }
    return value;
  }

  build(): void {
    Stack() {
      ForEach(this.frames ?? [], (item: ViewAnnotationRenderState) => {
        if (!item.visible) {
          Blank()
            .hitTestBehavior(HitTestMode.None);
        } else {
          Stack() {
            renderAnnotationContent(item.builder);
          }
          .width(item.width > 0 ? item.width : 'auto')
          .height(item.height > 0 ? item.height : 'auto')
          .position({ x: item.positionX, y: item.positionY })
          .opacity(this.clampOpacity(item.opacity))
          .scale({
            x: this.sanitizeScale(item.scale),
            y: this.sanitizeScale(item.scale),
            centerX: '50%',
            centerY: '100%'
          })
          .rotate({
            angle: this.sanitizeRotation(item.rotation),
            centerX: '50%',
            centerY: '100%'
          })
          .zIndex(item.zIndex ?? 0)
          .hitTestBehavior(HitTestMode.Transparent);
        }
      }, (item: ViewAnnotationRenderState) => `view-annotation-${item.id}`);
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent);
  }
}

