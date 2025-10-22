/**
 * MarkerDragState - Marker 拖拽状态枚举
 * 
 * 表示 Marker 当前的拖拽状态
 * 
 * 参考:
 * - iOS: MLNAnnotationViewDragState
 */
export enum MarkerDragState {
  /**
   * 未参与拖拽操作
   */
  None = 0,
  
  /**
   * 开始拖拽
   * 用户长按 Marker 后，准备开始拖拽
   */
  Starting = 1,
  
  /**
   * 拖拽中
   * Marker 正在跟随用户手势移动
   */
  Dragging = 2,
  
  /**
   * 取消拖拽
   * 拖拽操作被取消
   */
  Canceling = 3,
  
  /**
   * 拖拽结束
   * 用户抬起手指，拖拽操作完成
   */
  Ending = 4
}

