/**
 * MapLibre Native for HarmonyOS - VectorSource Type Definitions
 * 矢量瓦片数据源 API
 */

/**
 * 从 URL 创建矢量数据源
 * @param id 数据源 ID
 * @param url 瓦片 URL
 * @returns 数据源原生指针
 */
export function createWithUrl(id: string, url: string): number;

/**
 * 从 TileSet 创建矢量数据源
 * @param id 数据源 ID
 * @param tileSetJson TileSet JSON 配置
 * @returns 数据源原生指针
 */
export function createWithTileSet(id: string, tileSetJson: string): number;

/**
 * 查询数据源要素
 * @param sourcePtr 数据源指针
 * @param sourceLayerId 源图层 ID
 * @param filterJson 可选的过滤器 JSON 字符串
 * @returns 要素集合 JSON 字符串
 */
export function querySourceFeatures(sourcePtr: number, sourceLayerId: string, filterJson: string | null): string;

