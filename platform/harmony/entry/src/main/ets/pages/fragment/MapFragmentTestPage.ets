/**
 * MapFragmentTestPage - Display a map inside a fragment-like container.
 *
 * Demonstrates embedding a MapView in a scrollable card layout that simulates
 * fragment-style navigation with show/hide toggles.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MarkerOptions, LatLng } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, TEST_LOCATIONS, showToast } from '../common/TestUtils';

@Entry
@Component
struct MapFragmentTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private fragmentVisible: boolean = true;
  @State private fragmentExpanded: boolean = false;
  @State private markerCount: number = 0;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    showToast('Map fragment ready');
  };

  private toggleVisibility(): void {
    this.fragmentVisible = !this.fragmentVisible;
    showToast('Fragment visibility: ' + (this.fragmentVisible ? 'visible' : 'hidden'));
  }

  private toggleSize(): void {
    this.fragmentExpanded = !this.fragmentExpanded;
    showToast('Fragment expanded: ' + this.fragmentExpanded);
  }

  private addMarker(): void {
    if (!this.mapController) return;
    // Add a marker at a random location near Hangzhou
    const offsetLat = (Math.random() - 0.5) * 0.1;
    const offsetLng = (Math.random() - 0.5) * 0.1;
    const pos = new LatLng(
      DEFAULT_MAP_CONFIG.latitude + offsetLat,
      DEFAULT_MAP_CONFIG.longitude + offsetLng
    );
    const options = new MarkerOptions()
      .position(pos)
      .title('Marker #' + (this.markerCount + 1))
      .snippet('Added at fragment test');
    this.mapController.addMarker(options).then((marker) => {
      this.markerCount++;
      showToast('Added marker #' + this.markerCount);
    }).catch((err: Error) => {
      showToast('Failed to add marker: ' + err.message);
    });
  }

  @Builder
  mapContent() {
    Stack() {
      if (this.fragmentVisible) {
        Column() {
          // Fragment header bar
          Row() {
            Text('Map Fragment')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .layoutWeight(1)
              .margin({ left: 12 })
            Button(this.fragmentExpanded ? 'Collapse' : 'Expand')
              .fontSize(12)
              .height(28)
              .backgroundColor(Color.Transparent)
              .fontColor(Color.White)
              .onClick(() => this.toggleSize())
            Button('Hide')
              .fontSize(12)
              .height(28)
              .backgroundColor(Color.Transparent)
              .fontColor(Color.White)
              .onClick(() => this.toggleVisibility())
          }
          .width('100%')
          .height(36)
          .backgroundColor('#FF5722')
          .padding({ right: 8 })

          // Map content area
          if (this.fragmentExpanded) {
            MapView({
              onMapReady: this.onMapReady,
            })
              .width('100%')
              .height('100%')
          } else {
            MapView({
              onMapReady: this.onMapReady,
            })
              .width('100%')
              .height('100%')
          }
        }
        .width('100%')
        .height(this.fragmentExpanded ? '100%' : '60%')
        .borderRadius(8)
        .clip(true)
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 4 })
      } else {
        // Placeholder shown when fragment is hidden
        Column() {
          Text('Fragment is hidden')
            .fontSize(16)
            .fontColor('#999')
          Button('Show Fragment')
            .fontSize(14)
            .margin({ top: 12 })
            .onClick(() => this.toggleVisibility())
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F0F0F0')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Fragment Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text('Demonstrates map inside a fragment-like container with show/hide and expand/collapse.')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ bottom: 12 })

      Row() {
        Button('Toggle Visibility')
          .width('48%')
          .onClick(() => this.toggleVisibility())
        Button('Toggle Expand')
          .width('48%')
          .margin({ left: 8 })
          .onClick(() => this.toggleSize())
          .enabled(this.fragmentVisible)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Button('Add Marker')
        .width('100%')
        .onClick(() => this.addMarker())
        .enabled(this.isMapReady)

      Text('Markers added: ' + this.markerCount)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 8 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Map Fragment',
      subtitle: 'Fragment container with show/hide/expand',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
