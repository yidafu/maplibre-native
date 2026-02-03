import { InfoWindow, InfoWindowRenderContext } from './InfoWindow';
import { Marker } from './Marker';


export class ViewAnnotationBuilderContext {
  annotationId: number = -1;
  viewName: string = '';
}

export class InfoWindowBuilderContext extends ViewAnnotationBuilderContext {
  markerId: number = -1;
  title: string = '';
  content: string = '';
  notifySizeChanged?: (width: number, height: number) => void;
  builderContext: InfoWindowRenderContext
  marker: Marker
  infoWindow: InfoWindow;
  constructor(infoWindow: InfoWindow, builderContent: InfoWindowRenderContext) {
    super();
    this.infoWindow = infoWindow
    this.marker = infoWindow.getMarker();
    this.markerId = this.marker.getId();
    this.title = this.marker.getTitle() || '';
    this.content = this.marker.getSnippet() || '';
    this.builderContext = builderContent;
  }
}

export type ViewAnnotationRenderCallback = () => void;

export type ViewAnnotationWrappedBuilder<T extends ViewAnnotationBuilderContext = ViewAnnotationBuilderContext> = WrappedBuilder<[T]>;
export type InfoWindowWrappedBuilder = ViewAnnotationWrappedBuilder<InfoWindowBuilderContext>;

@Builder
export function ViewAnnotationPayloadBuilder(ctx: ViewAnnotationBuilderContext): void {

}

export const DEFAULT_VIEW_ANNOTATION_WRAPPED_BUILDER: ViewAnnotationWrappedBuilder =
  wrapBuilder<[ViewAnnotationBuilderContext]>(ViewAnnotationPayloadBuilder);

export const DEFAULT_VIEW_ANNOTATION_VIEW_NAME: string = 'maplibre_view_annotation';
export const INFO_WINDOW_VIEW_NAME: string = 'maplibre_info_window';
