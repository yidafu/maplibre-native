/**
 * MapRenderer - 地图渲染器类
 */
export class MapRenderer {
  public renderingRefreshMode: number;
  public maximumFps: number;

  constructor(options: {
    renderingRefreshMode?: number;
    maximumFps?: number;
  } = {}) {
    this.renderingRefreshMode = options.renderingRefreshMode || 0; // WHEN_DIRTY
    this.maximumFps = options.maximumFps || 60;
  }

  /**
   * 获取渲染刷新模式
   */
  public getRenderingRefreshMode(): number {
    return this.renderingRefreshMode;
  }

  /**
   * 设置渲染刷新模式
   */
  public setRenderingRefreshMode(mode: number): void {
    this.renderingRefreshMode = mode;
  }

  /**
   * 获取最大帧率
   */
  public getMaximumFps(): number {
    return this.maximumFps;
  }

  /**
   * 设置最大帧率
   */
  public setMaximumFps(fps: number): void {
    this.maximumFps = Math.max(1, fps);
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `MapRenderer(mode=${this.renderingRefreshMode}, maxFps=${this.maximumFps})`;
  }
}
