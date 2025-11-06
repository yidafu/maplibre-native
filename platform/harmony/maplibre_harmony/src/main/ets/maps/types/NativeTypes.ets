/**
 * NativeTypes - 原生类型和辅助类型导出
 *
 * 1. 导出 NAPI 提供的 maplibre namespace
 * 2. 提供辅助类型定义（用于测试页面和应用开发）
 */

import maplibre from 'libmaplibre.so';

// 不允许导出 maplibre，原生方法必要在ets里转发一道（或者重新导出）
// ========== 导出 maplibre namespace ==========
// export { maplibre };

// ========== 辅助类型定义 ==========

/**
 * 经纬度接口（坐标点类型）
 * 
 * 用于表示地理坐标，支持对象字面量和 LatLng 类实例
 * 
 * @example
 * ```typescript
 * const position: ILatLng = { latitude: 39.9, longitude: 116.4 };
 * const latLng = new LatLng(position.latitude, position.longitude);
 * ```
 */
export type ILatLng = maplibre.LatLng;

/**
 * 矩形字面量接口
 * 
 * 表示屏幕矩形区域，坐标系为屏幕像素坐标
 */
export interface RectangleLiteral {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

/**
 * 尺寸接口
 * 
 * 表示宽度和高度，单位为像素
 * 
 * @example
 * ```typescript
 * const mapSize: Size = { width: 800, height: 600 };
 * ```
 */
export interface Size {
  width: number;
  height: number;
}

/**
 * 边距接口
 * 
 * 表示四边的内边距，单位为像素（vp）
 * 用于配置UI组件相对于容器边缘的偏移量
 * 
 * @example
 * ```typescript
 * const padding: Padding = { top: 10, left: 10, bottom: 10, right: 10 };
 * ```
 */
export interface Padding {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/**
 * 边距接口（别名）
 * 
 * 与 Padding 功能相同，提供更语义化的命名
 * 用于UI组件（Compass、Logo、ScaleBar、Attribution）的边距配置
 */
export type Margins = Padding;

/**
 * 从数组创建 Margins 对象
 * 
 * @param arr 边距数组 [left, top, right, bottom]
 * @returns Margins 对象
 * 
 * @example
 * ```typescript
 * const margins = createMargins([10, 20, 10, 20]);
 * // { left: 10, top: 20, right: 10, bottom: 20 }
 * ```
 */
export function createMargins(arr: number[]): Margins {
  return {
    left: arr[0] || 0,
    top: arr[1] || 0,
    right: arr[2] || 0,
    bottom: arr[3] || 0
  };
}

/**
 * 从单个值创建统一的 Margins 对象
 * 
 * @param value 统一的边距值
 * @returns Margins 对象
 * 
 * @example
 * ```typescript
 * const margins = createUniformMargins(10);
 * // { left: 10, top: 10, right: 10, bottom: 10 }
 * ```
 */
export function createUniformMargins(value: number): Margins {
  return {
    left: value,
    top: value,
    right: value,
    bottom: value
  };
}

/**
 * 合并两个 Margins 对象（第二个覆盖第一个）
 * 
 * @param base 基础 Margins
 * @param override 覆盖的 Margins（仅覆盖非 undefined 的值）
 * @returns 合并后的 Margins 对象
 */
export function mergeMargins(base: Margins, override: Partial<Margins>): Margins {
  return {
    left: override.left !== undefined ? override.left : base.left,
    top: override.top !== undefined ? override.top : base.top,
    right: override.right !== undefined ? override.right : base.right,
    bottom: override.bottom !== undefined ? override.bottom : base.bottom
  };
}

/**
 * 相机选项字面量接口（用于测试页面）
 */
export interface CameraOptionsLiteral {
  center?: ILatLng;
  zoom?: number;
  bearing?: number;
  pitch?: number;
  padding?: Padding;
}

// ========== 从 types.ets 合并的类型定义 ==========

/**
 * 装饰物位置枚举（对齐 Android MLNOrnamentPosition 和 iOS MLNOrnamentPosition）
 * 用于配置 Compass、Logo、ScaleBar、Attribution 等 UI 组件的位置
 */
export enum OrnamentPosition {
  /** 放置在地图左上角 */
  TopLeft = 0,
  /** 放置在地图右上角 */
  TopRight = 1,
  /** 放置在地图左下角 */
  BottomLeft = 2,
  /** 放置在地图右下角 */
  BottomRight = 3
}


/**
 * 渲染刷新模式（对齐 Android MapRenderer.RenderingRefreshMode）
 */
export enum RenderingRefreshMode {
  /** 持续渲染模式 - 每帧都渲染，适合动画场景 */
  CONTINUOUS = 0,
  /** 按需渲染模式 - 只在需要时渲染，节省性能 */
  WHEN_DIRTY = 1
}

/**
 * 瓦片操作枚举（对齐 Android TileOperation）
 */
export enum TileOperation {
  /** 瓦片被添加 */
  Added = 0,
  /** 瓦片被更新 */
  Updated = 1,
  /** 瓦片被移除 */
  Removed = 2
}

/**
 * 用户位置跟踪模式（对齐 iOS MLNUserTrackingMode）
 */
export enum UserTrackingMode {
  /** 不跟踪用户位置 */
  None = 0,
  /** 跟随用户位置，用户平移地图时退出该模式 */
  Follow = 1,
  /** 跟随用户位置和方向（指南针方向），用户旋转地图时退回到 Follow 模式 */
  FollowWithHeading = 2,
  /** 跟随用户位置和航向（移动方向），用户旋转地图时退回到 Follow 模式 */
  FollowWithCourse = 3
}

/**
 * 相机移动原因（对齐 Android OnCameraMoveStartedListener）
 */
export enum CameraMoveReason {
  /** 未知原因 */
  Unknown = 0,
  /** 程序化 API 调用 */
  API_ANIMATION = 1,
  /** 用户手势操作 */
  API_GESTURE = 2,
  /** 开发者调用的动画 */
  DEVELOPER_ANIMATION = 3
}


