/**
 * LocalGlyphTestPage - Local glyph font rendering.
 *
 * Tests setLocalIdeographFontFamily for rendering CJK characters
 * with local fonts instead of downloading glyph data.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct LocalGlyphTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready';
  @State private currentFont: string = '(default)';
  @State private localFontEnabled: boolean = false;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.queryCurrentFont();
    this.statusMessage = 'Map ready';
  };

  private queryCurrentFont(): void {
    if (!this.mapController) return;
    try {
      const font = this.mapController.getLocalIdeographFontFamily();
      this.currentFont = font || '(disabled, using remote glyphs)';
      this.localFontEnabled = font !== null && font !== undefined && font !== '';
    } catch (e) {
      this.currentFont = `(error: ${e})`;
    }
  }

  private enableLocalFont(): void {
    if (!this.mapController) return;
    try {
      // HarmonyOS system font
      this.mapController.setLocalIdeographFontFamily('HarmonyOS_Sans');
      this.localFontEnabled = true;
      this.currentFont = 'HarmonyOS_Sans';
      this.statusMessage = 'Local glyph font enabled: HarmonyOS_Sans';
      showToast('Local glyph font set to HarmonyOS_Sans');
      this.queryCurrentFont();
    } catch (e) {
      this.statusMessage = `Failed to set local font: ${e}`;
    }
  }

  private enableNotoFont(): void {
    if (!this.mapController) return;
    try {
      this.mapController.setLocalIdeographFontFamily('Noto Sans CJK SC');
      this.localFontEnabled = true;
      this.currentFont = 'Noto Sans CJK SC';
      this.statusMessage = 'Local glyph font enabled: Noto Sans CJK SC';
      showToast('Local glyph font set to Noto Sans CJK SC');
    } catch (e) {
      this.statusMessage = `Failed to set local font: ${e}`;
    }
  }

  private disableLocalFont(): void {
    if (!this.mapController) return;
    try {
      this.mapController.setLocalIdeographFontFamily(null);
      this.localFontEnabled = false;
      this.currentFont = '(disabled, using remote glyphs)';
      this.statusMessage = 'Local glyph rendering disabled';
      showToast('Using remote glyphs');
    } catch (e) {
      this.statusMessage = `Failed to disable local font: ${e}`;
    }
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 12,
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Local Glyph Font')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text(this.statusMessage)
        .fontSize(12)
        .fontColor('#333')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Current Font')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Text(this.currentFont)
        .fontSize(13)
        .fontFamily('monospace')
        .fontColor(this.localFontEnabled ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(10)
        .backgroundColor('#F0F0F0')
        .borderRadius(6)

      Text('Local Font Options')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Button('Enable HarmonyOS Sans')
        .width('100%')
        .height(40)
        .margin({ top: 4 })
        .backgroundColor(this.localFontEnabled && this.currentFont.includes('HarmonyOS') ? '#4CAF50' : '#2196F3')
        .enabled(this.isMapReady)
        .onClick(() => this.enableLocalFont())

      Button('Enable Noto Sans CJK SC')
        .width('100%')
        .height(40)
        .margin({ top: 6 })
        .backgroundColor(this.localFontEnabled && this.currentFont.includes('Noto') ? '#4CAF50' : '#2196F3')
        .enabled(this.isMapReady)
        .onClick(() => this.enableNotoFont())

      Button('Disable (Use Remote Glyphs)')
        .width('100%')
        .height(40)
        .margin({ top: 6 })
        .backgroundColor('#FF5722')
        .enabled(this.isMapReady && this.localFontEnabled)
        .onClick(() => this.disableLocalFont())

      Text('Note')
        .fontSize(11)
        .fontColor('#999')
        .width('100%')
        .margin({ top: 12 })
      Text('Local ideograph fonts render CJK characters without downloading glyph data. The map reinitializes and reloads the style when the font changes.')
        .fontSize(10)
        .fontColor('#999')
        .lineHeight(15)
        .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Local Glyph',
      subtitle: 'Local glyph font rendering',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
