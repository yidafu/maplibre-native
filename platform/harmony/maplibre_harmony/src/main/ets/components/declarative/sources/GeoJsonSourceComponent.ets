/**
 * GeoJsonSourceComponent - 声明式 GeoJsonSource 组件
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap } from '../../../maps/MapLibreMap';
import { GeoJsonSource, GeoJsonData } from '../../../maps/style/sources/GeoJsonSource';
import { GeoJsonOptions } from '../../../maps/style/sources/GeoJsonOptions';
import { DOMAIN } from '../../../constants/HiLogConstants';

export interface GeoJsonSourceComponentParams {
  id: string;
  geojson?: GeoJsonData;
  options?: GeoJsonOptions;
}

@Component
export struct GeoJsonSourceComponent {
  @Consume('mapLibreMap') mapInstance: MapLibreMap | null;
  
  @Prop sourceId: string = '';
  @Prop geojson: string = '';
  @Prop sourceOptions: GeoJsonOptions = {};
  
  @BuilderParam children?: () => void;
  @Provide('sourceId') currentSourceId: string = '';
  
  private source: GeoJsonSource | null = null;
  private isAdded: boolean = false;
  private retryCount: number = 0;
  private maxRetries: number = 20;

  aboutToAppear(): void {
    hilog.debug(DOMAIN, 'GeoJsonSourceComponent', `aboutToAppear: ${this.sourceId}`);
    this.currentSourceId = this.sourceId;
    this.tryAddSource();
  }

  aboutToDisappear(): void {
    hilog.debug(DOMAIN, 'GeoJsonSourceComponent', `aboutToDisappear: ${this.sourceId}`);
    this.removeSource();
  }

  private tryAddSource(): void {
    if (this.mapInstance && !this.isAdded) {
      const style = this.mapInstance.getStyle();
      if (style) {
        this.addSource();
      } else if (this.retryCount < this.maxRetries) {
        this.retryCount++;
        setTimeout(() => this.tryAddSource(), 50);
      }
    } else if (!this.mapInstance && this.retryCount < this.maxRetries) {
      this.retryCount++;
      setTimeout(() => this.tryAddSource(), 50);
    }
  }

  private addSource(): void {
    if (!this.mapInstance || this.isAdded) return;

    try {
      const style = this.mapInstance.getStyle();
      if (!style) return;

      if (this.geojson && this.geojson !== '') {
        this.source = GeoJsonSource.fromGeoJson(this.sourceId, this.geojson, this.sourceOptions);
      } else {
        this.source = GeoJsonSource.create(this.sourceId, this.sourceOptions);
      }

      style.addSource(this.source);
      this.isAdded = true;
      
      hilog.info(DOMAIN, 'GeoJsonSourceComponent', `GeoJsonSource added: ${this.sourceId}`);
    } catch (error) {
      hilog.error(DOMAIN, 'GeoJsonSourceComponent', `Failed to add source: ${error.message}`);
    }
  }

  private removeSource(): void {
    if (this.mapInstance && this.isAdded && this.source) {
      try {
        const style = this.mapInstance.getStyle();
        if (style) {
          style.removeSource(this.sourceId);
          hilog.info(DOMAIN, 'GeoJsonSourceComponent', `GeoJsonSource removed: ${this.sourceId}`);
        }
      } catch (error) {
        hilog.error(DOMAIN, 'GeoJsonSourceComponent', `Failed to remove source: ${error.message}`);
      }
    }
    this.source = null;
    this.isAdded = false;
  }

  build() {
    if (this.children) {
      this.children()
    }
  }
}

