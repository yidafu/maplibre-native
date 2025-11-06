/**
 * SnapshotOverlay - 快照覆盖层绘制工具
 * 
 * 提供在快照图像上绘制 Logo 和归属信息的功能
 * 参考 Android 的 MapSnapshotter.addOverlay() 实现
 */

import image from '@ohos.multimedia.image';
import { drawing } from '@kit.ArkGraphics2D';
import { MapSnapshot } from './MapSnapshot';

/**
 * Logo 位置枚举
 */
export enum LogoPosition {
  BOTTOM_LEFT = 0,
  BOTTOM_RIGHT = 1,
  TOP_LEFT = 2,
  TOP_RIGHT = 3
}

/**
 * 归属信息位置枚举
 */
export enum AttributionPosition {
  BOTTOM_LEFT = 0,
  BOTTOM_RIGHT = 1,
  TOP_LEFT = 2,
  TOP_RIGHT = 3
}

/**
 * Overlay 配置选项
 */
export interface OverlayOptions {
  /**
   * Logo 位置
   * 默认：BOTTOM_LEFT
   */
  logoPosition?: LogoPosition;
  
  /**
   * 归属信息位置
   * 默认：BOTTOM_RIGHT
   */
  attributionPosition?: AttributionPosition;
  
  /**
   * 边距（像素）
   * 默认：8
   */
  margin?: number;
  
  /**
   * Logo 缩放比例
   * 默认：1.0
   */
  logoScale?: number;
  
  /**
   * 归属文字大小
   * 默认：10
   */
  attributionTextSize?: number;
  
  /**
   * 是否绘制 Logo
   * 默认：true
   */
  drawLogo?: boolean;
  
  /**
   * 是否绘制归属信息
   * 默认：true
   */
  drawAttribution?: boolean;
}

/**
 * SnapshotOverlay 类
 * 
 * 用于在地图快照上绘制 Logo 和归属信息
 * 
 * @example
 * ```typescript
 * // 自动添加所有覆盖层
 * await SnapshotOverlay.addOverlay(snapshot);
 * 
 * // 自定义位置和样式
 * await SnapshotOverlay.addOverlay(snapshot, {
 *   logoPosition: LogoPosition.BOTTOM_RIGHT,
 *   attributionPosition: AttributionPosition.BOTTOM_LEFT,
 *   margin: 12
 * });
 * 
 * // 只绘制 Logo
 * await SnapshotOverlay.drawLogo(snapshot.getImage());
 * ```
 */
export class SnapshotOverlay {
  private static readonly DEFAULT_MARGIN = 8;
  private static readonly DEFAULT_LOGO_SCALE = 1.0;
  private static readonly DEFAULT_TEXT_SIZE = 10;

  /**
   * 在快照上绘制 Logo
   * 
   * @param pixelMap 快照图像
   * @param position Logo 位置
   * @param margin 边距（像素）
   * @param scale Logo 缩放比例
   * @returns Promise<void>
   */
  public static async drawLogo(
    pixelMap: image.PixelMap,
    position: LogoPosition = LogoPosition.BOTTOM_LEFT,
    margin: number = SnapshotOverlay.DEFAULT_MARGIN,
    scale: number = SnapshotOverlay.DEFAULT_LOGO_SCALE
  ): Promise<void> {
    // TODO: 实现 Logo 绘制
    // 1. 加载 MapLibre Logo 图片资源
    // 2. 根据 position 计算绘制位置
    // 3. 使用 drawing API 绘制到 pixelMap 上
    
    console.warn('[SnapshotOverlay] drawLogo: Not yet implemented - requires graphics.drawing API');
    
    // 实现示例（需要根据实际 Logo 资源调整）:
    // const canvas = drawing.Canvas.createCanvas(pixelMap);
    // const imageInfo = await pixelMap.getImageInfo();
    // const logoX = margin;
    // const logoY = imageInfo.size.height - logoHeight - margin;
    // canvas.drawImage(logoImage, logoX, logoY);
  }

  /**
   * 在快照上绘制归属信息
   * 
   * @param pixelMap 快照图像
   * @param attributions 归属信息数组
   * @param position 归属信息位置
   * @param margin 边距（像素）
   * @param textSize 文字大小
   * @returns Promise<void>
   */
  public static async drawAttributions(
    pixelMap: image.PixelMap,
    attributions: string[],
    position: AttributionPosition = AttributionPosition.BOTTOM_RIGHT,
    margin: number = SnapshotOverlay.DEFAULT_MARGIN,
    textSize: number = SnapshotOverlay.DEFAULT_TEXT_SIZE
  ): Promise<void> {
    if (!attributions || attributions.length === 0) {
      return;
    }

    // TODO: 实现归属信息绘制
    // 1. 合并归属信息文本
    // 2. 根据 position 计算绘制位置
    // 3. 使用 drawing API 绘制文字到 pixelMap 上
    
    console.warn('[SnapshotOverlay] drawAttributions: Not yet implemented - requires graphics.drawing API');
    
    // 实现示例:
    // const canvas = drawing.Canvas.createCanvas(pixelMap);
    // const text = attributions.join(' | ');
    // const paint = new drawing.Paint();
    // paint.setTextSize(textSize);
    // canvas.drawText(text, x, y, paint);
  }

  /**
   * 自动添加所有覆盖层（Logo + 归属信息）
   * 
   * 对应 Android: `MapSnapshotter.addOverlay(MapSnapshot)`
   * 
   * @param snapshot MapSnapshot 对象
   * @param options 可选配置
   * @returns Promise<void>
   * 
   * @example
   * ```typescript
   * snapshotter.start({
   *   onSnapshotReady: async (snapshot) => {
   *     // 自动添加 Logo 和归属信息
   *     await SnapshotOverlay.addOverlay(snapshot);
   *     
   *     // 使用快照
   *     const pixelMap = snapshot.getImage();
   *   }
   * });
   * ```
   */
  public static async addOverlay(
    snapshot: MapSnapshot,
    options?: OverlayOptions
  ): Promise<void> {
    // 使用显式类型定义避免对象字面量错误
    const logoPos: LogoPosition = options?.logoPosition ?? LogoPosition.BOTTOM_LEFT;
    const attrPos: AttributionPosition = options?.attributionPosition ?? AttributionPosition.BOTTOM_RIGHT;
    const margin: number = options?.margin ?? SnapshotOverlay.DEFAULT_MARGIN;
    const logoScale: number = options?.logoScale ?? SnapshotOverlay.DEFAULT_LOGO_SCALE;
    const attrTextSize: number = options?.attributionTextSize ?? SnapshotOverlay.DEFAULT_TEXT_SIZE;
    const drawLogo: boolean = options?.drawLogo !== false;
    const drawAttribution: boolean = options?.drawAttribution !== false;

    const pixelMap = snapshot.getImage();

    try {
      // 绘制 Logo
      if (drawLogo && snapshot.showLogo) {
        await SnapshotOverlay.drawLogo(
          pixelMap,
          logoPos,
          margin,
          logoScale
        );
      }

      // 绘制归属信息
      if (drawAttribution && snapshot.attributions.length > 0) {
        await SnapshotOverlay.drawAttributions(
          pixelMap,
          snapshot.attributions,
          attrPos,
          margin,
          attrTextSize
        );
      }
    } catch (err) {
      const error = err as Error;
      console.error('[SnapshotOverlay] addOverlay failed:', error.message);
      throw new Error(`Overlay drawing failed: ${error.message}`);
    }
  }
}

