/**
 * MapLibre Native for HarmonyOS - FillLayer Type Definitions
 * 填充图层 API (NAPI 类)
 */

/**
 * FillLayer - 填充图层
 * 用于渲染多边形区域
 */
export class FillLayer {
    /**
     * 创建填充图层
     * @param layerId 图层 ID
     * @param sourceId 数据源 ID
     */
    constructor(layerId: string, sourceId: string);

    /**
     * 设置填充颜色
     * @param color 颜色值（CSS 颜色字符串，如 "#ff0000" 或 "rgba(255, 0, 0, 1)"）
     * @returns 返回 this 以支持链式调用
     */
    setFillColor(color: string): this;

    /**
     * 设置填充不透明度
     * @param opacity 不透明度（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setFillOpacity(opacity: number): this;

    /**
     * 设置填充轮廓颜色
     * @param color 颜色值（CSS 颜色字符串）
     * @returns 返回 this 以支持链式调用
     */
    setFillOutlineColor(color: string): this;

    /**
     * 设置填充图案
     * @param pattern 图案名称（需要先通过 addImage 添加）
     * @returns 返回 this 以支持链式调用
     */
    setFillPattern(pattern: string): this;

    /**
     * 设置填充抗锯齿
     * @param antialias 是否启用抗锯齿
     * @returns 返回 this 以支持链式调用
     */
    setFillAntialias(antialias: boolean): this;

    /**
     * 设置填充平移
     * @param translate 平移量 [x, y]（单位：像素）
     * @returns 返回 this 以支持链式调用
     */
    setFillTranslate(translate: number[]): this;

    /**
     * 获取填充颜色
     * @returns 颜色字符串，如果是表达式则返回 undefined
     */
    getFillColor(): string | undefined;

    /**
     * 获取填充不透明度
     * @returns 不透明度值，如果是表达式则返回 undefined
     */
    getFillOpacity(): number | undefined;

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
     */
    getVisibility(): 'visible' | 'none';

    /**
     * 设置最小缩放级别
     * @param zoom 最小缩放级别（0-24）
     */
    setMinZoom(zoom: number): this;
    getMinZoom(): number;

    /**
     * 设置最大缩放级别
     * @param zoom 最大缩放级别（0-24）
     */
    setMaxZoom(zoom: number): this;
    getMaxZoom(): number;

    /**
     * 设置源图层
     * @param sourceLayer 源图层名称
     */
    setSourceLayer(sourceLayer: string): this;
    getSourceLayer(): string;

    /**
     * 设置图层过滤器
     * @param filter 过滤器表达式数组
     */
    setFilter(filter: any[]): this;

    /**
     * 获取图层过滤器
     */
    getFilter(): any[] | null;
}
