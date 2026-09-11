/**
 * PointQueryTestPage - Query features at a screen point.
 *
 * Demonstrates queryRenderedFeaturesForPoint by tapping the map
 * and showing information about the features found at that location.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { MapClickListener } from '../../utils/ListenerFactories';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';
import type { IFeature } from 'maplibre_harmony';

@Entry
@Component
struct PointQueryTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Tap the map to query features at a point';
  @State private queryResult: string = '(no query yet)';
  @State private featureCount: number = 0;
  @State private lastTapX: number = 0;
  @State private lastTapY: number = 0;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Tap anywhere to query features.';

    // Register click listener for feature queries
    map.addOnMapClickListener(new MapClickListener(
      (x: number, y: number): boolean => {
        this.queryAtPoint(x, y);
        return true;
      }
    ));

    console.info('[PointQueryTestPage] Map ready, click listener registered');
  };

  /**
   * Query rendered features at the given screen coordinates.
   */
  private queryAtPoint(x: number, y: number): void {
    if (!this.mapController) return;

    this.lastTapX = x;
    this.lastTapY = y;

    try {
      const features: IFeature[] = this.mapController.queryRenderedFeaturesForPoint(x, y);
      this.featureCount = features.length;
      this.statusMessage = `Queried at (${x.toFixed(0)}, ${y.toFixed(0)})`;

      if (features.length === 0) {
        this.queryResult = 'No features found at this location. Try tapping on a map feature.';
      } else {
        let result = `Found ${features.length} feature(s):\n`;
        for (let i = 0; i < Math.min(features.length, 5); i++) {
          const feat = features[i];
          const props: Record<string, Object> = (feat as Object as Record<string, Object>).properties as Record<string, Object> || {};
          const propKeys = Object.keys(props);
          const propStr = propKeys.slice(0, 3).map(k => `${k}: ${props[k]}`).join(', ');
          result += `${i + 1}. Type: ${(feat as Object as Record<string, Object>).type || 'unknown'}`;
          if (propStr) result += ` (${propStr})`;
          result += '\n';
        }
        this.queryResult = result;
      }

      console.info(`[PointQueryTestPage] Query at (${x}, ${y}): ${features.length} features`);
    } catch (error) {
      this.statusMessage = `Query error: ${error instanceof Error ? error.message : String(error)}`;
      this.queryResult = '(query failed)';
    }
  }

  /**
   * Query only specific layers to narrow results.
   */
  private queryOnSpecificLayers(): void {
    if (!this.mapController) return;

    // Guess some common layer IDs that might exist in the default style
    const layerIds: string[] = ['poi-label', 'road-label', 'country-label', 'state-label', 'settlement-label'];
    const features: IFeature[] = this.mapController.queryRenderedFeaturesForPoint(
      this.lastTapX, this.lastTapY, layerIds
    );
    this.featureCount = features.length;
    this.queryResult = `Filtered to label layers: ${features.length} feature(s)`;
    showToast(`Found ${features.length} features in label layers`);
  }

  /**
   * Get the current camera center coordinates and query there.
   */
  private queryAtCenter(): void {
    if (!this.mapController) return;

    const viewW = this.mapController.getViewWidth();
    const viewH = this.mapController.getViewHeight();
    if (viewW === 0 || viewH === 0) {
      showToast('View size not available');
      return;
    }

    const cx = viewW / 2;
    const cy = viewH / 2;
    this.queryAtPoint(cx, cy);
    showToast(`Queried at map center (${cx.toFixed(0)}, ${cy.toFixed(0)})`);
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

      Text('Last Tap Position')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Text(`X: ${this.lastTapX.toFixed(0)}, Y: ${this.lastTapY.toFixed(0)}`)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')

      Text('Query Results')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })

      Text(`Features found: ${this.featureCount}`)
        .fontSize(12)
        .fontColor('#2196F3')
        .width('100%')
        .margin({ bottom: 4 })

      Scroll() {
        Text(this.queryResult)
          .fontSize(12)
          .fontColor('#333')
          .width('100%')
          .lineHeight(18)
      }
      .width('100%')
      .constraintSize({ maxHeight: 120 })
      .backgroundColor('#FAFAFA')
      .borderRadius(4)
      .padding(8)

      Row() {
        Button('Query at Center')
          .width('48%')
          .margin({ top: 12, right: '4%' })
          .onClick((): void => this.queryAtCenter())
          .enabled(this.isMapReady)

        Button('Filter Labels')
          .width('48%')
          .margin({ top: 12 })
          .onClick((): void => this.queryOnSpecificLayers())
          .enabled(this.isMapReady && this.featureCount > 0)
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Point Query',
      subtitle: 'Query features at a screen point',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
