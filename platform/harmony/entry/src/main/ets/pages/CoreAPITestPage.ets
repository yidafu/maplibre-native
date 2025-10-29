/**
 * 核心 API 测试页面
 * 测试新增的 Android/iOS 对齐 API 和核心功能
 */
import router from '@ohos.router';
import { maplibre } from 'maplibre_harmony';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { DOMAIN } from '../constants/HiLogConstants';
import { TestPageLayout } from '../components/TestPageLayout';

type NullableNativeMapView = maplibre.NativeMapView | null;

@Entry
@Component
struct CoreAPITestPage {
  private mapView: NullableNativeMapView = null;
  @State private testResults: string[] = [];
  @State private currentPadding: number[] = [0, 0, 0, 0];
  @State private pixelRatio: number = 1.0;
  @State private showPaddingOverlay: boolean = true;
  
  aboutToAppear() {
    hilog.info(DOMAIN, 'CoreAPITestPage', 'Page aboutToAppear');
  }
  
  aboutToDisappear() {
    hilog.info(DOMAIN, 'CoreAPITestPage', 'Page aboutToDisappear');
  }
  
  /**
   * 添加测试结果
   */
  private addTestResult(result: string): void {
    this.testResults.push(`[${new Date().toLocaleTimeString()}] ${result}`);
    if (this.testResults.length > 20) {
      this.testResults.shift(); // 保持最多 20 条
    }
  }
  
  /**
   * 测试内容边距 API
   */
  private testContentPadding(): void {
    if (!this.mapView) {
      this.addTestResult('❌ Map not initialized');
      return;
    }
    
    try {
      // 测试设置边距
      const newPadding = [100, 50, 80, 50];
      this.mapView.setContentPadding(newPadding);
      this.addTestResult(`✅ setContentPadding: [${newPadding.join(', ')}]`);
      
      // 测试获取边距
      const padding = this.mapView.getContentPadding();
      this.currentPadding = padding as number[];
      this.addTestResult(`✅ getContentPadding: [${this.currentPadding.join(', ')}]`);
      
      // 验证值是否正确
      if (JSON.stringify(padding) === JSON.stringify(newPadding)) {
        this.addTestResult('✅ 边距设置验证成功');
      } else {
        this.addTestResult(`❌ 边距验证失败: 期望 [${newPadding.join(',')}], 实际 [${padding.join(',')}]`);
      }
    } catch (error) {
      this.addTestResult(`❌ 内容边距测试失败: ${error.message}`);
    }
  }
  
  /**
   * 测试像素比例 API
   */
  private testPixelRatio(): void {
    if (!this.mapView) {
      this.addTestResult('❌ Map not initialized');
      return;
    }
    
    try {
      const ratio = this.mapView.getPixelRatio();
      this.pixelRatio = ratio as number;
      this.addTestResult(`✅ getPixelRatio: ${this.pixelRatio.toFixed(2)}x`);
      
      // 测试矩形转换
      const logicalRect: maplibre.Rect = { left: 100, top: 100, right: 300, bottom: 300 } as maplibre.Rect;
      const physicalRect = this.mapView.getDensityDependantRectangle(logicalRect);
      
      this.addTestResult(`✅ 逻辑矩形: [${logicalRect.left}, ${logicalRect.top}, ${logicalRect.right}, ${logicalRect.bottom}]`);
      this.addTestResult(`✅ 物理矩形: [${physicalRect.left.toFixed(1)}, ${physicalRect.top.toFixed(1)}, ${physicalRect.right.toFixed(1)}, ${physicalRect.bottom.toFixed(1)}]`);
      
      // 验证计算
      const expectedLeft = logicalRect.left / this.pixelRatio;
      if (Math.abs(physicalRect.left - expectedLeft) < 0.01) {
        this.addTestResult('✅ 矩形转换计算正确');
      } else {
        this.addTestResult(`❌ 矩形转换计算错误`);
      }
    } catch (error) {
      this.addTestResult(`❌ 像素比例测试失败: ${error.message}`);
    }
  }
  
  /**
   * 测试相机控制 API
   */
  private testCameraControl(): void {
    if (!this.mapView) {
      this.addTestResult('❌ Map not initialized');
      return;
    }
    
    try {
      // 测试 jumpTo
      this.mapView.jumpTo(0, 39.9042, 116.4074, 0, 12); // 北京
      this.addTestResult('✅ jumpTo: 跳转到北京');
      
      setTimeout(() => {
        if (!this.mapView) return;
        
        // 测试 getLatLng
        const center: maplibre.LatLng = this.mapView.getLatLng();
        this.addTestResult(`✅ getLatLng: (${center.latitude.toFixed(4)}, ${center.longitude.toFixed(4)})`);
        
        // 测试 getZoom
        const zoom: number = this.mapView.getZoom();
        this.addTestResult(`✅ getZoom: ${zoom.toFixed(2)}`);
        
        // 测试 getBearing
        const bearing: number = this.mapView.getBearing();
        this.addTestResult(`✅ getBearing: ${bearing.toFixed(2)}°`);
        
        // 测试 getPitch
        const pitch: number = this.mapView.getPitch();
        this.addTestResult(`✅ getPitch: ${pitch.toFixed(2)}°`);
      }, 500);
      
      // 测试 easeTo
      setTimeout(() => {
        if (!this.mapView) return;
        this.mapView.easeTo({
          center: new maplibre.LatLng(31.2304, 121.4737), // 上海
          zoom: 14,
          bearing: 45,
          pitch: 30
        }, 2000);
        this.addTestResult('✅ easeTo: 飞行到上海（2秒动画）');
      }, 1500);
    } catch (error) {
      this.addTestResult(`❌ 相机控制测试失败: ${error.message}`);
    }
  }
  
  /**
   * 测试缩放和俯仰角限制
   */
  private testZoomPitchLimits(): void {
    if (!this.mapView) {
      this.addTestResult('❌ Map not initialized');
      return;
    }
    
    try {
      // 设置缩放限制
      this.mapView.setMinZoom(5);
      this.mapView.setMaxZoom(18);
      const minZoom: number = this.mapView.getMinZoom();
      const maxZoom: number = this.mapView.getMaxZoom();
      this.addTestResult(`✅ 缩放范围: ${minZoom.toFixed(1)} - ${maxZoom.toFixed(1)}`);
      
      // 设置俯仰角限制
      this.mapView.setMinPitch(0);
      this.mapView.setMaxPitch(60);
      const minPitch = this.mapView.getMinPitch();
      const maxPitch = this.mapView.getMaxPitch();
      this.addTestResult(`✅ 俯仰角范围: ${minPitch.toFixed(1)}° - ${maxPitch.toFixed(1)}°`);
    } catch (error) {
      this.addTestResult(`❌ 限制测试失败: ${error.message}`);
    }
  }
  
  /**
   * 测试坐标转换 API
   */
  private testCoordinateConversion(): void {
    if (!this.mapView) {
      this.addTestResult('❌ Map not initialized');
      return;
    }
    
    try {
      // 测试 latLng -> pixel
      const latLng = new maplibre.LatLng(39.9042, 116.4074);
      const pixel = this.mapView.pixelForLatLng(latLng.latitude, latLng.longitude);
      this.addTestResult(`✅ pixelForLatLng: (${pixel.x.toFixed(1)}, ${pixel.y.toFixed(1)})`);
      
      // 测试 pixel -> latLng
      const convertedLatLng = this.mapView.latLngForPixel(pixel.x, pixel.y);
      this.addTestResult(`✅ latLngForPixel: (${convertedLatLng.latitude.toFixed(4)}, ${convertedLatLng.longitude.toFixed(4)})`);
      
      // 测试投影米坐标
      const projectedMeters = this.mapView.projectedMetersForLatLng(39.9042, 116.4074);
      this.addTestResult(`✅ projectedMeters: northing=${projectedMeters.northing.toFixed(2)}, easting=${projectedMeters.easting.toFixed(2)}`);
    } catch (error) {
      this.addTestResult(`❌ 坐标转换测试失败: ${error.message}`);
    }
  }
  
  /**
   * 测试瓦片管理 API
   */
  private testTileManagement(): void {
    if (!this.mapView) {
      this.addTestResult('❌ Map not initialized');
      return;
    }
    
    try {
      // 测试预加载设置
      this.mapView.setPrefetchTiles(true);
      const prefetch = this.mapView.getPrefetchTiles();
      this.addTestResult(`✅ 瓦片预加载: ${prefetch ? '启用' : '禁用'}`);
      
      // 测试 LOD 设置
      this.mapView.setTileLodMinRadius(1.0);
      const lodMinRadius = this.mapView.getTileLodMinRadius();
      this.addTestResult(`✅ LOD 最小半径: ${lodMinRadius.toFixed(2)}`);
      
      this.mapView.setTileLodScale(1.0);
      const lodScale = this.mapView.getTileLodScale();
      this.addTestResult(`✅ LOD 缩放因子: ${lodScale.toFixed(2)}`);
    } catch (error) {
      this.addTestResult(`❌ 瓦片管理测试失败: ${error.message}`);
    }
  }
  
  /**
   * 测试地图状态 API
   */
  private testMapState(): void {
    if (!this.mapView) {
      this.addTestResult('❌ Map not initialized');
      return;
    }
    
    try {
      const isLoaded = this.mapView.isFullyLoaded();
      this.addTestResult(`✅ 地图加载状态: ${isLoaded ? '已加载' : '加载中'}`);
      
      const styleUrl = this.mapView.getStyleUrl();
      this.addTestResult(`✅ 当前样式: ${styleUrl.substring(0, 50)}...`);
    } catch (error) {
      this.addTestResult(`❌ 地图状态测试失败: ${error.message}`);
    }
  }
  
  /**
   * 运行所有测试
   */
  private runAllTests(): void {
    this.testResults = [];
    this.addTestResult('========== 开始测试 ==========');
    this.addTestResult('');
    
    // 按顺序执行测试
    this.addTestResult('📋 1. 测试像素比例 API');
    this.testPixelRatio();
    
    this.addTestResult('');
    this.addTestResult('📋 2. 测试内容边距 API');
    this.testContentPadding();
    
    this.addTestResult('');
    this.addTestResult('📋 3. 测试地图状态 API');
    this.testMapState();
    
    this.addTestResult('');
    this.addTestResult('📋 4. 测试缩放和俯仰角限制');
    this.testZoomPitchLimits();
    
    this.addTestResult('');
    this.addTestResult('📋 5. 测试坐标转换 API');
    this.testCoordinateConversion();
    
    this.addTestResult('');
    this.addTestResult('📋 6. 测试瓦片管理 API');
    this.testTileManagement();
    
    this.addTestResult('');
    this.addTestResult('📋 7. 测试相机控制 API');
    this.testCameraControl();
    
    this.addTestResult('');
    this.addTestResult('========== 测试完成 ==========');
  }
  
  /**
   * 清除边距
   */
  private clearPadding(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setContentPadding([0, 0, 0, 0]);
      this.currentPadding = [0, 0, 0, 0];
      this.addTestResult('✅ 边距已清除');
    } catch (error) {
      this.addTestResult(`❌ 清除边距失败: ${error.message}`);
    }
  }
  
  /**
   * 应用示例边距（模拟有导航栏的场景）
   */
  private applyExamplePadding(): void {
    if (!this.mapView) return;
    
    try {
      // 顶部导航栏 80px，底部工具栏 120px
      const padding = [80, 0, 120, 0];
      this.mapView.setContentPadding(padding);
      this.currentPadding = padding;
      this.addTestResult(`✅ 应用示例边距: 顶${padding[0]}px, 底${padding[2]}px`);
    } catch (error) {
      this.addTestResult(`❌ 应用边距失败: ${error.message}`);
    }
  }

  @Builder
  MapAreaBuilder() {
    Stack() {
      // 地图组件
      NativeMapView({
        styleUrl: "https://demotiles.maplibre.org/style.json",
        initialLatitude: 30.2741,
        initialLongitude: 120.1551,
        initialZoom: 10,
        initialBearing: 0,
        initialPitch: 0,
        onMapReady: (mapView) => {
          this.mapView = mapView as maplibre.NativeMapView;
          hilog.info(DOMAIN, 'CoreAPITestPage', 'Map ready, running initial tests...');
          
          // 获取设备像素比
          if (this.mapView) {
            try {
              this.pixelRatio = this.mapView.getPixelRatio() as number;
              this.addTestResult(`📱 设备像素比: ${this.pixelRatio.toFixed(2)}x`);
            } catch (error) {
              hilog.error(DOMAIN, 'CoreAPITestPage', `Failed to get pixel ratio: ${error.message}`);
            }
          }
        }
      })
      
      // 边距可视化覆盖层
      if (this.showPaddingOverlay && this.currentPadding.some(p => p > 0)) {
        Column() {
          // 顶部边距指示器
          if (this.currentPadding[0] > 0) {
            Row()
              .width('100%')
              .height(this.currentPadding[0])
              .backgroundColor('rgba(255, 0, 0, 0.2)')
          }
          
          Row() {
            // 左边距指示器
            if (this.currentPadding[1] > 0) {
              Column()
                .width(this.currentPadding[1])
                .height('100%')
                .backgroundColor('rgba(0, 255, 0, 0.2)')
            }
            
            Blank()
            
            // 右边距指示器
            if (this.currentPadding[3] > 0) {
              Column()
                .width(this.currentPadding[3])
                .height('100%')
                .backgroundColor('rgba(0, 255, 0, 0.2)')
            }
          }
          .layoutWeight(1)
          
          // 底部边距指示器
          if (this.currentPadding[2] > 0) {
            Row()
              .width('100%')
              .height(this.currentPadding[2])
              .backgroundColor('rgba(255, 0, 0, 0.2)')
          }
        }
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Transparent)
      }
      
      // 边距显示/隐藏控制按钮
      Button(this.showPaddingOverlay ? '隐藏边距' : '显示边距')
        .fontSize(12)
        .padding(8)
        .position({ x: 8, y: 8 })
        .onClick(() => {
          this.showPaddingOverlay = !this.showPaddingOverlay;
        })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ControlAreaBuilder() {
    // 快捷测试按钮
    Row() {
      Button('运行所有测试')
        .fontSize(14)
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#007AFF')
        .width('48%')
        .onClick(() => {
          this.handleRunAllTests();
        })
      
      Button('清除结果')
        .fontSize(14)
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#FF3B30')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.testResults = [];
        })
    }
    .width('100%')
    
    // 测试按钮组
    Text('新增 API 测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('像素比例')
        .fontSize(13)
        .type(ButtonType.Normal)
        .borderRadius(6)
        .width('48%')
        .onClick(() => this.handleTestPixelRatio())
      
      Button('内容边距')
        .fontSize(13)
        .type(ButtonType.Normal)
        .borderRadius(6)
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => this.handleTestContentPadding())
    }
    .width('100%')
    
    Text('边距控制')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('示例边距')
        .fontSize(13)
        .type(ButtonType.Normal)
        .borderRadius(6)
        .width('48%')
        .onClick(() => this.handleApplyExamplePadding())
      
      Button('清除边距')
        .fontSize(13)
        .type(ButtonType.Normal)
        .borderRadius(6)
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => this.handleClearPadding())
    }
    .width('100%')
    
    Text('相机控制测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('相机控制')
        .fontSize(13)
        .type(ButtonType.Normal)
        .borderRadius(6)
        .width('48%')
        .onClick(() => this.handleTestCameraControl())
      
      Button('限制测试')
        .fontSize(13)
        .type(ButtonType.Normal)
        .borderRadius(6)
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => this.handleTestZoomPitchLimits())
    }
    .width('100%')
    
    Text('工具 API 测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('坐标转换')
        .fontSize(13)
        .type(ButtonType.Normal)
        .borderRadius(6)
        .width('48%')
        .onClick(() => this.handleTestCoordinateConversion())
      
      Button('瓦片管理')
        .fontSize(13)
        .type(ButtonType.Normal)
        .borderRadius(6)
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => this.handleTestTileManagement())
    }
    .width('100%')
    
    Text('地图状态')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Button('查询状态')
      .fontSize(13)
      .type(ButtonType.Normal)
      .borderRadius(6)
      .width('48%')
      .onClick(() => this.handleTestMapState())
    
    Divider()
    
    // 当前状态显示
    Column() {
      Text('当前状态')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 5 })
      
      Text(`像素比: ${this.pixelRatio.toFixed(2)}x`)
        .fontSize(12)
        .fontColor('#666')
      
      Text(`边距: [${this.currentPadding.map(p => p.toFixed(0)).join(', ')}]`)
        .fontSize(12)
        .fontColor('#666')
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#F0F0F0')
    .alignItems(HorizontalAlign.Start)
    .borderRadius(4)
    
    // 测试结果日志
    Text('测试结果')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Column() {
      ForEach(this.testResults, (result: string, index: number) => {
        Text(result)
          .fontSize(11)
          .fontFamily('monospace')
          .width('100%')
          .padding({ left: 5, right: 5, top: 2, bottom: 2 })
          .backgroundColor(index % 2 === 0 ? '#FAFAFA' : '#FFFFFF')
      })
    }
    .width('100%')
    .height(150)
    .backgroundColor('#F5F5F5')
    .borderRadius(4)
    .border({ width: 1, color: '#E0E0E0' })
  }

  build() {
    Column() {
      TestPageLayout({
        title: '核心 API 测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }
  
  // ========== 包装方法（用于 @Builder 中的 this 上下文绑定） ==========
  
  private handleRunAllTests = (): void => {
    this.runAllTests();
  }
  
  private handleTestPixelRatio = (): void => {
    this.testPixelRatio();
  }
  
  private handleTestContentPadding = (): void => {
    this.testContentPadding();
  }
  
  private handleApplyExamplePadding = (): void => {
    this.applyExamplePadding();
  }
  
  private handleClearPadding = (): void => {
    this.clearPadding();
  }
  
  private handleTestCameraControl = (): void => {
    this.testCameraControl();
  }
  
  private handleTestZoomPitchLimits = (): void => {
    this.testZoomPitchLimits();
  }
  
  private handleTestCoordinateConversion = (): void => {
    this.testCoordinateConversion();
  }
  
  private handleTestTileManagement = (): void => {
    this.testTileManagement();
  }
  
  private handleTestMapState = (): void => {
    this.testMapState();
  }
}

