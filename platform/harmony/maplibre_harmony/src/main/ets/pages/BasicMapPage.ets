/**
 * 基础地图测试页面
 * 测试相机控制功能：jumpTo、flyTo、easeTo 等
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { NativeMapView } from '../maps/NativeMapView';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import maplibre from 'libmaplibre_native.so';

// 从 NAPI 模块导入相机选项类型
type CameraOptions = maplibre.CameraOptions;

const DOMAIN = 0x0000;
const TAG = 'BasicMapPage';

// 全局地图视图引用（用于测试）
let globalMapView: maplibre.NativeMapView | null = null;

// 预定义的测试位置
interface TestLocation {
  name: string;
  latitude: number;
  longitude: number;
  zoom: number;
  bearing?: number;
  pitch?: number;
  icon: string;
}

// 按钮动作接口
interface ButtonAction {
  title: string;
  action: () => void;
}

@Entry
@Component
struct BasicMapPage {
  @State mapReady: boolean = false;
  @State currentInfo: string = '北京 - 天安门';
  @State showControlPanel: boolean = true;
  
  // 测试位置列表
  private testLocations: TestLocation[] = [
    { name: '北京 - 天安门', latitude: 39.9042, longitude: 116.4074, zoom: 6, icon: '🏛️' },
    { name: '上海 - 东方明珠', latitude: 31.2397, longitude: 121.4997, zoom: 6, icon: '🗼' },
    { name: '杭州 - 西湖', latitude: 30.2489, longitude: 120.1363, zoom: 6, icon: '🏞️' },
    { name: '深圳 - 深圳湾', latitude: 22.5431, longitude: 113.9547, zoom: 6, icon: '🌊' },
    { name: '成都 - 锦里', latitude: 30.6517, longitude: 104.0468, zoom: 6, icon: '🏮' },
  ];

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#2196F3')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 5 })

        Text('基础地图测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(50)
      .backgroundColor('#F0F0F0')

      // 信息栏
      Row() {
        Text(`📍 ${this.currentInfo}`)
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Text(this.mapReady ? '✅ 已加载' : '⏳ 加载中...')
          .fontSize(12)
          .fontColor(this.mapReady ? '#4CAF50' : '#FF9800')
          .margin({ right: 10 })
        
        Button(this.showControlPanel ? '隐藏面板' : '显示面板')
          .fontSize(12)
          .height(30)
          .onClick(() => {
            this.showControlPanel = !this.showControlPanel;
          })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#F8F8F8')

      // 地图容器 - 移除加载遮罩层，避免遮挡地图渲染
      Stack() {
        // 地图视图 - 使用 NativeMapView 组件
        NativeMapView({
          styleUrl: "https://demotiles.maplibre.org/style.json",
          initialLatitude: 39.9042,
          initialLongitude: 116.4074,
          initialZoom: 6,
          initialBearing: 0,
          initialPitch: 0,
          onMapReady: (mapView?: maplibre.NativeMapView) => {
            if (mapView) {
              globalMapView = mapView;
              this.mapReady = true;
              hilog.info(DOMAIN, TAG, 'Map ready and saved');
            } else {
              hilog.error(DOMAIN, TAG, 'Map ready callback received null mapView');
            }
          }
        })
          .width('100%')
          .height('100%')

        // 控制面板 - 浮动在地图上方
        if (this.mapReady && this.showControlPanel) {
          Column() {
            this.buildControlPanel()
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.End)
          .padding({ bottom: 20 })
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildControlPanel() {
    Column() {
      Scroll() {
        Column({ space: 10 }) {
          // 相机跳转控制
          this.buildSection('🎯 相机跳转 (jumpTo)', [
            { title: '北京', action: (): void => this.jumpToLocation(0) },
            { title: '上海', action: (): void => this.jumpToLocation(1) },
            { title: '杭州', action: (): void => this.jumpToLocation(2) },
          ] as ButtonAction[])

          // 飞行动画控制
          this.buildSection('✈️ 飞行动画 (flyTo)', [
            { title: '深圳 (3s)', action: (): void => this.flyToLocation(3, 3000) },
            { title: '成都 (5s)', action: (): void => this.flyToLocation(4, 5000) },
            { title: '北京 (2s)', action: (): void => this.flyToLocation(0, 2000) },
          ] as ButtonAction[])

          // 平滑过渡控制
          this.buildSection('🎬 平滑过渡 (easeTo)', [
            { title: '上海 (2s)', action: (): void => this.easeToLocation(1, 2000) },
            { title: '杭州 (3s)', action: (): void => this.easeToLocation(2, 3000) },
            { title: '旋转视角', action: (): void => this.easeToRotated() },
          ] as ButtonAction[])

          // 相机属性控制
          this.buildSection('📐 相机属性', [
            { title: '放大 (Zoom+)', action: (): void => this.adjustZoom(2) },
            { title: '缩小 (Zoom-)', action: (): void => this.adjustZoom(-2) },
            { title: '设置倾斜 60°', action: (): void => this.setPitch(60) },
            { title: '重置倾斜 0°', action: (): void => this.setPitch(0) },
            { title: '旋转 45°', action: (): void => this.setBearing(45) },
            { title: '重置方向', action: (): void => this.setBearing(0) },
          ] as ButtonAction[])

          // 获取相机信息
          this.buildSection('ℹ️ 相机信息', [
            { title: '获取当前位置', action: (): void => this.getCurrentPosition() },
            { title: '获取缩放级别', action: (): void => this.getCurrentZoom() },
            { title: '获取方向角度', action: (): void => this.getCurrentBearing() },
            { title: '获取倾斜角度', action: (): void => this.getCurrentPitch() },
          ] as ButtonAction[])
        }
        .padding(10)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('90%')
    .height('70%')
    .backgroundColor('rgba(255, 255, 255, 0.95)')
    .borderRadius(10)
    .shadow({
      radius: 10,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  buildSection(title: string, buttons: ButtonAction[]) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(buttons, (btn: ButtonAction, index: number) => {
          Button(btn.title)
            .fontSize(12)
            .height(32)
            .margin({ right: 8, bottom: 8 })
            .onClick((): void => {
              // 添加点击事件日志
              hilog.info(DOMAIN, 'BasicMapPage', `🖱️ Button clicked: "${btn.title}" (index=${index})`);
              try {
                btn.action();
                hilog.info(DOMAIN, 'BasicMapPage', `✅ Button action completed: "${btn.title}"`);
              } catch (error) {
                hilog.error(DOMAIN, 'BasicMapPage', `❌ Button action failed: ${error}`);
              }
            })
        }, (btn: ButtonAction, index: number) => `${title}-${index}-${btn.title}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
  }

  // ========== 相机控制方法 ==========

  /**
   * 使用 jumpTo 跳转到指定位置（无动画）
   */
  jumpToLocation(index: number) {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    const location = this.testLocations[index];
    const bearing = location.bearing || 0;
    const pitch = location.pitch || 0;
    globalMapView.jumpTo(bearing, location.latitude, location.longitude, pitch, location.zoom);
    this.currentInfo = location.name;
    this.showToast(`跳转到: ${location.name}`);
    hilog.info(DOMAIN, 'BasicMapPage', `jumpTo: ${location.name}`);
  }

  /**
   * 使用 flyTo 飞行到指定位置（飞行动画）
   */
  flyToLocation(index: number, duration: number) {
    // 🔵 最优先的日志 - 确保能捕获到点击事件
    const timestamp = Date.now();
    hilog.info(DOMAIN, 'BasicMapPage', `🔵 flyToLocation CALLED: index=${index}, duration=${duration}, timestamp=${timestamp}`);
    
    if (!globalMapView) {
      hilog.error(DOMAIN, 'BasicMapPage', '❌ globalMapView is NULL');
      this.showToast('地图未初始化');
      return;
    }
    
    hilog.info(DOMAIN, 'BasicMapPage', '✅ globalMapView exists, calling cancelTransitions...');
    
    // 取消当前正在进行的所有动画
    globalMapView.cancelTransitions();
    
    hilog.info(DOMAIN, 'BasicMapPage', '✅ cancelTransitions completed');
    
    const location = this.testLocations[index];
    const options: CameraOptions = {
      center: {
        latitude: location.latitude,
        longitude: location.longitude
      },
      zoom: 6,  // 固定 zoom 为 6（用于测试）
      bearing: location.bearing || 0,
      pitch: location.pitch || 0
    };
    
    // 调试日志：记录当前位置和目标位置
    const currentPos = globalMapView.getLatLng();
    const currentZoom = globalMapView.getZoom();
    hilog.info(DOMAIN, 'BasicMapPage', 
      `flyTo: BEFORE - current: lat=${currentPos.latitude}, lng=${currentPos.longitude}, zoom=${currentZoom}`);
    hilog.info(DOMAIN, 'BasicMapPage', 
      `flyTo: TARGET - lat=${location.latitude}, lng=${location.longitude}, zoom=6 (fixed for testing), duration=${duration}ms`);
    
    globalMapView.flyTo(options, duration);
    
    // 🔧 显式触发渲染，确保动画开始
    globalMapView.triggerRepaint();
    
    this.currentInfo = location.name;
    this.showToast(`飞往: ${location.name} (${duration / 1000}秒)`);
    hilog.info(DOMAIN, 'BasicMapPage', `flyTo: Animation started for ${location.name}`);
  }

  /**
   * 使用 easeTo 平滑过渡到指定位置
   */
  easeToLocation(index: number, duration: number) {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    // 取消当前正在进行的所有动画
    globalMapView.cancelTransitions();
    
    const location = this.testLocations[index];
    const options: CameraOptions = {
      center: {
        latitude: location.latitude,
        longitude: location.longitude
      },
      zoom: 6,  // 固定 zoom 为 6（用于测试）
      bearing: location.bearing || 0,
      pitch: location.pitch || 0
    };
    
    // 调试日志：记录当前位置和目标位置
    const currentPos = globalMapView.getLatLng();
    const currentZoom = globalMapView.getZoom();
    hilog.info(DOMAIN, 'BasicMapPage', 
      `easeTo: BEFORE - current: lat=${currentPos.latitude}, lng=${currentPos.longitude}, zoom=${currentZoom}`);
    hilog.info(DOMAIN, 'BasicMapPage', 
      `easeTo: TARGET - lat=${location.latitude}, lng=${location.longitude}, zoom=6 (fixed for testing), duration=${duration}ms`);
    
    globalMapView.easeTo(options, duration);
    
    // 🔧 显式触发渲染，确保动画开始
    globalMapView.triggerRepaint();
    
    this.currentInfo = location.name;
    this.showToast(`平滑过渡到: ${location.name} (${duration / 1000}秒)`);
    hilog.info(DOMAIN, 'BasicMapPage', `easeTo: Animation started for ${location.name}`);
  }

  /**
   * 过渡到旋转视角
   */
  easeToRotated() {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    // 取消当前正在进行的所有动画
    globalMapView.cancelTransitions();
    
    const currentPos = globalMapView.getLatLng();
    
    // 旋转到 120 度，倾斜 45 度
    const options: CameraOptions = {
      center: {
        latitude: currentPos.latitude,
        longitude: currentPos.longitude
      },
      zoom: 6,  // 固定 zoom 为 6（用于测试）
      bearing: 120,
      pitch: 45
    };
    
    hilog.info(DOMAIN, 'BasicMapPage', `easeToRotated: bearing=120, pitch=45, zoom=6 (fixed for testing)`);
    globalMapView.easeTo(options, 2000);
    
    // 🔧 显式触发渲染，确保动画开始
    globalMapView.triggerRepaint();
    
    this.showToast('旋转视角: 120°, 倾斜: 45°');
    hilog.info(DOMAIN, 'BasicMapPage', 'easeToRotated: Animation started');
  }

  /**
   * 调整缩放级别
   */
  adjustZoom(delta: number) {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    const currentZoom = globalMapView.getZoom();
    const newZoom = currentZoom + delta;
    globalMapView.setZoom(newZoom, undefined, undefined, 300);
    this.showToast(`缩放: ${newZoom.toFixed(1)}`);
    hilog.info(DOMAIN, 'BasicMapPage', `setZoom: ${newZoom}`);
  }

  /**
   * 设置倾斜角度
   */
  setPitch(pitch: number) {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    globalMapView.setPitch(pitch, 500);
    this.showToast(`倾斜角度: ${pitch}°`);
    hilog.info(DOMAIN, 'BasicMapPage', `setPitch: ${pitch}`);
  }

  /**
   * 设置方向角度
   */
  setBearing(bearing: number) {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    globalMapView.setBearing(bearing, 500);
    this.showToast(`方向角度: ${bearing}°`);
    hilog.info(DOMAIN, 'BasicMapPage', `setBearing: ${bearing}`);
  }

  /**
   * 获取当前位置
   */
  getCurrentPosition() {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    const pos = globalMapView.getLatLng();
    const info = `位置: ${pos.latitude.toFixed(4)}, ${pos.longitude.toFixed(4)}`;
    this.showToast(info);
    hilog.info(DOMAIN, 'BasicMapPage', info);
  }

  /**
   * 获取当前缩放级别
   */
  getCurrentZoom() {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    const zoom = globalMapView.getZoom();
    const info = `缩放级别: ${zoom.toFixed(2)}`;
    this.showToast(info);
    hilog.info(DOMAIN, 'BasicMapPage', info);
  }

  /**
   * 获取当前方向角度
   */
  getCurrentBearing() {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    const bearing = globalMapView.getBearing();
    const info = `方向角度: ${bearing.toFixed(1)}°`;
    this.showToast(info);
    hilog.info(DOMAIN, 'BasicMapPage', info);
  }

  /**
   * 获取当前倾斜角度
   */
  getCurrentPitch() {
    if (!globalMapView) {
      this.showToast('地图未初始化');
      return;
    }
    
    const pitch = globalMapView.getPitch();
    const info = `倾斜角度: ${pitch.toFixed(1)}°`;
    this.showToast(info);
    hilog.info(DOMAIN, 'BasicMapPage', info);
  }

  /**
   * 显示提示消息
   */
  showToast(message: string) {
    promptAction.showToast({
      message: message,
      duration: 2000,
      bottom: 100
    });
  }
}


