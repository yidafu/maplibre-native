/**
 * NetworkConfigTestPage - 网络配置测试页面
 * 
 * 测试自定义HTTP请求头功能
 */

import { MapView, MapLibreMap, NetworkConfiguration, DEFAULT_STYLE_URLS } from '@ohos/maplibre';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;

@Entry
@Component
struct NetworkConfigTestPage {
  @State pageTitle: string = '网络配置测试';
  @State statusMessage: string = '准备就绪';
  @State headersJson: string = '{}';
  private map: MapLibreMap | null = null;

  aboutToAppear() {
    hilog.info(DOMAIN, 'NetworkConfigTestPage', 'Page is about to appear');
    
    // 在创建地图之前配置自定义请求头
    try {
      // 测试1: 设置多个自定义请求头
      NetworkConfiguration.setCustomHttpHeaders({
        'X-Custom-Test-Header': 'test-value-1',
        'X-API-Version': 'v1.0',
        'X-Request-ID': `harmony-${Date.now()}`
      });
      
      this.statusMessage = '已设置自定义请求头';
      this.updateHeadersDisplay();
      
      hilog.info(DOMAIN, 'NetworkConfigTestPage', 'Custom headers configured successfully');
    } catch (error) {
      hilog.error(DOMAIN, 'NetworkConfigTestPage', `Failed to configure headers: ${error}`);
      this.statusMessage = `配置失败: ${error}`;
    }
  }

  aboutToDisappear() {
    hilog.info(DOMAIN, 'NetworkConfigTestPage', 'Page is about to disappear');
    
    // 清理资源
    if (this.map) {
      this.map.destroy();
      this.map = null;
    }
  }

  /**
   * 更新请求头显示
   */
  private updateHeadersDisplay(): void {
    try {
      const headers = NetworkConfiguration.getCustomHttpHeaders();
      this.headersJson = JSON.stringify(headers, null, 2);
    } catch (error) {
      hilog.error(DOMAIN, 'NetworkConfigTestPage', `Failed to get headers: ${error}`);
    }
  }

  /**
   * 添加单个请求头
   */
  private addHeader(): void {
    try {
      const timestamp = Date.now();
      NetworkConfiguration.addCustomHttpHeader('X-Test-Timestamp', timestamp.toString());
      this.statusMessage = `已添加时间戳请求头: ${timestamp}`;
      this.updateHeadersDisplay();
      
      hilog.info(DOMAIN, 'NetworkConfigTestPage', `Added timestamp header: ${timestamp}`);
    } catch (error) {
      hilog.error(DOMAIN, 'NetworkConfigTestPage', `Failed to add header: ${error}`);
      this.statusMessage = `添加失败: ${error}`;
    }
  }

  /**
   * 移除指定请求头
   */
  private removeHeader(): void {
    try {
      const removed = NetworkConfiguration.removeCustomHttpHeader('X-Test-Timestamp');
      this.statusMessage = removed ? '已移除时间戳请求头' : '时间戳请求头不存在';
      this.updateHeadersDisplay();
      
      hilog.info(DOMAIN, 'NetworkConfigTestPage', `Remove timestamp header: ${removed}`);
    } catch (error) {
      hilog.error(DOMAIN, 'NetworkConfigTestPage', `Failed to remove header: ${error}`);
      this.statusMessage = `移除失败: ${error}`;
    }
  }

  /**
   * 清除所有自定义请求头
   */
  private clearHeaders(): void {
    try {
      NetworkConfiguration.clearCustomHttpHeaders();
      this.statusMessage = '已清除所有自定义请求头';
      this.updateHeadersDisplay();
      
      hilog.info(DOMAIN, 'NetworkConfigTestPage', 'Cleared all custom headers');
    } catch (error) {
      hilog.error(DOMAIN, 'NetworkConfigTestPage', `Failed to clear headers: ${error}`);
      this.statusMessage = `清除失败: ${error}`;
    }
  }

  /**
   * 重新配置请求头（用于测试地图资源加载）
   */
  private reconfigureHeaders(): void {
    try {
      NetworkConfiguration.setCustomHttpHeaders({
        'X-Custom-Test-Header': 'updated-value',
        'X-API-Version': 'v2.0',
        'X-Request-ID': `harmony-${Date.now()}`,
        'Authorization': 'Bearer test-token-123'
      });
      
      this.statusMessage = '已更新自定义请求头';
      this.updateHeadersDisplay();
      
      hilog.info(DOMAIN, 'NetworkConfigTestPage', 'Headers reconfigured');
    } catch (error) {
      hilog.error(DOMAIN, 'NetworkConfigTestPage', `Failed to reconfigure headers: ${error}`);
      this.statusMessage = `更新失败: ${error}`;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.pageTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .padding(16)
      }
      .width('100%')
      .backgroundColor('#f5f5f5')

      // 状态信息
      Row() {
        Text(`状态: ${this.statusMessage}`)
          .fontSize(14)
          .padding(12)
      }
      .width('100%')
      .backgroundColor('#e0e0e0')

      // 当前请求头显示
      Column() {
        Text('当前自定义请求头:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })
        
        Text(this.headersJson)
          .fontSize(12)
          .fontFamily('monospace')
          .width('100%')
          .padding(8)
          .backgroundColor('#f9f9f9')
          .border({ width: 1, color: '#ddd' })
      }
      .width('90%')
      .margin(12)
      .alignItems(HorizontalAlign.Start)

      // 操作按钮
      Column({ space: 8 }) {
        Button('添加时间戳请求头')
          .width('90%')
          .onClick(() => this.addHeader())

        Button('移除时间戳请求头')
          .width('90%')
          .onClick(() => this.removeHeader())

        Button('重新配置请求头')
          .width('90%')
          .onClick(() => this.reconfigureHeaders())

        Button('清除所有请求头')
          .width('90%')
          .backgroundColor('#ff6b6b')
          .onClick(() => this.clearHeaders())
      }
      .width('100%')
      .margin({ top: 12, bottom: 12 })

      // 地图视图（用于验证请求头是否生效）
      Column() {
        Text('地图加载测试:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })
        
        MapView({
          styleUrl: DEFAULT_STYLE_URLS.streets,
          onMapReady: (map: MapLibreMap) => {
            this.map = map;
            map.setLatLng(39.9042, 116.4074);  // 北京
            map.setZoom(12);
            
            hilog.info(DOMAIN, 'NetworkConfigTestPage', 'Map is ready');
            this.statusMessage = '地图已加载 - 请求头应已应用';
          }
        })
        .width('100%')
        .height(300)
      }
      .width('90%')
      .margin(12)
      .alignItems(HorizontalAlign.Start)

      // 说明文本
      Column() {
        Text('使用说明:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })
        
        Text('1. 页面启动时会自动配置自定义请求头\n' +
             '2. 使用按钮测试添加、移除、更新请求头\n' +
             '3. 地图加载时会应用当前配置的请求头\n' +
             '4. 查看日志确认请求头是否正确应用\n' +
             '5. 注意: User-Agent请求头不允许覆盖')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
      }
      .width('90%')
      .margin(12)
      .padding(12)
      .backgroundColor('#fff3cd')
      .border({ width: 1, color: '#ffc107' })
      .borderRadius(4)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
}

