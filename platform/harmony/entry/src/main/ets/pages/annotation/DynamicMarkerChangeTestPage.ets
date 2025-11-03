/**
 * Dynamic Marker Change Test Page
 * 动态Marker变化测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, Marker, MarkerOptions, LatLng, OnMarkerClickListener } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct DynamicMarkerChangeTestPage {
  private mapController: MapLibreMap | null = null;
  private marker: Marker | null = null;
  @State private markerPosition: LatLng = LatLng.create(39.9042, 116.4074);
  @State private markerTitle: string = '动态Marker';
  @State private changeCount: number = 0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    this.mapController = map;
    
    // 注册 Marker 点击监听器以显示 InfoWindow
    this.setupMarkerClickListener(map);
    
    await this.addMarker();
  };
  
  private setupMarkerClickListener = (map: MapLibreMap): void => {
    class MarkerClickListenerImpl implements OnMarkerClickListener {
      mapController: MapLibreMap;
      
      constructor(mapController: MapLibreMap) {
        this.mapController = mapController;
      }
      
      onMarkerClick(marker: Marker): boolean {
        console.info(`[DynamicMarkerChange] Marker clicked - title: "${marker.getTitle()}", snippet: "${marker.getSnippet()}"`);
        // 选中 Marker 并显示 InfoWindow
        this.mapController.selectMarker(marker, true);
        showToast(`点击了: ${marker.getTitle()}`);
        return false; // 返回 false 表示不消费事件，允许显示 InfoWindow
      }
    }
    
    map.setOnMarkerClickListener(new MarkerClickListenerImpl(map));
  };
  
  private addMarker = async (): Promise<void> => {
    if (!this.mapController) return;
    
    const markerOptions = new MarkerOptions()
      .position(this.markerPosition)
      .title(this.markerTitle)
      .snippet(`变更次数: ${this.changeCount}`);
    
    this.marker = await this.mapController.addMarker(markerOptions);
    showToast('Marker已添加');
  };
  
  private changePosition = (): void => {
    if (!this.marker) return;
    
    const newLat = 39.85 + Math.random() * 0.1;
    const newLng = 116.35 + Math.random() * 0.1;
    this.markerPosition = LatLng.create(newLat, newLng);
    
    this.marker.setPosition(this.markerPosition);
    this.changeCount++;
    this.marker.setSnippet(`变更次数: ${this.changeCount}`);
    
    if (this.mapController) {
      this.mapController.easeTo({ center: this.markerPosition }, 500);
    }
    
    showToast('位置已更新');
  };
  
  private changeTitle = (): void => {
    if (!this.marker) return;
    
    const titles = ['Marker A', 'Marker B', 'Marker C', 'Marker D']
    this.markerTitle = titles[Math.floor(Math.random() * titles.length)]
    this.marker.setTitle(this.markerTitle);
    this.changeCount++;
    this.marker.setSnippet(`变更次数: ${this.changeCount}`);
    
    showToast(`标题已更新: ${this.markerTitle}`);
  };
  
  private showMarkerInfo = (): void => {
    if (!this.marker || !this.mapController) return;
    
    console.info(`[DynamicMarkerChange] Manual show InfoWindow - title: "${this.marker.getTitle()}", snippet: "${this.marker.getSnippet()}"`);
    this.mapController.selectMarker(this.marker, true);
    showToast('显示 InfoWindow');
  };
  
  private hideMarkerInfo = (): void => {
    if (!this.marker || !this.mapController) return;
    
    this.mapController.deselectMarker(this.marker);
    showToast('隐藏 InfoWindow');
  };
  
  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      onMapReady: this.onMapReady
    })
  }
  
  @Builder
  buildActionButtons() {
    Column({ space: 8 }) {
      // Marker 属性信息展示区
      Column({ space: 4 }) {
        Text('动态Marker属性')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%');
        
        Text(`标题: ${this.markerTitle}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%');
        
        Text(`位置: ${this.markerPosition.latitude.toFixed(4)}, ${this.markerPosition.longitude.toFixed(4)}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%');
        
        Text(`变更次数: ${this.changeCount}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%');
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(8)
      .backgroundColor('#FFFFFF')
      .borderRadius(4)
      
      // 分隔线
      Divider()
        .color('#E0E0E0')
        .strokeWidth(1)
      
      // 操作按钮区
      Column({ space: 8 }) {
        Button('随机改变位置')
          .fontSize(14)
          .width('100%')
          .onClick(() => this.changePosition());
        
        Button('随机改变标题')
          .fontSize(14)
          .width('100%')
          .onClick(() => this.changeTitle());
        
        Button('同时改变')
          .fontSize(14)
          .width('100%')
          .backgroundColor('#4CAF50')
          .onClick(() => {
            this.changePosition();
            this.changeTitle();
          });
        
        // 分隔线
        Divider()
          .color('#E0E0E0')
          .strokeWidth(1)
          .margin({ top: 4, bottom: 4 });
        
        // InfoWindow 控制按钮
        Row({ space: 8 }) {
          Button('显示信息')
            .fontSize(14)
            .layoutWeight(1)
            .backgroundColor('#2196F3')
            .onClick(() => this.showMarkerInfo());
          
          Button('隐藏信息')
            .fontSize(14)
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .onClick(() => this.hideMarkerInfo());
        }
        .width('100%');
        
        Text('提示：也可以直接点击地图上的 Marker')
          .fontSize(12)
          .fontColor('#999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 4 });
      }
      .width('100%')
    }
    .width('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Dynamic Marker Change',
        description: '动态Marker变化',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}


