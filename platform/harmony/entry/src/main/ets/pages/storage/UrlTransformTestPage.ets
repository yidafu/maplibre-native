/**
 * UrlTransformTestPage - URL转换功能测试页面
 * 
 * 测试 MapLibre Native URL 转换 API 的各种使用场景
 * 
 * MapLibre Native 接口：
 * - setResourceTransformCallback(callback): 设置URL转换回调
 * - clearResourceTransformCallback(): 清除URL转换回调
 * - hasResourceTransformCallback(): 检查是否已设置回调
 * 
 * 回调函数签名: (kind: number, url: string) => string
 * 
 * Resource Kind 类型:
 * - 0: Unknown
 * - 1: Style
 * - 2: Source
 * - 3: Tile
 * - 4: Glyphs
 * - 5: SpriteImage
 * - 6: SpriteJSON
 * - 7: Image
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, ResourceTransform, ResourceKind } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

// 转换记录接口
interface TransformRecord {
  timestamp: string;
  kind: number;
  kindName: string;
  originalUrl: string;
  transformedUrl: string;
}

@Entry
@Component
struct UrlTransformTestPage {
  private mapController: MapLibreMap | null = null;
  @State private transformActive: boolean = false;
  @State private transformedCount: number = 0;
  @State private transformRecords: TransformRecord[] = [];
  @State private currentStrategy: string = '无';
  @State private useStreetsStyle: boolean = true;  // 用于切换样式
  
  aboutToDisappear() {
    console.info('[UrlTransformTestPage] Page is about to disappear');
    
    // 清理资源
    try {
      ResourceTransform.clearCallback();
    } catch (e) {
      const error = e as Error;
      console.error('[UrlTransformTestPage] Failed to clear callback:', error.message || String(e));
    }
    
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }

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
   * 记录转换
   */
  private recordTransform = (kind: number, originalUrl: string, transformedUrl: string): void => {
    const record: TransformRecord = {
      timestamp: new Date().toLocaleTimeString(),
      kind: kind,
      kindName: this.getResourceKindName(kind),
      originalUrl: originalUrl,
      transformedUrl: transformedUrl
    };
    
    this.transformRecords.unshift(record);
    this.transformedCount++;
    
    // 限制记录数量
    if (this.transformRecords.length > 20) {
      this.transformRecords = this.transformRecords.slice(0, 20);
    }
    
    console.info(`[UrlTransformTestPage] Recorded transform: ${this.getResourceKindName(kind)} - ${originalUrl}`);
  };
  
  /**
   * 地图就绪回调
   */
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[UrlTransformTestPage] Map is ready');
    this.mapController = map;
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  /**
   * 测试1: 简单记录（不修改URL）
   */
  private testSimpleLog = (): void => {
    try {
      this.clearRecords();
      
      ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
        console.info(`[URLTransform] kind=${this.getResourceKindName(kind)}, url=${url}`);
        this.recordTransform(kind, url, url);
        return url;  // 不修改URL
      });
      
      this.transformActive = true;
      this.currentStrategy = '简单记录（不修改）';
      showToast('已启用简单记录模式');
      console.info('[UrlTransformTestPage] Simple log transform enabled');
      
    } catch (e) {
      const error = e as Error;
      const errorMsg = error.message || String(e);
      console.error('[UrlTransformTestPage] Failed to set simple log:', errorMsg);
      showToast(`设置失败: ${errorMsg}`);
    }
  };

  /**
   * 测试2: CDN切换
   */
  private testCdnSwitch = (): void => {
    try {
      this.clearRecords();
      
      ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
        // 将 demotiles.maplibre.org 替换为自定义CDN
        let transformed = url;
        if (url.includes('demotiles.maplibre.org')) {
          transformed = url.replace('demotiles.maplibre.org', 'cdn.example.com');
          console.info(`[URLTransform] CDN switched: ${url} -> ${transformed}`);
        }
        
        this.recordTransform(kind, url, transformed);
        return transformed;
      });
      
      this.transformActive = true;
      this.currentStrategy = 'CDN切换';
      showToast('已启用CDN切换模式');
      console.info('[UrlTransformTestPage] CDN switch enabled');
      
    } catch (e) {
      const error = e as Error;
      const errorMsg = error.message || String(e);
      console.error('[UrlTransformTestPage] Failed to set CDN switch:', errorMsg);
      showToast(`设置失败: ${errorMsg}`);
    }
  };

  /**
   * 测试3: 资源类型过滤（只转换Tile）
   */
  private testTileFilter = (): void => {
    try {
      this.clearRecords();
      
      ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
        let transformed = url;
        
        // 只转换瓦片请求
        if (kind === ResourceKind.Tile) {
          const separator = url.includes('?') ? '&' : '?';
          transformed = `${url}${separator}tile_filtered=true`;
          console.info(`[URLTransform] Tile filtered: ${url}`);
        }
        
        this.recordTransform(kind, url, transformed);
        return transformed;
      });
      
      this.transformActive = true;
      this.currentStrategy = '瓦片过滤（只转换Tile）';
      showToast('已启用瓦片过滤模式');
      console.info('[UrlTransformTestPage] Tile filter enabled');
      
    } catch (e) {
      const error = e as Error;
      const errorMsg = error.message || String(e);
      console.error('[UrlTransformTestPage] Failed to set tile filter:', errorMsg);
      showToast(`设置失败: ${errorMsg}`);
    }
  };

  /**
   * 测试4: 添加认证参数
   */
  private testAuthParams = (): void => {
    try {
      this.clearRecords();
      
      ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
        // 为所有请求添加token参数
        const token = 'test-token-12345';
        const separator = url.includes('?') ? '&' : '?';
        const transformed = `${url}${separator}access_token=${token}`;
        
        console.info(`[URLTransform] Auth added to ${this.getResourceKindName(kind)}: ${url}`);
        this.recordTransform(kind, url, transformed);
        
        return transformed;
      });
      
      this.transformActive = true;
      this.currentStrategy = '认证参数';
      showToast('已启用认证参数模式');
      console.info('[UrlTransformTestPage] Auth params enabled');
      
    } catch (e) {
      const error = e as Error;
      const errorMsg = error.message || String(e);
      console.error('[UrlTransformTestPage] Failed to set auth params:', errorMsg);
      showToast(`设置失败: ${errorMsg}`);
    }
  };

  /**
   * 测试5: URL前缀替换
   */
  private testPrefixReplace = (): void => {
    try {
      this.clearRecords();
      
      ResourceTransform.setCallback((kind: ResourceKind, url: string): string => {
        // 将 https:// 替换为自定义协议
        let transformed = url;
        if (url.startsWith('https://')) {
          transformed = url.replace('https://', 'https://proxy.example.com/');
          console.info(`[URLTransform] Prefix replaced: ${url} -> ${transformed}`);
        }
        
        this.recordTransform(kind, url, transformed);
        return transformed;
      });
      
      this.transformActive = true;
      this.currentStrategy = 'URL前缀替换';
      showToast('已启用前缀替换模式');
      console.info('[UrlTransformTestPage] Prefix replace enabled');
      
    } catch (e) {
      const error = e as Error;
      const errorMsg = error.message || String(e);
      console.error('[UrlTransformTestPage] Failed to set prefix replace:', errorMsg);
      showToast(`设置失败: ${errorMsg}`);
    }
  };

  /**
   * 清除转换回调
   */
  private clearTransform = (): void => {
    try {
      ResourceTransform.clearCallback();
      this.transformActive = false;
      this.currentStrategy = '无';
      
      showToast('已清除URL转换');
      console.info('[UrlTransformTestPage] Transform cleared');
      
    } catch (e) {
      const error = e as Error;
      const errorMsg = error.message || String(e);
      console.error('[UrlTransformTestPage] Failed to clear transform:', errorMsg);
      showToast(`清除失败: ${errorMsg}`);
    }
  };
  
  /**
   * 清除记录
   */
  private clearRecords = (): void => {
    this.transformRecords = [];
    this.transformedCount = 0;
  };

  /**
   * 检查回调状态
   */
  private checkCallbackStatus = (): void => {
    try {
      const hasCallback = ResourceTransform.hasCallback();
      showToast(hasCallback ? '✅ 已设置回调' : '❌ 未设置回调');
      console.info('[UrlTransformTestPage] Has callback:', hasCallback);
    } catch (e) {
      const error = e as Error;
      const errorMsg = error.message || String(e);
      console.error('[UrlTransformTestPage] Failed to check callback:', errorMsg);
      showToast(`检查失败: ${errorMsg}`);
    }
  };

  /**
   * 重新加载地图（触发新的资源请求）
   */
  private reloadMap = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 在 streets 和 bright 之间切换
      const styleUrl = this.useStreetsStyle ? DEFAULT_STYLE_URLS.streets : DEFAULT_STYLE_URLS.bright;
      const styleName = this.useStreetsStyle ? 'Streets' : 'Bright';
      
      // 通过修改样式URL来触发重新加载
      this.mapController.setStyleUrl(styleUrl);
      
      // 切换状态，下次加载另一个样式
      this.useStreetsStyle = !this.useStreetsStyle;
      
      showToast(`正在加载 ${styleName} 样式...`);
      console.info(`[UrlTransformTestPage] Loading ${styleName} style: ${styleUrl}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[UrlTransformTestPage] Failed to reload map:', errorMsg);
      showToast(`重新加载失败: ${errorMsg}`);
    }
  };

  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 12
    })
      .width('100%')
      .height('100%');
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('URL转换测试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      // 状态信息
      Column({ space: 8 }) {
        Row() {
          Text('当前策略:')
            .fontSize(12)
            .fontColor('#666')
            .width(80)
          
          Text(this.currentStrategy)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.transformActive ? '#4CAF50' : '#999')
            .layoutWeight(1)
        }
        
        Row() {
          Text('转换次数:')
            .fontSize(12)
            .fontColor('#666')
            .width(80)
          
          Text(`${this.transformedCount}`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
            .layoutWeight(1)
        }
        
        Row() {
          Text('记录数量:')
            .fontSize(12)
            .fontColor('#666')
            .width(80)
          
          Text(`${this.transformRecords.length}`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9800')
        }
      }
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)

      Divider().margin({ top: 4, bottom: 4 })
      
      // 测试按钮
      Text('测试场景')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
      
      Column({ space: 6 }) {
        Button('简单记录（不修改URL）')
          .fontSize(12)
          .height(36)
          .backgroundColor('#2196F3')
          .onClick(() => this.testSimpleLog())
        
        Button('CDN切换测试')
          .fontSize(12)
          .height(36)
          .backgroundColor('#4CAF50')
          .onClick(() => this.testCdnSwitch())
        
        Button('瓦片过滤（只转换Tile）')
          .fontSize(12)
          .height(36)
          .backgroundColor('#FF9800')
          .onClick(() => this.testTileFilter())
        
        Button('认证参数（添加Token）')
          .fontSize(12)
          .height(36)
          .backgroundColor('#9C27B0')
          .onClick(() => this.testAuthParams())
        
        Button('URL前缀替换')
          .fontSize(12)
          .height(36)
          .backgroundColor('#00BCD4')
          .onClick(() => this.testPrefixReplace())
      }
      
      // 控制按钮
      Row({ space: 8 }) {
        Button('🗺️ 重新加载')
          .layoutWeight(1)
          .fontSize(12)
          .height(36)
          .backgroundColor('#673AB7')
          .onClick(() => this.reloadMap())
        
        Button('🔍 检查状态')
          .layoutWeight(1)
          .fontSize(12)
          .height(36)
          .backgroundColor('#607D8B')
          .onClick(() => this.checkCallbackStatus())
        
        Button('❌ 清除')
          .layoutWeight(1)
          .fontSize(12)
          .height(36)
          .backgroundColor('#FF6B6B')
          .onClick(() => this.clearTransform())
      }
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 转换记录
      Text(`转换记录 (${this.transformRecords.length})`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
      
      Scroll() {
        Column() {
          if (this.transformRecords.length > 0) {
            ForEach(this.transformRecords, (record: TransformRecord, index: number) => {
              Column({ space: 4 }) {
                Row() {
                  Text(record.timestamp)
                    .fontSize(10)
                    .fontColor('#999')
                  
                  Text(record.kindName)
                    .fontSize(10)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#2196F3')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .backgroundColor('#E3F2FD')
                    .borderRadius(2)
                    .margin({ left: 8 })
                }
                
                Text('原始URL:')
                  .fontSize(9)
                  .fontColor('#666')
                
                Text(record.originalUrl.length > 60 ? 
                  record.originalUrl.substring(0, 60) + '...' : 
                  record.originalUrl)
                  .fontSize(9)
                  .fontFamily('monospace')
                  .fontColor('#333')
                
                if (record.originalUrl !== record.transformedUrl) {
                  Text('转换后:')
                    .fontSize(9)
                    .fontColor('#666')
                  
                  Text(record.transformedUrl.length > 60 ? 
                    record.transformedUrl.substring(0, 60) + '...' : 
                    record.transformedUrl)
                    .fontSize(9)
                    .fontFamily('monospace')
                    .fontColor('#4CAF50')
                }
              }
              .padding(8)
              .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F5F5F5')
              .borderRadius(4)
              .border({ width: 1, color: '#E0E0E0' })
              .margin({ bottom: 4 })
            }, (record: TransformRecord, index: number) => `${index}_${record.timestamp}`)
          } else {
            Text('暂无转换记录')
              .fontSize(12)
              .fontColor('#999')
              .padding(12)
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
          }
        }.layoutWeight(1)
      }
      .height(200)
      .backgroundColor('#FAFAFA')
      .border({ width: 1, color: '#DDD' })
      .borderRadius(4)
      
      // 说明文字
      Column({ space: 4 }) {
        Text('💡 使用说明')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        
        Text('1. 选择测试场景启用URL转换')
          .fontSize(10)
          .fontColor('#666')
        
        Text('2. 重新加载地图触发资源请求')
          .fontSize(10)
          .fontColor('#666')
        
        Text('3. 查看转换记录和控制台日志')
          .fontSize(10)
          .fontColor('#666')
        
        Text('4. 注意：修改后的URL可能无法访问')
          .fontSize(10)
          .fontColor('#FF6B6B')
      }
      .padding(8)
      .backgroundColor('#FFF3CD')
      .borderRadius(4)
      .margin({ top: 8 })
    }
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'URL Transform Test',
        description: 'URL转换功能测试',
        showActionBar: false,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      });
    }
    .width('100%')
    .height('100%');
  }
}
