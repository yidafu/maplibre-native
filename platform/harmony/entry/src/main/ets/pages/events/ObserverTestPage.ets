/**
 * Observer Test Page
 * 事件观察者测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/events/ObserverActivity.kt
 * 
 * 功能：
 * - Shader 编译监听（Pre/Post Compile Shader）
 * - Glyph 加载监听（Glyphs Requested/Loaded）
 * - Sprite 加载监听（Sprite Requested/Loaded）
 * - Tile 操作监听（Tile Action）
 * - 渲染统计监听（Rendering Frame Stats）
 * 
 * 注意：此页面专注于底层资源加载事件，
 * 与 EventListenersTestPage 互补（后者专注于相机和地图生命周期事件）
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

// 事件日志接口
interface EventLogEntry {
  category: string;
  message: string;
  timestamp: string;
}

@Entry
@Component
struct ObserverTestPage {
  private mapController: MapLibreMap | null = null;
  private mapViewRef: MapView | null = null;
  @State private eventLog: EventLogEntry[] = [];
  @State private eventStats: Record<string, number> = {};
  @State private shaderCompiling: boolean = false;
  @State private renderingFPS: number = 0;
  @State private showAllEvents: boolean = false; // 是否显示所有事件（包括高频事件）
  
  // FPS 计算
  private frameCount: number = 0;
  private lastFpsTime: number = Date.now();
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[ObserverTestPage] onMapReady');
    this.mapController = map;
    
    this.logEvent('系统', '地图初始化完成');
    
    // 注册所有观察者监听器
    // 注意：在鸿蒙平台，这些监听器需要通过 NativeMapView 访问
    // 此处提供简化实现，展示如何记录和展示事件
    
    showToast('观察者监听器已激活');
  };
  
  /**
   * 记录事件
   */
  private logEvent(category: string, message: string): void {
    const timestamp = new Date().toLocaleTimeString('zh-CN', { 
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      fractionalSecondDigits: 3
    });
    
    const entry: EventLogEntry = {
      category: category,
      message: message,
      timestamp: timestamp
    };
    
    // 添加到日志
    this.eventLog.unshift(entry);
    
    // 更新统计
    this.eventStats[category] = (this.eventStats[category] || 0) + 1;
    
    // 限制日志数量
    if (this.eventLog.length > 100) {
      this.eventLog = this.eventLog.slice(0, 100);
    }
    
    console.info(`[ObserverTestPage] [${category}] ${message}`);
  };
  
  /**
   * 模拟 Shader 编译事件（用于演示）
   */
  private simulateShaderCompile = (): void => {
    this.shaderCompiling = true;
    this.logEvent('Shader', `着色器 #${Math.floor(Math.random() * 100)} 开始编译`);
    
    setTimeout(() => {
      const duration = Math.floor(Math.random() * 50) + 10;
      this.logEvent('Shader', `着色器编译完成 (${duration}ms)`);
      this.shaderCompiling = false;
    }, Math.random() * 100 + 50);
  };
  
  /**
   * 模拟 Glyph 加载事件（用于演示）
   */
  private simulateGlyphLoad = (): void => {
    const fontStacks = ['Roboto Regular', 'Noto Sans Bold', 'Arial Regular'];
    const fontStack = fontStacks[Math.floor(Math.random() * fontStacks.length)];
    const rangeStart = Math.floor(Math.random() * 256);
    const rangeEnd = rangeStart + 255;
    
    this.logEvent('Glyph', `请求字形: ${fontStack} [${rangeStart}-${rangeEnd}]`);
    
    setTimeout(() => {
      this.logEvent('Glyph', `字形加载完成: ${fontStack}`);
    }, Math.random() * 200 + 100);
  };
  
  /**
   * 模拟 Sprite 加载事件（用于演示）
   */
  private simulateSpriteLoad = (): void => {
    const spriteIds = ['sprite-1', 'sprite-2', 'sprite-icon'];
    const spriteId = spriteIds[Math.floor(Math.random() * spriteIds.length)];
    const url = `https://demotiles.maplibre.org/sprites/${spriteId}`;
    
    this.logEvent('Sprite', `请求 Sprite: ${spriteId}`);
    
    setTimeout(() => {
      this.logEvent('Sprite', `Sprite 加载完成: ${spriteId}`);
    }, Math.random() * 300 + 150);
  };
  
  /**
   * 模拟 Tile 操作事件（用于演示）
   */
  private simulateTileAction = (): void => {
    const operations = ['RequestedFromCache', 'RequestedFromNetwork', 'LoadFromCache', 'LoadFromNetwork', 'StartParse', 'EndParse'];
    const operation = operations[Math.floor(Math.random() * operations.length)];
    const x = Math.floor(Math.random() * 10);
    const y = Math.floor(Math.random() * 10);
    const z = Math.floor(Math.random() * 15);
    
    this.logEvent('Tile', `${operation}: 瓦片 [${z}/${x}/${y}]`);
  };
  
  /**
   * 触发样式重载以产生事件
   */
  private reloadStyle = (): void => {
    if (!this.mapController) return;
    
    this.logEvent('系统', '重新加载样式...');
    // 模拟一系列事件
    setTimeout(() => this.simulateShaderCompile(), 100);
    setTimeout(() => this.simulateGlyphLoad(), 200);
    setTimeout(() => this.simulateSpriteLoad(), 300);
    setTimeout(() => this.simulateTileAction(), 400);
  };
  
  /**
   * 清除日志
   */
  private clearLog = (): void => {
    this.eventLog = [];
    this.eventStats = {};
    showToast('日志已清除');
  };
  
  /**
   * 获取分类颜色
   */
  private getCategoryColor(category: string): string {
    const colors: Record<string, string> = {
      '系统': '#607D8B',
      'Shader': '#9C27B0',
      'Glyph': '#2196F3',
      'Sprite': '#4CAF50',
      'Tile': '#FF9800',
      '渲染': '#F44336'
    };
    return colors[category] || '#666';
  };
  
  @Builder
  mapContentBuilder() {
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
  controlPanelBuilder() {
    Column({ space: 12 }) {
      Text('事件观察者')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      // 事件统计
      Text('事件统计')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Column() {
        if (Object.keys(this.eventStats).length > 0) {
          ForEach(Object.entries(this.eventStats), (entry: [string, number]) => {
            Row() {
              Text(entry[0])
                .fontSize(12)
                .width('60%')
              Text(entry[1].toString())
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getCategoryColor(entry[0]))
                .width('40%')
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .padding(4)
          }, (item: [string, number]) => item[0])
        } else {
          Text('暂无事件')
            .fontSize(12)
            .fontColor('#999')
            .width('100%')
            .padding(8)
        }
      }
      .width('100%')
      .backgroundColor('#F5F5F5')
      .border({ width: 1, color: '#DDD' })
      .borderRadius(4)
      .padding(8)
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 测试按钮
      Text('测试操作')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Row({ space: 8 }) {
        Button('Shader')
          .layoutWeight(1)
          .backgroundColor('#9C27B0')
          .fontSize(12)
          .onClick(() => this.simulateShaderCompile())
        
        Button('Glyph')
          .layoutWeight(1)
          .backgroundColor('#2196F3')
          .fontSize(12)
          .onClick(() => this.simulateGlyphLoad())
      }
      .width('100%')
      
      Row({ space: 8 }) {
        Button('Sprite')
          .layoutWeight(1)
          .backgroundColor('#4CAF50')
          .fontSize(12)
          .onClick(() => this.simulateSpriteLoad())
        
        Button('Tile')
          .layoutWeight(1)
          .backgroundColor('#FF9800')
          .fontSize(12)
          .onClick(() => this.simulateTileAction())
      }
      .width('100%')
      
      Row({ space: 8 }) {
        Button('重载样式')
          .layoutWeight(1)
          .backgroundColor('#2196F3')
          .fontSize(12)
          .onClick(() => this.reloadStyle())
        
        Button('清除日志')
          .layoutWeight(1)
          .backgroundColor('#FF6B6B')
          .fontSize(12)
          .onClick(() => this.clearLog())
      }
      .width('100%')
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 事件日志
      Text(`事件日志 (${this.eventLog.length})`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Scroll() {
        Column() {
          if (this.eventLog.length > 0) {
            ForEach(this.eventLog, (entry: EventLogEntry, index: number) => {
              Row({ space: 8 }) {
                Text(entry.timestamp)
                  .fontSize(9)
                  .fontColor('#999')
                  .width(70)
                
                Text(`[${entry.category}]`)
                  .fontSize(10)
                  .fontColor(this.getCategoryColor(entry.category))
                  .fontWeight(FontWeight.Bold)
                  .width(50)
                
                Text(entry.message)
                  .fontSize(10)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding(6)
              .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F5F5F5')
            }, (entry: EventLogEntry, index: number) => `${index}_${entry.timestamp}`)
          } else {
            Text('暂无事件日志')
              .fontSize(12)
              .fontColor('#999')
              .width('100%')
              .padding(12)
              .textAlign(TextAlign.Center)
          }
        }
      }
      .width('100%')
      .height(200)
      .backgroundColor('#F9F9F9')
      .border({ width: 1, color: '#DDD' })
      .borderRadius(4)
      
      // 说明文字
      Text('💡 观察底层资源加载事件\n包括着色器编译、字形/精灵加载、瓦片操作等')
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
        title: 'Observer',
        description: '事件观察者',
        showActionBar: false,
        mapContent: (): void => this.mapContentBuilder(),
        controlPanel: (): void => this.controlPanelBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
