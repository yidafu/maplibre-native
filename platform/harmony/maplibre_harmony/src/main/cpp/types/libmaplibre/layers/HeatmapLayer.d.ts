/**
 * MapLibre Native for HarmonyOS - HeatmapLayer Type Definitions
 * 热力图层 API (NAPI 类)
 */

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
     * @param radius 半径（单位：像素）
     * @returns 返回 this 以支持链式调用
     */
    setHeatmapRadius(radius: number): this;

    /**
     * 设置热力图强度
     * @param intensity 强度值
     * @returns 返回 this 以支持链式调用
     */
    setHeatmapIntensity(intensity: number): this;

    /**
     * 设置热力图不透明度
     * @param opacity 不透明度（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setHeatmapOpacity(opacity: number): this;

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
