/**
 * DeleteRegionTestPage - Test deleting offline regions.
 *
 * Demonstrates listing all offline regions and deleting selected ones.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { OfflineManager, OfflineRegion } from 'maplibre_harmony';
import { common } from '@kit.AbilityKit';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct DeleteRegionTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  @State private isMapReady: boolean = false;
  @State private regions: OfflineRegion[] = [];
  @State private statusMessage: string = 'Loading...';
  @State private isListLoaded: boolean = false;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private getManager(): OfflineManager {
    if (!this.offlineManager) {
      const context = getContext();
      this.offlineManager = OfflineManager.getInstance(context as common.UIAbilityContext);
    }
    return this.offlineManager;
  }

  private listRegions(): void {
    const manager = this.getManager();
    this.statusMessage = 'Listing regions...';
    manager.listOfflineRegions().then((regions: OfflineRegion[]) => {
      this.regions = regions;
      this.isListLoaded = true;
      this.statusMessage = 'Found ' + regions.length + ' region(s)';
      if (regions.length === 0) {
        showToast('No offline regions found');
      }
    }).catch((err: Error) => {
      this.statusMessage = 'List error: ' + err.message;
      showToast('Error: ' + err.message);
    });
  }

  private deleteRegion(region: OfflineRegion, index: number): void {
    // Confirm deletion
    const regionId = region.id;
    this.statusMessage = 'Deleting region ' + regionId + '...';

    region.delete((error?: string) => {
      if (error) {
        this.statusMessage = 'Delete failed: ' + error;
        showToast('Delete failed: ' + error);
      } else {
        // Remove from list
        this.regions.splice(index, 1);
        this.regions = this.regions.slice(); // Trigger re-render
        this.statusMessage = 'Region ' + regionId + ' deleted';
        showToast('Region ' + regionId + ' deleted');
      }
    });
  }

  private deleteAllRegions(): void {
    if (this.regions.length === 0) {
      showToast('No regions to delete');
      return;
    }

    this.statusMessage = 'Deleting all ' + this.regions.length + ' regions...';
    let completed = 0;
    let failed = 0;
    const total = this.regions.length;

    for (let i = this.regions.length - 1; i >= 0; i--) {
      const region = this.regions[i];
      region.delete((error?: string) => {
        if (error) {
          failed++;
        } else {
          completed++;
        }
        if (completed + failed >= total) {
          this.listRegions();
          this.statusMessage = 'Deleted ' + completed + '/' + total + ' regions';
          showToast('Deleted ' + completed + ' regions');
        }
      });
    }
  }

  private deleteRegionById(): void {
    // Delete first region for demo simplicity
    if (this.regions.length > 0) {
      this.deleteRegion(this.regions[0], 0);
    } else {
      showToast('No regions to delete');
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

      Row() {
        Button('List Regions')
          .width('48%')
          .onClick(() => this.listRegions())

        Button('Delete All')
          .width('48%')
          .margin({ left: '4%' })
          .backgroundColor('#FF5722')
          .enabled(this.regions.length > 0)
          .onClick(() => this.deleteAllRegions())
      }
      .width('100%')

      if (this.regions.length > 0) {
        Divider().height(1).margin({ top: 12, bottom: 8 })
        Text('Regions (' + this.regions.length + ')')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        ForEach(this.regions, (region: OfflineRegion, index: number) => {
          Row() {
            Column() {
              Text('ID: ' + region.id)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
              Text('Metadata: ' + (region.metadata.byteLength > 0 ? region.metadata.byteLength + ' bytes' : 'empty'))
                .fontSize(11)
                .fontColor('#666')
            }
            .layoutWeight(1)

            Button('Delete')
              .fontSize(12)
              .backgroundColor('#FF5722')
              .height(32)
              .onClick(() => this.deleteRegion(region, index))
          }
          .width('100%')
          .padding(8)
          .backgroundColor('#FAFAFA')
          .borderRadius(4)
          .margin({ top: 4 })
        }, (region: OfflineRegion) => String(region.id))
      } else if (this.isListLoaded) {
        Text('No offline regions available')
          .fontSize(13)
          .fontColor('#999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 16 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Delete Region',
      subtitle: 'Delete offline map regions',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
