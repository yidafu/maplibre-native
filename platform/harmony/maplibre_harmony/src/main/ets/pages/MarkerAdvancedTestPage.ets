/**
 * MarkerAdvancedTestPage - Marker 高级功能测试页面
 * 
 * 测试基于 GeoJSON + SymbolLayer 的 Marker 高级功能：
 * - Rotation（旋转）
 * - Alpha（透明度）
 * - Z-Index（层级）
 * - Anchor（锚点）
 * - Draggable（拖拽）
 * - Animations（动画）
 */

import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from '../maps/camera/CameraPosition';
import { MarkerLayerManager } from '../maps/annotations/MarkerLayerManager';
import { MarkerOptions } from '../maps/annotations/MarkerOptions';
import { IconFactory } from '../maps/annotations/IconFactory';
import { router } from '@kit.ArkUI';
import maplibre from 'libmaplibre_native.so';

@Entry
@Component
struct MarkerAdvancedTestPage {
  private mapLibreMap: MapLibreMap | null = null;
  private markerLayerManager: MarkerLayerManager | null = null;
  
  @State testResults: string[] = [];
  @State currentTest: string = '准备测试...';
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#2196F3')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 5 })

        Text('Marker 高级功能测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F5F5F5')
      
      // 地图区域（60%）
      NativeMapView({
        onMapReady: (nativeMapView?: maplibre.NativeMapView) => {
          this.onMapReady(nativeMapView);
        }
      })
        .width('100%')
        .height('60%')
      
      // 测试按钮区域（40%，可滚动）
      Scroll() {
        Column() {
          // 当前测试状态
          Text(this.currentTest)
            .fontSize(14)
            .width('100%')
            .padding(12)
            .backgroundColor('#F8F8F8')
            .margin({ bottom: 8 })
          
          // 测试按钮
          Text('测试项目')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Button('测试 1: 旋转角度')
            .onClick(() => this.testRotation())
            .width('100%')
            .margin({ bottom: 8 })
          
          Button('测试 2: 透明度')
            .onClick(() => this.testAlpha())
            .width('100%')
            .margin({ bottom: 8 })
          
          Button('测试 3: 批量添加')
            .onClick(() => this.testBatchAdd())
            .width('100%')
            .margin({ bottom: 8 })
          
          Button('测试 4: 更新属性')
            .onClick(() => this.testUpdateProperties())
            .width('100%')
            .margin({ bottom: 8 })
          
          Button('清除所有')
            .onClick(() => this.clearAll())
            .width('100%')
            .backgroundColor('#FF6B6B')
            .margin({ bottom: 12 })
          
          Divider().height(1).color('#E0E0E0').margin({ bottom: 12 })
          
          // 测试结果
          Text('测试结果')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })
          
          Column() {
            ForEach(this.testResults, (result: string, index: number) => {
              Text(result)
                .fontSize(12)
                .padding(8)
                .width('100%')
                .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F9F9F9')
                .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
            }, (result: string, index: number) => `${index}-${result}`)
          }
          .width('100%')
          .border({ width: 1, color: '#E0E0E0' })
          .borderRadius(4)
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 12 })
        .width('100%')
      }
      .width('100%')
      .height('40%')
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
  }
  
  private onMapReady(nativeMapView?: maplibre.NativeMapView) {
    try {
      if (!nativeMapView) {
        console.error('MarkerAdvancedTestPage: NativeMapView is null');
        return;
      }
      
      const latLng = new maplibre.LatLng(39.9042, 116.4074);
      const cameraPos = createCameraPosition(latLng, 12, 0, 0);
      const options = new MapLibreMapOptions();
      options.cameraPosition = cameraPos;
      options.styleUrl = 'https://demotiles.maplibre.org/style.json';
      
      this.mapLibreMap = new MapLibreMap(nativeMapView, options);
      
      // 等待样式加载
      setTimeout(() => {
        this.initializeMarkerLayer();
      }, 2000);
      
      this.log('✅ 地图初始化成功');
    } catch (error) {
      this.log(`❌ 地图初始化失败: ${error}`);
    }
  }
  
  private initializeMarkerLayer() {
    if (!this.mapLibreMap) return;
    
    try {
      this.markerLayerManager = new MarkerLayerManager(this.mapLibreMap);
      this.markerLayerManager.initialize();
      this.log('✅ MarkerLayerManager 初始化成功');
      this.currentTest = '就绪 - 可以开始测试';
      
      // 添加默认 marker icon
      this.addDefaultIcon();
    } catch (error) {
      this.log(`❌ MarkerLayerManager 初始化失败: ${error}`);
    }
  }
  
  private async addDefaultIcon() {
    try {
      const iconFactory = IconFactory.getInstance();
      // 使用 startIcon 作为默认图标
      const icon = await iconFactory.fromResource($r('app.media.startIcon'));
      
      if (this.mapLibreMap && icon) {
        // 将 icon 添加到 style（注意：MarkerLayerManager 需要 icon 已经注册）
        // TODO: 自动注册 icon
        this.log('✅ 默认 icon 已加载');
      }
    } catch (error) {
      this.log(`⚠️ 默认 icon 加载失败: ${error}`);
    }
  }
  
  /**
   * 测试 1：旋转角度
   */
  private testRotation() {
    if (!this.markerLayerManager) {
      this.log('❌ MarkerLayerManager 未初始化');
      return;
    }
    
    this.currentTest = '测试旋转角度...';
    this.log('--- 测试 1: 旋转角度 ---');
    
    try {
      // 添加不同旋转角度的 markers
      const rotations = [0, 45, 90, 135, 180, 225, 270, 315];
      const iconFactory = IconFactory.getInstance();
      
      for (let i = 0; i < rotations.length; i++) {
        const rotation = rotations[i];
        const lat = 39.9042 + (i - 4) * 0.01;
        const lon = 116.4074;
        
        const marker = new MarkerOptions()
          .position(new maplibre.LatLng(lat, lon))
          .rotation(rotation)
          .title(`旋转 ${rotation}°`)
          .getMarker();
        
        this.markerLayerManager.addMarker(marker);
      }
      
      this.log(`✅ 添加了 ${rotations.length} 个不同旋转角度的 markers`);
      this.currentTest = '测试完成';
    } catch (error) {
      this.log(`❌ 测试失败: ${error}`);
      this.currentTest = '测试失败';
    }
  }
  
  /**
   * 测试 2：透明度
   */
  private testAlpha() {
    if (!this.markerLayerManager) {
      this.log('❌ MarkerLayerManager 未初始化');
      return;
    }
    
    this.currentTest = '测试透明度...';
    this.log('--- 测试 2: 透明度 ---');
    
    try {
      // 添加不同透明度的 markers
      for (let i = 0; i <= 10; i++) {
        const alpha = i / 10;
        const lat = 39.9042;
        const lon = 116.4074 + (i - 5) * 0.01;
        
        const marker = new MarkerOptions()
          .position(new maplibre.LatLng(lat, lon))
          .alpha(alpha)
          .title(`Alpha ${alpha.toFixed(1)}`)
          .getMarker();
        
        this.markerLayerManager.addMarker(marker);
      }
      
      this.log('✅ 添加了 11 个不同透明度的 markers (0.0 - 1.0)');
      this.currentTest = '测试完成';
    } catch (error) {
      this.log(`❌ 测试失败: ${error}`);
      this.currentTest = '测试失败';
    }
  }
  
  /**
   * 测试 3: 批量添加
   */
  private testBatchAdd() {
    if (!this.markerLayerManager) {
      this.log('❌ MarkerLayerManager 未初始化');
      return;
    }
    
    this.currentTest = '测试批量添加...';
    this.log('--- 测试 3: 批量添加 ---');
    
    try {
      const markers: maplibre.Marker[] = [];
      const count = 50;
      
      for (let i = 0; i < count; i++) {
        const lat = 39.9042 + (Math.random() - 0.5) * 0.1;
        const lon = 116.4074 + (Math.random() - 0.5) * 0.1;
        
        const marker = new MarkerOptions()
          .position(new maplibre.LatLng(lat, lon))
          .rotation(Math.random() * 360)
          .alpha(0.5 + Math.random() * 0.5)
          .title(`Marker ${i}`)
          .getMarker();
        
        markers.push(marker);
      }
      
      const startTime = Date.now();
      this.markerLayerManager.addMarkers(markers);
      const duration = Date.now() - startTime;
      
      this.log(`✅ 批量添加 ${count} 个 markers 成功，耗时 ${duration}ms`);
      this.currentTest = '测试完成';
    } catch (error) {
      this.log(`❌ 测试失败: ${error}`);
      this.currentTest = '测试失败';
    }
  }
  
  /**
   * 测试 4: 更新属性
   */
  private testUpdateProperties() {
    if (!this.markerLayerManager) {
      this.log('❌ MarkerLayerManager 未初始化');
      return;
    }
    
    this.currentTest = '测试更新属性...';
    this.log('--- 测试 4: 更新属性 ---');
    
    try {
      // 添加一个 marker
      const marker = new MarkerOptions()
        .position(new maplibre.LatLng(39.9042, 116.4074))
        .rotation(0)
        .alpha(1.0)
        .title('测试 Marker')
        .getMarker();
      
      const featureId = this.markerLayerManager.addMarker(marker);
      this.log(`✅ 添加 marker (ID: ${featureId})`);
      
      // 延迟更新属性
      setTimeout(() => {
        marker.setRotation(90);
        marker.setAlpha(0.5);
        this.markerLayerManager!.updateMarker(featureId, marker);
        this.log('✅ 更新 marker：旋转 90°，透明度 0.5');
      }, 1000);
      
      setTimeout(() => {
        marker.setRotation(180);
        marker.setAlpha(0.3);
        this.markerLayerManager!.updateMarker(featureId, marker);
        this.log('✅ 更新 marker：旋转 180°，透明度 0.3');
      }, 2000);
      
      this.currentTest = '测试进行中...';
    } catch (error) {
      this.log(`❌ 测试失败: ${error}`);
      this.currentTest = '测试失败';
    }
  }
  
  /**
   * 清除所有 markers
   */
  private clearAll() {
    if (!this.markerLayerManager) {
      this.log('❌ MarkerLayerManager 未初始化');
      return;
    }
    
    try {
      const count = this.markerLayerManager.getMarkerCount();
      this.markerLayerManager.clearMarkers();
      this.log(`✅ 清除了 ${count} 个 markers`);
      this.currentTest = '已清除';
    } catch (error) {
      this.log(`❌ 清除失败: ${error}`);
    }
  }
  
  /**
   * 记录日志
   */
  private log(message: string) {
    console.info(`[MarkerAdvancedTest] ${message}`);
    this.testResults.push(`[${new Date().toLocaleTimeString()}] ${message}`);
    
    // 限制日志数量
    if (this.testResults.length > 20) {
      this.testResults.shift();
    }
  }
}

