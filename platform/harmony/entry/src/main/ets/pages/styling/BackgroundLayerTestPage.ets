/**
 * BackgroundLayerTestPage - Set background color and pattern on the map.
 *
 * Demonstrates using a BackgroundLayer to set a solid color or
 * pattern as the map background, visible when no tiles are loaded.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, BackgroundLayer
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

interface ColorItem {
  name: string;
  value: string;
}

@Entry
@Component
struct BackgroundLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerAdded: boolean = false;
  @State private currentColor: string = '#FF5722';

  private readonly LAYER_ID: string = 'background-layer-test';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add a background layer';
    console.info('[BackgroundLayerTestPage] Map ready');
  };

  private addBackgroundLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addBackgroundLayer(), 500);
      return;
    }

    try {
      const layer = new BackgroundLayer(this.LAYER_ID);
      layer.setBackgroundColor(this.currentColor);
      layer.setBackgroundOpacity(0.5);
      style.addLayer(layer);

      this.layerAdded = true;
      this.statusMessage = `Background: ${this.currentColor}`;
      showToast('Background layer added');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[BackgroundLayerTestPage] Error:', err);
    }
  }

  private changeBackgroundColor(color: string): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as BackgroundLayer;
    if (!layer) {
      showToast('Add layer first');
      return;
    }

    this.currentColor = color;
    layer.setBackgroundColor(color);
    this.statusMessage = `Background: ${color}`;
    showToast(`Color: ${color}`);
  }

  private changeBackgroundOpacity(opacity: number): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as BackgroundLayer;
    if (!layer) return;

    layer.setBackgroundOpacity(opacity);
    this.statusMessage = `Opacity: ${(opacity * 100).toFixed(0)}%`;
  }

  private removeBackgroundLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    style.removeLayer(this.LAYER_ID);
    this.layerAdded = false;
    this.statusMessage = 'Background layer removed';
    showToast('Background layer removed');
  }

  private readonly colors: ColorItem[] = [
    { name: 'Orange', value: '#FF5722' },
    { name: 'Blue', value: '#2196F3' },
    { name: 'Green', value: '#4CAF50' },
    { name: 'Purple', value: '#9C27B0' },
    { name: 'Red', value: '#F44336' },
    { name: 'Teal', value: '#009688' },
    { name: 'Yellow', value: '#FFEB3B' },
    { name: 'Black', value: '#000000' },
  ];

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

      Text('Background Layer')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button(this.layerAdded ? 'Update Background' : 'Add Background')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick(() => {
          if (!this.layerAdded) {
            this.addBackgroundLayer();
          } else {
            this.changeBackgroundColor(this.currentColor);
          }
        })
        .enabled(this.isMapReady)

      if (this.layerAdded) {
        Text('Colors').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({ top: 8 })

        ForEach(this.colors, (c: ColorItem) => {
          Row() {
            Circle()
              .width(16)
              .height(16)
              .fill(c.value)
            Text(c.name)
              .fontSize(13)
              .margin({ left: 8 })
              .layoutWeight(1)
            Toggle({ type: ToggleType.Checkbox, isOn: this.currentColor === c.value })
              .onChange(() => {
                this.changeBackgroundColor(c.value);
              })
          }
          .width('100%')
          .height(36)
          .padding({ left: 4 })
        })

        Row() {
          Button('Opacity 25%').fontSize(12).layoutWeight(1).margin({ right: 4 })
            .onClick(() => this.changeBackgroundOpacity(0.25))
          Button('Opacity 50%').fontSize(12).layoutWeight(1).margin({ right: 4 })
            .onClick(() => this.changeBackgroundOpacity(0.5))
          Button('Opacity 75%').fontSize(12).layoutWeight(1)
            .onClick(() => this.changeBackgroundOpacity(0.75))
        }
        .width('100%')
        .margin({ top: 8 })

        Button('Remove Layer')
          .width('100%')
          .margin({ top: 6 })
          .backgroundColor('#F44336')
          .fontColor(Color.White)
          .onClick(() => this.removeBackgroundLayer())
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Background Layer',
      subtitle: 'Background color/pattern',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
