/**
 * BoxQueryTestPage - Query features within a bounding box.
 *
 * Uses queryRenderedFeaturesForBox to find features inside a
 * rectangular area on the screen.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';
import type { IFeature } from 'maplibre_harmony';

interface Quadrant {
  name: string;
  x: number;
  y: number;
}

@Entry
@Component
struct BoxQueryTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready. Use the buttons to query a box area.';
  @State private queryResult: string = '(no query yet)';
  @State private featureCount: number = 0;
  @State private boxSize: number = 100;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    console.info('[BoxQueryTestPage] Map ready');
  };

  /**
   * Query features in a box centered on the map view.
   */
  private queryBox(x: number, y: number, size: number): void {
    if (!this.mapController) return;

    const half = size / 2;
    const left = x - half;
    const top = y - half;
    const right = x + half;
    const bottom = y + half;

    try {
      const features: IFeature[] = this.mapController.queryRenderedFeaturesForBox(
        left, top, right, bottom
      );
      this.featureCount = features.length;
      this.statusMessage = `Box query at center (${x.toFixed(0)}, ${y.toFixed(0)}), size=${size}x${size}`;

      if (features.length === 0) {
        this.queryResult = 'No features found in the box area.';
      } else {
        let result = `Found ${features.length} feature(s) in box:\n`;
        for (let i = 0; i < Math.min(features.length, 8); i++) {
          const feat = features[i];
          const props = feat.properties;
          const propKeys = Object.keys(props);
          const propStr = propKeys.slice(0, 2).map(k => `${k}: ${props[k]}`).join(', ');
          result += `${i + 1}. Type: ${feat.type}`;
          if (propStr) result += ` [${propStr}]`;
          result += '\n';
        }
        this.queryResult = result;
      }

      console.info(`[BoxQueryTestPage] Box query: ${features.length} features in ${size}x${size} box`);
    } catch (error) {
      this.statusMessage = `Query error: ${error instanceof Error ? error.message : String(error)}`;
      this.queryResult = '(query failed)';
    }
  }

  /**
   * Query a box at the center of the map.
   */
  private queryAtCenter(): void {
    if (!this.mapController) return;

    const viewW = this.mapController.getViewWidth();
    const viewH = this.mapController.getViewHeight();
    if (viewW === 0 || viewH === 0) {
      showToast('View size not available');
      return;
    }

    this.queryBox(viewW / 2, viewH / 2, this.boxSize);
    showToast(`Box query at center (${this.boxSize}x${this.boxSize})`);
  }

  /**
   * Query a box in each quadrant of the map separately.
   */
  private queryQuadrants(): void {
    if (!this.mapController) return;

    const viewW = this.mapController.getViewWidth();
    const viewH = this.mapController.getViewHeight();
    if (viewW === 0 || viewH === 0) {
      showToast('View size not available');
      return;
    }

    const cx = viewW / 2;
    const cy = viewH / 2;
    const size = this.boxSize;
    const half = size / 2;

    // Query all 4 quadrants
    const quadrants: Quadrant[] = [
      { name: 'Top-Left', x: cx / 2, y: cy / 2 },
      { name: 'Top-Right', x: cx + cx / 2, y: cy / 2 },
      { name: 'Bottom-Left', x: cx / 2, y: cy + cy / 2 },
      { name: 'Bottom-Right', x: cx + cx / 2, y: cy + cy / 2 },
    ];

    let totalFeatures = 0;
    for (const q of quadrants) {
      const features: IFeature[] = this.mapController.queryRenderedFeaturesForBox(
        q.x - half, q.y - half, q.x + half, q.y + half
      );
      totalFeatures += features.length;
    }

    this.featureCount = totalFeatures;
    this.statusMessage = `Queried all 4 quadrants: ${totalFeatures} total features`;
    this.queryResult = `Total features across all quadrants: ${totalFeatures}`;
    showToast(`Found ${totalFeatures} features in all quadrants`);
  }

  /**
   * Set the box query size.
   */
  private setBoxSize(size: number): void {
    this.boxSize = size;
    this.statusMessage = `Box size set to ${size}x${size}`;
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

      Text('Box Query Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Text('Box Size:')
        .fontSize(14)
        .width('100%')
        .margin({ bottom: 6 })

      Row() {
        Button('50x50')
          .width('23%')
          .fontSize(12)
          .backgroundColor(this.boxSize === 50 ? '#2196F3' : '#BDBDBD')
          .onClick((): void => this.setBoxSize(50))

        Button('100x100')
          .width('23%')
          .fontSize(12)
          .margin({ left: '2.66%' })
          .backgroundColor(this.boxSize === 100 ? '#2196F3' : '#BDBDBD')
          .onClick((): void => this.setBoxSize(100))

        Button('200x200')
          .width('23%')
          .fontSize(12)
          .margin({ left: '2.66%' })
          .backgroundColor(this.boxSize === 200 ? '#2196F3' : '#BDBDBD')
          .onClick((): void => this.setBoxSize(200))

        Button('400x400')
          .width('23%')
          .fontSize(12)
          .margin({ left: '2.66%' })
          .backgroundColor(this.boxSize === 400 ? '#2196F3' : '#BDBDBD')
          .onClick((): void => this.setBoxSize(400))
      }
      .width('100%')

      Row() {
        Button('Query at Center')
          .width('48%')
          .margin({ top: 12, right: '4%' })
          .onClick(() => this.queryAtCenter())
          .enabled(this.isMapReady)

        Button('Query Quadrants')
          .width('48%')
          .margin({ top: 12 })
          .onClick(() => this.queryQuadrants())
          .enabled(this.isMapReady)
      }
      .width('100%')

      Text('Query Result')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Text(`Features: ${this.featureCount}`)
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
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Box Query',
      subtitle: 'Query features in a bounding box',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
