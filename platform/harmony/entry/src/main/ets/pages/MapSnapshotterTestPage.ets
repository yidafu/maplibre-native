/**
 * MapSnapshotterTestPage - 地图快照测试页面
 *
 * 测试内容：
 * - 创建快照
 * - 不同尺寸和像素比的快照
 * - 自定义相机位置
 * - 取消快照
 */

import {
  MapSnapshotter,
  SnapshotOptions,
  SnapshotOptionsBuilder,
  SnapshotReadyCallback,
  SnapshotErrorHandler
} from 'maplibre_harmony/src/main/ets/maps/snapshot';
import { maplibre } from 'maplibre_harmony';
import { MapSnapshot } from 'maplibre_harmony/src/main/ets/maps/snapshot';
import { createLatLng } from 'maplibre_harmony/src/main/ets/maps/geometry/LatLng';
import { LatLngBounds } from 'maplibre_harmony/src/main/ets/maps/geometry/LatLngBounds';
import { CameraPosition } from 'maplibre_harmony/src/main/ets/maps/camera/CameraPosition';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import image from '@ohos.multimedia.image';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

class ErrorCallback implements SnapshotErrorHandler {
  private page: MapSnapshotterTestPage;

  constructor(page: MapSnapshotterTestPage) {
    this.page = page
  }

  onError(error: string) {
    this.page.status = `❌ 快照生成失败: ${error}`;

    hilog.error(DOMAIN, 'MapSnapshotterTest', `Snapshot error: ${error}`);

    promptAction.showToast({
      message: `生成失败: ${error}`,
      duration: 3000
    });
  }
}

class ReadCallback implements SnapshotReadyCallback {
  private page: MapSnapshotterTestPage

  constructor(page: MapSnapshotterTestPage) {
    this.page = page
  }

  onSnapshotReady(snapshot: MapSnapshot) {
    this.page.snapshotCount++;
    this.page.status = `✅ 快照生成成功！（${snapshot.width}x${snapshot.height}）`;
    this.page.snapshotImage = snapshot.getImage();

    hilog.info(DOMAIN, 'MapSnapshotterTest',
      `Snapshot ready: ${snapshot.width}x${snapshot.height}, ` +
        `attributions: ${snapshot.getAttributions().length}`);

    promptAction.showToast({
      message: '快照生成成功！',
      duration: 2000
    });

  }
}

@Entry
@Component
struct MapSnapshotterTestPage {
  @State snapshotImage: image.PixelMap | null = null;
  @State status: string = '等待操作...';
  @State snapshotCount: number = 0;

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('地图快照测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })

        Blank()

        Button('返回')
          .onClick(() => {
            hilog.info(DOMAIN, 'MapSnapshotterTest', 'Navigating back');
            router.back();
          })
          .margin({ right: 16 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F7F7F7')

      // 快照预览区域
      if (this.snapshotImage) {
        Image(this.snapshotImage)
          .width('100%')
          .height('40%')
          .objectFit(ImageFit.Contain)
          .backgroundColor('#EEEEEE')
      } else {
        Stack() {
          Text('快照预览')
            .fontSize(16)
            .fontColor(Color.Gray)
        }
        .width('100%')
        .height('40%')
        .backgroundColor('#F5F5F5')
        .alignContent(Alignment.Center)
      }

      // 控制区
      Scroll() {
        Column({ space: 12 }) {
          Text('快照测试')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')

          // 测试按钮
          Button('生成标准快照（1080x1920）')
            .width('90%')
            .onClick(() => {
              this.testStandardSnapshot();
            })

          Button('生成高分辨率快照（2x）')
            .width('90%')
            .onClick(() => {
              this.testHighResSnapshot();
            })

          Button('生成小尺寸快照（540x960）')
            .width('90%')
            .onClick(() => {
              this.testSmallSnapshot();
            })

          Button('自定义位置快照（北京）')
            .width('90%')
            .onClick(() => {
              this.testCustomLocationSnapshot();
            })

          Button('边界区域快照（杭州西湖）')
            .width('90%')
            .onClick(() => {
              this.testBoundsSnapshot();
            })

          Divider()

          // 状态显示
          Text('状态')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')

          Text(this.status)
            .fontSize(14)
            .width('90%')
            .fontColor(Color.Gray)

          Text(`已生成快照: ${this.snapshotCount}`)
            .fontSize(14)
            .width('90%')

          Divider()

          // 说明
          Text('说明')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')

          Text('• MapSnapshotter 在后台渲染地图\n' +
            '• 可指定尺寸、像素比、相机位置\n' +
            '• 生成高质量快照用于分享或缓存\n' +
            '• 支持自定义样式和区域范围')
            .fontSize(12)
            .width('90%')
            .fontColor(Color.Gray)
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 生成标准快照
   */
  private testStandardSnapshot(): void {
    this.status = '正在生成标准快照...';
    hilog.info(DOMAIN, 'MapSnapshotterTest', 'Creating standard snapshot');

    const cameraPos: CameraPosition = {
      target: createLatLng(30.2741, 120.1551),
      zoom: 12,
      bearing: 0,
      tilt: 0
    } as CameraPosition;

    const options: SnapshotOptions = {
      size: { width: 1080, height: 1920 },
      pixelRatio: 1.0,
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      cameraPosition: cameraPos,
      showLogo: true
    };

    this.createSnapshot(options);
  }

  /**
   * 生成高分辨率快照
   */
  private testHighResSnapshot(): void {
    this.status = '正在生成高分辨率快照（2x）...';
    hilog.info(DOMAIN, 'MapSnapshotterTest', 'Creating high-res snapshot');

    const cameraPos: CameraPosition = {
      target: createLatLng(30.2741, 120.1551),
      zoom: 13,
      bearing: 0,
      tilt: 0
    } as CameraPosition;

    const options = new SnapshotOptionsBuilder(1080, 1920)
      .withPixelRatio(2.0)
      .withStyleUrl('https://demotiles.maplibre.org/style.json')
      .withCameraPosition(cameraPos)
      .withShowLogo(true)
      .build();

    this.createSnapshot(options);
  }

  /**
   * 生成小尺寸快照
   */
  private testSmallSnapshot(): void {
    this.status = '正在生成小尺寸快照...';
    hilog.info(DOMAIN, 'MapSnapshotterTest', 'Creating small snapshot');

    const options: SnapshotOptions = {
      size: { width: 540, height: 960 },
      pixelRatio: 1.0,
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      cameraPosition: {
        target: createLatLng(30.2741, 120.1551),
        zoom: 11,
        bearing: 0,
        tilt: 0
      }
    };

    this.createSnapshot(options);
  }

  /**
   * 自定义位置快照（北京）
   */
  private testCustomLocationSnapshot(): void {
    this.status = '正在生成北京快照...';
    hilog.info(DOMAIN, 'MapSnapshotterTest', 'Creating Beijing snapshot');

    const options: SnapshotOptions = {
      size: { width: 1080, height: 1920 },
      pixelRatio: 1.5,
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      cameraPosition: {
        target: createLatLng(39.9042, 116.4074), // 北京天安门
        zoom: 14,
        bearing: 45,
        tilt: 30
      },
      showLogo: true
    };

    this.createSnapshot(options);
  }

  /**
   * 边界区域快照（杭州西湖）
   */
  private testBoundsSnapshot(): void {
    this.status = '正在生成杭州西湖区域快照...';
    hilog.info(DOMAIN, 'MapSnapshotterTest', 'Creating West Lake snapshot');

    // 定义西湖区域边界
    const southwest = createLatLng(30.23, 120.12);
    const northeast = createLatLng(30.27, 120.17);
    const bounds = LatLngBounds.fromLatLngs(southwest, northeast);

    const options: SnapshotOptions = {
      size: { width: 1080, height: 1920 },
      pixelRatio: 1.0,
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      region: bounds,
      showLogo: true
    };

    this.createSnapshot(options);
  }

  /**
   * 创建快照的通用方法
   */
  private createSnapshot(options: SnapshotOptions): void {
    try {
      const snapshotter = new MapSnapshotter(options);

      const readyCallback: SnapshotReadyCallback = new ReadCallback(this);

      const errorCallback = new ErrorCallback(this);

      snapshotter.start(readyCallback as SnapshotReadyCallback, errorCallback as SnapshotErrorHandler);

    } catch (error) {
      this.status = `❌ 创建快照器失败: ${error}`;

      hilog.error(DOMAIN, 'MapSnapshotterTest', `Failed to create snapshotter: ${error}`);

      promptAction.showToast({
        message: `创建失败: ${error}`,
        duration: 3000
      });
    }
  }
}

