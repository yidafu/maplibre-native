/**
 * MapLibre Native for HarmonyOS - RasterDemSource Type Definitions
 * 栅格 DEM（数字高程模型）数据源 API
 */

/**
 * DEM 编码类型
 */
export type DemEncoding = 'mapbox' | 'terrarium';

/**
 * 从 URL 创建栅格 DEM 数据源
 * @param id 数据源 ID
 * @param url 瓦片 URL
 * @param encoding DEM 编码类型
 * @returns 数据源原生指针
 */
export function createWithUrl(id: string, url: string, encoding: DemEncoding): number;

/**
 * 从 TileSet 创建栅格 DEM 数据源
 * @param id 数据源 ID
 * @param tileSetJson TileSet JSON 配置
 * @param encoding DEM 编码类型
 * @returns 数据源原生指针
 */
export function createWithTileSet(id: string, tileSetJson: string, encoding: DemEncoding): number;

