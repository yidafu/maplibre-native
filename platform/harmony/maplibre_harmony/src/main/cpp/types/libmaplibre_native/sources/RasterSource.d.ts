/**
 * MapLibre Native for HarmonyOS - RasterSource Type Definitions
 * 栅格瓦片数据源 API
 */

/**
 * 从 URL 创建栅格数据源
 * @param id 数据源 ID
 * @param url 瓦片 URL
 * @param tileSize 瓦片大小（像素）
 * @returns 数据源原生指针
 */
export function createWithUrl(id: string, url: string, tileSize: number): number;

/**
 * 从 TileSet 创建栅格数据源
 * @param id 数据源 ID
 * @param tileSetJson TileSet JSON 配置
 * @param tileSize 瓦片大小（像素）
 * @returns 数据源原生指针
 */
export function createWithTileSet(id: string, tileSetJson: string, tileSize: number): number;

