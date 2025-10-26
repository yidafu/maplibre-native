/**
 * MapLibre Native for HarmonyOS - HillshadeLayer Type Definitions
 * 山体阴影图层 API
 */

/**
 * 光照锚点类型
 */
export type IlluminationAnchor = 'map' | 'viewport';

/**
 * 创建山体阴影图层
 * @param layerId 图层 ID
 * @param sourceId 数据源 ID
 * @returns 图层原生指针
 */
export function create(layerId: string, sourceId: string): number;

/**
 * 设置光照方向
 * @param layerPtr 图层指针
 * @param direction 光照方向（度，0-359，0 为正北）
 */
export function setHillshadeIlluminationDirection(layerPtr: number, direction: number): void;

/**
 * 设置光照锚点
 * @param layerPtr 图层指针
 * @param anchor 锚点类型
 */
export function setHillshadeIlluminationAnchor(layerPtr: number, anchor: IlluminationAnchor): void;

/**
 * 设置夸张程度
 * @param layerPtr 图层指针
 * @param exaggeration 夸张程度（0.0 - 1.0）
 */
export function setHillshadeExaggeration(layerPtr: number, exaggeration: number): void;

/**
 * 设置阴影颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setHillshadeShadowColor(layerPtr: number, color: string): void;

/**
 * 设置高光颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setHillshadeHighlightColor(layerPtr: number, color: string): void;

/**
 * 设置强调颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setHillshadeAccentColor(layerPtr: number, color: string): void;

