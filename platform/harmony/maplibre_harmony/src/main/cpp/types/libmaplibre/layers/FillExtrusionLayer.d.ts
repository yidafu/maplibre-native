/**
 * MapLibre Native for HarmonyOS - FillExtrusionLayer Type Definitions
 * 3D填充拉伸图层 API (NAPI 类)
 */

/**
 * FillExtrusionLayer - 3D 填充拉伸图层
 * 用于渲染 3D 建筑物等拉伸效果
 * 
 * Note: 此为简化实现，完整功能待后续补充
 */
export class FillExtrusionLayer {
    /**
     * 创建3D填充拉伸图层
     * @param layerId 图层 ID
     * @param sourceId 数据源 ID
     */
    constructor(layerId: string, sourceId: string);

    /**
     * 设置拉伸高度
     * @param height 高度（单位：米）
     * @returns 返回 this 以支持链式调用
     */
    setFillExtrusionHeight(height: number): this;

    /**
     * 设置拉伸基准高度
     * @param base 基准高度（单位：米）
     * @returns 返回 this 以支持链式调用
     */
    setFillExtrusionBase(base: number): this;

    /**
     * 设置拉伸颜色
     * @param color 颜色值（CSS 颜色字符串）
     * @returns 返回 this 以支持链式调用
     */
    setFillExtrusionColor(color: string): this;

    /**
     * 设置拉伸不透明度
     * @param opacity 不透明度（0.0 - 1.0）
     * @returns 返回 this 以支持链式调用
     */
    setFillExtrusionOpacity(opacity: number): this;

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
    
    // ==================== 新增属性 ====================
    
    /**
     * 设置填充挤出平移锚点
     * @param anchor 'map' | 'viewport'
     */
    setFillExtrusionTranslateAnchor(anchor: string): this;
    getFillExtrusionTranslateAnchor(): string | undefined;
}
