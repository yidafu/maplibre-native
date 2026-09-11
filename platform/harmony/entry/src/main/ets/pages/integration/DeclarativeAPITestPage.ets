/**
 * DeclarativeAPITestPage - Demo of HarmonyOS declarative map API.
 *
 * Shows how to use MapView with @State properties, reactive style changes,
 * and builder params. Includes buttons to toggle between street/satellite styles,
 * toggle layers, and show map state info.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraState } from 'maplibre_harmony';
import { StyleLoadedListener } from '../../utils/ListenerFactories';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct DeclarativeAPITestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private currentStyleUrl: string = DEFAULT_STYLE_URLS.streets;
  @State private currentStyleName: string = 'Streets';
  @State private zoom: number = 0;
  @State private bearing: number = 0;
  @State private pitch: number = 0;
  @State private isLayerVisible: boolean = true;

  private readonly LAYER_ID: string = 'road-label';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.refreshCameraState();
    showToast('Map ready');
    console.info('[DeclarativeAPITestPage] Map ready');
  };

  private refreshCameraState(): void {
    if (!this.mapController) return;
    const state: CameraState = this.mapController.getCameraState();
    this.zoom = state.zoom;
    this.bearing = state.bearing;
    this.pitch = state.pitch;
  }

  private switchStyle(name: string, url: string): void {
    if (!this.mapController) return;
    this.currentStyleName = name;
    this.currentStyleUrl = url;
    this.mapController.setStyleUrl(url);
    const listener = new StyleLoadedListener(
      (): void => {
        this.refreshCameraState();
        showToast(`Style: ${name}`);
      }
    );
    this.mapController.addOnStyleLoadedListener(listener);
  }

  private toggleLayer(): void {
    if (!this.mapController) return;
    this.isLayerVisible = !this.isLayerVisible;
    try {
      const layer = this.mapController.getLayer(this.LAYER_ID);
      if (layer) {
        // setVisibility is available on all concrete layer types
        layer.setVisibility(this.isLayerVisible ? 'visible' : 'none')
        showToast(`Layer ${this.LAYER_ID}: ${this.isLayerVisible ? 'visible' : 'hidden'}`);
      } else {
        showToast(`Layer not found: ${this.LAYER_ID}`);
      }
    } catch (e) {
      showToast(`Layer toggle error: ${e}`);
    }
  }

  @Builder
  mapContent() {
    // Demonstrates reactive @State binding: changing currentStyleUrl
    // triggers MapView to reload with the new style
    MapView({
      styleUrl: this.currentStyleUrl,
      onMapReady: this.onMapReady,
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      // Camera state info — updates when user interacts with the map
      Text(`Zoom: ${this.zoom.toFixed(1)} | Bearing: ${this.bearing.toFixed(1)} | Pitch: ${this.pitch.toFixed(1)}`)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      // Style toggle section — @State-driven reactive UI
      Text('Reactive Style (via @State)')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Row() {
        Button('Streets')
          .layoutWeight(1)
          .backgroundColor(this.currentStyleName === 'Streets' ? '#2196F3' : '#9E9E9E')
          .onClick(() => this.switchStyle('Streets', DEFAULT_STYLE_URLS.streets))
          .enabled(this.isMapReady)

        Button('Satellite')
          .layoutWeight(1)
          .margin({ left: 8 })
          .backgroundColor(this.currentStyleName === 'Satellite' ? '#2196F3' : '#9E9E9E')
          .onClick(() => this.switchStyle('Satellite', DEFAULT_STYLE_URLS.satellite))
          .enabled(this.isMapReady)
      }
      .width('100%')

      Button('Bright')
        .width('100%')
        .margin({ top: 8 })
        .onClick(() => this.switchStyle('Bright', DEFAULT_STYLE_URLS.bright))
        .enabled(this.isMapReady)

      // Layer visibility control
      Text('Layer Control')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button(`Toggle Layer (${this.LAYER_ID}): ${this.isLayerVisible ? 'ON' : 'OFF'}`)
        .width('100%')
        .onClick(() => this.toggleLayer())
        .enabled(this.isMapReady)

      // Camera state refresh
      Button('Refresh Camera State')
        .width('100%')
        .margin({ top: 8 })
        .onClick(() => {
          this.refreshCameraState();
          showToast('Camera state refreshed');
        })
        .enabled(this.isMapReady)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Declarative API',
      subtitle: 'Reactive style and layer demo',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
