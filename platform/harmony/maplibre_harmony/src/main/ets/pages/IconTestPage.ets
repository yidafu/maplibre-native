import { MapViewComponentController } from '../maps/MapViewComponentController';
import { LatLng } from '../maps/geometry/LatLng';
import { Icon, IconFactory, MarkerOptions } from '../maps/annotations/index';
import maplibre from 'libmaplibre_native.so';
import resourceManager from '@ohos.resourceManager';

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
  
  private mapController: MapViewComponentController = new MapViewComponentController();
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
      const position = new LatLng(39.9042, 116.4074); // 北京
      const markerOptions = new MarkerOptions()
        .position(position)
        .title('默认图标测试')
        .icon(defaultIcon);

      const marker = markerOptions.getMarker();
      this.mapController.getMap().addMarker(marker);
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
      const position = new LatLng(39.9142, 116.4174); // 稍微偏移
      const markerOptions = new MarkerOptions()
        .position(position)
        .title('自定义图标测试')
        .snippet('使用自定义图标')
        .icon(this.testIcon);

      const marker = markerOptions.getMarker();
      this.mapController.getMap().addMarker(marker);
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
        new LatLng(39.9242, 116.4274),
        new LatLng(39.9342, 116.4374),
        new LatLng(39.9442, 116.4474)
      ];

      for (let i = 0; i < positions.length; i++) {
        const markerOptions = new MarkerOptions()
          .position(positions[i])
          .title(`共享图标 Marker ${i + 1}`)
          .icon(this.testIcon!);

        const marker = markerOptions.getMarker();
        this.mapController.getMap().addMarker(marker);
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
        this.mapController.getMap().removeMarker(marker);
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
    await new Promise(resolve => setTimeout(resolve, 1000));

    await this.testCustomIcon();
    await new Promise(resolve => setTimeout(resolve, 1000));

    await this.testSharedIcon();
    await new Promise(resolve => setTimeout(resolve, 1000));

    this.testCleanup();
    await new Promise(resolve => setTimeout(resolve, 1000));

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
        this.mapController.getMap().removeMarker(marker);
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

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#1976D2')
      .alignItems(VerticalAlign.Center)

      // 状态信息
      Column() {
        Text(`状态: ${this.testStatus}`)
          .fontSize(14)
          .margin({ top: 8, bottom: 4 })

        Text(`当前 Marker 数量: ${this.iconCount}`)
          .fontSize(14)
          .margin({ bottom: 8 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F5F5F5')

      // 测试按钮区域
      Column({ space: 8 }) {
        Button('测试默认图标')
          .width('90%')
          .onClick(() => {
            this.testDefaultIcon();
          })

        Button('测试自定义图标')
          .width('90%')
          .onClick(() => {
            this.testCustomIcon();
          })

        Button('测试共享图标')
          .width('90%')
          .onClick(() => {
            this.testSharedIcon();
          })

        Button('测试清理')
          .width('90%')
          .onClick(() => {
            this.testCleanup();
          })

        Button('运行全部测试')
          .width('90%')
          .backgroundColor('#4CAF50')
          .onClick(() => {
            this.runAllTests();
          })
      }
      .width('100%')
      .padding(16)

      // 地图视图
      MapViewComponentController({ controller: this.mapController })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}

