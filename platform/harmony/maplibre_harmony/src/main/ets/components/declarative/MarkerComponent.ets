/**
 * MarkerComponent - 声明式 Marker 组件
 * 
 * 提供声明式 API 来创建和管理地图标记
 * 注意：由于 ArkTS 限制，不支持属性的响应式更新
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Marker } from '../../maps/annotations/Marker';
import { MarkerOptions } from '../../maps/annotations/MarkerOptions';
import { MapLibreMap } from '../../maps/MapLibreMap';
import { LatLng } from '../../maps/geometry/LatLng';
import type { ILatLng } from '../../maps/types/NativeTypes';
import { DOMAIN } from '../../constants/HiLogConstants';

export interface MarkerComponentParams {
  markerPosition: ILatLng;
  markerTitle?: string;
  markerSnippet?: string;
  markerDraggable?: boolean;
}

@Component
export struct MarkerComponent {
  @Consume('mapLibreMap') mapInstance: MapLibreMap | null;
  
  @Prop markerPosition: ILatLng = { latitude: 0, longitude: 0 };
  @Prop markerTitle: string = '';
  @Prop markerSnippet: string = '';
  @Prop markerDraggable: boolean = false;
  
  private marker: Marker | null = null;
  private isAdded: boolean = false;
  private retryCount: number = 0;
  private maxRetries: number = 20;

  aboutToAppear(): void {
    hilog.debug(DOMAIN, 'MarkerComponent', 'aboutToAppear');
    this.tryAddMarker();
  }

  aboutToDisappear(): void {
    hilog.debug(DOMAIN, 'MarkerComponent', 'aboutToDisappear');
    this.removeMarker();
  }

  private tryAddMarker(): void {
    if (this.mapInstance && !this.isAdded) {
      this.addMarker();
    } else if (!this.mapInstance && this.retryCount < this.maxRetries) {
      this.retryCount++;
      setTimeout(() => this.tryAddMarker(), 50);
    }
  }

  private async addMarker(): Promise<void> {
    if (!this.mapInstance || this.isAdded) return;

    try {
      const options = new MarkerOptions()
        .position(new LatLng(this.markerPosition.latitude, this.markerPosition.longitude))
        .draggable(this.markerDraggable);
      
      if (this.markerTitle) options.title(this.markerTitle);
      if (this.markerSnippet) options.snippet(this.markerSnippet);

      this.marker = await this.mapInstance.addMarker(options);
      this.isAdded = true;
      
      hilog.info(DOMAIN, 'MarkerComponent', `Marker added: ${this.marker.getId()}`);
    } catch (error) {
      hilog.error(DOMAIN, 'MarkerComponent', `Failed to add marker: ${error.message}`);
    }
  }

  private removeMarker(): void {
    if (this.mapInstance && this.isAdded && this.marker) {
      try {
        this.mapInstance.removeMarker(this.marker);
        hilog.info(DOMAIN, 'MarkerComponent', `Marker removed`);
      } catch (error) {
        hilog.error(DOMAIN, 'MarkerComponent', `Failed to remove marker: ${error.message}`);
      }
    }
    this.marker = null;
    this.isAdded = false;
  }

  build() {
  }
}
