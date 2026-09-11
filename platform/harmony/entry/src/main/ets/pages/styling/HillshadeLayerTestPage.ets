/**
 * HillshadeLayerTestPage - Render terrain hillshading on the map.
 *
 * Demonstrates adding a RasterDemSource with digital elevation
 * data and styling it with a HillshadeLayer for terrain shading.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, RasterDemSource, HillshadeLayer,
  LatLng
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';
import { RasterDemSourceOptions } from 'maplibre_harmony/src/main/cpp/types/libmaplibre/sources';


@Entry
@Component
struct HillshadeLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerAdded: boolean = false;

  private readonly SOURCE_ID: string = 'hillshade-dem-source';
  private readonly LAYER_ID: string = 'hillshade-layer-test';

  // Terrain DEM tile URLs (MapTiler needs API key, using a sample)
  private readonly terrainUrl: string = 'https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add hillshade layer';
    console.info('[HillshadeLayerTestPage] Map ready');
  };

  private addHillshadeLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addHillshadeLayer(), 500);
      return;
    }

    try {
      // Add a DEM source
      const demOptions: RasterDemSourceOptions = {
        url: this.terrainUrl,
        tileSize: 256,
        encoding: 'terrarium'
      };
      const demSource = new RasterDemSource(this.SOURCE_ID, demOptions);
      style.addSource(demSource);

      // Add hillshade layer
      const layer = new HillshadeLayer(this.LAYER_ID, this.SOURCE_ID);
      layer.setHillshadeIlluminationDirection(315);
      layer.setHillshadeExaggeration(0.5);
      style.addLayer(layer);

      this.layerAdded = true;
      this.statusMessage = 'Hillshade layer added';
      showToast('Hillshade layer created');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[HillshadeLayerTestPage] Error:', err);
    }
  }

  private updateIllumination(direction: number): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as HillshadeLayer;
    if (!layer) return;

    layer.setHillshadeIlluminationDirection(direction);
    this.statusMessage = `Illumination: ${direction} deg`;
    showToast(`Direction: ${direction} deg`);
  }

  private updateExaggeration(exaggeration: number): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as HillshadeLayer;
    if (!layer) return;

    layer.setHillshadeExaggeration(exaggeration);
    this.statusMessage = `Exaggeration: ${exaggeration.toFixed(1)}`;
  }

  private removeHillshadeLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    style.removeLayer(this.LAYER_ID);
    style.removeSource(this.SOURCE_ID);
    this.layerAdded = false;
    this.statusMessage = 'Hillshade layer removed';
    showToast('Hillshade removed');
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
    Column() {
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Hillshade Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add Hillshade Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick(() => this.addHillshadeLayer())
        .enabled(this.isMapReady)

      if (this.layerAdded) {
        Text('Light Direction').fontSize(13).fontWeight(FontWeight.Bold).width('100%').margin({ top: 6 })

        Row() {
          Button('0 deg').layoutWeight(1).margin({ right: 4 }).fontSize(12)
            .onClick(() => this.updateIllumination(0))
          Button('180 deg').layoutWeight(1).margin({ right: 4 }).fontSize(12)
            .onClick(() => this.updateIllumination(180))
          Button('315 deg').layoutWeight(1).fontSize(12)
            .onClick(() => this.updateIllumination(315))
        }
        .width('100%')
        .margin({ top: 4 })

        Text('Exaggeration').fontSize(13).fontWeight(FontWeight.Bold).width('100%').margin({ top: 6 })

        Row() {
          Button('0.2').layoutWeight(1).margin({ right: 4 }).fontSize(12)
            .onClick(() => this.updateExaggeration(0.2))
          Button('0.5').layoutWeight(1).margin({ right: 4 }).fontSize(12)
            .onClick(() => this.updateExaggeration(0.5))
          Button('1.0').layoutWeight(1).fontSize(12)
            .onClick(() => this.updateExaggeration(1.0))
        }
        .width('100%')
        .margin({ top: 4 })

        Button('Remove Layer')
          .width('100%')
          .margin({ top: 8 })
          .backgroundColor('#F44336')
          .fontColor(Color.White)
          .onClick(() => this.removeHillshadeLayer())
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Hillshade Layer',
      subtitle: 'Terrain hillshading',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
