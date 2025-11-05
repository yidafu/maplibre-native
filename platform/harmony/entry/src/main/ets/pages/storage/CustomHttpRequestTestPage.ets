/**
 * Custom HTTP Request Test Page
 * 自定义HTTP请求头测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/storage/CustomHttpRequestImplActivity.kt
 * 
 * 功能：
 * - 动态配置和管理HTTP请求头
 * - 使用NetworkConfiguration接口配置请求头
 * - 使用ResourceTransform监听和记录所有网络请求
 * - 通过触发地图加载测试请求头是否生效
 * - 实时显示请求日志（资源类型、URL、时间戳等）
 * 
 * NetworkConfiguration 接口：
 * - NetworkConfiguration.setCustomHttpHeaders(headers): 设置所有自定义请求头
 * - NetworkConfiguration.addCustomHttpHeader(key, value): 添加单个请求头
 * - NetworkConfiguration.removeCustomHttpHeader(key): 移除指定请求头
 * - NetworkConfiguration.clearCustomHttpHeaders(): 清除所有请求头
 * - NetworkConfiguration.getCustomHttpHeaders(): 获取所有请求头
 * 
 * ResourceTransform 接口：
 * - ResourceTransform.setCallback(callback): 设置URL转换回调（用于监听请求）
 * - ResourceTransform.clearCallback(): 清除回调
 * - ResourceTransform.hasCallback(): 检查是否已设置回调
 * 
 * 测试方式：
 * 1. 配置自定义请求头
 * 2. 点击"加载样式"或"移动地图"按钮触发资源请求
 * 3. ResourceTransform会捕获所有请求并记录
 * 4. 在请求日志中查看实际发起的网络请求
 * 5. 在服务器端验证请求头是否正确携带
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, NetworkConfiguration, ResourceTransform, ResourceKind } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

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
  kind: number;
  kindName: string;
  timestamp: string;
  hasHeaders: boolean;
}

// 自定义请求头
interface CustomHeader {
  key: string;
  value: string;
  enabled: boolean;
}

@Entry
@Component
struct CustomHttpRequestTestPage {
  private mapController: MapLibreMap | null = null;
  @State private requestLogs: RequestLog[] = [];
  @State private isMonitoring: boolean = false;
  @State private customHeaders: CustomHeader[] = [
    { key: 'Content-Type', value: 'application/json', enabled: true },
    { key: 'User-Agent', value: 'MapLibre-Harmony-Test', enabled: true },
    { key: 'Accept', value: '*/*', enabled: true },
    { key: 'X-Custom-Test', value: 'test-value', enabled: true },
  ];
  @State private showHeaderEditor: boolean = false;
  @State private editingHeaderKey: string = '';
  @State private editingHeaderValue: string = '';
  @State private useStreetsStyle: boolean = true;  // 用于切换样式
  
  aboutToDisappear() {
    // 清除监听
    try {
      ResourceTransform.clearCallback();
    } catch (e) {
      console.error('[CustomHttpRequestTestPage] Failed to clear callback:', e);
    }
    
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[CustomHttpRequestTestPage] onMapReady');
    this.mapController = map;
    
    // 初始化时应用自定义请求头到MapLibre
    this.applyHeadersToMapLibre();
    
    // 启动请求监听
    this.startMonitoring();
    
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  /**
   * 构建请求头对象
   */
  private buildHeaders(): Record<string, string> {
    const headers: Record<string, string> = {};
    this.customHeaders
      .filter(header => header.enabled && header.key.trim() !== '')
      .forEach(header => {
        headers[header.key] = header.value;
      });
    return headers;
  }
  
  /**
   * 应用请求头到MapLibre Native
   */
  private applyHeadersToMapLibre = (): void => {
    try {
      const headers = this.buildHeaders();
      NetworkConfiguration.setCustomHttpHeaders(headers);
      console.info('[CustomHttpRequestTestPage] Applied headers to MapLibre:', JSON.stringify(headers));
    } catch (e) {
      const error = e as Error;
      console.error('[CustomHttpRequestTestPage] Failed to apply headers to MapLibre:', error.message || String(e));
      showToast('应用请求头失败');
    }
  };
  
  /**
   * 获取 Resource Kind 名称
   */
  private getResourceKindName = (kind: number): string => {
    const names: Record<number, string> = {
      0: 'Unknown',
      1: 'Style',
      2: 'Source',
      3: 'Tile',
      4: 'Glyphs',
      5: 'SpriteImage',
      6: 'SpriteJSON',
      7: 'Image'
    };
    return names[kind] || `Unknown(${kind})`;
  };
  
  /**
   * 启动请求监听
   */
  private startMonitoring = (): void => {
    try {
      ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
        // 记录请求
        this.recordRequest(kind, url);
        
        // 不修改URL，直接返回
        return url;
      });
      
      this.isMonitoring = true;
      console.info('[CustomHttpRequestTestPage] Request monitoring started');
    } catch (e) {
      const error = e as Error;
      console.error('[CustomHttpRequestTestPage] Failed to start monitoring:', error.message || String(e));
      showToast('启动监听失败');
    }
  };
  
  /**
   * 停止请求监听
   */
  private stopMonitoring = (): void => {
    try {
      ResourceTransform.clearCallback();
      this.isMonitoring = false;
      console.info('[CustomHttpRequestTestPage] Request monitoring stopped');
      showToast('已停止监听');
    } catch (e) {
      const error = e as Error;
      console.error('[CustomHttpRequestTestPage] Failed to stop monitoring:', error.message || String(e));
      showToast('停止监听失败');
    }
  };
  
  /**
   * 记录请求
   */
  private recordRequest = (kind: number, url: string): void => {
    const log: RequestLog = {
      url: url,
      kind: kind,
      kindName: this.getResourceKindName(kind),
      timestamp: new Date().toLocaleTimeString(),
      hasHeaders: this.customHeaders.some(h => h.enabled)
    };
    
    this.requestLogs.unshift(log);
    
    // 限制日志数量
    if (this.requestLogs.length > 30) {
      this.requestLogs = this.requestLogs.slice(0, 30);
    }
    
    console.info(`[CustomHttpRequestTestPage] Recorded request: ${this.getResourceKindName(kind)} - ${url}`);
  };
  
  /**
   * 测试样式加载（触发Style请求）
   */
  private testStyleLoad = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 清空日志
      this.requestLogs = [];
      
      // 在 streets 和 bright 之间切换
      const styleUrl = this.useStreetsStyle ? DEFAULT_STYLE_URLS.streets : DEFAULT_STYLE_URLS.bright;
      const styleName = this.useStreetsStyle ? 'Streets' : 'Bright';
      
      // 重新加载样式
      this.mapController.setStyleUrl(styleUrl);
      
      // 切换状态，下次加载另一个样式
      this.useStreetsStyle = !this.useStreetsStyle;
      
      showToast(`正在加载 ${styleName} 样式...`);
      console.info(`[CustomHttpRequestTestPage] Loading ${styleName} style: ${styleUrl}`);
    } catch (e) {
      const error = e as Error;
      console.error('[CustomHttpRequestTestPage] Failed to load style:', error.message || String(e));
      showToast(`加载失败: ${error.message || String(e)}`);
    }
  };
  
  /**
   * 测试瓦片加载（触发Tile请求）
   */
  private testTileLoad = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 清空日志
      this.requestLogs = [];
      
      // 通过移动地图触发瓦片请求
      this.mapController.setZoom(15);
      this.mapController.setLatLng(39.9042, 116.4074);
      showToast('移动地图加载瓦片...');
      console.info('[CustomHttpRequestTestPage] Moving map to trigger tile requests');
    } catch (e) {
      const error = e as Error;
      console.error('[CustomHttpRequestTestPage] Failed to move map:', error.message || String(e));
      showToast(`移动失败: ${error.message || String(e)}`);
    }
  };
  
  /**
   * 清除日志
   */
  private clearLogs = (): void => {
    this.requestLogs = [];
    showToast('已清除日志');
  };
  
  /**
   * 切换请求头启用状态
   */
  private toggleHeader = (index: number): void => {
    this.customHeaders[index].enabled = !this.customHeaders[index].enabled;
    // 同步到MapLibre
    this.applyHeadersToMapLibre();
    showToast(this.customHeaders[index].enabled ? '已启用' : '已禁用');
  };
  
  /**
   * 删除请求头
   */
  private deleteHeader = (index: number): void => {
    this.customHeaders.splice(index, 1);
    // 同步到MapLibre
    this.applyHeadersToMapLibre();
    showToast('请求头已删除');
  };
  
  /**
   * 添加新请求头
   */
  private addHeader = (): void => {
    if (this.editingHeaderKey.trim() === '') {
      showToast('请输入请求头名称');
      return;
    }
    
    // 检查是否已存在
    const exists = this.customHeaders.some(h => h.key === this.editingHeaderKey);
    if (exists) {
      showToast('该请求头已存在');
      return;
    }
    
    this.customHeaders.push({
      key: this.editingHeaderKey.trim(),
      value: this.editingHeaderValue.trim(),
      enabled: true
    });
    
    // 同步到MapLibre
    this.applyHeadersToMapLibre();
    
    // 清空输入
    this.editingHeaderKey = '';
    this.editingHeaderValue = '';
    this.showHeaderEditor = false;
    
    showToast('请求头已添加');
  };
  
  /**
   * 重置为默认请求头
   */
  private resetHeaders = (): void => {
    this.customHeaders = [
      { key: 'Content-Type', value: 'application/json', enabled: true },
      { key: 'User-Agent', value: 'MapLibre-Harmony-Test', enabled: true },
      { key: 'Accept', value: '*/*', enabled: true },
    ];
    // 同步到MapLibre
    this.applyHeadersToMapLibre();
    showToast('已重置为默认请求头');
  };
  
  /**
   * 查看MapLibre中当前的请求头
   */
  private viewMapLibreHeaders = (): void => {
    try {
      const headers: Record<string, string> = NetworkConfiguration.getCustomHttpHeaders();
      console.info('[CustomHttpRequestTestPage] MapLibre headers:', JSON.stringify(headers));
      
      const headerCount = Object.keys(headers).length;
      showToast(`MapLibre已配置${headerCount}个请求头\n查看控制台日志`);
    } catch (e) {
      const error = e as Error;
      console.error('[CustomHttpRequestTestPage] Failed to get MapLibre headers:', error.message || String(e));
      showToast('获取请求头失败');
    }
  };
  
  /**
   * 重新加载地图样式（测试请求头）
   */
  private reloadMapStyle = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 应用当前请求头
      this.applyHeadersToMapLibre();
      
      // 重新加载样式
      this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
      showToast('正在重新加载地图样式...');
      console.info('[CustomHttpRequestTestPage] Reloading map style with custom headers');
    } catch (error) {
      console.error('[CustomHttpRequestTestPage] Failed to reload map style:', error);
      showToast('重新加载失败');
    }
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
      
      // 请求头管理
      Row() {
        Text('请求头配置')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        
        Button('查看')
          .fontSize(12)
          .height(28)
          .padding({ left: 8, right: 8 })
          .backgroundColor('#9C27B0')
          .onClick(() => this.viewMapLibreHeaders())
        
        Button('重置')
          .fontSize(12)
          .height(28)
          .padding({ left: 8, right: 8 })
          .margin({ left: 4 })
          .backgroundColor('#FF9800')
          .onClick(() => this.resetHeaders())
      }
      
      Scroll() {
        Column({ space: 4 }) {
          ForEach(this.customHeaders, (header: CustomHeader, index: number) => {
            Row({ space: 8 }) {
              // 启用/禁用切换
              Checkbox()
                .select(header.enabled)
                .onChange((value: boolean) => this.toggleHeader(index))
                .width(20)
                .height(20)
              
              // 请求头信息
              Column({ space: 2 }) {
                Text(header.key)
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(header.enabled ? '#333' : '#999')
                
                Text(header.value)
                  .fontSize(10)
                  .fontColor(header.enabled ? '#666' : '#BBB')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              
              // 删除按钮
              Button('删除')
                .fontSize(10)
                .height(24)
                .padding({ left: 8, right: 8 })
                .backgroundColor('#FF6B6B')
                .onClick(() => this.deleteHeader(index))
            }
            .padding(8)
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
          }, (header: CustomHeader, index: number) => `${index}_${header.key}`)
          
          // 添加新请求头
          if (this.showHeaderEditor) {
            Column({ space: 8 }) {
              TextInput({ placeholder: '请求头名称 (例如: Authorization)' })
                .fontSize(12)
                .height(32)
                .onChange((value: string) => {
                  this.editingHeaderKey = value;
                })
              
              TextInput({ placeholder: '请求头值 (例如: Bearer token)' })
                .fontSize(12)
                .height(32)
                .onChange((value: string) => {
                  this.editingHeaderValue = value;
                })
              
              Row({ space: 8 }) {
                Button('取消')
                  .layoutWeight(1)
                  .fontSize(12)
                  .height(32)
                  .backgroundColor('#999')
                  .onClick(() => {
                    this.showHeaderEditor = false;
                    this.editingHeaderKey = '';
                    this.editingHeaderValue = '';
                  })
                
                Button('添加')
                  .layoutWeight(1)
                  .fontSize(12)
                  .height(32)
                  .backgroundColor('#4CAF50')
                  .onClick(() => this.addHeader())
              }
            }
            .padding(8)
            .backgroundColor('#E3F2FD')
            .borderRadius(4)
          } else {
            Button('+ 添加请求头')
              .fontSize(12)
              .height(32)
              .backgroundColor('#2196F3')
              .onClick(() => {
                this.showHeaderEditor = true;
              })
          }
        }
      }
      .height(180)
      .backgroundColor('#FAFAFA')
      .border({ width: 1, color: '#DDD' })
      .borderRadius(4)
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 监听状态
      Row() {
        Text('请求监听:')
          .fontSize(12)
          .fontColor('#666')
          .width(80)
        
        Text(this.isMonitoring ? '✓ 已启用' : '✗ 未启用')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isMonitoring ? '#4CAF50' : '#999')
          .layoutWeight(1)
      }
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 测试按钮
      Text('触发请求测试')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
      
      Column({ space: 6 }) {
        Button('🎨 加载样式（Style + Source + SpriteJSON）')
          .fontSize(12)
          .height(36)
          .backgroundColor('#2196F3')
          .onClick(() => this.testStyleLoad())
        
        Button('🗺️ 移动地图（Tile请求）')
          .fontSize(12)
          .height(36)
          .backgroundColor('#4CAF50')
          .onClick(() => this.testTileLoad())
        
        Row({ space: 8 }) {
          Button('查看请求头')
            .layoutWeight(1)
            .fontSize(12)
            .height(36)
            .backgroundColor('#9C27B0')
            .onClick(() => this.viewMapLibreHeaders())
          
          Button('清除日志')
            .layoutWeight(1)
            .fontSize(12)
            .height(36)
            .backgroundColor('#FF6B6B')
            .onClick(() => this.clearLogs())
        }
      }
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 请求日志
      Text(`请求日志 (${this.requestLogs.length})`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
      
      Scroll() {
        Column() {
          if (this.requestLogs.length > 0) {
            ForEach(this.requestLogs, (log: RequestLog, index: number) => {
              Column({ space: 4 }) {
                Row() {
                  Text(log.timestamp)
                    .fontSize(10)
                    .fontColor('#999')
                  
                  Text(log.kindName)
                    .fontSize(10)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#2196F3')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .backgroundColor('#E3F2FD')
                    .borderRadius(2)
                    .margin({ left: 8 })
                  
                  if (log.hasHeaders) {
                    Text('📝')
                      .fontSize(10)
                      .margin({ left: 4 })
                  }
                }
                
                Text(log.url.length > 60 ? log.url.substring(0, 60) + '...' : log.url)
                  .fontSize(9)
                  .fontFamily('monospace')
                  .fontColor('#333')
              }
              .padding(8)
              .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F5F5F5')
              .borderRadius(4)
              .border({ width: 1, color: '#E0E0E0' })
              .margin({ bottom: 4 })
            }, (log: RequestLog, index: number) => `${index}_${log.timestamp}`)
          } else {
            Text('暂无请求日志\n\n触发地图加载以查看请求记录')
              .fontSize(12)
              .fontColor('#999')
              .padding(16)
              .textAlign(TextAlign.Center)
          }
        }
      }
      .height(180)
      .backgroundColor('#F9F9F9')
      .border({ width: 1, color: '#DDD' })
      .borderRadius(4)
      
      // 说明文字
      Column({ space: 4 }) {
        Text('💡 功能说明')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        
        Text('1. 配置请求头后自动同步到MapLibre Native')
          .fontSize(10)
          .fontColor('#666')
        
        Text('2. 使用ResourceTransform监听所有网络请求')
          .fontSize(10)
          .fontColor('#666')
        
        Text('3. 触发地图加载测试请求头是否生效')
          .fontSize(10)
          .fontColor('#666')
        
        Text('4. 查看控制台日志确认请求详情')
          .fontSize(10)
          .fontColor('#666')
      }
      .padding(8)
      .backgroundColor('#E3F2FD')
      .borderRadius(4)
      .margin({ top: 8 })
    }
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


