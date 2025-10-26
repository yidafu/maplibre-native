/**
 * MapLibre Native for HarmonyOS - HeatmapLayer Type Definitions
 * 热力图层 API
 */

/**
 * 创建热力图层
 * @param layerId 图层 ID
 * @param sourceId 数据源 ID
 * @returns 图层原生指针
 */
export function create(layerId: string, sourceId: string): number;

/**
 * 设置热力图半径
 * @param layerPtr 图层指针
 * @param radius 半径（单位：像素）
 */
export function setHeatmapRadius(layerPtr: number, radius: number): void;

/**
 * 设置热力图权重
 * @param layerPtr 图层指针
 * @param weight 权重（0.0 - 1.0）
 */
export function setHeatmapWeight(layerPtr: number, weight: number): void;

/**
 * 设置热力图强度
 * @param layerPtr 图层指针
 * @param intensity 强度倍数
 */
export function setHeatmapIntensity(layerPtr: number, intensity: number): void;

/**
 * 设置热力图颜色
 * @param layerPtr 图层指针
 * @param color 颜色表达式（如渐变色）
 */
export function setHeatmapColor(layerPtr: number, color: string): void;

/**
 * 设置热力图不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setHeatmapOpacity(layerPtr: number, opacity: number): void;

