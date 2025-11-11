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
import type {
  OnCanRemoveUnusedStyleImageListener,
  OnGlyphsErrorListener,
  OnGlyphsLoadedListener,
  OnGlyphsRequestedListener,
  OnPreCompileShaderListener,
  OnPostCompileShaderListener,
  OnShaderCompileFailedListener,
  OnSpriteErrorListener,
  OnSpriteLoadedListener,
  OnSpriteRequestedListener,
  OnTileActionListener,
  OnWillStartLoadingMapListener,
  OnDidFinishLoadingMapListener,
  OnDidFailLoadingMapListener,
  OnWillStartRenderingFrameListener,
  OnDidFinishRenderingFrameWithStatsListener,
  OnWillStartRenderingMapListener,
  OnDidFinishRenderingMapListener,
  OnDidFinishLoadingStyleListener,
  OnStyleImageMissingListener,
  OnDidBecomeIdleListener,
  OnSourceChangedListener,
  OnCameraWillChangeListener,
  OnCameraIsChangingListener,
  OnCameraDidChangeListener
} from 'maplibre_harmony';
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
  
  // Shader 编译时间记录
  private shaderTimes: Map<string, number> = new Map();
  
  // 监听器注册标记（确保只注册一次）
  private listenersRegistered: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  /**
   * 早期初始化回调
   * 在 MapView 创建后、地图加载前就调用，用于注册观察者监听器
   * 对齐 Android 模式：在 onCreate 中注册监听器，而不是在 onMapReady 中
   */
  private onMapViewCreated = (map: MapLibreMap): void => {
    console.info('[ObserverTestPage] onMapViewCreated - Early initialization');
    this.mapController = map;
    
    // 立即注册所有观察者监听器（对齐 Android：在 MapView 创建时注册）
    this.registerObservers();
    
    this.logEvent('系统', '✅ MapView 已创建，观察者监听器已注册');
    this.logEvent('系统', '💡 监听器已就绪，将捕获初始加载事件');
  };
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[ObserverTestPage] onMapReady - Map fully loaded');
    
    // 如果之前没有注册（防御性编程），现在注册
    if (!this.listenersRegistered && this.mapController) {
      this.registerObservers();
    }
    
    this.logEvent('系统', '✅ 地图完全加载完成');
    this.logEvent('系统', '💡 提示：点击「重载样式」或「切换样式」按钮触发更多事件');
    
    showToast('地图加载完成');
  };
  
  /**
   * 注册所有观察者监听器（使用真实事件）
   * 使用接口实现类，符合 Android API 风格
   */
  private registerObservers(): void {
    if (!this.mapController) return;
    if (this.listenersRegistered) {
      console.warn('[ObserverTestPage] Listeners already registered, skipping');
      return;
    }
    
    try {
      // ========== Shader 编译监听器 ==========
      const preCompileShaderListener: OnPreCompileShaderListener = (shaderId: number, backendType: number, defines: string) => {
        this.handlePreCompileShader(shaderId, backendType, defines);
      };
      this.mapController.addOnPreCompileShaderListener(preCompileShaderListener);
      
      const postCompileShaderListener: OnPostCompileShaderListener = (shaderId: number, backendType: number, defines: string) => {
        this.handlePostCompileShader(shaderId, backendType, defines);
      };
      this.mapController.addOnPostCompileShaderListener(postCompileShaderListener);
      
      const shaderCompileFailedListener: OnShaderCompileFailedListener = (shaderId: number, backendType: number, defines: string) => {
        this.handleShaderCompileFailed(shaderId, backendType, defines);
      };
      this.mapController.addOnShaderCompileFailedListener(shaderCompileFailedListener);
      
      // ========== Glyph 加载监听器 ==========
      const glyphsRequestedListener: OnGlyphsRequestedListener = (fontStack: string[], rangeStart: number, rangeEnd: number) => {
        this.handleGlyphsRequested(fontStack, rangeStart, rangeEnd);
      };
      this.mapController.addOnGlyphsRequestedListener(glyphsRequestedListener);
      
      const glyphsLoadedListener: OnGlyphsLoadedListener = (fontStack: string[], rangeStart: number, rangeEnd: number) => {
        this.handleGlyphsLoaded(fontStack, rangeStart, rangeEnd);
      };
      this.mapController.addOnGlyphsLoadedListener(glyphsLoadedListener);
      
      const glyphsErrorListener: OnGlyphsErrorListener = (fontStack: string[], rangeStart: number, rangeEnd: number) => {
        this.handleGlyphsError(fontStack, rangeStart, rangeEnd);
      };
      this.mapController.addOnGlyphsErrorListener(glyphsErrorListener);
      
      // ========== Sprite 加载监听器 ==========
      const spriteRequestedListener: OnSpriteRequestedListener = (spriteId: string, url: string) => {
        this.handleSpriteRequested(spriteId, url);
      };
      this.mapController.addOnSpriteRequestedListener(spriteRequestedListener);
      
      const spriteLoadedListener: OnSpriteLoadedListener = (spriteId: string, url: string) => {
        this.handleSpriteLoaded(spriteId, url);
      };
      this.mapController.addOnSpriteLoadedListener(spriteLoadedListener);
      
      const spriteErrorListener: OnSpriteErrorListener = (spriteId: string, url: string) => {
        this.handleSpriteError(spriteId, url);
      };
      this.mapController.addOnSpriteErrorListener(spriteErrorListener);
      
      // ========== Tile 操作监听器 ==========
      const tileActionListener: OnTileActionListener = (
        operation: number,
        x: number,
        y: number,
        z: number,
        wrap: number,
        overscaledZ: number,
        sourceId: string
      ) => {
        this.handleTileAction(operation, x, y, z, wrap, overscaledZ, sourceId);
      };
      this.mapController.addOnTileActionListener(tileActionListener);
      
      console.info('[ObserverTestPage] ✅ 所有观察者监听器已注册（使用接口实现类）');
      console.info('[ObserverTestPage] 监听器将接收来自 MapLibre 核心的真实事件');
      console.info('[ObserverTestPage] C++ NAPI 绑定已完成，事件将实时传递');
      this.logEvent('系统', '✅ 已注册10个观察者监听器（Shader×3, Glyph×3, Sprite×3, Tile×1）');
      
      // 标记监听器已注册
      this.listenersRegistered = true;
    } catch (error) {
      console.error('[ObserverTestPage] 注册监听器失败:', error);
      this.logEvent('系统', `❌ 注册监听器失败: ${error}`);
    }
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
  
  // ========== 监听器回调处理方法 ==========
  
  /**
   * 着色器编译前回调（真实事件）
   */
  public handlePreCompileShader(shaderId: number, backendType: number, defines: string): void {
    const key = `${shaderId}-${backendType}-${defines}`;
    this.shaderTimes.set(key, Date.now());
    this.shaderCompiling = true;
    
    const backendName = backendType === 0 ? 'OpenGL' : 'Vulkan';
    this.logEvent('Shader', `开始编译: ID=${shaderId}, Backend=${backendName}, Defines=${defines}`);
    console.info(`[ObserverTestPage] onPreCompileShader: ${key}`);
  }
  
  /**
   * 着色器编译后回调（真实事件）
   */
  public handlePostCompileShader(shaderId: number, backendType: number, defines: string): void {
    const key = `${shaderId}-${backendType}-${defines}`;
    const startTime = this.shaderTimes.get(key);
    const duration = startTime ? Date.now() - startTime : 0;
    this.shaderTimes.delete(key);
    this.shaderCompiling = false;
    
    const backendName = backendType === 0 ? 'OpenGL' : 'Vulkan';
    this.logEvent('Shader', `编译完成: ID=${shaderId}, Backend=${backendName}, 耗时=${duration}ms`);
    console.info(`[ObserverTestPage] onPostCompileShader: ${key}, duration=${duration}ms`);
  }
  
  /**
   * 着色器编译失败回调（真实事件）
   */
  public handleShaderCompileFailed(shaderId: number, backendType: number, defines: string): void {
    const key = `${shaderId}-${backendType}-${defines}`;
    this.shaderTimes.delete(key);
    this.shaderCompiling = false;
    
    const backendName = backendType === 0 ? 'OpenGL' : 'Vulkan';
    this.logEvent('Shader', `❌ 编译失败: ID=${shaderId}, Backend=${backendName}, Defines=${defines}`);
    console.error(`[ObserverTestPage] onShaderCompileFailed: ${key}`);
  }
  
  /**
   * 字形请求回调（真实事件）
   */
  public handleGlyphsRequested(fontStack: string[], rangeStart: number, rangeEnd: number): void {
    const fonts = fontStack.join(', ');
    this.logEvent('Glyph', `请求字形: ${fonts} [${rangeStart}-${rangeEnd}]`);
    console.info(`[ObserverTestPage] onGlyphsRequested: ${fonts}, range=${rangeStart}-${rangeEnd}`);
  }
  
  /**
   * 字形加载完成回调（真实事件）
   */
  public handleGlyphsLoaded(fontStack: string[], rangeStart: number, rangeEnd: number): void {
    const fonts = fontStack.join(', ');
    this.logEvent('Glyph', `加载完成: ${fonts} [${rangeStart}-${rangeEnd}]`);
    console.info(`[ObserverTestPage] onGlyphsLoaded: ${fonts}, range=${rangeStart}-${rangeEnd}`);
  }
  
  /**
   * 字形加载错误回调（真实事件）
   */
  public handleGlyphsError(fontStack: string[], rangeStart: number, rangeEnd: number): void {
    const fonts = fontStack.join(', ');
    this.logEvent('Glyph', `❌ 加载失败: ${fonts} [${rangeStart}-${rangeEnd}]`);
    console.error(`[ObserverTestPage] onGlyphsError: ${fonts}, range=${rangeStart}-${rangeEnd}`);
  }
  
  /**
   * Sprite 请求回调（真实事件）
   */
  public handleSpriteRequested(spriteId: string, url: string): void {
    this.logEvent('Sprite', `请求: ID=${spriteId}, URL=${url}`);
    console.info(`[ObserverTestPage] onSpriteRequested: ${spriteId}, ${url}`);
  }
  
  /**
   * Sprite 加载完成回调（真实事件）
   */
  public handleSpriteLoaded(spriteId: string, url: string): void {
    this.logEvent('Sprite', `加载完成: ID=${spriteId}, URL=${url}`);
    console.info(`[ObserverTestPage] onSpriteLoaded: ${spriteId}, ${url}`);
  }
  
  /**
   * Sprite 加载错误回调（真实事件）
   */
  public handleSpriteError(spriteId: string, url: string): void {
    this.logEvent('Sprite', `❌ 加载失败: ID=${spriteId}, URL=${url}`);
    console.error(`[ObserverTestPage] onSpriteError: ${spriteId}, ${url}`);
  }
  
  /**
   * 瓦片操作回调（真实事件）
   */
  public handleTileAction(
    operation: number,
    x: number,
    y: number,
    z: number,
    wrap: number,
    overscaledZ: number,
    sourceId: string
  ): void {
    const opNames: string[] = [
      'CacheRequest', 'NetworkRequest', 'CacheLoad', 'NetworkLoad', 'StartParse', 'EndParse'
    ];
    const opName = opNames[operation] || 'Unknown';
    
    // 过滤高频事件（可选）
    // TileOperation 枚举值: 0=CacheRequest, 1=NetworkRequest, 2=CacheLoad, 3=NetworkLoad, 4=StartParse, 5=EndParse
    if (!this.showAllEvents && (operation === 4 || operation === 5)) {
      return;
    }
    
    this.logEvent('Tile', `${opName}: [${z}/${x}/${y}] Source=${sourceId}`);
    console.info(`[ObserverTestPage] onTileAction: ${opName}, tile=${z}/${x}/${y}, source=${sourceId}`);
  }
  
  /**
   * 触发样式重载以产生真实事件
   */
  private reloadStyle = (): void => {
    if (!this.mapController) return;
    
    this.logEvent('系统', '重新加载样式...');
    this.logEvent('系统', '✅ 真实事件将被触发（Shader、Glyph、Sprite、Tile）');
    
    // 切换样式触发真实事件
    const currentStyle = this.mapController.getStyleUrl();
    const newStyle = (currentStyle && currentStyle.includes('bright'))
      ? DEFAULT_STYLE_URLS.streets 
      : DEFAULT_STYLE_URLS.bright;
    
    this.mapController.setStyleUrl(newStyle);
    showToast('样式重载中，观察真实事件...');
  };
  
  /**
   * 切换样式（在不同样式之间切换）
   */
  private switchStyle = (): void => {
    if (!this.mapController) return;
    
    this.logEvent('系统', '切换地图样式...');
    
    // 在多个样式之间循环切换
    const currentStyle = this.mapController.getStyleUrl();
    let newStyle: string;
    
    if (!currentStyle || currentStyle.includes('streets')) {
      newStyle = DEFAULT_STYLE_URLS.bright;
      showToast('切换到 Bright 样式');
    } else if (currentStyle.includes('bright')) {
      newStyle = DEFAULT_STYLE_URLS.satellite;
      showToast('切换到 Satellite 样式');
    } else {
      newStyle = DEFAULT_STYLE_URLS.streets;
      showToast('切换到 Streets 样式');
    }
    
    this.mapController.setStyleUrl(newStyle);
    this.logEvent('系统', `✅ 已切换样式: ${newStyle}`);
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
      onMapViewCreated: this.onMapViewCreated, // 早期回调：在样式加载前注册监听器
      onMapReady: this.onMapReady, // 常规回调：样式加载完成
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
      .width('100%')
      .height('100%');
  }
  
  @Builder
  actionButtonBuilder() {
    Column({ space: 4 }) {
      // 第一行：重载样式、切换样式
      Row({ space: 4 }) {
        Button('重载样式')
          .fontSize(11)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#2196F3')
          .layoutWeight(1)
          .onClick(() => this.reloadStyle())
        
        Button('切换样式')
          .fontSize(11)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#4CAF50')
          .layoutWeight(1)
          .onClick(() => this.switchStyle())
      }
      .width('100%')
      
      // 第二行：清除日志、显示控制
      Row({ space: 4 }) {
        Button('清除日志')
          .fontSize(11)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#FF6B6B')
          .layoutWeight(1)
          .onClick(() => this.clearLog())
        
        Button(this.showAllEvents ? '隐藏高频' : '显示全部')
          .fontSize(11)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.showAllEvents ? '#FF9800' : '#9E9E9E')
          .layoutWeight(1)
          .onClick(() => {
            this.showAllEvents = !this.showAllEvents;
            showToast(this.showAllEvents ? '已显示所有事件' : '已隐藏高频事件');
          })
      }
      .width('100%')
    }
    .width('100%')
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
      Text('💡 事件观察者功能说明')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .width('100%')
        .margin({ top: 8 })
      
      Text('✅ 已实现的监听器（使用真实事件）：\n' +
        '• Shader 编译（Pre/Post/Failed）- 着色器编译事件\n' +
        '• Glyph 加载（Requested/Loaded/Error）- 字形加载事件\n' +
        '• Sprite 加载（Requested/Loaded/Error）- 精灵图加载事件\n' +
        '• Tile 操作（6种类型）- 瓦片缓存/网络/解析事件')
        .fontSize(10)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 4 })
        .lineHeight(16)
      
      Text('\n💡 使用说明：\n' +
        '✅ 所有事件均来自 MapLibre 核心层（非模拟）\n' +
        '• 点击"重载样式"触发 Shader、Glyph、Sprite、Tile 事件\n' +
        '• 地图平移/缩放会触发 Tile 请求和解析事件\n' +
        '• 可切换"显示所有事件"查看高频瓦片解析事件')
        .fontSize(10)
        .fontColor('#2196F3')
        .width('100%')
        .margin({ top: 4 })
        .lineHeight(14)
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
        controlPanel: (): void => this.controlPanelBuilder(),
        actionButtons: (): void => this.actionButtonBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
