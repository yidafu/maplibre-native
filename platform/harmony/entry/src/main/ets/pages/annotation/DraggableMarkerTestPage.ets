/**
 * DraggableMarkerTestPage - Test draggable markers.
 *
 * Demonstrates creating markers with drag support and
 * listening to drag events (start, drag, end).
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, Marker, MarkerOptions, LatLng,
  OnMarkerDragListener
} from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast, formatLatLng } from '../common/TestUtils';

class DraggableDragListener implements OnMarkerDragListener {
  private page: DraggableMarkerTestPage;

  constructor(page: DraggableMarkerTestPage) {
    this.page = page;
  }

  onMarkerDragStart(marker: Marker): void {
    this.page.dragStatus = 'Drag started';
    console.info('[DraggableMarker] Drag start');
  }

  onMarkerDrag(marker: Marker): void {
    const pos = marker.getPosition();
    this.page.dragStatus = `Dragging: ${formatLatLng(pos.latitude, pos.longitude, 4)}`;
  }

  onMarkerDragEnd(marker: Marker): void {
    const pos = marker.getPosition();
    this.page.dragStatus = `Drag end: ${formatLatLng(pos.latitude, pos.longitude, 4)}`;
    showToast('Marker moved to new position');
  }
}

@Entry
@Component
struct DraggableMarkerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State dragStatus: string = 'Long-press a marker to drag';
  @State private markerCount: number = 0;

  aboutToDisappear(): void {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;

    // Add initial draggable marker
    map.addMarker(new MarkerOptions()
      .position(TEST_LOCATIONS.beijing)
      .title('Drag me')
      .snippet('Beijing')
      .draggable(true)
    ).then(() => {
      this.markerCount = 1;
    });

    map.addMarker(new MarkerOptions()
      .position(TEST_LOCATIONS.shanghai)
      .title('Drag me too')
      .snippet('Shanghai')
      .draggable(true)
    ).then(() => {
      this.markerCount = 2;
    });

    // Set up drag listener
    map.setOnMarkerDragListener(new DraggableDragListener(this));

    this.dragStatus = 'Long-press a marker to drag';
    console.info('[DraggableMarkerTestPage] Map ready');
  };

  private async addDraggableMarker(): Promise<void> {
    if (!this.mapController) return;
    const center = this.mapController.getLatLng();
    await this.mapController.addMarker(new MarkerOptions()
      .position(center)
      .title(`Marker ${this.markerCount + 1}`)
      .snippet(`Created at ${formatLatLng(center.latitude, center.longitude, 4)}`)
      .draggable(true)
    );
    this.markerCount++;
    showToast('Draggable marker added');
  }

  private clearAll(): void {
    if (!this.mapController) return;
    this.mapController.clear();
    this.markerCount = 0;
    this.dragStatus = 'All markers cleared';
    showToast('Cleared all markers');
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
      Text('Drag Status')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text(this.dragStatus)
        .fontSize(14)
        .fontColor('#666')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)
        .margin({ top: 8 })

      Text(`Markers: ${this.markerCount}`)
        .fontSize(14)
        .fontColor('#2196F3')
        .width('100%')
        .margin({ top: 12 })

      Button('Add Draggable Marker')
        .width('100%')
        .margin({ top: 12 })
        .onClick((): void => { this.addDraggableMarker(); })
        .enabled(this.isMapReady)

      Button('Clear All')
        .width('100%')
        .margin({ top: 8 })
        .fontColor(Color.White)
        .backgroundColor('#F44336')
        .onClick((): void => this.clearAll())
        .enabled(this.isMapReady && this.markerCount > 0)

      Text('Hint: Long-press on a marker to start dragging')
        .fontSize(12)
        .fontColor('#999')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 12 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Draggable Marker',
      subtitle: 'Drag markers to new positions',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
