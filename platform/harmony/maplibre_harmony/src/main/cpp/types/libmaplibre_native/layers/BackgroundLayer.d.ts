/**
 * MapLibre Native for HarmonyOS - BackgroundLayer Type Definitions
 * 背景图层 API
 */

/**
 * 创建背景图层
 * @param layerId 图层 ID
 * @returns 图层原生指针
 */
export function create(layerId: string): number;

/**
 * 设置背景颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setBackgroundColor(layerPtr: number, color: string): void;

/**
 * 设置背景不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setBackgroundOpacity(layerPtr: number, opacity: number): void;

/**
 * 设置背景图案
 * @param layerPtr 图层指针
 * @param pattern 图案名称（需要先通过 addImage 添加）
 */
export function setBackgroundPattern(layerPtr: number, pattern: string): void;

