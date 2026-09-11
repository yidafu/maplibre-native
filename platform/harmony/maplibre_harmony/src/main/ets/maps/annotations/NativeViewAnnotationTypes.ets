export interface NativeViewAnnotationAnchor {
  latitude: number;
  longitude: number;
}

export class NativeViewAnnotationAnchorImpl implements NativeViewAnnotationAnchor {
  latitude: number;
  longitude: number;

  constructor(latitude: number = 0, longitude: number = 0) {
    this.latitude = latitude;
    this.longitude = longitude;
  }
}

export interface NativeViewAnnotationCenterOffset {
  dx: number;
  dy: number;
}

export class NativeViewAnnotationCenterOffsetImpl implements NativeViewAnnotationCenterOffset {
  dx: number;
  dy: number;

  constructor(dx: number = 0, dy: number = 0) {
    this.dx = dx;
    this.dy = dy;
  }
}

export interface NativeViewAnnotationOptions {
  // Optional: add options always provide it; partial update payloads omit it
  // so the native layer keeps the previously stored anchor.
  anchor?: NativeViewAnnotationAnchor;
  width?: number;
  height?: number;
  anchorHeight?: number;
  centerOffset?: NativeViewAnnotationCenterOffset;
  visible?: boolean;
  allowOverlap?: boolean;
  draggable?: boolean;
  scalesWithViewingDistance?: boolean;
  rotatesWithCamera?: boolean;
  minZoom?: number;
  maxZoom?: number;
}

export class NativeViewAnnotationOptionsImpl implements NativeViewAnnotationOptions {
  anchor?: NativeViewAnnotationAnchor;
  width?: number;
  height?: number;
  anchorHeight?: number;
  centerOffset?: NativeViewAnnotationCenterOffset;
  visible?: boolean;
  allowOverlap?: boolean;
  draggable?: boolean;
  scalesWithViewingDistance?: boolean;
  rotatesWithCamera?: boolean;
  minZoom?: number;
  maxZoom?: number;

  constructor(anchor?: NativeViewAnnotationAnchor) {
    if (anchor) {
      this.anchor = anchor;
    }
  }
}

export interface NativeViewAnnotationFrame {
  id: number;
  x: number;
  y: number;
  width: number;
  height: number;
  offsetX: number;
  offsetY: number;
  scale: number;
  rotation: number;
  opacity: number;
  pixelRatio: number;
  positionX: number;  // Pre-computed by C++: final render X in logical pixels
  positionY: number;  // Pre-computed by C++: final render Y in logical pixels
  visible: boolean;
  draggable: boolean;
}

export class NativeViewAnnotationFrameImpl implements NativeViewAnnotationFrame {
  id: number = 0;
  x: number = 0;
  y: number = 0;
  width: number = 0;
  height: number = 0;
  offsetX: number = 0;
  offsetY: number = 0;
  scale: number = 1;
  rotation: number = 0;
  opacity: number = 1;
  pixelRatio: number = 1;
  positionX: number = 0;  // Pre-computed by C++
  positionY: number = 0;  // Pre-computed by C++
  visible: boolean = true;
  draggable: boolean = false;
}

