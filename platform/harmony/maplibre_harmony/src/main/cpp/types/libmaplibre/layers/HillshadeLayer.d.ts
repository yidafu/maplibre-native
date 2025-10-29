/**
 * MapLibre Native for HarmonyOS - HillshadeLayer Type Definitions
 * 山体阴影图层 API (NAPI 类)
 */

/**
 * HillshadeLayer - 山体阴影图层
 * 用于渲染地形阴影效果
 * 
 * Note: 此为简化实现，完整功能待后续补充
 */
export class HillshadeLayer {
    /**
     * 创建山体阴影图层
     * @param layerId 图层 ID
     * @param sourceId 数据源 ID
     */
    constructor(layerId: string, sourceId: string);

    /**
     * 设置光照方向
     * @param direction 光照方向角度（0-359 度）
     * @returns 返回 this 以支持链式调用
     */
    setHillshadeIlluminationDirection(direction: number): this;

    /**
     * 设置夸张程度
     * @param exaggeration 夸张系数（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setHillshadeExaggeration(exaggeration: number): this;

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
