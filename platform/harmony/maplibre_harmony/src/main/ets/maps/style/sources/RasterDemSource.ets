import { Source, SourceOptions } from './Source';
import { TileSet } from './TileSet';
import maplibre from 'libmaplibre_native.so';

/**
 * DEM编码类型
 */
export enum DemEncoding {
  MAPBOX = 'mapbox',
  TERRARIUM = 'terrarium'
}

/**
 * RasterDemSource - DEM（数字高程模型）栅格数据源
 * 
 * 用于山体阴影等地形可视化
 */
export class RasterDemSource extends Source {
  private nativePtr: number = 0;
  private encoding: DemEncoding;

  /**
   * 从URL创建DEM数据源
   */
  constructor(id: string, url: string, encoding: DemEncoding = DemEncoding.MAPBOX) {
    super({
      id: id,
      type: 'raster-dem',
      url: url
    });
    this.encoding = encoding;
    this.initializeWithUrl(id, url, encoding);
  }

  /**
   * 从TileSet创建DEM数据源
   */
  public static withTileSet(id: string, tileSet: TileSet, encoding: DemEncoding = DemEncoding.MAPBOX): RasterDemSource {
    const source = new RasterDemSource(id, '', encoding);
    source.initializeWithTileSet(id, tileSet, encoding);
    return source;
  }

  /**
   * 使用URL初始化
   */
  private initializeWithUrl(id: string, url: string, encoding: DemEncoding): void {
    try {
      this.nativePtr = maplibre.RasterDemSource.createWithUrl(id, url, encoding);
    } catch (error) {
      console.error(`Failed to initialize RasterDemSource with URL: ${error}`);
    }
  }

  /**
   * 使用TileSet初始化
   */
  private initializeWithTileSet(id: string, tileSet: TileSet, encoding: DemEncoding): void {
    try {
      const tileSetJson = JSON.stringify(tileSet.toJSON());
      this.nativePtr = maplibre.RasterDemSource.createWithTileSet(id, tileSetJson, encoding);
    } catch (error) {
      console.error(`Failed to initialize RasterDemSource with TileSet: ${error}`);
    }
  }

  /**
   * 获取编码类型
   */
  public getEncoding(): DemEncoding {
    return this.encoding;
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
    return `RasterDemSource(id=${this.id}, encoding=${this.encoding})`;
  }
}

