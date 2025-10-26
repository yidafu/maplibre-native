/**
 * MapLibre Native for HarmonyOS - SymbolLayer Type Definitions
 * 符号图层 API（图标和文本）
 */

/**
 * 文本锚点类型
 */
export type TextAnchor = 'center' | 'left' | 'right' | 'top' | 'bottom' | 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right';

/**
 * 创建符号图层
 * @param layerId 图层 ID
 * @param sourceId 数据源 ID
 * @returns 图层原生指针
 */
export function create(layerId: string, sourceId: string): number;

// ========== 图标属性 ==========

/**
 * 设置图标图像
 * @param layerPtr 图层指针
 * @param iconImage 图标名称（需要先通过 addImage 添加）
 */
export function setIconImage(layerPtr: number, iconImage: string): void;

/**
 * 设置图标大小
 * @param layerPtr 图层指针
 * @param size 大小倍数（1.0 为原始大小）
 */
export function setIconSize(layerPtr: number, size: number): void;

/**
 * 设置图标旋转角度
 * @param layerPtr 图层指针
 * @param rotate 旋转角度（度）
 */
export function setIconRotate(layerPtr: number, rotate: number): void;

/**
 * 设置图标不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setIconOpacity(layerPtr: number, opacity: number): void;

/**
 * 设置图标颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setIconColor(layerPtr: number, color: string): void;

// ========== 文本属性 ==========

/**
 * 设置文本字段
 * @param layerPtr 图层指针
 * @param textField 文本内容或字段表达式
 */
export function setTextField(layerPtr: number, textField: string): void;

/**
 * 设置文本大小
 * @param layerPtr 图层指针
 * @param size 文本大小（单位：像素）
 */
export function setTextSize(layerPtr: number, size: number): void;

/**
 * 设置文本颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setTextColor(layerPtr: number, color: string): void;

/**
 * 设置文本光晕颜色
 * @param layerPtr 图层指针
 * @param color 颜色值（CSS 颜色字符串）
 */
export function setTextHaloColor(layerPtr: number, color: string): void;

/**
 * 设置文本光晕宽度
 * @param layerPtr 图层指针
 * @param width 光晕宽度（单位：像素）
 */
export function setTextHaloWidth(layerPtr: number, width: number): void;

/**
 * 设置文本不透明度
 * @param layerPtr 图层指针
 * @param opacity 不透明度（0.0 - 1.0）
 */
export function setTextOpacity(layerPtr: number, opacity: number): void;

/**
 * 设置文本锚点
 * @param layerPtr 图层指针
 * @param anchor 锚点位置
 */
export function setTextAnchor(layerPtr: number, anchor: TextAnchor): void;

/**
 * 设置文本偏移
 * @param layerPtr 图层指针
 * @param offset 偏移量 [x, y]（单位：ems）
 */
export function setTextOffset(layerPtr: number, offset: number[]): void;

/**
 * 设置文本字体
 * @param layerPtr 图层指针
 * @param font 字体名称数组
 */
export function setTextFont(layerPtr: number, font: string[]): void;

