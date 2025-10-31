/**
 * MapLibre Native for HarmonyOS - HeatmapLayer Type Definitions
 * 热力图层 API (NAPI 类)
 */

import type { NumberValue } from '../LayerPropertyTypes';

/**
 * HeatmapLayer - 热力图层
 * 用于渲染密度热力图
 * 
 * Note: 此为简化实现，完整功能待后续补充
 */
export class HeatmapLayer {
    /**
     * 创建热力图层
     * @param layerId 图层 ID
     * @param sourceId 数据源 ID
     */
    constructor(layerId: string, sourceId: string);

    /**
     * 设置热力图半径
     * @param radius 半径或Expression
     */
    setHeatmapRadius(radius: NumberValue): this;

    /**
     * 设置热力图强度
     * @param intensity 强度值或Expression
     */
    setHeatmapIntensity(intensity: NumberValue): this;

    /**
     * 设置热力图不透明度
     * @param opacity 不透明度或Expression（0.0 - 1.0）
     */
    setHeatmapOpacity(opacity: NumberValue): this;

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
     * 设置热力图颜色渐变（仅支持 Expression）
     * 必须使用 heatmap-density 表达式
     * @param color 颜色表达式数组
     */
    setHeatmapColor(color: any[]): this;
    getHeatmapColor(): any[] | undefined;
}
