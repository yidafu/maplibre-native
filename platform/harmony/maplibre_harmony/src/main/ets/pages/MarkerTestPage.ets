import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { MarkerOptions } from '../maps/annotations/MarkerOptions';
import { Marker } from '../maps/annotations/Marker';
import { LatLng } from '../maps/geometry/LatLng';
import { CameraPosition } from '../maps/camera/CameraPosition';
import { OnMarkerClickListener } from '../maps/listeners/OnMarkerClickListener';
import { OnMarkerDragListener } from '../maps/listeners/OnMarkerDragListener';
import { OnInfoWindowClickListener } from '../maps/listeners/OnInfoWindowClickListener';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import maplibre from 'libmaplibre_native.so';

const DOMAIN = 0x0000;
const TAG = 'MarkerTestPage';

/**
 * MarkerTestPage - Marker 功能测试页面
 * 
 * 完整展示 Marker 的所有功能：
 * 1. ✅ 添加/删除单个 Marker
 * 2. ✅ 批量添加 Marker
 * 3. ✅ Marker 点击事件
 * 4. ✅ Marker 拖拽事件监听
 * 5. ✅ InfoWindow 显示/隐藏
 * 6. ✅ 不同样式的 Marker（透明度、旋转、锚点、Z-index）
 * 7. ✅ Marker 动画（位置、透明度、旋转）
 * 8. ✅ 选中/取消选中
 */

/**
 * Marker 点击监听器实现
 */
class MarkerClickListenerImpl implements OnMarkerClickListener {
  private testPage: MarkerTestPage;
  
  constructor(testPage: MarkerTestPage) {
    this.testPage = testPage;
  }
  
  onMarkerClick(marker: Marker): boolean {
    this.testPage.selectedMarkerId = marker.getId();
    const pos = marker.getPosition();
    this.testPage.message = `🎯 点击: ${marker.getTitle()} (${pos.latitude.toFixed(4)}, ${pos.longitude.toFixed(4)})`;
    this.testPage.lastMarkerPosition = `${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)}`;
    
    console.info(`MarkerTestPage: Marker clicked - ID=${marker.getId()}, Title=${marker.getTitle()}`);
    
    // 显示 InfoWindow
    marker.showInfoWindow();
    return true;
  }
}

/**
 * Marker 拖拽监听器实现
 */
class MarkerDragListenerImpl implements OnMarkerDragListener {
  private testPage: MarkerTestPage;
  
  constructor(testPage: MarkerTestPage) {
    this.testPage = testPage;
  }
  
  onMarkerDragStart(marker: Marker): void {
    const pos = marker.getPosition();
    this.testPage.message = `🤏 开始拖拽: ${marker.getTitle()}`;
    this.testPage.lastMarkerPosition = `起始: ${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)}`;
    console.info(`MarkerTestPage: Drag start - ${marker.getTitle()}`);
  }
  
  onMarkerDrag(marker: Marker): void {
    const pos = marker.getPosition();
    this.testPage.lastMarkerPosition = `拖拽中: ${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)}`;
    console.info(`MarkerTestPage: Dragging to ${pos.latitude}, ${pos.longitude}`);
  }
  
  onMarkerDragEnd(marker: Marker): void {
    const pos = marker.getPosition();
    this.testPage.message = `✓ 拖拽完成: ${marker.getTitle()}`;
    this.testPage.lastMarkerPosition = `最终: ${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)}`;
    console.info(`MarkerTestPage: Drag end at ${pos.latitude}, ${pos.longitude}`);
  }
}

/**
 * InfoWindow 点击监听器实现
 */
class InfoWindowClickListenerImpl implements OnInfoWindowClickListener {
  private testPage: MarkerTestPage;
  
  constructor(testPage: MarkerTestPage) {
    this.testPage = testPage;
  }
  
  onInfoWindowClick(marker: Marker): void {
    this.testPage.message = `💬 InfoWindow 被点击: ${marker.getTitle()}`;
    console.info(`MarkerTestPage: InfoWindow clicked - ${marker.getTitle()}`);
  }
}


@Entry
@Component
struct MarkerTestPage {
  private mapLibreMap: MapLibreMap | null = null;
  private nativeMapView: maplibre.NativeMapView | null = null;
  
  @State mapReady: boolean = false;
  @State markerCount: number = 0;
  @State selectedMarkerId: number = -1;
  @State message: string = '等待地图加载...';
  @State lastMarkerPosition: string = '';
  
  // 测试用的位置
  private testLocations: LatLng[] = [
    { latitude: 39.9042, longitude: 116.4074 },  // 北京
    { latitude: 31.2304, longitude: 121.4737 },  // 上海
    { latitude: 22.3193, longitude: 114.1694 },  // 深圳
    { latitude: 30.5728, longitude: 104.0668 },  // 成都
    { latitude: 34.2634, longitude: 108.9463 },  // 西安
  ];
  
  private testMarker: Marker | null = null;
  private markerList: Marker[] = [];
  
  aboutToAppear() {
    hilog.info(DOMAIN, TAG, 'aboutToAppear');
  }
  
  aboutToDisappear() {
    hilog.info(DOMAIN, TAG, 'aboutToDisappear');
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
    }
  }
  
  /**
   * 地图初始化完成回调
   */
  onMapReady(mapView?: maplibre.NativeMapView) {
    if (!mapView) {
      hilog.error(DOMAIN, TAG, 'onMapReady: mapView is null');
      this.message = '❌ 地图初始化失败';
      return;
    }
    
    try {
      this.nativeMapView = mapView;
      
      // 创建 MapLibreMap 实例
      const options = new MapLibreMapOptions();
      this.mapLibreMap = new MapLibreMap(mapView, options);
      
      // 设置初始相机位置（中国中心）
      this.mapLibreMap.jumpTo(0, 35.0, 105.0, 0, 4.0);
      
      this.mapReady = true;
      this.message = '✅ 地图已就绪 - 可以开始测试';
      
      // 设置事件监听器
      this.setupEventListeners();
      
      hilog.info(DOMAIN, TAG, 'Map ready, setting up event listeners');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to initialize MapLibreMap: ${errorMsg}`);
      this.message = `❌ 初始化失败: ${errorMsg}`;
    }
  }
  
  /**
   * 设置事件监听器
   */
  setupEventListeners() {
    if (!this.mapLibreMap) return;
    
    // 创建监听器实例
    const markerClickListener = new MarkerClickListenerImpl(this);
    const markerDragListener = new MarkerDragListenerImpl(this);
    const infoWindowClickListener = new InfoWindowClickListenerImpl(this);
    
    // 设置监听器
    this.mapLibreMap.setOnMarkerClickListener(markerClickListener);
    this.mapLibreMap.setOnMarkerDragListener(markerDragListener);
    this.mapLibreMap.setOnInfoWindowClickListener(infoWindowClickListener);
    
    console.info('MarkerTestPage: Event listeners configured');
  }
  
  /**
   * 添加单个 Marker
   */
  addSingleMarker() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    const locationIndex = this.markerCount % this.testLocations.length;
    const location = this.testLocations[locationIndex];
    
    try {
      // 创建带不同样式的 Marker
      const marker = this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(location)
          .title(`Marker ${this.markerCount + 1}`)
          .snippet(`位置: ${location.latitude.toFixed(4)}, ${location.longitude.toFixed(4)}`)
          .draggable(true)
          .alpha(0.9)
          .rotation(this.markerCount * 15)  // 每个 Marker 不同的旋转角度
          .zIndex(this.markerCount)
      );
      
      this.testMarker = marker;
      this.markerList.push(marker);
      this.markerCount++;
      this.lastMarkerPosition = `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`;
      this.message = `➕ 添加成功: ${marker.getTitle()} (ID: ${marker.getId()})`;
      
      console.info(`MarkerTestPage: Added marker ${marker.getId()} at ${location.latitude}, ${location.longitude}`);
    } catch (e) {
      this.message = `❌ 添加失败: ${e.message}`;
      console.error(`MarkerTestPage: Failed to add marker - ${e.message}`);
    }
  }
  
  /**
   * 批量添加 Marker
   */
  addBatchMarkers() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    try {
      const options: MarkerOptions[] = [];
      const cities = ['北京', '上海', '深圳', '成都', '西安'];
      
      for (let i = 0; i < this.testLocations.length; i++) {
        options.push(
          new MarkerOptions()
            .position(this.testLocations[i])
            .title(cities[i])
            .snippet(`批量添加 - ${cities[i]}`)
            .alpha(0.85)
            .rotation(i * 72) // 均匀分布旋转角度
            .zIndex(100 + i)  // 更高的 Z-index
            .draggable(true)
        );
      }
      
      const startTime = Date.now();
      const markers = this.mapLibreMap.addMarkersBatch(options);
      const endTime = Date.now();
      
      this.markerList.push(...markers);
      this.markerCount += markers.length;
      this.message = `🚀 批量添加成功: ${markers.length} 个 Marker (耗时: ${endTime - startTime}ms)`;
      
      console.info(`MarkerTestPage: Batch added ${markers.length} markers in ${endTime - startTime}ms`);
    } catch (e) {
      this.message = `❌ 批量添加失败: ${e.message}`;
      console.error(`MarkerTestPage: Failed to add batch markers - ${e.message}`);
    }
  }
  
  /**
   * 移除最后添加的 Marker
   */
  removeLastMarker() {
    if (!this.mapLibreMap) {
      this.message = '地图未初始化';
      return;
    }
    
    if (this.testMarker) {
      this.testMarker.remove();
      this.message = `移除了 Marker: ${this.testMarker.getTitle()}`;
      this.testMarker = null;
      this.markerCount = Math.max(0, this.markerCount - 1);
    } else {
      this.message = '没有可移除的 Marker';
    }
  }
  
  /**
   * 清除所有 Marker
   */
  clearAllMarkers() {
    if (!this.mapLibreMap) {
      this.message = '地图未初始化';
      return;
    }
    
    this.mapLibreMap.clearMarkers();
    this.markerCount = 0;
    this.testMarker = null;
    this.message = '已清除所有 Marker';
    
    console.info('MarkerTestPage: Cleared all markers');
  }
  
  /**
   * 测试 Marker 动画
   */
  testMarkerAnimation() {
    if (!this.testMarker) {
      this.message = '请先添加一个 Marker';
      return;
    }
    
    const currentPos = this.testMarker.getPosition();
    const targetPos: LatLng = {
      latitude: currentPos.latitude + 0.5,
      longitude: currentPos.longitude + 0.5
    };
    
    this.message = '开始动画...';
    
    this.testMarker.animateToPosition(targetPos, 2000, () => {
      this.message = '动画完成';
      console.info('MarkerTestPage: Animation completed');
    });
  }
  
  /**
   * 测试透明度动画
   */
  testAlphaAnimation() {
    if (!this.testMarker) {
      this.message = '请先添加一个 Marker';
      return;
    }
    
    const currentAlpha = this.testMarker.getAlpha();
    const targetAlpha = currentAlpha > 0.5 ? 0.3 : 1.0;
    
    this.testMarker.animateAlpha(targetAlpha, 1000, () => {
      this.message = `透明度动画完成: ${targetAlpha}`;
    });
  }
  
  /**
   * 测试旋转动画
   */
  testRotationAnimation() {
    if (!this.testMarker) {
      this.message = '请先添加一个 Marker';
      return;
    }
    
    const currentRotation = this.testMarker.getRotation();
    const targetRotation = currentRotation + 90;
    
    this.testMarker.animateRotation(targetRotation, 1000, () => {
      this.message = `旋转动画完成: ${targetRotation}°`;
    });
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#1E88E5')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 5 })
        
        Text('Marker 功能测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(50)
      .backgroundColor('#1E88E5')
      .justifyContent(FlexAlign.Start)
      
      // 地图视图容器
      Stack() {
        // 使用 NativeMapView 组件
        NativeMapView({
          styleUrl: "https://demotiles.maplibre.org/style.json",
          initialLatitude: 35.0,
          initialLongitude: 105.0,
          initialZoom: 4,
          initialBearing: 0,
          initialPitch: 0,
          onMapReady: (mapView?: maplibre.NativeMapView): void => this.onMapReady(mapView)
        })
          .width('100%')
          .height('100%')
        
        // 加载指示器
        if (!this.mapReady) {
          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
              .color('#1E88E5')
            
            Text('地图加载中...')
              .fontSize(16)
              .margin({ top: 10 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('rgba(255, 255, 255, 0.8)')
        }
      }
      .width('100%')
      .height(300)
      .backgroundColor('#EEEEEE')
      
      // 状态信息区
      Column({ space: 5 }) {
        Text(this.message)
          .fontSize(13)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 10, right: 10 })
        
        Row({ space: 20 }) {
          Text(`Marker 数量: ${this.markerCount}`)
            .fontSize(12)
            .fontColor('#1E88E5')
          
          if (this.selectedMarkerId >= 0) {
            Text(`选中 ID: ${this.selectedMarkerId}`)
              .fontSize(12)
              .fontColor('#43A047')
          }
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
        
        if (this.lastMarkerPosition) {
          Text(`坐标: ${this.lastMarkerPosition}`)
            .fontSize(11)
            .fontColor('#757575')
            .width('100%')
            .padding({ left: 10, right: 10 })
        }
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .backgroundColor('#F5F5F5')
      
      // 控制按钮区
      Scroll() {
        Column({ space: 10 }) {
          // 基础操作
          Text('基础操作')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 5 })
          
          Row({ space: 8 }) {
            Button('➕ 添加单个')
              .onClick(() => this.addSingleMarker())
              .flexGrow(1)
              .type(ButtonType.Normal)
              .borderRadius(8)
            
            Button('🚀 批量添加')
              .onClick(() => this.addBatchMarkers())
              .flexGrow(1)
              .type(ButtonType.Normal)
              .borderRadius(8)
          }
          .width('100%')
          
          Row({ space: 8 }) {
            Button('➖ 移除最后')
              .onClick(() => this.removeLastMarker())
              .flexGrow(1)
              .type(ButtonType.Normal)
              .borderRadius(8)
              .backgroundColor('#FFA726')
            
            Button('🗑️ 清除所有')
              .onClick(() => this.clearAllMarkers())
              .flexGrow(1)
              .type(ButtonType.Normal)
              .borderRadius(8)
              .backgroundColor('#EF5350')
          }
          .width('100%')
          
          // 动画测试
          Text('动画测试')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 10 })
          
          Row({ space: 8 }) {
            Button('📍 位置')
              .onClick(() => this.testMarkerAnimation())
              .flexGrow(1)
              .type(ButtonType.Normal)
              .borderRadius(8)
              .backgroundColor('#AB47BC')
            
            Button('👁️ 透明度')
              .onClick(() => this.testAlphaAnimation())
              .flexGrow(1)
              .type(ButtonType.Normal)
              .borderRadius(8)
              .backgroundColor('#AB47BC')
          }
          .width('100%')
          
          Button('🔄 旋转')
            .onClick(() => this.testRotationAnimation())
            .width('100%')
            .type(ButtonType.Normal)
            .borderRadius(8)
            .backgroundColor('#AB47BC')
          
          // 高级功能
          Text('高级功能')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 10 })
          
          Row({ space: 8 }) {
            Button('🎯 选中第一个')
              .onClick(() => this.selectFirstMarker())
              .flexGrow(1)
              .type(ButtonType.Normal)
              .borderRadius(8)
              .backgroundColor('#26A69A')
            
            Button('❌ 取消选中')
              .onClick(() => this.deselectAll())
              .flexGrow(1)
              .type(ButtonType.Normal)
              .borderRadius(8)
              .backgroundColor('#78909C')
          }
          .width('100%')
          
          // 说明
          Text('功能说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 10 })
          
          Text('✅ Marker 基础功能\n' +
            '• 单个/批量添加和删除\n' +
            '• 自定义样式（透明度、旋转、Z-index）\n\n' +
            '✅ 事件监听\n' +
            '• 点击事件（显示 InfoWindow）\n' +
            '• 拖拽事件（开始、进行中、结束）\n\n' +
            '✅ 动画效果\n' +
            '• 位置平滑移动\n' +
            '• 透明度渐变\n' +
            '• 旋转动画\n\n' +
            '✅ 选中管理\n' +
            '• 选中/取消选中\n' +
            '• InfoWindow 显示控制')
            .fontSize(11)
            .fontColor('#616161')
            .lineHeight(18)
        }
        .padding(12)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
  
  /**
   * 选中第一个 Marker
   */
  selectFirstMarker() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    if (this.markerList.length === 0) {
      this.message = '⚠️ 没有 Marker 可选中';
      return;
    }
    
    const marker = this.markerList[0];
    this.mapLibreMap.selectMarker(marker, true);
    this.selectedMarkerId = marker.getId();
    this.message = `🎯 已选中: ${marker.getTitle()}`;
    console.info(`MarkerTestPage: Selected marker ${marker.getId()}`);
  }
  
  /**
   * 取消所有选中
   */
  deselectAll() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    this.mapLibreMap.deselectMarkers();
    this.selectedMarkerId = -1;
    this.message = '❌ 已取消所有选中';
    console.info('MarkerTestPage: Deselected all markers');
  }
}

