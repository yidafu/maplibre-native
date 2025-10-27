/**
 * 位置过期状态监听器
 */
export interface OnLocationStaleListener {
  /**
   * 当位置变为过期状态时调用
   * @param isStale 是否过期
   */
  onStaleStateChange(isStale: boolean): void;
}

