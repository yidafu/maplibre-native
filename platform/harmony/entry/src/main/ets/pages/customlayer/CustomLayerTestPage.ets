/**
 * CustomLayerTestPage - Demonstrate custom OpenGL rendering on the map.
 *
 * Adds a CustomLayer that renders a semi-transparent colored overlay
 * to show how custom OpenGL content can be composited on the map.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CustomLayer, createCustomLayerWithColor } from 'maplibre_harmony';
import type { RGBAColor } from 'maplibre_harmony';

@Entry
@Component
struct CustomLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerVisible: boolean = true;
  @State private currentColor: string = 'red';
  @State private layerAdded: boolean = false;
  private customLayer: CustomLayer | null = null;

  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
    console.info('[CustomLayerTestPage] Map ready');
  };

  /**
   * Add a custom layer with a semi-transparent color.
   */
  private addCustomLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      this.statusMessage = 'Style not yet loaded';
      return;
    }

    try {
      this.customLayer = createCustomLayerWithColor('custom-demo-layer', {
        r: 1.0,
        g: 0.0,
        b: 0.0,
        a: 0.3
      } as RGBAColor);
      style.addLayer(this.customLayer);
      this.layerAdded = true;
      this.currentColor = 'red';
      this.layerVisible = true;
      this.statusMessage = 'Custom layer added (red, alpha 0.3)';
    } catch (error) {
      this.statusMessage = `Failed: ${error instanceof Error ? error.message : String(error)}`;
      console.error('[CustomLayerTestPage] Error:', error);
    }
  }

  /**
   * Toggle the custom layer between visible and hidden.
   */
  private toggleLayer(): void {
    if (!this.customLayer) {
      this.statusMessage = 'No custom layer to toggle';
      return;
    }
    try {
      const newVisibility = this.layerVisible ? 'none' : 'visible';
      this.customLayer.setVisibility(newVisibility);
      this.layerVisible = !this.layerVisible;
      this.statusMessage = `Layer ${this.layerVisible ? 'visible' : 'hidden'}`;
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Set the custom layer's color.
   */
  private setLayerColor(r: number, g: number, b: number, colorName: string): void {
    if (!this.customLayer) {
      this.statusMessage = 'No custom layer to modify';
      return;
    }
    try {
      this.customLayer.setColor(r, g, b, 0.3);
      this.currentColor = colorName;
      this.statusMessage = `Color: ${colorName}`;
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Remove the custom layer from the style.
   */
  private removeCustomLayer(): void {
    if (!this.mapController || !this.customLayer) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    try {
      style.removeLayer(this.customLayer.getId());
      this.customLayer = null;
      this.layerAdded = false;
      this.statusMessage = 'Custom layer removed';
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
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
        .fontColor(this.isMapReady ? (this.layerAdded ? '#4CAF50' : '#FF9800') : '#FF9800')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Custom Layer Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button(this.layerAdded ? 'Remove Layer' : 'Add Custom Layer')
        .width('100%')
        .backgroundColor(this.layerAdded ? '#E91E63' : '#2196F3')
        .onClick((): void => {
          if (this.layerAdded) {
            this.removeCustomLayer();
          } else {
            this.addCustomLayer();
          }
        })
        .enabled(this.isMapReady)

      if (this.layerAdded) {
        Text('Layer Color:')
          .fontSize(14)
          .width('100%')
          .margin({ top: 12, bottom: 6 })

        Row() {
          Button('Red')
            .width('30%')
            .fontSize(13)
            .backgroundColor(this.currentColor === 'red' ? '#F44336' : '#BDBDBD')
            .onClick((): void => this.setLayerColor(1.0, 0.0, 0.0, 'red'))
            .enabled(this.layerAdded)

          Button('Green')
            .width('30%')
            .fontSize(13)
            .margin({ left: '5%' })
            .backgroundColor(this.currentColor === 'green' ? '#4CAF50' : '#BDBDBD')
            .onClick((): void => this.setLayerColor(0.0, 1.0, 0.0, 'green'))
            .enabled(this.layerAdded)

          Button('Blue')
            .width('30%')
            .fontSize(13)
            .margin({ left: '5%' })
            .backgroundColor(this.currentColor === 'blue' ? '#2196F3' : '#BDBDBD')
            .onClick((): void => this.setLayerColor(0.0, 0.0, 1.0, 'blue'))
            .enabled(this.layerAdded)
        }
        .width('100%')

        Button(this.layerVisible ? 'Hide Layer' : 'Show Layer')
          .width('100%')
          .margin({ top: 10 })
          .onClick((): void => this.toggleLayer())
          .enabled(this.layerAdded)
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Custom Layer',
      subtitle: 'Custom OpenGL rendering',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
