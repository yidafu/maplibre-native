/**
 * VisibilityChangeTestPage - Test visibility lifecycle.
 *
 * Demonstrates map visibility toggling and lifecycle events.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct VisibilityChangeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private isVisible: boolean = true;
  @State private statusMessage: string = 'Ready';
  @State private lifecycleLog: string[] = [];

  private readonly MAX_LOG: number = 15;

  aboutToDisappear() {
    this.addLog('aboutToDisappear');
    this.mapController?.destroy();
    this.mapController = null;
  }

  onPageShow() {
    this.addLog('onPageShow');
    this.statusMessage = 'Page shown';
  }

  onPageHide() {
    this.addLog('onPageHide');
    this.statusMessage = 'Page hidden';
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.addLog('MapLibreMap ready');
    this.statusMessage = 'Map ready';
  };

  private toggleVisibility(): void {
    this.isVisible = !this.isVisible;
    const state = this.isVisible ? 'visible' : 'hidden';
    this.addLog(`Map visibility: ${state}`);
    this.statusMessage = `Map ${state}`;
    showToast(`Map ${state}`);

    if (this.isVisible && this.mapController) {
      // Trigger a repaint when map becomes visible again
      this.mapController.triggerRepaint();
      this.addLog('triggerRepaint after visibility restore');
    }
  }

  private addLog(msg: string): void {
    const t = new Date().toLocaleTimeString();
    this.lifecycleLog = [`[${t}] ${msg}`, ...this.lifecycleLog].slice(0, this.MAX_LOG);
  }

  private simulatePageHide(): void {
    this.onPageHide();
  }

  private simulatePageShow(): void {
    this.onPageShow();
  }

  @Builder
  mapContent() {
    if (this.isVisible) {
      MapView({
        onMapReady: this.onMapReady,
      })
        .width('100%')
        .height('100%')
    } else {
      Column() {
        Text('Map is hidden')
          .fontSize(18)
          .fontColor('#999')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F0F0F0')
    }
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Visibility Controls')
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

      Button(this.isVisible ? 'Hide Map' : 'Show Map')
        .width('100%')
        .height(44)
        .margin({ top: 8 })
        .backgroundColor(this.isVisible ? '#FF5722' : '#4CAF50')
        .enabled(this.isMapReady || !this.isVisible)
        .onClick(() => this.toggleVisibility())

      Row() {
        Button('Simulate onPageHide').layoutWeight(1).height(36).margin({ top: 8 })
          .onClick(() => this.simulatePageHide())
        Button('Simulate onPageShow').layoutWeight(1).height(36).margin({ top: 8, left: 6 })
          .onClick(() => this.simulatePageShow())
      }
      .width('100%')

      Text('Lifecycle Log')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Column() {
        ForEach(this.lifecycleLog, (line: string) => {
          Text(line)
            .fontSize(9)
            .fontFamily('monospace')
            .fontColor('#333')
            .lineHeight(15)
            .width('100%')
        }, (line: string) => line)
      }
      .width('100%')
      .height(160)
      .padding(6)
      .backgroundColor('#F5F5F5')
      .borderRadius(6)

      Button('Clear Log')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => { this.lifecycleLog = []; })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Visibility Change',
      subtitle: 'Test visibility lifecycle',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
