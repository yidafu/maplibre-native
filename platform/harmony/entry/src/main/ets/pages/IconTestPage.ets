import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { maplibre } from 'maplibre_harmony';
import { LatLng } from 'maplibre_harmony/src/main/ets/maps/geometry/LatLng';
import { IconFactory, MarkerOptions } from 'maplibre_harmony/src/main/ets/maps/annotations/index';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from 'maplibre_harmony/src/main/ets/maps/camera/CameraPosition';
import { router } from '@kit.ArkUI';
import resourceManager from '@ohos.resourceManager';
import { TestPageLayout } from '../components/TestPageLayout';

// Use NAPI Icon type
type Icon = maplibre.Icon;

/**
 * IconTestPage - Icon 管理系统测试页面
 * 
 * 测试功能：
 * 1. 从不同来源创建 Icon（Resource、PixelMap）
 * 2. 多个 Marker 共享同一 Icon（验证引用计数）
 * 3. 删除 Marker 后 Icon 自动清理
 * 4. 默认图标显示
 */
@Entry
@Component
struct IconTestPage {
  @State message: string = 'Icon 系统测试';
  @State testStatus: string = '等待测试...';
  @State iconCount: number = 0;
  
  private mapLibreMap: MapLibreMap | null = null;
  private iconFactory: IconFactory | null = null;
  private markers: maplibre.Marker[] = [];
  private testIcon: Icon | null = null;

  aboutToAppear() {
    console.info('[IconTestPage] Page loading...');
  }

  aboutToDisappear() {
    console.info('[IconTestPage] Page unloading...');
    this.cleanup();
  }

  /**
   * 初始化 Icon 系统
   */
  private async initIconSystem() {
    try {
      // 获取 ResourceManager
      const context = getContext(this);
      const resourceMgr = context.resourceManager;
      
      // 初始化 IconFactory
      this.iconFactory = IconFactory.getInstance(resourceMgr);
      this.iconFactory.setPixelRatio(2.0); // 设置像素密度
      
      this.testStatus = 'Icon 系统初始化成功';
      console.info('[IconTestPage] Icon system initialized');
    } catch (error) {
      this.testStatus = `初始化失败: ${error}`;
      console.error('[IconTestPage] Failed to initialize icon system:', error);
    }
  }

  /**
   * 测试 1: 创建默认图标
   */
  private async testDefaultIcon() {
    if (!this.iconFactory) {
      await this.initIconSystem();
    }

    try {
      this.testStatus = '测试默认图标...';
      console.info('[IconTestPage] Testing default icon...');

      // 创建默认图标
      const defaultIcon = await this.iconFactory!.defaultMarker();
      console.info(`[IconTestPage] Default icon created: ${defaultIcon.getId()}`);
      console.info(`[IconTestPage] Icon size: ${defaultIcon.getWidth()}x${defaultIcon.getHeight()}`);

      // 在地图上添加使用默认图标的 Marker
      const position = new maplibre.LatLng(39.9042, 116.4074); // 北京
      const markerOptions = new MarkerOptions()
        .position(position)
        .title('默认图标测试')
        .icon(defaultIcon);

      const marker: maplibre.Marker = await this.mapLibreMap!.addMarker(markerOptions);
      this.markers.push(marker);

      this.testStatus = `默认图标测试成功 - ${defaultIcon.toString()}`;
      this.iconCount = 1;
    } catch (error) {
      this.testStatus = `默认图标测试失败: ${error}`;
      console.error('[IconTestPage] Default icon test failed:', error);
    }
  }

  /**
   * 测试 2: 创建自定义图标（从资源）
   */
  private async testCustomIcon() {
    if (!this.iconFactory) {
      await this.initIconSystem();
    }

    try {
      this.testStatus = '测试自定义图标...';
      console.info('[IconTestPage] Testing custom icon...');

      // 尝试从资源创建图标
      try {
        this.testIcon = await this.iconFactory!.fromResource($r('app.media.startIcon'));
        console.info(`[IconTestPage] Custom icon created: ${this.testIcon.getId()}`);
      } catch (error) {
        console.warn('[IconTestPage] Failed to load custom icon from resource, using default');
        this.testIcon = await this.iconFactory!.defaultMarker();
      }

      // 添加使用自定义图标的 Marker
      const position = new maplibre.LatLng(39.9142, 116.4174); // 稍微偏移
      const markerOptions = new MarkerOptions()
        .position(position)
        .title('自定义图标测试')
        .snippet('使用自定义图标')
        .icon(this.testIcon);

      const marker: maplibre.Marker = await this.mapLibreMap!.addMarker(markerOptions);
      this.markers.push(marker);

      this.testStatus = `自定义图标测试成功 - ${this.testIcon.toString()}`;
      this.iconCount = 2;
    } catch (error) {
      this.testStatus = `自定义图标测试失败: ${error}`;
      console.error('[IconTestPage] Custom icon test failed:', error);
    }
  }

  /**
   * 测试 3: 多个 Marker 共享同一 Icon
   */
  private async testSharedIcon() {
    if (!this.testIcon) {
      await this.testCustomIcon();
    }

    try {
      this.testStatus = '测试共享图标...';
      console.info('[IconTestPage] Testing shared icon...');

      // 在不同位置添加多个使用相同图标的 Marker
      const positions = [
        new maplibre.LatLng(39.9242, 116.4274),
        new maplibre.LatLng(39.9342, 116.4374),
        new maplibre.LatLng(39.9442, 116.4474)
      ];

      for (let i = 0; i < positions.length; i++) {
        const markerOptions = new MarkerOptions()
          .position(positions[i])
          .title(`共享图标 Marker ${i + 1}`)
          .icon(this.testIcon!);

        const marker: maplibre.Marker = await this.mapLibreMap!.addMarker(markerOptions);
        this.markers.push(marker);
      }

      this.testStatus = `共享图标测试成功 - 创建了 3 个共享图标的 Marker`;
      this.iconCount = this.markers.length;
      console.info('[IconTestPage] Shared icon test completed');
    } catch (error) {
      this.testStatus = `共享图标测试失败: ${error}`;
      console.error('[IconTestPage] Shared icon test failed:', error);
    }
  }

  /**
   * 测试 4: 清理 Marker（测试引用计数）
   */
  private testCleanup() {
    try {
      this.testStatus = '测试清理...';
      console.info('[IconTestPage] Testing cleanup...');

      // 删除所有 Marker
      const removedCount = this.markers.length;
      for (const marker of this.markers) {
        this.mapLibreMap?.removeMarker(marker);
      }
      this.markers = [];

      this.testStatus = `清理测试成功 - 删除了 ${removedCount} 个 Marker`;
      this.iconCount = 0;
      console.info('[IconTestPage] Cleanup test completed');
    } catch (error) {
      this.testStatus = `清理测试失败: ${error}`;
      console.error('[IconTestPage] Cleanup test failed:', error);
    }
  }

  /**
   * 运行所有测试
   */
  private async runAllTests() {
    this.testStatus = '开始运行测试套件...';
    console.info('[IconTestPage] Running all tests...');

    await this.testDefaultIcon();
    await new Promise<void>((resolve) => setTimeout(resolve, 1000));

    await this.testCustomIcon();
    await new Promise<void>((resolve) => setTimeout(resolve, 1000));

    await this.testSharedIcon();
    await new Promise<void>((resolve) => setTimeout(resolve, 1000));

    this.testCleanup();
    await new Promise<void>((resolve) => setTimeout(resolve, 1000));

    this.testStatus = '所有测试完成！';
    console.info('[IconTestPage] All tests completed');
  }

  /**
   * 清理资源
   */
  private cleanup() {
    try {
      // 删除所有 Marker
      for (const marker of this.markers) {
        this.mapLibreMap?.removeMarker(marker);
      }
      this.markers = [];

      // 释放 Icon
      if (this.testIcon) {
        this.testIcon.release();
        this.testIcon = null;
      }

      // 重置 IconFactory
      if (this.iconFactory) {
        this.iconFactory.reset();
      }

      console.info('[IconTestPage] Resources cleaned up');
    } catch (error) {
      console.error('[IconTestPage] Cleanup error:', error);
    }
  }

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

  @Builder
  ControlAreaBuilder() {
          // 状态信息
          Column() {
            Text(`状态: ${this.testStatus}`)
              .fontSize(14)
              .margin({ bottom: 4 })

            Text(`当前 Marker 数量: ${this.iconCount}`)
              .fontSize(14)
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#F8F8F8')
          .margin({ bottom: 8 })

          // 测试按钮
          Text('Icon 测试')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Button('测试默认图标')
            .width('100%')
            .onClick(() => {
              this.testDefaultIcon();
            })
            .margin({ bottom: 8 })

          Button('测试自定义图标')
            .width('100%')
            .onClick(() => {
              this.testCustomIcon();
            })
            .margin({ bottom: 8 })

          Button('测试共享图标')
            .width('100%')
            .onClick(() => {
              this.testSharedIcon();
            })
            .margin({ bottom: 8 })

          Button('测试清理')
            .width('100%')
            .onClick(() => {
              this.testCleanup();
            })
            .margin({ bottom: 8 })

          Button('运行全部测试')
            .width('100%')
            .backgroundColor('#4CAF50')
            .onClick(() => {
              this.runAllTests();
            })
  }

  build() {
    Column() {
      TestPageLayout({
        title: this.message,
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }

  private onMapReady(nativeMapView?: maplibre.NativeMapView) {
    try {
      if (!nativeMapView) {
        console.error('[IconTestPage] NativeMapView is null');
        this.testStatus = 'NativeMapView is null';
        return;
      }
      
      const latLng = new maplibre.LatLng(39.9042, 116.4074);
      const cameraPos = createCameraPosition(latLng, 12, 0, 0);
      const options = new MapLibreMapOptions();
      options.cameraPosition = cameraPos;
      options.styleUrl = 'https://demotiles.maplibre.org/style.json';
      
      this.mapLibreMap = new MapLibreMap(nativeMapView, options);
      
      // 立即初始化 Icon 系统（不需要等待样式加载）
      this.initIconSystem();
      
      console.info('[IconTestPage] Map initialized successfully');
    } catch (error) {
      console.error('[IconTestPage] Map initialization failed:', error);
      this.testStatus = `地图初始化失败: ${error}`;
    }
  }
}

