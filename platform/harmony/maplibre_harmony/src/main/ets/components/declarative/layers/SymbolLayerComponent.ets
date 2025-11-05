/**
 * SymbolLayerComponent - 声明式 Symbol 图层组件
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap } from '../../../maps/MapLibreMap';
import { SymbolLayer } from '../../../maps/style/layers/SymbolLayer';
import type { PropertyValue } from '../../../maps/style/expressions/index';
import { DOMAIN } from '../../../constants/HiLogConstants';

@Component
export struct SymbolLayerComponent {
  @Consume('mapLibreMap') mapInstance: MapLibreMap | null;
  @Consume('sourceId') sourceId: string;
  
  @Prop layerId: string = '';
  @Prop layerVisibility: 'visible' | 'none' = 'visible';
  @Prop layerMinZoom: number = 0;
  @Prop layerMaxZoom: number = 24;
  
  @Prop iconImage: string = '';
  @Prop iconSize: number = 1;
  @Prop textField: string = '';
  @Prop textSize: number = 16;
  @Prop textColor: string = '#000000';
  
  private layer: SymbolLayer | null = null;
  private isAdded: boolean = false;
  private retryCount: number = 0;
  private maxRetries: number = 20;

  aboutToAppear(): void {
    if (!this.sourceId) {
      hilog.error(DOMAIN, 'SymbolLayerComponent', 'Must be child of Source component');
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

      this.layer = SymbolLayer.create(this.layerId, this.sourceId);
      this.layer.setVisibility(this.layerVisibility);
      
      if (this.layerMinZoom > 0) this.layer.setMinZoom(this.layerMinZoom);
      if (this.layerMaxZoom < 24) this.layer.setMaxZoom(this.layerMaxZoom);
      if (this.iconImage) this.layer.setIconImage(this.iconImage);
      if (this.iconSize) this.layer.setIconSize(this.iconSize);
      if (this.textField) this.layer.setTextField(this.textField);
      if (this.textSize) this.layer.setTextSize(this.textSize);
      if (this.textColor) this.layer.setTextColor(this.textColor);

      style.addLayer(this.layer);
      this.isAdded = true;
      hilog.info(DOMAIN, 'SymbolLayerComponent', `Layer added: ${this.layerId}`);
    } catch (error) {
      hilog.error(DOMAIN, 'SymbolLayerComponent', `Failed: ${error.message}`);
    }
  }

  private removeLayer(): void {
    if (this.mapInstance && this.isAdded && this.layer) {
      try {
        this.mapInstance.getStyle()?.removeLayer(this.layerId);
      } catch (error) {
        hilog.error(DOMAIN, 'SymbolLayerComponent', `Remove failed: ${error.message}`);
      }
    }
    this.layer = null;
    this.isAdded = false;
  }

  build() {
  }
}

