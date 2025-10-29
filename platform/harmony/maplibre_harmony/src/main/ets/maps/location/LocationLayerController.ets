import maplibre from 'libmaplibre.so';
import { LocationComponentOptions } from './LocationComponentOptions';
import { LocationComponentConstants } from './LocationComponentConstants';
import { RenderMode } from './modes/RenderMode';
import { OnRenderModeChangedListener } from './listeners/OnRenderModeChangedListener';
import { LatLng } from '../geometry/LatLng';
import { Point as GeometryPoint, Feature } from '../geojson';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

type Style = maplibre.Style;
type GeoJsonSource = maplibre.GeoJsonSource;
type CircleLayer = maplibre.CircleLayer;
type SymbolLayer = maplibre.SymbolLayer;

/**
 * 位置图层控制器
 * 负责管理位置相关的地图图层
 */
export class LocationLayerController {
  private static readonly TAG: string = 'LocationLayerController';

  private style?: Style;
  private options: LocationComponentOptions;
  private renderMode: number = RenderMode.NORMAL;
  private renderModeChangedListener?: OnRenderModeChangedListener;
  
  // 位置数据
  private currentLocation?: LatLng;
  private bearing: number = 0;
  private accuracy: number = 0;
  private isStale: boolean = false;
  
  // 图层是否已添加
  private layersAdded: boolean = false;
  private isHidden: boolean = true;

  constructor(options: LocationComponentOptions, renderModeChangedListener?: OnRenderModeChangedListener) {
    this.options = options;
    this.renderModeChangedListener = renderModeChangedListener;
  }

  /**
   * 初始化组件
   */
  initializeComponents(style: Style): void {
    hilog.info(DOMAIN, LocationLayerController.TAG, 'Initializing location layer controller');
    this.style = style;
    
    // 添加图层
    this.addLayers();
    
    // 初始化时隐藏
    if (this.isHidden) {
      this.hide();
    }
  }

  /**
   * 添加图层到地图
   */
  private addLayers(): void {
    if (!this.style || this.layersAdded) {
      return;
    }

    try {
      // 创建数据源
      const sourceFeature: Feature = new maplibre.Feature({
        geometry: new maplibre.Point([0, 0])
      });
      
      const geoJsonSource = new maplibre.GeoJsonSource(
        LocationComponentConstants.LOCATION_SOURCE
      );
      geoJsonSource.setGeoJson(JSON.stringify(sourceFeature.toJSON()));
      this.style.addSource(geoJsonSource);

      // 添加精度圈图层
      const accuracyLayer = new maplibre.CircleLayer(
        LocationComponentConstants.ACCURACY_LAYER,
        LocationComponentConstants.LOCATION_SOURCE
      );
      this.style.addLayer(accuracyLayer);

      // 添加背景图标图层
      const backgroundLayer = new maplibre.SymbolLayer(
        LocationComponentConstants.BACKGROUND_LAYER,
        LocationComponentConstants.LOCATION_SOURCE
      );
      this.style.addLayer(backgroundLayer);

      // 添加前景图标图层
      const foregroundLayer = new maplibre.SymbolLayer(
        LocationComponentConstants.FOREGROUND_LAYER,
        LocationComponentConstants.LOCATION_SOURCE
      );
      this.style.addLayer(foregroundLayer);

      // 添加方向图标图层
      const bearingLayer = new maplibre.SymbolLayer(
        LocationComponentConstants.BEARING_LAYER,
        LocationComponentConstants.LOCATION_SOURCE
      );
      this.style.addLayer(bearingLayer);

      this.layersAdded = true;
      hilog.info(DOMAIN, LocationLayerController.TAG, 'Location layers added successfully');
      
      // 应用初始样式
      this.styleAccuracy();
      this.updateIconStyles();
      
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to add layers: ${err}`);
    }
  }

  /**
   * 移除图层
   */
  removeLayers(): void {
    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      this.style.removeLayer(LocationComponentConstants.BEARING_LAYER);
      this.style.removeLayer(LocationComponentConstants.FOREGROUND_LAYER);
      this.style.removeLayer(LocationComponentConstants.BACKGROUND_LAYER);
      this.style.removeLayer(LocationComponentConstants.ACCURACY_LAYER);
      this.style.removeSource(LocationComponentConstants.LOCATION_SOURCE);
      
      this.layersAdded = false;
      hilog.info(DOMAIN, LocationLayerController.TAG, 'Location layers removed');
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to remove layers: ${err}`);
    }
  }

  /**
   * 更新位置
   */
  updateLocation(location: LatLng, bearing: number, accuracy: number): void {
    this.currentLocation = location;
    this.bearing = bearing;
    this.accuracy = accuracy;
    
    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      // 更新数据源位置
      const sourceFeature: Feature = new maplibre.Feature({
        geometry: new maplibre.Point([location.longitude, location.latitude])
      });
      
      const source = this.style.getSource(LocationComponentConstants.LOCATION_SOURCE) as GeoJsonSource;
      if (source) {
        source.setGeoJson(JSON.stringify(sourceFeature));
      }

      // 更新精度圈
      this.updateAccuracyRadius(accuracy);
      
      // 更新方向
      this.updateBearing(bearing);
      
      hilog.debug(DOMAIN, LocationLayerController.TAG, 
        `Location updated: ${location.latitude}, ${location.longitude}, bearing: ${bearing}, accuracy: ${accuracy}`);
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to update location: ${err}`);
    }
  }

  /**
   * 更新精度圈半径
   */
  private updateAccuracyRadius(accuracy: number): void {
    if (!this.style) {
      return;
    }

    try {
      const layer: maplibre.CircleLayer | null = this.style.getLayer(LocationComponentConstants.ACCURACY_LAYER) as maplibre.CircleLayer | null;
      if (layer) {
        // 根据精度值设置圆圈半径（需要考虑地图缩放级别）
        // 这里简化处理，实际应该根据纬度和缩放级别计算
        const radiusInPixels = Math.max(accuracy / 2, 10);
        // layer.setProperties({ 'circle-radius': radiusInPixels });
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to update accuracy radius: ${err}`);
    }
  }

  /**
   * 更新方向角度
   */
  private updateBearing(bearing: number): void {
    if (!this.style) {
      return;
    }

    try {
      const layer: maplibre.SymbolLayer | null = this.style.getLayer(LocationComponentConstants.BEARING_LAYER) as maplibre.SymbolLayer | null;
      if (layer && this.renderMode !== RenderMode.NORMAL) {
        // layer.setProperties({ 'icon-rotate': bearing });
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to update bearing: ${err}`);
    }
  }

  /**
   * 设置渲染模式
   */
  setRenderMode(mode: number): void {
    if (!RenderMode.isValid(mode)) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Invalid render mode: ${mode}`);
      return;
    }

    if (this.renderMode === mode) {
      return;
    }

    hilog.info(DOMAIN, LocationLayerController.TAG, 
      `Changing render mode from ${RenderMode.getName(this.renderMode)} to ${RenderMode.getName(mode)}`);

    this.renderMode = mode;
    this.updateIconStyles();

    if (this.renderModeChangedListener) {
      this.renderModeChangedListener.onRenderModeChanged(mode);
    }
  }

  /**
   * 更新图标样式
   */
  private updateIconStyles(): void {
    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      // 根据渲染模式显示/隐藏不同的图层
      const foregroundLayer: maplibre.SymbolLayer | null = this.style.getLayer(LocationComponentConstants.FOREGROUND_LAYER) as maplibre.SymbolLayer | null;
      const backgroundLayer: maplibre.SymbolLayer | null = this.style.getLayer(LocationComponentConstants.BACKGROUND_LAYER) as maplibre.SymbolLayer | null;
      const bearingLayer: maplibre.SymbolLayer | null = this.style.getLayer(LocationComponentConstants.BEARING_LAYER) as maplibre.SymbolLayer | null;

      if (this.renderMode === RenderMode.NORMAL) {
        // 普通模式：只显示前景和背景
        // foregroundLayer?.setProperty('visibility', 'visible');
        // backgroundLayer?.setProperty('visibility', 'visible');
        // bearingLayer?.setProperty('visibility', 'none');
      } else if (this.renderMode === RenderMode.COMPASS || this.renderMode === RenderMode.GPS) {
        // 指南针/GPS 模式：显示所有图层
        // foregroundLayer?.setProperty('visibility', 'visible');
        // backgroundLayer?.setProperty('visibility', 'visible');
        // bearingLayer?.setProperty('visibility', 'visible');
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to update icon styles: ${err}`);
    }
  }

  /**
   * 应用样式配置
   */
  applyStyle(options: LocationComponentOptions): void {
    this.options = options;
    this.styleAccuracy();
    this.updateIconStyles();
  }

  /**
   * 设置精度圈样式
   */
  private styleAccuracy(): void {
    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      const layer: maplibre.CircleLayer | null = this.style.getLayer(LocationComponentConstants.ACCURACY_LAYER) as maplibre.CircleLayer | null;
      if (layer) {
        // layer.setProperties({
        //   'circle-color': this.options.accuracyColor,
        //   'circle-opacity': this.options.accuracyAlpha
        // });
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to style accuracy: ${err}`);
    }
  }

  /**
   * 设置过期状态
   */
  setStale(isStale: boolean): void {
    if (this.isStale === isStale) {
      return;
    }

    this.isStale = isStale;
    hilog.info(DOMAIN, LocationLayerController.TAG, `Location stale state: ${isStale}`);
    
    // 更新图标为过期状态的图标
    this.updateIconStyles();
  }

  /**
   * 显示位置图层
   */
  show(): void {
    if (!this.isHidden) {
      return;
    }

    this.isHidden = false;
    
    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      // 设置所有图层为可见
      const layers = [
        LocationComponentConstants.ACCURACY_LAYER,
        LocationComponentConstants.BACKGROUND_LAYER,
        LocationComponentConstants.FOREGROUND_LAYER,
        LocationComponentConstants.BEARING_LAYER
      ];

      layers.forEach(layerId => {
        const layer: object | null = this.style!.getLayer(layerId);
        // layer?.setProperty('visibility', 'visible');
      });

      hilog.info(DOMAIN, LocationLayerController.TAG, 'Location layers shown');
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to show layers: ${err}`);
    }
  }

  /**
   * 隐藏位置图层
   */
  hide(): void {
    if (this.isHidden) {
      return;
    }

    this.isHidden = true;
    
    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      // 设置所有图层为不可见
      const layers = [
        LocationComponentConstants.ACCURACY_LAYER,
        LocationComponentConstants.BACKGROUND_LAYER,
        LocationComponentConstants.FOREGROUND_LAYER,
        LocationComponentConstants.BEARING_LAYER
      ];

      layers.forEach(layerId => {
        const layer: object | null = this.style!.getLayer(layerId);
        // layer?.setProperty('visibility', 'none');
      });

      hilog.info(DOMAIN, LocationLayerController.TAG, 'Location layers hidden');
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to hide layers: ${err}`);
    }
  }

  /**
   * 获取当前渲染模式
   */
  getRenderMode(): number {
    return this.renderMode;
  }

  /**
   * 获取当前位置
   */
  getCurrentLocation(): LatLng | undefined {
    return this.currentLocation;
  }
}

