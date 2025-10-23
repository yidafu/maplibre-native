import { Source, SourceOptions } from './Source';
import { TileSet } from './TileSet';
import maplibre from 'libmaplibre_native.so';

/**
 * RasterSource - 栅格瓦片数据源
 * 
 * 用于显示栅格瓦片图层
 */
export class RasterSource extends Source {
  private nativePtr: number = 0;
  private _tileSize: number;

  /**
   * 从URL创建栅格数据源
   */
  constructor(id: string, url: string, tileSize: number = 512) {
    super({
      id: id,
      type: 'raster',
      url: url,
      tileSize: tileSize
    });
    this._tileSize = tileSize;
    this.initializeWithUrl(id, url, tileSize);
  }

  /**
   * 从TileSet创建栅格数据源
   */
  public static withTileSet(id: string, tileSet: TileSet, tileSize: number = 512): RasterSource {
    const source = new RasterSource(id, '');
    source._tileSize = tileSize;
    source.initializeWithTileSet(id, tileSet, tileSize);
    return source;
  }

  /**
   * 使用URL初始化
   */
  private initializeWithUrl(id: string, url: string, tileSize: number): void {
    try {
      this.nativePtr = maplibre.RasterSource.createWithUrl(id, url, tileSize);
    } catch (error) {
      console.error(`Failed to initialize RasterSource with URL: ${error}`);
    }
  }

  /**
   * 使用TileSet初始化
   */
  private initializeWithTileSet(id: string, tileSet: TileSet, tileSize: number): void {
    try {
      const tileSetJson = JSON.stringify(tileSet.toJSON());
      this.nativePtr = maplibre.RasterSource.createWithTileSet(id, tileSetJson, tileSize);
    } catch (error) {
      console.error(`Failed to initialize RasterSource with TileSet: ${error}`);
    }
  }

  /**
   * 获取瓦片大小
   */
  public getTileSize(): number {
    return this._tileSize;
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
    return `RasterSource(id=${this.id}, tileSize=${this._tileSize})`;
  }
}

