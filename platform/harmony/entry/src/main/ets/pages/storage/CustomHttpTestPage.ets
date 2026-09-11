/**
 * CustomHttpTestPage - Custom HTTP headers for map resource requests.
 *
 * Demonstrates setting, updating, and clearing custom HTTP headers
 * using NetworkConfiguration.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, NetworkConfiguration } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';
import type { HttpHeaders } from 'maplibre_harmony';

@Entry
@Component
struct CustomHttpTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private headersActive: boolean = false;
  @State private currentHeaders: string = '(none)';

  aboutToDisappear() {
    // Clear custom headers on exit
    try {
      NetworkConfiguration.clearCustomHttpHeaders();
    } catch (e) {
      console.error('[CustomHttpTestPage] Cleanup error:', e);
    }
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Configure custom HTTP headers.';
    console.info('[CustomHttpTestPage] Map ready');
  };

  /**
   * Set a simple custom header for authentication.
   */
  private setAuthHeader(): void {
    try {
      NetworkConfiguration.setCustomHttpHeaders({
        'Authorization': 'Bearer test-token-12345',
        'X-Client-Id': 'maplibre-harmony-test'
      });
      this.headersActive = true;
      this.currentHeaders = 'Authorization: Bearer test-token-12345\nX-Client-Id: maplibre-harmony-test';
      this.statusMessage = 'Custom auth headers set';
      showToast('Auth headers set');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Set custom headers for API versioning.
   */
  private setApiVersionHeader(): void {
    try {
      NetworkConfiguration.setCustomHttpHeaders({
        'Accept': 'application/vnd.maplibre.v2+json',
        'X-API-Version': '2.0'
      });
      this.headersActive = true;
      this.currentHeaders = 'Accept: application/vnd.maplibre.v2+json\nX-API-Version: 2.0';
      this.statusMessage = 'API version headers set';
      showToast('API version headers set');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Add a single custom header to the existing set.
   */
  private addSingleHeader(): void {
    try {
      NetworkConfiguration.addCustomHttpHeader('X-Trace-Id', `trace-${Date.now()}`);
      this.statusMessage = 'Single header added: X-Trace-Id';
      this.refreshHeaders();
      showToast('Header added');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Refresh the displayed headers by reading the current configuration.
   */
  private refreshHeaders(): void {
    try {
      const headers: HttpHeaders = NetworkConfiguration.getCustomHttpHeaders();
      const keys = Object.keys(headers);
      if (keys.length === 0) {
        this.currentHeaders = '(none)';
        this.headersActive = false;
      } else {
        this.currentHeaders = keys.map(k => `${k}: ${headers[k]}`).join('\n');
        this.headersActive = true;
      }
    } catch (error) {
      this.currentHeaders = `(error reading: ${error})`;
    }
  }

  /**
   * Clear all custom HTTP headers.
   */
  private clearHeaders(): void {
    try {
      NetworkConfiguration.clearCustomHttpHeaders();
      this.headersActive = false;
      this.currentHeaders = '(none)';
      this.statusMessage = 'All custom headers cleared';
      showToast('Headers cleared');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Reload the map style to trigger new requests with current headers.
   */
  private reloadStyle(): void {
    if (!this.mapController) return;
    const currentUrl = this.mapController.getStyleUrl();
    // Re-set the same URL to trigger a reload
    this.mapController.setStyleUrl(currentUrl);
    this.statusMessage = 'Reloading style with current headers...';
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

      Text('HTTP Header Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Text('Custom HTTP headers are sent with every map resource request (tiles, styles, glyphs, sprites).')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .lineHeight(18)
        .margin({ bottom: 12 })

      Button('Set Auth Headers')
        .width('100%')
        .backgroundColor('#2196F3')
        .margin({ bottom: 6 })
        .onClick(() => this.setAuthHeader())
        .enabled(this.isMapReady)

      Button('Set API Version Headers')
        .width('100%')
        .backgroundColor('#4CAF50')
        .margin({ bottom: 6 })
        .onClick(() => this.setApiVersionHeader())
        .enabled(this.isMapReady)

      Button('Add Single Header (X-Trace-Id)')
        .width('100%')
        .backgroundColor('#FF9800')
        .margin({ bottom: 6 })
        .onClick(() => this.addSingleHeader())
        .enabled(this.isMapReady)

      Row() {
        Button('Refresh Headers')
          .width('48%')
          .margin({ right: '4%' })
          .onClick(() => this.refreshHeaders())
          .enabled(this.isMapReady)

        Button('Clear Headers')
          .width('48%')
          .backgroundColor('#E91E63')
          .onClick(() => this.clearHeaders())
          .enabled(this.isMapReady && this.headersActive)
      }
      .width('100%')

      Button('Reload Style (apply headers)')
        .width('100%')
        .backgroundColor('#607D8B')
        .margin({ top: 8 })
        .onClick(() => this.reloadStyle())
        .enabled(this.isMapReady)

      Divider()
        .margin({ top: 12, bottom: 8 })

      Text('Current HTTP Headers')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 4 })

      Text(`Status: ${this.headersActive ? 'Active' : 'Inactive'}`)
        .fontSize(12)
        .fontColor(this.headersActive ? '#4CAF50' : '#999')
        .width('100%')
        .margin({ bottom: 4 })

      Scroll() {
        Text(this.currentHeaders)
          .fontSize(12)
          .fontColor('#333')
          .width('100%')
          .fontFamily('monospace')
          .lineHeight(20)
      }
      .width('100%')
      .constraintSize({ maxHeight: 100 })
      .backgroundColor('#FAFAFA')
      .borderRadius(4)
      .padding(8)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Custom HTTP',
      subtitle: 'Custom HTTP request headers',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
