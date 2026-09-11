/**
 * NoStyleTestPage - Display a map with no style loaded.
 *
 * Tests the map rendering behavior when no style is set.
 * Demonstrates adding a style later via user interaction.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct NoStyleTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Map created without style';
  @State private hasStyle: boolean = false;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - no style loaded';
    console.info('[NoStyleTestPage] Map ready (no style)');
  };

  private getStatusColor(): string {
    if (this.hasStyle) {
      return '#4CAF50';
    }
    if (this.isMapReady) {
      return '#FF9800';
    }
    return '#999';
  }

  private loadStyleNow(): void {
    if (!this.mapController) return;
    this.statusMessage = 'Loading style...';
    this.mapController.setStyleWithCallback(DEFAULT_STYLE_URLS.bright, () => {
      this.hasStyle = true;
      this.statusMessage = 'Style loaded - map is now visible';
      showToast('Style loaded successfully');
    });
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
        .fontColor(this.getStatusColor())
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('No Style Mode')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Text('The map was created without a style. Click below to load one.')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .lineHeight(18)

      Button('Load Style Now')
        .width('100%')
        .margin({ top: 12 })
        .backgroundColor('#4CAF50')
        .onClick(() => this.loadStyleNow())
        .enabled(this.isMapReady && !this.hasStyle)

      if (this.hasStyle) {
        Text('Style is loaded. Use reset to test again.')
          .fontSize(12)
          .fontColor('#4CAF50')
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
      title: 'No Style',
      subtitle: 'Map without a loaded style',
      mapContent: this.mapContent,
      controlPanel: this.controlPanel,
      })
    }
    .width('100%')
    .height('100%')
  }
}
