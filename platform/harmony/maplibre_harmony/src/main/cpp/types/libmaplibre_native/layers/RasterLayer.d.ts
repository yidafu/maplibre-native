/**
 * MapLibre Native for HarmonyOS - RasterLayer Type Definitions
 * 栅格图层 API (NAPI 类)
 */

/**
 * RasterLayer - 栅格图层
 * 用于渲染栅格瓦片数据
 */
export class RasterLayer {
    /**
     * 创建栅格图层
     * @param layerId 图层 ID
     * @param sourceId 数据源 ID
     */
    constructor(layerId: string, sourceId: string);

    /**
     * 设置栅格不透明度
     * @param opacity 不透明度（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setRasterOpacity(opacity: number): this;

    /**
     * 设置栅格色相旋转
     * @param hueRotate 色相旋转角度（度）
     * @returns 返回 this 以支持链式调用
     */
    setRasterHueRotate(hueRotate: number): this;

    /**
     * 设置栅格最小亮度
     * @param brightnessMin 最小亮度（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setRasterBrightnessMin(brightnessMin: number): this;

    /**
     * 设置栅格最大亮度
     * @param brightnessMax 最大亮度（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setRasterBrightnessMax(brightnessMax: number): this;

    /**
     * 设置栅格饱和度
     * @param saturation 饱和度（-1.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setRasterSaturation(saturation: number): this;

    /**
     * 设置栅格对比度
     * @param contrast 对比度（-1.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setRasterContrast(contrast: number): this;

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
