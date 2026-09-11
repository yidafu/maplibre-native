/**
 * BulkMarkerTestPage - Performance test for adding 1000+ markers.
 *
 * Tests map performance with a large number of markers,
 * including batch addition, removal, and visibility toggling.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, Marker, MarkerOptions, LatLng } from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast, delay } from '../common/TestUtils';

interface BoundingBox {
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
}

@Entry
@Component
struct BulkMarkerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private markerCount: number = 0;
  @State private isAdding: boolean = false;

  private markers: Marker[] = [];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
    console.info('[BulkMarkerTestPage] Map ready');
  };

  private generateMarkers(count: number, centerLat: number, centerLng: number, spread: number): MarkerOptions[] {
    const options: MarkerOptions[] = [];
    for (let i = 0; i < count; i++) {
      const lat: number = centerLat + (Math.random() - 0.5) * spread;
      const lng: number = centerLng + (Math.random() - 0.5) * spread;
      const opts: MarkerOptions = new MarkerOptions()
        .position(new LatLng(lat, lng))
        .alpha(0.8 + Math.random() * 0.2);
      if (Math.random() > 0.5) {
        opts.title(`Marker #${i + 1}`);
      }
      options.push(opts);
    }
    return options;
  }

  private async addBulkMarkers(count: number): Promise<void> {
    if (!this.mapController || this.isAdding) return;
    this.isAdding = true;
    const startTime: number = Date.now();
    this.statusMessage = `Adding ${count} markers...`;

    try {
      const center: LatLng = this.mapController.getLatLng();
      const optionsList: MarkerOptions[] = this.generateMarkers(count, center.latitude, center.longitude, 0.2);
      const markers: Marker[] = await this.mapController.addMarkersBatch(optionsList);
      this.markers.push(...markers);
      this.markerCount = this.markers.length;
      const elapsed: number = Date.now() - startTime;
      this.statusMessage = `Added ${count} markers in ${elapsed}ms (total: ${this.markerCount})`;
      showToast(`Total markers: ${this.markerCount}`);
    } catch (err) {
      this.statusMessage = `Error adding markers: ${err}`;
      console.error(`[BulkMarkerTestPage] Error: ${err}`);
    } finally {
      this.isAdding = false;
    }
  }

  private clearAllMarkers(): void {
    if (!this.mapController) return;
    const startTime: number = Date.now();
    this.mapController.clearMarkers();
    this.markers = [];
    this.markerCount = 0;
    const elapsed: number = Date.now() - startTime;
    this.statusMessage = `All markers cleared (${elapsed}ms)`;
    showToast('Cleared all markers');
  }

  private zoomToFitMarkers(): void {
    if (!this.mapController || this.markers.length === 0) return;
    const bbox: BoundingBox = this.calculateBbox();
    const latCenter: number = (bbox.minLat + bbox.maxLat) / 2;
    const lngCenter: number = (bbox.minLng + bbox.maxLng) / 2;
    this.mapController.setLatLng(latCenter, lngCenter);
    this.mapController.setZoom(11);
    this.statusMessage = `Zoomed to fit ${this.markerCount} markers`;
  }

  private calculateBbox(): BoundingBox {
    let minLat: number = 90, maxLat: number = -90, minLng: number = 180, maxLng: number = -180;
    for (const marker of this.markers) {
      const pos: LatLng = marker.getPosition();
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }
    return { minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng } as BoundingBox;
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

      Row() {
        Button('Add 100')
          .width('48%')
          .onClick((): void => { this.addBulkMarkers(100); })
          .enabled(this.isMapReady && !this.isAdding)

        Button('Add 500')
          .width('48%')
          .margin({ left: 8 })
          .onClick((): void => { this.addBulkMarkers(500); })
          .enabled(this.isMapReady && !this.isAdding)
      }
      .width('100%')
      .margin({ top: 8 })

      Row() {
        Button('Add 1000')
          .width('48%')
          .onClick((): void => { this.addBulkMarkers(1000); })
          .enabled(this.isMapReady && !this.isAdding)

        Button('Add 5000')
          .width('48%')
          .margin({ left: 8 })
          .onClick((): void => { this.addBulkMarkers(5000); })
          .enabled(this.isMapReady && !this.isAdding)
      }
      .width('100%')
      .margin({ top: 8 })

      Row() {
        Button('Clear All')
          .width('48%')
          .fontColor(Color.White)
          .backgroundColor('#F44336')
          .onClick((): void => this.clearAllMarkers())
          .enabled(this.isMapReady && this.markerCount > 0)

        Button('Fit Markers')
          .width('48%')
          .margin({ left: 8 })
          .fontColor(Color.White)
          .backgroundColor('#2196F3')
          .onClick((): void => this.zoomToFitMarkers())
          .enabled(this.isMapReady && this.markerCount > 0)
      }
      .width('100%')
      .margin({ top: 8 })

      if (this.markerCount > 0) {
        Text(`Total: ${this.markerCount} markers on map`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Bulk Marker',
      subtitle: 'Performance test with 1000+ markers',
      mapContent: this.mapContent,
      controlPanel: this.controlPanel,
      })
    }
    .width('100%')
    .height('100%')
  }
}
