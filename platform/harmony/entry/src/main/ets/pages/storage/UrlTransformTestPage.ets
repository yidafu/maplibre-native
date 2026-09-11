/**
 * UrlTransformTestPage - Transform tile URLs with ResourceTransform.
 *
 * Demonstrates how to intercept and modify resource URLs at runtime,
 * enabling CDN switching, offline remapping, and auth token injection.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, ResourceTransform, ResourceKind } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';

interface TransformRecord {
  timestamp: string;
  kind: string;
  originalUrl: string;
  transformedUrl: string;
}

@Entry
@Component
struct UrlTransformTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private transformActive: boolean = false;
  @State private transformCount: number = 0;
  @State private records: TransformRecord[] = [];
  @State private currentStrategy: string = '(none)';

  aboutToDisappear() {
    try {
      ResourceTransform.clearCallback();
    } catch (e) {
      console.error('[UrlTransformTestPage] Cleanup error:', e);
    }
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Select a URL transform strategy.';
    console.info('[UrlTransformTestPage] Map ready');
  };

  /**
   * Record a URL transformation for display.
   */
  private record(kind: ResourceKind, original: string, transformed: string): void {
    const kindNames: Record<number, string> = {
      0: 'Unknown', 1: 'Style', 2: 'Source', 3: 'Tile',
      4: 'Glyphs', 5: 'SpriteImage', 6: 'SpriteJSON', 7: 'Image'
    };
    this.records.unshift({
      timestamp: new Date().toLocaleTimeString(),
      kind: kindNames[kind] || `Kind(${kind})`,
      originalUrl: original,
      transformedUrl: transformed
    });
    this.transformCount++;
    if (this.records.length > 30) {
      this.records = this.records.slice(0, 30);
    }
  }

  /**
   * Strategy 1: Log all requests without modifying URLs.
   */
  private startLogging(): void {
    this.clearAll();
    ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
      this.record(kind, url, url);
      return url;
    });
    this.transformActive = true;
    this.currentStrategy = 'Logging (no modification)';
    this.statusMessage = 'Logging mode active. Reload style to capture URLs.';
    showToast('Logging enabled');
  }

  /**
   * Strategy 2: Switch CDN host.
   */
  private startCdnSwitch(): void {
    this.clearAll();
    ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
      let result = url.replace('demotiles.maplibre.org', 'cdn.example.com');
      this.record(kind, url, result);
      return result;
    });
    this.transformActive = true;
    this.currentStrategy = 'CDN switch (demotiles -> cdn.example.com)';
    this.statusMessage = 'CDN switch active. Note: transformed URLs may not load.';
    showToast('CDN switch enabled');
  }

  /**
   * Strategy 3: Add auth token parameter to all Tile requests.
   */
  private startAuthToken(): void {
    this.clearAll();
    ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
      let result = url;
      if (kind === ResourceKind.Tile) {
        const sep = url.includes('?') ? '&' : '?';
        result = `${url}${sep}access_token=test-token`;
      }
      this.record(kind, url, result);
      return result;
    });
    this.transformActive = true;
    this.currentStrategy = 'Auth token for Tile requests';
    this.statusMessage = 'Auth token injector active for tile requests.';
    showToast('Auth token enabled');
  }

  /**
   * Strategy 4: Append query param to all URL requests.
   */
  private startAppendParam(): void {
    this.clearAll();
    ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
      const sep = url.includes('?') ? '&' : '?';
      const result = `${url}${sep}_url_transform=1`;
      this.record(kind, url, result);
      return result;
    });
    this.transformActive = true;
    this.currentStrategy = 'Append ?_url_transform=1';
    this.statusMessage = 'Param appending active.';
    showToast('URL param append enabled');
  }

  /**
   * Stop URL transformation and clear the callback.
   */
  private stopTransform(): void {
    ResourceTransform.clearCallback();
    this.transformActive = false;
    this.currentStrategy = '(none)';
    this.statusMessage = 'Transform stopped.';
    showToast('Transform disabled');
  }

  /**
   * Clear all recorded transforms.
   */
  private clearAll(): void {
    this.records = [];
    this.transformCount = 0;
  }

  /**
   * Check if a transform callback is currently registered.
   */
  private checkStatus(): void {
    const has = ResourceTransform.hasCallback();
    showToast(has ? 'Transform callback IS registered' : 'No transform callback registered');
  }

  /**
   * Reload the map style to trigger new resource requests.
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
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Row() {
        Text('Strategy:')
          .fontSize(12)
          .fontColor('#666')
        Text(this.currentStrategy)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.transformActive ? '#4CAF50' : '#999')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 8 })

      Text(`URLs transformed: ${this.transformCount}`)
        .fontSize(12)
        .fontColor('#2196F3')
        .width('100%')

      Text('Transform Strategies')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('1. Log URLs (no change)')
        .width('100%')
        .fontSize(12)
        .backgroundColor('#2196F3')
        .margin({ bottom: 4 })
        .onClick(() => this.startLogging())
        .enabled(this.isMapReady)

      Button('2. CDN Switch')
        .width('100%')
        .fontSize(12)
        .backgroundColor('#4CAF50')
        .margin({ bottom: 4 })
        .onClick(() => this.startCdnSwitch())
        .enabled(this.isMapReady)

      Button('3. Auth Token (Tile only)')
        .width('100%')
        .fontSize(12)
        .backgroundColor('#FF9800')
        .margin({ bottom: 4 })
        .onClick(() => this.startAuthToken())
        .enabled(this.isMapReady)

      Button('4. Append Query Param')
        .width('100%')
        .fontSize(12)
        .backgroundColor('#9C27B0')
        .margin({ bottom: 4 })
        .onClick(() => this.startAppendParam())
        .enabled(this.isMapReady)

      Divider().margin({ top: 8, bottom: 8 })

      Row() {
        Button('Check Status')
          .width('30%')
          .fontSize(11)
          .onClick(() => this.checkStatus())
          .enabled(this.isMapReady)

        Button('Reload Style')
          .width('30%')
          .fontSize(11)
          .margin({ left: '5%' })
          .onClick(() => this.reloadStyle())
          .enabled(this.isMapReady)

        Button(this.transformActive ? 'Stop' : 'Clear')
          .width('30%')
          .fontSize(11)
          .margin({ left: '5%' })
          .backgroundColor(this.transformActive ? '#E91E63' : '#607D8B')
          .onClick(() => {
            if (this.transformActive) this.stopTransform();
            else this.clearAll();
          })
      }
      .width('100%')

      if (this.records.length > 0) {
        Divider().margin({ top: 8, bottom: 8 })

        Text(`Recent Transformations (${this.records.length})`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: 4 })

        Scroll() {
          Column() {
            ForEach(this.records.slice(0, 10), (record: TransformRecord, index: number) => {
              Column() {
                Row() {
                  Text(record.timestamp)
                    .fontSize(9)
                    .fontColor('#999')
                  Text(record.kind)
                    .fontSize(9)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#2196F3')
                    .margin({ left: 6 })
                    .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                    .backgroundColor('#E3F2FD')
                    .borderRadius(2)
                }

                Text('Original:')
                  .fontSize(9)
                  .fontColor('#666')
                  .margin({ top: 2 })

                Text(record.originalUrl.length > 50 ?
                  record.originalUrl.substring(0, 50) + '...' :
                  record.originalUrl)
                  .fontSize(8)
                  .fontFamily('monospace')
                  .fontColor('#333')

                if (record.originalUrl !== record.transformedUrl) {
                  Text('Transformed:')
                    .fontSize(9)
                    .fontColor('#666')
                    .margin({ top: 2 })

                  Text(record.transformedUrl.length > 50 ?
                    record.transformedUrl.substring(0, 50) + '...' :
                    record.transformedUrl)
                    .fontSize(8)
                    .fontFamily('monospace')
                    .fontColor('#4CAF50')
                }
              }
              .width('100%')
              .padding(6)
              .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F5F5F5')
              .borderRadius(4)
              .margin({ bottom: 3 })
            }, (record: TransformRecord, index: number) => `${index}`)
          }
        }
        .constraintSize({ maxHeight: 160 })
        .backgroundColor('#FAFAFA')
        .borderRadius(4)
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'URL Transform',
      subtitle: 'Transform tile URLs',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
