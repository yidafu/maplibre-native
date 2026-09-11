/**
 * LightTestPage - Configure scene lighting on the map.
 *
 * Demonstrates adjusting the light anchor, color, intensity,
 * and position to control the map's 3D scene lighting.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, Light
} from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct LightTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';

  @State private lightColor: string = '#FFFFFF';
  @State private lightIntensity: number = 0.5;
  @State private lightAnchor: string = 'viewport';
  @State private lightPosition: string = '1.0, 210, 30';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - configure lighting';
    console.info('[LightTestPage] Map ready');
  };

  private getLight(): Light | null {
    if (!this.mapController) return null;
    try {
      return this.mapController.getLight();
    } catch (err) {
      console.error('[LightTestPage] getLight error:', err);
      return null;
    }
  }

  private setColor(color: string): void {
    if (!this.mapController) return;
    try {
      const light = this.getLight();
      if (light) {
        light.setColor(color);
        this.lightColor = color;
        this.statusMessage = `Light color: ${color}`;
        showToast(`Color: ${color}`);
      } else {
        showToast('Light object not available');
      }
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
    }
  }

  private setIntensity(intensity: number): void {
    if (!this.mapController) return;
    try {
      const light = this.getLight();
      if (light) {
        light.setIntensity(intensity);
        this.lightIntensity = intensity;
        this.statusMessage = `Intensity: ${intensity.toFixed(1)}`;
      }
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
    }
  }

  private toggleAnchor(): void {
    if (!this.mapController) return;
    try {
      const light = this.getLight();
      if (light) {
        const newAnchor = light.getAnchor() === 'map' ? 'viewport' : 'map';
        light.setAnchor(newAnchor);
        this.lightAnchor = newAnchor;
        this.statusMessage = `Anchor: ${newAnchor}`;
        showToast(`Anchor: ${newAnchor}`);
      }
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
    }
  }

  private setPosition(radial: number, azimuthal: number, polar: number): void {
    if (!this.mapController) return;
    try {
      const light = this.getLight();
      if (light) {
        const position: number[] = [radial, azimuthal, polar];
        light.setPosition(position);
        this.lightPosition = `${radial}, ${azimuthal}, ${polar}`;
        this.statusMessage = `Position: [${radial}, ${azimuthal}, ${polar} deg]`;
        showToast(`Position updated`);
      }
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
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
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Light Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Text('Light Color').fontSize(14).fontWeight(FontWeight.Bold).width('100%')
      Row() {
        Button('White').layoutWeight(1).margin({ right: 4 }).fontSize(12)
          .onClick(() => this.setColor('#FFFFFF'))
        Button('Warm').layoutWeight(1).margin({ right: 4 }).fontSize(12)
          .onClick(() => this.setColor('#FFE0B2'))
        Button('Cool').layoutWeight(1).fontSize(12)
          .onClick(() => this.setColor('#BBDEFB'))
      }
      .width('100%')
      .margin({ top: 4 })

      Text('Intensity').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({ top: 8 })
      Row() {
        Button('0.2').layoutWeight(1).margin({ right: 4 }).fontSize(12)
          .onClick(() => this.setIntensity(0.2))
        Button('0.5').layoutWeight(1).margin({ right: 4 }).fontSize(12)
          .onClick(() => this.setIntensity(0.5))
        Button('1.0').layoutWeight(1).fontSize(12)
          .onClick(() => this.setIntensity(1.0))
        Button('1.5').layoutWeight(1).fontSize(12)
          .onClick(() => this.setIntensity(1.5))
      }
      .width('100%')
      .margin({ top: 4 })

      Row() {
        Button(`Anchor: ${this.lightAnchor}`)
          .width('100%')
          .margin({ top: 8 })
          .onClick(() => this.toggleAnchor())
          .enabled(this.isMapReady)
      }
      .width('100%')

      Text('Light Position').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({ top: 8 })
      Row() {
        Button('Top').layoutWeight(1).margin({ right: 4 }).fontSize(12)
          .onClick(() => this.setPosition(1.0, 210, 90))
        Button('Side').layoutWeight(1).margin({ right: 4 }).fontSize(12)
          .onClick(() => this.setPosition(1.0, 0, 30))
        Button('Low').layoutWeight(1).fontSize(12)
          .onClick(() => this.setPosition(1.0, 180, 10))
      }
      .width('100%')
      .margin({ top: 4 })

      Text(`Position: [${this.lightPosition}]`)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Light',
      subtitle: 'Scene lighting configuration',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
