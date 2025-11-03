/**
 * CompassVisibility - 指南针可见性模式枚举
 *
 * 参考 iOS MLNOrnamentVisibility
 */
export enum CompassVisibility {
  /**
   * 自适应模式：当地图不是正北朝向时显示，正北时隐藏
   */
  Adaptive = 0,

  /**
   * 总是可见
   */
  Visible = 1,

  /**
   * 总是隐藏
   */
  Hidden = 2
}

