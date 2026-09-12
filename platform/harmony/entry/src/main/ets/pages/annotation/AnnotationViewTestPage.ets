/**
 * AnnotationViewTestPage - Custom annotation views.
 *
 * Demonstrates using AnnotationViewDelegate to create custom
 * marker views (marker-anchored ViewAnnotations) with different
 * visual styles and behaviors.
 */
import {
  TestPageLayout
} from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, Marker, MarkerOptions, LatLng,
  AnnotationViewConfig, AnnotationViewDelegate,
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

const CIRCLE_RED = '#F44336';
const CIRCLE_BLUE = '#2196F3';
const CIRCLE_GREEN = '#4CAF50';
const BADGE_PURPLE = '#9C27B0';

class CircleContentParams {
  color: string = '';
  title: string = '';
}

class BadgeContentParams {
  title: string = '';
}

// UI (DSL) syntax is only allowed inside @Builder contexts, so marker view
// content lives in module-level @Builder functions; the delegate's
// contentBuilder closures simply forward to them.
@Builder
function circleMarkerContent($$: CircleContentParams) {
  Column() {
    Circle()
      .width(36)
      .height(36)
      .fill($$.color)
      .stroke(Color.White)
      .strokeWidth(2)
    Text($$.title)
      .fontSize(10)
      .fontColor($$.color)
      .textAlign(TextAlign.Center)
      .maxLines(1)
  }
  .alignItems(HorizontalAlign.Center)
}

@Builder
function badgeMarkerContent($$: BadgeContentParams) {
  Column() {
    Text($$.title)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .padding({ left: 10, right: 10, top: 4, bottom: 2 })
    Text('Custom view annotation')
      .fontSize(10)
      .fontColor('rgba(255,255,255,0.8)')
      .padding({ left: 10, right: 10, bottom: 4 })
  }
  .backgroundColor(BADGE_PURPLE)
  .borderRadius(8)
  .shadow({ radius: 4, color: 'rgba(0,0,0,0.3)', offsetX: 0, offsetY: 2 })
}

class TestAnnotationViewDelegate implements AnnotationViewDelegate {
  private page: AnnotationViewTestPage;

  constructor(page: AnnotationViewTestPage) {
    this.page = page;
  }

  viewForAnnotation(marker: Marker): AnnotationViewConfig | null {
    const snippet = marker.getSnippet();
    if (snippet === 'circle-red' || snippet === 'circle-blue' || snippet === 'circle-green') {
      const color = snippet === 'circle-red' ? CIRCLE_RED :
        snippet === 'circle-blue' ? CIRCLE_BLUE : CIRCLE_GREEN;
      const params = new CircleContentParams();
      params.color = color;
      params.title = marker.getTitle();
      return {
        reuseIdentifier: snippet,
        contentBuilder: (): void => {
          circleMarkerContent(params)
        },
        draggable: false,
        centerOffset: { dx: 0, dy: -18 },
        zIndex: 5
      } as AnnotationViewConfig;
    } else if (snippet === 'info-badge') {
      const params = new BadgeContentParams();
      params.title = marker.getTitle();
      return {
        reuseIdentifier: 'info-badge',
        contentBuilder: (): void => {
          badgeMarkerContent(params)
        },
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

  private delegate: TestAnnotationViewDelegate | null = null;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;

    // Set up delegate (marker custom views render as marker-anchored
    // ViewAnnotations on the shared floating-layer engine)
    this.delegate = new TestAnnotationViewDelegate(this);
    map.setAnnotationViewDelegate(this.delegate);

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
          .backgroundColor(CIRCLE_RED)
          .fontColor(Color.White)
          .onClick((): void => { this.addMarkers('red', 5); })
          .enabled(this.isMapReady)

        Button('Blue (5)')
          .width('31%')
          .margin({ left: 8 })
          .fontSize(12)
          .backgroundColor(CIRCLE_BLUE)
          .fontColor(Color.White)
          .onClick((): void => { this.addMarkers('blue', 5); })
          .enabled(this.isMapReady)

        Button('Green (5)')
          .width('31%')
          .margin({ left: 8 })
          .fontSize(12)
          .backgroundColor(CIRCLE_GREEN)
          .fontColor(Color.White)
          .onClick((): void => { this.addMarkers('green', 5); })
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 4 })

      Button('Add Info Badges')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor(BADGE_PURPLE)
        .fontColor(Color.White)
        .fontSize(13)
        .onClick((): void => { this.addInfoBadgeMarkers(); })
        .enabled(this.isMapReady)

      Button('Clear All')
        .width('100%')
        .margin({ top: 8 })
        .backgroundColor(CIRCLE_RED)
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
