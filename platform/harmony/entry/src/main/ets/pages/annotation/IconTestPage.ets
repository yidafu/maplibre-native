/**
 * IconTestPage - Custom marker icons test.
 *
 * Demonstrates creating markers with different icon types,
 * including default icons and resource-based custom icons.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, Marker, MarkerOptions, LatLng,
  IconFactory, Icon
} from 'maplibre_harmony';
import { showToast, formatLatLng } from '../common/TestUtils';

@Entry
@Component
struct IconTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private markerCount: number = 0;

  private iconFactory: IconFactory | null = null;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add markers with icons';
    console.info('[IconTestPage] Map ready');
  };

  private async initIconFactory(): Promise<void> {
    if (this.iconFactory) return;
    try {
      const context = getContext(this);
      this.iconFactory = IconFactory.getInstance(context.resourceManager);
      this.iconFactory.setPixelRatio(2.0);
    } catch (err) {
      console.error('[IconTestPage] IconFactory init error:', err);
    }
  }

  private async addDefaultMarker(): Promise<void> {
    if (!this.mapController) return;
    await this.initIconFactory();
    const center = this.mapController.getLatLng();
    const lat = center.latitude + (Math.random() - 0.5) * 0.2;
    const lng = center.longitude + (Math.random() - 0.5) * 0.2;

    await this.mapController.addMarker(new MarkerOptions()
      .position(new LatLng(lat, lng))
      .title('Default Icon')
      .snippet(formatLatLng(lat, lng))
    );
    this.markerCount++;
    this.statusMessage = `Added default marker (${this.markerCount})`;
    showToast('Default marker added');
  }

  private async addMarkersWithResourceIcons(): Promise<void> {
    if (!this.mapController) return;
    await this.initIconFactory();

    try {
      const iconResources: Resource[] = [
        $r('app.media.marker_dot_blue'),
        $r('app.media.marker_dot_red'),
        $r('app.media.marker_dot_green'),
        $r('app.media.marker_pin_blue'),
        $r('app.media.marker_pin_red'),
      ];

      const iconNames: string[] = [
        'Blue Dot',
        'Red Dot',
        'Green Dot',
        'Blue Pin',
        'Red Pin',
      ];

      const center = this.mapController.getLatLng();
      if (!this.iconFactory) {
        this.statusMessage = 'IconFactory not initialized';
        return;
      }
      for (let i = 0; i < iconResources.length; i++) {
        try {
          const icon: Icon = await this.iconFactory!.fromResource(iconResources[i]);
          const lat = center.latitude + (Math.random() - 0.5) * 0.4;
          const lng = center.longitude + (Math.random() - 0.5) * 0.4;

          await this.mapController.addMarker(new MarkerOptions()
            .position(new LatLng(lat, lng))
            .title(iconNames[i])
            .snippet(`Icon: ${icon.getId()}`)
            .icon(icon)
          );
          this.markerCount++;
        } catch (err) {
          console.error(`[IconTestPage] Failed to create icon ${iconNames[i]}:`, err);
        }
      }
      this.statusMessage = `Added ${iconResources.length} resource icons`;
      showToast('Resource icons added');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[IconTestPage] Error:', err);
    }
  }

  private clearAll(): void {
    if (!this.mapController) return;
    this.mapController.clear();
    this.markerCount = 0;
    this.statusMessage = 'All markers cleared';
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

      Text('Icon Tests')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add Default Marker')
        .width('100%')
        .margin({ top: 6 })
        .onClick((): void => { this.addDefaultMarker(); })
        .enabled(this.isMapReady)

      Button('Add Resource Icons (5)')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick((): void => { this.addMarkersWithResourceIcons(); })
        .enabled(this.isMapReady)

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
      title: 'Icon Test',
      subtitle: 'Custom marker icons',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
