import { Source } from './sources/Source';
import { Layer } from './layers/Layer';
import { Image } from './images/Image';
import { Light } from './light/Light';
import { TransitionOptions } from './layers/TransitionOptions';
import maplibre from 'libmaplibre_native.so';

/**
 * Style - 样式管理类
 * 
 * 用于管理地图样式、数据源、图层和图片资源
 */
export class Style {
  private nativeMapPtr: number;
  private sources: Map<string, Source> = new Map();
  private layers: Map<string, Layer> = new Map();
  private images: Map<string, Image> = new Map();
  private fullyLoaded: boolean = false;

  constructor(nativeMapPtr: number) {
    this.nativeMapPtr = nativeMapPtr;
  }

  /**
   * 标记样式为完全加载
   */
  public setFullyLoaded(loaded: boolean): void {
    this.fullyLoaded = loaded;
  }

  /**
   * 样式是否完全加载
   */
  public isFullyLoaded(): boolean {
    return this.fullyLoaded;
  }

  /**
   * 获取样式URL
   */
  public getUrl(): string {
    try {
      return maplibre.Style.getStyleUri(this.nativeMapPtr);
    } catch (error) {
      console.error(`Failed to get style URL: ${error}`);
      return '';
    }
  }

  /**
   * 获取样式JSON
   */
  public getJson(): string {
    try {
      return maplibre.Style.getStyleJson(this.nativeMapPtr);
    } catch (error) {
      console.error(`Failed to get style JSON: ${error}`);
      return '';
    }
  }

  // ==================== 数据源管理 ====================

  /**
   * 添加数据源
   */
  public addSource(source: Source): void {
    if (!this.fullyLoaded) {
      console.warn('Style is not fully loaded yet');
    }

    try {
      const sourceJson = JSON.stringify(source.toJSON());
      maplibre.Style.addSource(this.nativeMapPtr, source.getId(), sourceJson, source.getNativePtr());
      this.sources.set(source.getId(), source);
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to add source: ${error.message}`);
      throw new Error(`Failed to add source: ${error.message}`);
    }
  }

  /**
   * 移除数据源
   */
  public removeSource(sourceId: string): boolean {
    try {
      const success = maplibre.Style.removeSource(this.nativeMapPtr, sourceId);
      if (success) {
        this.sources.delete(sourceId);
      }
      return success;
    } catch (error) {
      console.error(`Failed to remove source: ${error}`);
      return false;
    }
  }

  /**
   * 获取数据源
   */
  public getSource(sourceId: string): Source | null {
    // 先从缓存获取
    if (this.sources.has(sourceId)) {
      return this.sources.get(sourceId) || null;
    }

    // 从native获取
    try {
      const sourceJson: string | null = maplibre.Style.getSource(this.nativeMapPtr, sourceId) as string | null;
      if (sourceJson) {
        // TODO: 根据type创建对应的Source实例
        // 这里需要反序列化Source
        console.info(`Get source: ${sourceId}`);
        return null;
      }
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to get source: ${error.message}`);
    }

    return null;
  }

  /**
   * 获取所有数据源
   */
  public getSources(): Source[] {
    try {
      const sourcesJson: string = maplibre.Style.getSources(this.nativeMapPtr);
      const sourcesData: Array<ESObject> = JSON.parse(sourcesJson) as Array<ESObject>;
      
      // 更新缓存
      sourcesData.forEach((sourceData: ESObject): void => {
        // TODO: 根据type创建对应的Source实例
        const sourceId: string = sourceData['id'] as string;
        console.info(`Source: ${sourceId}`);
      });

      return Array.from(this.sources.values());
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to get sources: ${error.message}`);
      return [];
    }
  }

  // ==================== 图层管理 ====================

  /**
   * 添加图层（添加到顶部）
   */
  public addLayer(layer: Layer): void {
    if (!this.fullyLoaded) {
      console.warn('Style is not fully loaded yet');
    }

    try {
      const layerJson = JSON.stringify(layer.toJSON());
      maplibre.Style.addLayer(this.nativeMapPtr, layer.getId(), layerJson, layer.getNativePtr());
      this.layers.set(layer.getId(), layer);
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to add layer: ${error.message}`);
      throw new Error(`Failed to add layer: ${error.message}`);
    }
  }

  /**
   * 在指定图层下方添加图层
   */
  public addLayerBelow(layer: Layer, belowLayerId: string): void {
    if (!this.fullyLoaded) {
      console.warn('Style is not fully loaded yet');
    }

    try {
      const layerJson = JSON.stringify(layer.toJSON());
      maplibre.Style.addLayerBelow(this.nativeMapPtr, layer.getId(), layerJson, layer.getNativePtr(), belowLayerId);
      this.layers.set(layer.getId(), layer);
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to add layer below: ${error.message}`);
      throw new Error(`Failed to add layer below: ${error.message}`);
    }
  }

  /**
   * 在指定图层上方添加图层
   */
  public addLayerAbove(layer: Layer, aboveLayerId: string): void {
    if (!this.fullyLoaded) {
      console.warn('Style is not fully loaded yet');
    }

    try {
      const layerJson = JSON.stringify(layer.toJSON());
      maplibre.Style.addLayerAbove(this.nativeMapPtr, layer.getId(), layerJson, layer.getNativePtr(), aboveLayerId);
      this.layers.set(layer.getId(), layer);
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to add layer above: ${error.message}`);
      throw new Error(`Failed to add layer above: ${error.message}`);
    }
  }

  /**
   * 在指定索引位置添加图层
   */
  public addLayerAt(layer: Layer, index: number): void {
    if (!this.fullyLoaded) {
      console.warn('Style is not fully loaded yet');
    }

    try {
      const layerJson = JSON.stringify(layer.toJSON());
      maplibre.Style.addLayerAt(this.nativeMapPtr, layer.getId(), layerJson, layer.getNativePtr(), index);
      this.layers.set(layer.getId(), layer);
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to add layer at: ${error.message}`);
      throw new Error(`Failed to add layer at: ${error.message}`);
    }
  }

  /**
   * 移除图层
   */
  public removeLayer(layerId: string): boolean {
    try {
      const success = maplibre.Style.removeLayer(this.nativeMapPtr, layerId);
      if (success) {
        this.layers.delete(layerId);
      }
      return success;
    } catch (error) {
      console.error(`Failed to remove layer: ${error}`);
      return false;
    }
  }

  /**
   * 移除指定索引的图层
   */
  public removeLayerAt(index: number): boolean {
    try {
      return maplibre.Style.removeLayerAt(this.nativeMapPtr, index);
    } catch (error) {
      console.error(`Failed to remove layer at: ${error}`);
      return false;
    }
  }

  /**
   * 获取图层
   */
  public getLayer(layerId: string): Layer | null {
    // 先从缓存获取
    if (this.layers.has(layerId)) {
      return this.layers.get(layerId) || null;
    }

    // 从native获取
    try {
      const layerJson: string | null = maplibre.Style.getLayer(this.nativeMapPtr, layerId) as string | null;
      if (layerJson) {
        // TODO: 根据type创建对应的Layer实例
        console.info(`Get layer: ${layerId}`);
        return null;
      }
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to get layer: ${error.message}`);
    }

    return null;
  }

  /**
   * 获取所有图层
   */
  public getLayers(): Layer[] {
    try {
      const layersJson: string = maplibre.Style.getLayers(this.nativeMapPtr);
      const layersData: Array<ESObject> = JSON.parse(layersJson) as Array<ESObject>;
      
      // 更新缓存
      layersData.forEach((layerData: ESObject): void => {
        // TODO: 根据type创建对应的Layer实例
        const layerId: string = layerData['id'] as string;
        console.info(`Layer: ${layerId}`);
      });

      return Array.from(this.layers.values());
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to get layers: ${error.message}`);
      return [];
    }
  }

  // ==================== 图片资源管理 ====================

  /**
   * 添加图片
   */
  public addImage(name: string, image: Image, sdf: boolean = false): void {
    if (!this.fullyLoaded) {
      console.warn('Style is not fully loaded yet');
    }

    try {
      const imageData = image.getData();
      maplibre.Style.addImage(this.nativeMapPtr, name, imageData, image.getWidth(), image.getHeight(), sdf);
      this.images.set(name, image);
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to add image: ${error.message}`);
      throw new Error(`Failed to add image: ${error.message}`);
    }
  }

  /**
   * 移除图片
   */
  public removeImage(name: string): boolean {
    try {
      const success = maplibre.Style.removeImage(this.nativeMapPtr, name);
      if (success) {
        this.images.delete(name);
      }
      return success;
    } catch (error) {
      console.error(`Failed to remove image: ${error}`);
      return false;
    }
  }

  /**
   * 获取图片
   */
  public getImage(name: string): Image | null {
    if (this.images.has(name)) {
      return this.images.get(name) || null;
    }

    try {
      const imageData: ESObject | null = maplibre.Style.getImage(this.nativeMapPtr, name) as ESObject | null;
      if (imageData) {
        // TODO: 从imageData创建Image实例
        console.info(`Get image: ${name}`);
        return null;
      }
    } catch (e) {
      const error = e as Error;
      console.error(`Failed to get image: ${error.message}`);
    }

    return null;
  }

  // ==================== 光照和过渡 ====================

  /**
   * 获取光照
   */
  public getLight(): Light | null {
    try {
      const lightJson = maplibre.Style.getLight(this.nativeMapPtr);
      if (lightJson) {
        return JSON.parse(lightJson) as Light;
      }
    } catch (error) {
      console.error(`Failed to get light: ${error}`);
    }
    return null;
  }

  /**
   * 设置光照
   */
  public setLight(light: Light): void {
    try {
      const lightJson = JSON.stringify(light);
      maplibre.Style.setLight(this.nativeMapPtr, lightJson);
    } catch (error) {
      console.error(`Failed to set light: ${error}`);
    }
  }

  /**
   * 获取过渡选项
   */
  public getTransition(): TransitionOptions | null {
    try {
      const transitionJson = maplibre.Style.getTransition(this.nativeMapPtr);
      if (transitionJson) {
        return JSON.parse(transitionJson) as TransitionOptions;
      }
    } catch (error) {
      console.error(`Failed to get transition: ${error}`);
    }
    return null;
  }

  /**
   * 设置过渡选项
   */
  public setTransition(transition: TransitionOptions): void {
    try {
      const transitionJson = JSON.stringify(transition);
      maplibre.Style.setTransition(this.nativeMapPtr, transitionJson);
    } catch (error) {
      console.error(`Failed to set transition: ${error}`);
    }
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Style(loaded=${this.fullyLoaded}, sources=${this.sources.size}, layers=${this.layers.size})`;
  }
}

