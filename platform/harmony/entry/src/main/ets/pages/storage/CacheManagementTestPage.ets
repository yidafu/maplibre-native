/**
 * CacheManagementTestPage - Manage tile cache.
 *
 * Demonstrates cache management operations: reset database,
 * invalidate ambient cache, clear ambient cache, and set
 * maximum ambient cache size.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, OfflineManager } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct CacheManagementTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Initializing...';
  @State private isProcessing: boolean = false;

  aboutToAppear() {
    try {
      this.offlineManager = OfflineManager.getInstance(this.context);
      this.statusMessage = 'OfflineManager ready';
    } catch (error) {
      this.statusMessage = `Init error: ${error instanceof Error ? error.message : String(error)}`;
      console.error('[CacheManagementTestPage] Init error:', error);
    }
  }

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Use buttons to manage cache.';
    console.info('[CacheManagementTestPage] Map ready');
  };

  /**
   * Reset the entire database, removing all offline regions and cache data.
   */
  private resetDatabase = async (): Promise<void> => {
    if (!this.offlineManager || this.isProcessing) return;
    this.isProcessing = true;
    this.statusMessage = 'Resetting database...';

    try {
      await this.offlineManager.resetDatabase();
      this.statusMessage = 'Database reset successful';
      showToast('Database reset');
    } catch (error) {
      this.statusMessage = `Reset failed: ${error instanceof Error ? error.message : String(error)}`;
      showToast('Reset failed');
    } finally {
      this.isProcessing = false;
    }
  };

  /**
   * Invalidate the ambient cache, forcing tiles to be re-downloaded.
   */
  private invalidateAmbientCache = async (): Promise<void> => {
    if (!this.offlineManager || this.isProcessing) return;
    this.isProcessing = true;
    this.statusMessage = 'Invalidating ambient cache...';

    try {
      await this.offlineManager.invalidateAmbientCache();
      this.statusMessage = 'Ambient cache invalidated';
      showToast('Cache invalidated');
    } catch (error) {
      this.statusMessage = `Invalidation failed: ${error instanceof Error ? error.message : String(error)}`;
    } finally {
      this.isProcessing = false;
    }
  };

  /**
   * Clear the ambient cache, removing all cached tiles.
   */
  private clearAmbientCache = async (): Promise<void> => {
    if (!this.offlineManager || this.isProcessing) return;
    this.isProcessing = true;
    this.statusMessage = 'Clearing ambient cache...';

    try {
      await this.offlineManager.clearAmbientCache();
      this.statusMessage = 'Ambient cache cleared';
      showToast('Cache cleared');
    } catch (error) {
      this.statusMessage = `Clear failed: ${error instanceof Error ? error.message : String(error)}`;
    } finally {
      this.isProcessing = false;
    }
  };

  /**
   * Set the maximum ambient cache size to 5 MB.
   */
  private setMaximumAmbientCacheSize = (): void => {
    if (!this.offlineManager || this.isProcessing) return;
    this.isProcessing = true;
    this.statusMessage = 'Setting maximum cache size...';

    try {
      const maxSize = 5 * 1024 * 1024; // 5 MB
      this.offlineManager.setMaximumAmbientCacheSize(maxSize);
      this.statusMessage = `Max cache size set to 5 MB`;
      showToast('Cache size set to 5 MB');
    } catch (error) {
      this.statusMessage = `Set size failed: ${error instanceof Error ? error.message : String(error)}`;
    } finally {
      this.isProcessing = false;
    }
  };

  /**
   * Reload the map style to observe cache effects.
   */
  private reloadStyle(): void {
    if (!this.mapController) return;
    const url = this.mapController.getStyleUrl();
    this.mapController.setStyleUrl(url);
    this.statusMessage = 'Reloading style...';
    showToast('Style reloaded');
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
        .fontColor(this.isMapReady ? (this.isProcessing ? '#FF9800' : '#4CAF50') : '#FF9800')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Cache Operations')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Reset Database')
        .width('100%')
        .backgroundColor('#FF6B6B')
        .margin({ bottom: 6 })
        .onClick(() => this.resetDatabase())
        .enabled(!this.isProcessing)

      Button('Invalidate Ambient Cache')
        .width('100%')
        .backgroundColor('#FFA500')
        .margin({ bottom: 6 })
        .onClick(() => this.invalidateAmbientCache())
        .enabled(!this.isProcessing)

      Button('Clear Ambient Cache')
        .width('100%')
        .backgroundColor('#4CAF50')
        .margin({ bottom: 6 })
        .onClick(() => this.clearAmbientCache())
        .enabled(!this.isProcessing)

      Button('Set Max Cache (5 MB)')
        .width('100%')
        .backgroundColor('#2196F3')
        .margin({ bottom: 6 })
        .onClick(() => this.setMaximumAmbientCacheSize())
        .enabled(!this.isProcessing)

      Button('Reload Map Style')
        .width('100%')
        .backgroundColor('#607D8B')
        .onClick(() => this.reloadStyle())
        .enabled(this.isMapReady)

      Text('Warning: Reset Database deletes all offline data.')
        .fontSize(12)
        .fontColor('#FF6B6B')
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Cache Management',
      subtitle: 'Manage tile cache',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
