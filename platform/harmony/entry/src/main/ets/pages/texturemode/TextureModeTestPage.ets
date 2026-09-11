/**
 * TextureModeTestPage - map rendered on XComponentType.TEXTURE via TextureMapView.
 *
 * Verifies the TEXTURE render mode end to end:
 * - Rendering, gestures, and camera controls through the texture surface
 * - ArkUI in-tree compositing: rotate/scale transforms applied to the map
 *   container (SURFACE mode ignores these)
 * - Debug overlay rendering on top of the composited texture
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { TextureMapView, MapLibreMap } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct TextureModeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private isDebugActive: boolean = false;
  @State private isTransformed: boolean = false;
  @State private mapRotation: number = 0;
  @State private mapScale: number = 1;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    showToast('TextureMapView ready');
  };

  private toggleDebugVisuals(): void {
    if (!this.mapController) return;
    this.isDebugActive = !this.isDebugActive;
    this.mapController.setDebugActive(this.isDebugActive);
    showToast('Debug visuals: ' + (this.isDebugActive ? 'ON' : 'OFF'));
  }

  private toggleTransform(): void {
    this.isTransformed = !this.isTransformed;
    animateTo({ duration: 600, curve: Curve.EaseInOut }, () => {
      this.mapRotation = this.isTransformed ? 20 : 0;
      this.mapScale = this.isTransformed ? 0.8 : 1;
    });
    showToast('Transform: ' + (this.isTransformed ? 'rotate 20° / scale 0.8' : 'identity'));
  }

  @Builder
  mapContent() {
    Stack() {
      TextureMapView({
        debugMode: false,
        onMapReady: this.onMapReady,
      })
        .width('100%')
        .height('100%')
        .rotate({
          x: 0,
          y: 0,
          z: 1,
          angle: this.mapRotation
        })
        .scale({ x: this.mapScale, y: this.mapScale })

      // In-tree compositing proof: this overlay stays glued to the transformed map
      Text('XComponentType.TEXTURE')
        .fontSize(11)
        .fontColor(Color.White)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .backgroundColor('rgba(0,0,0,0.6)')
        .borderRadius(4)
        .margin(8)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Texture Mode')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text('Map rendered via TextureMapView (XComponentType.TEXTURE). ' +
        'Use the transform toggle to verify in-tree compositing; compare with SURFACE pages.')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ bottom: 12 })

      Row() {
        Button(this.isDebugActive ? 'Debug: ON' : 'Debug: OFF')
          .fontSize(12)
          .backgroundColor(this.isDebugActive ? '#4CAF50' : '#9E9E9E')
          .layoutWeight(1)
          .margin({ right: 4 })
          .onClick(() => this.toggleDebugVisuals())
          .enabled(this.isMapReady)

        Button(this.isTransformed ? 'Reset Transform' : 'Apply Transform')
          .fontSize(12)
          .backgroundColor(this.isTransformed ? '#2196F3' : '#9E9E9E')
          .layoutWeight(1)
          .margin({ left: 4 })
          .onClick(() => this.toggleTransform())
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'Texture Mode',
        subtitle: 'Map on XComponentType.TEXTURE with transforms',
        mapContent: (): void => this.mapContent(),
        controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
