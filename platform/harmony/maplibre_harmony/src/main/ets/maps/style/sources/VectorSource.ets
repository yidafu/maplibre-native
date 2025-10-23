import { Source, SourceOptions } from './Source';
import { TileSet } from './TileSet';
import { Feature } from '../../geojson/Feature';
import maplibre from 'libmaplibre_native.so';

/**
 * VectorSource - 矢量瓦片数据源
 * 
 * 支持TileJSON URL和TileSet配置
 */
export class VectorSource extends Source {
  private nativePtr: number = 0;

  /**
   * 从URL创建矢量数据源
   */
  constructor(id: string, url: string) {
    super({
      id: id,
      type: 'vector',
      url: url
    });
    this.initializeWithUrl(id, url);
  }

  /**
   * 从TileSet创建矢量数据源
   */
  public static withTileSet(id: string, tileSet: TileSet): VectorSource {
    const source = new VectorSource(id, '');
    source.initializeWithTileSet(id, tileSet);
    return source;
  }

  /**
   * 使用URL初始化
   */
  private initializeWithUrl(id: string, url: string): void {
    try {
      this.nativePtr = maplibre.VectorSource.createWithUrl(id, url);
    } catch (error) {
      console.error(`Failed to initialize VectorSource with URL: ${error}`);
    }
  }

  /**
   * 使用TileSet初始化
   */
  private initializeWithTileSet(id: string, tileSet: TileSet): void {
    try {
      const tileSetJson = JSON.stringify(tileSet.toJSON());
      this.nativePtr = maplibre.VectorSource.createWithTileSet(id, tileSetJson);
    } catch (error) {
      console.error(`Failed to initialize VectorSource with TileSet: ${error}`);
    }
  }

  /**
   * 查询数据源要素
   */
  public querySourceFeatures(sourceLayerId: string, filter?: Object): Feature[] {
    if (this.nativePtr === 0) return [];
    
    try {
      const filterJson = filter ? JSON.stringify(filter) : null;
      const featuresJson = maplibre.VectorSource.querySourceFeatures(this.nativePtr, sourceLayerId, filterJson);
      return JSON.parse(featuresJson) as Feature[];
    } catch (error) {
      console.error(`Failed to query source features: ${error}`);
      return [];
    }
  }

  /**
   * 获取原生指针
   */
  public override getNativePtr(): number {
    return this.nativePtr;
  }

  /**
   * 转换为字符串
   */
  public override toString(): string {
    return `VectorSource(id=${this.id})`;
  }
}

