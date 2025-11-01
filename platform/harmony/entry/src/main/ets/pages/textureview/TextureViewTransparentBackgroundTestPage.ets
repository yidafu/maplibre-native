/**
 * TextureView Transparent Background Test Page
 * TextureView透明背景测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct TextureViewTransparentBackgroundTestPage {
  private mapController: MapLibreMap | null = null;
  @State private mapOpacity: number = 1.0;
  @State private backgroundColorStr: string = '#FFFFFF';
  
  private bgColors: string[] = ['#FFFFFF', '#000000', '#FF0000', '#00FF00', '#0000FF']
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  @Builder
  buildMapContent() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.backgroundColorStr)
      
      MapView({
        onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
      })
      .width('100%')
      .height('100%')
      .opacity(this.mapOpacity)
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('透明度控制')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Row() {
        Text('透明度:')
          .fontSize(14)
          .width(80)
        Slider({
          value: this.mapOpacity,
          min: 0,
          max: 1,
          step: 0.1
        })
        .layoutWeight(1)
        .onChange((value: number) => {
          this.mapOpacity = value;
        })
        Text(`${(this.mapOpacity * 100).toFixed(0)}%`)
          .fontSize(14)
          .width(50)
      }
      .width('100%')
      
      Text('背景颜色')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
        ForEach(this.bgColors, (color: string) => {
          Button()
            .width(50)
            .height(50)
            .backgroundColor(color)
            .margin(4)
            .onClick(() => {
              this.backgroundColorStr = color;
            })
            .border({
              width: this.backgroundColorStr === color ? 3 : 0,
              color: '#000000'
            })
        })
      }
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'TextureView Transparent',
        description: 'XComponent透明背景',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


