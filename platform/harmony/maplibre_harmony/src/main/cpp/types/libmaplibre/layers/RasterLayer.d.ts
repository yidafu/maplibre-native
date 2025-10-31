/**
 * MapLibre Native for HarmonyOS - RasterLayer Type Definitions
 * 栅格图层 API (NAPI 类)
 */

import type { NumberValue } from '../LayerPropertyTypes';

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
     * @param opacity 不透明度或Expression（0.0 - 1.0）
     */
    setRasterOpacity(opacity: NumberValue): this;

    /**
     * 设置栅格色相旋转
     * @param hueRotate 色相旋转角度或Expression
     */
    setRasterHueRotate(hueRotate: NumberValue): this;

    /**
     * 设置栅格最小亮度
     * @param brightnessMin 最小亮度或Expression（0.0 - 1.0）
     */
    setRasterBrightnessMin(brightnessMin: NumberValue): this;

    /**
     * 设置栅格最大亮度
     * @param brightnessMax 最大亮度或Expression（0.0 - 1.0）
     */
    setRasterBrightnessMax(brightnessMax: NumberValue): this;

    /**
     * 设置栅格饱和度
     * @param saturation 饱和度或Expression（-1.0 - 1.0）
     */
    setRasterSaturation(saturation: NumberValue): this;

    /**
     * 设置栅格对比度
     * @param contrast 对比度或Expression（-1.0 - 1.0）
     */
    setRasterContrast(contrast: NumberValue): this;

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
     */
    setVisibility(visibility: 'visible' | 'none'): this;
    getVisibility(): 'visible' | 'none';

    /**
     * 设置最小/最大缩放级别
     */
    setMinZoom(zoom: number): this;
    getMinZoom(): number;
    setMaxZoom(zoom: number): this;
    getMaxZoom(): number;

    /**
     * 设置源图层
     */
    setSourceLayer(sourceLayer: string): this;
    getSourceLayer(): string;

    /**
     * 设置图层过滤器
     * @param filter 过滤器表达式数组
     */
    setFilter(filter: Object[]): this;
    getFilter(): Object[] | null;
    
    // ==================== 新增属性 ====================
    
    /**
     * 设置栅格淡入淡出持续时间（毫秒）
     * @param duration 持续时间
     */
    setRasterFadeDuration(duration: number): this;
    getRasterFadeDuration(): number | undefined;
    
    /**
     * 设置栅格重采样方式
     * @param resampling 'linear' | 'nearest'
     */
    setRasterResampling(resampling: string): this;
    getRasterResampling(): string | undefined;
}
