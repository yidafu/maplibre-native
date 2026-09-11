/**
 * PitchRotateTestPage - Tilt and rotation control.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraState } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct PitchRotateTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private currentPitch: number = 0;
  @State private currentBearing: number = 0;
  @State private statusMessage: string = 'Ready';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.refreshState();
    this.statusMessage = 'Map ready';
  };

  private refreshState(): void {
    if (!this.mapController) return;
    const state: CameraState = this.mapController.getCameraState();
    this.currentPitch = state.pitch;
    this.currentBearing = state.bearing;
  }

  private setPitch(pitch: number): void {
    if (!this.mapController) return;
    this.mapController.setPitch(pitch, 300);
    setTimeout((): void => this.refreshState(), 400);
    this.statusMessage = `Pitch set to ${pitch} deg`;
  }

  private setBearing(bearing: number): void {
    if (!this.mapController) return;
    this.mapController.setBearing(bearing, 300);
    setTimeout((): void => this.refreshState(), 400);
    this.statusMessage = `Bearing set to ${bearing} deg`;
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
      Text('Pitch & Rotation')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Column() {
        Row() {
          Text('Pitch:').fontSize(13).fontColor('#666').width(60)
          Text(`${this.currentPitch.toFixed(1)} deg`).fontSize(14).fontFamily('monospace')
        }
        .width('100%')
        Row() {
          Text('Bearing:').fontSize(13).fontColor('#666').width(60).margin({ top: 4 })
          Text(`${this.currentBearing.toFixed(1)} deg`).fontSize(14).fontFamily('monospace').margin({ top: 4 })
        }
        .width('100%')
      }
      .padding(10)
      .backgroundColor('#F5F5F5')
      .borderRadius(6)

      Text('Pitch (Tilt)')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Pitch 0').height(36).enabled(this.isMapReady)
          .onClick((): void => this.setPitch(0))
        Button('Pitch 15').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setPitch(15))
        Button('Pitch 30').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setPitch(30))
        Button('Pitch 45').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setPitch(45))
        Button('Pitch 60').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setPitch(60))
      }
      .width('100%')

      Text('Bearing (Rotation)')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('North 0').height(36).enabled(this.isMapReady)
          .onClick((): void => {
            this.mapController?.resetNorth(400);
            setTimeout((): void => this.refreshState(), 500);
          })
        Button('45 deg').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setBearing(45))
        Button('90 deg').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setBearing(90))
        Button('135 deg').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setBearing(135))
      }
      .width('100%')

      Row() {
        Button('180 deg').height(36).margin({ top: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setBearing(180))
        Button('270 deg').height(36).margin({ top: 6, left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setBearing(270))
        Button('360 deg').height(36).margin({ top: 6, left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setBearing(360))
      }
      .width('100%')

      Text('Combined')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Tilt 45 + Rot 45').height(36).enabled(this.isMapReady)
          .onClick((): void => {
            this.mapController?.setPitch(45, 300);
            this.mapController?.setBearing(45, 300);
            setTimeout((): void => this.refreshState(), 600);
            this.statusMessage = 'Tilt 45 + Rot 45';
          })
        Button('Max Tilt+Rot').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => {
            this.mapController?.setPitch(60, 500);
            this.mapController?.setBearing(135, 500);
            setTimeout((): void => this.refreshState(), 800);
            this.statusMessage = 'Max tilt + rotation';
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Pitch and Rotate',
      subtitle: 'Tilt and rotation control',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
