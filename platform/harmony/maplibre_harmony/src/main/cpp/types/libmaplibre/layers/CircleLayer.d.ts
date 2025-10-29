/**
 * MapLibre Native for HarmonyOS - CircleLayer Type Definitions
 * 圆形图层 API (NAPI 类)
 */

/**
 * CircleLayer - 圆形图层
 * 用于渲染圆形点要素
 */
export class CircleLayer {
    /**
     * 创建圆形图层
     * @param layerId 图层 ID
     * @param sourceId 数据源 ID
     */
    constructor(layerId: string, sourceId: string);

    /**
     * 设置圆形半径
     * @param radius 半径（单位：像素）
     * @returns 返回 this 以支持链式调用
     */
    setCircleRadius(radius: number): this;

    /**
     * 设置圆形颜色
     * @param color 颜色值（CSS 颜色字符串）
     * @returns 返回 this 以支持链式调用
     */
    setCircleColor(color: string): this;

    /**
     * 设置圆形不透明度
     * @param opacity 不透明度（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setCircleOpacity(opacity: number): this;

    /**
     * 设置圆形模糊
     * @param blur 模糊量（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setCircleBlur(blur: number): this;

    /**
     * 设置圆形边框宽度
     * @param width 边框宽度（单位：像素）
     * @returns 返回 this 以支持链式调用
     */
    setCircleStrokeWidth(width: number): this;

    /**
     * 设置圆形边框颜色
     * @param color 颜色值（CSS 颜色字符串）
     * @returns 返回 this 以支持链式调用
     */
    setCircleStrokeColor(color: string): this;

    /**
     * 设置圆形边框不透明度
     * @param opacity 不透明度（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setCircleStrokeOpacity(opacity: number): this;

    /**
     * 获取圆形半径
     * @returns 半径值，如果是表达式则返回 undefined
     */
    getCircleRadius(): number | undefined;

    /**
     * 获取圆形颜色
     * @returns 颜色字符串，如果是表达式则返回 undefined
     */
    getCircleColor(): string | undefined;

    /**
     * 获取圆形不透明度
     * @returns 不透明度值，如果是表达式则返回 undefined
     */
    getCircleOpacity(): number | undefined;

    /**
     * 获取图层 ID
     */
    getId(): string;

    /**
     * 获取图层类型
     */
    getType(): string;

    /**
     * 获取数据源 ID
     */
    getSourceId(): string;

    /**
     * 设置图层可见性
     * @param visibility 可见性：'visible' 显示 | 'none' 隐藏
     * @returns 返回 this 以支持链式调用
     */
    setVisibility(visibility: 'visible' | 'none'): this;

    /**
     * 获取图层可见性
     * @returns 'visible' 或 'none'
     */
    getVisibility(): 'visible' | 'none';

    /**
     * 设置最小缩放级别
     * 图层只在缩放级别 >= minZoom 时显示
     * @param zoom 最小缩放级别（0-24）
     * @returns 返回 this 以支持链式调用
     */
    setMinZoom(zoom: number): this;

    /**
     * 获取最小缩放级别
     */
    getMinZoom(): number;

    /**
     * 设置最大缩放级别
     * 图层只在缩放级别 <= maxZoom 时显示
     * @param zoom 最大缩放级别（0-24）
     * @returns 返回 this 以支持链式调用
     */
    setMaxZoom(zoom: number): this;

    /**
     * 获取最大缩放级别
     */
    getMaxZoom(): number;

    /**
     * 设置源图层
     * 用于矢量瓦片数据源，指定要使用的图层名称
     * @param sourceLayer 源图层名称
     * @returns 返回 this 以支持链式调用
     */
    setSourceLayer(sourceLayer: string): this;

    /**
     * 获取源图层
     */
    getSourceLayer(): string;

    /**
     * 设置图层过滤器
     * 使用 MapLibre 表达式数组过滤要素
     * 
     * @param filter 过滤器表达式数组，例如：
     *   - ["==", ["get", "type"], "restaurant"]
     *   - ["all", [">=", ["get", "price"], 10], ["<", ["get", "price"], 100]]
     * @returns 返回 this 以支持链式调用
     * @see https://maplibre.org/maplibre-style-spec/expressions/
     */
    setFilter(filter: any[]): this;

    /**
     * 获取图层过滤器
     * @returns 过滤器表达式数组或 null
     */
    getFilter(): any[] | null;
}
