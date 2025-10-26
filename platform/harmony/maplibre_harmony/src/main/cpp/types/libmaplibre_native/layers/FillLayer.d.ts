/**
 * MapLibre Native for HarmonyOS - FillLayer Type Definitions
 * 填充图层 API
 */

/**
 * 创建填充图层
 * @param layerId 图层 ID
 * @param sourceId 数据源 ID
 * @returns 图层原生指针
 */
export function create(layerId: string, sourceId: string): number;

/**
 * 设置填充颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串，如 "#ff0000" 或 "rgba(255, 0, 0, 1)"）
 */
export function setFillColor(layerPtr: number, color: string): void;

/**
 * 设置填充不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setFillOpacity(layerPtr: number, opacity: number): void;

/**
 * 设置填充轮廓颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setFillOutlineColor(layerPtr: number, color: string): void;

/**
 * 设置填充图案
 * @param layerPtr 图层指针
 * @param pattern 图案名称（需要先通过 addImage 添加）
 */
export function setFillPattern(layerPtr: number, pattern: string): void;

/**
 * 设置填充抗锯齿
 * @param layerPtr 图层指针
 * @param antialias 是否启用抗锯齿
 */
export function setFillAntialias(layerPtr: number, antialias: boolean): void;

/**
 * 设置填充平移
 * @param layerPtr 图层指针
 * @param translate 平移量 [x, y]（单位：像素）
 */
export function setFillTranslate(layerPtr: number, translate: number[]): void;

