import { Source, SourceOptions } from './Source';
import { GeoJsonOptions } from './GeoJsonOptions';
import { Feature } from '../../geojson/Feature';
import { Geometry } from '../../geojson/Geometry';
import maplibre from 'libmaplibre_native.so';

/**
 * GeoJSON数据源类型
 */
export type GeoJsonData = Object | string | Feature | Geometry | null;

/**
 * GeoJsonSource - GeoJSON数据源
 * 
 * 支持FeatureCollection、Feature、Geometry、URL和原始JSON字符串
 */
export class GeoJsonSource extends Source {
  private nativePtr: number = 0;
  private geoJsonOptions: GeoJsonOptions | null;

  /**
   * 创建空的GeoJsonSource
   */
  constructor(id: string, options?: GeoJsonOptions) {
    super({
      id: id,
      type: 'geojson'
    });
    this.geoJsonOptions = options || null;
    this.initialize(id, options);
  }

  /**
   * 创建带数据的GeoJsonSource
   */
  public static withData(id: string, data: GeoJsonData, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setGeoJson(data);
    return source;
  }

  /**
   * 创建带URL的GeoJsonSource
   */
  public static withUrl(id: string, url: string, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setUrl(url);
    return source;
  }

  /**
   * 初始化native对象
   */
  private initialize(id: string, options?: GeoJsonOptions): void {
    try {
      // 调用native方法初始化
      const optionsJson = options ? JSON.stringify(options) : null;
      this.nativePtr = maplibre.GeoJsonSource.create(id, optionsJson);
    } catch (error) {
      console.error(`Failed to initialize GeoJsonSource: ${error}`);
    }
  }

  /**
   * 设置GeoJSON数据（异步）
   */
  public setGeoJson(data: GeoJsonData): void {
    if (this.nativePtr === 0) return;
    
    try {
      let jsonStr: string;
      if (typeof data === 'string') {
        jsonStr = data;
      } else if (data !== null) {
        jsonStr = JSON.stringify(data);
      } else {
        jsonStr = '{"type":"FeatureCollection","features":[]}';
      }
      
      maplibre.GeoJsonSource.setGeoJson(this.nativePtr, jsonStr);
    } catch (error) {
      console.error(`Failed to set GeoJSON data: ${error}`);
    }
  }

  /**
   * 设置GeoJSON数据（同步）
   */
  public setGeoJsonSync(data: GeoJsonData): void {
    if (this.nativePtr === 0) return;
    
    try {
      let jsonStr: string;
      if (typeof data === 'string') {
        jsonStr = data;
      } else if (data !== null) {
        jsonStr = JSON.stringify(data);
      } else {
        jsonStr = '{"type":"FeatureCollection","features":[]}';
      }
      
      maplibre.GeoJsonSource.setGeoJsonSync(this.nativePtr, jsonStr);
    } catch (error) {
      console.error(`Failed to set GeoJSON data sync: ${error}`);
    }
  }

  /**
   * 设置URL
   */
  public setUrl(url: string): void {
    if (this.nativePtr === 0) return;
    
    try {
      maplibre.GeoJsonSource.setUrl(this.nativePtr, url);
    } catch (error) {
      console.error(`Failed to set URL: ${error}`);
    }
  }

  /**
   * 获取URL
   */
  public getUrl(): string | null {
    if (this.nativePtr === 0) return null;
    
    try {
      return maplibre.GeoJsonSource.getUrl(this.nativePtr);
    } catch (error) {
      console.error(`Failed to get URL: ${error}`);
      return null;
    }
  }

  /**
   * 查询数据源要素
   */
  public querySourceFeatures(filter?: Object): Feature[] {
    if (this.nativePtr === 0) return [];
    
    try {
      const filterJson = filter ? JSON.stringify(filter) : null;
      const featuresJson = maplibre.GeoJsonSource.querySourceFeatures(this.nativePtr, filterJson) as string;
      return JSON.parse(featuresJson) as Feature[];
    } catch (error) {
      console.error(`Failed to query source features: ${error}`);
      return [];
    }
  }

  /**
   * 获取聚类子项
   */
  public getClusterChildren(cluster: Feature): Feature[] {
    if (this.nativePtr === 0) return [];
    
    try {
      const clusterJson = JSON.stringify(cluster);
      const childrenJson = maplibre.GeoJsonSource.getClusterChildren(this.nativePtr, clusterJson) as string;
      return JSON.parse(childrenJson) as Feature[];
    } catch (error) {
      console.error(`Failed to get cluster children: ${error}`);
      return [];
    }
  }

  /**
   * 获取聚类叶子节点
   */
  public getClusterLeaves(cluster: Feature, limit: number, offset: number): Feature[] {
    if (this.nativePtr === 0) return [];
    
    try {
      const clusterJson = JSON.stringify(cluster);
      const leavesJson = maplibre.GeoJsonSource.getClusterLeaves(this.nativePtr, clusterJson, limit, offset) as string;
      return JSON.parse(leavesJson) as Feature[];
    } catch (error) {
      console.error(`Failed to get cluster leaves: ${error}`);
      return [];
    }
  }

  /**
   * 获取聚类展开缩放级别
   */
  public getClusterExpansionZoom(cluster: Feature): number {
    if (this.nativePtr === 0) return 0;
    
    try {
      const clusterJson = JSON.stringify(cluster);
      return maplibre.GeoJsonSource.getClusterExpansionZoom(this.nativePtr, clusterJson);
    } catch (error) {
      console.error(`Failed to get cluster expansion zoom: ${error}`);
      return 0;
    }
  }


  /**
   * 转换为字符串
   */
  public override toString(): string {
    return `GeoJsonSource(id=${this.id}, cluster=${this.geoJsonOptions?.cluster || false})`;
  }
}

