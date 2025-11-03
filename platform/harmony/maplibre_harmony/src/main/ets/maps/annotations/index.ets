/**
 * Annotations 模块导出
 *
 * 提供地图标注相关的所有类和接口
 */

// 基础类
export { Annotation } from './Annotation';

export { AnnotationType } from './AnnotationType';

// Icon 相关
// Icon 封装类，不再直接暴露 NAPI Icon
export { Icon } from './Icon';

export { IconFactory } from './IconFactory';

export { IconManager } from './IconManager';

// Marker 相关
// Marker 封装类，不再直接暴露 NAPI Marker
export { Marker } from './Marker';

export { MarkerOptions } from './MarkerOptions';

export { MarkerDragState } from './MarkerDragState';

export { MarkerManager } from './MarkerManager';

// InfoWindow 相关
export { InfoWindow, InfoWindowComponent } from './InfoWindow';

export { InfoWindowAdapter } from './InfoWindowAdapter';

export { InfoWindowManager } from './InfoWindowManager';

// AnnotationView 相关
export { AnnotationView } from './AnnotationView';

export { AnnotationViewAdapter } from './AnnotationViewAdapter';

export { AnnotationViewManager, AnnotationViewData } from './AnnotationViewManager';

// 其他标注类型
export { Polyline } from './Polyline';

export { Polygon } from './Polygon';

export { PolygonManager } from './PolygonManager';

export { PolylineManager } from './PolylineManager';


