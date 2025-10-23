// NativeMapView class
export class NativeMapView {
    constructor();

    // View management
    resizeView(width: number, height: number): void;
    setNativeWindow(surfaceId: BigInt): void;

    // Style management
    getStyleUrl(): string;
    setStyleUrl(url: string): void;
    getStyleJson(): string;
    setStyleJson(json: string): void;
    setLatLngBounds(bounds: any): void;

    // Camera control
    cancelTransitions(): void;
    setGestureInProgress(inProgress: boolean): void;
    moveBy(dx: number, dy: number, duration: number): void;
    jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number, padding?: number[]): void;
    easeTo(angle: number, latitude: number, longitude: number, duration: number, pitch: number, zoom: number, padding?: number[], easingInterpolator?: boolean): void;
    flyTo(angle: number, latitude: number, longitude: number, duration: number, pitch: number, zoom: number, padding?: number[]): void;

    // Position and camera
    getLatLng(): { latitude: number; longitude: number };
    setLatLng(latitude: number, longitude: number, padding?: number[], duration?: number): void;
    getCameraForLatLngBounds(bounds: any, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): any;
    getCameraForGeometry(geometry: any, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): any;
    setReachability(status: boolean): void;
    resetPosition(): void;

    // Pitch control
    getPitch(): number;
    setPitch(pitch: number, duration?: number): void;

    // Zoom control
    setZoom(zoom: number, cx?: number, cy?: number, duration?: number): void;
    getZoom(): number;
    resetZoom(): void;
    setMinZoom(zoom: number): void;
    getMinZoom(): number;
    setMaxZoom(zoom: number): void;
    getMaxZoom(): number;

    // Pitch limits
    setMinPitch(pitch: number): void;
    getMinPitch(): number;
    setMaxPitch(pitch: number): void;
    getMaxPitch(): number;

    // Rotation
    rotateBy(sx: number, sy: number, ex: number, ey: number, duration?: number): void;

    // Bearing control
    setBearing(degrees: number, duration?: number): void;
    setBearingXY(degrees: number, fx: number, fy: number, duration?: number): void;
    getBearing(): number;
    resetNorth(): void;

    // Coordinate bounds
    setVisibleCoordinateBounds(coordinates: any[], padding: any, direction: number, duration: number): void;
    getVisibleCoordinateBounds(): any[];

    // Snapshot
    scheduleSnapshot(): void;

    // Camera position
    getCameraPosition(): any;

    // Annotations
    updateMarker(markerId: number, lat: number, lon: number, iconId: string): void;
    addMarkers(markers: any[]): number[];
    addPolylines(polylines: any[]): number[];
    addPolygons(polygons: any[]): number[];
    updatePolyline(polylineId: number, polyline: any): void;
    updatePolygon(polygonId: number, polygon: any): void;
    removeAnnotations(ids: number[]): void;
    addAnnotationIcon(symbol: string, width: number, height: number, scale: number, pixels: Uint8Array): void;
    removeAnnotationIcon(symbol: string): void;
    getTopOffsetPixelsForAnnotationSymbol(symbolName: string): number;

    // Memory management
    onLowMemory(): void;

    // Debug
    setDebug(debug: boolean): void;
    getDebug(): boolean;

    // Action journal
    getActionJournalLogFiles(): string[];
    getActionJournalLog(): string[];
    clearActionJournalLog(): void;

    // Loading status
    isFullyLoaded(): boolean;

    // Coordinate conversion
    getMetersPerPixelAtLatitude(latitude: number, zoom: number): number;
    projectedMetersForLatLng(latitude: number, longitude: number): any;
    pixelForLatLng(latitude: number, longitude: number): { x: number; y: number };
    pixelsForLatLngs(input: number[], output: number[]): void;
    latLngForProjectedMeters(northing: number, easting: number): { latitude: number; longitude: number };
    latLngForPixel(x: number, y: number): { latitude: number; longitude: number };
    latLngsForPixels(input: number[], output: number[]): void;

    // Transitions
    getTransitionOptions(): any;
    setTransitionOptions(options: any): void;

    // Query
    queryPointAnnotations(rect: any): number[];
    queryShapeAnnotations(rect: any): number[];
    queryRenderedFeaturesForPoint(x: number, y: number, layerIds?: string[], filter?: any): any[];
    queryRenderedFeaturesForBox(left: number, top: number, right: number, bottom: number, layerIds?: string[], filter?: any): any[];

    // Light
    getLight(): any;

    // Layers
    getLayers(): any[];
    getLayer(layerId: string): any;
    addLayer(layer: any): void;
    addLayerAbove(layer: any, aboveLayerId: string): void;
    addLayerAt(layer: any, index: number): void;
    removeLayerAt(index: number): boolean;
    removeLayer(layer: any): boolean;

    // Sources
    getSources(): any[];
    getSource(sourceId: string): any;
    addSource(source: any): void;
    removeSource(source: any): boolean;

    // Images
    addImage(name: string, bitmap: any, pixelRatio: number, sdf: boolean): void;
    addImages(images: any[]): void;
    removeImage(name: string): void;
    getImage(name: string): any;

    // Tile management
    setPrefetchTiles(enable: boolean): void;
    getPrefetchTiles(): boolean;
    setPrefetchZoomDelta(delta: number): void;
    getPrefetchZoomDelta(): number;
    setTileCacheEnabled(enabled: boolean): void;
    getTileCacheEnabled(): boolean;

    // Tile LOD
    setTileLodMinRadius(radius: number): void;
    getTileLodMinRadius(): number;
    setTileLodScale(scale: number): void;
    getTileLodScale(): number;
    setTileLodPitchThreshold(threshold: number): void;
    getTileLodPitchThreshold(): number;
    setTileLodZoomShift(shift: number): void;
    getTileLodZoomShift(): number;

    // Rendering
    triggerRepaint(): void;
    isRenderingStatsViewEnabled(): boolean;
    enableRenderingStatsView(enabled: boolean): void;

    // Native pointer (for Style API)
    getNativePtr?(): number;
}

// 原有接口定义
