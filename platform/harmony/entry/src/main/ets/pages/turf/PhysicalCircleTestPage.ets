/**
 * PhysicalCircleTestPage - Draw a turf physical circle (in meters) on the map.
 *
 * Demonstrates generating a GeoJSON polygon approximating a circle
 * with a real-world radius using the Haversine formula, rendered as
 * a FillLayer with adjustable radius and vertex count.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, GeoJson, GeoJsonSource, FillLayer } from 'maplibre_harmony';
import type { Position } from 'maplibre_harmony';
import { showToast, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct PhysicalCircleTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private radius: number = 5000;
  @State private steps: number = 64;
  @State private centerLat: number = TEST_LOCATIONS.beijing.latitude;
  @State private centerLng: number = TEST_LOCATIONS.beijing.longitude;
  @State private statusMessage: string = 'Loading...';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready, adding circle...';
    // Wait for the style to load before adding layers
    setTimeout(() => this.addCircleLayer(), 800);
  };

  /**
   * Generate a GeoJSON polygon that approximates a circle on the globe.
   * Uses the Haversine formula to convert meters to angular distances.
   */
  private generateCircleGeoJson(): object {
    const coordinates: number[][] = [];
    const radiusKm = this.radius / 1000;
    const centerLatRad = this.centerLat * Math.PI / 180;
    const centerLngRad = this.centerLng * Math.PI / 180;

    for (let i = 0; i <= this.steps; i++) {
      const angle = (i * 360 / this.steps) * Math.PI / 180;
      // Destination point given distance and bearing from start
      const d = radiusKm / 6371; // angular distance in radians
      const latRad = Math.asin(
        Math.sin(centerLatRad) * Math.cos(d) +
        Math.cos(centerLatRad) * Math.sin(d) * Math.cos(angle)
      );
      const lngRad = centerLngRad + Math.atan2(
        Math.sin(angle) * Math.sin(d) * Math.cos(centerLatRad),
        Math.cos(d) - Math.sin(centerLatRad) * Math.sin(latRad)
      );
      coordinates.push([lngRad * 180 / Math.PI, latRad * 180 / Math.PI]);
    }

    const coords3d: Position[] = coordinates.map(
      (c: number[]): Position => [c[0], c[1], 0] as Position
    );
    return GeoJson.featureCollection([
      GeoJson.polygonFeature([coords3d])
    ]);
  }

  private addCircleLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addCircleLayer(), 500);
      return;
    }

    const circleGeoJson = this.generateCircleGeoJson();
    const source = new GeoJsonSource('turf-circle-source');
    source.setGeoJson(circleGeoJson);
    style.addSource(source);

    const fillLayer = new FillLayer('turf-circle-fill', 'turf-circle-source');
    fillLayer
      .setFillColor('#4A90E2')
      .setFillOpacity(0.35)
      .setFillOutlineColor('#1565C0');
    style.addLayer(fillLayer);

    this.statusMessage = `Circle radius: ${this.radius}m, vertices: ${this.steps}`;
    showToast('Physical circle added');
  }

  private updateCircle(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const source = style.getSource('turf-circle-source');
    if (source && source instanceof GeoJsonSource) {
      source.setGeoJson(this.generateCircleGeoJson());
      this.statusMessage = `Circle radius: ${this.radius}m, vertices: ${this.steps}`;
    }
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: this.centerLat,
      initialLongitude: this.centerLng,
      initialZoom: 10,
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

      Text('Physical Circle')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Row() {
        Text('Radius (m):')
          .fontSize(14)
          .width(90)
        Slider({
          value: this.radius,
          min: 500,
          max: 50000,
          step: 500,
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.radius = value;
            this.updateCircle();
          })
        Text(`${this.radius}`)
          .fontSize(13)
          .width(60)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: 4 })

      Row() {
        Text('Vertices:')
          .fontSize(14)
          .width(90)
        Slider({
          value: this.steps,
          min: 8,
          max: 128,
          step: 8,
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.steps = value;
            this.updateCircle();
          })
        Text(`${this.steps}`)
          .fontSize(13)
          .width(60)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: 4 })

      Row() {
        Button('Jump to Beijing')
          .width('48%')
          .onClick(() => {
            if (this.mapController) {
              this.mapController.jumpTo(0, TEST_LOCATIONS.beijing.latitude,
                TEST_LOCATIONS.beijing.longitude, 0, 10);
              this.centerLat = TEST_LOCATIONS.beijing.latitude;
              this.centerLng = TEST_LOCATIONS.beijing.longitude;
              setTimeout(() => this.updateCircle(), 500);
            }
          })
          .enabled(this.isMapReady)
        Button('Jump to London')
          .width('48%')
          .margin({ left: 8 })
          .onClick(() => {
            if (this.mapController) {
              this.mapController.jumpTo(0, TEST_LOCATIONS.london.latitude,
                TEST_LOCATIONS.london.longitude, 0, 10);
              this.centerLat = TEST_LOCATIONS.london.latitude;
              this.centerLng = TEST_LOCATIONS.london.longitude;
              setTimeout(() => this.updateCircle(), 500);
            }
          })
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 8 })

      Text(`Circumference: ${(2 * Math.PI * this.radius / 1000).toFixed(2)} km`)
        .fontSize(13)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 8 })
      Text(`Area: ${(Math.PI * this.radius * this.radius / 1e6).toFixed(2)} km2`)
        .fontSize(13)
        .fontColor('#666')
        .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Physical Circle',
      subtitle: 'Turf circle at real-world scale',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
