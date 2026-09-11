/**
 * WithinExpressionTestPage - Demonstrate the Expression.within() filter.
 *
 * Draws a polygon boundary and scattered points, then uses a filter
 * expression with Expression.within() to visually distinguish points
 * that fall inside the polygon from those outside.
 *
 * A point-in-polygon ray casting algorithm counts how many points
 * are inside/outside for the status display.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, GeoJson, GeoJsonSource, FillLayer, CircleLayer,
  Expression
} from 'maplibre_harmony';
import type { Position, IFeature } from 'maplibre_harmony';
import type { JSONValue } from 'libmaplibre.so';
import { showToast, TEST_LOCATIONS } from '../common/TestUtils';

interface PointData {
  lng: number;
  lat: number;
}

@Entry
@Component
struct WithinExpressionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private pointsInside: number = 0;
  @State private pointsOutside: number = 0;
  @State private totalPoints: number = 60;
  @State private statusMessage: string = 'Loading...';

  // Polygon boundary points (clockwise)
  private polyPoints: Position[] = [];
  // Generated random points
  private generatedPoints: PointData[] = [];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready, building layers...';
    setTimeout(() => this.addWithinLayers(), 1000);
  };

  /**
   * Build a rectangular polygon around Beijing.
   */
  private buildPolygonGeoJson(): object {
    const centerLng = TEST_LOCATIONS.beijing.longitude;
    const centerLat = TEST_LOCATIONS.beijing.latitude;
    const halfSpan = 0.06;
    this.polyPoints = [
      [centerLng - halfSpan, centerLat - halfSpan, 0] as Position,
      [centerLng + halfSpan, centerLat - halfSpan, 0] as Position,
      [centerLng + halfSpan, centerLat + halfSpan, 0] as Position,
      [centerLng - halfSpan, centerLat + halfSpan, 0] as Position,
      [centerLng - halfSpan, centerLat - halfSpan, 0] as Position,
    ];
    return GeoJson.featureCollection([
      GeoJson.polygonFeature([this.polyPoints])
    ]);
  }

  /**
   * Generate random points scattered around Beijing and count inside/outside.
   */
  private buildPointsGeoJson(total: number): object {
    const centerLng = TEST_LOCATIONS.beijing.longitude;
    const centerLat = TEST_LOCATIONS.beijing.latitude;
    const spread = 0.12;
    this.generatedPoints = [];
    const features: IFeature[] = [];
    for (let i = 0; i < total; i++) {
      const lng = centerLng + (Math.random() - 0.5) * spread;
      const lat = centerLat + (Math.random() - 0.5) * spread;
      this.generatedPoints.push({ lng, lat });
      const props: Record<string, JSONValue> = { "id": i };
      features.push(GeoJson.pointFeature([lng, lat, 0], props));
    }
    this.countInsideOutside();
    return GeoJson.featureCollection(features);
  }

  /**
   * Ray casting point-in-polygon test for a single point.
   */
  private isPointInPolygon(lng: number, lat: number): boolean {
    let inside = false;
    const n = this.polyPoints.length;
    for (let i = 0, j = n - 1; i < n; j = i++) {
      const xi = this.polyPoints[i][0];
      const yi = this.polyPoints[i][1];
      const xj = this.polyPoints[j][0];
      const yj = this.polyPoints[j][1];
      if ((yi > lat) !== (yj > lat) &&
          lng < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }

  /**
   * Count how many generated points fall inside vs outside the polygon.
   */
  private countInsideOutside(): void {
    let inside = 0;
    let outside = 0;
    for (const p of this.generatedPoints) {
      if (this.isPointInPolygon(p.lng, p.lat)) {
        inside++;
      } else {
        outside++;
      }
    }
    this.pointsInside = inside;
    this.pointsOutside = outside;
  }

  /**
   * Extract the polygon geometry object from the FeatureCollection.
   */
  private extractPolygonGeometry(collection: object): object | null {
    const coll = collection as Record<string, JSONValue>;
    const featureList = coll['features'] as object[] | undefined;
    if (featureList && featureList.length > 0) {
      const feature = featureList[0] as Record<string, JSONValue>;
      const geometry = feature['geometry'] as object;
      if (geometry) {
        return geometry;
      }
    }
    // Fallback: return null indicating no polygon geometry found
    return null;
  }

  private addWithinLayers(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addWithinLayers(), 500);
      return;
    }

    const polygonGeoJson = this.buildPolygonGeoJson();
    const pointsGeoJson = this.buildPointsGeoJson(this.totalPoints);
    const polygonGeom = this.extractPolygonGeometry(polygonGeoJson);
    if (!polygonGeom) {
      this.statusMessage = 'Error: Could not extract polygon geometry';
      showToast('Error extracting polygon geometry');
      return;
    }

    // Source for the polygon boundary
    const polygonSource = new GeoJsonSource('within-polygon-source');
    polygonSource.setGeoJson(polygonGeoJson);
    style.addSource(polygonSource);

    // Source for the random points
    const pointsSource = new GeoJsonSource('within-points-source');
    pointsSource.setGeoJson(pointsGeoJson);
    style.addSource(pointsSource);

    // Fill layer for the polygon
    const polygonLayer = new FillLayer('within-polygon-layer', 'within-polygon-source');
    polygonLayer
      .setFillColor('#FF9800')
      .setFillOpacity(0.25)
      .setFillOutlineColor('#E65100');
    style.addLayer(polygonLayer);

    // Points OUTSIDE the polygon: grey
    const outsideFilter = Expression.not(
      Expression.within(polygonGeom)
    );
    const pointsOutsideLayer = new CircleLayer('within-points-outside', 'within-points-source');
    pointsOutsideLayer
      .setCircleRadius(5)
      .setCircleColor('#9E9E9E')
      .setCircleOpacity(0.7)
      .setCircleStrokeColor('#616161')
      .setCircleStrokeWidth(1)
      .setFilter(outsideFilter);
    style.addLayer(pointsOutsideLayer);

    // Points INSIDE the polygon: green
    const insideFilter = Expression.within(polygonGeom);
    const pointsInsideLayer = new CircleLayer('within-points-inside', 'within-points-source');
    pointsInsideLayer
      .setCircleRadius(7)
      .setCircleColor('#4CAF50')
      .setCircleOpacity(0.85)
      .setCircleStrokeColor('#1B5E20')
      .setCircleStrokeWidth(1.5)
      .setFilter(insideFilter);
    style.addLayer(pointsInsideLayer);

    this.statusMessage = `Filter applied via Expression.within()`;
    showToast('Within expression layers added');
  }

  private regeneratePoints(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const pointsGeoJson = this.buildPointsGeoJson(this.totalPoints);
    const source = style.getSource('within-points-source');
    if (source && source instanceof GeoJsonSource) {
      source.setGeoJson(pointsGeoJson);
      this.statusMessage = `Regenerated ${this.totalPoints} points (${this.pointsInside} inside, ${this.pointsOutside} outside)`;
      showToast('Points regenerated');
    }
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: TEST_LOCATIONS.beijing.latitude,
      initialLongitude: TEST_LOCATIONS.beijing.longitude,
      initialZoom: 11,
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

      Text('Within Expression')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Row() {
        Text('Inside:')
          .fontSize(16)
          .fontColor('#4CAF50')
          .fontWeight(FontWeight.Bold)
        Text(`${this.pointsInside}`)
          .fontSize(16)
          .fontColor('#4CAF50')
          .fontWeight(FontWeight.Bold)
          .margin({ left: 4 })
        Blank()
        Text('Outside:')
          .fontSize(16)
          .fontColor('#9E9E9E')
          .fontWeight(FontWeight.Bold)
        Text(`${this.pointsOutside}`)
          .fontSize(16)
          .fontColor('#9E9E9E')
          .fontWeight(FontWeight.Bold)
          .margin({ left: 4 })
      }
      .width('100%')
      .margin({ top: 8 })

      Row() {
        Text('Count:')
          .fontSize(14)
        Slider({
          value: this.totalPoints,
          min: 10,
          max: 200,
          step: 10,
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.totalPoints = value;
          })
        Text(`${this.totalPoints}`)
          .fontSize(13)
          .width(45)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: 8 })

      Button('Regenerate Points')
        .width('100%')
        .margin({ top: 8 })
        .onClick(() => this.regeneratePoints())
        .enabled(this.isMapReady)

      Text('Orange = boundary polygon. Green circles pass Expression.within(). Grey circles do not.')
        .fontSize(12)
        .fontColor('#888')
        .width('100%')
        .margin({ top: 8 })
        .lineHeight(16)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Within Expression',
      subtitle: 'Filter points with Expression.within()',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
