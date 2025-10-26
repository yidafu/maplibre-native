/**
 * MapLibre Native for HarmonyOS - LineLayer Type Definitions
 * 线图层 API (NAPI 类)
 */

/**
 * LineLayer - 线图层
 * 用于渲染线要素
 */
export class LineLayer {
    /**
     * 创建线图层
     * @param layerId 图层 ID
     * @param sourceId 数据源 ID
     */
    constructor(layerId: string, sourceId: string);

    /**
     * 设置线条颜色
     * @param color 颜色值（CSS 颜色字符串）
     * @returns 返回 this 以支持链式调用
     */
    setLineColor(color: string): this;

    /**
     * 设置线条宽度
     * @param width 宽度（单位：像素）
     * @returns 返回 this 以支持链式调用
     */
    setLineWidth(width: number): this;

    /**
     * 设置线条不透明度
     * @param opacity 不透明度（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setLineOpacity(opacity: number): this;

    /**
     * 设置线条图案
     * @param pattern 图案名称（需要先通过 addImage 添加）
     * @returns 返回 this 以支持链式调用
     */
    setLinePattern(pattern: string): this;

    /**
     * 设置线条间隙宽度
     * @param gapWidth 间隙宽度（单位：像素）
     * @returns 返回 this 以支持链式调用
     */
    setLineGapWidth(gapWidth: number): this;

    /**
     * 设置虚线样式
     * @param dasharray 虚线数组，例如 [2, 2] 表示 2 像素实线，2 像素空白
     * @returns 返回 this 以支持链式调用
     */
    setLineDasharray(dasharray: number[]): this;

    /**
     * 设置线条模糊
     * @param blur 模糊量（单位：像素）
     * @returns 返回 this 以支持链式调用
     */
    setLineBlur(blur: number): this;

    /**
     * 设置线条偏移
     * @param offset 偏移量（单位：像素，正值向右，负值向左）
     * @returns 返回 this 以支持链式调用
     */
    setLineOffset(offset: number): this;

    /**
     * 设置线条端点样式
     * @param cap 端点样式：'butt' | 'round' | 'square'
     * @returns 返回 this 以支持链式调用
     */
    setLineCap(cap: string): this;

    /**
     * 设置线条连接样式
     * @param join 连接样式：'miter' | 'round' | 'bevel'
     * @returns 返回 this 以支持链式调用
     */
    setLineJoin(join: string): this;

    /**
     * 获取线条颜色
     * @returns 颜色字符串，如果是表达式则返回 undefined
     */
    getLineColor(): string | undefined;

    /**
     * 获取线条宽度
     * @returns 宽度值，如果是表达式则返回 undefined
     */
    getLineWidth(): number | undefined;

    /**
     * 获取线条不透明度
     * @returns 不透明度值，如果是表达式则返回 undefined
     */
    getLineOpacity(): number | undefined;

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
}
