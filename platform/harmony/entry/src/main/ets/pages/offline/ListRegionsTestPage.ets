/**
 * ListRegionsTestPage - Test listing offline regions.
 *
 * Demonstrates querying all offline regions and displaying their details.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import {
  OfflineManager,
  OfflineRegion,
  OfflineRegionStatus
} from 'maplibre_harmony';
import { common } from '@kit.AbilityKit';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct ListRegionsTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  @State private isMapReady: boolean = false;
  @State private regions: OfflineRegion[] = [];
  @State private expandedRegionId: number = -1;
  @State private statusMessage: string = 'Loading...';
  @State private isRefreshing: boolean = false;
  @State private regionStatuses: Map<number, string> = new Map();

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Tap Refresh to list regions.';
  };

  private getManager(): OfflineManager {
    if (!this.offlineManager) {
      const context = getContext() as common.UIAbilityContext;
      this.offlineManager = OfflineManager.getInstance(context);
    }
    return this.offlineManager;
  }

  private refreshList(): void {
    this.isRefreshing = true;
    this.statusMessage = 'Loading regions...';

    const manager = this.getManager();
    manager.listOfflineRegions().then((regions: OfflineRegion[]) => {
      this.regions = regions;
      this.isRefreshing = false;
      this.statusMessage = regions.length + ' region(s) found';

      // Fetch status for each region
      this.refreshAllStatuses();

      showToast('Listed ' + regions.length + ' regions');
    }).catch((err: Error) => {
      this.isRefreshing = false;
      this.statusMessage = 'Error: ' + err.message;
      showToast('Error: ' + err.message);
    });
  }

  private refreshAllStatuses(): void {
    for (const region of this.regions) {
      this.fetchRegionStatus(region);
    }
  }

  private fetchRegionStatus(region: OfflineRegion): void {
    region.getStatus((result: OfflineRegionStatus | string) => {
      if (typeof result === 'string') {
        this.regionStatuses.set(region.id, 'Error: ' + result);
      } else {
        const info = 'Complete: ' + (result.complete ? 'Yes' : 'No') +
          ' | Downloading: ' + (result.downloadState === 1 ? 'Yes' : 'No') +
          ' | Tiles: ' + (result.completedTileCount ?? 0) + '/' + (result.requiredTileCount ?? 0);
        this.regionStatuses.set(region.id, info);
      }
      // Trigger re-render by reassigning
      this.regionStatuses = new Map(this.regionStatuses);
    });
  }

  private getStatusForRegion(region: OfflineRegion): string {
    return this.regionStatuses.get(region.id) || 'Fetching...';
  }

  private formatMetadata(metadata: ArrayBuffer): string {
    if (!metadata || metadata.byteLength === 0) {
      return '(empty)';
    }
    try {
      // Try to decode as text
      const uint8 = new Uint8Array(metadata);
      let text = '';
      for (let i = 0; i < uint8.length; i++) {
        text += String.fromCharCode(uint8[i]);
      }
      return text.substring(0, 50) + (text.length > 50 ? '...' : '');
    } catch (_e) {
      return metadata.byteLength + ' bytes';
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
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)
        .margin({ bottom: 8 })

      Button('Refresh List')
        .width('100%')
        .enabled(!this.isRefreshing)
        .onClick(() => this.refreshList())

      if (this.regions.length > 0) {
        Text('Total: ' + this.regions.length + ' offline region(s)')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12, bottom: 4 })

        ForEach(this.regions, (region: OfflineRegion, index: number) => {
          Column() {
            Row() {
              Text('#' + region.id)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2196F3')

              Blank()

              Text(this.expandedRegionId === region.id ? 'Collapse' : 'Details')
                .fontSize(12)
                .fontColor('#2196F3')
                .onClick(() => {
                  this.expandedRegionId = this.expandedRegionId === region.id ? -1 : region.id;
                  if (this.expandedRegionId === region.id) {
                    this.fetchRegionStatus(region);
                  }
                })
            }
            .width('100%')

            // Always show basic info
            Row() {
              Text('Metadata: ')
                .fontSize(12)
                .fontColor('#666')
              Text(this.formatMetadata(region.metadata))
                .fontSize(12)
                .fontColor('#333')
            }
            .width('100%')
            .margin({ top: 2 })

            Text('Status: ' + this.getStatusForRegion(region))
              .fontSize(12)
              .fontColor('#666')
              .width('100%')
              .margin({ top: 2 })

            // Extra details when expanded
            if (this.expandedRegionId === region.id) {
              Divider().height(1).margin({ top: 6, bottom: 6 })

              Text('Definition type: ' + (region.definition as Object as Record<string, Object>)['type'] || 'unknown')
                .fontSize(11)
                .fontColor('#999')

              Text('Style URL: ' + (region.definition as Object as Record<string, Object>)['styleURL'] || 'unknown')
                .fontSize(11)
                .fontColor('#999')
                .margin({ top: 2 })

              // Refresh status
              Button('Refresh Status')
                .fontSize(12)
                .height(28)
                .width('100%')
                .margin({ top: 6 })
                .onClick(() => this.fetchRegionStatus(region))
            }
          }
          .width('100%')
          .padding(10)
          .backgroundColor(index % 2 === 0 ? '#FAFAFA' : '#FFFFFF')
          .borderRadius(6)
          .margin({ top: 6 })
        }, (region: OfflineRegion) => String(region.id))
      } else if (!this.isRefreshing) {
        Text('No offline regions. Use Download Region test page to create one.')
          .fontSize(13)
          .fontColor('#999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 24 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'List Regions',
      subtitle: 'List offline map regions',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
