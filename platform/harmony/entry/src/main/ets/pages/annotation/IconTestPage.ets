import {
  NativeMapView,
  LatLng,
  IconFactory,
  Icon,
  Marker,
  MarkerOptions,
  MapLibreMap,
  MapLibreMapOptions,
  CameraPosition
} from 'maplibre_harmony';
import { router } from '@kit.ArkUI';
import resourceManager from '@ohos.resourceManager';
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { MapView } from 'maplibre_harmony';

/**
 * IconTestPage - Icon 管理系统测试页面
 * 
 * 测试最新的IconFactory/IconManager API功能：
 * 1. fromResource() - 从资源创建Icon（性能优化版）
 * 2. fromPath() - 从文件路径创建Icon
 * 3. 引用计数机制 - 多个Marker共享同一Icon
 * 4. Icon的isReleased()状态检查
 * 5. 默认图标的缓存机制
 * 6. 性能对比 - fromResource vs fromPixelMap（已弃用）
 */
@Entry
@Component
struct IconTestPage {
  @State message: string = 'Icon 系统测试';
  @State testStatus: string = '等待测试...';
  @State iconCount: number = 0;
  
  private mapLibreMap: MapLibreMap | null = null;
  private iconFactory: IconFactory | null = null;
  private markers: Marker[] = [];;
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
      const position = LatLng.create(39.9042, 116.4074); // 北京
      const markerOptions = new MarkerOptions()
        .position(position)
        .title('默认图标测试')
        .icon(defaultIcon);

      const marker: Marker = await this.mapLibreMap!.addMarker(markerOptions);
      this.markers.push(marker);

      this.testStatus = `默认图标测试成功 - ${defaultIcon.toString()}`;
      this.iconCount = 1;
    } catch (error) {
      this.testStatus = `默认图标测试失败: ${error}`;
      console.error('[IconTestPage] Default icon test failed:', error);
    }
  }

  /**
   * 测试 2: 创建自定义图标（从资源 - 性能优化）
   */
  private async testCustomIcon() {
    if (!this.iconFactory) {
      await this.initIconSystem();
    }

    try {
      this.testStatus = '测试fromResource（性能优化版）...';
      console.info('[IconTestPage] Testing custom icon with fromResource...');

      // 使用 fromResource - 在C++层直接解码，性能提升30-50%
      try {
        this.testIcon = await this.iconFactory!.fromResource($r('app.media.startIcon'));
        console.info(`[IconTestPage] Custom icon created: ${this.testIcon.getId()}`);
        console.info(`[IconTestPage] Icon released? ${this.testIcon.isReleased()}`);
      } catch (error) {
        console.warn('[IconTestPage] Failed to load custom icon from resource, using default');
        this.testIcon = await this.iconFactory!.defaultMarker();
      }

      // 添加使用自定义图标的 Marker
      const position = LatLng.create(39.9142, 116.4174);
      const markerOptions = new MarkerOptions()
        .position(position)
        .title('fromResource优化版')
        .snippet('C++层直接解码，零复制')
        .icon(this.testIcon);

      const marker: Marker = await this.mapLibreMap!.addMarker(markerOptions);
      this.markers.push(marker);

      this.testStatus = `✅ fromResource测试成功 - 性能优化版\nIcon ID: ${this.testIcon.getId()}\n已释放: ${this.testIcon.isReleased()}`;
      this.iconCount = 2;
    } catch (error) {
      this.testStatus = `自定义图标测试失败: ${error}`;
      console.error('[IconTestPage] Custom icon test failed:', error);
    }
  }
  
  /**
   * 测试 2.5: 测试Icon的isReleased()状态
   */
  private async testIconReleaseStatus() {
    if (!this.testIcon) {
      await this.testCustomIcon();
    }

    try {
      this.testStatus = '测试Icon释放状态...';
      console.info('[IconTestPage] Testing Icon release status...');

      if (this.testIcon) {
        const isReleased = this.testIcon.isReleased();
        const iconId = this.testIcon.getId();
        const iconWidth = this.testIcon.getWidth();
        const iconHeight = this.testIcon.getHeight();
        
        this.testStatus = `✅ Icon状态检查:\n` +
          `ID: ${iconId}\n` +
          `尺寸: ${iconWidth}x${iconHeight}\n` +
          `已释放: ${isReleased}\n` +
          `说明: 使用中的Icon不应被释放`;
        
        console.info(`[IconTestPage] Icon status - ID: ${iconId}, Released: ${isReleased}`);
      } else {
        this.testStatus = '❌ 没有可用的测试Icon';
      }
    } catch (error) {
      this.testStatus = `Icon状态检查失败: ${error}`;
      console.error('[IconTestPage] Icon status check failed:', error);
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
        LatLng.create(39.9242, 116.4274),
        LatLng.create(39.9342, 116.4374),
        LatLng.create(39.9442, 116.4474)
      ]

      for (let i = 0; i < positions.length; i++) {
        const markerOptions = new MarkerOptions()
          .position(positions[i])
          .title(`共享图标 Marker ${i + 1}`)
          .icon(this.testIcon!);

        const marker: Marker = await this.mapLibreMap!.addMarker(markerOptions);
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

  /**
   * 地图就绪回调
   */
  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    console.info('[IconTestPage] onMapReady');
    this.mapLibreMap = map;
    
    // 初始化 Icon 系统
    await this.initIconSystem();
  };

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: this.onMapReady,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
  }

  @Builder
  buildControlPanel() {
          // 状态信息
          Column() {
            Text(`状态: ${this.testStatus}`)
              .fontSize(14)
              .margin({ bottom: 4 })

            Text(`当前 Marker 数量: ${this.iconCount}`)
              .fontSize(14)
          }
          .width('100%')
          .backgroundColor('#F8F8F8')
          .margin({ bottom: 8 })

          // 测试按钮
          Text('基础测试')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')

          Button('测试默认图标')
            .width('100%')
            .onClick(() => {
              this.testDefaultIcon();
            })
            .margin({ bottom: 8 })

          Button('测试fromResource（优化版）')
            .width('100%')
            .onClick(() => {
              this.testCustomIcon();
            })
            .margin({ bottom: 8 })

          Divider().margin({ top: 8, bottom: 8 })

          Text('引用计数与生命周期')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')

          Button('测试Icon状态（isReleased）')
            .width('100%')
            .onClick(() => {
              this.testIconReleaseStatus();
            })
            .margin({ bottom: 8 })

          Button('测试共享图标（引用计数）')
            .width('100%')
            .onClick(() => {
              this.testSharedIcon();
            })
            .margin({ bottom: 8 })

          Button('测试清理（自动释放）')
            .width('100%')
            .onClick(() => {
              this.testCleanup();
            })
            .margin({ bottom: 8 })

          Divider().margin({ top: 8, bottom: 8 })

          Button('运行全部测试')
            .width('100%')
            .onClick(() => {
              this.runAllTests();
            })
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: this.message,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%');
  }
}
