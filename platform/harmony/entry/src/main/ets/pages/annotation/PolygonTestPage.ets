/**
 * PolygonTestPage - Draw and interact with polygons.
 *
 * Demonstrates adding polygons, changing fill and stroke
 * properties, toggling holes, and managing multiple polygons.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, Polygon, LatLng, PolygonOptions } from 'maplibre_harmony';
import { showToast, randomColor } from '../common/TestUtils';

@Entry
@Component
struct PolygonTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private polygonCount: number = 0;
  @State private currentFillColor: string = '#FF5722';
  @State private currentStrokeColor: string = '#FFFFFF';

  private polygons: Polygon[] = [];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - draw a polygon';
    console.info('[PolygonTestPage] Map ready');
  };

  private addStarPolygon(holes: boolean = false): void {
    if (!this.mapController) return;
    const center = this.mapController.getLatLng();

    // Generate a star-shaped polygon
    const points: LatLng[] = [];
    const numPoints = 10;
    const outerRadius = 0.08;
    const innerRadius = 0.03;

    for (let i = 0; i < numPoints; i++) {
      const angle = (i / numPoints) * Math.PI * 2 - Math.PI / 2;
      const radius = i % 2 === 0 ? outerRadius : innerRadius;
      const lat = center.latitude + radius * Math.sin(angle);
      const lng = center.longitude + radius * Math.cos(angle);
      points.push(new LatLng(lat, lng));
    }

    const polygonOptions: PolygonOptions = {
      points: points,
      fillColor: this.currentFillColor,
      strokeColor: this.currentStrokeColor,
      strokeWidth: 2,
      fillAlpha: 0.7,
      strokeAlpha: 1.0,
    };

    if (holes) {
      // Add a small triangular hole in the center
      polygonOptions.holes = [[
        new LatLng(center.latitude + 0.01, center.longitude),
        new LatLng(center.latitude - 0.01, center.longitude - 0.01),
        new LatLng(center.latitude - 0.01, center.longitude + 0.01),
      ]];
    }

    const polygon = new Polygon(polygonOptions);
    const ids = this.mapController.addPolygons([polygon]);
    if (ids.length > 0) {
      this.polygons.push(polygon);
      this.polygonCount++;
      this.statusMessage = holes ? 'Polygon with hole added' : 'Polygon added';
      showToast(holes ? 'Polygon with hole created' : 'Polygon created');
    }
  }

  private addRandomPolygons(count: number): void {
    if (!this.mapController) return;
    const center = this.mapController.getLatLng();

    for (let i = 0; i < count; i++) {
      const centerLat = center.latitude + (Math.random() - 0.5) * 0.3;
      const centerLng = center.longitude + (Math.random() - 0.5) * 0.3;
      const halfSize = 0.01 + Math.random() * 0.03;

      const points: LatLng[] = [
        new LatLng(centerLat - halfSize, centerLng - halfSize),
        new LatLng(centerLat + halfSize, centerLng - halfSize),
        new LatLng(centerLat + halfSize, centerLng + halfSize),
        new LatLng(centerLat - halfSize, centerLng + halfSize),
        new LatLng(centerLat - halfSize, centerLng - halfSize),
      ];

      const polygon = new Polygon({
        points: points,
        fillColor: randomColor(),
        strokeColor: '#FFFFFF',
        strokeWidth: 1,
        fillAlpha: 0.6,
      });

      const ids = this.mapController.addPolygons([polygon]);
      if (ids.length > 0) {
        this.polygons.push(polygon);
        this.polygonCount++;
      }
    }
    this.statusMessage = `Added ${count} random polygons`;
    showToast(`Added ${count} polygons`);
  }

  private updatePolygonColors(): void {
    if (!this.mapController || this.polygons.length === 0) return;

    this.currentFillColor = randomColor();
    this.currentStrokeColor = randomColor();

    for (const polygon of this.polygons) {
      polygon.setFillColor(this.currentFillColor);
      polygon.setStrokeColor(this.currentStrokeColor);
      this.mapController.updatePolygon(polygon);
    }
    this.statusMessage = `Colors updated for ${this.polygons.length} polygons`;
    showToast('Polygon colors updated');
  }

  private clearAll(): void {
    if (!this.mapController) return;
    this.mapController.clearPolygons();
    this.polygons = [];
    this.polygonCount = 0;
    this.statusMessage = 'All polygons cleared';
    showToast('Cleared all polygons');
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

      Text(`Polygons: ${this.polygonCount}`)
        .fontSize(14)
        .fontColor('#2196F3')
        .width('100%')
        .margin({ top: 8 })

      Button('Add Star Polygon')
        .width('100%')
        .margin({ top: 8 })
        .onClick((): void => this.addStarPolygon(false))
        .enabled(this.isMapReady)

      Button('Add Polygon with Hole')
        .width('100%')
        .margin({ top: 6 })
        .onClick((): void => this.addStarPolygon(true))
        .enabled(this.isMapReady)

      Row() {
        Button('Add 5 Random')
          .width('48%')
          .margin({ top: 6 })
          .fontSize(13)
          .onClick((): void => this.addRandomPolygons(5))
          .enabled(this.isMapReady)

        Button('Add 20 Random')
          .width('48%')
          .margin({ top: 6, left: 8 })
          .fontSize(13)
          .onClick((): void => this.addRandomPolygons(20))
          .enabled(this.isMapReady)
      }
      .width('100%')

      Button('Update Colors')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#FF9800')
        .fontColor(Color.White)
        .onClick((): void => this.updatePolygonColors())
        .enabled(this.isMapReady && this.polygonCount > 0)

      Button('Clear All')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick((): void => this.clearAll())
        .enabled(this.isMapReady && this.polygonCount > 0)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Polygon',
      subtitle: 'Draw and interact with polygons',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
