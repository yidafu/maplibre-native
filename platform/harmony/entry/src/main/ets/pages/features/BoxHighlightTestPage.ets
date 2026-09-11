/**
 * BoxHighlightTestPage - Highlight features within a box selection.
 *
 * Queries features in a box area and manipulates their visibility
 * or applies style changes to highlight the selection.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';
import type { IFeature } from 'maplibre_harmony';

@Entry
@Component
struct BoxHighlightTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready. Click buttons to query and highlight.';
  @State private queryResult: string = '';
  @State private featureCount: number = 0;
  @State private highlightActive: boolean = false;
  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    console.info('[BoxHighlightTestPage] Map ready');
  };

  /**
   * Query features in a box and record the count and sample properties.
   */
  private highlightBox(x: number, y: number, size: number): void {
    if (!this.mapController) return;

    const half = size / 2;

    try {
      const features: IFeature[] = this.mapController.queryRenderedFeaturesForBox(
        x - half, y - half, x + half, y + half
      );
      this.featureCount = features.length;
      this.highlightActive = true;

      this.statusMessage = `Box highlight at (${x.toFixed(0)}, ${y.toFixed(0)}), size=${size}x${size}`;

      if (features.length === 0) {
        this.queryResult = 'No features in the selected box area.';
      } else {
        // Categorize features by type
        const typeCount: Record<string, number> = {} as Record<string, number>;
        for (const feat of features) {
          const type = String((feat as Object as Record<string, Object>).type || 'unknown');
          typeCount[type] = (typeCount[type] || 0) + 1;
        }

        let result = `Selected area contains ${features.length} feature(s):\n\n`;
        for (const entry of Object.entries(typeCount)) {
          result += `${entry[0]}: ${entry[1]}\n`;
        }

        // Show first 3 features' properties
        result += '\nSample features:\n';
        for (let i = 0; i < Math.min(features.length, 3); i++) {
          const props: Record<string, Object> = (features[i] as Object as Record<string, Object>).properties as Record<string, Object> || {};
          const keys = Object.keys(props);
          if (keys.length > 0) {
            result += `${i + 1}. ${keys.slice(0, 4).map((k: string): string => `${k}=${props[k]}`).join(', ')}\n`;
          }
        }

        this.queryResult = result;
        showToast(`Found ${features.length} features in box`);
      }

      console.info(`[BoxHighlightTestPage] Box highlight: ${features.length} features`);
    } catch (error) {
      this.statusMessage = `Query error: ${error instanceof Error ? error.message : String(error)}`;
      this.queryResult = '(query failed)';
    }
  }

  /**
   * Query at the map center with current box size.
   */
  private highlightCenter(): void {
    if (!this.mapController) return;
    const w = this.mapController.getViewWidth();
    const h = this.mapController.getViewHeight();
    if (w === 0 || h === 0) {
      showToast('View size not available');
      return;
    }
    this.highlightBox(w / 2, h / 2, 150);
  }

  /**
   * Query at the top-left quadrant.
   */
  private highlightTopLeft(): void {
    if (!this.mapController) return;
    const w = this.mapController.getViewWidth();
    const h = this.mapController.getViewHeight();
    if (w === 0 || h === 0) return;
    this.highlightBox(w * 0.25, h * 0.25, 150);
  }

  /**
   * Query at the bottom-right quadrant.
   */
  private highlightBottomRight(): void {
    if (!this.mapController) return;
    const w = this.mapController.getViewWidth();
    const h = this.mapController.getViewHeight();
    if (w === 0 || h === 0) return;
    this.highlightBox(w * 0.75, h * 0.75, 150);
  }

  /**
   * Clear the highlight results.
   */
  private clearHighlight(): void {
    this.highlightActive = false;
    this.featureCount = 0;
    this.queryResult = '(cleared)';
    this.statusMessage = 'Highlight cleared. Use buttons to query again.';
    showToast('Highlight cleared');
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

      Text('Box Highlight Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Text('Select an area to query:')
        .fontSize(14)
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        Button('Center')
          .width('30%')
          .fontSize(13)
          .onClick((): void => this.highlightCenter())
          .enabled(this.isMapReady)

        Button('Top-Left')
          .width('30%')
          .fontSize(13)
          .margin({ left: '5%' })
          .onClick((): void => this.highlightTopLeft())
          .enabled(this.isMapReady)

        Button('Bottom-Right')
          .width('30%')
          .fontSize(13)
          .margin({ left: '5%' })
          .onClick((): void => this.highlightBottomRight())
          .enabled(this.isMapReady)
      }
      .width('100%')

      Button('Clear Highlight')
        .width('100%')
        .backgroundColor('#E91E63')
        .margin({ top: 12 })
        .onClick((): void => this.clearHighlight())
        .enabled(this.isMapReady && this.highlightActive)

      Divider()
        .margin({ top: 12, bottom: 8 })

      Text('Results')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 4 })

      Text(`Features in selection: ${this.featureCount}`)
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
      .constraintSize({ maxHeight: 150 })
      .backgroundColor('#FAFAFA')
      .borderRadius(4)
      .padding(8)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Box Highlight',
      subtitle: 'Highlight features in selection',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
