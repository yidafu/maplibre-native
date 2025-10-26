/**
 * MapLibre Native for HarmonyOS - Style API Type Definitions
 * 地图样式管理 API
 */

/**
 * 样式 API 命名空间
 * 提供地图样式、数据源、图层、图像、光照和过渡效果的管理功能
 */
export namespace Style {
    /**
     * 获取样式 URI
     * @param mapPtr 地图指针
     * @returns 样式 URI
     */
    export function getStyleUri(mapPtr: number): string;

    /**
     * 获取样式 JSON
     * @param mapPtr 地图指针
     * @returns 样式 JSON 字符串
     */
    export function getStyleJson(mapPtr: number): string;

    // ========== 数据源管理 ==========

    /**
     * 添加数据源
     * @param mapPtr 地图指针
     * @param sourceId 数据源 ID
     * @param sourceJson 数据源 JSON 配置
     * @param sourceNativePtr 数据源原生指针
     * @returns 是否成功
     */
    export function addSource(mapPtr: number, sourceId: string, sourceJson: string, sourceNativePtr: number): boolean;

    /**
     * 移除数据源
     * @param mapPtr 地图指针
     * @param sourceId 数据源 ID
     * @returns 是否成功
     */
    export function removeSource(mapPtr: number, sourceId: string): boolean;

    /**
     * 获取指定数据源
     * @param mapPtr 地图指针
     * @param sourceId 数据源 ID
     * @returns 数据源 JSON 字符串，如果不存在则返回 null
     */
    export function getSource(mapPtr: number, sourceId: string): string | null;

    /**
     * 获取所有数据源
     * @param mapPtr 地图指针
     * @returns 数据源列表 JSON 字符串
     */
    export function getSources(mapPtr: number): string;

    // ========== 图层管理 ==========

    /**
     * 添加图层（添加到顶部）
     * @param mapPtr 地图指针
     * @param layerId 图层 ID
     * @param layerJson 图层 JSON 配置
     * @param layerNativePtr 图层原生指针
     * @returns 是否成功
     */
    export function addLayer(mapPtr: number, layerId: string, layerJson: string, layerNativePtr: number): boolean;

    /**
     * 在指定图层下方添加图层
     * @param mapPtr 地图指针
     * @param layerId 图层 ID
     * @param layerJson 图层 JSON 配置
     * @param layerNativePtr 图层原生指针
     * @param belowLayerId 参考图层 ID（新图层将添加到此图层下方）
     * @returns 是否成功
     */
    export function addLayerBelow(mapPtr: number, layerId: string, layerJson: string, layerNativePtr: number, belowLayerId: string): boolean;

    /**
     * 在指定图层上方添加图层
     * @param mapPtr 地图指针
     * @param layerId 图层 ID
     * @param layerJson 图层 JSON 配置
     * @param layerNativePtr 图层原生指针
     * @param aboveLayerId 参考图层 ID（新图层将添加到此图层上方）
     * @returns 是否成功
     */
    export function addLayerAbove(mapPtr: number, layerId: string, layerJson: string, layerNativePtr: number, aboveLayerId: string): boolean;

    /**
     * 在指定索引位置添加图层
     * @param mapPtr 地图指针
     * @param layerId 图层 ID
     * @param layerJson 图层 JSON 配置
     * @param layerNativePtr 图层原生指针
     * @param index 索引位置
     * @returns 是否成功
     */
    export function addLayerAt(mapPtr: number, layerId: string, layerJson: string, layerNativePtr: number, index: number): boolean;

    /**
     * 移除指定图层
     * @param mapPtr 地图指针
     * @param layerId 图层 ID
     * @returns 是否成功
     */
    export function removeLayer(mapPtr: number, layerId: string): boolean;

    /**
     * 移除指定索引位置的图层
     * @param mapPtr 地图指针
     * @param index 索引位置
     * @returns 是否成功
     */
    export function removeLayerAt(mapPtr: number, index: number): boolean;

    /**
     * 获取指定图层
     * @param mapPtr 地图指针
     * @param layerId 图层 ID
     * @returns 图层 JSON 字符串，如果不存在则返回 null
     */
    export function getLayer(mapPtr: number, layerId: string): string | null;

    /**
     * 获取所有图层
     * @param mapPtr 地图指针
     * @returns 图层列表 JSON 字符串
     */
    export function getLayers(mapPtr: number): string;

    // ========== 图像管理 ==========

    /**
     * 添加图像
     * @param mapPtr 地图指针
     * @param name 图像名称
     * @param imageData 图像数据
     * @param width 图像宽度
     * @param height 图像高度
     * @param sdf 是否为 SDF (Signed Distance Field) 图像
     * @returns 是否成功
     */
    export function addImage(mapPtr: number, name: string, imageData: any, width: number, height: number, sdf: boolean): boolean;

    /**
     * 移除图像
     * @param mapPtr 地图指针
     * @param name 图像名称
     * @returns 是否成功
     */
    export function removeImage(mapPtr: number, name: string): boolean;

    /**
     * 获取图像
     * @param mapPtr 地图指针
     * @param name 图像名称
     * @returns 图像数据，如果不存在则返回 null
     */
    export function getImage(mapPtr: number, name: string): any | null;

    // ========== 光照管理 ==========

    /**
     * 获取光照设置
     * @param mapPtr 地图指针
     * @returns 光照 JSON 字符串，如果不存在则返回 null
     */
    export function getLight(mapPtr: number): string | null;

    /**
     * 设置光照
     * @param mapPtr 地图指针
     * @param lightJson 光照 JSON 配置
     * @returns 是否成功
     */
    export function setLight(mapPtr: number, lightJson: string): boolean;

    // ========== 过渡效果管理 ==========

    /**
     * 获取过渡效果设置
     * @param mapPtr 地图指针
     * @returns 过渡效果 JSON 字符串，如果不存在则返回 null
     */
    export function getTransition(mapPtr: number): string | null;

    /**
     * 设置过渡效果
     * @param mapPtr 地图指针
     * @param transitionJson 过渡效果 JSON 配置
     * @returns 是否成功
     */
    export function setTransition(mapPtr: number, transitionJson: string): boolean;
}

