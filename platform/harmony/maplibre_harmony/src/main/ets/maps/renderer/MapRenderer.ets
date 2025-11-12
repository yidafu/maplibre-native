/**
 * MapRenderer options interface.
 */
export interface MapRendererOptions {
  renderingRefreshMode?: number;
  maximumFps?: number;
}

/**
 * MapRenderer - map renderer helper.
 */
export class MapRenderer {
  public renderingRefreshMode: number;
  public maximumFps: number;

  constructor(options: MapRendererOptions = {}) {
    this.renderingRefreshMode =
      options.renderingRefreshMode !== undefined ? options.renderingRefreshMode : 0; // WHEN_DIRTY
    this.maximumFps = options.maximumFps !== undefined ? options.maximumFps : 60;
  }

  /**
   * Get the rendering refresh mode.
   */
  public getRenderingRefreshMode(): number {
    return this.renderingRefreshMode;
  }

  /**
   * Set the rendering refresh mode.
   */
  public setRenderingRefreshMode(mode: number): void {
    this.renderingRefreshMode = mode;
  }

  /**
   * Get the maximum FPS.
   */
  public getMaximumFps(): number {
    return this.maximumFps;
  }

  /**
   * Set the maximum FPS.
   */
  public setMaximumFps(fps: number): void {
    this.maximumFps = Math.max(1, fps);
  }

  /**
   * Convert to string.
   */
  public toString(): string {
    return `MapRenderer(mode=${this.renderingRefreshMode}, maxFps=${this.maximumFps})`;
  }
}
