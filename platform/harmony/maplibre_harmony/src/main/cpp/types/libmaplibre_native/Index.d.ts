
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

// RasterDemSource 类型定义
export namespace RasterDemSource {
  export function createWithUrl(id: string, url: string, encoding: string): number;
  export function createWithTileSet(id: string, tileSetJson: string, encoding: string): number;
}

// ImageSource 类型定义
export namespace ImageSource {
  export function create(id: string, coordinates: string, imageData: Uint8Array | null): number;
  export function setUrl(sourcePtr: number, url: string): void;
  export function setImage(sourcePtr: number, imageData: Uint8Array): void;
  export function setCoordinates(sourcePtr: number, coordinates: string): void;
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

// SymbolLayer 类型定义
export namespace SymbolLayer {
  export function create(layerId: string, sourceId: string): number;
  export function setIconImage(layerPtr: number, iconImage: string): void;
  export function setIconSize(layerPtr: number, size: number): void;
  export function setIconRotate(layerPtr: number, rotate: number): void;
  export function setIconOpacity(layerPtr: number, opacity: number): void;
  export function setIconColor(layerPtr: number, color: string): void;
  export function setTextField(layerPtr: number, textField: string): void;
  export function setTextSize(layerPtr: number, size: number): void;
  export function setTextColor(layerPtr: number, color: string): void;
  export function setTextHaloColor(layerPtr: number, color: string): void;
  export function setTextHaloWidth(layerPtr: number, width: number): void;
  export function setTextOpacity(layerPtr: number, opacity: number): void;
  export function setTextAnchor(layerPtr: number, anchor: string): void;
  export function setTextOffset(layerPtr: number, offset: number[]): void;
  export function setTextFont(layerPtr: number, font: string[]): void;
}

// RasterLayer 类型定义
export namespace RasterLayer {
  export function create(layerId: string, sourceId: string): number;
  export function setRasterOpacity(layerPtr: number, opacity: number): void;
  export function setRasterHueRotate(layerPtr: number, hueRotate: number): void;
  export function setRasterBrightnessMin(layerPtr: number, brightnessMin: number): void;
  export function setRasterBrightnessMax(layerPtr: number, brightnessMax: number): void;
  export function setRasterSaturation(layerPtr: number, saturation: number): void;
  export function setRasterContrast(layerPtr: number, contrast: number): void;
  export function setRasterFadeDuration(layerPtr: number, fadeDuration: number): void;
  export function setRasterResampling(layerPtr: number, resampling: string): void;
}

// BackgroundLayer 类型定义
export namespace BackgroundLayer {
  export function create(layerId: string): number;
  export function setBackgroundColor(layerPtr: number, color: string): void;
  export function setBackgroundOpacity(layerPtr: number, opacity: number): void;
  export function setBackgroundPattern(layerPtr: number, pattern: string): void;
}

// HeatmapLayer 类型定义
export namespace HeatmapLayer {
  export function create(layerId: string, sourceId: string): number;
  export function setHeatmapRadius(layerPtr: number, radius: number): void;
  export function setHeatmapWeight(layerPtr: number, weight: number): void;
  export function setHeatmapIntensity(layerPtr: number, intensity: number): void;
  export function setHeatmapColor(layerPtr: number, color: string): void;
  export function setHeatmapOpacity(layerPtr: number, opacity: number): void;
}

// HillshadeLayer 类型定义
export namespace HillshadeLayer {
  export function create(layerId: string, sourceId: string): number;
  export function setHillshadeIlluminationDirection(layerPtr: number, direction: number): void;
  export function setHillshadeIlluminationAnchor(layerPtr: number, anchor: string): void;
  export function setHillshadeExaggeration(layerPtr: number, exaggeration: number): void;
  export function setHillshadeShadowColor(layerPtr: number, color: string): void;
  export function setHillshadeHighlightColor(layerPtr: number, color: string): void;
  export function setHillshadeAccentColor(layerPtr: number, color: string): void;
}

// FillExtrusionLayer 类型定义
export namespace FillExtrusionLayer {
  export function create(layerId: string, sourceId: string): number;
  export function setFillExtrusionOpacity(layerPtr: number, opacity: number): void;
  export function setFillExtrusionColor(layerPtr: number, color: string): void;
  export function setFillExtrusionTranslate(layerPtr: number, translate: number[]): void;
  export function setFillExtrusionPattern(layerPtr: number, pattern: string): void;
  export function setFillExtrusionHeight(layerPtr: number, height: number): void;
  export function setFillExtrusionBase(layerPtr: number, base: number): void;
  export function setFillExtrusionVerticalGradient(layerPtr: number, verticalGradient: boolean): void;
}

export * from './NativeMapView'