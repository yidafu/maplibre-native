/**
 * OfflineManagerTestPage - Test offline manager operations.
 *
 * Demonstrates OfflineManager singleton, listing, tile count limits,
 * and overall management of the offline storage system.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { OfflineManager, OfflineRegion, OfflineRegionStatus } from 'maplibre_harmony';
import { common } from '@kit.AbilityKit';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct OfflineManagerTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private regionCount: number = -1;
  @State private totalTiles: number = 0;
  @State private managerInfo: string = '--';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Use controls to manage offline storage.';
  };

  private getManager(): OfflineManager {
    if (!this.offlineManager) {
      const context = getContext() as common.UIAbilityContext;
      this.offlineManager = OfflineManager.getInstance(context);
      this.managerInfo = 'Singleton: ' + (OfflineManager.getInstance(context) === this.offlineManager ? 'Yes' : 'No');
    }
    return this.offlineManager;
  }

  private scanRegions(): void {
    const manager = this.getManager();
    this.statusMessage = 'Scanning offline storage...';
    let tileCount = 0;

    manager.listOfflineRegions().then((regions: OfflineRegion[]) => {
      this.regionCount = regions.length;

      if (regions.length === 0) {
        this.totalTiles = 0;
        this.statusMessage = 'No offline regions found';
        showToast('No regions');
        return;
      }

      // Sum up completed tiles across all regions
      let processed = 0;
      for (const region of regions) {
        region.getStatus((result: OfflineRegionStatus | string) => {
          processed++;
          if (typeof result !== 'string') {
            tileCount += result.completedTileCount ?? 0;
          }
          if (processed >= regions.length) {
            this.totalTiles = tileCount;
            this.statusMessage = regions.length + ' region(s), ' + tileCount + ' total tiles';
            showToast('Scanned ' + regions.length + ' regions');
          }
        });
      }
    }).catch((err: Error) => {
      this.statusMessage = 'Scan error: ' + err.message;
    });
  }

  private setTileLimit(): void {
    // Tile limit is managed internally by OfflineManager
    this.statusMessage = 'Tile limit management is internal to OfflineManager';
    showToast('Tile limit is managed internally');
  }

  private clearAllRegions(): void {
    const manager = this.getManager();
    this.statusMessage = 'Clearing all regions...';

    manager.listOfflineRegions().then((regions: OfflineRegion[]) => {
      if (regions.length === 0) {
        this.statusMessage = 'No regions to clear';
        return;
      }

      let deleted = 0;
      for (const region of regions) {
        region.delete((error?: string) => {
          if (!error) {
            deleted++;
          }
          if (deleted + (error ? 1 : 0) >= regions.length) {
            this.regionCount = 0;
            this.totalTiles = 0;
            this.statusMessage = 'Cleared ' + deleted + ' region(s)';
            showToast('Cleared ' + deleted + ' regions');
          }
        });
      }
    }).catch((err: Error) => {
      this.statusMessage = 'Clear error: ' + err.message;
    });
  }

  private showManagerInfo(): void {
    const manager = this.getManager();
    let info = 'Instance: ' + (manager ? 'Created' : 'Failed') + '\n';
    info += this.managerInfo + '\n';
    info += 'Has regions: ' + (this.regionCount >= 0 ? String(this.regionCount) : 'Unknown') + '\n';
    info += 'Total tiles: ' + this.totalTiles;
    this.statusMessage = 'Manager info:\n' + info;
    showToast('Info displayed');
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

      // Stats display
      if (this.regionCount >= 0) {
        Row() {
          Column() {
            Text(String(this.regionCount))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
            Text('Regions')
              .fontSize(12)
              .fontColor('#666')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(String(this.totalTiles))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
            Text('Tiles')
              .fontSize(12)
              .fontColor('#666')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)
        .margin({ bottom: 12 })
      }

      // Scan / refresh
      Button('Scan Offline Storage')
        .width('100%')
        .onClick(() => this.scanRegions())

      // Set tile limit
      Button('Set Tile Limit')
        .width('100%')
        .margin({ top: 8 })
        .onClick(() => this.setTileLimit())

      // Show info
      Button('Show Manager Info')
        .width('100%')
        .margin({ top: 8 })
        .onClick(() => this.showManagerInfo())

      Divider().height(1).margin({ top: 12, bottom: 8 })

      Button('Clear All Regions')
        .width('100%')
        .backgroundColor('#FF5722')
        .enabled(this.regionCount !== 0)
        .onClick(() => this.clearAllRegions())

      Text('Region count: ' + (this.regionCount >= 0 ? String(this.regionCount) : 'Not scanned'))
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
      title: 'Offline Manager',
      subtitle: 'Manage offline storage',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
