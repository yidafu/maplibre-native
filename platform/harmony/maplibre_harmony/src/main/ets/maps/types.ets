/**
 * 通用类型定义文件
 * 包含地图相关的枚举、接口等类型定义
 */

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
 * 边距类型
 * 用于配置 UI 组件相对于容器边缘的偏移量
 */
export interface Margins {
  /** 左边距（vp） */
  left: number;
  /** 上边距（vp） */
  top: number;
  /** 右边距（vp） */
  right: number;
  /** 下边距（vp） */
  bottom: number;
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

