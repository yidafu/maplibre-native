import { MapLibreMap } from './MapLibreMap';

/**
 * MapViewComponentController - 地图视图组件控制器
 * 提供对地图实例的访问和生命周期管理
 */
export class MapViewComponentController {
  private xComponentController: XComponentController = new XComponentController();
  private mapLibreMap: MapLibreMap | null = null;
  private onMapReadyCallback?: (map: MapLibreMap) => void;

  /**
   * 获取 XComponentController 实例
   */
  public getXComponentController(): XComponentController {
    return this.xComponentController;
  }

  /**
   * 设置地图准备完成的回调
   */
  public setOnMapReadyCallback(callback: (map: MapLibreMap) => void): void {
    this.onMapReadyCallback = callback;
  }

  /**
   * XComponent onCreate 回调
   */
  public onCreate(): void {
    console.info('MapViewComponentController: onCreate');
    // 这里可以进行一些初始化工作
  }

  /**
   * 设置 MapLibreMap 实例
   */
  public setMapLibreMap(map: MapLibreMap): void {
    this.mapLibreMap = map;
    if (this.onMapReadyCallback) {
      this.onMapReadyCallback(map);
    }
  }

  /**
   * 获取 MapLibreMap 实例
   */
  public getMapLibreMap(): MapLibreMap | null {
    return this.mapLibreMap;
  }
}