import { LatLng, MapLibreMap, Marker, MarkerOptions, MapView, OnMarkerClickListener } from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

/**
 * Marker Click Activity
 * 标记点击事件测试
 * 参考 Android OnMarkerClickListener
 */

class MarkerClickListener implements OnMarkerClickListener {
  private page: MarkerClickTestPage;
  
  constructor(page: MarkerClickTestPage) {
    this.page = page;
  }
  
  onMarkerClick(marker: Marker): boolean {
    this.page.clickCount++;
    this.page.lastClickedMarker = marker.getTitle() || `ID ${marker.getId()}`;
    showToast(`点击了: ${this.page.lastClickedMarker}`);
    return false; // false 表示继续显示 InfoWindow
  }
}

@Entry
@Component
struct MarkerClickTestPage {
  private mapController: MapLibreMap | null = null;
  @State clickCount: number = 0;
  @State lastClickedMarker: string = '';
  @State markersReady: boolean = false;
  @State markerCount: number = 0;
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Marker Click',
      description: '标记点击事件',
      showActionBar: true,
      mapContent: (): void => this.buildMapContent(),
      actionButtons: (): void => this.buildActionButtons()
    })
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      onMapReady: async (map: MapLibreMap) => {
        console.info('[MarkerClickTest] 📍 onMapReady callback started');
        this.mapController = map;
        map.jumpTo(0, 35, 105, 0, 4);
        
        console.info('[MarkerClickTest] 📍 Setting up click listener BEFORE adding markers...');
        this.setupClickListener(map);
        
        // 添加多个标记
        console.info('[MarkerClickTest] 📍 Starting to add markers...');
        await this.addMultipleMarkers(map);
        console.info('[MarkerClickTest] 📍 Markers added, onMapReady callback completed');
      }
    })
  }

  
  private async addMultipleMarkers(map: MapLibreMap): Promise<void> {
    console.info('[MarkerClickTest] 开始添加 markers...');
    this.markersReady = false;
    
    const cities = [
      TEST_LOCATIONS.beijing,
      TEST_LOCATIONS.shanghai,
      TEST_LOCATIONS.guangzhou,
      TEST_LOCATIONS.shenzhen,
      TEST_LOCATIONS.hangzhou
    ]
    
    const options: MarkerOptions[] = cities.map((latLng, index) => 
      new MarkerOptions()
        .position(latLng)
        .title(`城市 ${index + 1}`)
    );
    
    const markers = await map.addMarkersBatch(options);
    this.markerCount = markers.length;
    console.info(`[MarkerClickTest] Markers 添加完成，数量: ${markers.length}`);
    
    // 等待一段时间确保 marker 已渲染到地图上
    // MarkerLayerManager.updateSource 使用 setTimeout(0) 延迟更新
    setTimeout(() => {
      this.markersReady = true;
      console.info('[MarkerClickTest] ✅ Markers 已就绪，可以点击');
      showToast('Markers 已加载完成，可以点击');
    }, 500);  // 给足够的时间让渲染完成
  }
  
  private setupClickListener(map: MapLibreMap): void {
    console.info('[MarkerClickTest] 🔧 Setting up click listener...');
    const clickListener = new MarkerClickListener(this);
    console.info(`[MarkerClickTest] 🔧 Created MarkerClickListener instance`);
    map.setOnMarkerClickListener(clickListener);
    console.info('[MarkerClickTest] 🔧 Click listener set successfully');
  }
  
  @Builder
  buildActionButtons() {
    Column({ space: 12 }) {
      // 状态信息区域
      Column({ space: 6 }) {
        Row({ space: 12 }) {
          Text(`Marker 数量: ${this.markerCount}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          
          Text(this.markersReady ? '✓ 已就绪' : '⏳ 加载中')
            .fontSize(12)
            .fontColor(this.markersReady ? '#4CAF50' : '#FF9800')
        }
        
        Row({ space: 8 }) {
          Text(`点击次数: ${this.clickCount}`)
            .fontSize(14)
          
          if (this.lastClickedMarker) {
            Text(`| ${this.lastClickedMarker}`)
              .fontSize(12)
              .fontColor('#666666')
          }
        }
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      
      // 操作按钮区域
      Row({ space: 10 }) {
        Button('添加 Marker')
          .onClick(() => {
            this.addRandomMarker();
          })
        
        Button('重置计数')
          .onClick(() => {
            this.clickCount = 0;
            this.lastClickedMarker = '';
            showToast('计数已重置');
          })
      }
    }
    .alignItems(HorizontalAlign.Start)
  }
  
  private async addRandomMarker(): Promise<void> {
    if (!this.mapController) {
      showToast('地图未加载');
      return;
    }
    
    // 生成随机经纬度 (中国范围内)
    const lat = 20 + Math.random() * 30;  // 20-50度
    const lng = 80 + Math.random() * 50;  // 80-130度
    
    console.info(`[MarkerClickTest] 添加随机 marker at (${lat.toFixed(2)}, ${lng.toFixed(2)})`);
    this.markersReady = false;
    
    const markerOption = new MarkerOptions()
      .position(new LatLng(lat, lng))
      .title(`随机标记 ${Date.now()}`);
    
    await this.mapController.addMarker(markerOption);
    this.markerCount++;
    
    // 等待渲染完成
    setTimeout(() => {
      this.markersReady = true;
      showToast(`已添加标记 (${lat.toFixed(2)}, ${lng.toFixed(2)})`);
      console.info('[MarkerClickTest] ✅ 随机 Marker 已就绪');
    }, 500);
  }
}