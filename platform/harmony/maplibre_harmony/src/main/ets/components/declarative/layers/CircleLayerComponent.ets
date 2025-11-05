/**
 * CircleLayerComponent - 声明式 Circle 图层组件
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap } from '../../../maps/MapLibreMap';
import { CircleLayer } from '../../../maps/style/layers/CircleLayer';
import { DOMAIN } from '../../../constants/HiLogConstants';

@Component
export struct CircleLayerComponent {
  @Consume('mapLibreMap') mapInstance: MapLibreMap | null;
  @Consume('sourceId') sourceId: string;
  
  @Prop layerId: string = '';
  @Prop layerVisibility: 'visible' | 'none' = 'visible';
  @Prop circleRadius: number = 5;
  @Prop circleColor: string = '#000000';
  @Prop circleStrokeWidth: number = 0;
  @Prop circleStrokeColor: string = '#FFFFFF';
  
  private layer: CircleLayer | null = null;
  private isAdded: boolean = false;
  private retryCount: number = 0;
  private maxRetries: number = 20;

  aboutToAppear(): void {
    if (!this.sourceId) {
      hilog.error(DOMAIN, 'CircleLayerComponent', 'Must be child of Source component');
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

      this.layer = CircleLayer.create(this.layerId, this.sourceId);
      this.layer.setVisibility(this.layerVisibility);
      if (this.circleRadius) this.layer.setCircleRadius(this.circleRadius);
      if (this.circleColor) this.layer.setCircleColor(this.circleColor);
      if (this.circleStrokeWidth) this.layer.setCircleStrokeWidth(this.circleStrokeWidth);
      if (this.circleStrokeColor) this.layer.setCircleStrokeColor(this.circleStrokeColor);

      style.addLayer(this.layer);
      this.isAdded = true;
      hilog.info(DOMAIN, 'CircleLayerComponent', `Layer added: ${this.layerId}`);
    } catch (error) {
      hilog.error(DOMAIN, 'CircleLayerComponent', `Failed: ${error.message}`);
    }
  }

  private removeLayer(): void {
    if (this.mapInstance && this.isAdded && this.layer) {
      try {
        this.mapInstance.getStyle()?.removeLayer(this.layerId);
      } catch (error) {
        hilog.error(DOMAIN, 'CircleLayerComponent', `Remove failed: ${error.message}`);
      }
    }
    this.layer = null;
    this.isAdded = false;
  }

  build() {
  }
}
