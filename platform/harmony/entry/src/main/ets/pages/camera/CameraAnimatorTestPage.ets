/**
 * CameraAnimatorTestPage - Animation duration and easing tests.
 *
 * Reference: Android CameraAnimatorActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { CameraAnimationCallbackImpl } from '../../utils/ListenerFactories';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct CameraAnimatorTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready';
  @State private isAnimating: boolean = false;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private animatePosition(lat: number, lng: number, zoom: number, bearing: number, pitch: number, duration: number): void {
    if (!this.mapController || this.isAnimating) return;
    this.isAnimating = true;
    this.statusMessage = `Animating (${duration}ms)...`;

    const target = new LatLng(lat, lng);
    const position: CameraPosition = { target: target, zoom: zoom, bearing: bearing, tilt: pitch };

    this.mapController.animateCamera(position, duration, new CameraAnimationCallbackImpl(
      (): void => {
        this.isAnimating = false;
        this.statusMessage = 'Animation complete';
        showToast(`Animation finished (${duration}ms)`);
      },
      (): void => {
        this.isAnimating = false;
        this.statusMessage = 'Animation cancelled';
      }
    ));
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
        .fontSize(13)
        .fontColor(this.isAnimating ? '#FF9800' : '#4CAF50')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Animation Duration')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('100ms').height(36).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(39.9042, 116.4074, 12, 0, 0, 100))
        Button('500ms').height(36).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(31.2304, 121.4737, 13, 45, 0, 500))
        Button('1000ms').height(36).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(30.2741, 120.1551, 14, 90, 0, 1000))
      }
      .width('100%')

      Row() {
        Button('2000ms').height(36).margin({ top: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(40.7128, -74.006, 13, 180, 0, 2000))
        Button('3000ms').height(36).margin({ top: 6, left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(35.6762, 139.6503, 14, 270, 0, 3000))
        Button('5000ms').height(36).margin({ top: 6, left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(48.8566, 2.3522, 12, 0, 30, 5000))
      }
      .width('100%')

      Text('Animated Camera Options')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Zoom + Rotate').height(36).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(39.9042, 116.4074, 15, 45, 0, 1000))
        Button('Zoom + Tilt').height(36).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(39.9042, 116.4074, 14, 0, 45, 1000))
      }
      .width('100%')

      Row() {
        Button('Max Tilt').height(36).margin({ top: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(39.9042, 116.4074, 13, 90, 60, 1500))
        Button('Full Rotation').height(36).margin({ top: 6, left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animatePosition(39.9042, 116.4074, 12, 360, 30, 3000))
      }
      .width('100%')

      Button('Cancel')
        .width('100%')
        .margin({ top: 10 })
        .backgroundColor('#F44336')
        .enabled(this.isAnimating)
        .onClick(() => {
          this.mapController?.cancelTransitions();
          this.isAnimating = false;
          this.statusMessage = 'Cancelled';
        })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Camera Animator',
      subtitle: 'Animation duration and easing',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
