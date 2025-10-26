/**
 * MapLibre Native for HarmonyOS - PluginManager Type Definitions
 * XComponent 管理和测试函数
 */

/**
 * XComponent 上下文状态
 */
export interface XComponentContextStatus {
    /** 是否已绘制 */
    hasDraw: boolean;
    /** 是否已改变颜色 */
    hasChangeColor: boolean;
}

/**
 * 设置 Surface ID
 * @param id Surface ID
 * @returns 结果
 */
export function SetSurfaceId(id: BigInt): any;

/**
 * 改变 Surface
 * @param id Surface ID
 * @param w 宽度
 * @param h 高度
 * @returns 结果
 */
export function ChangeSurface(id: BigInt, w: number, h: number): any;

/**
 * 绘制图案
 * @param id Surface ID
 * @returns 结果
 */
export function DrawPattern(id: BigInt): any;

/**
 * 获取 XComponent 状态
 * @param id Surface ID
 * @returns XComponent 上下文状态
 */
export function GetXComponentStatus(id: BigInt): XComponentContextStatus;

/**
 * 改变颜色
 * @param id Surface ID
 * @returns 结果
 */
export function ChangeColor(id: BigInt): any;

/**
 * 销毁 Surface
 * @param id Surface ID
 * @returns 结果
 */
export function DestroySurface(id: BigInt): any;

/**
 * 测试函数：两数相加
 * @param a 第一个数
 * @param b 第二个数
 * @returns 两数之和
 */
export function add(a: number, b: number): number;

