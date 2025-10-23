
export type XComponentContextStatus = {
  hasDraw: boolean,
  hasChangeColor: boolean,
};

export const SetSurfaceId: (id: BigInt) => any;
export const ChangeSurface: (id: BigInt, w: number, h: number) => any;
export const DrawPattern: (id: BigInt) => any;
export const GetXComponentStatus: (id: BigInt) => XComponentContextStatus;
export const ChangeColor: (id: BigInt) => any;
export const DestroySurface: (id: BigInt) => any;

export const add: (a: number, b: number) => number;

// Style API 类型定义
export namespace Style {
  export function getStyleUri(mapPtr: number): string;
  export function getStyleJson(mapPtr: number): string;
  export function addSource(mapPtr: number, sourceId: string, sourceJson: string, sourceNativePtr: number): boolean;
  export function removeSource(mapPtr: number, sourceId: string): boolean;
  export function getSource(mapPtr: number, sourceId: string): string | null;
  export function getSources(mapPtr: number): string;
  export function addLayer(mapPtr: number, layerId: string, layerJson: string, layerNativePtr: number): boolean;
  export function addLayerBelow(mapPtr: number, layerId: string, layerJson: string, layerNativePtr: number, belowLayerId: string): boolean;
  export function addLayerAbove(mapPtr: number, layerId: string, layerJson: string, layerNativePtr: number, aboveLayerId: string): boolean;
  export function addLayerAt(mapPtr: number, layerId: string, layerJson: string, layerNativePtr: number, index: number): boolean;
  export function removeLayer(mapPtr: number, layerId: string): boolean;
  export function removeLayerAt(mapPtr: number, index: number): boolean;
  export function getLayer(mapPtr: number, layerId: string): string | null;
  export function getLayers(mapPtr: number): string;
  export function addImage(mapPtr: number, name: string, imageData: any, width: number, height: number, sdf: boolean): boolean;
  export function removeImage(mapPtr: number, name: string): boolean;
  export function getImage(mapPtr: number, name: string): any | null;
  export function getLight(mapPtr: number): string | null;
  export function setLight(mapPtr: number, lightJson: string): boolean;
  export function getTransition(mapPtr: number): string | null;
  export function setTransition(mapPtr: number, transitionJson: string): boolean;
}

// GeoJsonSource 类型定义
export namespace GeoJsonSource {
  export function create(id: string, optionsJson: string | null): number;
  export function setGeoJson(sourcePtr: number, geoJsonString: string): void;
  export function setGeoJsonSync(sourcePtr: number, geoJsonString: string): void;
  export function setUrl(sourcePtr: number, url: string): void;
  export function getUrl(sourcePtr: number): string;
  export function querySourceFeatures(sourcePtr: number, filterJson: string | null): string;
  export function getClusterChildren(sourcePtr: number, clusterJson: string): string;
  export function getClusterLeaves(sourcePtr: number, clusterJson: string, limit: number, offset: number): string;
  export function getClusterExpansionZoom(sourcePtr: number, clusterJson: string): number;
}

// VectorSource 类型定义
export namespace VectorSource {
  export function createWithUrl(id: string, url: string): number;
  export function createWithTileSet(id: string, tileSetJson: string): number;
  export function querySourceFeatures(sourcePtr: number, sourceLayerId: string, filterJson: string | null): string;
}

// RasterSource 类型定义
export namespace RasterSource {
  export function createWithUrl(id: string, url: string, tileSize: number): number;
  export function createWithTileSet(id: string, tileSetJson: string, tileSize: number): number;
}

// FillLayer 类型定义
export namespace FillLayer {
  export function create(layerId: string, sourceId: string): number;
  export function setFillColor(layerPtr: number, color: string): void;
  export function setFillOpacity(layerPtr: number, opacity: number): void;
  export function setFillOutlineColor(layerPtr: number, color: string): void;
  export function setFillPattern(layerPtr: number, pattern: string): void;
  export function setFillAntialias(layerPtr: number, antialias: boolean): void;
  export function setFillTranslate(layerPtr: number, translate: number[]): void;
}

// LineLayer 类型定义
export namespace LineLayer {
  export function create(layerId: string, sourceId: string): number;
  export function setLineColor(layerPtr: number, color: string): void;
  export function setLineWidth(layerPtr: number, width: number): void;
  export function setLineOpacity(layerPtr: number, opacity: number): void;
  export function setLinePattern(layerPtr: number, pattern: string): void;
  export function setLineGapWidth(layerPtr: number, gapWidth: number): void;
  export function setLineDasharray(layerPtr: number, dasharray: number[]): void;
  export function setLineBlur(layerPtr: number, blur: number): void;
  export function setLineCap(layerPtr: number, cap: string): void;
  export function setLineJoin(layerPtr: number, join: string): void;
}

// CircleLayer 类型定义
export namespace CircleLayer {
  export function create(layerId: string, sourceId: string): number;
  export function setCircleRadius(layerPtr: number, radius: number): void;
  export function setCircleColor(layerPtr: number, color: string): void;
  export function setCircleOpacity(layerPtr: number, opacity: number): void;
  export function setCircleBlur(layerPtr: number, blur: number): void;
  export function setCircleStrokeWidth(layerPtr: number, width: number): void;
  export function setCircleStrokeColor(layerPtr: number, color: string): void;
  export function setCircleStrokeOpacity(layerPtr: number, opacity: number): void;
}

export * from './NativeMapView'