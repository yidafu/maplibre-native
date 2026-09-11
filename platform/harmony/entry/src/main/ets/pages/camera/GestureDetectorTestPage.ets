/**
 * GestureDetectorTestPage - Gesture recognizer testing.
 *
 * Registers map click, long-click, camera move listeners to log and display gesture events.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng, CameraState } from 'maplibre_harmony';
import { MapClickListener, MapLongClickListener } from '../../utils/ListenerFactories';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct GestureDetectorTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready';
  @State private lastEvent: string = '(none)';
  @State private lastCoordinate: string = '';
  @State private eventCount: number = 0;
  @State private listenerActive: boolean = false;

  private mapClickListener = new MapClickListener(
    (x: number, y: number): boolean => {
      if (!this.mapController) return false;
      const latLng: LatLng = this.mapController.latLngForPixel(x, y);
      this.lastEvent = 'Click';
      this.lastCoordinate = `(${latLng.latitude.toFixed(4)}, ${latLng.longitude.toFixed(4)})`;
      this.eventCount++;
      this.statusMessage = `Click at screen (${x}, ${y})`;
      return true;
    }
  );

  private mapLongClickListener = new MapLongClickListener(
    (x: number, y: number): boolean => {
      if (!this.mapController) return false;
      const latLng: LatLng = this.mapController.latLngForPixel(x, y);
      this.lastEvent = 'Long Click';
      this.lastCoordinate = `(${latLng.latitude.toFixed(4)}, ${latLng.longitude.toFixed(4)})`;
      this.eventCount++;
      this.statusMessage = `Long click at screen (${x}, ${y})`;
      return true;
    }
  );

  aboutToDisappear() {
    if (this.mapController) {
      this.removeListeners();
      this.mapController.destroy();
    }
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Tap "Enable Listeners" to start.';
  };

  private toggleListeners(): void {
    if (!this.mapController) return;
    if (this.listenerActive) {
      this.removeListeners();
      this.listenerActive = false;
      this.statusMessage = 'Listeners disabled';
      showToast('Gesture listeners removed');
    } else {
      this.mapController.addOnMapClickListener(this.mapClickListener);
      this.mapController.addOnMapLongClickListener(this.mapLongClickListener);
      this.listenerActive = true;
      this.statusMessage = 'Listeners active. Tap or long-press the map.';
      showToast('Gesture listeners enabled');
    }
  }

  private removeListeners(): void {
    if (!this.mapController) return;
    try {
      this.mapController.removeOnMapClickListener(this.mapClickListener);
      this.mapController.removeOnMapLongClickListener(this.mapLongClickListener);
    } catch (_e) {
      // ignore errors during cleanup
    }
  }

  private clearEvents(): void {
    this.lastEvent = '(none)';
    this.lastCoordinate = '';
    this.eventCount = 0;
    this.statusMessage = 'Events cleared';
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
      Text('Gesture Detector')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        Text(this.statusMessage)
          .fontSize(12)
          .layoutWeight(1)
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#F5F5F5')
      .borderRadius(6)

      Text('Last Event')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Column() {
        Text(`Type: ${this.lastEvent}`)
          .fontSize(13)
        Text(`Coordinate: ${this.lastCoordinate}`)
          .fontSize(13)
          .fontFamily('monospace')
          .margin({ top: 2 })
        Text(`Total Events: ${this.eventCount}`)
          .fontSize(13)
          .margin({ top: 2 })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFF8E1')
      .borderRadius(6)
      .padding(10)

      Button(this.listenerActive ? 'Disable Listeners' : 'Enable Listeners')
        .width('100%')
        .margin({ top: 12 })
        .backgroundColor(this.listenerActive ? '#FF5722' : '#4CAF50')
        .enabled(this.isMapReady)
        .onClick((): void => this.toggleListeners())

      Button('Clear Events')
        .width('100%')
        .margin({ top: 8 })
        .enabled(this.isMapReady)
        .onClick((): void => this.clearEvents())

      Button('Get Camera State')
        .width('100%')
        .margin({ top: 8 })
        .enabled(this.isMapReady)
        .onClick((): void => {
          if (!this.mapController) return;
          const state: CameraState = this.mapController.getCameraState();
          this.statusMessage = `Camera: (${state.latitude.toFixed(4)}, ${state.longitude.toFixed(4)}) z=${state.zoom.toFixed(2)}`;
        })

      Text('Hint')
        .fontSize(11)
        .fontColor('#999')
        .width('100%')
        .margin({ top: 10 })
      Text('Enable listeners then tap or long-press the map to see gesture events.')
        .fontSize(11)
        .fontColor('#999')
        .lineHeight(16)
        .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Gesture Detector',
      subtitle: 'Gesture recognizer testing',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
