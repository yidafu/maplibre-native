/**
 * TextureView Animation Test Page
 * TextureView动画测试页面
 * 
 * 注意: Harmony使用NativeMapView基于XComponent实现
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct TextureViewAnimationTestPage {
  private mapController: MapLibreMap | null = null;
  @State private mapWidth: string = '100%';
  @State private mapHeight: string = '100%';
  @State private mapOpacity: number = 1.0;
  @State private animating: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (mapView: NativeMapView): void => {
    const options = new MapLibreMapOptions();
    this.mapController = new MapLibreMap(mapView, options);
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  private animateSize = (): void => {
    if (this.animating) return;
    
    this.animating = true;
    animateTo({ duration: 1000, curve: Curve.EaseInOut }, () => {
      this.mapWidth = '80%';
      this.mapHeight = '80%';
    });
    
    setTimeout(() => {
      animateTo({ duration: 1000, curve: Curve.EaseInOut }, () => {
        this.mapWidth = '100%';
        this.mapHeight = '100%';
      });
      this.animating = false;
    }, 1000);
  };
  
  private animateOpacity = (): void => {
    if (this.animating) return;
    
    this.animating = true;
    animateTo({ duration: 800 }, () => {
      this.mapOpacity = 0.3;
    });
    
    setTimeout(() => {
      animateTo({ duration: 800 }, () => {
        this.mapOpacity = 1.0;
      });
      this.animating = false;
    }, 800);
  };
  
  @Builder
  buildMapContent() {
    Column() {
      NativeMapView({
        onMapReady: this.onMapReady
      })
      .width(this.mapWidth)
      .height(this.mapHeight)
      .opacity(this.mapOpacity)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('XComponent 动画')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Button('大小动画')
        .width('100%')
        .enabled(!this.animating)
        .onClick(() => this.animateSize())
      
      Button('透明度动画')
        .width('100%')
        .enabled(!this.animating)
        .onClick(() => this.animateOpacity())
      
      Text('说明: Harmony使用XComponent实现地图视图')
        .fontSize(12)
        .fontColor('#666')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'TextureView Animation',
        description: 'XComponent动画',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


