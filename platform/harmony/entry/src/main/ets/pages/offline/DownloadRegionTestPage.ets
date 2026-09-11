/**
 * DownloadRegionTestPage - Test downloading an offline region.
 *
 * Demonstrates creating and downloading an offline map region using
 * the OfflineManager and OfflineRegion APIs.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import {
  OfflineManager,
  OfflineRegion,
  createTilePyramidRegionDefinition,
  DownloadState,
  OfflineRegionObserver,
  OfflineRegionStatus,
  OfflineRegionError
} from 'maplibre_harmony';
import { LatLngBounds, LatLng } from 'maplibre_harmony';
import { common } from '@kit.AbilityKit';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct DownloadRegionTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  private currentRegion: OfflineRegion | null = null;
  @State private isMapReady: boolean = false;
  @State private isDownloading: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private progress: string = '--';
  @State private completedTileCount: number = 0;
  @State private requiredTileCount: number = 0;
  @State private downloadState: string = 'Idle';

  aboutToDisappear() {
    // Pause any active download
    if (this.currentRegion) {
      try {
        this.currentRegion.setDownloadState(DownloadState.INACTIVE);
      } catch (_e) {}
    }
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private getOfflineManager(): OfflineManager {
    if (!this.offlineManager) {
      // Use the global application context
      const context = getContext() as common.UIAbilityContext;
      this.offlineManager = OfflineManager.getInstance(context);
    }
    return this.offlineManager;
  }

  private startDownload(): void {
    if (!this.mapController) {
      showToast('Map not ready');
      return;
    }

    const styleUrl = this.mapController.getStyleUrl();
    if (!styleUrl) {
      showToast('Style URL not available');
      return;
    }

    // Create bounds around current map center (approximately 0.5 degrees)
    const center = this.mapController.getLatLng();
    const sw = new LatLng(center.latitude - 0.25, center.longitude - 0.25);
    const ne = new LatLng(center.latitude + 0.25, center.longitude + 0.25);
    const bounds = new LatLngBounds(sw, ne);

    const definition = createTilePyramidRegionDefinition(
      styleUrl,
      bounds,
      0,   // minZoom
      12,  // maxZoom
      1.0, // pixelRatio
      true // includeIdeographs
    );

    // Create with empty metadata for simplicity
    const metadata = new ArrayBuffer(0);

    this.statusMessage = 'Creating offline region...';
    showToast('Creating region...');

    const manager = this.getOfflineManager();
    manager.createOfflineRegion(definition, metadata).then((region: OfflineRegion) => {
      this.currentRegion = region;
      this.statusMessage = 'Region created (id=' + region.id + '), starting download';
      this.downloadState = 'Created';

      // Set up observer
      const observer: OfflineRegionObserver = {
        onStatusChanged: (status: OfflineRegionStatus) => {
          this.completedTileCount = status.completedTileCount ?? 0;
          this.requiredTileCount = status.requiredTileCount ?? 0;
          if (status.requiredTileCount && status.requiredTileCount > 0) {
            const pct = ((status.completedTileCount ?? 0) / status.requiredTileCount * 100).toFixed(1);
            this.progress = pct + '%';
          }
          this.downloadState = status.complete ? 'Complete' : ((status.downloadState === 1) ? 'Downloading' : 'Paused');

          if (status.complete) {
            this.isDownloading = false;
            this.statusMessage = 'Download complete! ' + status.completedTileCount + ' tiles';
            showToast('Download complete');
          } else {
            this.statusMessage = 'Downloading: ' + this.progress;
          }
        },
        onError: (error: OfflineRegionError) => {
          this.isDownloading = false;
          this.statusMessage = 'Download error: ' + error.message;
          showToast('Error: ' + error.message);
        },
        mapboxTileCountLimitExceeded: (_limit: number) => {
          console.warn('[DownloadRegionTestPage] Tile count limit exceeded:', _limit);
        },
      };
      region.setObserver(observer);

      // Start downloading
      region.setDownloadState(DownloadState.ACTIVE);
      this.isDownloading = true;
      this.downloadState = 'Downloading';
      this.statusMessage = 'Download started';
      showToast('Download started');
    }).catch((err: Error) => {
      this.statusMessage = 'Create region failed: ' + err.message;
      showToast('Error: ' + err.message);
    });
  }

  private pauseDownload(): void {
    if (this.currentRegion) {
      this.currentRegion.setDownloadState(DownloadState.INACTIVE);
      this.isDownloading = false;
      this.downloadState = 'Paused';
      this.statusMessage = 'Download paused';
      showToast('Download paused');
    }
  }

  private resumeDownload(): void {
    if (this.currentRegion) {
      this.currentRegion.setDownloadState(DownloadState.ACTIVE);
      this.isDownloading = true;
      this.downloadState = 'Downloading';
      this.statusMessage = 'Download resumed';
      showToast('Download resumed');
    }
  }

  private queryStatus(): void {
    if (!this.currentRegion) {
      showToast('No region');
      return;
    }
    this.currentRegion.getStatus((result: OfflineRegionStatus | string) => {
      if (typeof result === 'string') {
        this.statusMessage = 'Status error: ' + result;
      } else {
        const status = result as OfflineRegionStatus;
        this.completedTileCount = status.completedTileCount ?? 0;
        this.requiredTileCount = status.requiredTileCount ?? 0;
        this.downloadState = status.complete ? 'Complete' : ((status.downloadState === 1) ? 'Downloading' : 'Paused');
        this.statusMessage = 'Status: ' + this.downloadState + ', tiles: ' +
          this.completedTileCount + '/' + this.requiredTileCount;
      }
    });
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

      Text('State: ' + this.downloadState)
        .fontSize(13)
        .fontColor('#333')
        .width('100%')

      Text('Tiles: ' + this.completedTileCount + ' / ' + this.requiredTileCount)
        .fontSize(13)
        .fontColor('#666')
        .width('100%')
        .margin({ bottom: 8 })

      if (!this.currentRegion) {
        Button('Start Download (Current View)')
          .width('100%')
          .enabled(this.isMapReady)
          .onClick(() => this.startDownload())
      } else {
        // Download controls
        if (this.isDownloading) {
          Button('Pause Download')
            .width('100%')
            .backgroundColor('#FF9800')
            .onClick(() => this.pauseDownload())
        } else {
          Button('Resume Download')
            .width('100%')
            .backgroundColor('#4CAF50')
            .onClick(() => this.resumeDownload())
        }

        Button('Query Status')
          .width('100%')
          .margin({ top: 8 })
          .onClick(() => this.queryStatus())
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Download Region',
      subtitle: 'Download offline map region',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
