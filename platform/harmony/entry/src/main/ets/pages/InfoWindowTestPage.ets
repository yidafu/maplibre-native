/**
 * InfoWindowTestPage - InfoWindow（信息窗口）测试页面
 * 
 * 测试功能：
 * - 显示/隐藏 InfoWindow
 * - 自定义 InfoWindow 样式（颜色、字体、圆角等）
 * - InfoWindow 附件视图（左右按钮）
 * - InfoWindow 缩略图
 * - InfoWindow 关闭按钮
 * - InfoWindow 点击和长按事件
 * - 动态更新 InfoWindow 内容
 * - 多个 InfoWindow 管理
 * - InfoWindow 边界检测
 * - InfoWindow 偏移量配置
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { maplibre } from 'maplibre_harmony';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from 'maplibre_harmony/src/main/ets/maps/camera/CameraPosition';
import { MarkerOptions } from 'maplibre_harmony/src/main/ets/maps/annotations/MarkerOptions';
import { InfoWindowStyle } from 'maplibre_harmony/src/main/ets/maps/annotations/InfoWindow';

@Entry
@Component
struct InfoWindowTestPage {
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State markerCount: number = 0;
  @State infoWindowCount: number = 0;
  
  private mapLibreMap: MapLibreMap | null = null;
  private markerList: maplibre.Marker[] = [];

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
      Button('默认样式')
        .width('48%')
        .fontSize(12)
        .onClick(() => {
          this.addDefaultInfoWindow();
        })
        .enabled(this.mapReady)
      
      Button('多行文本')
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
    Text('自定义样式 + 颜色主题')
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
    
    // 附件和高级功能
    Text('附件视图 + 高级功能')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('带缩略图')
        .width('48%')
        .fontSize(12)
        .backgroundColor('#E91E63')
        .onClick(() => {
          this.addInfoWindowWithThumbnail();
        })
        .enabled(this.mapReady)
      
      Button('带关闭按钮')
        .width('48%')
        .fontSize(12)
        .margin({ left: 8 })
        .backgroundColor('#673AB7')
        .onClick(() => {
          this.addInfoWindowWithCloseButton();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Row() {
      Button('自定义偏移量')
        .width('48%')
        .fontSize(12)
        .backgroundColor('#795548')
        .onClick(() => {
          this.addInfoWindowWithOffset();
        })
        .enabled(this.mapReady)
      
      Button('圆角 + 阴影')
        .width('48%')
        .fontSize(12)
        .margin({ left: 8 })
        .backgroundColor('#607D8B')
        .onClick(() => {
          this.addInfoWindowWithShadow();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 随机位置测试
    Text('随机位置测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('随机红色主题')
        .width('48%')
        .fontSize(12)
        .backgroundColor('#FF5722')
        .onClick(() => {
          this.addInfoWindowAtCorner('topLeft');
        })
        .enabled(this.mapReady)
      
      Button('随机橙色主题')
        .width('48%')
        .fontSize(12)
        .margin({ left: 8 })
        .backgroundColor('#FF6F00')
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
   * 页面出现：重置状态，确保不复用上次实例
   */
  aboutToAppear() {
    this.statusMessage = '等待操作...';
    this.mapReady = false;
    this.markerCount = 0;
    this.infoWindowCount = 0;
    this.markerList = [];
    // 避免跨页复用旧实例
    this.mapLibreMap = null;
  }

  /**
   * 页面卸载
   */
  aboutToDisappear() {
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
    }
    this.mapLibreMap = null;
  }

  /**
   * 页面隐藏：与卸载同等对待，保障二次进入的幂等
   */
  onPageHide() {
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
    }
    this.mapLibreMap = null;
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
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
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
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
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
      
      const blueStyle: InfoWindowStyle = {
        backgroundColor: '#2196F3',
        titleFontColor: '#FFFFFF',
        snippetFontColor: '#E3F2FD',
        borderRadius: 12,
        padding: 16,
        shadowRadius: 12,
        shadowColor: 'rgba(33, 150, 243, 0.4)',
        animated: true
      };
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('蓝色主题 ✨')
          .snippet('使用蓝色背景和白色文字，圆角 12px')
          .draggable(false)
          .infoWindowStyle(blueStyle)
      );
      
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
      
      const greenStyle: InfoWindowStyle = {
        backgroundColor: '#4CAF50',
        titleFontColor: '#FFFFFF',
        snippetFontColor: '#C8E6C9',
        titleFontSize: 18,
        snippetFontSize: 15,
        borderRadius: 8,
        padding: 14,
        shadowRadius: 10,
        shadowColor: 'rgba(76, 175, 80, 0.3)'
      };
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('绿色主题 🌿')
          .snippet('清新的绿色配色方案，适合生态或健康相关内容')
          .draggable(false)
          .infoWindowStyle(greenStyle)
      );
      
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
      
      const largeFontStyle: InfoWindowStyle = {
        titleFontSize: 20,
        titleFontColor: '#FF9800',
        snippetFontSize: 16,
        snippetFontColor: '#F57C00',
        padding: 18,
        maxWidth: 320,
        borderRadius: 10
      };
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('大字体 📢')
          .snippet('使用更大的字体以提高可读性，适合重要信息')
          .draggable(false)
          .infoWindowStyle(largeFontStyle)
      );
      
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
      
      const compactStyle: InfoWindowStyle = {
        titleFontSize: 14,
        snippetFontSize: 12,
        padding: 8,
        maxWidth: 200,
        borderRadius: 6
      };
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('紧凑样式')
          .snippet('小巧紧凑的样式，占用更少空间')
          .draggable(false)
          .infoWindowStyle(compactStyle)
      );
      
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
   * 添加带缩略图的 InfoWindow
   */
  private async addInfoWindowWithThumbnail(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const thumbnailStyle: InfoWindowStyle = {
        thumbnailImage: $r('app.media.startIcon'), // 使用应用图标作为示例
        backgroundColor: '#E91E63',
        titleFontColor: '#FFFFFF',
        snippetFontColor: '#F8BBD0',
        padding: 12,
        borderRadius: 10
      };
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('带缩略图 🖼️')
          .snippet('在标题旁边显示缩略图，适合展示地点照片或图标')
          .draggable(false)
          .infoWindowStyle(thumbnailStyle)
      );
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加带缩略图 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added InfoWindow with thumbnail');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 添加带关闭按钮的 InfoWindow
   */
  private async addInfoWindowWithCloseButton(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const closeButtonStyle: InfoWindowStyle = {
        showCloseButton: true,
        backgroundColor: '#673AB7',
        titleFontColor: '#FFFFFF',
        snippetFontColor: '#D1C4E9',
        padding: 10,
        borderRadius: 8
      };
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('带关闭按钮 ❌')
          .snippet('右上角有关闭按钮，点击可关闭 InfoWindow')
          .draggable(false)
          .infoWindowStyle(closeButtonStyle)
      );
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加带关闭按钮 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added InfoWindow with close button');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 添加自定义偏移量的 InfoWindow
   */
  private async addInfoWindowWithOffset(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const offsetStyle: InfoWindowStyle = {
        offsetX: 50,  // 向右偏移 50 像素
        offsetY: -20, // 向上偏移 20 像素
        backgroundColor: '#795548',
        titleFontColor: '#FFFFFF',
        snippetFontColor: '#D7CCC8',
        padding: 12,
        borderRadius: 8
      };
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('自定义偏移 ↗️')
          .snippet('InfoWindow 向右偏移 50px，向上偏移 20px')
          .draggable(false)
          .infoWindowStyle(offsetStyle)
      );
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加自定义偏移 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added InfoWindow with offset');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 添加圆角和阴影的 InfoWindow
   */
  private async addInfoWindowWithShadow(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      const position = this.getRandomPosition();
      
      const shadowStyle: InfoWindowStyle = {
        backgroundColor: '#607D8B',
        titleFontColor: '#FFFFFF',
        snippetFontColor: '#CFD8DC',
        borderRadius: 16,
        padding: 16,
        shadowRadius: 20,
        shadowColor: 'rgba(0, 0, 0, 0.5)',
        maxWidth: 300
      };
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('圆角 + 阴影 ⚫')
          .snippet('大圆角（16px）+ 深阴影效果，突出显示')
          .draggable(false)
          .infoWindowStyle(shadowStyle)
      );
      
      this.markerList.push(marker);
      this.markerCount++;
      
      marker.showInfoWindow();
      this.infoWindowCount++;
      
      this.statusMessage = `✅ 已添加圆角阴影 InfoWindow (${this.markerCount})`;
      hilog.info(DOMAIN, 'InfoWindowTestPage', 'Added InfoWindow with shadow');
    } catch (error) {
      this.statusMessage = `❌ 添加失败: ${error.message}`;
      hilog.error(DOMAIN, 'InfoWindowTestPage', `Failed to add InfoWindow: ${error.message}`);
    }
  }

  /**
   * 添加随机位置的 InfoWindow（不同颜色主题）
   */
  private async addInfoWindowAtCorner(corner: string): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      let title: string;
      let backgroundColor: string;
      let snippetFontColor: string;
      
      switch (corner) {
        case 'topLeft':
          title = '随机位置 - 红色主题 🔴';
          backgroundColor = '#FF5722';
          snippetFontColor = '#FFCCBC';
          break;
        case 'topRight':
          title = '随机位置 - 橙色主题 🟠';
          backgroundColor = '#FF6F00';
          snippetFontColor = '#FFE0B2';
          break;
        default:
          return;
      }
      
      // 使用随机位置
      const position = this.getRandomPosition();
      
      const cornerStyle: InfoWindowStyle = {
        backgroundColor: backgroundColor,
        titleFontColor: '#FFFFFF',
        snippetFontColor: snippetFontColor,
        padding: 12,
        borderRadius: 8,
        maxWidth: 250
      };
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title(title)
          .snippet('随机位置测试\nInfoWindow 在地图上随机显示')
          .draggable(false)
          .infoWindowStyle(cornerStyle)
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
    
    const lat: number = baseLat + (Math.random() - 0.5) * range;
    const lng: number = baseLng + (Math.random() - 0.5) * range;
    
    return new maplibre.LatLng(lat, lng);
  }
}
