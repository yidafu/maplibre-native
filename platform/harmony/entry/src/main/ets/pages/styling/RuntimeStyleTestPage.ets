/**
 * RuntimeStyleTestPage - Switch between different map styles at runtime.
 *
 * Tests dynamic style switching by loading different style URLs
 * and observing the transition behavior.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng } from 'maplibre_harmony';
import { StyleLoadedListener } from '../../utils/ListenerFactories';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

interface StyleOption {
  name: string;
  url: string;
}

@Entry
@Component
struct RuntimeStyleTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private currentStyle: string = 'Bright';
  @State private statusMessage: string = 'Loading...';

  private readonly styles: StyleOption[] = [
    { name: 'Bright', url: DEFAULT_STYLE_URLS.bright },
    { name: 'OSM', url: DEFAULT_STYLE_URLS.osm },
    { name: 'Dark', url: DEFAULT_STYLE_URLS.dark },
    { name: 'Light', url: DEFAULT_STYLE_URLS.light },
    { name: 'Liberty', url: DEFAULT_STYLE_URLS.openfreeMapLiberty },
  ];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.currentStyle = this.getStyleName(map.getStyleUrl());
    this.statusMessage = `Style: ${this.currentStyle}`;
    console.info('[RuntimeStyleTestPage] Map ready');
  };

  private getStyleName(url: string): string {
    const found = this.styles.find(s => s.url === url);
    return found ? found.name : 'Custom';
  }

  private switchStyle(style: StyleOption): void {
    if (!this.mapController) return;
    this.statusMessage = `Loading ${style.name}...`;
    this.mapController.setStyleUrl(style.url);
    this.mapController.addOnStyleLoadedListener(new StyleLoadedListener(
      () => {
        this.currentStyle = style.name;
        this.statusMessage = `Style: ${style.name}`;
        showToast(`Loaded: ${style.name}`);
      }
    ));
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

      Text('Available Styles')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      ForEach(this.styles, (style: StyleOption) => {
        Button(style.name)
          .width('100%')
          .margin({ top: 6 })
          .backgroundColor(this.currentStyle === style.name ? '#2196F3' : '#9E9E9E')
          .onClick(() => this.switchStyle(style))
          .enabled(this.isMapReady)
      })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Runtime Style',
      subtitle: 'Switch map styles at runtime',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
