/**
 * StyleBuilder - 样式构建器
 * 
 * 参考 Android Style.Builder 实现，提供批量配置图层和数据源的能力
 * 确保所有 Layout 属性在 SymbolBucket 创建前正确设置，消除时序问题
 * 
 * @example
 * ```typescript
 * new StyleBuilder()
 *   .withSource(new GeoJsonSource('source-id'))
 *   .withLayer(
 *     new SymbolLayer('layer-id', 'source-id')
 *       .setTextField(['get', 'title'])
 *       .setTextAllowOverlap(true)
 *   )
 *   .build(map);
 * ```
 */

import type { MapLibreMap } from '../MapLibreMap';
import type { Source } from './sources/Source';
import type { Layer } from './layers/Layer';

/**
 * 图层配置类
 */
class LayerConfig {
  /** 图层实例 */
  layer: Layer;
  /** 在指定图层之前插入 */
  beforeId?: string;
  /** 在指定图层之后插入 */
  afterId?: string;
  /** 在指定索引位置插入 */
  atIndex?: number;

  constructor(layer: Layer, beforeId?: string, afterId?: string, atIndex?: number) {
    this.layer = layer;
    this.beforeId = beforeId;
    this.afterId = afterId;
    this.atIndex = atIndex;
  }
}

/**
 * 统计信息类
 */
class StyleBuilderStats {
  sources: number = 0;
  layers: number = 0;
  images: number = 0;
}

/**
 * 图像配置类
 */
class ImageConfig {
  /** 图像 ID */
  id: string;
  /** 图像数据 */
  image: ArrayBuffer | Uint8Array;
  /** 图像宽度 */
  width: number;
  /** 图像高度 */
  height: number;
  /** 是否为 SDF 图像 */
  sdf?: boolean;

  constructor(id: string, image: ArrayBuffer | Uint8Array, width: number, height: number, sdf?: boolean) {
    this.id = id;
    this.image = image;
    this.width = width;
    this.height = height;
    this.sdf = sdf;
  }
}

/**
 * StyleBuilder - 样式构建器类
 * 
 * 提供声明式的样式配置方式，确保所有组件按正确顺序添加
 */
export class StyleBuilder {
  /** 数据源映射 */
  private sources: Map<string, Source> = new Map();
  
  /** 图层配置数组 */
  private layers: LayerConfig[] = [];
  
  /** 图像配置数组 */
  private images: ImageConfig[] = [];
  
  /** 是否已构建 */
  private built: boolean = false;

  /**
   * 添加数据源
   * @param source 数据源实例
   * @returns 返回 this 以支持链式调用
   */
  public withSource(source: Source): StyleBuilder {
    this.checkNotBuilt();
    const sourceId = this.getSourceId(source);
    if (sourceId) {
      this.sources.set(sourceId, source);
    }
    return this;
  }

  /**
   * 批量添加数据源
   * @param sources 数据源数组
   * @returns 返回 this 以支持链式调用
   */
  public withSources(...sources: Source[]): StyleBuilder {
    this.checkNotBuilt();
    for (const source of sources) {
      this.withSource(source);
    }
    return this;
  }

  /**
   * 添加图层
   * @param layer 图层实例（所有属性应已设置完成）
   * @returns 返回 this 以支持链式调用
   */
  public withLayer(layer: Layer): StyleBuilder {
    this.checkNotBuilt();
    this.layers.push(new LayerConfig(layer));
    return this;
  }

  /**
   * 批量添加图层
   * @param layers 图层数组
   * @returns 返回 this 以支持链式调用
   */
  public withLayers(...layers: Layer[]): StyleBuilder {
    this.checkNotBuilt();
    for (const layer of layers) {
      this.withLayer(layer);
    }
    return this;
  }

  /**
   * 在指定图层之前添加图层
   * @param layer 图层实例
   * @param beforeLayerId 参考图层 ID
   * @returns 返回 this 以支持链式调用
   */
  public withLayerBefore(layer: Layer, beforeLayerId: string): StyleBuilder {
    this.checkNotBuilt();
    this.layers.push(new LayerConfig(layer, beforeLayerId));
    return this;
  }

  /**
   * 在指定图层之后添加图层
   * @param layer 图层实例
   * @param afterLayerId 参考图层 ID
   * @returns 返回 this 以支持链式调用
   */
  public withLayerAfter(layer: Layer, afterLayerId: string): StyleBuilder {
    this.checkNotBuilt();
    this.layers.push(new LayerConfig(layer, undefined, afterLayerId));
    return this;
  }

  /**
   * 在指定索引位置添加图层
   * @param layer 图层实例
   * @param index 索引位置
   * @returns 返回 this 以支持链式调用
   */
  public withLayerAt(layer: Layer, index: number): StyleBuilder {
    this.checkNotBuilt();
    this.layers.push(new LayerConfig(layer, undefined, undefined, index));
    return this;
  }

  /**
   * 添加图像资源
   * @param id 图像 ID
   * @param image 图像数据（ArrayBuffer 或 Uint8Array）
   * @param width 图像宽度
   * @param height 图像高度
   * @param sdf 是否为 SDF 图像
   * @returns 返回 this 以支持链式调用
   */
  public withImage(
    id: string,
    image: ArrayBuffer | Uint8Array,
    width: number,
    height: number,
    sdf: boolean = false
  ): StyleBuilder {
    this.checkNotBuilt();
    this.images.push(new ImageConfig(id, image, width, height, sdf));
    return this;
  }

  /**
   * 构建并应用样式
   * @param map 地图实例
   * @returns Promise，在所有组件添加完成后 resolve
   */
  public async build(map: MapLibreMap): Promise<void> {
    this.checkNotBuilt();
    this.built = true;

    try {
      // 1. 添加图像资源
      await this.addImages(map);

      // 2. 添加数据源
      await this.addSources(map);

      // 3. 添加图层
      await this.addLayers(map);

      console.info(`✅ StyleBuilder: Successfully built style with ${this.sources.size} sources, ${this.layers.length} layers, ${this.images.length} images`);
    } catch (error) {
      const errorMsg = `StyleBuilder: Failed to build style: ${error}`;
      console.error('❌', errorMsg);
      throw new Error(errorMsg);
    }
  }

  /**
   * 添加图像资源
   */
  private async addImages(map: MapLibreMap): Promise<void> {
    const style = map.getStyle();
    if (!style) {
      throw new Error('Style not loaded');
    }

    for (const imageConfig of this.images) {
      try {
        style.addImage(
          imageConfig.id,
          imageConfig.image,
          imageConfig.width,
          imageConfig.height,
          imageConfig.sdf ?? false
        );
        console.info(`✅ Added image: ${imageConfig.id}`);
      } catch (error) {
        console.error(`❌ Failed to add image ${imageConfig.id}:`, error);
        throw new Error(`Failed to add image ${imageConfig.id}: ${error}`);
      }
    }
  }

  /**
   * 添加数据源
   */
  private async addSources(map: MapLibreMap): Promise<void> {
    this.sources.forEach((source, sourceId) => {
      try {
        map.addSource(source);
        console.info(`✅ Added source: ${sourceId}`);
      } catch (error) {
        console.error(`❌ Failed to add source ${sourceId}:`, error);
        throw new Error(`Failed to add source ${sourceId}: ${error}`);
      }
    });

    // 给数据源一点时间注册
    if (this.sources.size > 0) {
      await this.delay(50);
    }
  }

  /**
   * 添加图层
   */
  private async addLayers(map: MapLibreMap): Promise<void> {
    for (const config of this.layers) {
      try {
        const layerId = this.getLayerId(config.layer);
        
        if (config.beforeId) {
          // 在指定图层之前添加
          map.addLayerAbove(config.layer, config.beforeId);
          console.info(`✅ Added layer ${layerId} before ${config.beforeId}`);
        } else if (config.afterId) {
          // 在指定图层之后添加
          map.addLayerAbove(config.layer, config.afterId);
          console.info(`✅ Added layer ${layerId} after ${config.afterId}`);
        } else if (config.atIndex !== undefined) {
          // 在指定位置添加
          map.addLayerAt(config.layer, config.atIndex);
          console.info(`✅ Added layer ${layerId} at index ${config.atIndex}`);
        } else {
          // 默认添加到最后
          map.addLayer(config.layer);
          console.info(`✅ Added layer: ${layerId}`);
        }
      } catch (error) {
        const layerId = this.getLayerId(config.layer);
        console.error(`❌ Failed to add layer ${layerId}:`, error);
        throw new Error(`Failed to add layer ${layerId}: ${error}`);
      }
    }
  }

  /**
   * 检查是否已构建
   */
  private checkNotBuilt(): void {
    if (this.built) {
      throw new Error('StyleBuilder has already been built. Create a new instance for additional changes.');
    }
  }

  /**
   * 延迟函数
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 获取数据源 ID
   */
  private getSourceId(source: Source): string | null {
    try {
      // Source 都有 getId() 方法
      return source.getId();
    } catch (error) {
      console.error('Error getting source ID:', error);
      return null;
    }
  }

  /**
   * 获取图层 ID
   */
  private getLayerId(layer: Layer): string {
    try {
      // Layer 都有 getId() 方法
      return layer.getId();
    } catch (error) {
      console.error('Error getting layer ID:', error);
      return 'unknown-layer';
    }
  }

  /**
   * 获取当前配置的统计信息
   */
  public getStats(): StyleBuilderStats {
    const stats = new StyleBuilderStats();
    stats.sources = this.sources.size;
    stats.layers = this.layers.length;
    stats.images = this.images.length;
    return stats;
  }

  /**
   * 清空所有配置（用于重置）
   */
  public clear(): void {
    this.sources.clear();
    this.layers = [];
    this.images = [];
    this.built = false;
  }
}

