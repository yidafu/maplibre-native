/**
 * MapLibre Native for HarmonyOS - GeoJsonSource Type Definitions
 * GeoJSON 数据源 API
 */

/**
 * 创建 GeoJSON 数据源
 * @param id 数据源 ID
 * @param optionsJson 可选的配置 JSON 字符串
 * @returns 数据源原生指针
 */
export function create(id: string, optionsJson: string | null): number;

/**
 * 设置 GeoJSON 数据（异步）
 * @param sourcePtr 数据源指针
 * @param geoJsonString GeoJSON 字符串
 */
export function setGeoJson(sourcePtr: number, geoJsonString: string): void;

/**
 * 设置 GeoJSON 数据（同步）
 * @param sourcePtr 数据源指针
 * @param geoJsonString GeoJSON 字符串
 */
export function setGeoJsonSync(sourcePtr: number, geoJsonString: string): void;

/**
 * 设置数据 URL
 * @param sourcePtr 数据源指针
 * @param url 数据 URL
 */
export function setUrl(sourcePtr: number, url: string): void;

/**
 * 获取数据 URL
 * @param sourcePtr 数据源指针
 * @returns 数据 URL
 */
export function getUrl(sourcePtr: number): string;

/**
 * 查询数据源要素
 * @param sourcePtr 数据源指针
 * @param filterJson 可选的过滤器 JSON 字符串
 * @returns 要素集合 JSON 字符串
 */
export function querySourceFeatures(sourcePtr: number, filterJson: string | null): string;

/**
 * 获取聚类的子节点
 * @param sourcePtr 数据源指针
 * @param clusterJson 聚类 JSON 字符串
 * @returns 子节点要素集合 JSON 字符串
 */
export function getClusterChildren(sourcePtr: number, clusterJson: string): string;

/**
 * 获取聚类的叶子节点
 * @param sourcePtr 数据源指针
 * @param clusterJson 聚类 JSON 字符串
 * @param limit 返回数量限制
 * @param offset 偏移量
 * @returns 叶子节点要素集合 JSON 字符串
 */
export function getClusterLeaves(sourcePtr: number, clusterJson: string, limit: number, offset: number): string;

/**
 * 获取聚类展开的缩放级别
 * @param sourcePtr 数据源指针
 * @param clusterJson 聚类 JSON 字符串
 * @returns 展开缩放级别
 */
export function getClusterExpansionZoom(sourcePtr: number, clusterJson: string): number;

