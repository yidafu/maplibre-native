/**
 * MapLibre Native for HarmonyOS - FillExtrusionLayer Type Definitions
 * 3D 填充拉伸图层 API
 */

/**
 * 创建 3D 填充拉伸图层
 * @param layerId 图层 ID
 * @param sourceId 数据源 ID
 * @returns 图层原生指针
 */
export function create(layerId: string, sourceId: string): number;

/**
 * 设置拉伸不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setFillExtrusionOpacity(layerPtr: number, opacity: number): void;

/**
 * 设置拉伸颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setFillExtrusionColor(layerPtr: number, color: string): void;

/**
 * 设置拉伸平移
 * @param layerPtr 图层指针
 * @param translate 平移量 [x, y]（单位：像素）
 */
export function setFillExtrusionTranslate(layerPtr: number, translate: number[]): void;

/**
 * 设置拉伸图案
 * @param layerPtr 图层指针
 * @param pattern 图案名称（需要先通过 addImage 添加）
 */
export function setFillExtrusionPattern(layerPtr: number, pattern: string): void;

/**
 * 设置拉伸高度
 * @param layerPtr 图层指针
 * @param height 高度（单位：米）
 */
export function setFillExtrusionHeight(layerPtr: number, height: number): void;

/**
 * 设置拉伸基础高度
 * @param layerPtr 图层指针
 * @param base 基础高度（单位：米）
 */
export function setFillExtrusionBase(layerPtr: number, base: number): void;

/**
 * 设置垂直渐变
 * @param layerPtr 图层指针
 * @param verticalGradient 是否启用垂直渐变
 */
export function setFillExtrusionVerticalGradient(layerPtr: number, verticalGradient: boolean): void;

