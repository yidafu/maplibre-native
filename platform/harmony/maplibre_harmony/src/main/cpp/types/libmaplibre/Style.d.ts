/**
 * MapLibre Native for HarmonyOS - Style API Type Definitions
 * 地图样式管理 API (NAPI 对象)
 * 
 * 重构为面向对象接口，与 Android/iOS 架构保持一致
 */

import type { Layer } from './layers';
import type { Source } from './sources';
import type { Image } from './images/Image';

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
     * @param source 数据源对象（GeoJsonSource、VectorSource、RasterSource 等 NAPI 对象）
     */
    addSource(source: Source): void;

    /**
     * 移除数据源
     * @param sourceId 数据源 ID
     * @returns 是否成功
     */
    removeSource(sourceId: string): boolean;

    /**
     * 获取指定数据源
     * @param sourceId 数据源 ID
     * @returns 数据源对象（GeoJsonSource、VectorSource 等），如果不存在则返回 null
     */
    getSource(sourceId: string): Source | null;

    /**
     * 获取所有数据源
     * @returns 数据源数组（包含所有已添加的数据源）
     */
    getSources(): Source[];

    // ========== 图层管理 ==========

    /**
     * 添加图层（添加到顶部）
     * @param layer 图层对象（FillLayer、LineLayer、CircleLayer 等 NAPI 对象）
     */
    addLayer(layer: Layer): void;

    /**
     * 在指定图层下方添加图层
     * @param layer 图层对象（FillLayer、LineLayer、CircleLayer 等 NAPI 对象）
     * @param belowLayerId 参考图层 ID（新图层将添加到此图层下方）
     */
    addLayerBelow(layer: Layer, belowLayerId: string): void;

    /**
     * 在指定图层上方添加图层
     * @param layer 图层对象（FillLayer、LineLayer、CircleLayer 等 NAPI 对象）
     * @param aboveLayerId 参考图层 ID（新图层将添加到此图层上方）
     */
    addLayerAbove(layer: Layer, aboveLayerId: string): void;

    /**
     * 在指定索引位置添加图层
     * @param layer 图层对象（FillLayer、LineLayer、CircleLayer 等 NAPI 对象）
     * @param index 索引位置
     */
    addLayerAt(layer: Layer, index: number): void;

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
     * @returns 图层对象（FillLayer、LineLayer 等），如果不存在则返回 null
     */
    getLayer(layerId: string): Layer | null;

    /**
     * 获取所有图层
     * @returns 图层数组（包含所有已添加的图层）
     */
    getLayers(): Layer[];

    // ========== 图像管理 ==========

    /**
     * 添加图像到样式
     * @param name 图像名称
     * @param imageData 图像数据（ArrayBuffer 或 Uint8Array，RGBA 格式）
     * @param width 图像宽度（像素）
     * @param height 图像高度（像素）
     * @param sdf 是否为 SDF (Signed Distance Field) 图像，默认 false
     */
    addImage(name: string, imageData: ArrayBuffer | Uint8Array, width: number, height: number, sdf?: boolean): void;

    /**
     * 从样式中移除图像
     * @param name 图像名称
     * @returns 是否成功移除
     */
    removeImage(name: string): boolean;

    /**
     * 获取图像对象
     * @param name 图像名称
     * @returns 图像对象，如果不存在则返回 null
     */
    getImage(name: string): Image | null;

    // ========== 光照管理 ==========

    /**
     * 获取光照设置
     * @returns 光照配置对象（包含 anchor、position、color 等属性），如果不存在则返回 null
     */
    getLight(): object | null;

    /**
     * 设置光照
     * @param lightJson 光照 JSON 配置字符串
     */
    setLight(lightJson: string): void;

    // ========== 过渡效果管理 ==========

    /**
     * 获取过渡效果设置
     * @returns 过渡选项对象（包含 duration、delay 等属性），如果不存在则返回 null
     */
    getTransition(): { duration?: number; delay?: number } | null;

    /**
     * 设置过渡效果
     * @param transitionJson 过渡效果 JSON 配置字符串
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
     * @param source 数据源对象（GeoJsonSource、VectorSource、RasterSource 等）
     * @returns this 支持链式调用
     */
    withSource(source: Source): this;

    /**
     * 添加图层（样式加载完成后添加）
     * @param layer 图层对象（FillLayer、LineLayer、CircleLayer 等）
     * @returns this 支持链式调用
     */
    withLayer(layer: Layer): this;

    /**
     * 添加图像（样式加载完成后添加）
     * @param image 图像对象（包含名称、数据等完整信息）
     * @returns this 支持链式调用
     */
    withImage(image: Image): this;

    /**
     * 设置过渡选项
     * @param options 过渡选项对象（包含 duration、delay 等属性）
     * @returns this 支持链式调用
     */
    withTransitionOptions(options: { duration?: number; delay?: number }): this;
}

