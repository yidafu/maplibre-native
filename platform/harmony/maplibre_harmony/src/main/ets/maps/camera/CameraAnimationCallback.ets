/**
 * CameraAnimationCallback - 相机动画回调接口
 * 
 * 用于监听相机动画的完成和取消事件
 * 对应 Android 的 CancelableCallback 和 iOS 的 completion handler
 */

/**
 * 相机动画回调接口
 */
export interface CameraAnimationCallback {
  /**
   * 动画完成时调用
   */
  onFinish(): void;
  
  /**
   * 动画取消时调用（可选）
   */
  onCancel?(): void;
}

/**
 * 简化的完成回调类型
 */
export type OnFinishCallback = () => void;

/**
 * 动画选项接口（扩展用）
 */
export interface AnimationOptions {
  /**
   * 动画持续时间（毫秒）
   */
  duration: number;
  
  /**
   * 完成回调（可选）
   */
  callback?: CameraAnimationCallback;
}

/**
 * CameraAnimationCallback 实现类
 * 用于避免对象字面量类型错误
 */
export class CameraAnimationCallbackImpl implements CameraAnimationCallback {
  private finishFn: () => void;
  private cancelFn?: () => void;
  
  constructor(onFinish: () => void, onCancel?: () => void) {
    this.finishFn = onFinish;
    this.cancelFn = onCancel;
  }
  
  onFinish(): void {
    this.finishFn();
  }
  
  onCancel(): void {
    if (this.cancelFn) {
      this.cancelFn();
    }
  }
}

/**
 * 创建 CameraAnimationCallback 的工厂函数
 */
export function createAnimationCallback(
  onFinish: () => void, 
  onCancel?: () => void
): CameraAnimationCallback {
  return new CameraAnimationCallbackImpl(onFinish, onCancel);
}

