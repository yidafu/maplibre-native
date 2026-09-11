/**
 * OverlayMapTestPage - Overlay views on the map.
 *
 * Demonstrates placing ArkUI components (labels, buttons) over the
 * map surface using a Stack layout.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct OverlayMapTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready';
  @State private showLabels: boolean = true;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Overlay buttons shown on top.';
  };

  @Builder
  mapContent() {
    Stack() {
      MapView({
        onMapReady: this.onMapReady,
      })
        .width('100%')
        .height('100%')

      // Top-left corner overlay
      Column() {
        Text('Map Overlay')
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor('rgba(33, 150, 243, 0.8)')
      .borderRadius(16)
      .position({ x: 12, y: 12 })

      // Center crosshair
      if (this.showLabels) {
        Column() {
          Circle({ width: 6, height: 6 })
            .fill('#FF5722')
            .strokeWidth(2)
            .stroke(Color.White)
        }
        .width(24)
        .height(24)
        .position({ x: '50%', y: '50%' })
        .offset({ x: -12, y: -12 })
        .zIndex(10)

        // Top-center label
        Column() {
          Text('PINNED LOCATION')
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('rgba(0,0,0,0.6)')
        .borderRadius(4)
        .position({ x: '50%', y: '40%' })
        .offset({ x: -50 })
        .zIndex(10)
      }

      // Bottom-right overlay buttons
      Column() {
        Button({ type: ButtonType.Circle }) {
          Text('+').fontSize(22).fontColor(Color.White)
        }
        .width(44)
        .height(44)
        .backgroundColor('rgba(33, 150, 243, 0.85)')
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.3)' })
        .onClick(() => {
          if (!this.mapController) return;
          const z = this.mapController.getZoom();
          this.mapController.setZoom(z + 1);
          showToast('Zoom in');
        })

        Button({ type: ButtonType.Circle }) {
          Text('-').fontSize(22).fontColor(Color.White)
        }
        .width(44)
        .height(44)
        .backgroundColor('rgba(33, 150, 243, 0.85)')
        .margin({ top: 8 })
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.3)' })
        .onClick(() => {
          if (!this.mapController) return;
          const z = this.mapController.getZoom();
          this.mapController?.setZoom(z - 1);
          showToast('Zoom out');
        })
      }
      .position({ x: '90%', y: '50%' })
      .offset({ x: -22 })
      .zIndex(10)

      // Bottom info bar
      Column() {
        Text('Beijing, China | Zoom: ~10 | Drag to explore')
          .fontSize(10)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding(8)
      .backgroundColor('rgba(0,0,0,0.5)')
      .position({ y: '90%' })
      .zIndex(10)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Overlay Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text(this.statusMessage)
        .fontSize(12)
        .fontColor('#333')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Overlay Toggles')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Toggle Crosshair')
          .height(36)
          .layoutWeight(1)
          .onClick(() => {
            this.showLabels = !this.showLabels;
            this.statusMessage = this.showLabels ? 'Crosshair visible' : 'Crosshair hidden';
          })
        Button('Test Tap Through')
          .height(36)
          .layoutWeight(1)
          .margin({ left: 6 })
          .onClick(() => {
            showToast('Button clicked (overlay handles tap)');
          })
      }
      .width('100%')

      Text('Note')
        .fontSize(11)
        .fontColor('#999')
        .width('100%')
        .margin({ top: 10 })
      Text('Overlay views are positioned on top of the map using a Stack. The +/- buttons in the bottom-right control zoom.')
        .fontSize(10)
        .fontColor('#999')
        .lineHeight(15)
        .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Overlay Map',
      subtitle: 'Overlay views on the map',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
