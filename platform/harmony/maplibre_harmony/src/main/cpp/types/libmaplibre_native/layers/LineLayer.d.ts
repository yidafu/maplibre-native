/**
 * MapLibre Native for HarmonyOS - LineLayer Type Definitions
 * 线图层 API
 */

/**
 * 线帽类型
 */
export type LineCap = 'butt' | 'round' | 'square';

/**
 * 线连接类型
 */
export type LineJoin = 'bevel' | 'round' | 'miter';

/**
 * 创建线图层
 * @param layerId 图层 ID
 * @param sourceId 数据源 ID
 * @returns 图层原生指针
 */
export function create(layerId: string, sourceId: string): number;

/**
 * 设置线颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setLineColor(layerPtr: number, color: string): void;

/**
 * 设置线宽
 * @param layerPtr 图层指针
 * @param width 线宽（单位：像素）
 */
export function setLineWidth(layerPtr: number, width: number): void;

/**
 * 设置线不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setLineOpacity(layerPtr: number, opacity: number): void;

/**
 * 设置线图案
 * @param layerPtr 图层指针
 * @param pattern 图案名称（需要先通过 addImage 添加）
 */
export function setLinePattern(layerPtr: number, pattern: string): void;

/**
 * 设置线间隙宽度
 * @param layerPtr 图层指针
 * @param gapWidth 间隙宽度（单位：像素）
 */
export function setLineGapWidth(layerPtr: number, gapWidth: number): void;

/**
 * 设置虚线数组
 * @param layerPtr 图层指针
 * @param dasharray 虚线数组，例如 [2, 4] 表示 2 像素实线，4 像素空白
 */
export function setLineDasharray(layerPtr: number, dasharray: number[]): void;

/**
 * 设置线模糊
 * @param layerPtr 图层指针
 * @param blur 模糊量（单位：像素）
 */
export function setLineBlur(layerPtr: number, blur: number): void;

/**
 * 设置线帽样式
 * @param layerPtr 图层指针
 * @param cap 线帽类型
 */
export function setLineCap(layerPtr: number, cap: LineCap): void;

/**
 * 设置线连接样式
 * @param layerPtr 图层指针
 * @param join 线连接类型
 */
export function setLineJoin(layerPtr: number, join: LineJoin): void;

