/**
 * StyleUrlTestPage - Load map styles from various URL sources.
 *
 * Demonstrates loading different style URLs including custom URLs
 * entered by the user. Tests style loading with different providers.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { StyleLoadedListener } from '../../utils/ListenerFactories';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

interface PresetUrl {
  name: string;
  url: string;
}

@Entry
@Component
struct StyleUrlTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private customUrl: string = '';

  private readonly presetUrls: PresetUrl[] = [
    { name: 'Bright', url: DEFAULT_STYLE_URLS.bright },
    { name: 'OpenFreeMap Bright', url: DEFAULT_STYLE_URLS.openfreeMapBright },
    { name: 'Liberty', url: DEFAULT_STYLE_URLS.openfreeMapLiberty },
    { name: 'Americana', url: DEFAULT_STYLE_URLS.americana },
    { name: 'Demotiles', url: DEFAULT_STYLE_URLS.demotiles },
    { name: 'Protomaps Light', url: DEFAULT_STYLE_URLS.protomapsLight },
    { name: 'Protomaps Dark', url: DEFAULT_STYLE_URLS.protomapsDark },
  ];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - select a style';
    console.info('[StyleUrlTestPage] Map ready');
  };

  private loadStyle(url: string, name: string): void {
    if (!this.mapController) return;
    this.statusMessage = `Loading ${name}...`;
    try {
      this.mapController.setStyleUrl(url);
      this.mapController.addOnStyleLoadedListener(new StyleLoadedListener(
        () => {
          this.statusMessage = `Loaded: ${name}`;
          showToast(`Style loaded: ${name}`);
        }
      ));
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      showToast(`Failed to load: ${name}`);
    }
  }

  private loadCustomUrl(): void {
    const url = this.customUrl.trim();
    if (!url) {
      showToast('Enter a style URL first');
      return;
    }
    this.loadStyle(url, url.substring(0, 40) + '...');
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
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Preset Style URLs')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      ForEach(this.presetUrls, (item: PresetUrl) => {
        Button(item.name)
          .width('100%')
          .margin({ top: 4 })
          .fontSize(13)
          .onClick(() => this.loadStyle(item.url, item.name))
          .enabled(this.isMapReady)
      })

      Divider().margin({ top: 12, bottom: 8 })

      Text('Custom Style URL')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      TextInput({ placeholder: 'Enter style URL...', text: this.customUrl })
        .width('100%')
        .height(36)
        .margin({ top: 6 })
        .onChange((val: string) => { this.customUrl = val; })

      Button('Load Custom URL')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => this.loadCustomUrl())
        .enabled(this.isMapReady)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Style URL',
      subtitle: 'Load styles from different URLs',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
