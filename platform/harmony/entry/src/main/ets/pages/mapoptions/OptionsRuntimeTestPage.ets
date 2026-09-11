/**
 * OptionsRuntimeTestPage - Test changing map options at runtime.
 *
 * Demonstrates dynamic configuration of zoom limits, pitch limits,
 * scroll/rotate/tilt gestures, prefetch tiles, and debug options
 * after the map has been initialised.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, MapLibreMapOptions, MapDebugOptions
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct OptionsRuntimeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Map ready';
  @State private minZoom: number = 0;
  @State private maxZoom: number = 22;
  @State private minPitch: number = 0;
  @State private maxPitch: number = 60;
  @State private scrollEnabled: boolean = true;
  @State private rotateEnabled: boolean = true;
  @State private tiltEnabled: boolean = true;
  @State private doubleTapZoom: boolean = true;
  @State private prefetchTiles: boolean = true;
  @State private debugActive: boolean = false;

  private readonly DEFAULT_MIN_ZOOM: number = 0;
  private readonly DEFAULT_MAX_ZOOM: number = 22;
  private readonly DEFAULT_MIN_PITCH: number = 0;
  private readonly DEFAULT_MAX_PITCH: number = 60;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    // Read current values
    this.minZoom = map.getMinZoom();
    this.maxZoom = map.getMaxZoom();
    this.minPitch = map.getMinPitch();
    this.maxPitch = map.getMaxPitch();
    this.prefetchTiles = map.getPrefetchTiles();
    this.statusMessage = 'Map ready - options loaded';
    console.info('[OptionsRuntimeTestPage] Map ready');
  };

  private applyMinZoom(): void {
    if (!this.mapController) return;
    try {
      this.mapController.setMinZoom(this.minZoom);
      showToast(`Min zoom set to ${this.minZoom}`);
    } catch (e) {
      showToast(`Failed to set min zoom: ${e}`);
    }
  }

  private applyMaxZoom(): void {
    if (!this.mapController) return;
    try {
      this.mapController.setMaxZoom(this.maxZoom);
      showToast(`Max zoom set to ${this.maxZoom}`);
    } catch (e) {
      showToast(`Failed to set max zoom: ${e}`);
    }
  }

  private applyMinPitch(): void {
    if (!this.mapController) return;
    try {
      this.mapController.setMinPitch(this.minPitch);
      showToast(`Min pitch set to ${this.minPitch}`);
    } catch (e) {
      showToast(`Failed to set min pitch: ${e}`);
    }
  }

  private applyMaxPitch(): void {
    if (!this.mapController) return;
    try {
      this.mapController.setMaxPitch(this.maxPitch);
      showToast(`Max pitch set to ${this.maxPitch}`);
    } catch (e) {
      showToast(`Failed to set max pitch: ${e}`);
    }
  }

  private toggleScroll(): void {
    if (!this.mapController) return;
    this.scrollEnabled = !this.scrollEnabled;
    // UiSettings controls gesture enablement
    const ui = this.mapController.getUiSettings();
    if (ui) {
      ui.setScrollGesturesEnabled(this.scrollEnabled);
    }
    showToast(`Scroll gestures: ${this.scrollEnabled}`);
  }

  private toggleRotate(): void {
    if (!this.mapController) return;
    this.rotateEnabled = !this.rotateEnabled;
    const ui = this.mapController.getUiSettings();
    if (ui) {
      ui.setRotateGesturesEnabled(this.rotateEnabled);
    }
    showToast(`Rotate gestures: ${this.rotateEnabled}`);
  }

  private toggleTilt(): void {
    if (!this.mapController) return;
    this.tiltEnabled = !this.tiltEnabled;
    const ui = this.mapController.getUiSettings();
    if (ui) {
      ui.setTiltGesturesEnabled(this.tiltEnabled);
    }
    showToast(`Tilt gestures: ${this.tiltEnabled}`);
  }

  private toggleDoubleTapZoom(): void {
    if (!this.mapController) return;
    this.doubleTapZoom = !this.doubleTapZoom;
    const ui = this.mapController.getUiSettings();
    if (ui) {
      ui.setDoubleTapGesturesEnabled(this.doubleTapZoom);
    }
    showToast(`Double-tap zoom: ${this.doubleTapZoom}`);
  }

  private togglePrefetch(): void {
    if (!this.mapController) return;
    this.prefetchTiles = !this.prefetchTiles;
    this.mapController.setPrefetchTiles(this.prefetchTiles);
    showToast(`Prefetch tiles: ${this.prefetchTiles}`);
  }

  private toggleDebug(): void {
    if (!this.mapController) return;
    this.debugActive = !this.debugActive;
    this.mapController.setDebugActive(this.debugActive);
    showToast(`Debug mode: ${this.debugActive}`);
  }

  private resetToDefaults(): void {
    if (!this.mapController) return;
    this.minZoom = this.DEFAULT_MIN_ZOOM;
    this.maxZoom = this.DEFAULT_MAX_ZOOM;
    this.minPitch = this.DEFAULT_MIN_PITCH;
    this.maxPitch = this.DEFAULT_MAX_PITCH;
    this.scrollEnabled = true;
    this.rotateEnabled = true;
    this.tiltEnabled = true;
    this.doubleTapZoom = true;
    this.prefetchTiles = true;
    this.debugActive = false;

    this.mapController.setMinZoom(this.minZoom);
    this.mapController.setMaxZoom(this.maxZoom);
    this.mapController.setMinPitch(this.minPitch);
    this.mapController.setMaxPitch(this.maxPitch);
    this.mapController.setPrefetchTiles(true);
    this.mapController.setDebugActive(false);

    const ui = this.mapController.getUiSettings();
    if (ui) {
      ui.setScrollGesturesEnabled(true);
      ui.setRotateGesturesEnabled(true);
      ui.setTiltGesturesEnabled(true);
      ui.setDoubleTapGesturesEnabled(true);
    }
    showToast('All options reset to defaults');
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: TEST_LOCATIONS.hangzhou.latitude,
      initialLongitude: TEST_LOCATIONS.hangzhou.longitude,
      initialZoom: 5,
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Runtime Map Options')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      // Zoom limits
      Row() {
        Text('Min Zoom:')
          .fontSize(13)
          .width(70)
        Slider({
          value: this.minZoom,
          min: 0,
          max: 10,
          step: 1,
        })
          .layoutWeight(1)
          .onChange((v: number) => {
            this.minZoom = v;
          })
        Text(`${this.minZoom.toFixed(0)}`)
          .fontSize(13)
          .width(30)
          .textAlign(TextAlign.End)
        Button('Set')
          .fontSize(12)
          .height(28)
          .margin({ left: 4 })
          .onClick(() => this.applyMinZoom())
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 4 })

      Row() {
        Text('Max Zoom:')
          .fontSize(13)
          .width(70)
        Slider({
          value: this.maxZoom,
          min: 10,
          max: 22,
          step: 1,
        })
          .layoutWeight(1)
          .onChange((v: number) => {
            this.maxZoom = v;
          })
        Text(`${this.maxZoom.toFixed(0)}`)
          .fontSize(13)
          .width(30)
          .textAlign(TextAlign.End)
        Button('Set')
          .fontSize(12)
          .height(28)
          .margin({ left: 4 })
          .onClick(() => this.applyMaxZoom())
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 2 })

      // Gesture toggles
      Row() {
        Text('Scroll:')
          .fontSize(13)
        Toggle({ type: ToggleType.Switch, isOn: this.scrollEnabled })
          .onChange(() => this.toggleScroll())
          .enabled(this.isMapReady)
        Text('Rotate:')
          .fontSize(13)
          .margin({ left: 12 })
        Toggle({ type: ToggleType.Switch, isOn: this.rotateEnabled })
          .onChange(() => this.toggleRotate())
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 6 })

      Row() {
        Text('Tilt:')
          .fontSize(13)
        Toggle({ type: ToggleType.Switch, isOn: this.tiltEnabled })
          .onChange(() => this.toggleTilt())
          .enabled(this.isMapReady)
        Text('DblTap Zoom:')
          .fontSize(13)
          .margin({ left: 12 })
        Toggle({ type: ToggleType.Switch, isOn: this.doubleTapZoom })
          .onChange(() => this.toggleDoubleTapZoom())
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 2 })

      // Feature toggles
      Row() {
        Text('Prefetch:')
          .fontSize(13)
        Toggle({ type: ToggleType.Switch, isOn: this.prefetchTiles })
          .onChange(() => this.togglePrefetch())
          .enabled(this.isMapReady)
        Text('Debug:')
          .fontSize(13)
          .margin({ left: 12 })
        Toggle({ type: ToggleType.Switch, isOn: this.debugActive })
          .onChange(() => this.toggleDebug())
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 2 })

      Button('Reset All to Defaults')
        .width('100%')
        .margin({ top: 12 })
        .onClick(() => this.resetToDefaults())
        .enabled(this.isMapReady)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Options Runtime',
      subtitle: 'Change map options at runtime',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
