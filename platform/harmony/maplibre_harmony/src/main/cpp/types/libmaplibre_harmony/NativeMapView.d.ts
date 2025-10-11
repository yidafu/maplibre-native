// NativeMapView接口定义

export class NativeMapView {
    constructor();
    
    // 基础方法
    resizeView(width: number, height: number): void;
    getStyleUrl(): string;
    setStyleUrl(url: string): void;
    getStyleJson(): string;
    setStyleJson(json: string): void;
    setLatLngBounds(bounds: any): void;
    cancelTransitions(): void;
    setGestureInProgress(inProgress: boolean): void;
    
    // 相机控制
    moveBy(deltaX: number, deltaY: number, duration: number): void;
    jumpTo(longitude: number, latitude: number, zoom: number, bearing: number, pitch: number, padding: number[]): void;
    easeTo(longitude: number, latitude: number, zoom: number, duration: number, bearing: number, pitch: number, padding: number[], animated: boolean): void;
    flyTo(longitude: number, latitude: number, zoom: number, duration: number, bearing: number, pitch: number, padding: number[]): void;
    getLatLng(): any;
    setLatLng(longitude: number, latitude: number, padding: number[], duration: number): void;
    getCameraForLatLngBounds(bounds: any, top: number, left: number, bottom: number, right: number, bearing: number, tilt: number): any;
    getCameraForGeometry(geometry: any, top: number, left: number, bottom: number, right: number, bearing: number, tilt: number): any;
    resetPosition(): void;
    
    // 缩放控制
    getPitch(): number;
    setPitch(pitch: number, duration: number): void;
    setZoom(zoom: number, latitude: number, longitude: number, duration: number): void;
    getZoom(): number;
    resetZoom(): void;
    setMinZoom(zoom: number): void;
    getMinZoom(): number;
    setMaxZoom(zoom: number): void;
    getMaxZoom(): number;
    setMinPitch(pitch: number): void;
    getMinPitch(): number;
    setMaxPitch(pitch: number): void;
    getMaxPitch(): number;
    
    // 旋转控制
    rotateBy(deltaLongitude: number, deltaLatitude: number, pivotX: number, pivotY: number, duration: number): void;
    setBearing(bearing: number, duration: number): void;
    setBearingXY(centerX: number, centerY: number, angle: number, duration: number): void;
    getBearing(): number;
    resetNorth(): void;
    
    // 可见区域
    setVisibleCoordinateBounds(coordinates: any[], padding: any, zoom: number, duration: number): void;
    getVisibleCoordinateBounds(): number[];
    
    // 快照
    scheduleSnapshot(): void;
    getCameraPosition(): any;
    
    // 注解
    updateMarker(id: number, longitude: number, latitude: number, icon: string): void;
    addMarkers(markers: any[]): number[];
    addPolylines(polylines: any[]): number[];
    addPolygons(polygons: any[]): number[];
    updatePolyline(id: number, polyline: any): void;
    updatePolygon(id: number, polygon: any): void;
    removeAnnotations(ids: number[]): void;
    addAnnotationIcon(name: string, width: number, height: number, pixelRatio: number, data: Uint8Array): void;
    removeAnnotationIcon(name: string): void;
    getTopOffsetPixelsForAnnotationSymbol(name: string): number;
    
    // 样式和图层
    getTransitionOptions(): any;
    setTransitionOptions(options: any): void;
    getLayers(): any[];
    getLayer(id: string): any;
    addLayer(layerPtr: number, beforeId: string): void;
    addLayerAbove(layerPtr: number, aboveLayerId: string): void;
    addLayerAt(layerPtr: number, index: number): void;
    removeLayerAt(index: number): boolean;
    removeLayer(layerPtr: number): boolean;
    
    // 数据源
    getSources(): any[];
    getSource(id: string): any;
    addSource(source: any, nativePtr: number): void;
    removeSource(source: any, nativePtr: number): boolean;
    
    // 图片
    addImage(name: string, bitmap: any, pixelRatio: number, sdf: boolean): void;
    addImages(images: any[]): void;
    removeImage(name: string): void;
    getImage(name: string): any;
    
    // 缓存和预加载
    setPrefetchTiles(enabled: boolean): void;
    getPrefetchTiles(): boolean;
    setPrefetchZoomDelta(delta: number): void;
    getPrefetchZoomDelta(): number;
    setTileCacheEnabled(enabled: boolean): void;
    getTileCacheEnabled(): boolean;
    
    // 图层细节级别
    setTileLodMinRadius(radius: number): void;
    getTileLodMinRadius(): number;
    setTileLodScale(scale: number): void;
    getTileLodScale(): number;
    setTileLodPitchThreshold(threshold: number): void;
    getTileLodPitchThreshold(): number;
    setTileLodZoomShift(shift: number): void;
    getTileLodZoomShift(): number;
    
    // 光照
    getLight(): any;
    
    // 渲染控制
    triggerRepaint(): void;
    setReachability(reachable: boolean): void;
    onLowMemory(): void;
    setDebug(debug: boolean): void;
    getDebug(): boolean;
    
    // 调试
    getActionJournalLogFiles(): string[];
    getActionJournalLog(): string[];
    clearActionJournalLog(): void;
    isFullyLoaded(): boolean;
    
    // 工具方法
    getMetersPerPixelAtLatitude(latitude: number, zoom: number): number;
    projectedMetersForLatLng(latitude: number, longitude: number): any;
    pixelForLatLng(latitude: number, longitude: number): any;
    pixelsForLatLngs(coordinates: number[], pixels: number[], scale: number): void;
    latLngForProjectedMeters(easting: number, northing: number): any;
    latLngForPixel(x: number, y: number): any;
    latLngsForPixels(pixels: number[], coordinates: number[], scale: number): void;
    
    // 特性查询
    queryPointAnnotations(rect: any): number[];
    queryShapeAnnotations(rect: any): number[];
    queryRenderedFeaturesForPoint(x: number, y: number, layerIds: string[], filter: any[]): any[];
    queryRenderedFeaturesForBox(north: number, east: number, south: number, west: number, layerIds: string[], filter: any[]): any[];
    
    // 渲染统计
    isRenderingStatsViewEnabled(): boolean;
    enableRenderingStatsView(enabled: boolean): void;
}

// 原有接口定义

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