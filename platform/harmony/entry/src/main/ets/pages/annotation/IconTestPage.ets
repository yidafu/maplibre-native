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
 * 随机图标结果接口
 */
interface RandomIconResult {
  icon: Icon;
  name: string;
}

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
  
  // 可用的图标资源列表
  private readonly markerIcons: Resource[] = [
    $r('app.media.marker_dot_blue'),
    $r('app.media.marker_dot_cyan'),
    $r('app.media.marker_dot_green'),
    $r('app.media.marker_dot_red'),
    $r('app.media.marker_dot_yellow'),
    $r('app.media.marker_pin_blue'),
    $r('app.media.marker_pin_green'),
    $r('app.media.marker_pin_orange'),
    $r('app.media.marker_pin_purple'),
    $r('app.media.marker_pin_red')
  ];
  
  private readonly markerIconNames: string[] = [
    'marker_dot_blue',
    'marker_dot_cyan',
    'marker_dot_green',
    'marker_dot_red',
    'marker_dot_yellow',
    'marker_pin_blue',
    'marker_pin_green',
    'marker_pin_orange',
    'marker_pin_purple',
    'marker_pin_red'
  ];

  /**
   * 生成中国境内的随机坐标
   * 中国经纬度范围：
   * - 纬度：18°N 到 54°N
   * - 经度：73°E 到 135°E
   */
  private generateRandomChinaLatLng(): LatLng {
    const minLat = 18;
    const maxLat = 54;
    const minLng = 73;
    const maxLng = 135;
    
    const lat = minLat + Math.random() * (maxLat - minLat);
    const lng = minLng + Math.random() * (maxLng - minLng);
    
    return LatLng.create(lat, lng);
  }
  
  /**
   * 随机选择一个图标资源并创建Icon
   */
  private async createRandomIcon(): Promise<RandomIconResult> {
    if (!this.iconFactory) {
      await this.initIconSystem();
    }
    
    const randomIndex = Math.floor(Math.random() * this.markerIcons.length);
    const iconResource = this.markerIcons[randomIndex];
    const iconName = this.markerIconNames[randomIndex];
    
    const result: RandomIconResult = {
      icon: await this.iconFactory!.defaultMarker(),
      name: 'default'
    };
    
    try {
      result.icon = await this.iconFactory!.fromResource(iconResource);
      result.name = iconName;
      return result;
    } catch (error) {
      console.warn(`[IconTestPage] Failed to load icon ${iconName}, using default`);
      return result;
    }
  }

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
   * 测试 1: 添加随机图标（随机位置）
   */
  private async testDefaultIcon() {
    if (!this.iconFactory) {
      await this.initIconSystem();
    }

    try {
      this.testStatus = '添加随机图标...';
      console.info('[IconTestPage] Adding random marker icon...');

      // 创建随机图标
      const randomIconResult = await this.createRandomIcon();
      const icon = randomIconResult.icon;
      const name = randomIconResult.name;
      console.info(`[IconTestPage] Random icon created: ${name} (${icon.getId()})`);
      console.info(`[IconTestPage] Icon size: ${icon.getWidth()}x${icon.getHeight()}`);

      // 在地图上添加使用随机图标的 Marker（随机中国境内位置）
      const position = this.generateRandomChinaLatLng();
      const markerOptions = new MarkerOptions()
        .position(position)
        .title(name)
        .snippet(`位置: ${position.latitude.toFixed(2)}, ${position.longitude.toFixed(2)}`)
        .icon(icon);

      const marker: Marker = await this.mapLibreMap!.addMarker(markerOptions);
      this.markers.push(marker);

      this.testStatus = `添加成功 - ${name}`;
      this.iconCount = this.markers.length;
    } catch (error) {
      this.testStatus = `添加图标失败: ${error}`;
      console.error('[IconTestPage] Add marker test failed:', error);
    }
  }

  /**
   * 测试 2: 批量添加随机图标
   */
  private async testCustomIcon() {
    if (!this.iconFactory) {
      await this.initIconSystem();
    }

    try {
      this.testStatus = '批量添加随机图标...';
      console.info('[IconTestPage] Adding multiple random markers...');

      // 添加5个随机图标
      for (let i = 0; i < 5; i++) {
        const randomIconResult = await this.createRandomIcon();
        const icon = randomIconResult.icon;
        const name = randomIconResult.name;
        const position = this.generateRandomChinaLatLng();
        
        const markerOptions = new MarkerOptions()
          .position(position)
          .title(`${name}`)
          .snippet(`${position.latitude.toFixed(2)}, ${position.longitude.toFixed(2)}`)
          .icon(icon);

        const marker: Marker = await this.mapLibreMap!.addMarker(markerOptions);
        this.markers.push(marker);
        
        console.info(`[IconTestPage] Added marker ${i + 1}: ${name}`);
      }

      this.testStatus = `✅ 批量添加成功 - 已添加 5 个随机图标`;
      this.iconCount = this.markers.length;
    } catch (error) {
      this.testStatus = `批量添加失败: ${error}`;
      console.error('[IconTestPage] Batch add markers failed:', error);
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
   * 测试 3: 大量添加随机图标（压力测试）
   */
  private async testSharedIcon() {
    if (!this.iconFactory) {
      await this.initIconSystem();
    }

    try {
      this.testStatus = '批量添加随机图标（20个）...';
      console.info('[IconTestPage] Adding 20 random markers...');

      // 添加20个随机图标
      for (let i = 0; i < 20; i++) {
        const randomIconResult = await this.createRandomIcon();
        const icon = randomIconResult.icon;
        const name = randomIconResult.name;
        const position = this.generateRandomChinaLatLng();
        
        const markerOptions = new MarkerOptions()
          .position(position)
          .title(`${name}`)
          .snippet(`#${i + 1} | ${position.latitude.toFixed(2)}, ${position.longitude.toFixed(2)}`)
          .icon(icon);

        const marker: Marker = await this.mapLibreMap!.addMarker(markerOptions);
        this.markers.push(marker);
      }

      this.testStatus = `✅ 批量添加成功 - 已添加 20 个随机图标`;
      this.iconCount = this.markers.length;
      console.info('[IconTestPage] Batch add 20 markers completed');
    } catch (error) {
      this.testStatus = `批量添加失败: ${error}`;
      console.error('[IconTestPage] Batch add markers failed:', error);
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
    this.testStatus = '开始批量添加图标...';
    console.info('[IconTestPage] Running batch icon tests...');

    // 添加30个随机图标
    const totalCount = 30;
    for (let i = 0; i < totalCount; i++) {
      const randomIconResult = await this.createRandomIcon();
      const icon = randomIconResult.icon;
      const name = randomIconResult.name;
      const position = this.generateRandomChinaLatLng();
      
      const markerOptions = new MarkerOptions()
        .position(position)
        .title(`${name}`)
        .snippet(`#${i + 1} | ${position.latitude.toFixed(2)}, ${position.longitude.toFixed(2)}`)
        .icon(icon);

      const marker: Marker = await this.mapLibreMap!.addMarker(markerOptions);
      this.markers.push(marker);
      
      this.testStatus = `正在添加... (${i + 1}/${totalCount})`;
      this.iconCount = this.markers.length;
      
      // 每10个暂停一下，让UI有时间更新
      if ((i + 1) % 10 === 0) {
        await new Promise<void>((resolve) => setTimeout(resolve, 100));
      }
    }

    this.testStatus = `✅ 全部添加完成 - 共 ${totalCount} 个随机图标`;
    console.info('[IconTestPage] All batch tests completed');
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
  buildActionButtons() {
    // 状态信息
    Column() {
      Text(`状态: ${this.testStatus}`)
        .fontSize(12)
        .margin({ bottom: 2 })

      Text(`当前 Marker 数量: ${this.iconCount}`)
        .fontSize(12)
    }
    .width('100%')
    .backgroundColor('#F8F8F8')
    .padding(8)
    .borderRadius(4)
    .margin({ bottom: 8 })

    // 添加图标按钮行
    Row() {
      Button('添加 1 个')
        .fontSize(12)
        .layoutWeight(1)
        .onClick(() => {
          this.testDefaultIcon();
        })

      Button('添加 5 个')
        .fontSize(12)
        .layoutWeight(1)
        .margin({ left: 8 })
        .onClick(() => {
          this.testCustomIcon();
        })
      
      Button('添加 20 个')
        .fontSize(12)
        .layoutWeight(1)
        .margin({ left: 8 })
        .onClick(() => {
          this.testSharedIcon();
        })
    }
    .width('100%')
    .margin({ bottom: 8 })

    // 清理和批量测试按钮行
    Row() {
      Button('清理全部')
        .fontSize(12)
        .layoutWeight(1)
        .backgroundColor('#FF5722')
        .onClick(() => {
          this.testCleanup();
        })

      Button('添加 30 个')
        .fontSize(12)
        .layoutWeight(1)
        .margin({ left: 8 })
        .backgroundColor('#4CAF50')
        .onClick(() => {
          this.runAllTests();
        })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: this.message,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%');
  }
}
