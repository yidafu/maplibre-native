/**
 * TextureViewResizeTestPage - Resize the map view container dynamically.
 *
 * Demonstrates how the map handles dynamic container resizing by adjusting
 * the map view height with a slider. Resizing triggers internal renderer updates.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';

@Entry
@Component
struct TextureViewResizeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private mapHeight: number = 400;
  @State private mapWidthPct: number = 100;
  @State private statusMessage: string = 'Adjust the slider to resize';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - resize it!';
    showToast('Map ready for resize test');
  };

  private resetSize(): void {
    this.mapHeight = 400;
    this.mapWidthPct = 100;
    this.statusMessage = 'Reset to 400px x 100%';
    showToast('Reset to default size');
  }

  private applySizePreset(height: number, widthPct: number): void {
    this.mapHeight = height;
    this.mapWidthPct = widthPct;
    this.statusMessage = 'Size: ' + height + 'px x ' + widthPct + '%';
  }

  @Builder
  mapContent() {
    Column() {
      MapView({
        onMapReady: this.onMapReady,
      })
        .width(this.mapWidthPct + '%')
        .height(this.mapHeight)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#E0E0E0')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Container Size Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 4 })

      Text(this.statusMessage)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ bottom: 12 })

      Text('Height: ' + this.mapHeight + 'px')
        .fontSize(13)
        .width('100%')
        .margin({ bottom: 2 })
      Slider({
        value: this.mapHeight,
        min: 100,
        max: 700,
        step: 10,
        style: SliderStyle.InSet
      })
        .width('100%')
        .showTips(true)
        .onChange((value: number) => {
          this.mapHeight = value;
          this.statusMessage = 'Height: ' + value + 'px';
        })

      Text('Width: ' + this.mapWidthPct + '%')
        .fontSize(13)
        .width('100%')
        .margin({ top: 8, bottom: 2 })
      Slider({
        value: this.mapWidthPct,
        min: 30,
        max: 100,
        step: 5,
        style: SliderStyle.InSet
      })
        .width('100%')
        .showTips(true)
        .onChange((value: number) => {
          this.mapWidthPct = value;
          this.statusMessage = 'Width: ' + value + '%';
        })

      Text('Presets')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Row() {
        Button('Small 200px')
          .fontSize(11)
          .height(32)
          .layoutWeight(1)
          .margin({ right: 4 })
          .onClick(() => this.applySizePreset(200, 60))
          .enabled(this.isMapReady)
        Button('Medium 400px')
          .fontSize(11)
          .height(32)
          .layoutWeight(1)
          .margin({ left: 4, right: 4 })
          .onClick(() => this.applySizePreset(400, 80))
          .enabled(this.isMapReady)
        Button('Large 600px')
          .fontSize(11)
          .height(32)
          .layoutWeight(1)
          .margin({ left: 4 })
          .onClick(() => this.applySizePreset(600, 100))
          .enabled(this.isMapReady)
      }
      .width('100%')

      Button('Reset to Default')
        .width('100%')
        .margin({ top: 12 })
        .onClick(() => this.resetSize())
        .enabled(this.isMapReady)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'TextureView Resize',
      subtitle: 'Dynamic map container resize',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
