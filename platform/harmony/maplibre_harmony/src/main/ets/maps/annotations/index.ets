/**
 * Annotations module exports
 *
 * Re-exports all classes and interfaces related to map annotations
 */

// Core annotation classes
export { Annotation } from './Annotation';

export { AnnotationType } from './AnnotationType';

// Icon utilities
// Wrapper around Icon to avoid exposing the raw NAPI object
export { Icon } from './Icon';

export { IconFactory } from './IconFactory';

export { IconManager } from './IconManager';

// Marker utilities
// Wrapper around Marker to avoid exposing the raw NAPI object
export { Marker } from './Marker';

export { MarkerOptions } from './MarkerOptions';

export { MarkerDragState } from './MarkerDragState';

export { MarkerManager } from './MarkerManager';

// InfoWindow utilities
export { InfoWindow, InfoWindowComponent } from './InfoWindow';

export type { InfoWindowStyle, InfoWindowRenderParams } from './InfoWindow';

export { InfoWindowAdapter } from './InfoWindowAdapter';

export { InfoWindowManager } from './InfoWindowManager';

// AnnotationView utilities
// @deprecated Marker custom views are being converged into marker-anchored
// ViewAnnotations; prefer ViewAnnotationManager for floating layers.
export { AnnotationView } from './AnnotationView';

export { AnnotationViewAdapter } from './AnnotationViewAdapter';

export { AnnotationViewManager, AnnotationViewData } from './AnnotationViewManager';

export { ViewAnnotationHandle } from './ViewAnnotationHandle';

export {
  ViewAnnotationManager,
  ViewAnnotationAddOptions,
  ViewAnnotationUpdateOptions
} from './ViewAnnotationManager';

export {
  ViewAnnotationBuilderContext,
  InfoWindowBuilderContext,
  INFO_WINDOW_VIEW_NAME
} from './ViewAnnotationTypes';

// Additional annotation types
export { Polyline } from './Polyline';

export { Polygon } from './Polygon';

export { PolygonManager } from './PolygonManager';

export { PolylineManager } from './PolylineManager';


