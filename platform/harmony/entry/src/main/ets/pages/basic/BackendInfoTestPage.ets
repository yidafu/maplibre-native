/**
 * BackendInfoTestPage - Show the active rendering backend and GPU.
 *
 * The backend is chosen at compile time (scripts/build-harmony.sh --backend
 * opengl|vulkan). This page verifies which backend the loaded library uses
 * and that it initialized successfully. Build one variant per backend and
 * compare behaviour on device.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';

@Entry
@Component
struct BackendInfoTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private rendererInfo: string = '(not queried yet)';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.queryRendererInfo();
  };

  private queryRendererInfo(): void {
    if (!this.mapController) {
      return;
    }
    try {
      this.rendererInfo = this.mapController.getNativeMapView().getRendererInfo();
      console.info('[BackendInfoTestPage] renderer info: ' + this.rendererInfo);
    } catch (error) {
      this.rendererInfo = 'error: ' + error.message;
      console.error('[BackendInfoTestPage] getRendererInfo failed: ' + error.message);
    }
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column({ space: 8 }) {
      Text('Renderer Info')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text(this.rendererInfo)
        .fontSize(14)
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Button('Refresh')
        .width('100%')
        .enabled(this.isMapReady)
        .onClick((): void => {
          this.queryRendererInfo();
        })

      Text('Backend is selected at build time: scripts/build-harmony.sh --backend opengl|vulkan')
        .fontSize(12)
        .fontColor('#757575')
        .width('100%')
    }
    .width('100%')
    .padding(12)
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'Renderer Backend Info',
        subtitle: 'Active graphics backend (OpenGL ES / Vulkan)',
        mapContent: (): void => this.mapContent(),
        controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
