import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { MarkerOptions } from '../maps/annotations/MarkerOptions';
import { InfoWindowComponent } from '../maps/annotations/InfoWindow';
import { AnnotationView, AnnotationViewData, AnnotationViewAdapter } from '../maps/annotations';
// Marker 现在由 NAPI 提供
import { LatLng } from '../maps/geometry/LatLng';
import { CameraPosition } from '../maps/camera/CameraPosition';
import { OnMarkerClickListener } from '../maps/listeners/OnMarkerClickListener';
import { OnMarkerDragListener } from '../maps/listeners/OnMarkerDragListener';
import { OnInfoWindowClickListener } from '../maps/listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from '../maps/listeners/OnInfoWindowCloseListener';
import { OnMarkerSelectListener } from '../maps/listeners/OnMarkerSelectListener';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
// import { ComponentContent, wrapBuilder } from '@kit.ArkUI';
import maplibre from 'libmaplibre_native.so';

// 使用 NAPI Marker 类型
type Marker = maplibre.Marker;

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

/**
 * InfoWindow 关闭监听器实现
 */
class InfoWindowCloseListenerImpl implements OnInfoWindowCloseListener {
  private testPage: MarkerTestPage;
  
  constructor(testPage: MarkerTestPage) {
    this.testPage = testPage;
  }
  
  onInfoWindowClose(marker: Marker): void {
    this.testPage.message = `🔒 InfoWindow 关闭: ${marker.getTitle()}`;
    console.info(`MarkerTestPage: InfoWindow closed - ${marker.getTitle()}`);
  }
}

/**
 * Marker 选中监听器实现
 */
class MarkerSelectListenerImpl implements OnMarkerSelectListener {
  private testPage: MarkerTestPage;
  
  constructor(testPage: MarkerTestPage) {
    this.testPage = testPage;
  }
  
  onMarkerSelect(marker: Marker): void {
    this.testPage.message = `✅ Marker 选中: ${marker.getTitle()}`;
    console.info(`MarkerTestPage: Marker selected - ID=${marker.getId()}, Title=${marker.getTitle()}`);
  }
  
  onMarkerDeselect(marker: Marker): void {
    this.testPage.message = `⭕ Marker 取消选中: ${marker.getTitle()}`;
    console.info(`MarkerTestPage: Marker deselected - ID=${marker.getId()}, Title=${marker.getTitle()}`);
  }
}

/**
 * 自定义 Marker 视图 Builder
 */
interface CustomMarkerParams {
  marker: Marker;
}

@Builder
function CustomMarkerBuilder(params: CustomMarkerParams) {
  Column() {
    // 自定义外观：圆形背景 + 标题
    Stack() {
      Circle({ width: 60, height: 60 })
        .fill('#FF5722')
        .opacity(0.9)
      
      Text(params.marker.getTitle())
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
    }
    .width(60)
    .height(60)
  }
}

/**
 * 自定义 AnnotationView 适配器
 * 
 * TODO: 等待 HarmonyOS SDK 支持 wrapBuilder 和 ComponentContent API
 * 当前版本暂时不支持自定义视图
 */
class TestAnnotationViewAdapter implements AnnotationViewAdapter {
  getAnnotationView(marker: Marker): object | null {
    // TODO: 实现自定义视图
    // 当前 HarmonyOS SDK 版本不支持 ComponentContent 和 wrapBuilder
    return null;  // 暂时使用默认图标
  }
  
  getReuseIdentifier(marker: Marker): string {
    return marker.getIcon() || 'default';
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
  
  // InfoWindow 显示状态
  @State showInfoWindow: boolean = false;
  @State infoWindowMarker: Marker | null = null;
  @State infoWindowX: number = 0;
  @State infoWindowY: number = 0;
  
  // AnnotationView 显示状态
  @State annotationViews: AnnotationViewData[] = [];
  @State useCustomView: boolean = false;
  
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
      
      // 延迟设置初始相机位置，等待地图完全初始化
      setTimeout(() => {
        if (this.mapLibreMap && !this.mapLibreMap.isDestroyed()) {
          try {
            // 设置初始相机位置（中国中心）
            this.mapLibreMap.jumpTo(0, 35.0, 105.0, 0, 4.0);
            hilog.info(DOMAIN, TAG, 'Initial camera position set');
          } catch (e) {
            hilog.error(DOMAIN, TAG, `Failed to set initial camera: ${e.message}`);
          }
        }
      }, 500);
      
      this.mapReady = true;
      this.message = '✅ 地图已就绪 - 可以开始测试';
      
      // 设置事件监听器
      this.setupEventListeners();
      
      // 设置 InfoWindow UI 回调
      this.setupInfoWindowCallbacks();
      
      // 设置 AnnotationView Manager
      this.setupAnnotationViewManager();
      
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
    const infoWindowCloseListener = new InfoWindowCloseListenerImpl(this);
    const markerSelectListener = new MarkerSelectListenerImpl(this);
    
    // 设置监听器
    this.mapLibreMap.setOnMarkerClickListener(markerClickListener);
    this.mapLibreMap.setOnMarkerDragListener(markerDragListener);
    this.mapLibreMap.setOnInfoWindowClickListener(infoWindowClickListener);
    this.mapLibreMap.setOnInfoWindowCloseListener(infoWindowCloseListener);
    this.mapLibreMap.setOnMarkerSelectListener(markerSelectListener);
    
    console.info('MarkerTestPage: Event listeners configured');
  }
  
  /**
   * 设置 InfoWindow UI 回调
   */
  setupInfoWindowCallbacks() {
    if (!this.mapLibreMap) return;
    
    const infoWindowManager = this.mapLibreMap.getMarkerManager().getInfoWindowManager();
    
    // 设置显示回调
    infoWindowManager.setOnShowUICallback((marker: Marker) => {
      this.showInfoWindowUI(marker);
    });
    
    // 设置隐藏回调
    infoWindowManager.setOnHideUICallback((marker: Marker) => {
      this.hideInfoWindowUI();
    });
    
    console.info('MarkerTestPage: InfoWindow callbacks configured');
  }
  
  /**
   * 设置 AnnotationView Manager
   */
  setupAnnotationViewManager() {
    if (!this.mapLibreMap || !this.nativeMapView) return;
    
    const markerManager = this.mapLibreMap.getMarkerManager();
    
    // 设置 Native MapView（用于坐标转换）
    markerManager.setNativeMapView(this.nativeMapView);
    
    console.info('MarkerTestPage: AnnotationView manager configured');
  }
  
  /**
   * 显示 InfoWindow UI
   */
  showInfoWindowUI(marker: Marker) {
    if (!this.nativeMapView) return;
    
    const pos = marker.getPosition();
    
    try {
      // 转换地理坐标到屏幕坐标
      const pixelCoord = this.nativeMapView.pixelForLatLng(pos.latitude, pos.longitude);
      
      // InfoWindow 显示在 Marker 上方
      this.infoWindowX = pixelCoord.x - 100;  // 假设 InfoWindow 宽度 200，居中显示
      this.infoWindowY = pixelCoord.y - 80;   // 向上偏移
      this.infoWindowMarker = marker;
      this.showInfoWindow = true;
      
      console.info(`[InfoWindow] Showing UI at (${this.infoWindowX}, ${this.infoWindowY})`);
    } catch (e) {
      console.error('[InfoWindow] Failed to show UI:', e);
    }
  }
  
  /**
   * 隐藏 InfoWindow UI
   */
  hideInfoWindowUI() {
    this.showInfoWindow = false;
    this.infoWindowMarker = null;
    console.info('[InfoWindow] Hiding UI');
  }
  
  /**
   * 更新 AnnotationView 显示
   */
  updateAnnotationViews() {
    if (!this.mapLibreMap) return;
    
    const annotationViewManager = this.mapLibreMap.getMarkerManager().getAnnotationViewManager();
    this.annotationViews = annotationViewManager.getVisibleViews();
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
      // [MarkerDebug] 记录地图当前状态
      if (this.nativeMapView) {
        const currentPos = this.nativeMapView.getLatLng();
        const currentZoom = this.nativeMapView.getZoom();
        console.info(`[MarkerDebug] TestPage: Current camera - lat=${currentPos.latitude}, lng=${currentPos.longitude}, zoom=${currentZoom}`);
        console.info(`[MarkerDebug] TestPage: Adding marker at lat=${location.latitude}, lng=${location.longitude}`);
        
        // 简单判断是否在视口范围内（粗略估算）
        const latDiff = Math.abs(currentPos.latitude - location.latitude);
        const lngDiff = Math.abs(currentPos.longitude - location.longitude);
        const roughDistance = Math.sqrt(latDiff * latDiff + lngDiff * lngDiff);
        const viewportSize = Math.pow(2, 10 - currentZoom); // 粗略估算视口大小
        
        if (roughDistance > viewportSize) {
          console.warn(`[MarkerDebug] TestPage: ⚠️ Marker may be outside viewport (distance=${roughDistance.toFixed(2)}, viewport~${viewportSize.toFixed(2)})`);
          this.message = `⚠️ Marker 可能在视口外，请缩放或移动地图`;
        }
      }
      
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
          // 注意：没有设置 icon，将使用空字符串，可能导致不可见！
      );
      
      this.testMarker = marker;
      this.markerList.push(marker);
      this.markerCount++;
      this.lastMarkerPosition = `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`;
      this.message = `➕ 添加成功: ${marker.getTitle()} (ID: ${marker.getId()}) - 注意：未设置 icon`;
      
      console.info(`[MarkerDebug] TestPage: Marker added with ID=${marker.getId()}`);
    } catch (e) {
      this.message = `❌ 添加失败: ${e.message}`;
      console.error(`[MarkerDebug] TestPage: ❌ Failed to add marker - ${e.message}`);
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
    
    this.message = '开始位置动画...';
    
    // 使用 animateToPosition API
    this.testMarker.animateToPosition(targetPos, 2000, () => {
      if (this.mapLibreMap) {
        this.mapLibreMap.updateMarker(this.testMarker!);
      }
      this.message = '✅ 位置动画完成';
      console.info('MarkerTestPage: Position animation completed');
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
    
    this.message = '开始透明度动画...';
    
    // 使用 animateAlpha API
    this.testMarker.animateAlpha(targetAlpha, 1000, () => {
      if (this.mapLibreMap) {
        this.mapLibreMap.updateMarker(this.testMarker!);
      }
      this.message = `✅ 透明度动画完成: ${targetAlpha}`;
      console.info('MarkerTestPage: Alpha animation completed');
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
    
    this.message = '开始旋转动画...';
    
    // 使用 animateRotation API
    this.testMarker.animateRotation(targetRotation, 1000, () => {
      if (this.mapLibreMap) {
        this.mapLibreMap.updateMarker(this.testMarker!);
      }
      this.message = `✅ 旋转动画完成: ${targetRotation}°`;
      console.info('MarkerTestPage: Rotation animation completed');
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
      .layoutWeight(1)
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

