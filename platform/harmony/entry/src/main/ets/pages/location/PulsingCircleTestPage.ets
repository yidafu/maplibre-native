/**
 * PulsingCircleTestPage - Test custom pulsing circle on location.
 *
 * Demonstrates the pulse animation configuration in LocationComponentOptions:
 * pulseEnabled, pulseColor, pulseSingleDuration, pulseMaxRadius, pulseAlpha.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { LocationComponent, LocationComponentOptions, CameraMode, RenderMode } from 'maplibre_harmony';
import { showToast, randomColor } from '../common/TestUtils';

@Entry
@Component
struct PulsingCircleTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private isMapReady: boolean = false;
  @State private isActivated: boolean = false;
  @State private isPulseEnabled: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private pulseColor: string = '#4264fb';
  @State private pulseRadius: number = 50;
  @State private pulseDuration: number = 2300;
  @State private pulseAlpha: number = 0.6;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Activate location to begin.';
  };

  private buildOptions(): LocationComponentOptions {
    return LocationComponentOptions.builder()
      .setPulseEnabled(this.isPulseEnabled)
      .setPulseColor(this.pulseColor)
      .setPulseMaxRadius(this.pulseRadius)
      .setPulseSingleDuration(this.pulseDuration)
      .setPulseAlpha(this.pulseAlpha)
      .setPulseFadeEnabled(true)
      .build();
  }

  private activateLocation(): void {
    if (!this.mapController || !this.isMapReady) {
      showToast('Map not ready');
      return;
    }
    this.mapController.addOnDidFinishLoadingStyleListener(() => {
      const lc = this.mapController!.getLocationComponent();
      if (!lc) {
        showToast('No LocationComponent');
        return;
      }
      this.locationComponent = lc;

      const options = this.buildOptions();
      lc.activateLocationComponent(options).then(() => {
        this.isActivated = true;
        lc.setLocationComponentEnabled(true);
        lc.setCameraMode(CameraMode.TRACKING);
        this.isPulseEnabled = true;
        this.statusMessage = 'Location active with pulsing circle';
        showToast('Location active, pulse ON');
      }).catch((err: Error) => {
        this.statusMessage = 'Error: ' + err.message;
      });
    });
  }

  private togglePulse(): void {
    if (!this.locationComponent || !this.isActivated) {
      return;
    }
    this.isPulseEnabled = !this.isPulseEnabled;
    this.applyStyle();
    this.statusMessage = 'Pulse ' + (this.isPulseEnabled ? 'enabled' : 'disabled');
    showToast('Pulse ' + (this.isPulseEnabled ? 'ON' : 'OFF'));
  }

  private applyStyle(): void {
    if (!this.locationComponent) {
      return;
    }
    const options = this.buildOptions();
    this.locationComponent.applyStyle(options);
  }

  private changeColor(): void {
    this.pulseColor = randomColor();
    this.applyStyle();
    this.statusMessage = 'Pulse color: ' + this.pulseColor;
  }

  private increaseRadius(): void {
    this.pulseRadius = Math.min(this.pulseRadius + 10, 150);
    this.applyStyle();
    this.statusMessage = 'Pulse radius: ' + this.pulseRadius;
  }

  private decreaseRadius(): void {
    this.pulseRadius = Math.max(this.pulseRadius - 10, 10);
    this.applyStyle();
    this.statusMessage = 'Pulse radius: ' + this.pulseRadius;
  }

  private increaseDuration(): void {
    this.pulseDuration = Math.min(this.pulseDuration + 500, 5000);
    this.applyStyle();
    this.statusMessage = 'Pulse duration: ' + this.pulseDuration + 'ms';
  }

  private decreaseDuration(): void {
    this.pulseDuration = Math.max(this.pulseDuration - 500, 500);
    this.applyStyle();
    this.statusMessage = 'Pulse duration: ' + this.pulseDuration + 'ms';
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
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)
        .margin({ bottom: 8 })

      if (!this.isActivated) {
        Button('Activate Location')
          .width('100%')
          .enabled(this.isMapReady)
          .onClick(() => this.activateLocation())
      } else {
        // Pulse toggle
        Button(this.isPulseEnabled ? 'Pulse: ON' : 'Pulse: OFF')
          .width('100%')
          .backgroundColor(this.isPulseEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick(() => this.togglePulse())

        // Color
        Button('Random Color: ' + this.pulseColor)
          .width('100%')
          .margin({ top: 8 })
          .fontColor(Color.White)
          .backgroundColor(this.pulseColor)
          .onClick(() => this.changeColor())

        // Radius controls
        Text('Radius: ' + this.pulseRadius + 'px')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12 })

        Row() {
          Button('-10')
            .width('48%')
            .onClick(() => this.decreaseRadius())
          Button('+10')
            .width('48%')
            .margin({ left: '4%' })
            .onClick(() => this.increaseRadius())
        }
        .width('100%')

        // Duration controls
        Text('Duration: ' + this.pulseDuration + 'ms')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12 })

        Row() {
          Button('-500ms')
            .width('48%')
            .onClick(() => this.decreaseDuration())
          Button('+500ms')
            .width('48%')
            .margin({ left: '4%' })
            .onClick(() => this.increaseDuration())
        }
        .width('100%')

        // Alpha control (toggles between 0.3 and 1.0)
        Button('Toggle Alpha (current: ' + this.pulseAlpha.toFixed(1) + ')')
          .width('100%')
          .margin({ top: 8 })
          .onClick(() => {
            this.pulseAlpha = this.pulseAlpha > 0.5 ? 0.3 : 1.0;
            this.applyStyle();
            this.statusMessage = 'Pulse alpha: ' + this.pulseAlpha;
          })

        Button('Apply Changes')
          .width('100%')
          .margin({ top: 8 })
          .backgroundColor('#2196F3')
          .onClick(() => {
            this.applyStyle();
            showToast('Pulse settings applied');
          })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Pulsing Circle',
      subtitle: 'Custom pulsing circle animation',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
