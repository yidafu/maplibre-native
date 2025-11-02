/**
 * Custom HTTP Request Test Page
 * 自定义HTTP请求测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/storage/CustomHttpRequestImplActivity.kt
 * 
 * 功能：
 * - 演示如何使用鸿蒙的 @kit.NetworkKit 进行HTTP请求
 * - 测试网络请求功能
 * - 展示请求统计信息
 * - 错误处理示例
 * 
 * 注意：
 * 在 Android 中可以通过 ModuleProvider 自定义 HTTP 实现，
 * 在鸿蒙平台中使用 @kit.NetworkKit 提供的 HTTP 客户端。
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';
import { http } from '@kit.NetworkKit';

// 请求统计接口
interface RequestStats {
  total: number;
  success: number;
  failed: number;
  totalTime: number;
}

// 请求日志条目
interface RequestLog {
  url: string;
  status: number;
  time: number;
  timestamp: string;
  error?: string;
}

@Entry
@Component
struct CustomHttpRequestTestPage {
  private mapController: MapLibreMap | null = null;
  @State private stats: RequestStats = {
    total: 0,
    success: 0,
    failed: 0,
    totalTime: 0
  };
  @State private requestLogs: RequestLog[] = [];
  @State private isRequesting: boolean = false;
  
  // 测试 URL 列表
  private testUrls: string[] = [
    'https://demotiles.maplibre.org/style.json',
    'https://demotiles.maplibre.org/tiles/0/0/0.pbf',
  ];
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[CustomHttpRequestTestPage] onMapReady');
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  /**
   * 执行自定义 HTTP 请求
   */
  private testCustomRequest = async (url: string): Promise<void> => {
    if (this.isRequesting) return;
    
    this.isRequesting = true;
    const startTime = Date.now();
    
    try {
      // 创建 HTTP 请求实例
      const httpRequest = http.createHttp();
      
      // 配置请求选项
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'User-Agent': 'MapLibre-Harmony-Test'
        },
        readTimeout: 30000,
        connectTimeout: 30000
      };
      
      console.info(`[CustomHttpRequestTestPage] Requesting: ${url}`);
      
      // 发起请求
      const response = await httpRequest.request(url, options);
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      // 更新统计
      this.stats.total++;
      this.stats.totalTime += duration;
      
      if (response.responseCode === http.ResponseCode.OK) {
        this.stats.success++;
        
        // 记录成功日志
        this.addRequestLog({
          url: url,
          status: response.responseCode,
          time: duration,
          timestamp: new Date().toLocaleTimeString()
        });
        
        showToast(`✅ 请求成功 (${duration}ms)`);
        console.info(`[CustomHttpRequestTestPage] Success: ${response.responseCode}, ${duration}ms`);
      } else {
        this.stats.failed++;
        
        // 记录失败日志
        this.addRequestLog({
          url: url,
          status: response.responseCode,
          time: duration,
          timestamp: new Date().toLocaleTimeString(),
          error: `HTTP ${response.responseCode}`
        });
        
        showToast(`❌ 请求失败: ${response.responseCode}`);
        console.error(`[CustomHttpRequestTestPage] Failed: ${response.responseCode}`);
      }
      
      // 销毁请求实例
      httpRequest.destroy();
      
    } catch (error) {
      const endTime = Date.now();
      const duration = endTime - startTime;
      const errorMsg = error instanceof Error ? error.message : String(error);
      
      // 更新统计
      this.stats.total++;
      this.stats.failed++;
      this.stats.totalTime += duration;
      
      // 记录错误日志
      this.addRequestLog({
        url: url,
        status: 0,
        time: duration,
        timestamp: new Date().toLocaleTimeString(),
        error: errorMsg
      });
      
      showToast(`❌ 请求异常: ${errorMsg}`);
      console.error(`[CustomHttpRequestTestPage] Exception:`, errorMsg);
    } finally {
      this.isRequesting = false;
    }
  };
  
  /**
   * 添加请求日志
   */
  private addRequestLog(log: RequestLog): void {
    this.requestLogs.unshift(log);
    
    // 限制日志数量
    if (this.requestLogs.length > 20) {
      this.requestLogs = this.requestLogs.slice(0, 20);
    }
  };
  
  /**
   * 测试样式 JSON 请求
   */
  private testStyleRequest = (): void => {
    this.testCustomRequest(this.testUrls[0]);
  };
  
  /**
   * 测试瓦片请求
   */
  private testTileRequest = (): void => {
    this.testCustomRequest(this.testUrls[1]);
  };
  
  /**
   * 清除统计和日志
   */
  private clearStats = (): void => {
    this.stats = {
      total: 0,
      success: 0,
      failed: 0,
      totalTime: 0
    };
    this.requestLogs = [];
    showToast('统计已清除');
  };
  
  /**
   * 获取平均请求时间
   */
  private getAverageTime(): string {
    if (this.stats.total === 0) return '0';
    return (this.stats.totalTime / this.stats.total).toFixed(0);
  };
  
  /**
   * 获取成功率
   */
  private getSuccessRate(): string {
    if (this.stats.total === 0) return '0';
    return ((this.stats.success / this.stats.total) * 100).toFixed(1);
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
      Text('自定义HTTP请求')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      // 统计面板
      Row({ space: 8 }) {
        Column() {
          Text(`${this.stats.total}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
          Text('总请求')
            .fontSize(11)
            .fontColor('#666')
        }
        .layoutWeight(1)
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        
        Column() {
          Text(`${this.stats.success}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          Text('成功')
            .fontSize(11)
            .fontColor('#666')
        }
        .layoutWeight(1)
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        
        Column() {
          Text(`${this.stats.failed}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
          Text('失败')
            .fontSize(11)
            .fontColor('#666')
        }
        .layoutWeight(1)
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
      }
      .width('100%')
      
      Row({ space: 8 }) {
        Column() {
          Text(`${this.getAverageTime()}ms`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9800')
          Text('平均耗时')
            .fontSize(11)
            .fontColor('#666')
        }
        .layoutWeight(1)
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        
        Column() {
          Text(`${this.getSuccessRate()}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#9C27B0')
          Text('成功率')
            .fontSize(11)
            .fontColor('#666')
        }
        .layoutWeight(1)
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
      }
      .width('100%')
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 测试按钮
      Text('测试请求')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Row({ space: 8 }) {
        Button('Style')
          .layoutWeight(1)
          .backgroundColor('#2196F3')
          .onClick(() => this.testStyleRequest())
          .enabled(!this.isRequesting)
        
        Button('Tile')
          .layoutWeight(1)
          .backgroundColor('#4CAF50')
          .onClick(() => this.testTileRequest())
          .enabled(!this.isRequesting)
        
        Button('清除')
          .layoutWeight(1)
          .backgroundColor('#FF6B6B')
          .onClick(() => this.clearStats())
          .enabled(!this.isRequesting)
      }
      .width('100%')
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 请求日志
      Text(`请求日志 (${this.requestLogs.length})`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Scroll() {
        Column() {
          if (this.requestLogs.length > 0) {
            ForEach(this.requestLogs, (log: RequestLog, index: number) => {
              Column({ space: 4 }) {
                Row() {
                  Text(log.timestamp)
                    .fontSize(10)
                    .fontColor('#999')
                    .layoutWeight(1)
                  
                  Text(log.error ? '❌' : '✅')
                    .fontSize(12)
                  
                  Text(`${log.time}ms`)
                    .fontSize(10)
                    .fontColor('#666')
                }
                .width('100%')
                
                Text(log.url.length > 40 ? log.url.substring(0, 40) + '...' : log.url)
                  .fontSize(10)
                  .fontFamily('monospace')
                  .fontColor('#333')
                  .width('100%')
                
                if (log.error) {
                  Text(`错误: ${log.error}`)
                    .fontSize(9)
                    .fontColor('#FF6B6B')
                    .width('100%')
                }
              }
              .width('100%')
              .padding(8)
              .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F5F5F5')
              .borderRadius(4)
            }, (log: RequestLog, index: number) => `${index}_${log.timestamp}`)
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
      .height(160)
      .backgroundColor('#F9F9F9')
      .border({ width: 1, color: '#DDD' })
      .borderRadius(4)
      
      // 说明文字
      Text('💡 使用 @kit.NetworkKit 进行 HTTP 请求\n可配置超时、请求头等参数')
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
        title: 'Custom HTTP Request',
        description: '自定义HTTP请求',
        showActionBar: false,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      });
    }
    .width('100%')
    .height('100%');
  }
}


