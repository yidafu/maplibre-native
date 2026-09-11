/**
 * CameraUpdateTestPage - Animate camera movements.
 *
 * Reference: Android CameraUpdateFactoryActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng } from 'maplibre_harmony';
import { CameraAnimationCallbackImpl } from '../../utils/ListenerFactories';
import { TEST_LOCATIONS, showToast, DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct CameraUpdateTestPage {
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

  private animateToTarget(lat: number, lng: number, zoom: number, bearing: number, pitch: number, duration: number): void {
    if (!this.mapController || this.isAnimating) return;
    this.isAnimating = true;
    this.statusMessage = `Animating to (${lat.toFixed(2)}, ${lng.toFixed(2)})...`;

    this.mapController.easeTo(
      { center: new LatLng(lat, lng).toObject(), zoom: zoom, bearing: bearing, pitch: pitch },
      duration,
      new CameraAnimationCallbackImpl(
        (): void => {
          this.isAnimating = false;
          this.statusMessage = 'Animation complete';
          showToast('Animation finished');
        },
        (): void => {
          this.isAnimating = false;
          this.statusMessage = 'Animation cancelled';
        }
      )
    );
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
      Text('Camera Animation')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text(this.statusMessage)
        .fontSize(12)
        .fontColor(this.isAnimating ? '#FF9800' : '#4CAF50')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Animate to Cities')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Beijing').height(36).enabled(!this.isAnimating)
          .onClick(() => this.animateToTarget(39.9042, 116.4074, 12, 0, 0, 1500))
        Button('Shanghai').height(36).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animateToTarget(31.2304, 121.4737, 14, 45, 30, 2000))
        Button('Hangzhou').height(36).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animateToTarget(30.2741, 120.1551, 13, 0, 0, 1500))
      }
      .width('100%')

      Row() {
        Button('NYC').height(36).margin({ top: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animateToTarget(40.7128, -74.006, 14, 90, 45, 2500))
        Button('Tokyo').height(36).margin({ top: 6, left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animateToTarget(35.6762, 139.6503, 13, 180, 30, 2000))
        Button('London').height(36).margin({ top: 6, left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animateToTarget(51.5074, -0.1278, 12, 270, 0, 1500))
      }
      .width('100%')

      Text('Animation Duration')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('0ms (Jump)').height(36).enabled(!this.isAnimating)
          .onClick(() => this.animateToTarget(30.2741, 120.1551, 8, 0, 0, 0))
        Button('500ms').height(36).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animateToTarget(30.2741, 120.1551, 10, 0, 0, 500))
        Button('3000ms').height(36).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick(() => this.animateToTarget(30.2741, 120.1551, 12, 0, 0, 3000))
      }
      .width('100%')

      Button('Cancel Animation')
        .width('100%')
        .margin({ top: 10 })
        .backgroundColor('#FF5722')
        .enabled(this.isAnimating)
        .onClick(() => {
          this.mapController?.cancelTransitions();
          this.isAnimating = false;
          this.statusMessage = 'Animation cancelled';
        })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Camera Update',
      subtitle: 'Animate camera movements',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
