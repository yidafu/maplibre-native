/**
 * MapLibre Native for HarmonyOS - FillLayer Type Definitions
 * 填充图层 API (NAPI 类)
 */

import type { PropertyValue, ColorValue, NumberValue, BooleanValue } from '../LayerPropertyTypes';

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
     * @param color 颜色值或Expression
     */
    setFillColor(color: ColorValue): this;

    /**
     * 设置填充不透明度
     * @param opacity 不透明度或Expression（0.0 - 1.0）
     */
    setFillOpacity(opacity: NumberValue): this;

    /**
     * 设置填充轮廓颜色
     * @param color 颜色值或Expression
     */
    setFillOutlineColor(color: ColorValue): this;

    /**
     * 设置填充图案
     * @param pattern 图案名称或Expression
     */
    setFillPattern(pattern: PropertyValue<string>): this;

    /**
     * 设置填充抗锯齿
     * @param antialias 是否启用抗锯齿或Expression
     */
    setFillAntialias(antialias: BooleanValue): this;

    /**
     * 设置填充平移
     * @param translate 平移量或Expression
     */
    setFillTranslate(translate: PropertyValue<number[]>): this;

    /**
     * 获取填充颜色
     */
    getFillColor(): string | undefined;

    /**
     * 获取填充不透明度
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
     * @param visibility 可见性
     */
    setVisibility(visibility: 'visible' | 'none'): this;
    getVisibility(): 'visible' | 'none';

    /**
     * 设置最小缩放级别
     */
    setMinZoom(zoom: number): this;
    getMinZoom(): number;

    /**
     * 设置最大缩放级别
     */
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
    
    /**
     * 设置填充平移锚点
     * @param anchor 'map' | 'viewport' 或Expression
     */
    setFillTranslateAnchor(anchor: PropertyValue<string>): this;
    getFillTranslateAnchor(): string | undefined;
    
    /**
     * 设置填充排序键
     * @param sortKey 排序键或Expression
     */
    setFillSortKey(sortKey: NumberValue): this;
    getFillSortKey(): number | undefined;
}
