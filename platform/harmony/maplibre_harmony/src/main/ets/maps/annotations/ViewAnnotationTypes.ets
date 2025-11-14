export class ViewAnnotationBuilderContext {
  annotationId: number = -1;
  viewName: string = '';
}

export class InfoWindowBuilderContext extends ViewAnnotationBuilderContext {
  markerId: number = -1;
  title: string = '';
  content: string = '';
  notifySizeChanged?: (width: number, height: number) => void;

  constructor() {
    super();
  }
}

export type ViewAnnotationRenderCallback = () => void;

export type ViewAnnotationWrappedBuilder = WrappedBuilder<[ViewAnnotationBuilderContext]>;
export type InfoWindowWrappedBuilder = WrappedBuilder<[InfoWindowBuilderContext]>;


@Builder
export function ViewAnnotationPayloadBuilder(ctx: ViewAnnotationBuilderContext): void {

}

export const DEFAULT_VIEW_ANNOTATION_WRAPPED_BUILDER: ViewAnnotationWrappedBuilder =
  wrapBuilder<[ViewAnnotationBuilderContext]>(ViewAnnotationPayloadBuilder);

export const DEFAULT_VIEW_ANNOTATION_VIEW_NAME: string = 'maplibre_view_annotation';
export const INFO_WINDOW_VIEW_NAME: string = 'maplibre_info_window';
