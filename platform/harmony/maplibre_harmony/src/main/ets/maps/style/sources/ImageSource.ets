import { Source, SourceOptions } from './Source';
import { LatLng } from '../../geometry/LatLng';
import { Image } from '../images/Image';
import maplibre from 'libmaplibre_native.so';

/**
 * ImageSource - 图片数据源
 * 
 * 在地图上显示由四个角坐标定位的图片
 */
export class ImageSource extends Source {
  private nativePtr: number = 0;
  private coordinates: LatLng[];

  /**
   * 创建图片数据源
   * 
   * @param id 数据源ID
   * @param coordinates 四个角的坐标 [topLeft, topRight, bottomRight, bottomLeft]
   * @param image 图片（可选）
   */
  constructor(id: string, coordinates: LatLng[], image?: Image) {
    super({
      id: id,
      type: 'image'
    });
    
    if (coordinates.length !== 4) {
      throw new Error('ImageSource requires exactly 4 coordinates');
    }
    
    this.coordinates = coordinates;
    this.initialize(id, coordinates, image);
  }

  /**
   * 初始化native对象
   */
  private initialize(id: string, coordinates: LatLng[], image?: Image): void {
    try {
      const coordsArray = coordinates.map(c => [c.longitude, c.latitude]);
      const coordsJson = JSON.stringify(coordsArray);
      const imageData = image ? image.getData() : null;
      
      this.nativePtr = maplibre.ImageSource.create(id, coordsJson, imageData);
    } catch (error) {
      console.error(`Failed to initialize ImageSource: ${error}`);
    }
  }

  /**
   * 设置图片
   */
  public setImage(image: Image): void {
    if (this.nativePtr === 0) return;
    
    try {
      const imageData = image.getData();
      maplibre.ImageSource.setImage(this.nativePtr, imageData);
    } catch (error) {
      console.error(`Failed to set image: ${error}`);
    }
  }

  /**
   * 设置坐标
   */
  public setCoordinates(coordinates: LatLng[]): void {
    if (this.nativePtr === 0) return;
    
    if (coordinates.length !== 4) {
      throw new Error('ImageSource requires exactly 4 coordinates');
    }
    
    try {
      const coordsArray = coordinates.map(c => [c.longitude, c.latitude]);
      const coordsJson = JSON.stringify(coordsArray);
      maplibre.ImageSource.setCoordinates(this.nativePtr, coordsJson);
      this.coordinates = coordinates;
    } catch (error) {
      console.error(`Failed to set coordinates: ${error}`);
    }
  }

  /**
   * 获取坐标
   */
  public getCoordinates(): LatLng[] {
    return this.coordinates;
  }


  /**
   * 转换为字符串
   */
  public override toString(): string {
    return `ImageSource(id=${this.id}, coordinates=${this.coordinates.length})`;
  }
}

