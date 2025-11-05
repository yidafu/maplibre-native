/**
 * LineLayerComponent - 声明式 Line 图层组件
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap } from '../../../maps/MapLibreMap';
import { LineLayer } from '../../../maps/style/layers/LineLayer';
import { DOMAIN } from '../../../constants/HiLogConstants';

@Component
export struct LineLayerComponent {
  @Consume('mapLibreMap') mapInstance: MapLibreMap | null;
  @Consume('sourceId') sourceId: string;
  
  @Prop layerId: string = '';
  @Prop layerVisibility: 'visible' | 'none' = 'visible';
  @Prop lineColor: string = '#000000';
  @Prop lineWidth: number = 1;
  
  private layer: LineLayer | null = null;
  private isAdded: boolean = false;
  private retryCount: number = 0;
  private maxRetries: number = 20;

  aboutToAppear(): void {
    if (!this.sourceId) {
      hilog.error(DOMAIN, 'LineLayerComponent', 'Must be child of Source component');
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

      this.layer = LineLayer.create(this.layerId, this.sourceId);
      this.layer.setVisibility(this.layerVisibility);
      if (this.lineColor) this.layer.setLineColor(this.lineColor);
      if (this.lineWidth) this.layer.setLineWidth(this.lineWidth);

      style.addLayer(this.layer);
      this.isAdded = true;
      hilog.info(DOMAIN, 'LineLayerComponent', `Layer added: ${this.layerId}`);
    } catch (error) {
      hilog.error(DOMAIN, 'LineLayerComponent', `Failed: ${error.message}`);
    }
  }

  private removeLayer(): void {
    if (this.mapInstance && this.isAdded && this.layer) {
      try {
        this.mapInstance.getStyle()?.removeLayer(this.layerId);
      } catch (error) {
        hilog.error(DOMAIN, 'LineLayerComponent', `Remove failed: ${error.message}`);
      }
    }
    this.layer = null;
    this.isAdded = false;
  }

  build() {
  }
}

