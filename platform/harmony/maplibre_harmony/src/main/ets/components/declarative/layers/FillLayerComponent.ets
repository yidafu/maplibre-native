/**
 * FillLayerComponent - 声明式 Fill 图层组件
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap } from '../../../maps/MapLibreMap';
import { FillLayer } from '../../../maps/style/layers/FillLayer';
import { DOMAIN } from '../../../constants/HiLogConstants';

@Component
export struct FillLayerComponent {
  @Consume('mapLibreMap') mapInstance: MapLibreMap | null;
  @Consume('sourceId') sourceId: string;
  
  @Prop layerId: string = '';
  @Prop layerVisibility: 'visible' | 'none' = 'visible';
  @Prop fillColor: string = '#000000';
  @Prop fillOpacity: number = 1;
  
  private layer: FillLayer | null = null;
  private isAdded: boolean = false;
  private retryCount: number = 0;
  private maxRetries: number = 20;

  aboutToAppear(): void {
    if (!this.sourceId) {
      hilog.error(DOMAIN, 'FillLayerComponent', 'Must be child of Source component');
      return;
    }
    this.tryAddLayer();
  }

  aboutToDisappear(): void {
    this.removeLayer();
  }

  private tryAddLayer(): void {
    if (this.mapInstance && !this.isAdded) {
      const style = this.mapInstance.getStyle();
      if (style) {
        this.addLayer();
      } else if (this.retryCount < this.maxRetries) {
        this.retryCount++;
        setTimeout(() => this.tryAddLayer(), 50);
      }
    } else if (!this.mapInstance && this.retryCount < this.maxRetries) {
      this.retryCount++;
      setTimeout(() => this.tryAddLayer(), 50);
    }
  }

  private addLayer(): void {
    if (!this.mapInstance || this.isAdded) return;

    try {
      const style = this.mapInstance.getStyle();
      if (!style) return;

      this.layer = FillLayer.create(this.layerId, this.sourceId);
      this.layer.setVisibility(this.layerVisibility);
      if (this.fillColor) this.layer.setFillColor(this.fillColor);
      if (this.fillOpacity) this.layer.setFillOpacity(this.fillOpacity);

      style.addLayer(this.layer);
      this.isAdded = true;
      hilog.info(DOMAIN, 'FillLayerComponent', `Layer added: ${this.layerId}`);
    } catch (error) {
      hilog.error(DOMAIN, 'FillLayerComponent', `Failed: ${error.message}`);
    }
  }

  private removeLayer(): void {
    if (this.mapInstance && this.isAdded && this.layer) {
      try {
        this.mapInstance.getStyle()?.removeLayer(this.layerId);
      } catch (error) {
        hilog.error(DOMAIN, 'FillLayerComponent', `Remove failed: ${error.message}`);
      }
    }
    this.layer = null;
    this.isAdded = false;
  }

  build() {
  }
}
