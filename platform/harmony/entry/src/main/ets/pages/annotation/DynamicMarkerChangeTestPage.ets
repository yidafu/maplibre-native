/**
 * DynamicMarkerChangeTestPage - Change marker properties at runtime.
 *
 * Demonstrates modifying marker position, title, alpha, rotation,
 * and visibility dynamically through the API.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, Marker, MarkerOptions, LatLng
} from 'maplibre_harmony';
import { MarkerClickListener } from '../../utils/ListenerFactories';
import { showToast, formatLatLng } from '../common/TestUtils';

@Entry
@Component
struct DynamicMarkerChangeTestPage {
  private mapController: MapLibreMap | null = null;
  private marker: Marker | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private changeCount: number = 0;
  @State private markerPosition: string = '39.9042, 116.4074';
  @State private markerTitle: string = 'Dynamic Marker';
  @State private markerAlpha: number = 1.0;
  @State private markerRotation: number = 0;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Adding marker...';

    // Set up marker click listener
    map.setOnMarkerClickListener(new MarkerClickListener(
      (marker: Marker): boolean => {
        showToast(`Clicked: ${marker.getTitle()}`);
        return false;
      }
    ));

    // Add initial marker
    const initialPos = new LatLng(39.9042, 116.4074);
    this.marker = await map.addMarker(new MarkerOptions()
      .position(initialPos)
      .title('Dynamic Marker')
      .snippet('Change properties below')
    );

    this.markerPosition = formatLatLng(initialPos.latitude, initialPos.longitude);
    this.statusMessage = 'Marker ready - try changing properties';
    console.info('[DynamicMarkerChangeTestPage] Map ready');
  };

  private changePosition(): void {
    if (!this.marker) return;
    const newLat = 39.85 + Math.random() * 0.1;
    const newLng = 116.35 + Math.random() * 0.1;
    const newPos = new LatLng(newLat, newLng);
    this.marker.setPosition(newPos);
    this.markerPosition = formatLatLng(newLat, newLng);
    this.changeCount++;
    this.statusMessage = `Position changed (${this.changeCount})`;
    showToast('Position updated');
  }

  private changeTitle(): void {
    if (!this.marker) return;
    const titles: string[] = ['Marker A', 'Marker B', 'Marker C', 'Dynamic Point', 'Test Location'];
    this.markerTitle = titles[Math.floor(Math.random() * titles.length)];
    this.marker.setTitle(this.markerTitle);
    this.changeCount++;
    this.marker.setSnippet(`Changes: ${this.changeCount}`);
    this.statusMessage = `Title: ${this.markerTitle}`;
    showToast('Title updated');
  }

  private changeAlpha(): void {
    if (!this.marker) return;
    this.markerAlpha = 0.2 + Math.random() * 0.8;
    this.marker.setAlpha(this.markerAlpha);
    this.changeCount++;
    this.statusMessage = `Alpha: ${this.markerAlpha.toFixed(2)}`;
  }

  private changeRotation(): void {
    if (!this.marker) return;
    this.markerRotation = (this.markerRotation + 45) % 360;
    this.marker.setRotation(this.markerRotation);
    this.changeCount++;
    this.statusMessage = `Rotation: ${this.markerRotation} deg`;
    showToast(`Rotated to ${this.markerRotation} deg`);
  }

  private toggleVisibility(): void {
    if (!this.marker) return;
    const visible = !this.marker.getVisible();
    this.marker.setVisible(visible);
    this.changeCount++;
    this.statusMessage = `Visible: ${visible}`;
    showToast(visible ? 'Marker visible' : 'Marker hidden');
  }

  private showInfoWindow(): void {
    if (!this.marker || !this.mapController) return;
    this.mapController.selectMarker(this.marker, true);
  }

  private hideInfoWindow(): void {
    if (!this.marker || !this.mapController) return;
    this.mapController.deselectMarker(this.marker);
  }

  private removeAndRecreate(): void {
    if (!this.mapController) return;
    if (this.marker) {
      this.mapController.removeMarker(this.marker);
    }
    const pos = new LatLng(39.9042, 116.4074);
    this.mapController.addMarker(new MarkerOptions()
      .position(pos)
      .title('Dynamic Marker')
      .snippet('Recreated')
    ).then((marker: Marker): void => {
      this.marker = marker;
      this.markerPosition = formatLatLng(pos.latitude, pos.longitude);
      this.markerTitle = 'Dynamic Marker';
      this.markerAlpha = 1.0;
      this.markerRotation = 0;
      this.changeCount = 0;
      this.statusMessage = 'Marker recreated';
      showToast('Marker recreated');
    });
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

      Text('Marker Properties')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Text(`Title: ${this.markerTitle}`).fontSize(12).fontColor('#666').width('100%')
      Text(`Position: ${this.markerPosition}`).fontSize(12).fontColor('#666').width('100%')
      Text(`Alpha: ${this.markerAlpha.toFixed(2)}`).fontSize(12).fontColor('#666').width('100%')
      Text(`Rotation: ${this.markerRotation} deg`).fontSize(12).fontColor('#666').width('100%')
      Text(`Changes: ${this.changeCount}`).fontSize(12).fontColor('#666').width('100%')

      Row() {
        Button('Change Position')
          .width('48%')
          .margin({ top: 8 })
          .fontSize(13)
          .onClick((): void => this.changePosition())
          .enabled(this.isMapReady)

        Button('Change Title')
          .width('48%')
          .margin({ top: 8, left: 8 })
          .fontSize(13)
          .onClick((): void => this.changeTitle())
          .enabled(this.isMapReady)
      }
      .width('100%')

      Row() {
        Button('Change Alpha')
          .width('48%')
          .margin({ top: 6 })
          .fontSize(13)
          .onClick((): void => this.changeAlpha())
          .enabled(this.isMapReady)

        Button('Change Rotation')
          .width('48%')
          .margin({ top: 6, left: 8 })
          .fontSize(13)
          .onClick((): void => this.changeRotation())
          .enabled(this.isMapReady)
      }
      .width('100%')

      Row() {
        Button('Toggle Visibility')
          .width('48%')
          .margin({ top: 6 })
          .fontSize(13)
          .onClick((): void => this.toggleVisibility())
          .enabled(this.isMapReady)

        Button('Recreate Marker')
          .width('48%')
          .margin({ top: 6, left: 8 })
          .fontSize(13)
          .backgroundColor('#FF9800')
          .onClick((): void => this.removeAndRecreate())
          .enabled(this.isMapReady)
      }
      .width('100%')

      Row() {
        Button('Show Info')
          .width('48%')
          .margin({ top: 8 })
          .fontSize(13)
          .onClick((): void => this.showInfoWindow())
          .enabled(this.isMapReady)

        Button('Hide Info')
          .width('48%')
          .margin({ top: 8, left: 8 })
          .fontSize(13)
          .onClick((): void => this.hideInfoWindow())
          .enabled(this.isMapReady)
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Dynamic Marker',
      subtitle: 'Change marker properties at runtime',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
