/**
 * Snapshot Basic Test Page
 * 基础截图功能测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/imagegenerator/SnapshotActivity.kt
 * 
 * 功能:
 * - 地图截图生成
 * - 截图保存
 * - 不同参数截图（尺寸、质量）
 * 
 * 注意: 截图功能需要 MapSnapshotter 或 screenshot API 支持
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapLibreMap, MapView } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG  } from '../common/TestUtils';
import { image } from '@kit.ImageKit';
import { componentSnapshot } from '@kit.ArkUI';
import { ImageSaveUtil } from '../../utils/ImageSaveUtil';

@Entry
@Component
struct SnapshotBasicTestPage {
  private mapController: MapLibreMap | null = null;
  @State private hasSnapshot: boolean = false;
  @State private snapshotCount: number = 0;
  @State private lastSnapshotSize: string = '';
  private mapComponentId: string = 'map-snapshot-view';
  private currentPixelMap: image.PixelMap | null = null;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[SnapshotBasicTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.bright);
    
    // 设置初始位置
    map.jumpTo(0, 39.9, 116.4, 0, 10);
  };
  
  /**
   * 截取地图当前视图
   */
  private takeSnapshot = async (): Promise<void> => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      showToast('正在截图...');
      
      // 使用 ArkUI 的 componentSnapshot API 截图
      // 需要给 NativeMapView 设置一个 ID
      const pixelMap = await componentSnapshot.get(this.mapComponentId);
      
      if (pixelMap) {
        const imageInfo = await pixelMap.getImageInfo();
        this.lastSnapshotSize = `${imageInfo.size.width} x ${imageInfo.size.height}`;
        this.snapshotCount++;
        this.hasSnapshot = true;
        
        showToast(`截图成功! ${this.lastSnapshotSize}`);
        
        // 保存当前的 pixelMap，以便用户选择保存时使用
        this.currentPixelMap = pixelMap;
        
        // 弹出对话框询问用户是否保存
        this.showSaveConfirmDialog();
      } else {
        showToast('截图失败');
      }
    } catch (error) {
      console.error(`截图失败: ${error}`);
      showToast(`截图失败: ${error}`);
    }
  };
  
  /**
   * 显示保存确认对话框
   */
  private showSaveConfirmDialog = (): void => {
    AlertDialog.show({
      title: '保存截图',
      message: '是否将截图保存到相册？',
      primaryButton: {
        value: '取消',
        action: () => {
          // 用户取消，释放 pixelMap
          if (this.currentPixelMap) {
            this.currentPixelMap.release();
            this.currentPixelMap = null;
          }
        }
      },
      secondaryButton: {
        value: '保存',
        action: async () => {
          await this.saveToGallery();
        }
      }
    });
  };
  
  /**
   * 使用 PhotoViewPicker 保存截图到相册
   * 无需权限声明，系统会拉起相册选择器让用户选择保存位置
   */
  private saveToGallery = async (): Promise<void> => {
    if (!this.currentPixelMap) {
      showToast('没有可保存的截图');
      return;
    }
    
    try {
      // 使用 PhotoViewPicker 保存到相册（无需权限）
      const result = await ImageSaveUtil.savePixelMapToGalleryWithPicker(
        this.currentPixelMap,
        `maplibre_snapshot_${Date.now()}`
      );
      
      if (result.success) {
        showToast('截图已保存到相册');
      } else {
        // 如果用户取消，不显示错误提示
        if (result.message !== '用户取消保存') {
          showToast(result.message);
        }
      }
      
      // 释放 pixelMap
      this.currentPixelMap.release();
      this.currentPixelMap = null;
    } catch (error) {
      console.error(`保存到相册失败: ${error}`);
      showToast(`保存失败: ${error}`);
      
      // 释放 pixelMap
      if (this.currentPixelMap) {
        this.currentPixelMap.release();
        this.currentPixelMap = null;
      }
    }
  };
  
  /**
   * 快速截图（使用默认参数）
   */
  private quickSnapshot = (): void => {
    this.takeSnapshot();
  };
  
  /**
   * 高质量截图
   */
  private highQualitySnapshot = (): void => {
    // 可以在实际实现中调整截图参数
    showToast('高质量截图模式');
    this.takeSnapshot();
  };
  
  /**
   * 小尺寸截图
   */
  private smallSizeSnapshot = (): void => {
    showToast('小尺寸截图模式（演示）');
    this.takeSnapshot();
  };
  
  /**
   * 清除统计
   */
  private clearStats = (): void => {
    this.snapshotCount = 0;
    this.hasSnapshot = false;
    this.lastSnapshotSize = '';
    showToast('已清除统计');
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('快速截图')
      .fontSize(14)
      .onClick(this.quickSnapshot);
    
    Button('高质量')
      .fontSize(14)
      .onClick(this.highQualitySnapshot);
    
    Button('小尺寸')
      .fontSize(14)
      .onClick(this.smallSizeSnapshot);
    
    Button('清除统计')
      .fontSize(14)
      .backgroundColor('#FF9800')
      .enabled(this.hasSnapshot)
      .onClick(this.clearStats);
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('地图截图')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 });
      
      Text(`截图次数: ${this.snapshotCount}`)
        .fontSize(12)
        .fontColor('#666');
      
      if (this.lastSnapshotSize) {
        Text(`最后尺寸: ${this.lastSnapshotSize}`)
          .fontSize(12)
          .fontColor('#666');
      }
      
      Divider().margin({ top: 8, bottom: 8 });
      
      Text('功能说明')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 });
      
      Text('• 快速截图 - 默认参数')
        .fontSize(11)
        .fontColor('#666');
      
      Text('• 高质量 - 高质量截图')
        .fontSize(11)
        .fontColor('#666');
      
      Text('• 小尺寸 - 缩略图模式')
        .fontSize(11)
        .fontColor('#666');
      
      Divider().margin({ top: 8, bottom: 8 });
      
      Text('技术说明')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 });
      
      Text('使用 componentSnapshot API 实现地图截图功能')
        .fontSize(10)
        .fontColor('#999')
        .margin({ bottom: 2 });
      
      Text('截图会保存当前地图视图的完整内容')
        .fontSize(10)
        .fontColor('#999');
    }
    .alignItems(HorizontalAlign.Start);
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: this.onMapReady,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
      .width('100%')
      .height('100%')
      .id(this.mapComponentId);
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Snapshot',
        description: '地图截图',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        controlPanel: (): void => this.controlPanelBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}

