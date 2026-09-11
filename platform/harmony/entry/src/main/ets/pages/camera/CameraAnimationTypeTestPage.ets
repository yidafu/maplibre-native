/**
 * CameraAnimationTypeTestPage - Compare animation curves (easeTo vs flyTo).
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng, CameraOptions } from 'maplibre_harmony';
import { CameraAnimationCallbackImpl } from '../../utils/ListenerFactories';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct CameraAnimationTypeTestPage {
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

  private easeToTarget(lat: number, lng: number, zoom: number, duration: number): void {
    if (!this.mapController || this.isAnimating) return;
    this.isAnimating = true;
    this.statusMessage = `easeTo: moving to (${lat.toFixed(2)}, ${lng.toFixed(2)})...`;
    this.mapController.easeTo(
      { center: new LatLng(lat, lng).toObject(), zoom: zoom } as CameraOptions,
      duration,
      new CameraAnimationCallbackImpl(
        (): void => {
          this.isAnimating = false;
          this.statusMessage = 'easeTo complete';
          showToast('easeTo finished');
        },
        (): void => {
          this.isAnimating = false;
          this.statusMessage = 'easeTo cancelled';
        }
      )
    );
  }

  private flyToTarget(lat: number, lng: number, zoom: number, duration: number): void {
    if (!this.mapController || this.isAnimating) return;
    this.isAnimating = true;
    this.statusMessage = `flyTo: moving to (${lat.toFixed(2)}, ${lng.toFixed(2)})...`;
    this.mapController.flyTo(
      { center: new LatLng(lat, lng).toObject(), zoom: zoom } as CameraOptions,
      duration,
      new CameraAnimationCallbackImpl(
        (): void => {
          this.isAnimating = false;
          this.statusMessage = 'flyTo complete';
          showToast('flyTo finished');
        },
        (): void => {
          this.isAnimating = false;
          this.statusMessage = 'flyTo cancelled';
        }
      )
    );
  }

  private jumpToTarget(lat: number, lng: number, zoom: number): void {
    if (!this.mapController) return;
    const bearing = this.mapController.getBearing();
    const pitch = this.mapController.getPitch();
    this.mapController.jumpTo(bearing, lat, lng, pitch, zoom);
    this.statusMessage = `Jumped to (${lat.toFixed(2)}, ${lng.toFixed(2)})`;
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

      Text('Animation Types - Beijing to Shanghai')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Jump').height(44).enabled(!this.isAnimating)
          .onClick((): void => this.jumpToTarget(31.2304, 121.4737, 10))
        Button('Ease 500ms').height(44).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick((): void => this.easeToTarget(31.2304, 121.4737, 10, 500))
        Button('Fly 500ms').height(44).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick((): void => this.flyToTarget(31.2304, 121.4737, 10, 500))
      }
      .width('100%')

      Row() {
        Button('Ease 2s').height(44).margin({ top: 6 }).enabled(!this.isAnimating)
          .onClick((): void => this.easeToTarget(31.2304, 121.4737, 12, 2000))
        Button('Fly 2s').height(44).margin({ top: 6, left: 6 }).enabled(!this.isAnimating)
          .onClick((): void => this.flyToTarget(31.2304, 121.4737, 12, 2000))
        Button('Fly 4s').height(44).margin({ top: 6, left: 6 }).enabled(!this.isAnimating)
          .onClick((): void => this.flyToTarget(31.2304, 121.4737, 14, 4000))
      }
      .width('100%')

      Text('Long Distance')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Ease: Beijing->NYC').height(44).enabled(!this.isAnimating)
          .onClick((): void => this.easeToTarget(40.7128, -74.006, 10, 3000))
        Button('Fly: Beijing->NYC').height(44).margin({ left: 6 }).enabled(!this.isAnimating)
          .onClick((): void => this.flyToTarget(40.7128, -74.006, 10, 3000))
      }
      .width('100%')

      Text('Notes')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 10 })
      Text('easeTo: smooth linear movement. flyTo: curved aerial arc with zoom out/in.')
        .fontSize(11)
        .fontColor('#666')
        .lineHeight(16)
        .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Animation Type',
      subtitle: 'easeTo vs flyTo comparison',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
