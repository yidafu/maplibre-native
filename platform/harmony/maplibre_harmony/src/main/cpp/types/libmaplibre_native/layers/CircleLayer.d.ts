/**
 * MapLibre Native for HarmonyOS - CircleLayer Type Definitions
 * 圆形图层 API
 */

/**
 * 创建圆形图层
 * @param layerId 图层 ID
 * @param sourceId 数据源 ID
 * @returns 图层原生指针
 */
export function create(layerId: string, sourceId: string): number;

/**
 * 设置圆形半径
 * @param layerPtr 图层指针
 * @param radius 半径（单位：像素）
 */
export function setCircleRadius(layerPtr: number, radius: number): void;

/**
 * 设置圆形颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setCircleColor(layerPtr: number, color: string): void;

/**
 * 设置圆形不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setCircleOpacity(layerPtr: number, opacity: number): void;

/**
 * 设置圆形模糊
 * @param layerPtr 图层指针
 * @param blur 模糊量（0.0 - 1.0）
 */
export function setCircleBlur(layerPtr: number, blur: number): void;

/**
 * 设置圆形边框宽度
 * @param layerPtr 图层指针
 * @param width 边框宽度（单位：像素）
 */
export function setCircleStrokeWidth(layerPtr: number, width: number): void;

/**
 * 设置圆形边框颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setCircleStrokeColor(layerPtr: number, color: string): void;

/**
 * 设置圆形边框不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setCircleStrokeOpacity(layerPtr: number, opacity: number): void;

