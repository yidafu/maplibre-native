/**
 * MapLibre Native for HarmonyOS - Type Definitions
 * 主入口文件
 *
 * 此文件重新导出所有类型定义，提供统一的访问入口
 */

// ========== 核心组件 ==========

/**
 * LatLng - 经纬度坐标接口
 * 注意：已改为 ETS 层实现，这里仅作为类型定义导出
 */
export { LatLng } from './NativeMapView';

/**
 * NativeMapView - 地图视图主类
 * 提供地图渲染、相机控制、图层管理等核心功能
 */
export * from './NativeMapView';

/**
 * Marker - 地图标记点
 * 表示地图上的一个点标注，由 C++ NAPI 层实现
 */
export { Marker, MarkerOptions } from './Marker';

/**
 * Polygon - 多边形标注
 * 表示地图上的多边形标注，由 C++ NAPI 层实现
 */
export { Polygon } from './annotations/Polygon';

/**
 * Polyline - 折线标注
 * 表示地图上的折线标注，由 C++ NAPI 层实现
 */
export { Polyline } from './annotations/Polyline';

/**
 * Icon - 图标类
 * 表示地图标注的图标，由 C++ NAPI 层实现
 * 包含图标的位图数据和元信息
 */
export { Icon } from './Icon';

/**
 * IconFactory - 图标工厂类（静态工厂方法）
 * 提供零复制的高性能图标创建方法，由 C++ NAPI 层实现
 */
export { IconFactory } from './IconFactory';

/**
 * Style - 样式管理类 (NAPI 对象)
 * 提供面向对象的样式管理接口
 *
 * StyleBuilder - 样式构建器
 * 使用 Builder 模式构建地图样式
 */
export { Style, StyleBuilder } from './Style';

// ========== GeoJSON 类型 (NAPI 类) ==========

/**
 * GeoJSON 类型
 * 所有 GeoJSON 几何体和特征类型都由 C++ NAPI 层实现
 */
export * from './geojson';

// ========== 属性值类型 ==========

/**
 * Expression 类型定义
 * 包含：ExpressionLiteral、ExpressionValue 以及所有具体的表达式类型
 * （ComparisonExpression、LogicalExpression、MathExpression 等）
 */
export * from './ExpressionTypes';

/**
 * Layer 属性值类型
 * 包含：PropertyValue、ColorValue、NumberValue、StringValue、BooleanValue
 */
export * from './LayerPropertyTypes';

// ========== 数据源 (Sources) - NAPI 类 ==========

/**
 * 所有数据源类型和联合类型
 * 包含：GeoJsonSource、VectorSource、RasterSource、RasterDemSource、ImageSource
 * 以及联合类型 Source 和对应的 Options 接口
 */
export * from './sources';

/**
 * Image - 样式图像类（NAPI 对象）
 * 用于在地图样式中添加自定义图片资源
 */
export { Image, ImageOptions } from './images/Image';

// ========== 图层 (Layers) ==========

/**
 * 所有图层类型和联合类型
 * 包含：FillLayer、LineLayer、CircleLayer、SymbolLayer、BackgroundLayer、
 *       RasterLayer、HeatmapLayer、HillshadeLayer、FillExtrusionLayer
 * 以及联合类型 Layer
 */
export * from './layers';

// ========== 离线地图 (Offline) ==========

/**
 * OfflineManager - 离线地图管理器
 * OfflineRegion - 离线区域
 * 离线地图下载、管理和使用功能
 */
export * from './offline';

// ========== 通用类型 (Common Types) ==========

/**
 * CommonTypes - 通用类型定义
 * LightSpecification - 光照配置规范
 * TransitionOptions - 过渡动画选项
 * MapSnapshotterObserver - 快照器观察者接口
 * JSONValue/JSONObject - JSON 类型
 */
export * from './CommonTypes';

// ========== 网络配置 (Network Configuration) ==========

/**
 * 设置自定义HTTP请求头（替换所有现有请求头）
 * @param headers - 请求头键值对对象
 */
export function setCustomHttpHeaders(headers: Record<string, string>): void;

/**
 * 添加单个自定义HTTP请求头
 * @param key - 请求头名称
 * @param value - 请求头值
 */
export function addCustomHttpHeader(key: string, value: string): void;

/**
 * 移除指定的自定义HTTP请求头
 * @param key - 请求头名称
 * @returns 如果成功移除返回true，否则返回false
 */
export function removeCustomHttpHeader(key: string): boolean;

/**
 * 清除所有自定义HTTP请求头
 */
export function clearCustomHttpHeaders(): void;

/**
 * 获取所有自定义HTTP请求头
 * @returns 请求头键值对对象
 */
export function getCustomHttpHeaders(): Record<string, string>;

/**
 * 设置资源URL转换回调
 * @param callback - URL转换回调函数
 */
export function setResourceTransformCallback(callback: (kind: number, url: string) => string): void;

/**
 * 清除资源URL转换回调
 */
export function clearResourceTransformCallback(): void;

/**
 * 检查是否设置了URL转换回调
 * @returns 如果设置了回调返回true，否则返回false
 */
export function hasResourceTransformCallback(): boolean;

// ========== 全局配置 (Global Configuration) ==========

/**
 * 设置 Access Token（用于 Mapbox、MapTiler 等服务）
 * @param token - API Key / Access Token
 */
export function setAccessToken(token: string): void;

/**
 * 获取当前配置的 Access Token
 * @returns 当前的 API Key / Access Token
 */
export function getAccessToken(): string;

/**
 * 使用 Mapbox 瓦片服务器配置
 * 配置后支持使用 mapbox:// 协议的 URL
 */
export function useMapboxConfiguration(): void;

/**
 * 使用 MapTiler 瓦片服务器配置
 * 配置后支持使用 maptiler:// 协议的 URL
 */
export function useMapTilerConfiguration(): void;

/**
 * 使用 MapLibre 默认瓦片服务器配置（开源，无需 token）
 * 配置后支持使用 maplibre:// 协议的 URL
 */
export function useMapLibreConfiguration(): void;

/**
 * 设置自定义 API Base URL
 * @param url - 基础 URL（如 https://api.example.com）
 */
export function setApiBaseURL(url: string): void;

/**
 * 获取当前 API Base URL
 * @returns 当前配置的基础 URL
 */
export function getApiBaseURL(): string;
