/**
 * VectorTileTestPage - Display a vector tile source.
 *
 * Creates a VectorSource pointing to a public vector tile endpoint
 * and adds layers to render the vector data on the map.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, VectorSource, CircleLayer, FillLayer, LineLayer } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';

@Entry
@Component
struct VectorTileTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private sourceAdded: boolean = false;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Style loaded.';
    console.info('[VectorTileTestPage] Map ready');
  };

  private addVectorSource(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      this.statusMessage = 'Style not yet loaded';
      return;
    }

    try {
      // Create a vector source pointing to the MapLibre demo tiles
      const source = new VectorSource('demo-vector-source', {
        url: 'https://demotiles.maplibre.org/tiles/tiles.json'
      });
      style.addSource(source);

      // Add a circle layer to render POI points
      const circleLayer = new CircleLayer('demo-circle-layer', 'demo-vector-source');
      circleLayer.setSourceLayer('countryregion');
      // Note: Paint properties would be set via the circle layer API
      style.addLayer(circleLayer);

      this.sourceAdded = true;
      this.statusMessage = 'Vector source and layer added';
      showToast('Vector source added');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
      console.error('[VectorTileTestPage] Error:', error);
    }
  }

  private removeVectorSource(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    try {
      // Remove layers first, then source
      style.removeLayer('demo-circle-layer');
      style.removeSource('demo-vector-source');
      this.sourceAdded = false;
      this.statusMessage = 'Vector source removed';
      showToast('Vector source removed');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
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
    Column() {
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Vector Tile Source')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Text('Adds a vector tile source from the MapLibre demo server and renders it with a circle layer.')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .lineHeight(18)
        .margin({ bottom: 12 })

      Button(this.sourceAdded ? 'Remove Source' : 'Add Vector Source')
        .width('100%')
        .backgroundColor(this.sourceAdded ? '#E91E63' : '#2196F3')
        .onClick((): void => {
          if (this.sourceAdded) {
            this.removeVectorSource();
          } else {
            this.addVectorSource();
          }
        })
        .enabled(this.isMapReady)

      if (this.sourceAdded) {
        Text('Source: demotiles.maplibre.org')
          .fontSize(11)
          .fontColor('#999')
          .width('100%')
          .margin({ top: 8 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Vector Tile',
      subtitle: 'Vector tile source display',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
