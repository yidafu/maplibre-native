/**
 * CameraMoveReason - 相机移动原因枚举
 *
 * 用于区分相机移动的触发原因
 */

/**
 * 相机移动原因
 */
export enum CameraMoveReason {
  /**
   * 未知原因
   */
  UNKNOWN = 0,

  /**
   * 手势操作（平移、缩放、旋转等）
   */
  GESTURE = 1,

  /**
   * API 调用（jumpTo、setCenter等）
   */
  API_ANIMATION = 2,

  /**
   * 动画（easeTo、flyTo）
   */
  DEVELOPER_ANIMATION = 3,

  /**
   * 取消动画
   */
  ANIMATION_CANCELLED = 4
}

/**
 * 获取相机移动原因的描述文本
 */
export function getCameraMoveReasonText(reason: CameraMoveReason): string {
  switch (reason) {
    case CameraMoveReason.GESTURE:
      return '手势操作';
    case CameraMoveReason.API_ANIMATION:
      return 'API 调用';
    case CameraMoveReason.DEVELOPER_ANIMATION:
      return '开发者动画';
    case CameraMoveReason.ANIMATION_CANCELLED:
      return '动画取消';
    default:
      return '未知原因';
  }
}

