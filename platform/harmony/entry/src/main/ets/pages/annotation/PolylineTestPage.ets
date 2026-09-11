/**
 * PolylineTestPage - Draw and interact with polylines.
 *
 * Demonstrates adding polylines between cities, changing
 * line colors, widths, dash patterns, and managing
 * multiple polylines.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, Polyline, LatLng } from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast, randomColor } from '../common/TestUtils';

interface RouteDef {
  points: LatLng[];
  color: string;
  width: number;
}

@Entry
@Component
struct PolylineTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private polylineCount: number = 0;

  private polylines: Polyline[] = [];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - draw polylines';
    console.info('[PolylineTestPage] Map ready');
  };

  private addCityRoute(): void {
    if (!this.mapController) return;

    // Create routes connecting Chinese cities
    const routes: RouteDef[] = [
      {
        points: [TEST_LOCATIONS.beijing, TEST_LOCATIONS.shanghai],
        color: '#F44336',
        width: 4
      } as RouteDef,
      {
        points: [TEST_LOCATIONS.shanghai, TEST_LOCATIONS.guangzhou],
        color: '#2196F3',
        width: 4
      } as RouteDef,
      {
        points: [TEST_LOCATIONS.guangzhou, TEST_LOCATIONS.shenzhen],
        color: '#4CAF50',
        width: 3
      } as RouteDef,
      {
        points: [TEST_LOCATIONS.shenzhen, TEST_LOCATIONS.hangzhou],
        color: '#FF9800',
        width: 3
      } as RouteDef,
      {
        points: [TEST_LOCATIONS.hangzhou, TEST_LOCATIONS.beijing],
        color: '#9C27B0',
        width: 4
      } as RouteDef,
      {
        points: [TEST_LOCATIONS.beijing, TEST_LOCATIONS.xian],
        color: '#009688',
        width: 3
      } as RouteDef,
      {
        points: [TEST_LOCATIONS.xian, TEST_LOCATIONS.chengdu],
        color: '#FF5722',
        width: 3
      } as RouteDef,
      {
        points: [TEST_LOCATIONS.chengdu, TEST_LOCATIONS.wuhan],
        color: '#795548',
        width: 3
      } as RouteDef,
      {
        points: [TEST_LOCATIONS.wuhan, TEST_LOCATIONS.shanghai],
        color: '#607D8B',
        width: 3
      } as RouteDef,
    ];

    for (const route of routes) {
      const polyline = new Polyline({
        points: route.points,
        color: route.color,
        width: route.width,
        alpha: 0.9,
        zIndex: 1,
      });
      const ids = this.mapController.addPolylines([polyline]);
      if (ids.length > 0) {
        this.polylines.push(polyline);
        this.polylineCount++;
      }
    }

    this.statusMessage = `Added ${routes.length} city route polylines`;
    showToast('City routes drawn');
  }

  private addRandomPolylines(count: number): void {
    if (!this.mapController) return;
    const center = this.mapController.getLatLng();

    for (let i = 0; i < count; i++) {
      const startLat = center.latitude + (Math.random() - 0.5) * 0.4;
      const startLng = center.longitude + (Math.random() - 0.5) * 0.4;
      const endLat = startLat + (Math.random() - 0.5) * 0.2;
      const endLng = startLng + (Math.random() - 0.5) * 0.2;

      const polyline = new Polyline({
        points: [new LatLng(startLat, startLng), new LatLng(endLat, endLng)],
        color: randomColor(),
        width: 2 + Math.random() * 4,
        alpha: 0.6 + Math.random() * 0.4,
      });

      const ids = this.mapController.addPolylines([polyline]);
      if (ids.length > 0) {
        this.polylines.push(polyline);
        this.polylineCount++;
      }
    }
    this.statusMessage = `Added ${count} random polylines`;
    showToast(`Added ${count} polylines`);
  }

  private updateLineProperties(): void {
    if (!this.mapController || this.polylines.length === 0) return;

    const newColor = randomColor();
    const newWidth = 2 + Math.random() * 6;

    for (const polyline of this.polylines) {
      polyline.setColor(newColor);
      polyline.setWidth(newWidth);
      polyline.setAlpha(0.5 + Math.random() * 0.5);
      this.mapController.updatePolyline(polyline);
    }
    this.statusMessage = `Updated ${this.polylines.length} polylines`;
    showToast('Polyline properties updated');
  }

  private toggleDashPattern(): void {
    if (!this.mapController || this.polylines.length === 0) return;

    const currentPattern = this.polylines[0].getPattern();
    const useDash = !(currentPattern && currentPattern.length > 0);

    for (const polyline of this.polylines) {
      if (useDash) {
        polyline.setPattern([5, 5]);
      } else {
        polyline.setPattern(null);
      }
      this.mapController.updatePolyline(polyline);
    }
    this.statusMessage = useDash ? 'Dash pattern ON' : 'Solid lines';
    showToast(useDash ? 'Dashed lines' : 'Solid lines');
  }

  private clearAll(): void {
    if (!this.mapController) return;
    this.mapController.clearPolylines();
    this.polylines = [];
    this.polylineCount = 0;
    this.statusMessage = 'All polylines cleared';
    showToast('Cleared all polylines');
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

      Text(`Polylines: ${this.polylineCount}`)
        .fontSize(14)
        .fontColor('#2196F3')
        .width('100%')
        .margin({ top: 8 })

      Button('Draw City Routes')
        .width('100%')
        .margin({ top: 8 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick((): void => this.addCityRoute())
        .enabled(this.isMapReady)

      Row() {
        Button('Add 5 Random')
          .width('48%')
          .fontSize(13)
          .margin({ top: 6 })
          .onClick((): void => this.addRandomPolylines(5))
          .enabled(this.isMapReady)

        Button('Add 20 Random')
          .width('48%')
          .fontSize(13)
          .margin({ top: 6, left: 8 })
          .onClick((): void => this.addRandomPolylines(20))
          .enabled(this.isMapReady)
      }
      .width('100%')

      Button('Randomize Properties')
        .width('100%')
        .margin({ top: 6 })
        .onClick((): void => this.updateLineProperties())
        .enabled(this.isMapReady && this.polylineCount > 0)

      Button('Toggle Dash Pattern')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#FF9800')
        .fontColor(Color.White)
        .onClick((): void => this.toggleDashPattern())
        .enabled(this.isMapReady && this.polylineCount > 0)

      Button('Clear All')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick((): void => this.clearAll())
        .enabled(this.isMapReady && this.polylineCount > 0)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Polyline',
      subtitle: 'Draw and interact with polylines',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
