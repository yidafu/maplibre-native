/**
 * TextureViewAnimationTestPage - Animate the map view container.
 *
 * Demonstrates ArkUI animations applied to the MapView container:
 * - Size animation: shrink and expand the map view
 * - Opacity animation: fade the map in and out
 * - Translate animation: slide the map horizontally
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';

@Entry
@Component
struct TextureViewAnimationTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private mapWidth: string = '100%';
  @State private mapHeight: string = '100%';
  @State private mapOpacity: number = 1.0;
  @State private translateX: number = 0;
  @State private cornerRadius: number = 0;
  @State private animating: boolean = false;
  @State private statusMessage: string = 'Ready';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private animateSize(): void {
    if (this.animating) return;
    this.animating = true;
    this.statusMessage = 'Animating size...';
    animateTo({ duration: 1200, curve: Curve.EaseInOut }, () => {
      this.mapWidth = '70%';
      this.mapHeight = '70%';
      this.cornerRadius = 20;
    });
    setTimeout(() => {
      animateTo({ duration: 1200, curve: Curve.EaseInOut }, () => {
        this.mapWidth = '100%';
        this.mapHeight = '100%';
        this.cornerRadius = 0;
      });
      this.animating = false;
      this.statusMessage = 'Size animation complete';
    }, 1300);
  }

  private animateOpacity(): void {
    if (this.animating) return;
    this.animating = true;
    this.statusMessage = 'Animating opacity...';
    animateTo({ duration: 800, curve: Curve.EaseIn }, () => {
      this.mapOpacity = 0.2;
    });
    setTimeout(() => {
      animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
        this.mapOpacity = 1.0;
      });
      this.animating = false;
      this.statusMessage = 'Opacity animation complete';
    }, 900);
  }

  private animateTranslate(): void {
    if (this.animating) return;
    this.animating = true;
    this.statusMessage = 'Sliding...';
    animateTo({ duration: 600, curve: Curve.EaseInOut }, () => {
      this.translateX = 80;
    });
    setTimeout(() => {
      animateTo({ duration: 600, curve: Curve.EaseInOut }, () => {
        this.translateX = -80;
      });
      setTimeout(() => {
        animateTo({ duration: 600, curve: Curve.EaseInOut }, () => {
          this.translateX = 0;
        });
        this.animating = false;
        this.statusMessage = 'Slide animation complete';
      }, 700);
    }, 700);
  }

  private animateAll(): void {
    if (this.animating) return;
    this.animating = true;
    this.statusMessage = 'Running combo animation...';
    animateTo({ duration: 1000, curve: Curve.FastOutSlowIn }, () => {
      this.mapWidth = '60%';
      this.mapHeight = '60%';
      this.mapOpacity = 0.5;
      this.cornerRadius = 30;
      this.translateX = 50;
    });
    setTimeout(() => {
      animateTo({ duration: 1000, curve: Curve.FastOutSlowIn }, () => {
        this.mapWidth = '100%';
        this.mapHeight = '100%';
        this.mapOpacity = 1.0;
        this.cornerRadius = 0;
        this.translateX = 0;
      });
      this.animating = false;
      this.statusMessage = 'Combo animation complete';
    }, 1100);
  }

  @Builder
  mapContent() {
    Column() {
      MapView({
        onMapReady: this.onMapReady,
      })
        .width(this.mapWidth)
        .height(this.mapHeight)
        .opacity(this.mapOpacity)
        .translate({ x: this.translateX, y: 0 })
        .borderRadius(this.cornerRadius)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#E0E0E0')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Container Animation Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 4 })

      Text(this.statusMessage)
        .fontSize(12)
        .fontColor(this.animating ? '#FF9800' : '#4CAF50')
        .width('100%')
        .margin({ bottom: 12 })

      Row() {
        Button('Size').fontSize(13).layoutWeight(1).margin({ right: 4 })
          .enabled(!this.animating && this.isMapReady)
          .onClick(() => this.animateSize())
        Button('Opacity').fontSize(13).layoutWeight(1).margin({ left: 4, right: 4 })
          .enabled(!this.animating && this.isMapReady)
          .onClick(() => this.animateOpacity())
        Button('Slide').fontSize(13).layoutWeight(1).margin({ left: 4 })
          .enabled(!this.animating && this.isMapReady)
          .onClick(() => this.animateTranslate())
      }
      .width('100%')
      .margin({ bottom: 8 })

      Button('Combo (All Together)')
        .width('100%')
        .enabled(!this.animating && this.isMapReady)
        .onClick(() => this.animateAll())

      Text('Animated properties: width, height, opacity, corner radius, translate')
        .fontSize(11)
        .fontColor('#999')
        .width('100%')
        .margin({ top: 8 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'TextureView Animation',
      subtitle: 'Animate map container with ArkUI transitions',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
