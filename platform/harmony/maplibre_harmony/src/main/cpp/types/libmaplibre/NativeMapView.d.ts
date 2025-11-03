/**
 * MapLibre Native for HarmonyOS - Type Definitions
 * NativeMapView C++ NAPI Bindings
 */

import type { Style } from './Style';
import type { Icon } from './Icon';
import type { Marker } from './Marker';
import type { Polygon } from './annotations/Polygon';
import type { Polyline } from './annotations/Polyline';
import type { Layer } from './layers';
import type { Source } from './sources';
import type { Geometry, Feature } from './geojson';

// ==================== Type Definitions ====================

/**
 * 经纬度坐标接口
 * 注意：LatLng 已改为 ETS 层实现，这里定义为接口以保持类型兼容
 */
export interface LatLng {
    latitude: number;
    longitude: number;
}

/**
 * 经纬度边界接口
 * 注意：LatLngBounds 在 ETS 层实现，这里定义接口以保持类型兼容
 */
export interface LatLngBounds {
    north: number;
    east: number;
    south: number;
    west: number;
}

/**
 * 边距接口
 * 注意：EdgeInsets 在 ETS 层实现，这里定义接口以保持类型兼容
 */
export interface EdgeInsets {
    top: number;
    left: number;
    bottom: number;
    right: number;
}

/**
 * 相机位置接口
 * 注意：CameraPosition 在 ETS 层实现，这里定义接口以保持类型兼容
 */
export interface CameraPosition {
    target: LatLng;
    zoom: number;
    bearing: number;
    tilt: number;
}

/**
 * 相机选项接口
 * 用于设置相机参数
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
 * 矩形接口（用于查询等操作）
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
    /**
     * 创建 NativeMapView 实例
     * @param cachePath 应用缓存目录路径（必需），推荐使用 context.cacheDir + '/maplibre'
     */
    constructor(cachePath: string);

    // ========== View Management ==========
    
    /**
     * 调整视图大小
     * @param width 宽度（逻辑像素）
     * @param height 高度（逻辑像素）
     */
    resizeView(width: number, height: number): void;
    
    /**
     * 设置内容边距（对齐 Android API）
     * @param padding 边距数组 [top, left, bottom, right]（逻辑像素）
     */
    setContentPadding(padding: number[]): void;
    
    /**
     * 获取内容边距（对齐 Android API）
     * @returns 边距数组 [top, left, bottom, right]
     */
    getContentPadding(): number[];
    
    /**
     * 获取设备像素比（对齐 Android API）
     * @returns 像素比（例如：2.0、3.0）
     */
    getPixelRatio(): number;
    
    /**
     * 根据设备像素比调整矩形尺寸（对齐 Android API）
     * @param rectangle 输入矩形
     * @returns 调整后的矩形
     */
    getDensityDependantRectangle(rectangle: Rect): Rect;
    
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
    
    /**
     * 强制重置渲染器与上下文（硬重置）
     * - 释放当前渲染器/线程
     * - 清空并重建缓存目录
     * - 重新创建渲染器与上下文
     * - 若已绑定窗口则自动重新绑定并恢复尺寸
     */
    hardReset(): void;
    
    /**
     * 销毁地图实例并释放所有资源
     * 
     * 线程隔离模式下会销毁：
     * - EGL Context（实例独占）
     * - EGL Surface（实例独占）
     * - Render Thread（实例独占）
     * - Map 对象和相关资源
     * 
     * 不会销毁：
     * - EGL Display（进程共享）
     * 
     * 注意：
     * - 调用后地图实例不可再使用
     * - 可以安全地多次调用（有防重入保护）
     * - 建议在组件 aboutToDisappear() 时调用
     */
    destroy(): void;
    
    /**
     * 异步销毁地图资源（参考 Android/iOS 模式）
     * 使用异步回调而不是硬编码等待，防止阻塞主线程
     * @param callback 销毁完成后的回调函数
     */
    destroyAsync(callback: () => void): void;

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
     * 获取样式对象
     * @returns Style 对象，如果样式未加载则返回 null
     */
    getStyle(): Style | null;
    
    /**
     * 设置经纬度边界
     * @param bounds 边界对象
     */
    setLatLngBounds(bounds: LatLngBounds): void;

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
     * @returns 相机位置对象
     */
    getCameraForLatLngBounds(bounds: LatLngBounds, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): CameraPosition;
    
    /**
     * 获取适应几何对象的相机配置
     * @param geometry 几何对象
     * @param top 上边距
     * @param left 左边距
     * @param bottom 下边距
     * @param right 右边距
     * @param bearing 可选的方位角
     * @param tilt 可选的倾斜角
     * @returns 相机位置对象
     */
    getCameraForGeometry(geometry: Geometry, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): CameraPosition;
    
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
     * @param direction 方向（度）
     * @param duration 动画持续时间（毫秒）
     */
    setVisibleCoordinateBounds(coordinates: LatLng[], padding: EdgeInsets, direction: number, duration: number): void;
    
    /**
     * 获取可见坐标边界
     * @returns 坐标数组
     */
    getVisibleCoordinateBounds(): LatLng[];

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
    addMarkers(markers: Marker[]): number[];
    
    /**
     * 添加折线
     * @param polylines 折线数组
     * @returns 折线 ID 数组
     */
    addPolylines(polylines: Polyline[]): number[];
    
    /**
     * 添加多边形
     * @param polygons 多边形数组
     * @returns 多边形 ID 数组
     */
    addPolygons(polygons: Polygon[]): number[];
    
    /**
     * 更新折线
     * @param polyline 折线对象（必须已添加到地图）
     */
    updatePolyline(polyline: Polyline): void;
    
    /**
     * 更新多边形
     * @param polygon 多边形对象（必须已添加到地图）
     */
    updatePolygon(polygon: Polygon): void;
    
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
    /**
     * 添加标注图标（推荐方式）
     * 
     * 使用 Icon 对象添加图标，性能更好，无需数据拷贝。
     * 
     * @param icon Icon 对象（由 IconFactory 创建）
     * 
     * @example
     * ```typescript
     * const factory = IconFactory.getInstance();
     * const icon = await factory.fromResource($r('app.media.marker'));
     * nativeMapView.addAnnotationIcon(icon);
     * ```
     */
    addAnnotationIcon(icon: Icon): void;
    
    /**
     * 添加标注图标（向后兼容方式）
     * 
     * 使用字节数组添加图标，需要手动转换 PixelMap 为字节数组。
     * 此方式为向后兼容保留，建议使用 Icon 对象方式。
     * 
     * @param symbol 图标 ID
     * @param width 宽度（像素）
     * @param height 高度（像素）
     * @param scale 缩放比例
     * @param pixels 像素数据（RGBA 格式的 Uint8Array）
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
     * 设置调试选项
     * 使用位掩码来启用多个调试功能
     * @param debugOptions 调试选项位掩码（MapDebugOptions 枚举值）
     */
    setDebug(debugOptions: number): void;
    
    /**
     * 获取当前调试选项
     * @returns 当前启用的调试选项位掩码
     */
    getDebug(): number;
    
    /**
     * 快速开关调试模式（使用默认调试选项组合）
     * 启用时会显示：瓦片边界、瓦片信息和碰撞框
     * @param active 是否启用调试模式
     */
    setDebugActive(active: boolean): void;
    
    /**
     * 检查是否处于调试模式
     * @returns 是否有任何调试选项被启用
     */
    isDebugActive(): boolean;

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
     * @returns 投影米坐标对象（对象字面量）
     */
    projectedMetersForLatLng(latitude: number, longitude: number): { northing: number; easting: number; };
    
    /**
     * 将经纬度转换为像素坐标
     * @param latitude 纬度
     * @param longitude 经度
     * @returns 像素坐标（对象字面量）
     */
    pixelForLatLng(latitude: number, longitude: number): { x: number; y: number; };
    
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
     * @returns 转换选项对象（对象字面量）
     */
    getTransitionOptions(): { duration?: number; delay?: number; };
    
    /**
     * 设置转换选项
     * @param options 转换选项对象（对象字面量）
     */
    setTransitionOptions(options: { duration?: number; delay?: number; }): void;

    // ========== Query ==========
    
    /**
     * 查询指定点的渲染要素
     * @param x X 坐标（像素）
     * @param y Y 坐标（像素）
     * @param layerIds 可选的图层 ID 数组，为空则查询所有图层
     * @param filter 可选的过滤表达式
     * @returns GeoJSON Feature 数组
     */
    queryRenderedFeaturesForPoint(x: number, y: number, layerIds?: string[], filter?: object): Feature[];
    
    /**
     * 查询矩形区域内的渲染要素
     * @param left 左边界（像素）
     * @param top 上边界（像素）
     * @param right 右边界（像素）
     * @param bottom 下边界（像素）
     * @param layerIds 可选的图层 ID 数组，为空则查询所有图层
     * @param filter 可选的过滤表达式
     * @returns GeoJSON Feature 数组
     */
    queryRenderedFeaturesForBox(left: number, top: number, right: number, bottom: number, layerIds?: string[], filter?: object): Feature[];

    // ========== Light ==========
    
    /**
     * 获取光照设置
     * @returns 光照对象（包含位置、颜色、强度等属性）
     */
    getLight(): object;

    // ========== Layers ==========
    
    /**
     * 获取所有图层
     * @returns 图层数组
     */
    getLayers(): Layer[];
    
    /**
     * 获取指定图层
     * @param layerId 图层 ID
     * @returns 图层对象，如果不存在则返回 null
     */
    getLayer(layerId: string): Layer | null;
    
    /**
     * 添加图层
     * @param layer 图层对象
     */
    addLayer(layer: Layer): void;
    
    /**
     * 在指定图层上方添加图层
     * @param layer 图层对象
     * @param aboveLayerId 参考图层 ID
     */
    addLayerAbove(layer: Layer, aboveLayerId: string): void;
    
    /**
     * 在指定索引位置添加图层
     * @param layer 图层对象
     * @param index 索引位置
     */
    addLayerAt(layer: Layer, index: number): void;
    
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
    removeLayer(layer: Layer): boolean;

    // ========== Sources ==========
    
    /**
     * 获取所有数据源
     * @returns 数据源数组
     */
    getSources(): Source[];
    
    /**
     * 获取指定数据源
     * @param sourceId 数据源 ID
     * @returns 数据源对象，如果不存在则返回 null
     */
    getSource(sourceId: string): Source | null;
    
    /**
     * 添加数据源
     * @param source 数据源对象
     */
    addSource(source: Source): void;
    
    /**
     * 移除数据源
     * @param source 数据源对象
     * @returns 是否成功移除
     */
    removeSource(source: Source): boolean;

    // ========== Images ==========
    
    /**
     * 添加图像（原始位图方式，不推荐）
     * @deprecated 建议使用 Icon 对象方式
     * @param name 图像名称
     * @param bitmap 位图数据（内部格式，不建议直接使用）
     * @param pixelRatio 像素比
     * @param sdf 是否为 SDF 图像
     */
    addImage(name: string, bitmap: unknown, pixelRatio: number, sdf: boolean): void;
    
    /**
     * 批量添加图像
     * @param images 图像数组（Image 对象数组）
     */
    addImages(images: Icon[]): void;
    
    /**
     * 移除图像
     * @param name 图像名称
     */
    removeImage(name: string): void;
    
    /**
     * 获取图像
     * @param name 图像名称
     * @returns 图像对象，如果不存在则返回 null
     */
    getImage(name: string): Icon | null;

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

    // ========== Performance Configuration (参考 Android MapRenderer) ==========
    
    /**
     * 设置最大帧率（参考 Android MapView.setMaximumFps）
     * @param maximumFps 最大帧率，例如 30、60
     */
    setMaximumFps(maximumFps: number): void;
    
    /**
     * 设置渲染刷新模式（参考 Android MapView.setRenderingRefreshMode）
     * @param mode 渲染模式：0=CONTINUOUS（持续渲染），1=WHEN_DIRTY（按需渲染）
     */
    setRenderingRefreshMode(mode: number): void;
    
    /**
     * 获取渲染刷新模式（参考 Android MapView.getRenderingRefreshMode）
     * @returns 当前渲染模式：0=CONTINUOUS，1=WHEN_DIRTY
     */
    getRenderingRefreshMode(): number;
    
    /**
     * 设置 FPS 变化监听器（参考 Android MapView.setOnFpsChangedListener）
     * 用于实时监控渲染帧率
     * @param listener FPS 变化回调函数，参数为当前 FPS（每秒帧数），传入 null 则移除监听器
     */
    setOnFpsChangedListener(listener: ((fps: number) => void) | null): void;
    
    /**
     * 设置样式加载完成监听器
     * @param callback 回调函数，当样式加载完成时触发
     */
    setOnStyleLoadedListener(callback: (() => void) | null): void;
    
    /**
     * 设置样式加载错误监听器
     * @param callback 回调函数，当样式加载失败时触发
     */
    setOnStyleLoadErrorListener(callback: ((error: string) => void) | null): void;

    // ========== Camera Listeners ==========
    
    /**
     * 添加相机空闲监听器
     * @param callback 回调函数
     */
    addOnCameraIdleListener(callback: () => void): void;
    
    /**
     * 移除相机空闲监听器
     * @param callback 回调函数
     */
    removeOnCameraIdleListener(callback: () => void): void;
    
    /**
     * 添加相机开始移动监听器
     * @param callback 回调函数，参数为移动原因
     */
    addOnCameraMoveStartedListener(callback: (reason: number) => void): void;
    
    /**
     * 移除相机开始移动监听器
     * @param callback 回调函数
     */
    removeOnCameraMoveStartedListener(callback: (reason: number) => void): void;
    
    /**
     * 添加相机移动中监听器
     * @param callback 回调函数
     */
    addOnCameraMoveListener(callback: () => void): void;
    
    /**
     * 移除相机移动中监听器
     * @param callback 回调函数
     */
    removeOnCameraMoveListener(callback: () => void): void;
    
    /**
     * 添加相机移动取消监听器
     * @param callback 回调函数
     */
    addOnCameraMoveCanceledListener(callback: () => void): void;
    
    /**
     * 移除相机移动取消监听器
     * @param callback 回调函数
     */
    removeOnCameraMoveCanceledListener(callback: () => void): void;

    // ========== Android/iOS 风格监听器（新增） ==========
    
    // 相机事件监听器
    /**
     * 添加相机即将改变监听器
     * @param callback 回调函数，参数为是否使用动画
     */
    addOnCameraWillChangeListener(callback: (animated: boolean) => void): void;
    removeOnCameraWillChangeListener(callback: (animated: boolean) => void): void;
    
    /**
     * 添加相机正在改变监听器
     * @param callback 回调函数
     */
    addOnCameraIsChangingListener(callback: () => void): void;
    removeOnCameraIsChangingListener(callback: () => void): void;
    
    /**
     * 添加相机已改变监听器
     * @param callback 回调函数，参数为是否使用动画
     */
    addOnCameraDidChangeListener(callback: (animated: boolean) => void): void;
    removeOnCameraDidChangeListener(callback: (animated: boolean) => void): void;
    
    // 地图加载事件监听器
    /**
     * 添加地图即将开始加载监听器
     * @param callback 回调函数
     */
    addOnWillStartLoadingMapListener(callback: () => void): void;
    removeOnWillStartLoadingMapListener(callback: () => void): void;
    
    /**
     * 添加地图加载完成监听器
     * @param callback 回调函数
     */
    addOnDidFinishLoadingMapListener(callback: () => void): void;
    removeOnDidFinishLoadingMapListener(callback: () => void): void;
    
    /**
     * 添加地图加载失败监听器
     * @param callback 回调函数，参数为错误信息
     */
    addOnDidFailLoadingMapListener(callback: (errorMessage: string) => void): void;
    removeOnDidFailLoadingMapListener(callback: (errorMessage: string) => void): void;
    
    // 渲染事件监听器
    /**
     * 添加帧即将开始渲染监听器
     * @param callback 回调函数
     */
    addOnWillStartRenderingFrameListener(callback: () => void): void;
    removeOnWillStartRenderingFrameListener(callback: () => void): void;
    
    /**
     * 添加帧渲染完成监听器
     * @param callback 回调函数，参数为是否完全渲染、编码时间、渲染时间
     */
    addOnDidFinishRenderingFrameListener(callback: (fully: boolean, frameEncodingTime: number, frameRenderingTime: number) => void): void;
    removeOnDidFinishRenderingFrameListener(callback: (fully: boolean, frameEncodingTime: number, frameRenderingTime: number) => void): void;
    
    /**
     * 添加地图即将开始渲染监听器
     * @param callback 回调函数
     */
    addOnWillStartRenderingMapListener(callback: () => void): void;
    removeOnWillStartRenderingMapListener(callback: () => void): void;
    
    /**
     * 添加地图渲染完成监听器
     * @param callback 回调函数，参数为是否完全渲染
     */
    addOnDidFinishRenderingMapListener(callback: (fully: boolean) => void): void;
    removeOnDidFinishRenderingMapListener(callback: (fully: boolean) => void): void;
    
    // 样式事件监听器
    /**
     * 添加样式加载完成监听器
     * @param callback 回调函数
     */
    addOnDidFinishLoadingStyleListener(callback: () => void): void;
    removeOnDidFinishLoadingStyleListener(callback: () => void): void;
    
    /**
     * 添加样式图片缺失监听器
     * @param callback 回调函数，参数为缺失的图片 ID
     */
    addOnStyleImageMissingListener(callback: (id: string) => void): void;
    removeOnStyleImageMissingListener(callback: (id: string) => void): void;
    
    // 其他事件监听器
    /**
     * 添加地图进入空闲状态监听器
     * @param callback 回调函数
     */
    addOnDidBecomeIdleListener(callback: () => void): void;
    removeOnDidBecomeIdleListener(callback: () => void): void;
    
    /**
     * 添加数据源改变监听器
     * @param callback 回调函数，参数为数据源 ID
     */
    addOnSourceChangedListener(callback: (id: string) => void): void;
    removeOnSourceChangedListener(callback: (id: string) => void): void;

}

// ==================== MapSnapshotter API ====================

/**
 * 快照选项（NAPI 层）
 */
export interface SnapshotOptionsNAPI {
  /** 宽度（像素） */
  width: number;
  /** 高度（像素） */
  height: number;
  /** 像素比 */
  pixelRatio: number;
  /** 样式 URL */
  styleUrl: string;
  /** 样式 JSON（可选） */
  styleJson?: string;
  /** 是否显示 logo */
  showLogo?: boolean;
  /** 本地字体族 */
  localFontFamily?: string;
}

/**
 * 快照结果（NAPI 层）
 */
export interface SnapshotResultNAPI {
  /** 图像数据（RGBA格式） */
  data: ArrayBuffer;
  /** 图像宽度 */
  width: number;
  /** 图像高度 */
  height: number;
  /** 归属信息 */
  attributions?: string[];
}

/**
 * MapSnapshotter NAPI 对象
 */
export interface MapSnapshotterNAPI {
  /**
   * 开始生成快照
   * @param callback 回调函数 (error, result)
   */
  start(callback: (error: string | null, result: SnapshotResultNAPI | null) => void): void;
  
  /**
   * 取消快照生成
   */
  cancel(): void;
  
  /**
   * 设置样式 URL
   * @param styleUrl 样式 URL
   */
  setStyleUrl(styleUrl: string): void;
  
    /**
     * 设置相机位置
     * @param position 相机位置对象
     */
    setCameraPosition(position: CameraPosition): void;
    
    /**
     * 设置区域边界
     * @param bounds 边界对象
     */
    setRegion(bounds: LatLngBounds): void;
}

/**
 * 创建 MapSnapshotter 实例
 * 
 * @param options 快照选项
 * @returns MapSnapshotter NAPI 对象
 */
export function createMapSnapshotter(options: SnapshotOptionsNAPI): MapSnapshotterNAPI;

