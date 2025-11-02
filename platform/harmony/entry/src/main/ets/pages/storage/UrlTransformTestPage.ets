/**
 * URL Transform Test Page
 * URL转换测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/storage/UrlTransformActivity.kt
 * 
 * 功能：
 * - 实现 ResourceTransform 回调
 * - 拦截和转换 URL 请求
 * - 显示转换前后的 URL
 * - 记录所有资源请求
 * 
 * 注意：
 * 由于鸿蒙平台的 ResourceTransform 实现可能与 Android 不同，
 * 此页面展示了如何监听和记录 URL 请求。
 * 实际的 URL 转换功能需要在 Native 层实现。
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

// URL 转换回调类型
type ResourceKind = 'Unknown' | 'Style' | 'Source' | 'Tile' | 'Glyphs' | 'SpriteImage' | 'SpriteJSON';

@Entry
@Component
struct UrlTransformTestPage {
  private mapController: MapLibreMap | null = null;
  @State private transformEnabled: boolean = false;
  @State private requestLog: string[] = [];
  @State private transformCount: number = 0;
  @State private totalRequests: number = 0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[UrlTransformTestPage] onMapReady');
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    
    // 注意：实际的 URL 转换需要在创建 MapView 前设置
    // 这里仅演示日志记录功能
    showToast('URL转换功能需在 MapView 初始化前配置');
  };
  
  /**
   * 记录请求日志
   */
  private logRequest = (kind: string, url: string, transformed: boolean = false): void => {
    const timestamp = new Date().toLocaleTimeString();
    const urlPreview = url.length > 50 ? url.substring(0, 50) + '...' : url;
    const prefix = transformed ? '🔄' : '📡';
    const logEntry = `${prefix} [${timestamp}] [${kind}] ${urlPreview}`;
    
    this.requestLog.unshift(logEntry);
    this.totalRequests++;
    
    if (transformed) {
      this.transformCount++;
    }
    
    // 限制日志数量
    if (this.requestLog.length > 50) {
      this.requestLog = this.requestLog.slice(0, 50);
    }
  };
  
  /**
   * 模拟 URL 转换函数
   * 实际应用中，这应该在 Native 层实现
   */
  private transformUrl = (kind: string, url: string): string => {
    if (!this.transformEnabled) {
      return url;
    }
    
    // 示例转换：将 demotiles.maplibre.org 替换为自定义域名
    // 实际项目中可以实现更复杂的逻辑，如：
    // - 添加认证参数
    // - 使用镜像服务器
    // - 修改协议 (http -> https)
    // - 添加版本号或时间戳
    
    let transformedUrl = url;
    
    // 示例：记录转换
    if (url.includes('demotiles.maplibre.org')) {
      // 这里只是示例，实际不修改 URL
      transformedUrl = url; // 可以修改为: url.replace('demotiles.maplibre.org', 'custom-cdn.example.com')
      console.info(`[UrlTransformTestPage] Transform [${kind}]: ${url}`);
    }
    
    this.logRequest(kind, url, url !== transformedUrl);
    
    return transformedUrl;
  };
  
  /**
   * 切换转换开关
   */
  private toggleTransform = (): void => {
    this.transformEnabled = !this.transformEnabled;
    showToast(`URL转换: ${this.transformEnabled ? '启用' : '禁用'}`);
    
    if (this.transformEnabled) {
      // 记录示例请求
      this.logRequest('Style', 'https://demotiles.maplibre.org/style.json', false);
      this.logRequest('Tile', 'https://demotiles.maplibre.org/tiles/0/0/0.pbf', false);
    }
  };
  
  /**
   * 清除日志
   */
  private clearLog = (): void => {
    this.requestLog = [];
    this.transformCount = 0;
    this.totalRequests = 0;
    showToast('日志已清除');
  };
  
  /**
   * 重新加载地图以触发请求
   */
  private reloadMap = (): void => {
    if (!this.mapController) return;
    
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    showToast('地图样式重新加载');
    
    // 模拟记录一些请求
    this.logRequest('Style', DEFAULT_STYLE_URLS.streets, this.transformEnabled);
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
      .width('100%')
      .height('100%');
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('URL转换')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      // 统计信息
      Row() {
        Column() {
          Text(`${this.totalRequests}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
          Text('总请求数')
            .fontSize(12)
            .fontColor('#666')
        }
        .layoutWeight(1)
        
        Column() {
          Text(`${this.transformCount}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          Text('转换次数')
            .fontSize(12)
            .fontColor('#666')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      
      // 控制按钮
      Row({ space: 8 }) {
        Button(this.transformEnabled ? '禁用' : '启用')
          .layoutWeight(1)
          .backgroundColor(this.transformEnabled ? '#FF6B6B' : '#4CAF50')
          .onClick(() => this.toggleTransform())
        
        Button('重载')
          .layoutWeight(1)
          .backgroundColor('#2196F3')
          .onClick(() => this.reloadMap())
        
        Button('清除')
          .layoutWeight(1)
          .backgroundColor('#FFA500')
          .onClick(() => this.clearLog())
      }
      .width('100%')
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 请求日志
      Text(`请求日志 (${this.requestLog.length})`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Scroll() {
        Column() {
          if (this.requestLog.length > 0) {
            ForEach(this.requestLog, (log: string, index: number) => {
              Text(log)
                .fontSize(10)
                .fontFamily('monospace')
                .width('100%')
                .padding(6)
                .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F5F5F5')
                .fontColor(log.startsWith('🔄') ? '#4CAF50' : '#333')
            }, (log: string, index: number) => `${index}_${log}`)
          } else {
            Text('暂无请求日志')
              .fontSize(12)
              .fontColor('#999')
              .width('100%')
              .padding(12)
              .textAlign(TextAlign.Center)
          }
        }
      }
      .width('100%')
      .height(180)
      .backgroundColor('#F9F9F9')
      .border({ width: 1, color: '#DDD' })
      .borderRadius(4)
      
      // 说明文字
      Text('💡 URL转换用于拦截和修改资源请求\n常用于：添加认证、使用CDN、离线缓存')
        .fontSize(11)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 8 })
        .lineHeight(16)
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'URL Transform',
        description: 'URL转换',
        showActionBar: false,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      });
    }
    .width('100%')
    .height('100%');
  }
}


