/**
 * MapPaddingTestPage - Set content insets (padding) for the map.
 *
 * Adjusts the logical center for camera calculations, useful when
 * UI elements overlay the map (e.g. top bar, bottom sheet).
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraState } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct MapPaddingTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private paddingTop: number = 0;
  @State private paddingBottom: number = 0;
  @State private paddingLeft: number = 0;
  @State private paddingRight: number = 0;
  @State private statusMessage: string = 'Ready';

  private readonly PADDING_STEP: number = 50;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private applyPadding(): void {
    if (!this.mapController) return;
    this.mapController.setPadding(this.paddingLeft, this.paddingTop, this.paddingRight, this.paddingBottom);
    this.statusMessage = `Padding: T=${this.paddingTop} B=${this.paddingBottom} L=${this.paddingLeft} R=${this.paddingRight}`;
    showToast('Padding applied');
  }

  private resetPadding(): void {
    if (!this.mapController) return;
    this.paddingTop = 0;
    this.paddingBottom = 0;
    this.paddingLeft = 0;
    this.paddingRight = 0;
    this.mapController.setPadding(0, 0, 0, 0);
    this.statusMessage = 'Padding reset to 0';
    showToast('Padding reset');
  }

  private queryPadding(): void {
    if (!this.mapController) return;
    const p = this.mapController.getPadding();
    if (p && p.length >= 4) {
      this.statusMessage = `Current padding: [${p[0]}, ${p[1]}, ${p[2]}, ${p[3]}]`;
    }
  }

  @Builder
  mapContent() {
    Stack() {
      MapView({
        onMapReady: this.onMapReady,
      })
        .width('100%')
        .height('100%')

      // Visual padding indicator overlay
      if (this.paddingTop > 0 || this.paddingBottom > 0 || this.paddingLeft > 0 || this.paddingRight > 0) {
        Column() {
          if (this.paddingTop > 0) {
            Row() {
              Text(`Top: ${this.paddingTop}px`)
                .fontSize(10)
                .fontColor('#fff')
            }
            .width('100%')
            .height(this.paddingTop)
            .backgroundColor('rgba(33, 150, 243, 0.3)')
            .justifyContent(FlexAlign.Center)
          }

          Row() {
            if (this.paddingLeft > 0) {
              Text(`L:${this.paddingLeft}`)
                .fontSize(10)
                .fontColor('#fff')
                .width(this.paddingLeft)
                .height('100%')
                .backgroundColor('rgba(33, 150, 243, 0.3)')
                .textAlign(TextAlign.Center)
            }

            Blank().layoutWeight(1)

            if (this.paddingRight > 0) {
              Text(`R:${this.paddingRight}`)
                .fontSize(10)
                .fontColor('#fff')
                .width(this.paddingRight)
                .height('100%')
                .backgroundColor('rgba(33, 150, 243, 0.3)')
                .textAlign(TextAlign.Center)
            }
          }
          .layoutWeight(1)

          if (this.paddingBottom > 0) {
            Row() {
              Text(`Bottom: ${this.paddingBottom}px`)
                .fontSize(10)
                .fontColor('#fff')
            }
            .width('100%')
            .height(this.paddingBottom)
            .backgroundColor('rgba(33, 150, 243, 0.3)')
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Map Padding')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text(this.statusMessage)
        .fontSize(12)
        .fontColor('#333')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Top Padding')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      Text(`Current: ${this.paddingTop}px`)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
      Row() {
        Button('+50').height(32).enabled(this.isMapReady)
          .onClick(() => { this.paddingTop += this.PADDING_STEP; this.applyPadding(); })
        Button('-50').height(32).margin({ left: 8 }).enabled(this.isMapReady && this.paddingTop >= this.PADDING_STEP)
          .onClick(() => { this.paddingTop = Math.max(0, this.paddingTop - this.PADDING_STEP); this.applyPadding(); })
        Button('Set 200').height(32).margin({ left: 8 }).enabled(this.isMapReady)
          .onClick(() => { this.paddingTop = 200; this.applyPadding(); })
      }
      .width('100%')

      Text('Bottom Padding')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      Text(`Current: ${this.paddingBottom}px`)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
      Row() {
        Button('+50').height(32).enabled(this.isMapReady)
          .onClick(() => { this.paddingBottom += this.PADDING_STEP; this.applyPadding(); })
        Button('-50').height(32).margin({ left: 8 }).enabled(this.isMapReady && this.paddingBottom >= this.PADDING_STEP)
          .onClick(() => { this.paddingBottom = Math.max(0, this.paddingBottom - this.PADDING_STEP); this.applyPadding(); })
        Button('Set 300').height(32).margin({ left: 8 }).enabled(this.isMapReady)
          .onClick(() => { this.paddingBottom = 300; this.applyPadding(); })
      }
      .width('100%')

      Text('Left / Right Padding')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      Row() {
        Button('Left +50').height(32).enabled(this.isMapReady)
          .onClick(() => { this.paddingLeft += this.PADDING_STEP; this.applyPadding(); })
        Button('Left -50').height(32).margin({ left: 6 }).enabled(this.isMapReady && this.paddingLeft >= this.PADDING_STEP)
          .onClick(() => { this.paddingLeft = Math.max(0, this.paddingLeft - this.PADDING_STEP); this.applyPadding(); })
        Button('Right +50').height(32).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick(() => { this.paddingRight += this.PADDING_STEP; this.applyPadding(); })
        Button('Right -50').height(32).margin({ left: 6 }).enabled(this.isMapReady && this.paddingRight >= this.PADDING_STEP)
          .onClick(() => { this.paddingRight = Math.max(0, this.paddingRight - this.PADDING_STEP); this.applyPadding(); })
      }
      .width('100%')

      Row() {
        Button('Reset Padding')
          .height(36)
          .layoutWeight(1)
          .enabled(this.isMapReady)
          .onClick(() => this.resetPadding())
        Button('Query Padding')
          .height(36)
          .margin({ left: 8 })
          .layoutWeight(1)
          .enabled(this.isMapReady)
          .onClick(() => this.queryPadding())
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Map Padding',
      subtitle: 'Set content insets for the map',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
