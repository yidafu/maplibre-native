/**
 * AnnotationViewTestPage - Custom annotation views.
 *
 * Demonstrates using AnnotationViewAdapter to create custom
 * marker views with different visual styles and behaviors.
 */
import {
  TestPageLayout
} from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, Marker, MarkerOptions, LatLng,
  AnnotationViewAdapter, AnnotationViewConfig, AnnotationViewDelegate,
  OnMarkerDragListener
} from 'maplibre_harmony';
import { MarkerClickListener } from '../../utils/ListenerFactories';
import { showToast, formatLatLng } from '../common/TestUtils';

interface LocationInfo {
  lat: number;
  lng: number;
  name: string;
  desc: string;
}

@Component
export struct ColoredCircleView {
  @Prop color: string = '#FF5722';
  @Prop label: string = '';

  build() {
    Column() {
      Circle()
        .width(36)
        .height(36)
        .fill(this.color)
        .stroke(Color.White)
        .strokeWidth(2)
      Text(this.label)
        .fontSize(10)
        .fontColor(this.color)
        .textAlign(TextAlign.Center)
        .margin({ top: 2 })
    }
    .width(50)
    .height(50)
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
export struct InfoBadgeView {
  @Prop title: string = '';
  @Prop snippet: string = '';
  @Prop color: string = '#2196F3';

  build() {
    Column() {
      Text(this.title)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .padding({ left: 10, right: 10, top: 4, bottom: 2 })
      if (this.snippet) {
        Text(this.snippet)
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.8)')
          .padding({ left: 10, right: 10, bottom: 4 })
      }
    }
    .backgroundColor(this.color)
    .borderRadius(8)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.3)', offsetX: 0, offsetY: 2 })
  }
}

class TestAnnotationViewDelegate implements AnnotationViewDelegate {
  private page: AnnotationViewTestPage;

  constructor(page: AnnotationViewTestPage) {
    this.page = page;
  }

  viewForAnnotation(marker: Marker): AnnotationViewConfig | null {
    const snippet = marker.getSnippet();
    if (snippet === 'circle-red') {
      return {
        reuseIdentifier: 'circle-red',
        draggable: false,
        centerOffset: { dx: 0, dy: -18 },
        zIndex: 5
      } as AnnotationViewConfig;
    } else if (snippet === 'circle-blue') {
      return {
        reuseIdentifier: 'circle-blue',
        draggable: false,
        centerOffset: { dx: 0, dy: -18 },
        zIndex: 5
      } as AnnotationViewConfig;
    } else if (snippet === 'circle-green') {
      return {
        reuseIdentifier: 'circle-green',
        draggable: false,
        centerOffset: { dx: 0, dy: -18 },
        zIndex: 5
      } as AnnotationViewConfig;
    } else if (snippet === 'info-badge') {
      return {
        reuseIdentifier: 'info-badge',
        draggable: false,
        centerOffset: { dx: 0, dy: -30 },
        zIndex: 10
      } as AnnotationViewConfig;
    }
    return null;
  }

  didSelectAnnotationView(marker: Marker): void {
    this.page.statusMessage = `Selected: ${marker.getTitle()}`;
  }

  didDeselectAnnotationView(marker: Marker): void {
    this.page.statusMessage = `Deselected: ${marker.getTitle()}`;
  }

  annotationViewWillStartDragging(marker: Marker): void {
    this.page.statusMessage = `Drag started: ${marker.getTitle()}`;
  }

  annotationViewDidEndDragging(marker: Marker, finalPosition: LatLng): void {
    this.page.statusMessage = `Drag ended at ${formatLatLng(finalPosition.latitude, finalPosition.longitude, 4)}`;
  }

  getReuseIdentifier(marker: Marker): string | undefined {
    return marker.getSnippet() || undefined;
  }
}

@Entry
@Component
struct AnnotationViewTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State statusMessage: string = 'Loading...';
  @State private markerCount: number = 0;
  @State private scalesEnabled: boolean = false;
  @State private rotatesEnabled: boolean = false;
  @State private dragMode: boolean = false;

  private delegate: TestAnnotationViewDelegate | null = null;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;

    // Set up delegate
    this.delegate = new TestAnnotationViewDelegate(this);
    map.getMarkerManager().getAnnotationViewManager().setDelegate(this.delegate);

    // Set up click listener
    map.setOnMarkerClickListener(new MarkerClickListener(
      (marker: Marker): boolean => {
        const pos = marker.getPosition();
        this.statusMessage = `Clicked: ${marker.getTitle()} at ${formatLatLng(pos.latitude, pos.longitude, 4)}`;
        showToast(marker.getTitle());
        return false;
      }
    ));

    this.statusMessage = 'Map ready - add annotation views';
    console.info('[AnnotationViewTestPage] Map ready');
  };

  private async addMarkers(color: string, count: number): Promise<void> {
    if (!this.mapController) return;
    const center = this.mapController.getLatLng();
    const optionsList: MarkerOptions[] = [];

    for (let i = 0; i < count; i++) {
      const lat = center.latitude + (Math.random() - 0.5) * 0.3;
      const lng = center.longitude + (Math.random() - 0.5) * 0.3;
      const snippet = color === 'red' ? 'circle-red' :
        color === 'blue' ? 'circle-blue' : 'circle-green';
      optionsList.push(new MarkerOptions()
        .position(new LatLng(lat, lng))
        .title(`${color.charAt(0).toUpperCase() + color.slice(1)} #${i + 1}`)
        .snippet(snippet)
      );
    }

    const markers = await this.mapController.addMarkersBatch(optionsList);
    this.markerCount += markers.length;
    this.statusMessage = `Added ${count} ${color} markers`;
    showToast(`Added ${count} ${color} annotation views`);
  }

  private async addInfoBadgeMarkers(): Promise<void> {
    if (!this.mapController) return;
    const center = this.mapController.getLatLng();
    const locations: LocationInfo[] = [
      { lat: center.latitude + 0.1, lng: center.longitude, name: 'Location A', desc: 'First place' },
      { lat: center.latitude - 0.1, lng: center.longitude + 0.1, name: 'Location B', desc: 'Second place' },
      { lat: center.latitude, lng: center.longitude - 0.1, name: 'Location C', desc: 'Third place' },
    ];

    for (const loc of locations) {
      await this.mapController.addMarker(new MarkerOptions()
        .position(new LatLng(loc.lat, loc.lng))
        .title(loc.name)
        .snippet('info-badge')
      );
    }
    this.markerCount += locations.length;
    this.statusMessage = `Added ${locations.length} info badge markers`;
    showToast('Info badges added');
  }

  private clearAll(): void {
    if (!this.mapController) return;
    this.mapController.clear();
    this.markerCount = 0;
    this.statusMessage = 'All annotation views cleared';
    showToast('Cleared all');
  }

  private toggleScale(): void {
    this.scalesEnabled = !this.scalesEnabled;
    showToast(`Scale: ${this.scalesEnabled ? 'enabled' : 'disabled'}`);
  }

  private toggleRotate(): void {
    this.rotatesEnabled = !this.rotatesEnabled;
    showToast(`Rotate: ${this.rotatesEnabled ? 'enabled' : 'disabled'}`);
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

      Text(`Markers: ${this.markerCount}`)
        .fontSize(14)
        .fontColor('#2196F3')
        .width('100%')
        .margin({ top: 8 })

      Text('Add Colored Circles').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({ top: 8 })

      Row() {
        Button('Red (5)')
          .width('31%')
          .fontSize(12)
          .backgroundColor('#F44336')
          .fontColor(Color.White)
          .onClick((): void => { this.addMarkers('red', 5); })
          .enabled(this.isMapReady)

        Button('Blue (5)')
          .width('31%')
          .margin({ left: 8 })
          .fontSize(12)
          .backgroundColor('#2196F3')
          .fontColor(Color.White)
          .onClick((): void => { this.addMarkers('blue', 5); })
          .enabled(this.isMapReady)

        Button('Green (5)')
          .width('31%')
          .margin({ left: 8 })
          .fontSize(12)
          .backgroundColor('#4CAF50')
          .fontColor(Color.White)
          .onClick((): void => { this.addMarkers('green', 5); })
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 4 })

      Button('Add Info Badges')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#9C27B0')
        .fontColor(Color.White)
        .fontSize(13)
        .onClick((): void => { this.addInfoBadgeMarkers(); })
        .enabled(this.isMapReady)

      Divider().margin({ top: 8, bottom: 8 })

      Row() {
        Button(`Scale: ${this.scalesEnabled ? 'ON' : 'OFF'}`)
          .width('48%')
          .fontSize(12)
          .backgroundColor(this.scalesEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick((): void => this.toggleScale())
          .enabled(this.isMapReady)

        Button(`Rotate: ${this.rotatesEnabled ? 'ON' : 'OFF'}`)
          .width('48%')
          .margin({ left: 8 })
          .fontSize(12)
          .backgroundColor(this.rotatesEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick((): void => this.toggleRotate())
          .enabled(this.isMapReady)
      }
      .width('100%')

      Button('Clear All')
        .width('100%')
        .margin({ top: 8 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick((): void => this.clearAll())
        .enabled(this.isMapReady && this.markerCount > 0)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Annotation View',
      subtitle: 'Custom annotation views',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
