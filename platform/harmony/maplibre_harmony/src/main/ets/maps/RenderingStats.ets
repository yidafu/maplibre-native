/**
 * 渲染统计信息类
 * 对齐 Android OnDidFinishRenderingFrameWithStatsListener 中的 RenderingStats
 */
export class RenderingStats {
  /**
   * 是否完全渲染
   * true 表示所有内容都已渲染完成，false 表示部分渲染
   */
  public fully: boolean;
  
  /**
   * 帧编码时间（毫秒）
   * CPU 编码瓦片和符号所用的时间
   */
  public frameEncodingTime: number;
  
  /**
   * 帧渲染时间（毫秒）
   * GPU 渲染一帧所用的时间
   */
  public frameRenderingTime: number;

  constructor(fully: boolean, frameEncodingTime: number, frameRenderingTime: number) {
    this.fully = fully;
    this.frameEncodingTime = frameEncodingTime;
    this.frameRenderingTime = frameRenderingTime;
  }

  /**
   * 获取总帧时间
   * @returns 编码时间 + 渲染时间
   */
  getTotalFrameTime(): number {
    return this.frameEncodingTime + this.frameRenderingTime;
  }

  /**
   * 获取当前帧率估算值
   * @returns 帧率（FPS）
   */
  getEstimatedFps(): number {
    const totalTime = this.getTotalFrameTime();
    if (totalTime <= 0) {
      return 0;
    }
    return 1000.0 / totalTime;
  }

  /**
   * 转换为字符串表示
   */
  toString(): string {
    return `RenderingStats{fully=${this.fully}, encoding=${this.frameEncodingTime.toFixed(2)}ms, rendering=${this.frameRenderingTime.toFixed(2)}ms, fps=${this.getEstimatedFps().toFixed(1)}}`;
  }
}

