/**
 * Map Snapshotter Test Page
 * 地图快照测试页面
 *
 * 参考: platform/android/.../snapshot/MapSnapshotterActivity.kt
 *
 * 测试功能:
 * - 使用MapSnapshotter生成地图快照
 * - 网格布局显示多个快照
 * - 测试不同位置和缩放级别的快照
 */

import { TestPageLayout } from '../common/TestPageLayout';
import {
  CameraPosition,
  LatLng,
  MapLibreMap,
  MapSnapshot,
  MapSnapshotter,
  MapSnapshotterObserver,
  MapView,
  SnapshotErrorHandler,
  SnapshotOptions,
  SnapshotReadyCallback
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast, TEST_LOCATIONS } from '../common/TestUtils';
import { ImageSaveUtil } from '../../utils/ImageSaveUtil';
import { image } from '@kit.ImageKit';

interface LocationInfo {
  name: string;
  latitude: number;
  longitude: number;
  zoom: number;
}

/**
 * Observer 实现类
 */
class MapSnapshotterObserverImpl implements MapSnapshotterObserver {
  page: MapSnapshotterTestPage;

  constructor(page: MapSnapshotterTestPage) {
    this.page = page;
  }

  onDidFinishLoadingStyle(): void {
    this.page.styleLoadCount++;
    console.info('[MapSnapshotterTestPage] Style loaded, count:', this.page.styleLoadCount);
  }

  onStyleImageMissing(imageName: string): void {
    this.page.missingImageCount++;
    console.warn('[MapSnapshotterTestPage] Missing image:', imageName);
  }
}

@Entry
@Component
struct MapSnapshotterTestPage {
  private mapController: MapLibreMap | null = null;
  @State private snapshots: PixelMap[] = [];
  @State private snapshotCount: number = 0;
  @State private isCapturing: boolean = false;
  private currentSnapshotPixelMap: image.PixelMap | null = null;
  private currentSnapshotName: string = '';
  @State public styleLoadCount: number = 0;
  @State public missingImageCount: number = 0;

  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    // this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    // this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 5);
  };

  /**
   * 创建 Observer 实现
   */
  private createObserver(): MapSnapshotterObserverImpl {
    return new MapSnapshotterObserverImpl(this);
  }
  /**
   * 捕获快照（使用MapSnapshotter）
   */
  private captureSnapshot = async (lat: number, lng: number, zoom: number, name: string): Promise<void> => {
    try {
      const cameraPosition: CameraPosition = {
        target: new LatLng(lat, lng),
        zoom: zoom,
        bearing: 0,
        tilt: 0
      };

      const options: SnapshotOptions = {
        size: { width: 400, height: 300 },
        pixelRatio: 2.0,
        styleUrl: DEFAULT_STYLE_URLS.streets,
        cameraPosition: cameraPosition,
        showLogo: true
      };

      const snapshotter = new MapSnapshotter(options);

      // 设置 Observer 监听样式加载
      snapshotter.setObserver(this.createObserver());

      class ReadyCallback implements SnapshotReadyCallback {
        page: MapSnapshotterTestPage;
        snapshotter: MapSnapshotter;
        name: string;

        constructor(page: MapSnapshotterTestPage, snapshotter: MapSnapshotter, name: string) {
          this.page = page;
          this.snapshotter = snapshotter;
          this.name = name;
        }

        onSnapshotReady(snapshot: MapSnapshot): void {
          const pixelMap = snapshot.getImage();
          this.page.snapshots.push(pixelMap);
          this.page.snapshotCount++;
          showToast(`快照 ${this.page.snapshotCount} 已生成: ${this.name}`);

          // 保存当前快照信息，并显示保存确认对话框
          this.page.currentSnapshotPixelMap = pixelMap;
          this.page.currentSnapshotName = this.name;
          this.page.showSaveConfirmDialog();

          this.snapshotter.cancel();
        }
      }

      class ErrorCallback implements SnapshotErrorHandler {
        onError(error: string): void {
          console.error('[MapSnapshotterTestPage] Snapshot failed:', error);
          showToast(`快照失败: ${error}`);
        }
      }

      snapshotter.start(new ReadyCallback(this, snapshotter, name), new ErrorCallback());
    } catch (e) {
      const error = e as Error;
      console.error('[MapSnapshotterTestPage] Snapshot creation failed:', error.message || String(e));
      showToast(`创建快照失败: ${error.message || String(e)}`);
    }
  };
  /**
   * 生成当前视图快照
   */
  private captureCurrentView = async (): Promise<void> => {
    if (this.isCapturing || !this.mapController) {
      return;
    }

    this.isCapturing = true;
    const latLng = this.mapController.getLatLng();
    const zoom = this.mapController.getZoom();

    await this.captureSnapshot(latLng.latitude, latLng.longitude, zoom, '当前视图');
    this.isCapturing = false;
  };
  /**
   * 生成多个快照
   */
  private generateMultipleSnapshots = async (): Promise<void> => {
    if (this.isCapturing) {
      return;
    }

    this.isCapturing = true;

    const locations: LocationInfo[] = [
      {
        latitude: TEST_LOCATIONS.beijing.latitude,
        longitude: TEST_LOCATIONS.beijing.longitude,
        name: '北京',
        zoom: 12
      },
      {
        latitude: TEST_LOCATIONS.shanghai.latitude,
        longitude: TEST_LOCATIONS.shanghai.longitude,
        name: '上海',
        zoom: 12
      },
      {
        latitude: TEST_LOCATIONS.guangzhou.latitude,
        longitude: TEST_LOCATIONS.guangzhou.longitude,
        name: '广州',
        zoom: 12
      },
      {
        latitude: TEST_LOCATIONS.shenzhen.latitude,
        longitude: TEST_LOCATIONS.shenzhen.longitude,
        name: '深圳',
        zoom: 14
      }
    ];

    for (let loc of locations) {
      await this.captureSnapshot(loc.latitude, loc.longitude, loc.zoom, loc.name);
      await new Promise<void>(resolve => setTimeout(resolve, 500)); // 间隔500ms
    }

    this.isCapturing = false;
    showToast('批量快照完成');
  };
  /**
   * 清除所有快照
   */
  private clearSnapshots = (): void => {
    this.snapshots = [];
    this.snapshotCount = 0;
    showToast('快照已清除');
  };
  /**
   * 显示保存确认对话框
   */
  private showSaveConfirmDialog = (): void => {
    AlertDialog.show({
      title: '保存快照',
      message: `是否将快照 "${this.currentSnapshotName}" 保存到相册？`,
      primaryButton: {
        value: '取消',
        action: () => {
          // 用户取消，清空当前快照信息
          this.currentSnapshotPixelMap = null;
          this.currentSnapshotName = '';
        }
      },
      secondaryButton: {
        value: '保存',
        action: async () => {
          await this.saveSnapshotToGallery();
        }
      }
    });
  };
  /**
   * 使用 PhotoViewPicker 保存快照到相册
   * 无需权限声明，系统会拉起相册选择器让用户选择保存位置
   */
  private saveSnapshotToGallery = async (): Promise<void> => {
    if (!this.currentSnapshotPixelMap) {
      showToast('没有可保存的快照');
      return;
    }

    try {
      // 使用 PhotoViewPicker 保存到相册（无需权限）
      const fileName = `maplibre_${this.currentSnapshotName}_${Date.now()}`;
      const result = await ImageSaveUtil.savePixelMapToGalleryWithPicker(
        this.currentSnapshotPixelMap,
        fileName
      );

      if (result.success) {
        showToast(`快照 "${this.currentSnapshotName}" 已保存到相册`);
      } else {
        // 如果用户取消，不显示错误提示
        if (result.message !== '用户取消保存') {
          showToast(result.message);
        }
      }

      // 清空当前快照信息
      this.currentSnapshotPixelMap = null;
      this.currentSnapshotName = '';
    } catch (e) {
      const error = e as Error;
      console.error(`保存快照到相册失败: ${error.message || String(e)}`);
      showToast(`保存失败: ${error.message || String(e)}`);

      // 清空当前快照信息
      this.currentSnapshotPixelMap = null;
      this.currentSnapshotName = '';
    }
  };

  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
  }

  @Builder
  buildControlPanel() {
    Scroll() {
      Column({ space: 12 }) {
        Text('MapSnapshotter 快照')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Text(`已生成快照: ${this.snapshotCount}`)
          .fontSize(14)
          .fontColor('#666')

        Text(`样式加载次数: ${this.styleLoadCount}`)
          .fontSize(12)
          .fontColor('#999')

        Text(`缺失图片: ${this.missingImageCount}`)
          .fontSize(12)
          .fontColor('#999')

        Button(this.isCapturing ? '捕获中...' : '捕获当前视图')
          .width('100%')
          .enabled(!this.isCapturing)
          .onClick(() => this.captureCurrentView())

        Button('生成4个城市快照')
          .width('100%')
          .backgroundColor('#4CAF50')
          .enabled(!this.isCapturing)
          .onClick(() => this.generateMultipleSnapshots())

        Button('清除快照')
          .width('100%')
          .backgroundColor('#FF6B6B')
          .enabled(this.snapshots.length > 0)
          .onClick(() => this.clearSnapshots())

        Divider()

        Text('快照预览')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Grid() {
          ForEach(this.snapshots, (snapshot: PixelMap, index: number) => {
            GridItem() {
              Column() {
                Image(snapshot)
                  .width('100%')
                  .height(100)
                  .objectFit(ImageFit.Cover)
                  .border({ width: 1, color: '#DDD' })

                Text(`#${index + 1}`)
                  .fontSize(10)
                  .fontColor('#666')
              }
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')

        Text('说明: 使用MapSnapshotter后台渲染地图')
          .fontSize(12)
          .fontColor('#666')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(16)
    }
    .height('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'Map Snapshotter',
        description: '地图快照',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}
