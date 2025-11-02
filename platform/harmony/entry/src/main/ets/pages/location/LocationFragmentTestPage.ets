/**
 * Location Fragment Test Page
 * 定位Fragment测试页面
 *
 * 测试功能:
 * - Fragment 中的定位组件
 * - 生命周期管理
 */

import { TestPageLayout } from '../common/TestPageLayout';
import {
  NativeMapView,
  MapLibreMap,
  MapLibreMapOptions,
  LocationComponent,
  LocationComponentOptions,
  RenderMode,
  PermissionManager
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { MapView } from 'maplibre_harmony';

@Entry
@Component
struct LocationFragmentTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private fragmentActive: boolean = true;
  @State private locationActive: boolean = false;
  @State private lifecycleLog: string[] = [];

  aboutToAppear() {
    this.addLifecycleLog('aboutToAppear');
  }

  aboutToDisappear() {
    this.addLifecycleLog('aboutToDisappear');
    if (this.locationComponent) {
      this.locationComponent.setLocationComponentEnabled(false);
    }
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }

  private addLifecycleLog = (event: string): void => {
    const timestamp = new Date().toLocaleTimeString();
    this.lifecycleLog.unshift(`[${timestamp}] ${event}`);
    if (this.lifecycleLog.length > 12) {
      this.lifecycleLog.pop();
    }
  };
  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    this.addLifecycleLog('onMapReady');
    if (!map) {
      return;
    }
    this.mapController = map;
    if (this.mapController) {
      this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
      this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    }

    setTimeout(() => this.initLocationComponent(), 1500);
  };
  private initLocationComponent = async (): Promise<void> => {
    if (!this.mapController) {
      return;
    }

    try {
      const result = await PermissionManager.requestLocationPermission(getContext(this));
      const granted = result.granted;

      if (!granted) {
        this.addLifecycleLog('权限被拒绝');
        return;
      }

      this.locationComponent = this.mapController.getLocationComponent();
      const options = new LocationComponentOptions();
      this.locationComponent.activateLocationComponent(options);
      this.addLifecycleLog('LocationComponent initialized');
    } catch (error) {
      this.addLifecycleLog(`Init error: ${error}`);
    }
  };
  private toggleFragment = (): void => {
    this.fragmentActive = !this.fragmentActive;
    this.addLifecycleLog(`Fragment ${this.fragmentActive ? 'activated' : 'deactivated'}`);

    if (!this.fragmentActive && this.locationActive) {
      if (this.locationComponent) {
        this.locationComponent.setLocationComponentEnabled(false);
        this.locationActive = false;
        this.addLifecycleLog('Location stopped (Fragment inactive)');
      }
    }

    showToast(`Fragment ${this.fragmentActive ? '激活' : '停用'}`);
  };
  private toggleLocation = (): void => {
    if (!this.fragmentActive) {
      showToast('Fragment 未激活');
      return;
    }

    if (!this.locationComponent) {
      showToast('定位组件未初始化');
      return;
    }

    if (this.locationActive) {
      this.locationComponent.setLocationComponentEnabled(false);
      this.locationActive = false;
      this.addLifecycleLog('Location stopped');
    } else {
      this.locationComponent.setLocationComponentEnabled(true);
      this.locationComponent.setRenderMode(RenderMode.NORMAL);
      this.locationActive = true;
      this.addLifecycleLog('Location started');
    }
  };

  @Builder
  buildMapContent() {
    if (this.fragmentActive) {
      MapView({
        onMapReady: this.onMapReady,
        styleUrl: DEFAULT_STYLE_URLS.bright,
        initialLatitude: 39.9,
        initialLongitude: 116.4,
        initialZoom: 10
      })
        .width('100%')
        .height('100%')
    } else {
      Column() {
        Text('Fragment 已停用')
          .fontSize(18)
          .fontColor('#999')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F5F5F5')
    }
  }

  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('Fragment 生命周期')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)

      Button(this.fragmentActive ? '停用 Fragment' : '激活 Fragment')
        .width('100%')
        .backgroundColor(this.fragmentActive ? '#FF6B6B' : '#4CAF50')
        .onClick(() => this.toggleFragment())

      Button(this.locationActive ? '停止定位' : '启动定位')
        .width('100%')
        .backgroundColor(this.locationActive ? '#FF6B6B' : '#2196F3')
        .enabled(this.fragmentActive)
        .onClick(() => this.toggleLocation())

      Divider()

      Text('生命周期日志')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)

      Column() {
        ForEach(this.lifecycleLog, (log: string, index: number) => {
          Text(log)
            .fontSize(11)
            .fontFamily('monospace')
            .width('100%')
            .padding(4)
            .backgroundColor(index % 2 === 0 ? '#F5F5F5' : '#FFFFFF')
        })
      }
      .width('100%')
      .backgroundColor('#F9F9F9')
      .border({ width: 1, color: '#DDD' })
      .borderRadius(4)
      .padding(8)

      Text('说明: 测试Fragment生命周期中的LocationComponent')
        .fontSize(12)
        .fontColor('#666')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'Location Fragment',
        description: '定位Fragment测试',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}
