/**
 * MapLibre Native for HarmonyOS - RasterLayer Type Definitions
 * 栅格图层 API
 */

/**
 * 重采样方式
 */
export type RasterResampling = 'linear' | 'nearest';

/**
 * 创建栅格图层
 * @param layerId 图层 ID
 * @param sourceId 数据源 ID
 * @returns 图层原生指针
 */
export function create(layerId: string, sourceId: string): number;

/**
 * 设置栅格不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setRasterOpacity(layerPtr: number, opacity: number): void;

/**
 * 设置栅格色相旋转
 * @param layerPtr 图层指针
 * @param hueRotate 色相旋转角度（度，0-360）
 */
export function setRasterHueRotate(layerPtr: number, hueRotate: number): void;

/**
 * 设置栅格最小亮度
 * @param layerPtr 图层指针
 * @param brightnessMin 最小亮度（0.0 - 1.0）
 */
export function setRasterBrightnessMin(layerPtr: number, brightnessMin: number): void;

/**
 * 设置栅格最大亮度
 * @param layerPtr 图层指针
 * @param brightnessMax 最大亮度（0.0 - 1.0）
 */
export function setRasterBrightnessMax(layerPtr: number, brightnessMax: number): void;

/**
 * 设置栅格饱和度
 * @param layerPtr 图层指针
 * @param saturation 饱和度（-1.0 到 1.0，0 为无变化）
 */
export function setRasterSaturation(layerPtr: number, saturation: number): void;

/**
 * 设置栅格对比度
 * @param layerPtr 图层指针
 * @param contrast 对比度（-1.0 到 1.0，0 为无变化）
 */
export function setRasterContrast(layerPtr: number, contrast: number): void;

/**
 * 设置栅格淡入淡出持续时间
 * @param layerPtr 图层指针
 * @param fadeDuration 淡入淡出持续时间（毫秒）
 */
export function setRasterFadeDuration(layerPtr: number, fadeDuration: number): void;

/**
 * 设置栅格重采样方式
 * @param layerPtr 图层指针
 * @param resampling 重采样方式
 */
export function setRasterResampling(layerPtr: number, resampling: RasterResampling): void;

