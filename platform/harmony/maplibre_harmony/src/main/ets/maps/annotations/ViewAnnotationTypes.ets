import { InfoWindow, InfoWindowRenderContext } from './InfoWindow';
import { Marker } from './Marker';

/**
 * ViewAnnotationBuilderContext - Base context class passed to ViewAnnotation builders.
 * Extended by InfoWindowBuilderContext for InfoWindow-specific rendering.
 */
export class ViewAnnotationBuilderContext {
  annotationId: number = -1;
  viewName: string = '';
}

/**
 * InfoWindowBuilderContext provides marker data to InfoWindow rendering.
 *
 * Used by default InfoWindow rendering and as a base for custom builder-based
 * adapters. When using ComponentContent adapters, the builder context can be
 * embedded inside the ComponentContent.update() callback.
 */
export class InfoWindowBuilderContext extends ViewAnnotationBuilderContext {
  markerId: number = -1;
  title: string = '';
  content: string = '';
  notifySizeChanged?: (width: number, height: number) => void;
  builderContext: InfoWindowRenderContext;
  marker: Marker;
  infoWindow: InfoWindow;

  constructor(infoWindow: InfoWindow, builderContent: InfoWindowRenderContext) {
    super();
    this.infoWindow = infoWindow;
    this.marker = infoWindow.getMarker();
    this.markerId = this.marker.getId();
    this.title = this.marker.getTitle() || '';
    this.content = this.marker.getSnippet() || '';
    this.builderContext = builderContent;
  }
}

/**
 * View name constants used to distinguish annotation types in the overlay.
 */
export const INFO_WINDOW_VIEW_NAME: string = 'maplibre_info_window';
