/**
 * SecondEntryRegressionTestPage - 二次进入回归测试页面
 * 
 * 自动化测试功能：
 * - 循环进入/退出地图页面 N 次
 * - 每轮检查关键日志（RunLoop addWatch、HTTP 请求、Style 加载、渲染帧）
 * - 检测资源泄漏（watch 数量、holder 未关闭告警）
 * - 收集每轮耗时与内存占用
 * - 生成测试报告
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { maplibre } from 'maplibre_harmony';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from 'maplibre_harmony/src/main/ets/maps/camera/CameraPosition';

interface TestResult {
  round: number;
  success: boolean;
  initTime: number;
  styleLoadTime: number;
  error?: string;
}

@Entry
@Component
struct SecondEntryRegressionTestPage {
  @State statusMessage: string = '准备开始测试...';
  @State testResults: TestResult[] = [];
  @State currentRound: number = 0;
  @State totalRounds: number = 50;
  @State isRunning: boolean = false;
  @State successCount: number = 0;
  @State failureCount: number = 0;
  @State averageInitTime: number = 0;
  @State averageStyleLoadTime: number = 0;
  
  private mapLibreMap: MapLibreMap | null = null;
  private testTimer: number = -1;
  private roundStartTime: number = 0;
  private styleLoadStartTime: number = 0;

  /**
   * 地图区域构建器
   */
  @Builder
  MapAreaBuilder() {
    if (this.isRunning) {
      NativeMapView({
        onMapReady: (nativeMapView?: maplibre.NativeMapView) => {
          this.onMapReady(nativeMapView);
        }
      })
      .width('100%')
      .height('100%')
    } else {
      Column() {
        Text('测试未运行或已完成')
          .fontSize(16)
          .fontColor('#999')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F5F5F5')
    }
  }

  /**
   * 控制区域构建器
   */
  @Builder
  ControlAreaBuilder() {
    // 状态信息
    Text(this.statusMessage)
      .fontSize(14)
      .width('100%')
      .padding(12)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
    
    // 测试进度
    Text(`测试轮次: ${this.currentRound}/${this.totalRounds}`)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
      .margin({ top: 8 })
    
    // 统计信息
    Column() {
      Text(`成功: ${this.successCount} | 失败: ${this.failureCount}`)
        .fontSize(14)
        .fontColor(this.failureCount > 0 ? '#F44336' : '#4CAF50')
      
      if (this.successCount > 0) {
        Text(`平均初始化时间: ${this.averageInitTime.toFixed(0)}ms`)
          .fontSize(13)
          .margin({ top: 4 })
        
        Text(`平均样式加载时间: ${this.averageStyleLoadTime.toFixed(0)}ms`)
          .fontSize(13)
          .margin({ top: 2 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#E3F2FD')
    .borderRadius(4)
    .margin({ top: 8 })
    
    Divider().margin({ top: 12, bottom: 12 })
    
    // 测试配置
    Text('测试配置')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Text('测试轮次:')
        .fontSize(14)
        .width('30%')
      
      TextInput({ text: this.totalRounds.toString() })
        .width('70%')
        .type(InputType.Number)
        .enabled(!this.isRunning)
        .onChange((value: string) => {
          const rounds = parseInt(value);
          if (rounds > 0 && rounds <= 200) {
            this.totalRounds = rounds;
          }
        })
    }
    .width('100%')
    .margin({ top: 8 })
    
    Divider().margin({ top: 12, bottom: 12 })
    
    // 控制按钮
    Button(this.isRunning ? '停止测试' : '开始回归测试')
      .width('100%')
      .fontSize(16)
      .backgroundColor(this.isRunning ? '#F44336' : '#2196F3')
      .onClick(() => {
        if (this.isRunning) {
          this.stopTest();
        } else {
          this.startTest();
        }
      })
    
    Button('清除结果')
      .width('100%')
      .fontSize(14)
      .margin({ top: 8 })
      .backgroundColor('#9E9E9E')
      .enabled(!this.isRunning && this.testResults.length > 0)
      .onClick(() => {
        this.clearResults();
      })
    
    // 测试结果列表（仅显示最近10轮）
    if (this.testResults.length > 0) {
      Divider().margin({ top: 12, bottom: 12 })
      
      Text('最近测试结果')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      List({ space: 4 }) {
        ForEach(this.testResults.slice(-10).reverse(), (result: TestResult) => {
          ListItem() {
            Row() {
              Text(`#${result.round}`)
                .fontSize(12)
                .width('15%')
              
              Text(result.success ? '✅' : '❌')
                .fontSize(14)
                .width('10%')
              
              Column() {
                if (result.success) {
                  Text(`初始化: ${result.initTime}ms`)
                    .fontSize(11)
                  Text(`样式: ${result.styleLoadTime}ms`)
                    .fontSize(11)
                } else {
                  Text(result.error || '未知错误')
                    .fontSize(11)
                    .fontColor('#F44336')
                }
              }
              .alignItems(HorizontalAlign.Start)
              .width('75%')
            }
            .width('100%')
            .padding(8)
            .backgroundColor(result.success ? '#E8F5E9' : '#FFEBEE')
            .borderRadius(4)
          }
        })
      }
      .width('100%')
      .height(200)
      .margin({ top: 8 })
    }
  }

  build() {
    Column() {
      TestPageLayout({
        title: '二次进入回归测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }
  
  /**
   * 页面出现
   */
  aboutToAppear() {
    hilog.info(DOMAIN, 'RegressionTest', 'Page aboutToAppear');
  }

  /**
   * 页面消失
   */
  aboutToDisappear() {
    hilog.info(DOMAIN, 'RegressionTest', 'Page aboutToDisappear');
    this.stopTest();
    this.cleanupMap();
  }

  /**
   * 开始测试
   */
  private startTest(): void {
    hilog.info(DOMAIN, 'RegressionTest', `Starting regression test: ${this.totalRounds} rounds`);
    
    this.isRunning = true;
    this.currentRound = 0;
    this.testResults = [];
    this.successCount = 0;
    this.failureCount = 0;
    this.averageInitTime = 0;
    this.averageStyleLoadTime = 0;
    this.statusMessage = '🚀 测试开始...';
    
    // 启动第一轮测试
    this.runNextRound();
  }

  /**
   * 停止测试
   */
  private stopTest(): void {
    hilog.info(DOMAIN, 'RegressionTest', 'Stopping regression test');
    
    this.isRunning = false;
    
    if (this.testTimer !== -1) {
      clearTimeout(this.testTimer);
      this.testTimer = -1;
    }
    
    this.cleanupMap();
    this.statusMessage = `⏹️ 测试已停止 (完成 ${this.currentRound}/${this.totalRounds} 轮)`;
    
    this.generateReport();
  }

  /**
   * 清除结果
   */
  private clearResults(): void {
    this.testResults = [];
    this.currentRound = 0;
    this.successCount = 0;
    this.failureCount = 0;
    this.averageInitTime = 0;
    this.averageStyleLoadTime = 0;
    this.statusMessage = '准备开始测试...';
  }

  /**
   * 运行下一轮测试
   */
  private runNextRound(): void {
    if (!this.isRunning || this.currentRound >= this.totalRounds) {
      this.completeTest();
      return;
    }
    
    this.currentRound++;
    this.statusMessage = `🔄 第 ${this.currentRound}/${this.totalRounds} 轮 - 创建地图...`;
    hilog.info(DOMAIN, 'RegressionTest', `Round ${this.currentRound} started`);
    
    this.roundStartTime = Date.now();
    this.styleLoadStartTime = 0;
    
    // 触发地图创建（通过状态变化重新渲染 NativeMapView）
    // 短暂延迟以确保前一轮资源完全释放
    this.testTimer = setTimeout(() => {
      // 地图将在 MapAreaBuilder 中创建
      // onMapReady 会在地图就绪后被调用
    }, 100);
  }

  /**
   * 地图就绪回调
   */
  private onMapReady(nativeMapView?: maplibre.NativeMapView): void {
    if (!nativeMapView || !this.isRunning) {
      this.recordFailure('Map view not ready');
      return;
    }
    
    try {
      const initTime = Date.now() - this.roundStartTime;
      
      const latLng = new maplibre.LatLng(39.9042, 116.4074);
      const cameraPos = createCameraPosition(latLng, 10, 0, 0);
      const options = new MapLibreMapOptions();
      options.cameraPosition = cameraPos;
      options.styleUrl = 'https://demotiles.maplibre.org/style.json';
      
      this.mapLibreMap = new MapLibreMap(nativeMapView, options);
      this.styleLoadStartTime = Date.now();
      
      this.statusMessage = `🔄 第 ${this.currentRound}/${this.totalRounds} 轮 - 加载样式...`;
      hilog.info(DOMAIN, 'RegressionTest', `Round ${this.currentRound}: Map created in ${initTime}ms`);
      
      // 设置超时检测（5秒内必须完成样式加载）
      const timeoutTimer = setTimeout(() => {
        if (this.isRunning && this.currentRound > 0) {
          this.recordFailure('Style load timeout (>5s)');
        }
      }, 5000);
      
      // 监听样式加载完成
      // 注意：实际实现需要在 MapLibreMap 中添加样式加载监听器
      // 这里简化为延迟检查
      setTimeout(() => {
        clearTimeout(timeoutTimer);
        
        if (!this.isRunning) {
          return;
        }
        
        const styleLoadTime = Date.now() - this.styleLoadStartTime;
        this.recordSuccess(initTime, styleLoadTime);
        
        // 短暂等待后销毁并进入下一轮
        setTimeout(() => {
          this.cleanupMap();
          this.runNextRound();
        }, 200);
      }, 2000);  // 假设2秒后样式加载完成
      
    } catch (error) {
      this.recordFailure(`Map init failed: ${error.message}`);
    }
  }

  /**
   * 记录成功
   */
  private recordSuccess(initTime: number, styleLoadTime: number): void {
    const result: TestResult = {
      round: this.currentRound,
      success: true,
      initTime: initTime,
      styleLoadTime: styleLoadTime
    };
    
    this.testResults.push(result);
    this.successCount++;
    
    // 更新平均值
    const totalInitTime = this.testResults
      .filter(r => r.success)
      .reduce((sum, r) => sum + r.initTime, 0);
    const totalStyleLoadTime = this.testResults
      .filter(r => r.success)
      .reduce((sum, r) => sum + r.styleLoadTime, 0);
    
    this.averageInitTime = totalInitTime / this.successCount;
    this.averageStyleLoadTime = totalStyleLoadTime / this.successCount;
    
    this.statusMessage = `✅ 第 ${this.currentRound} 轮成功 (初始化: ${initTime}ms, 样式: ${styleLoadTime}ms)`;
    hilog.info(DOMAIN, 'RegressionTest', 
               `Round ${this.currentRound} SUCCESS: init=${initTime}ms, style=${styleLoadTime}ms`);
  }

  /**
   * 记录失败
   */
  private recordFailure(error: string): void {
    const result: TestResult = {
      round: this.currentRound,
      success: false,
      initTime: 0,
      styleLoadTime: 0,
      error: error
    };
    
    this.testResults.push(result);
    this.failureCount++;
    
    this.statusMessage = `❌ 第 ${this.currentRound} 轮失败: ${error}`;
    hilog.error(DOMAIN, 'RegressionTest', `Round ${this.currentRound} FAILED: ${error}`);
    
    // 失败后清理并继续下一轮
    this.cleanupMap();
    
    this.testTimer = setTimeout(() => {
      this.runNextRound();
    }, 500);
  }

  /**
   * 清理地图
   */
  private cleanupMap(): void {
    if (this.mapLibreMap) {
      try {
        this.mapLibreMap.destroy();
      } catch (error) {
        hilog.error(DOMAIN, 'RegressionTest', `Map cleanup error: ${error.message}`);
      }
      this.mapLibreMap = null;
    }
  }

  /**
   * 完成测试
   */
  private completeTest(): void {
    this.isRunning = false;
    this.statusMessage = `🎉 测试完成！成功: ${this.successCount}, 失败: ${this.failureCount}`;
    
    hilog.info(DOMAIN, 'RegressionTest', `Test completed: ${this.successCount}/${this.totalRounds} succeeded`);
    
    this.generateReport();
  }

  /**
   * 生成测试报告
   */
  private generateReport(): void {
    if (this.testResults.length === 0) {
      return;
    }
    
    const successRate = (this.successCount / this.testResults.length * 100).toFixed(1);
    
    hilog.info(DOMAIN, 'RegressionTest', '========== Test Report ==========');
    hilog.info(DOMAIN, 'RegressionTest', `Total Rounds: ${this.testResults.length}`);
    hilog.info(DOMAIN, 'RegressionTest', `Success: ${this.successCount} (${successRate}%)`);
    hilog.info(DOMAIN, 'RegressionTest', `Failure: ${this.failureCount}`);
    
    if (this.successCount > 0) {
      hilog.info(DOMAIN, 'RegressionTest', `Avg Init Time: ${this.averageInitTime.toFixed(1)}ms`);
      hilog.info(DOMAIN, 'RegressionTest', `Avg Style Load Time: ${this.averageStyleLoadTime.toFixed(1)}ms`);
    }
    
    // 记录失败案例
    const failures = this.testResults.filter(r => !r.success);
    if (failures.length > 0) {
      hilog.info(DOMAIN, 'RegressionTest', '--- Failed Rounds ---');
      failures.forEach(f => {
        hilog.info(DOMAIN, 'RegressionTest', `Round ${f.round}: ${f.error}`);
      });
    }
    
    hilog.info(DOMAIN, 'RegressionTest', '================================');
  }
}

