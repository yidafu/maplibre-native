/**
 * OfflineRegionDefinition - 离线区域定义
 * 
 * 定义离线地图区域的范围和参数
 */
import { LatLngBounds } from '../geometry/LatLngBounds';
import { Geometry } from '../geojson';
import maplibre from 'libmaplibre_native.so';

/**
 * 边界对象接口（用于内部转换）
 */
interface BoundsObject {
  north: number;
  east: number;
  south: number;
  west: number;
}

/**
 * 离线区域定义类型（匹配 .d.ts 定义）
 */
export type OfflineRegionDefinition = 
  maplibre.OfflineTilePyramidRegionDefinition 
  | maplibre.OfflineGeometryRegionDefinition;

/**
 * 基于瓦片金字塔的离线区域定义（匹配 .d.ts 定义）
 */
export type OfflineTilePyramidRegionDefinition = maplibre.OfflineTilePyramidRegionDefinition;

/**
 * 基于几何体的离线区域定义（匹配 .d.ts 定义）
 */
export type OfflineGeometryRegionDefinition = maplibre.OfflineGeometryRegionDefinition;

/**
 * 创建瓦片金字塔区域定义
 */
export function createTilePyramidRegionDefinition(
  styleURL: string,
  bounds: LatLngBounds,
  minZoom: number,
  maxZoom: number,
  pixelRatio: number = 1.0,
  includeIdeographs: boolean = true
): maplibre.OfflineTilePyramidRegionDefinition {
  const boundsObj: BoundsObject = {
    north: bounds.north,
    east: bounds.east,
    south: bounds.south,
    west: bounds.west
  };
  
  return {
    type: 'tilePyramid',
    styleURL,
    bounds: boundsObj,
    minZoom,
    maxZoom,
    pixelRatio,
    includeIdeographs
  };
}

/**
 * 创建几何体区域定义
 */
export function createGeometryRegionDefinition(
  styleURL: string,
  geometry: Geometry,
  minZoom: number,
  maxZoom: number,
  pixelRatio: number = 1.0,
  includeIdeographs: boolean = true
): maplibre.OfflineGeometryRegionDefinition {
  return {
    type: 'geometry',
    styleURL,
    geometry,
    minZoom,
    maxZoom,
    pixelRatio,
    includeIdeographs
  };
}

