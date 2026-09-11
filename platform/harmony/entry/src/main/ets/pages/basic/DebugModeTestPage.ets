/**
 * DebugModeTestPage - Toggle debug visualizations.
 *
 * Reference: Android DebugModeActivity, iOS MBXSettingsDebugTools
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapDebugOptions } from 'maplibre_harmony';

@Entry
@Component
struct DebugModeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private activeOptions: string[] = [];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    console.info('[DebugModeTestPage] Map ready');
  };

  private toggleDebug(option: string): void {
    if (!this.mapController) return;
    const idx = this.activeOptions.indexOf(option);
    if (idx >= 0) {
      this.activeOptions.splice(idx, 1);
    } else {
      this.activeOptions.push(option);
    }
    this.activeOptions = [...this.activeOptions];
    this.applyDebugOptions();
  }

  private applyDebugOptions(): void {
    if (!this.mapController) return;
    let options = MapDebugOptions.NoDebug;
    for (const opt of this.activeOptions) {
      switch (opt) {
        case 'TileBoundaries':
          options |= MapDebugOptions.TileBoundaries;
          break;
        case 'CollisionBoxes':
          options |= MapDebugOptions.CollisionBoxes;
          break;
        case 'Timestamps':
          options |= MapDebugOptions.Timestamps;
          break;
        case 'Overdraw':
          options |= MapDebugOptions.OverdrawVisualization;
          break;
      }
    }
    this.mapController.setDebugOptions(options);
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
      Text('Debug Options')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      this.buildToggle('Tile Boundaries', 'TileBoundaries')
      this.buildToggle('Collision Boxes', 'CollisionBoxes')
      this.buildToggle('Timestamps', 'Timestamps')
      this.buildToggle('Overdraw', 'Overdraw')

      Button('Clear All')
        .width('100%')
        .margin({ top: 12 })
        .onClick((): void => {
          this.activeOptions = [];
          this.applyDebugOptions();
        })
        .enabled(this.isMapReady && this.activeOptions.length > 0)
    }
    .width('100%')
  }

  @Builder
  buildToggle(label: string, option: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .layoutWeight(1)
      Toggle({ type: ToggleType.Checkbox, isOn: this.activeOptions.includes(option) })
        .onChange((): void => {
          this.toggleDebug(option);
        })
        .enabled(this.isMapReady)
    }
    .width('100%')
    .height(44)
    .padding({ left: 8, right: 8 })
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Debug Mode',
      subtitle: 'Toggle debug visualizations',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
