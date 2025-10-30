import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { maplibre } from 'maplibre_harmony';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
import { MarkerOptions } from 'maplibre_harmony/src/main/ets/maps/annotations/MarkerOptions';
import { InfoWindowComponent } from 'maplibre_harmony/src/main/ets/maps/annotations/InfoWindow';
import { AnnotationView, AnnotationViewData, AnnotationViewAdapter } from 'maplibre_harmony/src/main/ets/maps/annotations';
// Marker 现在由 NAPI 提供
import { LatLng } from 'maplibre_harmony/src/main/ets/maps/geometry/LatLng';
import { CameraPosition } from 'maplibre_harmony/src/main/ets/maps/camera/CameraPosition';
import { OnMarkerClickListener } from 'maplibre_harmony/src/main/ets/maps/listeners/OnMarkerClickListener';
import { OnMarkerDragListener } from 'maplibre_harmony/src/main/ets/maps/listeners/OnMarkerDragListener';
import { OnInfoWindowClickListener } from 'maplibre_harmony/src/main/ets/maps/listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from 'maplibre_harmony/src/main/ets/maps/listeners/OnInfoWindowCloseListener';
import { OnMarkerSelectListener } from 'maplibre_harmony/src/main/ets/maps/listeners/OnMarkerSelectListener';
import { router } from '@kit.ArkUI';
import { DOMAIN } from '../constants/HiLogConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';
// import { ComponentContent, wrapBuilder } from '@kit.ArkUI';
import { TestPageLayout } from '../components/TestPageLayout';


const TAG = 'MarkerTestPage';

/**
 * MarkerTestPage - Marker 完整功能测试页面
 * 
 * 完整展示 Marker 的所有功能：
 * 1. ✅ 添加/删除单个 Marker
 * 2. ✅ 批量添加 Marker（性能测试）
 * 3. ✅ Marker 点击事件
 * 4. ✅ Marker 拖拽事件监听
 * 5. ✅ InfoWindow 显示/隐藏
 * 6. ✅ 不同样式的 Marker（透明度、旋转、锚点、Z-index）
 * 7. ✅ Marker 动画（位置、透明度、旋转）
 * 8. ✅ 选中/取消选中
 * 9. ✅ 批量操作（旋转所有、切换可见性）
 * 10. ✅ 随机位置生成（中国范围）
 * 11. ✅ 样式控制（可见性、透明度调整、聚焦）
 * 12. ✅ Position 解析测试（LatLng 类、构造函数）
 * 
 * 注：已整合原 MarkerAdvancedTestPage 的功能
 */

/**
 * Marker 点击监听器实现
 */
class MarkerClickListenerImpl implements OnMarkerClickListener {
  private testPage: MarkerTestPage;
  
  constructor(testPage: MarkerTestPage) {
    this.testPage = testPage;
  }
  
  onMarkerClick(marker: maplibre.Marker): boolean {
    this.testPage.selectedMarkerId = marker.getId();
    const pos: maplibre.LatLng = marker.getPosition();
    this.testPage.message = `🎯 点击: ${marker.getTitle()} (${pos.latitude.toFixed(4)}, ${pos.longitude.toFixed(4)})`;
    this.testPage.lastMarkerPosition = `${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)}`;
    
    console.info(`MarkerTestPage: maplibre.Marker clicked - ID=${marker.getId()}, Title=${marker.getTitle()}`);
    
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
  
  onMarkerDragStart(marker: maplibre.Marker): void {
    const pos: maplibre.LatLng = marker.getPosition();
    this.testPage.message = `🤏 开始拖拽: ${marker.getTitle()}`;
    this.testPage.lastMarkerPosition = `起始: ${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)}`;
    console.info(`MarkerTestPage: Drag start - ${marker.getTitle()}`);
  }
  
  onMarkerDrag(marker: maplibre.Marker): void {
    const pos: maplibre.LatLng = marker.getPosition();
    this.testPage.lastMarkerPosition = `拖拽中: ${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)}`;
    console.info(`MarkerTestPage: Dragging to ${pos.latitude}, ${pos.longitude}`);
  }
  
  onMarkerDragEnd(marker: maplibre.Marker): void {
    const pos: maplibre.LatLng = marker.getPosition();
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
  
  onInfoWindowClick(marker: maplibre.Marker): void {
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
  
  onInfoWindowClose(marker: maplibre.Marker): void {
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
  
  onMarkerSelect(marker: maplibre.Marker): void {
    this.testPage.message = `✅ Marker 选中: ${marker.getTitle()}`;
    console.info(`MarkerTestPage: maplibre.Marker selected - ID=${marker.getId()}, Title=${marker.getTitle()}`);
  }
  
  onMarkerDeselect(marker: maplibre.Marker): void {
    this.testPage.message = `⭕ Marker 取消选中: ${marker.getTitle()}`;
    console.info(`MarkerTestPage: maplibre.Marker deselected - ID=${marker.getId()}, Title=${marker.getTitle()}`);
  }
}

/**
 * 自定义 Marker 视图 Builder
 */
interface CustomMarkerParams {
  marker: maplibre.Marker;
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
  getAnnotationView(marker: maplibre.Marker): object | null {
    // TODO: 实现自定义视图
    // 当前 HarmonyOS SDK 版本不支持 ComponentContent 和 wrapBuilder
    return null;  // 暂时使用默认图标
  }
  
  getReuseIdentifier(marker: maplibre.Marker): string {
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
  @State infoWindowMarker: maplibre.Marker | null = null;
  @State infoWindowX: number = 0;
  @State infoWindowY: number = 0;
  
  // AnnotationView 显示状态
  @State annotationViews: AnnotationViewData[] = [];
  @State useCustomView: boolean = false;
  
  // 测试用的位置（使用 LatLng NAPI 类）
  private testLocations: maplibre.LatLng[] = [
    new maplibre.LatLng(39.9042, 116.4074),  // 北京
    new maplibre.LatLng(31.2304, 121.4737),  // 上海
    new maplibre.LatLng(22.3193, 114.1694),  // 深圳
    new maplibre.LatLng(30.5728, 104.0668),  // 成都
    new maplibre.LatLng(34.2634, 108.9463),  // 西安
  ];
  
  /**
   * 生成中国境内的随机经纬度
   * 中国地理范围约为：
   * 纬度：18°N - 54°N
   * 经度：73°E - 135°E
   */
  private generateRandomLocationInChina(): maplibre.LatLng {
    // 中国的大致边界
    const minLat: number = 18.0;   // 最南端（海南岛）
    const maxLat: number = 54.0;   // 最北端（黑龙江）
    const minLng: number = 73.0;   // 最西端（新疆）
    const maxLng: number = 135.0;  // 最东端（黑龙江）
    
    // 生成随机经纬度
    const lat: number = minLat + Math.random() * (maxLat - minLat);
    const lng: number = minLng + Math.random() * (maxLng - minLng);
    
    return new maplibre.LatLng(lat, lng);
  }
  
  /**
   * 获取随机中国城市名称
   */
  private getRandomCityName(): string {
    const cities = [
      '北京', '上海', '广州', '深圳', '杭州', '南京', '苏州', '武汉',
      '成都', '重庆', '西安', '郑州', '济南', '青岛', '长沙', '福州',
      '厦门', '昆明', '贵阳', '南宁', '海口', '太原', '石家庄', '哈尔滨',
      '长春', '沈阳', '大连', '天津', '宁波', '温州', '合肥', '南昌'
    ];
    return cities[Math.floor(Math.random() * cities.length)];
  }
  
  private testMarker: maplibre.Marker | null = null;
  private markerList: maplibre.Marker[] = [];
  
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
    infoWindowManager.setOnShowUICallback((marker: maplibre.Marker) => {
      this.showInfoWindowUI(marker);
    });
    
    // 设置隐藏回调
    infoWindowManager.setOnHideUICallback((marker: maplibre.Marker) => {
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
  showInfoWindowUI(marker: maplibre.Marker) {
    if (!this.nativeMapView) return;
    
    const pos: maplibre.LatLng = marker.getPosition();
    
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
  async addSingleMarker() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    // 使用随机位置而不是固定位置
    const location = this.generateRandomLocationInChina();
    const cityName = this.getRandomCityName();
    
    try {
      // [MarkerDebug] 记录地图当前状态
      if (this.nativeMapView) {
        const currentPos: maplibre.LatLng = this.nativeMapView.getLatLng();
        const currentZoom: number = this.nativeMapView.getZoom();
        console.info(`[MarkerDebug] TestPage: Current camera - lat=${currentPos.latitude}, lng=${currentPos.longitude}, zoom=${currentZoom}`);
        console.info(`[MarkerDebug] TestPage: Adding random marker at lat=${location.latitude}, lng=${location.longitude}`);
      }
      
      // 创建带不同样式的 Marker（不设置 icon，将自动使用默认图标）
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(location)
          .title(`${cityName} #${this.markerCount + 1}`)
          .snippet(`位置: ${location.latitude.toFixed(4)}, ${location.longitude.toFixed(4)}`)
          .draggable(true)
          .alpha(0.85 + Math.random() * 0.15)  // 随机透明度 0.85-1.0
          .rotation(Math.random() * 360)  // 随机旋转角度
          .zIndex(this.markerCount)
          // ✅ 注意：不设置 icon，将自动使用默认的红色 pin 图标
      );
      
      this.testMarker = marker;
      this.markerList.push(marker);
      this.markerCount++;
      this.lastMarkerPosition = `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`;
      this.message = `✅ 添加成功: ${marker.getTitle()} (ID: ${marker.getId()})`;
      
      console.info(`[MarkerDebug] TestPage: Random marker added with ID=${marker.getId()} at (${location.latitude.toFixed(4)}, ${location.longitude.toFixed(4)})`);
    } catch (e) {
      this.message = `❌ 添加失败: ${e.message}`;
      console.error(`[MarkerDebug] TestPage: ❌ Failed to add marker - ${e.message}`);
    }
  }
  
  /**
   * 批量添加 Marker
   */
  async addBatchMarkers() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    try {
      const options: MarkerOptions[] = [];
      const batchSize = 5;  // 每次批量添加5个
      
      // 生成随机位置的markers
      for (let i = 0; i < batchSize; i++) {
        const location = this.generateRandomLocationInChina();
        const cityName = this.getRandomCityName();
        
        options.push(
          new MarkerOptions()
            .position(location)
            .title(`${cityName} #${this.markerCount + i + 1}`)
            .snippet(`批量 - ${location.latitude.toFixed(4)}, ${location.longitude.toFixed(4)}`)
            .alpha(0.85 + Math.random() * 0.15)  // 随机透明度
            .rotation(Math.random() * 360)  // 随机旋转
            .zIndex(100 + this.markerCount + i)
            .draggable(true)
            // ✅ 不设置 icon，将自动使用默认的红色 pin 图标
        );
      }
      
      const startTime = Date.now();
      const markers = await this.mapLibreMap.addMarkersBatch(options);
      const endTime = Date.now();
      
      this.markerList.push(...markers);
      this.markerCount += markers.length;
      this.message = `✅ 批量添加成功: ${markers.length} 个随机位置 Marker (耗时: ${endTime - startTime}ms)`;
      
      console.info(`MarkerTestPage: Batch added ${markers.length} markers at random locations in ${endTime - startTime}ms`);
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
    
    // 优先从 markerList 数组中移除最后一个
    if (this.markerList.length > 0) {
      const lastMarker = this.markerList[this.markerList.length - 1];
      console.info(`MarkerTestPage: Removing last marker from list, ID=${lastMarker.getId()}, title=${lastMarker.getTitle()}`);
      
      lastMarker.remove();
      this.markerList.pop(); // 从数组中移除
      
      // 如果移除的是 testMarker，清空引用
      if (lastMarker === this.testMarker) {
        this.testMarker = null;
      }
      
      this.message = `✅ 已移除最后的 Marker: ${lastMarker.getTitle()}`;
      this.markerCount = Math.max(0, this.markerCount - 1);
      
      console.info(`MarkerTestPage: maplibre.Marker removed successfully, remaining count: ${this.markerList.length}`);
    } else if (this.testMarker) {
      // 如果 markerList 为空但 testMarker 存在，移除 testMarker
      console.info(`MarkerTestPage: Removing testMarker, ID=${this.testMarker.getId()}`);
      
      this.testMarker.remove();
      this.message = `✅ 已移除 Marker: ${this.testMarker.getTitle()}`;
      this.testMarker = null;
      this.markerCount = Math.max(0, this.markerCount - 1);
      
      console.info(`MarkerTestPage: testMarker removed successfully`);
    } else {
      this.message = '❌ 没有可移除的 Marker';
      console.warn('MarkerTestPage: No markers to remove');
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
    this.markerList = [];  // 清空数组
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
    
    const currentPos: maplibre.LatLng = this.testMarker.getPosition();
    const targetPos: maplibre.LatLng = new maplibre.LatLng(
      currentPos.latitude + 0.5,
      currentPos.longitude + 0.5
    );
    
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
    if (!this.testMarker || !this.mapLibreMap) {
      this.message = '请先添加一个 Marker';
      return;
    }
    
    const marker: maplibre.Marker = this.testMarker;
    const currentAlpha: number = marker.getAlpha();
    const targetAlpha: number = currentAlpha > 0.5 ? 0.3 : 1.0;
    const duration: number = 1000;  // 1 秒
    const fps: number = 60;
    const steps: number = Math.floor(duration / (1000 / fps));
    const deltaAlpha: number = targetAlpha - currentAlpha;
    
    this.message = `开始透明度动画: ${currentAlpha.toFixed(2)} → ${targetAlpha.toFixed(2)}`;
    
    let currentStep = 0;
    
    // 使用定时器实现平滑动画
    const intervalId = setInterval(() => {
      currentStep++;
      const progress = currentStep / steps;
      
      if (progress >= 1.0) {
        // 动画完成
        marker.setAlpha(targetAlpha);
        if (this.mapLibreMap) {
          this.mapLibreMap.updateMarker(marker);
        }
        clearInterval(intervalId);
        this.message = `✅ 透明度动画完成: ${targetAlpha.toFixed(2)}`;
        console.info('MarkerTestPage: Alpha animation completed');
        return;
      }
      
      // 线性插值
      const newAlpha: number = currentAlpha + deltaAlpha * progress;
      marker.setAlpha(newAlpha);
      
      // 更新地图显示
      if (this.mapLibreMap) {
        this.mapLibreMap.updateMarker(marker);
      }
    }, 1000 / fps);
  }
  
  /**
   * 测试旋转动画
   */
  testRotationAnimation() {
    if (!this.testMarker || !this.mapLibreMap) {
      this.message = '请先添加一个 Marker';
      return;
    }
    
    const marker: maplibre.Marker = this.testMarker;
    const currentRotation: number = marker.getRotation();
    const targetRotation: number = currentRotation + 90;
    const duration: number = 1000;  // 1 秒
    const fps: number = 60;
    const steps: number = Math.floor(duration / (1000 / fps));
    const deltaRotation: number = targetRotation - currentRotation;
    
    this.message = `开始旋转动画: ${currentRotation.toFixed(1)}° → ${targetRotation.toFixed(1)}°`;
    
    let currentStep = 0;
    
    // 使用定时器实现平滑动画
    const intervalId = setInterval(() => {
      currentStep++;
      const progress = currentStep / steps;
      
      if (progress >= 1.0) {
        // 动画完成
        marker.setRotation(targetRotation);
        if (this.mapLibreMap) {
          this.mapLibreMap.updateMarker(marker);
        }
        clearInterval(intervalId);
        this.message = `✅ 旋转动画完成: ${targetRotation.toFixed(1)}°`;
        console.info('MarkerTestPage: Rotation animation completed');
        return;
      }
      
      // 线性插值
      const newRotation: number = currentRotation + deltaRotation * progress;
      marker.setRotation(newRotation);
      
      // 更新地图显示
      if (this.mapLibreMap) {
        this.mapLibreMap.updateMarker(marker);
      }
    }, 1000 / fps);
  }

  @Builder
  MapAreaBuilder() {
    Stack() {
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
            .color('#2196F3')
          
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
    .height('100%')
  }

  @Builder
  ControlAreaBuilder() {
    // 状态信息
    Column({ space: 5 }) {
      Text(this.message)
        .fontSize(13)
        .fontColor('#333333')
        .width('100%')
      
      Row({ space: 20 }) {
        Text(`Marker 数量: ${this.markerCount}`)
          .fontSize(12)
          .fontColor('#2196F3')
        
        if (this.selectedMarkerId >= 0) {
          Text(`选中 ID: ${this.selectedMarkerId}`)
            .fontSize(12)
            .fontColor('#43A047')
        }
      }
      .width('100%')
      
      if (this.lastMarkerPosition) {
        Text(`坐标: ${this.lastMarkerPosition}`)
          .fontSize(11)
          .fontColor('#757575')
          .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F8F8F8')
    
    // 基础操作
    Text('基础操作')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
    
    Row() {
      Button('➕ 添加单个')
        .onClick(() => this.handleAddSingleMarker())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
      
      Button('🚀 批量添加')
        .onClick(() => this.handleAddBatchMarkers())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
    }
    .width('100%')
    
    Row() {
      Button('➖ 移除最后')
        .onClick(() => this.handleRemoveLastMarker())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#FFA726')
      
      Button('🗑️ 清除所有')
        .onClick(() => this.handleClearAllMarkers())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#EF5350')
    }
    .width('100%')
    
    // 动画测试
    Text('动画测试')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
    
    Row() {
      Button('📍 位置')
        .onClick(() => this.handleTestMarkerAnimation())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#AB47BC')
      
      Button('👁️ 透明度')
        .onClick(() => this.handleTestAlphaAnimation())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#AB47BC')
    }
    .width('100%')
    
    Button('🔄 旋转')
      .onClick(() => this.handleTestRotationAnimation())
      .width('48%')
      .type(ButtonType.Normal)
      .borderRadius(8)
      .backgroundColor('#AB47BC')
    
    // Position 解析测试
    Text('Position 解析测试')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor('#E53935')
    
    Row() {
      Button('🧪 LatLng类')
        .onClick(() => this.handleTestLatLngClass())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#E53935')
      
      Button('📝 构造函数')
        .onClick(() => this.handleTestPlainObject())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#E53935')
    }
    .width('100%')
    
    Row() {
      Button('🔄 更新Position')
        .onClick(() => this.handleTestUpdatePosition())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#F4511E')
      
      Button('📊 显示信息')
        .onClick(() => this.handleShowMarkerInfo())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#F4511E')
    }
    .width('100%')
    
    // 高级功能
    Text('高级功能')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
    
    Row() {
      Button('🎯 选中第一个')
        .onClick(() => this.handleSelectFirstMarker())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#26A69A')
      
      Button('❌ 取消选中')
        .onClick(() => this.handleDeselectAll())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#78909C')
    }
    .width('100%')
    
    Row() {
      Button('💬 InfoWindow')
        .onClick(() => this.handleTestInfoWindow())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#26A69A')
      
      Button('🎨 自定义图标')
        .onClick(() => this.handleTestCustomIcon())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#5C6BC0')
    }
    .width('100%')
    
    // 样式控制
    Text('样式控制')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
    
    Row() {
      Button('👁️ 切换可见')
        .onClick(() => this.handleToggleVisibility())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#7E57C2')
      
      Button('🔍 聚焦Marker')
        .onClick(() => this.handleFocusMarker())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#7E57C2')
    }
    .width('100%')
    
    Row() {
      Button('💧 透明度+')
        .onClick(() => this.handleIncreaseAlpha())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#5C6BC0')
      
      Button('💧 透明度-')
        .onClick(() => this.handleDecreaseAlpha())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#5C6BC0')
    }
    .width('100%')
    
    Button('🚫 关闭所有InfoWindow')
      .onClick(() => this.handleCloseAllInfoWindows())
      .width('48%')
      .type(ButtonType.Normal)
      .borderRadius(8)
      .backgroundColor('#8D6E63')
    
    // 批量操作
    Text('批量操作')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
    
    Row() {
      Button('🔄 全部旋转90°')
        .onClick(() => this.handleRotateAllMarkers())
        .width('48%')
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#FF7043')
      
      Button('👻 切换全部可见')
        .onClick(() => this.handleToggleAllVisibility())
        .width('48%')
        .margin({ left: 8 })
        .type(ButtonType.Normal)
        .borderRadius(8)
        .backgroundColor('#FF7043')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'Marker 完整功能测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
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
  
  // ==================== Position 解析测试 (NEW) ====================
  
  /**
   * 测试使用 LatLng NAPI 类实例创建 Marker
   */
  async testLatLngClass() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    try {
      // 使用 LatLng NAPI 类创建位置（通过构造函数）
      const position: maplibre.LatLng = new maplibre.LatLng(39.9042, 116.4074);
      
      console.info(`[MarkerDebug] TestLatLngClass: Creating marker with LatLng instance`);
      console.info(`[MarkerDebug] TestLatLngClass: position.latitude=${position.latitude}, position.longitude=${position.longitude}`);
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('LatLng 类测试')
          .snippet(`使用 LatLng NAPI 类创建\n纬度: ${position.latitude}\n经度: ${position.longitude}`)
          .draggable(true)
          .alpha(1.0)
          .rotation(0)
          .zIndex(200)
          // ✅ 不设置 icon，将自动使用默认的红色 pin 图标
      );
      
      this.markerList.push(marker);
      this.markerCount++;
      this.testMarker = marker;
      
      const resultPos: maplibre.LatLng = marker.getPosition();
      this.message = `✅ LatLng类测试成功\n` +
        `输入: (${position.latitude}, ${position.longitude})\n` +
        `结果: (${resultPos.latitude}, ${resultPos.longitude})\n` +
        `ID: ${marker.getId()} - 使用默认图标`;
      
      console.info(`[MarkerDebug] TestLatLngClass: Success - Marker ID=${marker.getId()}`);
    } catch (e) {
      this.message = `❌ LatLng类测试失败: ${e.message}`;
      console.error(`[MarkerDebug] TestLatLngClass: Failed - ${e.message}`);
    }
  }
  
  /**
   * 测试使用构造函数创建 Marker
   */
  async testPlainObject() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    try {
      // 使用 new maplibre.LatLng() 构造函数创建位置
      const position: maplibre.LatLng = new maplibre.LatLng(31.2304, 121.4737);
      
      console.info(`[MarkerDebug] TestConstructor: Creating marker with constructor`);
      console.info(`[MarkerDebug] TestConstructor: position=(${position.latitude}, ${position.longitude})`);
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('构造函数测试')
          .snippet(`使用构造函数创建\n纬度: ${position.latitude}\n经度: ${position.longitude}`)
          .draggable(true)
          .alpha(0.9)
          .rotation(45)
          .zIndex(201)
          // ✅ 不设置 icon，将自动使用默认的红色 pin 图标
      );
      
      this.markerList.push(marker);
      this.markerCount++;
      this.testMarker = marker;
      
      const resultPos: maplibre.LatLng = marker.getPosition();
      this.message = `✅ 构造函数测试成功\n` +
        `输入: new maplibre.LatLng(${position.latitude}, ${position.longitude})\n` +
        `结果: (${resultPos.latitude}, ${resultPos.longitude})\n` +
        `ID: ${marker.getId()} - 使用默认图标`;
      
      console.info(`[MarkerDebug] TestConstructor: Success - Marker ID=${marker.getId()}`);
    } catch (e) {
      this.message = `❌ 构造函数测试失败: ${e.message}`;
      console.error(`[MarkerDebug] TestConstructor: Failed - ${e.message}`);
    }
  }
  
  /**
   * 测试更新 Marker 的 Position
   */
  testUpdatePosition() {
    if (!this.mapLibreMap || !this.testMarker) {
      this.message = '❌ 请先创建一个 Marker';
      return;
    }
    
    try {
      const oldPos: maplibre.LatLng = this.testMarker.getPosition();
      
      // 测试使用 LatLng 类实例更新
      const newPosition: maplibre.LatLng = new maplibre.LatLng(
        oldPos.latitude + 1.0,
        oldPos.longitude + 1.0
      );
      
      console.info(`[MarkerDebug] TestUpdatePosition: Updating marker ${this.testMarker.getId()}`);
      console.info(`[MarkerDebug] TestUpdatePosition: Old position=(${oldPos.latitude}, ${oldPos.longitude})`);
      console.info(`[MarkerDebug] TestUpdatePosition: New position=(${newPosition.latitude}, ${newPosition.longitude})`);
      
      this.testMarker.setPosition(newPosition);
      
      // 更新到地图
      this.mapLibreMap.updateMarker(this.testMarker);
      
      const resultPos: maplibre.LatLng = this.testMarker.getPosition();
      this.message = `✅ Position更新成功\n` +
        `旧位置: (${oldPos.latitude.toFixed(4)}, ${oldPos.longitude.toFixed(4)})\n` +
        `新位置: (${resultPos.latitude.toFixed(4)}, ${resultPos.longitude.toFixed(4)})`;
      
      console.info(`[MarkerDebug] TestUpdatePosition: Success - New position=(${resultPos.latitude}, ${resultPos.longitude})`);
    } catch (e) {
      this.message = `❌ Position更新失败: ${e.message}`;
      console.error(`[MarkerDebug] TestUpdatePosition: Failed - ${e.message}`);
    }
  }
  
  /**
   * 显示 Marker 的详细信息
   */
  showMarkerInfo() {
    if (!this.testMarker) {
      this.message = '❌ 请先创建一个 Marker';
      return;
    }
    
    try {
      const pos: maplibre.LatLng = this.testMarker.getPosition();
      const id: number = this.testMarker.getId();
      const title: string = this.testMarker.getTitle();
      const snippet: string = this.testMarker.getSnippet();
      const visible: boolean = this.testMarker.getVisible();
      const alpha: number = this.testMarker.getAlpha();
      const rotation: number = this.testMarker.getRotation();
      const zIndex: number = this.testMarker.getZIndex();
      const draggable: boolean = this.testMarker.getDraggable();
      const icon = this.testMarker.getIcon();
      
      this.message = `📊 Marker 详细信息\n` +
        `═══════════════════\n` +
        `ID: ${id}\n` +
        `标题: ${title}\n` +
        `位置: (${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)})\n` +
        `图标: ${icon || '(无)'}\n` +
        `可见: ${visible ? '是' : '否'}\n` +
        `透明度: ${alpha.toFixed(2)}\n` +
        `旋转角度: ${rotation.toFixed(1)}°\n` +
        `Z-Index: ${zIndex}\n` +
        `可拖拽: ${draggable ? '是' : '否'}`;
      
      console.info(`[MarkerDebug] ShowMarkerInfo: maplibre.Marker ${id} details displayed`);
      console.info(`[MarkerDebug] Position: (${pos.latitude}, ${pos.longitude})`);
    } catch (e) {
      this.message = `❌ 获取信息失败: ${e.message}`;
      console.error(`[MarkerDebug] ShowMarkerInfo: Failed - ${e.message}`);
    }
  }
  
  /**
   * 测试 InfoWindow 功能
   */
  async testInfoWindow() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    try {
      // 创建一个带有详细 InfoWindow 内容的 Marker
      const position = new maplibre.LatLng(40.0, 116.0);
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('InfoWindow 测试')
          .snippet('这是一个详细的描述信息\n可以包含多行文本\n用于展示 InfoWindow 功能')
          .draggable(false)
          .alpha(1.0)
          .zIndex(300)
      );
      
      this.testMarker = marker;
      this.markerList.push(marker);
      this.markerCount++;
      
      // 自动显示 InfoWindow
      marker.showInfoWindow();
      
      this.message = `✅ InfoWindow 测试创建成功\n` +
        `标题: ${marker.getTitle()}\n` +
        `描述: ${marker.getSnippet()}\n` +
        `💡 点击 Marker 可以显示/隐藏 InfoWindow`;
      
      console.info(`[MarkerDebug] InfoWindow test marker created with ID=${marker.getId()}`);
    } catch (e) {
      this.message = `❌ InfoWindow 测试失败: ${e.message}`;
      console.error(`[MarkerDebug] InfoWindow test failed - ${e.message}`);
    }
  }
  
  /**
   * 测试自定义图标功能
   */
  async testCustomIcon() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    try {
      const position = new maplibre.LatLng(38.0, 115.0);
      
      // 尝试加载自定义图标
      // 注意：这里需要先在 rawfile 目录准备自定义图标文件
      // 作为示例，我们先创建一个使用默认图标但带特殊标记的 Marker
      this.message = '⏳ 正在创建自定义图标 Marker...';
      
      const marker: maplibre.Marker = await this.mapLibreMap.addMarker(
        new MarkerOptions()
          .position(position)
          .title('自定义图标测试')
          .snippet('演示自定义图标功能\n当前使用默认图标')
          .draggable(true)
          .alpha(0.95)
          .rotation(45)  // 旋转 45 度以区分
          .zIndex(400)
      );
      
      this.testMarker = marker;
      this.markerList.push(marker);
      this.markerCount++;
      
      this.message = `✅ 自定义图标 Marker 创建成功\n` +
        `ID: ${marker.getId()}\n` +
        `位置: (${position.latitude}, ${position.longitude})\n` +
        `旋转: 45°\n` +
        `💡 提示: 当前使用默认图标\n` +
        `要使用自定义图标，请使用 IconFactory.fromRawfile()`;
      
      console.info(`[MarkerDebug] Custom icon test marker created with ID=${marker.getId()}`);
      
      // 显示如何使用自定义图标的提示
      setTimeout(() => {
        this.message += `\n\n📝 代码示例:\n` +
          `const iconFactory = IconFactory.getInstance();\n` +
          `const customIcon = await iconFactory.fromRawfile('my_icon.png');\n` +
          `options.icon(customIcon);`;
      }, 2000);
      
    } catch (e) {
      this.message = `❌ 自定义图标测试失败: ${e.message}`;
      console.error(`[MarkerDebug] Custom icon test failed - ${e.message}`);
    }
  }
  
  // ==================== 样式控制测试 ====================
  
  /**
   * 切换 Marker 可见性
   */
  toggleVisibility() {
    if (!this.testMarker) {
      this.message = '❌ 请先创建一个 Marker';
      return;
    }
    
    try {
      const currentVisible = this.testMarker.getVisible();
      this.testMarker.setVisible(!currentVisible);
      
      // 更新到地图
      if (this.mapLibreMap) {
        this.mapLibreMap.updateMarker(this.testMarker);
      }
      
      this.message = `✅ 可见性已切换: ${!currentVisible ? '显示' : '隐藏'}`;
      console.info(`[MarkerDebug] Marker visibility toggled to ${!currentVisible}`);
    } catch (e) {
      this.message = `❌ 切换可见性失败: ${e.message}`;
      console.error(`[MarkerDebug] Toggle visibility failed - ${e.message}`);
    }
  }
  
  /**
   * 聚焦到 Marker 位置
   */
  focusMarker() {
    if (!this.testMarker || !this.mapLibreMap) {
      this.message = '❌ 请先创建一个 Marker';
      return;
    }
    
    try {
      const pos: maplibre.LatLng = this.testMarker.getPosition();
      
      // 移动相机到 Marker 位置，缩放到合适级别
      this.mapLibreMap.flyTo({
        center: pos,
        zoom: 10,
        bearing: 0,
        pitch: 45
      }, 2000);
      
      this.message = `✅ 正在聚焦到 Marker\n位置: (${pos.latitude.toFixed(4)}, ${pos.longitude.toFixed(4)})`;
      console.info(`[MarkerDebug] Focusing on marker at (${pos.latitude}, ${pos.longitude})`);
    } catch (e) {
      this.message = `❌ 聚焦失败: ${e.message}`;
      console.error(`[MarkerDebug] Focus marker failed - ${e.message}`);
    }
  }
  
  /**
   * 增加 Marker 透明度
   */
  increaseAlpha() {
    if (!this.testMarker) {
      this.message = '❌ 请先创建一个 Marker';
      return;
    }
    
    try {
      const currentAlpha = this.testMarker.getAlpha();
      const newAlpha = Math.min(1.0, currentAlpha + 0.1);
      
      this.testMarker.setAlpha(newAlpha);
      
      // 更新到地图
      if (this.mapLibreMap) {
        this.mapLibreMap.updateMarker(this.testMarker);
      }
      
      this.message = `✅ 透明度增加\n当前: ${newAlpha.toFixed(2)} (${(newAlpha * 100).toFixed(0)}%)`;
      console.info(`[MarkerDebug] Alpha increased to ${newAlpha}`);
    } catch (e) {
      this.message = `❌ 调整透明度失败: ${e.message}`;
      console.error(`[MarkerDebug] Increase alpha failed - ${e.message}`);
    }
  }
  
  /**
   * 减少 Marker 透明度
   */
  decreaseAlpha() {
    if (!this.testMarker) {
      this.message = '❌ 请先创建一个 Marker';
      return;
    }
    
    try {
      const currentAlpha = this.testMarker.getAlpha();
      const newAlpha = Math.max(0.0, currentAlpha - 0.1);
      
      this.testMarker.setAlpha(newAlpha);
      
      // 更新到地图
      if (this.mapLibreMap) {
        this.mapLibreMap.updateMarker(this.testMarker);
      }
      
      this.message = `✅ 透明度减少\n当前: ${newAlpha.toFixed(2)} (${(newAlpha * 100).toFixed(0)}%)`;
      console.info(`[MarkerDebug] Alpha decreased to ${newAlpha}`);
    } catch (e) {
      this.message = `❌ 调整透明度失败: ${e.message}`;
      console.error(`[MarkerDebug] Decrease alpha failed - ${e.message}`);
    }
  }
  
  /**
   * 关闭所有 InfoWindow
   */
  closeAllInfoWindows() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    try {
      const markerManager = this.mapLibreMap.getMarkerManager();
      markerManager.hideAllInfoWindows();
      
      this.message = '✅ 已关闭所有 InfoWindow';
      console.info('[MarkerDebug] All InfoWindows closed');
    } catch (e) {
      this.message = `❌ 关闭 InfoWindow 失败: ${e.message}`;
      console.error(`[MarkerDebug] Close all InfoWindows failed - ${e.message}`);
    }
  }
  
  // ==================== 批量操作测试 ====================
  
  /**
   * 旋转所有 Marker
   */
  rotateAllMarkers() {
    if (!this.mapLibreMap || this.markerList.length === 0) {
      this.message = '❌ 没有可操作的 Marker';
      return;
    }
    
    try {
      let updateCount = 0;
      
      for (const marker of this.markerList) {
        const currentRotation = marker.getRotation();
        marker.setRotation(currentRotation + 90);
        this.mapLibreMap.updateMarker(marker);
        updateCount++;
      }
      
      this.message = `✅ 已旋转 ${updateCount} 个 Marker\n每个旋转 +90°`;
      console.info(`[MarkerDebug] Rotated ${updateCount} markers by 90 degrees`);
    } catch (e) {
      this.message = `❌ 批量旋转失败: ${e.message}`;
      console.error(`[MarkerDebug] Rotate all markers failed - ${e.message}`);
    }
  }
  
  /**
   * 切换所有 Marker 可见性
   */
  toggleAllVisibility() {
    if (!this.mapLibreMap || this.markerList.length === 0) {
      this.message = '❌ 没有可操作的 Marker';
      return;
    }
    
    try {
      // 检查第一个 marker 的状态，然后应用相反的状态到所有 marker
      const firstVisible = this.markerList[0].getVisible();
      const newVisible = !firstVisible;
      let updateCount = 0;
      
      for (const marker of this.markerList) {
        marker.setVisible(newVisible);
        this.mapLibreMap.updateMarker(marker);
        updateCount++;
      }
      
      this.message = `✅ 已更新 ${updateCount} 个 Marker\n状态: ${newVisible ? '显示' : '隐藏'}`;
      console.info(`[MarkerDebug] Toggled visibility for ${updateCount} markers to ${newVisible}`);
    } catch (e) {
      this.message = `❌ 批量切换可见性失败: ${e.message}`;
      console.error(`[MarkerDebug] Toggle all visibility failed - ${e.message}`);
    }
  }
  
  // ========== 包装方法（用于 @Builder 中的 this 上下文绑定） ==========
  
  private handleAddSingleMarker = (): void => {
    this.addSingleMarker();
  }
  
  private handleAddBatchMarkers = (): void => {
    this.addBatchMarkers();
  }
  
  private handleRemoveLastMarker = (): void => {
    this.removeLastMarker();
  }
  
  private handleClearAllMarkers = (): void => {
    this.clearAllMarkers();
  }
  
  private handleTestMarkerAnimation = (): void => {
    this.testMarkerAnimation();
  }
  
  private handleTestAlphaAnimation = (): void => {
    this.testAlphaAnimation();
  }
  
  private handleTestRotationAnimation = (): void => {
    this.testRotationAnimation();
  }
  
  private handleTestLatLngClass = (): void => {
    this.testLatLngClass();
  }
  
  private handleTestPlainObject = (): void => {
    this.testPlainObject();
  }
  
  private handleTestUpdatePosition = (): void => {
    this.testUpdatePosition();
  }
  
  private handleShowMarkerInfo = (): void => {
    this.showMarkerInfo();
  }
  
  private handleSelectFirstMarker = (): void => {
    this.selectFirstMarker();
  }
  
  private handleDeselectAll = (): void => {
    this.deselectAll();
  }
  
  private handleTestInfoWindow = (): void => {
    this.testInfoWindow();
  }
  
  private handleTestCustomIcon = (): void => {
    this.testCustomIcon();
  }
  
  private handleToggleVisibility = (): void => {
    this.toggleVisibility();
  }
  
  private handleFocusMarker = (): void => {
    this.focusMarker();
  }
  
  private handleIncreaseAlpha = (): void => {
    this.increaseAlpha();
  }
  
  private handleDecreaseAlpha = (): void => {
    this.decreaseAlpha();
  }
  
  private handleCloseAllInfoWindows = (): void => {
    this.closeAllInfoWindows();
  }
  
  private handleRotateAllMarkers = (): void => {
    this.rotateAllMarkers();
  }
  
  private handleToggleAllVisibility = (): void => {
    this.toggleAllVisibility();
  }
}

