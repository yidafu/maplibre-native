/**
 * MapLibre Native for HarmonyOS - Style API Type Definitions
 * 地图样式管理 API (NAPI 对象)
 * 
 * 重构为面向对象接口，与 Android/iOS 架构保持一致
 */

/**
 * Style - 地图样式管理类
 * 
 * 通过 MapLibreMap.getStyle() 获取实例
 * 不应该直接构造此类
 */
export class Style {
    /**
     * 获取样式 URI
     * @returns 样式 URI
     */
    getUri(): string;

    /**
     * 获取样式 JSON
     * @returns 样式 JSON 字符串
     */
    getJson(): string;

    /**
     * 样式是否完全加载
     * @returns true 如果样式已加载完成
     */
    isFullyLoaded(): boolean;

    // ========== 数据源管理 ==========

    /**
     * 添加数据源
     * @param sourceId 数据源 ID
     * @param sourceJson 数据源 JSON 配置
     * @param sourceNativePtr 数据源原生指针
     */
    addSource(sourceId: string, sourceJson: string, sourceNativePtr: number): void;

    /**
     * 移除数据源
     * @param sourceId 数据源 ID
     * @returns 是否成功
     */
    removeSource(sourceId: string): boolean;

    /**
     * 获取指定数据源
     * @param sourceId 数据源 ID
     * @returns 数据源对象，如果不存在则返回 null
     */
    getSource(sourceId: string): any | null;

    /**
     * 获取所有数据源
     * @returns 数据源列表
     */
    getSources(): any[];

    // ========== 图层管理 ==========

    /**
     * 添加图层（添加到顶部）
     * @param layerId 图层 ID
     * @param layerJson 图层 JSON 配置
     * @param layerNativePtr 图层原生指针
     */
    addLayer(layerId: string, layerJson: string, layerNativePtr: number): void;

    /**
     * 在指定图层下方添加图层
     * @param layerId 图层 ID
     * @param layerJson 图层 JSON 配置
     * @param layerNativePtr 图层原生指针
     * @param belowLayerId 参考图层 ID（新图层将添加到此图层下方）
     */
    addLayerBelow(layerId: string, layerJson: string, layerNativePtr: number, belowLayerId: string): void;

    /**
     * 在指定图层上方添加图层
     * @param layerId 图层 ID
     * @param layerJson 图层 JSON 配置
     * @param layerNativePtr 图层原生指针
     * @param aboveLayerId 参考图层 ID（新图层将添加到此图层上方）
     */
    addLayerAbove(layerId: string, layerJson: string, layerNativePtr: number, aboveLayerId: string): void;

    /**
     * 在指定索引位置添加图层
     * @param layerId 图层 ID
     * @param layerJson 图层 JSON 配置
     * @param layerNativePtr 图层原生指针
     * @param index 索引位置
     */
    addLayerAt(layerId: string, layerJson: string, layerNativePtr: number, index: number): void;

    /**
     * 移除指定图层
     * @param layerId 图层 ID
     * @returns 是否成功
     */
    removeLayer(layerId: string): boolean;

    /**
     * 移除指定索引位置的图层
     * @param index 索引位置
     * @returns 是否成功
     */
    removeLayerAt(index: number): boolean;

    /**
     * 获取指定图层
     * @param layerId 图层 ID
     * @returns 图层对象，如果不存在则返回 null
     */
    getLayer(layerId: string): any | null;

    /**
     * 获取所有图层
     * @returns 图层列表
     */
    getLayers(): any[];

    // ========== 图像管理 ==========

    /**
     * 添加图像
     * @param name 图像名称
     * @param imageData 图像数据
     * @param width 图像宽度
     * @param height 图像高度
     * @param sdf 是否为 SDF (Signed Distance Field) 图像
     */
    addImage(name: string, imageData: any, width: number, height: number, sdf?: boolean): void;

    /**
     * 移除图像
     * @param name 图像名称
     * @returns 是否成功
     */
    removeImage(name: string): boolean;

    /**
     * 获取图像
     * @param name 图像名称
     * @returns 图像数据，如果不存在则返回 null
     */
    getImage(name: string): any | null;

    // ========== 光照管理 ==========

    /**
     * 获取光照设置
     * @returns 光照对象，如果不存在则返回 null
     */
    getLight(): any | null;

    /**
     * 设置光照
     * @param lightJson 光照 JSON 配置
     */
    setLight(lightJson: string): void;

    // ========== 过渡效果管理 ==========

    /**
     * 获取过渡效果设置
     * @returns 过渡效果对象，如果不存在则返回 null
     */
    getTransition(): any | null;

    /**
     * 设置过渡效果
     * @param transitionJson 过渡效果 JSON 配置
     */
    setTransition(transitionJson: string): void;
}

/**
 * StyleBuilder - 样式构建器
 * 
 * 使用 Builder 模式构建地图样式
 * 
 * @example
 * ```typescript
 * const builder = new maplibre.StyleBuilder()
 *     .fromUri("https://demotiles.maplibre.org/style.json")
 *     .withSource(mySource)
 *     .withLayer(myLayer);
 * mapLibreMap.setStyle(builder);
 * ```
 */
export class StyleBuilder {
    /**
     * 构造一个新的样式构建器
     */
    constructor();

    /**
     * 从 URI 加载样式
     * 
     * URI 可以是：
     * - http://... 或 https://... - 从网络加载
     * - file://... - 从本地文件加载
     * - resource://... - 从资源文件加载
     * 
     * @param uri 样式 URI
     * @returns this 支持链式调用
     */
    fromUri(uri: string): this;

    /**
     * 从 JSON 字符串加载样式
     * @param json 样式 JSON 字符串
     * @returns this 支持链式调用
     */
    fromJson(json: string): this;

    /**
     * 添加数据源（样式加载完成后添加）
     * @param source 数据源对象
     * @returns this 支持链式调用
     */
    withSource(source: any): this;

    /**
     * 添加图层（样式加载完成后添加）
     * @param layer 图层对象
     * @returns this 支持链式调用
     */
    withLayer(layer: any): this;

    /**
     * 添加图像（样式加载完成后添加）
     * @param name 图像名称
     * @param image 图像对象
     * @returns this 支持链式调用
     */
    withImage(name: string, image: any): this;

    /**
     * 设置过渡选项
     * @param options 过渡选项
     * @returns this 支持链式调用
     */
    withTransitionOptions(options: any): this;
}

