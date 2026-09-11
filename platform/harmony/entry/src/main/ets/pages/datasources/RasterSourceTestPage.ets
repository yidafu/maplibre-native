/**
 * RasterSourceTestPage - Display a raster tile source.
 *
 * Creates a RasterSource pointing to a raster tile endpoint
 * and adds a RasterLayer to render it on the map.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, RasterSource, RasterLayer } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct RasterSourceTestPage {
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
    this.statusMessage = 'Map ready';
    console.info('[RasterSourceTestPage] Map ready');
  };

  private addRasterSource(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      this.statusMessage = 'Style not yet loaded';
      return;
    }

    try {
      // Create a raster source pointing to satellite imagery tiles
      const source = new RasterSource('satellite-raster-source');
      source.setUrl('https://demotiles.maplibre.org/tiles/satellite/tiles.json');
      source.setTileSize(256);
      style.addSource(source);

      // Add a raster layer to render the tiles
      const rasterLayer = new RasterLayer('satellite-raster-layer', 'satellite-raster-source');
      style.addLayer(rasterLayer);

      this.sourceAdded = true;
      this.statusMessage = 'Raster source and layer added. Zoom in to see satellite tiles.';
      showToast('Raster source added');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
      console.error('[RasterSourceTestPage] Error:', error);
    }
  }

  private removeRasterSource(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    try {
      style.removeLayer('satellite-raster-layer');
      style.removeSource('satellite-raster-source');
      this.sourceAdded = false;
      this.statusMessage = 'Raster source removed';
      showToast('Raster source removed');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  private setTileSize(size: number): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    try {
      // Remove and re-add with new tile size
      style.removeLayer('satellite-raster-layer');
      style.removeSource('satellite-raster-source');

      const source = new RasterSource('satellite-raster-source');
      source.setUrl('https://demotiles.maplibre.org/tiles/satellite/tiles.json');
      source.setTileSize(size);
      style.addSource(source);

      const rasterLayer = new RasterLayer('satellite-raster-layer', 'satellite-raster-source');
      style.addLayer(rasterLayer);

      this.statusMessage = `Tile size set to ${size}`;
      showToast(`Tile size: ${size}`);
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

      Text('Raster Source Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button(this.sourceAdded ? 'Remove Source' : 'Add Satellite Raster')
        .width('100%')
        .backgroundColor(this.sourceAdded ? '#E91E63' : '#2196F3')
        .onClick((): void => {
          if (this.sourceAdded) {
            this.removeRasterSource();
          } else {
            this.addRasterSource();
          }
        })
        .enabled(this.isMapReady)

      if (this.sourceAdded) {
        Text('Tile Size Options:')
          .fontSize(14)
          .width('100%')
          .margin({ top: 12, bottom: 6 })

        Row() {
          Button('256')
            .width('30%')
            .fontSize(13)
            .onClick((): void => this.setTileSize(256))
            .enabled(this.isMapReady)

          Button('512')
            .width('30%')
            .fontSize(13)
            .margin({ left: '5%' })
            .onClick((): void => this.setTileSize(512))
            .enabled(this.isMapReady)

          Button('1024')
            .width('30%')
            .fontSize(13)
            .margin({ left: '5%' })
            .onClick((): void => this.setTileSize(1024))
            .enabled(this.isMapReady)
        }
        .width('100%')
      }

      if (this.sourceAdded) {
        Text('Tip: Zoom in to see raster tile details more clearly.')
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
      title: 'Raster Source',
      subtitle: 'Raster tile source display',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
