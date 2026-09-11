/**
 * PressForMarkerTestPage - Long-press the map to add a marker.
 *
 * Demonstrates using OnMapLongClickListener to add markers
 * at the long-pressed location, and OnMapClickListener for
 * quick tap placement.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, Marker, MarkerOptions, LatLng
} from 'maplibre_harmony';
import { MapClickListener, MapLongClickListener } from '../../utils/ListenerFactories';
import { showToast, formatLatLng } from '../common/TestUtils';

@Entry
@Component
struct PressForMarkerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private markerCount: number = 0;
  @State private lastAction: string = '';
  @State private mode: string = 'longpress';

  private markers: Marker[] = [];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.setupListeners(map);
    this.statusMessage = 'Long-press the map to add a marker';
    console.info('[PressForMarkerTestPage] Map ready');
  };

  private setupListeners(map: MapLibreMap): void {
    // Long-press listener - always adds a marker
    map.addOnMapLongClickListener(new MapLongClickListener(
      (x: number, y: number): boolean => {
        if (!this.mapController) return false;
        const latLng = this.mapController.latLngForPixel(x, y);
        this.addMarkerAt(latLng, 'Long-press');
        return true;
      }
    ));

    // Click listener - adds a marker only in click mode
    map.addOnMapClickListener(new MapClickListener(
      (x: number, y: number): boolean => {
        if (!this.mapController || this.mode !== 'click') return false;
        const latLng = this.mapController.latLngForPixel(x, y);
        this.addMarkerAt(latLng, 'Click');
        return true;
      }
    ));
  }

  private async addMarkerAt(position: LatLng, actionType: string): Promise<void> {
    if (!this.mapController) return;

    try {
      const marker = await this.mapController.addMarker(new MarkerOptions()
        .position(position)
        .title(`Marker #${this.markerCount + 1}`)
        .snippet(`${actionType}: ${formatLatLng(position.latitude, position.longitude, 4)}`)
      );
      this.markers.push(marker);
      this.markerCount++;
      this.lastAction = `${actionType} at ${formatLatLng(position.latitude, position.longitude, 4)}`;
      this.statusMessage = `Added marker #${this.markerCount} via ${actionType}`;
    } catch (err) {
      this.statusMessage = `Error adding marker: ${err}`;
    }
  }

  private clearAllMarkers(): void {
    if (!this.mapController) return;
    this.mapController.clearMarkers();
    this.markers = [];
    this.markerCount = 0;
    this.lastAction = '';
    this.statusMessage = 'All markers cleared';
    showToast('Cleared all markers');
  }

  private switchMode(): void {
    this.mode = this.mode === 'longpress' ? 'click' : 'longpress';
    this.statusMessage = `Mode: ${this.mode === 'longpress' ? 'Long-press to add' : 'Tap to add'}`;
    showToast(`Switched to ${this.mode} mode`);
  }

  private undoLastMarker(): void {
    if (!this.mapController || this.markers.length === 0) return;
    const lastMarker = this.markers.pop();
    if (lastMarker) {
      this.mapController.removeMarker(lastMarker);
      this.markerCount--;
      this.statusMessage = `Removed last marker (${this.markerCount} remaining)`;
      showToast('Last marker removed');
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

      Text('Marker Count')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12 })

      Text(`${this.markerCount}`)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2196F3')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 4 })

      if (this.lastAction) {
        Text(`Last: ${this.lastAction}`)
          .fontSize(11)
          .fontColor('#666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 4 })
      }

      Divider().margin({ top: 12, bottom: 8 })

      Button(`Mode: ${this.mode === 'longpress' ? 'Long-Press' : 'Tap'}`)
        .width('100%')
        .margin({ top: 4 })
        .backgroundColor(this.mode === 'longpress' ? '#FF9800' : '#2196F3')
        .fontColor(Color.White)
        .onClick((): void => this.switchMode())
        .enabled(this.isMapReady)

      Button('Undo Last')
        .width('100%')
        .margin({ top: 6 })
        .onClick((): void => this.undoLastMarker())
        .enabled(this.isMapReady && this.markerCount > 0)

      Button('Clear All')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick((): void => this.clearAllMarkers())
        .enabled(this.isMapReady && this.markerCount > 0)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Press for Marker',
      subtitle: 'Long-press to add a marker',
      mapContent: this.mapContent,
      controlPanel: this.controlPanel,
      })
    }
    .width('100%')
    .height('100%')
  }
}
