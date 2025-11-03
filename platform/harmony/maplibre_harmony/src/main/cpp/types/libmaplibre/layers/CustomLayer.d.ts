/**
 * MapLibre Native for HarmonyOS - CustomLayer Type Definitions
 * 自定义图层 API (NAPI 类)
 */

/**
 * CustomLayer - 自定义图层
 *
 * 允许开发者使用自定义渲染逻辑创建图层
 *
 * Note: 此为简化实现，完整功能待后续补充
 */
export class CustomLayer {
  /**
   * 创建自定义图层
   * @param layerId 图层 ID
   */
  constructor(layerId: string);

  /**
   * 获取图层 ID
   */
  getId(): string;

  /**
   * 获取图层类型
   */
  getType(): string;

  /**
   * 设置图层可见性
   */
  setVisibility(visibility: 'visible' | 'none'): this;

  getVisibility(): 'visible' | 'none';

  /**
   * 设置最小/最大缩放级别
   */
  setMinZoom(zoom: number): this;

  getMinZoom(): number;

  setMaxZoom(zoom: number): this;

  getMaxZoom(): number;

  /**
   * 设置自定义图层颜色 (RGBA)
   * @param r 红色分量 (0.0 - 1.0)
   * @param g 绿色分量 (0.0 - 1.0)
   * @param b 蓝色分量 (0.0 - 1.0)
   * @param a 透明度 (0.0 - 1.0)
   */
  setColor(r: number, g: number, b: number, a: number): this;

  /**
   * 获取自定义图层颜色
   * @returns 颜色数组 [r, g, b, a]
   */
  getColor(): number[];
}

