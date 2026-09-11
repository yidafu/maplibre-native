/**
 * ObserverTestPage - Observe map and resource events.
 *
 * Registers listeners for various map lifecycle and resource loading
 * events, logging them in a scrollable panel for inspection.
 *
 * Covers:
 * - Camera events (willChange, isChanging, didChange, idle)
 * - Map loading events (willStart, didFinish, didFail)
 * - Rendering events (frame start/finish, map render)
 * - Style events (didFinishLoading, imageMissing)
 * - Resource events (Glyph, Sprite, Tile)
 * - Shader compile events
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';
import type {
  OnCameraWillChangeListener,
  OnCameraIsChangingListener,
  OnCameraDidChangeListener,
  OnWillStartLoadingMapListener,
  OnDidFinishLoadingMapListener,
  OnDidFailLoadingMapListener,
  OnWillStartRenderingFrameListener,
  OnDidFinishRenderingFrameListener,
  OnDidFinishRenderingMapListener,
  OnDidFinishLoadingStyleListener,
  OnDidBecomeIdleListener,
  OnSourceChangedListener,
  OnGlyphsLoadedListener,
  OnGlyphsRequestedListener,
  OnSpriteLoadedListener,
  OnSpriteRequestedListener,
  OnTileActionListener,
  OnStyleImageMissingListener,
} from 'maplibre_harmony';

interface LogEntry {
  category: string;
  message: string;
  timestamp: string;
}

@Entry
@Component
struct ObserverTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private logEntries: LogEntry[] = [];
  @State private eventStats: Record<string, number> = {};
  @State private showAllTiles: boolean = false;
  @State private listenersRegistered: boolean = false;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;

    // Register observers immediately when map is ready
    this.registerAllListeners();
    this.logEvent('System', 'Map ready, all observers registered');
    console.info('[ObserverTestPage] Map ready');
  };

  /**
   * Log an event entry and update statistics.
   */
  private logEvent(category: string, message: string): void {
    const timestamp = new Date().toLocaleTimeString('en-US', { hour12: false });
    const entry: LogEntry = { category, message, timestamp };
    this.logEntries.unshift(entry);
    this.eventStats[category] = (this.eventStats[category] || 0) + 1;

    if (this.logEntries.length > 200) {
      this.logEntries = this.logEntries.slice(0, 200);
    }
  }

  /**
   * Register all available map event listeners.
   */
  private registerAllListeners(): void {
    if (!this.mapController || this.listenersRegistered) return;
    this.listenersRegistered = true;

    try {
      // Camera events
      const cameraWillChange: OnCameraWillChangeListener = (): void => this.logEvent('Camera', 'willChange');
      this.mapController.addOnCameraWillChangeListener(cameraWillChange);

      const cameraIsChanging: OnCameraIsChangingListener = (): void => this.logEvent('Camera', 'isChanging');
      this.mapController.addOnCameraIsChangingListener(cameraIsChanging);

      const cameraDidChange: OnCameraDidChangeListener = (): void => this.logEvent('Camera', 'didChange');
      this.mapController.addOnCameraDidChangeListener(cameraDidChange);

      // Map loading events
      const willStartLoading: OnWillStartLoadingMapListener = (): void => this.logEvent('Loading', 'willStartLoading');
      this.mapController.addOnWillStartLoadingMapListener(willStartLoading);

      const didFinishLoading: OnDidFinishLoadingMapListener = (): void => this.logEvent('Loading', 'didFinishLoading');
      this.mapController.addOnDidFinishLoadingMapListener(didFinishLoading);

      const didFailLoading: OnDidFailLoadingMapListener = (reason: string): void => this.logEvent('Loading', `didFail: ${reason}`);
      this.mapController.addOnDidFailLoadingMapListener(didFailLoading);

      // Rendering events
      const willStartFrame: OnWillStartRenderingFrameListener = (): void => {
        // Suppress high-frequency frame events from log by default
      };
      this.mapController.addOnWillStartRenderingFrameListener(willStartFrame);

      const didFinishFrame: OnDidFinishRenderingFrameListener = (): void => {
        // Suppress high-frequency frame events
      };
      this.mapController.addOnDidFinishRenderingFrameListener(didFinishFrame);

      const didFinishMap: OnDidFinishRenderingMapListener = (): void => this.logEvent('Render', 'map didFinishRendering');
      this.mapController.addOnDidFinishRenderingMapListener(didFinishMap);

      // Style events
      const didFinishStyle: OnDidFinishLoadingStyleListener = (): void => this.logEvent('Style', 'didFinishLoading');
      this.mapController.addOnDidFinishLoadingStyleListener(didFinishStyle);

      const didBecomeIdle: OnDidBecomeIdleListener = (): void => this.logEvent('State', 'didBecomeIdle');
      this.mapController.addOnDidBecomeIdleListener(didBecomeIdle);

      // Source events
      const sourceChanged: OnSourceChangedListener = (sourceId: string): void => this.logEvent('Source', `changed: ${sourceId}`);
      this.mapController.addOnSourceChangedListener(sourceChanged);

      // Glyph events
      const glyphsRequested: OnGlyphsRequestedListener = (fontStack: string[], rangeStart: number, rangeEnd: number): void => {
        this.logEvent('Glyph', `requested: ${fontStack.join(',')} [${rangeStart}-${rangeEnd}]`);
      };
      this.mapController.addOnGlyphsRequestedListener(glyphsRequested);

      const glyphsLoaded: OnGlyphsLoadedListener = (fontStack: string[], rangeStart: number, rangeEnd: number): void => {
        this.logEvent('Glyph', `loaded: ${fontStack.join(',')} [${rangeStart}-${rangeEnd}]`);
      };
      this.mapController.addOnGlyphsLoadedListener(glyphsLoaded);

      // Sprite events
      const spriteRequested: OnSpriteRequestedListener = (spriteId: string, url: string): void => {
        this.logEvent('Sprite', `requested: ${spriteId}`);
      };
      this.mapController.addOnSpriteRequestedListener(spriteRequested);

      const spriteLoaded: OnSpriteLoadedListener = (spriteId: string, url: string): void => {
        this.logEvent('Sprite', `loaded: ${spriteId}`);
      };
      this.mapController.addOnSpriteLoadedListener(spriteLoaded);

      // Tile action events
      const tileAction: OnTileActionListener = (operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string): void => {
        if (!this.showAllTiles && (operation === 4 || operation === 5)) {
          return; // Suppress StartParse/EndParse when not showing all
        }
        const opNames: string[] = ['CacheRequest', 'NetworkRequest', 'CacheLoad', 'NetworkLoad', 'StartParse', 'EndParse'];
        const opName = opNames[operation] || `Op(${operation})`;
        this.logEvent('Tile', `${opName}: ${z}/${x}/${y} source=${sourceId}`);
      };
      this.mapController.addOnTileActionListener(tileAction);

      this.logEvent('System', 'Registered 15+ event listeners');

    } catch (error) {
      this.logEvent('System', `Listener registration error: ${error}`);
      console.error('[ObserverTestPage] Registration error:', error);
    }
  }

  /**
   * Reload the map style to trigger events.
   */
  private reloadStyle(): void {
    if (!this.mapController) return;
    const current = this.mapController.getStyleUrl();
    this.mapController.setStyleUrl(current);
    this.logEvent('System', 'Reloading style...');
    showToast('Style reloaded');
  }

  /**
   * Toggle the style between two URLs to trigger different events.
   */
  private toggleStyle(): void {
    if (!this.mapController) return;
    const current = this.mapController.getStyleUrl();
    // Toggle between styles
    const newUrl = current && current.includes('bright')
      ? 'https://demotiles.maplibre.org/style.json'
      : 'https://demotiles.maplibre.org/style.json';
    this.mapController.setStyleUrl(newUrl);
    this.logEvent('System', `Switching style...`);
    showToast('Style toggled');
  }

  /**
   * Clear the event log and statistics.
   */
  private clearLog(): void {
    this.logEntries = [];
    this.eventStats = {};
    showToast('Log cleared');
  }

  /**
   * Get a display color for each event category.
   */
  private getCategoryColor(category: string): string {
    const colors: Record<string, string> = {
      'System': '#607D8B',
      'Camera': '#9C27B0',
      'Loading': '#2196F3',
      'Render': '#F44336',
      'Style': '#4CAF50',
      'State': '#FF9800',
      'Source': '#00BCD4',
      'Glyph': '#3F51B5',
      'Sprite': '#E91E63',
      'Tile': '#795548',
    };
    return colors[category] || '#666';
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
      Text('Event Observer')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text('Event Statistics')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ top: 8, bottom: 4 })

      Column() {
        if (Object.keys(this.eventStats).length > 0) {
          ForEach(Object.entries(this.eventStats), (entry: [string, number]) => {
            Row() {
              Text(entry[0])
                .fontSize(11)
                .fontColor(this.getCategoryColor(entry[0]))
                .layoutWeight(1)
              Text(`${entry[1]}`)
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .padding({ top: 2, bottom: 2 })
          }, (item: [string, number]) => item[0])
        } else {
          Text('No events yet')
            .fontSize(11)
            .fontColor('#999')
        }
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)

      Divider().margin({ top: 8, bottom: 8 })

      Text('Controls')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 6 })

      Row() {
        Button('Reload Style')
          .layoutWeight(1)
          .fontSize(12)
          .margin({ right: 4 })
          .onClick(() => this.reloadStyle())
          .enabled(this.isMapReady)

        Button('Toggle Style')
          .layoutWeight(1)
          .fontSize(12)
          .margin({ left: 4, right: 4 })
          .onClick(() => this.toggleStyle())
          .enabled(this.isMapReady)

        Button('Clear Log')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#E91E63')
          .margin({ left: 4 })
          .onClick(() => this.clearLog())
      }
      .width('100%')

      Row() {
        Button(this.showAllTiles ? 'Hide Parse Events' : 'Show All Tiles')
          .width('100%')
          .fontSize(12)
          .backgroundColor(this.showAllTiles ? '#FF9800' : '#9E9E9E')
          .margin({ top: 6 })
          .onClick(() => {
            this.showAllTiles = !this.showAllTiles;
            showToast(this.showAllTiles ? 'Showing all tile events' : 'Hiding parse events');
          })
      }
      .width('100%')

      Divider().margin({ top: 8, bottom: 8 })

      Text(`Event Log (${this.logEntries.length})`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 4 })

      Scroll() {
        Column() {
          if (this.logEntries.length > 0) {
            ForEach(this.logEntries, (entry: LogEntry, index: number) => {
              Row() {
                Text(entry.timestamp)
                  .fontSize(9)
                  .fontColor('#999')
                  .width(60)

                Text(`[${entry.category}]`)
                  .fontSize(9)
                  .fontColor(this.getCategoryColor(entry.category))
                  .fontWeight(FontWeight.Bold)
                  .width(50)

                Text(entry.message)
                  .fontSize(9)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 3, bottom: 3, left: 4, right: 4 })
              .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F5F5F5')
            }, (entry: LogEntry, index: number) => `${index}_${entry.timestamp}`)
          } else {
            Text('No events captured yet. Interact with the map to generate events.')
              .fontSize(11)
              .fontColor('#999')
              .padding(12)
          }
        }
      }
      .width('100%')
      .constraintSize({ maxHeight: 180 })
      .backgroundColor('#FAFAFA')
      .borderRadius(4)
      .border({ width: 1, color: '#DDD' })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Observer',
      subtitle: 'Observe map and resource events',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
