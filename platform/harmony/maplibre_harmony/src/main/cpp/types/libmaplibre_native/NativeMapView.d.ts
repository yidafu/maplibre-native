/**
 * MapLibre Native for HarmonyOS - Type Definitions
 * NativeMapView C++ NAPI Bindings
 */

// ==================== Type Definitions ====================

/**
 * 经纬度坐标
 */
export interface LatLng {
    latitude: number;
    longitude: number;
}

/**
 * 相机选项
 */
export interface CameraOptions {
    /** 中心点坐标 */
    center?: LatLng;
    /** 缩放级别 */
    zoom?: number;
    /** 方位角（度） */
    bearing?: number;
    /** 俯仰角（度） */
    pitch?: number;
    /** 边距 */
    padding?: EdgeInsets;
}

/**
 * 边距设置
 */
export interface EdgeInsets {
    top: number;
    left: number;
    bottom: number;
    right: number;
}

/**
 * 相机位置
 */
export interface CameraPosition {
    /** 目标位置 */
    target: LatLng;
    /** 缩放级别 */
    zoom: number;
    /** 方位角（度） */
    bearing: number;
    /** 倾斜角（度） */
    tilt: number;
}

/**
 * 像素坐标
 */
export interface PixelCoordinate {
    x: number;
    y: number;
}

/**
 * 投影米坐标
 */
export interface ProjectedMeters {
    northing: number;
    easting: number;
}

/**
 * 转换选项
 */
export interface TransitionOptions {
    /** 持续时间（毫秒） */
    duration?: number;
    /** 延迟（毫秒） */
    delay?: number;
}

/**
 * 矩形区域
 */
export interface Rect {
    left: number;
    top: number;
    right: number;
    bottom: number;
}

// ==================== NativeMapView Class ====================

/**
 * MapLibre Native Map View
 * 提供地图渲染和交互的底层 C++ 绑定
 */
export class NativeMapView {
    constructor();

    // ========== View Management ==========
    
    /**
     * 调整视图大小
     * @param width 宽度（逻辑像素）
     * @param height 高度（逻辑像素）
     */
    resizeView(width: number, height: number): void;
    
    /**
     * 设置原生窗口
     * @param surfaceId Surface ID
     */
    setNativeWindow(surfaceId: BigInt): void;
    
    /**
     * 设置原生窗口（带尺寸参数）
     * @param surfaceId Surface ID
     * @param width 宽度（逻辑像素）
     * @param height 高度（逻辑像素）
     */
    setNativeWindowWithSize(surfaceId: BigInt, width: number, height: number): void;

    // ========== Style Management ==========
    
    /**
     * 获取当前样式 URL
     * @returns 样式 URL
     */
    getStyleUrl(): string;
    
    /**
     * 设置样式 URL
     * @param url 样式 URL
     */
    setStyleUrl(url: string): void;
    
    /**
     * 获取当前样式 JSON
     * @returns 样式 JSON 字符串
     */
    getStyleJson(): string;
    
    /**
     * 设置样式 JSON
     * @param json 样式 JSON 字符串
     */
    setStyleJson(json: string): void;
    
    /**
     * 设置经纬度边界
     * @param bounds 边界对象
     */
    setLatLngBounds(bounds: any): void;

    // ========== Camera Control ==========
    
    /**
     * 取消所有正在进行的过渡动画
     */
    cancelTransitions(): void;
    
    /**
     * 设置手势进行状态
     * @param inProgress 是否正在进行手势操作
     */
    setGestureInProgress(inProgress: boolean): void;
    
    /**
     * 平移地图
     * @param dx X 方向偏移量（像素）
     * @param dy Y 方向偏移量（像素）
     * @param duration 动画持续时间（毫秒）
     */
    moveBy(dx: number, dy: number, duration: number): void;
    
    /**
     * 立即跳转到指定相机位置（无动画）
     * @param angle 方位角（度）
     * @param latitude 纬度
     * @param longitude 经度
     * @param pitch 俯仰角（度）
     * @param zoom 缩放级别
     * @param padding 可选的边距数组 [top, left, bottom, right]
     */
    jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number, padding?: number[]): void;
    
    /**
     * 平滑过渡到指定相机位置
     * @param options 相机选项
     * @param duration 动画持续时间（毫秒）
     */
    easeTo(options: CameraOptions, duration: number): void;
    
    /**
     * 飞行动画到指定相机位置
     * @param options 相机选项
     * @param duration 动画持续时间（毫秒）
     */
    flyTo(options: CameraOptions, duration: number): void;

    // ========== Position and Camera ==========
    
    /**
     * 获取地图中心点坐标
     * @returns 经纬度坐标
     */
    getLatLng(): LatLng;
    
    /**
     * 设置地图中心点坐标
     * @param latitude 纬度
     * @param longitude 经度
     * @param padding 可选的边距数组
     * @param duration 可选的动画持续时间（毫秒）
     */
    setLatLng(latitude: number, longitude: number, padding?: number[], duration?: number): void;
    
    /**
     * 获取适应经纬度边界的相机配置
     * @param bounds 边界对象
     * @param top 上边距
     * @param left 左边距
     * @param bottom 下边距
     * @param right 右边距
     * @param bearing 可选的方位角
     * @param tilt 可选的倾斜角
     * @returns 相机配置对象
     */
    getCameraForLatLngBounds(bounds: any, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): any;
    
    /**
     * 获取适应几何对象的相机配置
     * @param geometry 几何对象
     * @param top 上边距
     * @param left 左边距
     * @param bottom 下边距
     * @param right 右边距
     * @param bearing 可选的方位角
     * @param tilt 可选的倾斜角
     * @returns 相机配置对象
     */
    getCameraForGeometry(geometry: any, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): any;
    
    /**
     * 设置网络可达性状态
     * @param status 是否可达
     */
    setReachability(status: boolean): void;
    
    /**
     * 重置地图位置到初始状态
     */
    resetPosition(): void;
    
    /**
     * 获取当前相机位置
     * @returns 相机位置对象
     */
    getCameraPosition(): CameraPosition;

    // ========== Pitch Control ==========
    
    /**
     * 获取当前俯仰角
     * @returns 俯仰角（度）
     */
    getPitch(): number;
    
    /**
     * 设置俯仰角
     * @param pitch 俯仰角（度，0-60）
     * @param duration 可选的动画持续时间（毫秒）
     */
    setPitch(pitch: number, duration?: number): void;
    
    /**
     * 设置最小俯仰角
     * @param pitch 最小俯仰角（度）
     */
    setMinPitch(pitch: number): void;
    
    /**
     * 获取最小俯仰角
     * @returns 最小俯仰角（度）
     */
    getMinPitch(): number;
    
    /**
     * 设置最大俯仰角
     * @param pitch 最大俯仰角（度）
     */
    setMaxPitch(pitch: number): void;
    
    /**
     * 获取最大俯仰角
     * @returns 最大俯仰角（度）
     */
    getMaxPitch(): number;

    // ========== Zoom Control ==========
    
    /**
     * 设置缩放级别
     * @param zoom 缩放级别
     * @param cx 可选的中心点 X 坐标
     * @param cy 可选的中心点 Y 坐标
     * @param duration 可选的动画持续时间（毫秒）
     */
    setZoom(zoom: number, cx?: number, cy?: number, duration?: number): void;
    
    /**
     * 获取当前缩放级别
     * @returns 缩放级别
     */
    getZoom(): number;
    
    /**
     * 重置缩放级别到默认值
     */
    resetZoom(): void;
    
    /**
     * 设置最小缩放级别
     * @param zoom 最小缩放级别
     */
    setMinZoom(zoom: number): void;
    
    /**
     * 获取最小缩放级别
     * @returns 最小缩放级别
     */
    getMinZoom(): number;
    
    /**
     * 设置最大缩放级别
     * @param zoom 最大缩放级别
     */
    setMaxZoom(zoom: number): void;
    
    /**
     * 获取最大缩放级别
     * @returns 最大缩放级别
     */
    getMaxZoom(): number;

    // ========== Rotation and Bearing ==========
    
    /**
     * 旋转地图
     * @param sx 起始点 X 坐标
     * @param sy 起始点 Y 坐标
     * @param ex 结束点 X 坐标
     * @param ey 结束点 Y 坐标
     * @param duration 可选的动画持续时间（毫秒）
     */
    rotateBy(sx: number, sy: number, ex: number, ey: number, duration?: number): void;
    
    /**
     * 设置方位角
     * @param degrees 方位角（度）
     * @param duration 可选的动画持续时间（毫秒）
     */
    setBearing(degrees: number, duration?: number): void;
    
    /**
     * 设置方位角（以指定点为中心）
     * @param degrees 方位角（度）
     * @param fx 中心点 X 坐标
     * @param fy 中心点 Y 坐标
     * @param duration 可选的动画持续时间（毫秒）
     */
    setBearingXY(degrees: number, fx: number, fy: number, duration?: number): void;
    
    /**
     * 获取当前方位角
     * @returns 方位角（度）
     */
    getBearing(): number;
    
    /**
     * 重置方位角到正北方向（0度）
     */
    resetNorth(): void;

    // ========== Coordinate Bounds ==========
    
    /**
     * 设置可见坐标边界
     * @param coordinates 坐标数组
     * @param padding 边距对象
     * @param direction 方向
     * @param duration 动画持续时间（毫秒）
     */
    setVisibleCoordinateBounds(coordinates: any[], padding: any, direction: number, duration: number): void;
    
    /**
     * 获取可见坐标边界
     * @returns 坐标数组
     */
    getVisibleCoordinateBounds(): any[];

    // ========== Snapshot ==========
    
    /**
     * 计划快照生成
     */
    scheduleSnapshot(): void;

    // ========== Annotations ==========
    
    /**
     * 更新标记位置
     * @param markerId 标记 ID
     * @param lat 纬度
     * @param lon 经度
     * @param iconId 图标 ID
     */
    updateMarker(markerId: number, lat: number, lon: number, iconId: string): void;
    
    /**
     * 添加标记
     * @param markers 标记数组
     * @returns 标记 ID 数组
     */
    addMarkers(markers: any[]): number[];
    
    /**
     * 添加折线
     * @param polylines 折线数组
     * @returns 折线 ID 数组
     */
    addPolylines(polylines: any[]): number[];
    
    /**
     * 添加多边形
     * @param polygons 多边形数组
     * @returns 多边形 ID 数组
     */
    addPolygons(polygons: any[]): number[];
    
    /**
     * 更新折线
     * @param polylineId 折线 ID
     * @param polyline 折线对象
     */
    updatePolyline(polylineId: number, polyline: any): void;
    
    /**
     * 更新多边形
     * @param polygonId 多边形 ID
     * @param polygon 多边形对象
     */
    updatePolygon(polygonId: number, polygon: any): void;
    
    /**
     * 移除注记
     * @param ids 注记 ID 数组
     */
    removeAnnotations(ids: number[]): void;
    
    /**
     * 添加注记图标
     * @param symbol 符号名称
     * @param width 宽度
     * @param height 高度
     * @param scale 缩放比例
     * @param pixels 像素数据
     */
    addAnnotationIcon(symbol: string, width: number, height: number, scale: number, pixels: Uint8Array): void;
    
    /**
     * 移除注记图标
     * @param symbol 符号名称
     */
    removeAnnotationIcon(symbol: string): void;
    
    /**
     * 获取注记符号的顶部偏移像素
     * @param symbolName 符号名称
     * @returns 偏移像素值
     */
    getTopOffsetPixelsForAnnotationSymbol(symbolName: string): number;

    // ========== Memory Management ==========
    
    /**
     * 低内存警告回调
     */
    onLowMemory(): void;

    // ========== Debug ==========
    
    /**
     * 设置调试模式
     * @param debug 是否启用调试
     */
    setDebug(debug: boolean): void;
    
    /**
     * 获取调试模式状态
     * @returns 是否启用调试
     */
    getDebug(): boolean;

    // ========== Action Journal ==========
    
    /**
     * 获取操作日志文件列表
     * @returns 日志文件路径数组
     */
    getActionJournalLogFiles(): string[];
    
    /**
     * 获取操作日志
     * @returns 日志条目数组
     */
    getActionJournalLog(): string[];
    
    /**
     * 清除操作日志
     */
    clearActionJournalLog(): void;

    // ========== Loading Status ==========
    
    /**
     * 检查地图是否完全加载
     * @returns 是否完全加载
     */
    isFullyLoaded(): boolean;

    // ========== Coordinate Conversion ==========
    
    /**
     * 获取指定纬度和缩放级别下每像素对应的米数
     * @param latitude 纬度
     * @param zoom 缩放级别
     * @returns 每像素米数
     */
    getMetersPerPixelAtLatitude(latitude: number, zoom: number): number;
    
    /**
     * 将经纬度转换为投影米坐标
     * @param latitude 纬度
     * @param longitude 经度
     * @returns 投影米坐标对象
     */
    projectedMetersForLatLng(latitude: number, longitude: number): ProjectedMeters;
    
    /**
     * 将经纬度转换为像素坐标
     * @param latitude 纬度
     * @param longitude 经度
     * @returns 像素坐标
     */
    pixelForLatLng(latitude: number, longitude: number): PixelCoordinate;
    
    /**
     * 批量将经纬度转换为像素坐标
     * @param input 输入经纬度数组 [lat1, lon1, lat2, lon2, ...]
     * @param output 输出像素坐标数组 [x1, y1, x2, y2, ...]
     */
    pixelsForLatLngs(input: number[], output: number[]): void;
    
    /**
     * 将投影米坐标转换为经纬度
     * @param northing 北向坐标
     * @param easting 东向坐标
     * @returns 经纬度坐标
     */
    latLngForProjectedMeters(northing: number, easting: number): LatLng;
    
    /**
     * 将像素坐标转换为经纬度
     * @param x X 坐标
     * @param y Y 坐标
     * @returns 经纬度坐标
     */
    latLngForPixel(x: number, y: number): LatLng;
    
    /**
     * 批量将像素坐标转换为经纬度
     * @param input 输入像素坐标数组 [x1, y1, x2, y2, ...]
     * @param output 输出经纬度数组 [lat1, lon1, lat2, lon2, ...]
     */
    latLngsForPixels(input: number[], output: number[]): void;

    // ========== Transitions ==========
    
    /**
     * 获取转换选项
     * @returns 转换选项对象
     */
    getTransitionOptions(): TransitionOptions;
    
    /**
     * 设置转换选项
     * @param options 转换选项对象
     */
    setTransitionOptions(options: TransitionOptions): void;

    // ========== Query ==========
    
    /**
     * 查询矩形区域内的点注记
     * @param rect 矩形区域
     * @returns 注记 ID 数组
     */
    queryPointAnnotations(rect: Rect): number[];
    
    /**
     * 查询矩形区域内的形状注记
     * @param rect 矩形区域
     * @returns 注记 ID 数组
     */
    queryShapeAnnotations(rect: Rect): number[];
    
    /**
     * 查询指定点的渲染要素
     * @param x X 坐标
     * @param y Y 坐标
     * @param layerIds 可选的图层 ID 数组
     * @param filter 可选的过滤器
     * @returns 要素数组
     */
    queryRenderedFeaturesForPoint(x: number, y: number, layerIds?: string[], filter?: any): any[];
    
    /**
     * 查询矩形区域内的渲染要素
     * @param left 左边界
     * @param top 上边界
     * @param right 右边界
     * @param bottom 下边界
     * @param layerIds 可选的图层 ID 数组
     * @param filter 可选的过滤器
     * @returns 要素数组
     */
    queryRenderedFeaturesForBox(left: number, top: number, right: number, bottom: number, layerIds?: string[], filter?: any): any[];

    // ========== Light ==========
    
    /**
     * 获取光照设置
     * @returns 光照对象
     */
    getLight(): any;

    // ========== Layers ==========
    
    /**
     * 获取所有图层
     * @returns 图层数组
     */
    getLayers(): any[];
    
    /**
     * 获取指定图层
     * @param layerId 图层 ID
     * @returns 图层对象
     */
    getLayer(layerId: string): any;
    
    /**
     * 添加图层
     * @param layer 图层对象
     */
    addLayer(layer: any): void;
    
    /**
     * 在指定图层上方添加图层
     * @param layer 图层对象
     * @param aboveLayerId 参考图层 ID
     */
    addLayerAbove(layer: any, aboveLayerId: string): void;
    
    /**
     * 在指定索引位置添加图层
     * @param layer 图层对象
     * @param index 索引位置
     */
    addLayerAt(layer: any, index: number): void;
    
    /**
     * 移除指定索引位置的图层
     * @param index 索引位置
     * @returns 是否成功移除
     */
    removeLayerAt(index: number): boolean;
    
    /**
     * 移除图层
     * @param layer 图层对象
     * @returns 是否成功移除
     */
    removeLayer(layer: any): boolean;

    // ========== Sources ==========
    
    /**
     * 获取所有数据源
     * @returns 数据源数组
     */
    getSources(): any[];
    
    /**
     * 获取指定数据源
     * @param sourceId 数据源 ID
     * @returns 数据源对象
     */
    getSource(sourceId: string): any;
    
    /**
     * 添加数据源
     * @param source 数据源对象
     */
    addSource(source: any): void;
    
    /**
     * 移除数据源
     * @param source 数据源对象
     * @returns 是否成功移除
     */
    removeSource(source: any): boolean;

    // ========== Images ==========
    
    /**
     * 添加图像
     * @param name 图像名称
     * @param bitmap 位图数据
     * @param pixelRatio 像素比
     * @param sdf 是否为 SDF 图像
     */
    addImage(name: string, bitmap: any, pixelRatio: number, sdf: boolean): void;
    
    /**
     * 批量添加图像
     * @param images 图像数组
     */
    addImages(images: any[]): void;
    
    /**
     * 移除图像
     * @param name 图像名称
     */
    removeImage(name: string): void;
    
    /**
     * 获取图像
     * @param name 图像名称
     * @returns 图像对象
     */
    getImage(name: string): any;

    // ========== Tile Management ==========
    
    /**
     * 设置是否启用瓦片预取
     * @param enable 是否启用
     */
    setPrefetchTiles(enable: boolean): void;
    
    /**
     * 获取瓦片预取状态
     * @returns 是否启用预取
     */
    getPrefetchTiles(): boolean;
    
    /**
     * 设置预取缩放增量
     * @param delta 缩放增量
     */
    setPrefetchZoomDelta(delta: number): void;
    
    /**
     * 获取预取缩放增量
     * @returns 缩放增量
     */
    getPrefetchZoomDelta(): number;
    
    /**
     * 设置是否启用瓦片缓存
     * @param enabled 是否启用
     */
    setTileCacheEnabled(enabled: boolean): void;
    
    /**
     * 获取瓦片缓存状态
     * @returns 是否启用缓存
     */
    getTileCacheEnabled(): boolean;

    // ========== Tile LOD ==========
    
    /**
     * 设置瓦片 LOD 最小半径
     * @param radius 最小半径
     */
    setTileLodMinRadius(radius: number): void;
    
    /**
     * 获取瓦片 LOD 最小半径
     * @returns 最小半径
     */
    getTileLodMinRadius(): number;
    
    /**
     * 设置瓦片 LOD 缩放比例
     * @param scale 缩放比例
     */
    setTileLodScale(scale: number): void;
    
    /**
     * 获取瓦片 LOD 缩放比例
     * @returns 缩放比例
     */
    getTileLodScale(): number;
    
    /**
     * 设置瓦片 LOD 俯仰阈值
     * @param threshold 俯仰阈值
     */
    setTileLodPitchThreshold(threshold: number): void;
    
    /**
     * 获取瓦片 LOD 俯仰阈值
     * @returns 俯仰阈值
     */
    getTileLodPitchThreshold(): number;
    
    /**
     * 设置瓦片 LOD 缩放偏移
     * @param shift 缩放偏移
     */
    setTileLodZoomShift(shift: number): void;
    
    /**
     * 获取瓦片 LOD 缩放偏移
     * @returns 缩放偏移
     */
    getTileLodZoomShift(): number;

    // ========== Rendering ==========
    
    /**
     * 触发地图重绘
     */
    triggerRepaint(): void;
    
    /**
     * 检查是否启用渲染统计视图
     * @returns 是否启用
     */
    isRenderingStatsViewEnabled(): boolean;
    
    /**
     * 启用或禁用渲染统计视图
     * @param enabled 是否启用
     */
    enableRenderingStatsView(enabled: boolean): void;

    // ========== Native Pointer ==========
    
    /**
     * 获取原生指针（用于 Style API）
     * @returns 原生指针
     */
    getNativePtr?(): number;
}
