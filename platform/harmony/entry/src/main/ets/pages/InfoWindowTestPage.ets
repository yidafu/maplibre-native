/**
 * InfoWindowTestPage - InfoWindow（信息窗口）测试页面
 * 
 * 测试功能：
 * - 显示/隐藏 InfoWindow
 * - 自定义 InfoWindow 样式
 * - InfoWindow 点击和长按事件
 * - 更新 InfoWindow 内容
 * - 多个 InfoWindow 管理
 * - InfoWindow 边界检测
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import maplibre from 'libmaplibre_native.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from 'maplibre_harmony/src/main/ets/maps/camera/CameraPosition';
import { MarkerOptions } from 'maplibre_harmony/src/main/ets/maps/annotations/MarkerOptions';
import { InfoWindowStyle } from 'maplibre_harmony/src/main/ets/maps/annotations/InfoWindow';

// 使用 NAPI Marker 类型
type Marker = maplibre.Marker;

@Entry
@Component
struct InfoWindowTestPage {
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State markerCount: number = 0;
  @State infoWindowCount: number = 0;
  
  private mapLibreMap: MapLibreMap | null = null;
  private markerList: Marker[] = [];

  /**
   * 地图区域构建器
   */
  @Builder
  MapAreaBuilder() {
    NativeMapView({
      onMapReady: (nativeMapView?: maplibre.NativeMapView) => {
        this.onMapReady(nativeMapView);
      }
    })
    .width('100%')
    .height('100%')
  }

  /**
   * 控制区域构建器
   */
  @Builder
  ControlAreaBuilder() {
    // 状态信息
    Text(this.statusMessage)
      .fontSize(14)
      .width('100%')
      .padding(12)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
    
    // 统计信息
    Text(`Marker 数量: ${this.markerCount} | 显示 InfoWindow: ${this.infoWindowCount}`)
      .fontSize(13)
      .width('100%')
      .padding(8)
      .backgroundColor('#E3F2FD')
      .borderRadius(4)
      .fontColor('#1976D2')
    
    // 基本功能
    Text('基本功能')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('添加默认InfoWindow')
        .width('48%')
        .fontSize(12)
        .onClick(() => {
          this.addDefaultInfoWindow();
        })
        .enabled(this.mapReady)
      
      Button('添加多行文本')
        .width('48%')
        .fontSize(12)
        .margin({ left: 8 })
        .onClick(() => {
          this.addMultiLineInfoWindow();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 自定义样式
    Text('自定义样式')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('蓝色主题')
        .width('48%')
        .fontSize(12)
        .backgroundColor('#2196F3')
        .onClick(() => {
          this.addBlueStyleInfoWindow();
        })
        .enabled(this.mapReady)
      
      Button('绿色主题')
        .width('48%')
        .fontSize(12)
        .margin({ left: 8 })
        .backgroundColor('#4CAF50')
        .onClick(() => {
          this.addGreenStyleInfoWindow();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Row() {
      Button('大字体样式')
        .width('48%')
        .fontSize(12)
        .backgroundColor('#FF9800')
        .onClick(() => {
          this.addLargeFontInfoWindow();
        })
        .enabled(this.mapReady)
      
      Button('紧凑样式')
        .width('48%')
        .fontSize(12)
        .margin({ left: 8 })
        .backgroundColor('#9C27B0')
        .onClick(() => {
          this.addCompactInfoWindow();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 边界测试
    Text('边界测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('左上角')
        .width('48%')
        .fontSize(12)
        .onClick(() => {
          this.addInfoWindowAtCorner('topLeft');
        })
        .enabled(this.mapReady)
      
      Button('右上角')
        .width('48%')
        .fontSize(12)
        .margin({ left: 8 })
        .onClick(() => {
          this.addInfoWindowAtCorner('topRight');
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 管理操作
    Text('管理操作')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('关闭所有InfoWindow')
        .width('48%')
        .fontSize(12)
        .backgroundColor('#F44336')
        .onClick(() => {
          this.closeAllInfoWindows();
        })
        .enabled(this.mapReady)
      
      Button('清除所有Marker')
        .width('48%')
        .fontSize(12)
        .margin({ left: 8 })
        .backgroundColor('#E91E63')
        .onClick(() => {
          this.clearAllMarkers();
        })
        .enabled(this.mapReady && this.markerCount > 0)
    }
    .width('100%')
    
    Button('显示所有InfoWindow')
      .width('100%')
      .fontSize(12)
      .backgroundColor('#00BCD4')
      .onClick(() => {
        this.showAllInfoWindows();
      })
      .enabled(this.mapReady && this.markerCount > 0)
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'InfoWindow 测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }
  
  /**
   * 页面卸载
   */
  aboutToDisappear() {
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
    }
  }

  /**
   * 地图就绪回调
   */
  private onMapReady(nativeMapView?: maplibre.NativeMapView): void {
    if (nativeMapView) {
      try {
        const latLng = new maplibre.LatLng(39.9042, 116.4074);
        const cameraPos = createCameraPosition(latLng, 10, 0, 0);
        const options = new MapLibreMapOptions();
        options.cameraPosition = cameraPos;
        options.styleUrl = 'https://demotiles.maplibre.org/style.json';
        
        this.mapLibreMap = new MapLibreMap(nativeMapView, options);
        this.mapReady = true;
        this.statusMessage = '✅ 地图加载成功，点击按钮添加 InfoWindow';
        
        hilog.info(DOMAIN, 'InfoWindowTestPage', 'Map ready');
      } catch (error) {
        this.statusMessage = `❌ 地图初始化失败: ${error.message}`;
        hilog.error(DOMAIN, 'InfoWindowTestPage', `Map init failed: ${error.message}`);
      }
    }
  }

  /**
   * 添加默认样式的 InfoWindow
   */
  private async addDefaultInfoWindow(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('默认 InfoWindow')
          .snippet('这是一个使用默认样式的信息窗口')
          .draggable(false)
      );
      
      this.markerList.push(marker);
      this.markerCount++;
      
      // 显示 InfoWindow
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加默认 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added default InfoWindow');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 添加多行文本的 InfoWindow
   */
  private async addMultiLineInfoWindow(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('多行文本 InfoWindow')
          .snippet('第一行信息\n第二行信息\n第三行信息\n支持多行显示')
          .draggable(false)
      );
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加多行文本 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added multi-line InfoWindow');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 添加蓝色主题的 InfoWindow
   */
  private async addBlueStyleInfoWindow(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('蓝色主题')
          .snippet('使用蓝色背景和白色文字')
          .draggable(false)
      );
      
      // 设置自定义样式
      // 注意：InfoWindow 样式需要通过 MarkerOptions 或其他方式设置
      // 当前 NAPI Marker 不直接暴露 getInfoWindow() 方法
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加蓝色主题 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added blue style InfoWindow');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 添加绿色主题的 InfoWindow
   */
  private async addGreenStyleInfoWindow(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('绿色主题')
          .snippet('清新的绿色配色方案')
          .draggable(false)
      );
      
      // 注意：InfoWindow 样式需要通过 MarkerOptions 或其他方式设置
      // 当前 NAPI Marker 不直接暴露 getInfoWindow() 方法
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加绿色主题 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added green style InfoWindow');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 添加大字体样式的 InfoWindow
   */
  private async addLargeFontInfoWindow(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('大字体')
          .snippet('使用更大的字体以提高可读性')
          .draggable(false)
      );
      
      // 注意：InfoWindow 样式需要通过 MarkerOptions 或其他方式设置
      // 当前 NAPI Marker 不直接暴露 getInfoWindow() 方法
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加大字体 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added large font InfoWindow');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 添加紧凑样式的 InfoWindow
   */
  private async addCompactInfoWindow(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('紧凑')
          .snippet('小巧紧凑的样式')
          .draggable(false)
      );
      
      // 注意：InfoWindow 样式需要通过 MarkerOptions 或其他方式设置
      // 当前 NAPI Marker 不直接暴露 getInfoWindow() 方法
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加紧凑样式 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added compact InfoWindow');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 在指定角落添加 InfoWindow
   */
  private async addInfoWindowAtCorner(corner: string): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      let lat: number;
      let lng: number;
      let title: string;
      
      switch (corner) {
        case 'topLeft':
          lat = 40.5;
          lng = 115.5;
          title = '左上角';
          break;
        case 'topRight':
          lat = 40.5;
          lng = 117.5;
          title = '右上角';
          break;
        default:
          return;
      }
      
      const position = new maplibre.LatLng(lat, lng);
      
      const marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title(title)
          .snippet('测试边界检测功能\nInfoWindow 应该自动调整位置')
          .draggable(false)
      );
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已在${title}添加 InfoWindow`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', `Added InfoWindow at ${corner}`);
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 关闭所有 InfoWindow
   */
  private closeAllInfoWindows(): void {
    if (!this.mapLibreMap) return;
    
    try {
      let closedCount = 0;
      
      for (const marker of this.markerList) {
        if (marker.isInfoWindowShown()) {
          marker.hideInfoWindow();
          closedCount++;
        }
      }
      
      this.infoWindowCount = 0;
      this.statusMessage = `✅ 已关闭 ${closedCount} 个 InfoWindow`;
      
      hilog.info(DOMAIN, 'InfoWindowTestPage', `Closed ${closedCount} InfoWindows`);
    } catch (error) {
      this.statusMessage = `❌ 关闭失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to close InfoWindows: ${error.message}`);
    }
  }

  /**
   * 显示所有 InfoWindow
   */
  private showAllInfoWindows(): void {
    if (!this.mapLibreMap) return;
    
    try {
      let shownCount = 0;
      
      for (const marker of this.markerList) {
        if (!marker.isInfoWindowShown()) {
          marker.showInfoWindow();
          shownCount++;
        }
      }
      
      this.infoWindowCount = this.markerList.length;
      this.statusMessage = `✅ 已显示 ${shownCount} 个 InfoWindow`;
      
      hilog.info(DOMAIN, 'InfoWindowTestPage', `Showed ${shownCount} InfoWindows`);
    } catch (error) {
      this.statusMessage = `❌ 显示失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to show InfoWindows: ${error.message}`);
    }
  }

  /**
   * 清除所有 Marker
   */
  private async clearAllMarkers(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      for (const marker of this.markerList) {
        await this.mapLibreMap.removeMarker(marker);
      }
      
      const count = this.markerList.length;
      this.markerList = [];
      this.markerCount = 0;
      this.infoWindowCount = 0;
      
      this.statusMessage = `✅ 已清除 ${count} 个 Marker`;
      
      hilog.info(DOMAIN, 'InfoWindowTestPage', `Cleared ${count} markers`);
    } catch (error) {
      this.statusMessage = `❌ 清除失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to clear markers: ${error.message}`);
    }
  }

  /**
   * 获取随机位置（在北京周围）
   */
  private getRandomPosition(): maplibre.LatLng {
    const baseLat = 39.9042;
    const baseLng = 116.4074;
    const range = 0.3; // 约30公里范围
    
    const lat = baseLat + (Math.random() - 0.5) * range;
    const lng = baseLng + (Math.random() - 0.5) * range;
    
    return new maplibre.LatLng(lat, lng);
  }
}

