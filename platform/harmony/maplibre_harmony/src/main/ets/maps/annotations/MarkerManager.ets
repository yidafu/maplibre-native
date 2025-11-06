import type { NativeMapView } from 'libmaplibre.so';
import type { MarkerOptions } from './MarkerOptions';
import { MarkerDragState } from './MarkerDragState';
import type { LatLng } from '../geometry/LatLng';
import { PixelCoordinate } from '../geometry/Point';
import type { MapLibreMap } from '../MapLibreMap';
import type { OnMarkerClickListener } from '../listeners/OnMarkerClickListener';
import type { OnMarkerLongClickListener } from '../listeners/OnMarkerLongClickListener';
import type { OnMarkerDragListener } from '../listeners/OnMarkerDragListener';
import type { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import type { OnInfoWindowCloseListener } from '../listeners/OnInfoWindowCloseListener';
import type { OnMarkerSelectListener } from '../listeners/OnMarkerSelectListener';
import type { InfoWindowAdapter } from './InfoWindowAdapter';
import { InfoWindowManager } from './InfoWindowManager';
import type { AnnotationViewAdapter } from './AnnotationViewAdapter';
import { AnnotationViewManager } from './AnnotationViewManager';
import { IconManager } from './IconManager';
import { IconFactory } from './IconFactory';
import { MarkerLayerManager } from './MarkerLayerManager';
import type { InfoWindowStyle } from './InfoWindow';
import type { Icon } from './Icon';
import type { Marker, MarkerAnchor } from './Marker';
import common from '@ohos.app.ability.common';
import type {
  OnMapClickListener,
  OnMapLongClickListener,
  OnTouchMoveListener,
  OnTouchUpListener
} from '../gestures/GestureListeners';
import type { OnStyleLoadedListener } from '../listeners/OnStyleLoadedListener';
import type { Style } from '../style/Style';

/**
 * MarkerManager - Marker 管理器
 *
 * 基于 GeoJSON Source + SymbolLayer 实现，支持所有高级功能
 *
 * 参考:
 * - Android: AnnotationManager + MarkerContainer + IconManager
 *   使用Icon对象引用计数，Marker直接持有Icon
 * - iOS: MLNShapeSource + MLNSymbolStyleLayer
 */
export class MarkerManager {
  private markerLayerManager: MarkerLayerManager;
  private selectedMarkers: Set<Marker> = new Set();
  private mapLibreMap: MapLibreMap;
  private infoWindowManager: InfoWindowManager;
  private annotationViewManager: AnnotationViewManager;
  private iconManager: IconManager;
  // Marker ID -> Marker 映射
  private markerMap: Map<number, Marker> = new Map();
  // Marker ID -> Icon 映射（因为NAPI Marker不持有Icon对象引用）
  // 注意：虽然保留此映射，但IconManager使用Icon对象作为key，确保引用计数正确
  private markerIconMap: Map<number, Icon> = new Map();
  // Marker ID -> InfoWindowStyle 映射（存储每个 Marker 的 InfoWindow 样式配置）
  private markerInfoWindowStyleMap: Map<number, InfoWindowStyle> = new Map();
  // 事件监听器
  private onMarkerClickListener: OnMarkerClickListener | null = null;
  private onMarkerLongClickListener: OnMarkerLongClickListener | null = null;
  private onMarkerDragListener: OnMarkerDragListener | null = null;
  private onInfoWindowClickListener: OnInfoWindowClickListener | null = null;
  private onMarkerSelectListener: OnMarkerSelectListener | null = null;
  private infoWindowAdapter: InfoWindowAdapter | null = null;
  // 拖拽相关
  private draggingMarker: Marker | null = null;
  private draggingMarkerId: number | null = null;

  /**
   * 构造函数
   *
   * @param mapLibreMap MapLibreMap 实例
   */
  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
    // ✅ 使用 MapLibreMap 的 InfoWindowManager（已经设置了 UI 回调）
    // 而不是创建新的实例（没有回调）
    this.infoWindowManager = mapLibreMap.getInfoWindowManager();
    this.annotationViewManager = new AnnotationViewManager();

    // 初始化 IconManager - 传递 ResourceManager 以支持 rawfile 加载
    const nativeMapView = mapLibreMap.getNativeMapView();

    // 获取 ResourceManager（用于加载 rawfile 资源，如默认图标）
    let iconFactory: IconFactory;
    try {
      // 从当前组件上下文获取 ResourceManager
      const context = getContext() as common.UIAbilityContext;
      const resourceMgr = context.resourceManager;
      iconFactory = IconFactory.getInstance(resourceMgr);
    } catch (error) {
      console.warn('[MarkerManager] Failed to get ResourceManager, using IconFactory without it:', error);
      iconFactory = IconFactory.getInstance();
    }

    this.iconManager = new IconManager(nativeMapView, iconFactory);

    // 初始化 MarkerLayerManager（GeoJSON + SymbolLayer）
    this.markerLayerManager = new MarkerLayerManager(mapLibreMap);

    // 设置地图点击事件监听器（GeoJSON + SymbolLayer 模式）
    this.setupMapClickListener();

    // 监听 style 加载事件，自动重新初始化 marker layer
    this.setupStyleLoadedListener();

  }

  /**
   * 监听 style 加载事件
   *
   * 当 style 被重新加载时，之前创建的 layer 和 source 会丢失，
   * 需要重新初始化 MarkerLayerManager 并恢复所有 markers
   */
  private setupStyleLoadedListener(): void {
    const manager = this;

    class StyleLoadedListenerImpl implements OnStyleLoadedListener {
      onStyleLoaded(style: Style | null): void {
        console.warn('[MarkerManager] ⚠️ Style reloaded, reinitializing MarkerLayerManager...');

        // 重新初始化 MarkerLayerManager
        manager.markerLayerManager.initialize();

        // 重新添加所有 markers
        if (manager.markerMap.size > 0) {

          // 获取所有 markers（显式类型）
          const markersToRestore = Array.from<Marker>(manager.markerMap.values());

          // 重新添加到 layer
          for (const marker of markersToRestore) {
            manager.markerLayerManager.addMarker(marker, true); // skipUpdate=true
          }

          // 统一更新 source
          manager.markerLayerManager.updateSource();

        }
      }
    }

    this.mapLibreMap.addOnStyleLoadedListener(new StyleLoadedListenerImpl());
  }

  /**
   * 设置地图点击事件监听器（GeoJSON + SymbolLayer 模式）
   *
   * 在 GeoJSON + SymbolLayer 模式下，Marker 不再是独立的对象，
   * 需要通过地图点击事件 + queryRenderedFeatures 来检测点击的 Marker
   *
   * 参考：
   * - Android: DraggableSymbolsManager (AndroidGesturesManager + MoveGestureDetector)
   * - iOS: UILongPressGestureRecognizer + UIPanGestureRecognizer
   */
  private setupMapClickListener(): void {

    // 点击事件
    class MapClickListenerImpl implements OnMapClickListener {
      manager: MarkerManager;

      constructor(manager: MarkerManager) {
        this.manager = manager;
      }

      onMapClick(x: number, y: number): boolean {
        return this.manager.handleMapClick(x, y);
      }
    }

    this.mapLibreMap.addOnMapClickListener(new MapClickListenerImpl(this));

    // 长按事件（用于拖拽开始）
    class MapLongClickListenerImpl implements OnMapLongClickListener {
      manager: MarkerManager;

      constructor(manager: MarkerManager) {
        this.manager = manager;
      }

      onMapLongClick(x: number, y: number): boolean {
        return this.manager.handleMapLongClick(x, y);
      }
    }

    this.mapLibreMap.addOnMapLongClickListener(new MapLongClickListenerImpl(this));

    // 触摸移动事件（用于拖拽过程）- 参考 Android MoveGestureDetector.onMove
    class TouchMoveListenerImpl implements OnTouchMoveListener {
      manager: MarkerManager;

      constructor(manager: MarkerManager) {
        this.manager = manager;
      }

      onTouchMove(x: number, y: number): boolean {
        return this.manager.handleTouchMove(x, y);
      }
    }

    this.mapLibreMap.addOnTouchMoveListener(new TouchMoveListenerImpl(this));

    // 触摸释放事件（用于拖拽结束）- 参考 Android MoveGestureDetector.onMoveEnd + iOS UIGestureRecognizerStateEnded
    class TouchUpListenerImpl implements OnTouchUpListener {
      manager: MarkerManager;

      constructor(manager: MarkerManager) {
        this.manager = manager;
      }

      onTouchUp(x: number, y: number): boolean {
        return this.manager.handleTouchUp(x, y);
      }
    }

    this.mapLibreMap.addOnTouchUpListener(new TouchUpListenerImpl(this));

  }

  /**
   * 处理地图点击事件
   *
   * 参考 Android AnnotationManager.onTap() 实现
   *
   * @param x 屏幕 X 坐标（逻辑像素）
   * @param y 屏幕 Y 坐标（逻辑像素）
   * @returns true 如果事件被消费
   */
  private handleMapClick(x: number, y: number): boolean {
    try {
      console.info(`[MarkerManager] handleMapClick at (${x}, ${y})`);
      
      // 查询点击位置的 Marker（坐标转换在 queryRenderedFeaturesForBox 中统一处理）
      const marker = this.queryMarkerAtPoint(x, y);

      if (marker) {
        console.info(`[MarkerManager] Found marker at click position: ${marker.getTitle()}`);
        // 触发 Marker 点击事件
        return this.handleMarkerClick(marker);
      }

      console.info(`[MarkerManager] No marker found at click position`);
      return false; // 没有点击到 Marker，事件未消费
    } catch (error) {
      console.error(`[MarkerManager] Error handling map click: ${error}`);
      return false;
    }
  }

  /**
   * 查询指定点位置的 Marker（通过 GeoJSON layer）
   *
   * 注意：MarkerManager 使用 GeoJSON + SymbolLayer 模式实现 Marker，
   * 因此需要使用 queryRenderedFeatures 查询 GeoJSON Feature，
   * 而不是 queryPointAnnotations（仅适用于原生注解系统）
   *
   * 坐标转换在 queryRenderedFeaturesForBox 中统一处理
   *
   * 参考 Android AnnotationManager.getMarkerHitFromTouchArea + MarkerHitResolver
   *
   * @param x 屏幕 X 坐标（逻辑像素）
   * @param y 屏幕 Y 坐标（逻辑像素）
   * @returns 找到的 Marker，如果没有则返回 null
   */
  private queryMarkerAtPoint(x: number, y: number): Marker | null {
    // 🎯 参考 Android AnnotationManager.getMarkerHitFromTouchArea:
    // 使用图标最大尺寸的 1.5 倍作为触摸区域
    // Android 代码:
    //   int touchSurfaceWidth = (int) (iconManager.getHighestIconHeight() * 1.5);
    //   int touchSurfaceHeight = (int) (iconManager.getHighestIconWidth() * 1.5);

    // 默认触摸区域（逻辑像素） - 参考 Android minimalTouchSize = 32dp
    const DEFAULT_TOUCH_SIZE = 48;
    let touchWidth = DEFAULT_TOUCH_SIZE;
    let touchHeight = DEFAULT_TOUCH_SIZE;

    // 使用图标最大尺寸计算自适应触摸区域
    const iconWidthPhysical = this.iconManager.getHighestIconWidth();   // 物理像素
    const iconHeightPhysical = this.iconManager.getHighestIconHeight(); // 物理像素

    if (iconWidthPhysical > 0 || iconHeightPhysical > 0) {
      // 转换为逻辑像素（触摸区域计算需要使用逻辑像素）
      const pixelRatio = this.mapLibreMap.getNativeMapView().getPixelRatio();
      const iconWidthLogical = iconWidthPhysical / pixelRatio;
      const iconHeightLogical = iconHeightPhysical / pixelRatio;
      
      // 注意：Android 中 width 和 height 交换了，因为 marker 通常是竖直的
      touchWidth = Math.max(iconHeightLogical * 1.5, DEFAULT_TOUCH_SIZE);
      touchHeight = Math.max(iconWidthLogical * 1.5, DEFAULT_TOUCH_SIZE);
    }

    // 构建查询矩形（逻辑像素，queryRenderedFeaturesForBox 会处理 DPI 转换）
    const left = x - touchWidth;
    const top = y - touchHeight;
    const right = x + touchWidth;
    const bottom = y + touchHeight;

    // 使用 queryRenderedFeaturesForBox 查询 GeoJSON layer 中的 Marker Feature
    // 坐标转换在 queryRenderedFeaturesForBox 中统一处理
    const features = this.mapLibreMap.queryRenderedFeaturesForBox(
      left, top, right, bottom,
      [this.markerLayerManager.getLayerId()],
      undefined
    );

    console.info(`[MarkerManager] queryMarkerAtPoint - features found: ${features ? features.length : 0}`);
    if (features && features.length > 0) {
      console.info(`[MarkerManager] Feature IDs: ${features.map(f => f.id).join(', ')}`);
      console.info(`[MarkerManager] MarkerMap has ${this.markerMap.size} markers`);
    }

    if (!features || features.length === 0) {
      return null;
    }

    // 如果只有一个 Feature，直接返回对应的 Marker
    if (features.length === 1) {
      const featureId = features[0].id;
      console.info(`[MarkerManager] Single feature - ID: ${featureId}, type: ${typeof featureId}`);
      if (typeof featureId === 'number' && this.markerMap.has(featureId)) {
        const marker = this.markerMap.get(featureId)!;
        console.info(`[MarkerManager] Found marker: ${marker.getTitle()}`);
        return marker;
      }
      console.warn(`[MarkerManager] Feature ID ${featureId} not found in markerMap`);
      return null;
    }

    // 多个 Feature 时，使用命中测试找到最接近点击点的 Marker
    // 参考 Android MarkerHitResolver.execute()
    const candidateIds: number[] = [];
    for (const feature of features) {
      const featureId = feature.id;
      console.info(`[MarkerManager] Checking feature ID: ${featureId}, type: ${typeof featureId}`);
      if (typeof featureId === 'number' && this.markerMap.has(featureId)) {
        candidateIds.push(featureId);
        console.info(`[MarkerManager] Added candidate ID: ${featureId}`);
      } else {
        console.warn(`[MarkerManager] Feature ID ${featureId} not in markerMap or wrong type`);
      }
    }

    console.info(`[MarkerManager] Candidate markers: ${candidateIds.length}`);
    if (candidateIds.length === 0) {
      console.warn(`[MarkerManager] No candidate markers found from ${features.length} features`);
      return null;
    }

    return this.resolveMarkerHit(x, y, candidateIds);
  }

  /**
   * 解析多个 Marker 的命中测试，找到最接近点击点的 Marker
   *
   * 参考 Android MarkerHitResolver 实现
   *
   * @param x 屏幕 X 坐标（逻辑像素）
   * @param y 屏幕 Y 坐标（逻辑像素）
   * @param markerIds 候选 Marker ID 数组
   * @returns 最接近点击点的 Marker，如果没有则返回 null
   */
  private resolveMarkerHit(x: number, y: number, markerIds: number[]): Marker | null {
    console.info(`[MarkerManager] resolveMarkerHit called with ${markerIds.length} candidates at logical (${x}, ${y})`);
    
    let closestMarker: Marker | null = null;
    let maxIntersectionArea = 0;

    // 逻辑像素转换为物理像素（DPI 转换在 PixelCoordinate 中统一处理）
    // pixelForLatLng 返回物理像素，需要统一坐标系统进行比较
    const pixelRatio = this.mapLibreMap.getNativeMapView().getPixelRatio();
    const physicalPoint = PixelCoordinate.fromLogicalPixels(x, y, pixelRatio);
    console.info(`[MarkerManager] Click point - logical: (${x}, ${y}), physical: (${physicalPoint.x}, ${physicalPoint.y}), pixelRatio: ${pixelRatio}`);

    for (const markerId of markerIds) {
      const marker = this.markerMap.get(markerId);
      if (!marker) {
        console.warn(`[MarkerManager] Marker ID ${markerId} not found in markerMap`);
        continue;
      }

      // 获取 Marker 的屏幕位置（物理像素，用于点击检测）
      const position = marker.getPosition();
      const screenPoint = this.mapLibreMap.pixelForLatLngPhysical(position.latitude, position.longitude);
      console.info(`[MarkerManager] Marker ${markerId} ("${marker.getTitle()}") - geo: (${position.latitude}, ${position.longitude}), physical screen: (${screenPoint.x}, ${screenPoint.y})`);

      // 获取图标尺寸
      const icon = this.markerIconMap.get(markerId);
      if (!icon) {
        console.warn(`[MarkerManager] Icon not found for marker ID ${markerId}`);
        continue;
      }


      let bitmapWidth = icon.getWidth();
      let bitmapHeight = icon.getHeight()
      console.info(`[MarkerManager] Marker ${markerId} - original icon size (physical): ${bitmapWidth}x${bitmapHeight}`);

      // 参考 Android: 最小触摸尺寸 32dp
      const minimalTouchSize = 48;
      if (bitmapHeight < minimalTouchSize) {
        bitmapHeight = minimalTouchSize;
      }
      if (bitmapWidth < minimalTouchSize) {
        bitmapWidth = minimalTouchSize;
      }
      console.info(`[MarkerManager] Marker ${markerId} - adjusted touch size (physical): ${bitmapWidth}x${bitmapHeight}`);

      // 获取 Marker 的锚点（默认是底部中心：0.5, 1.0）
      // 参考 Android: MarkerView 默认锚点是 (0.5f, 1.0f)
      // anchorU: 水平锚点 (0=左, 0.5=中, 1=右)
      // anchorV: 垂直锚点 (0=上, 0.5=中, 1=下)
      const anchor: MarkerAnchor = marker.getAnchor();
      const anchorU: number = anchor ? anchor.u : 0.5;
      const anchorV: number = anchor ? anchor.v : 1.0;
      console.info(`[MarkerManager] Marker ${markerId} - anchor: (${anchorU}, ${anchorV})`);

      // 构建 Marker 的矩形区域（基于锚点计算）
      // screenPoint 是锚点在屏幕上的位置
      const markerLeft = screenPoint.x - bitmapWidth * anchorU;
      const markerTop = screenPoint.y - bitmapHeight * anchorV;
      const markerRight = markerLeft + bitmapWidth;
      const markerBottom = markerTop + bitmapHeight;
      console.info(`[MarkerManager] Marker ${markerId} - hit rect (physical): [${markerLeft}, ${markerTop}, ${markerRight}, ${markerBottom}]`);

      // 检查点击点是否在 Marker 矩形内（使用物理像素进行比较）
      const isInside = physicalPoint.x >= markerLeft && physicalPoint.x <= markerRight &&
        physicalPoint.y >= markerTop && physicalPoint.y <= markerBottom;
      console.info(`[MarkerManager] Marker ${markerId} - click point (${physicalPoint.x}, ${physicalPoint.y}) isInside: ${isInside}`);
      
      if (isInside) {
        // 计算交集面积（这里简化为 Marker 矩形面积）
        const intersectionArea = bitmapWidth * bitmapHeight;
        console.info(`[MarkerManager] Marker ${markerId} - intersection area: ${intersectionArea}, current max: ${maxIntersectionArea}`);

        // 选择交集面积最大的 Marker（最接近点击点）
        if (intersectionArea > maxIntersectionArea) {
          maxIntersectionArea = intersectionArea;
          closestMarker = marker;
          console.info(`[MarkerManager] Marker ${markerId} ("${marker.getTitle()}") is now the closest marker`);
        }
      }
    }

    if (closestMarker) {
      console.info(`[MarkerManager] resolveMarkerHit result: "${closestMarker.getTitle()}"`);
    } else {
      console.warn(`[MarkerManager] resolveMarkerHit result: null (no marker hit)`);
    }

    return closestMarker;
  }

  /**
   * 尝试开始拖拽 Marker（在 Pan 手势开始时调用）
   *
   * @param x 屏幕 X 坐标（逻辑像素）
   * @param y 屏幕 Y 坐标（逻辑像素）
   * @returns true 如果有可拖拽的 Marker 并开始拖拽
   */
  public tryStartDrag(x: number, y: number): boolean {
    try {
      // 查询当前位置的 Marker（坐标转换在 queryRenderedFeaturesForBox 中统一处理）
      const marker = this.queryMarkerAtPoint(x, y);

      if (!marker || !marker.getDraggable()) {
        return false;
      }

      console.info(`[MarkerManager] 🎯 Drag START: marker id=${marker.getId()}`);

      // 开始拖拽
      this.draggingMarker = marker;
      this.draggingMarkerId = marker.getId();
      this.handleDragStart(marker);

      return true; // 事件被消费
    } catch (error) {
      console.error(`[MarkerManager] Error starting drag: ${error}`);
      return false;
    }
  }

  /**
   * 处理地图长按事件（触发 Marker 长按回调）
   *
   * @param x 屏幕 X 坐标（逻辑像素）
   * @param y 屏幕 Y 坐标（逻辑像素）
   * @returns true 如果事件被消费
   */
  private handleMapLongClick(x: number, y: number): boolean {
    try {
      // 查询长按位置的 Marker
      const marker = this.queryMarkerAtPoint(x, y);

      if (!marker) {
        return false;
      }

      // 触发 Marker 长按回调
      if (this.onMarkerLongClickListener) {
        return this.onMarkerLongClickListener.onMarkerLongClick(marker);
      }

      return false;
    } catch (error) {
      console.error(`[MarkerManager] Error handling long click: ${error}`);
      return false;
    }
  }

  /**
   * 处理触摸移动事件（拖拽过程）
   *
   * 参考 Android MoveGestureDetector.OnMoveGestureListener.onMove
   *
   * @param x 触摸位置 X 坐标（逻辑像素）
   * @param y 触摸位置 Y 坐标（逻辑像素）
   * @returns true 如果事件被消费
   */
  private handleTouchMove(x: number, y: number): boolean {
    // 只有在拖拽过程中才处理触摸移动
    if (!this.draggingMarker || !this.draggingMarkerId) {
      return false;
    }

    try {
      // 逻辑像素转换为物理像素（DPI 转换在 PixelCoordinate 中统一处理）
      const pixelRatio = this.mapLibreMap.getNativeMapView().getPixelRatio();
      const screenPoint = PixelCoordinate.fromLogicalPixels(x, y, pixelRatio);

      // 屏幕坐标转换为地理坐标
      const latLng: LatLng = this.mapLibreMap.getProjection().screenLocationToLatLng(screenPoint);

      // 更新 Marker 位置
      this.handleDrag(this.draggingMarker, latLng);

      // 更新 GeoJSON Source（实时更新 Marker 显示位置）
      this.markerLayerManager.updateMarker(this.draggingMarker);

      return true; // 事件被消费
    } catch (error) {
      console.error(`[MarkerManager] Error handling touch move: ${error}`);
      return false;
    }
  }

  /**
   * 处理触摸释放事件（拖拽结束）
   *
   * 参考：
   * - Android: MoveGestureDetector.OnMoveGestureListener.onMoveEnd
   * - iOS: UIPanGestureRecognizer UIGestureRecognizerStateEnded
   *
   * @param x 触摸释放位置 X 坐标
   * @param y 触摸释放位置 Y 坐标
   * @returns true 如果事件被消费
   */
  private handleTouchUp(x: number, y: number): boolean {
    // 只有在拖拽过程中才处理触摸释放
    if (!this.draggingMarker || !this.draggingMarkerId) {
      return false;
    }

    try {
      // 结束拖拽
      this.handleDragEnd(this.draggingMarker);

      // 清除拖拽状态
      this.draggingMarker = null;
      this.draggingMarkerId = null;

      return true; // 事件被消费
    } catch (error) {
      console.error(`[MarkerManager] Error handling touch up: ${error}`);

      // 清除拖拽状态
      this.draggingMarker = null;
      this.draggingMarkerId = null;

      return false;
    }
  }

  // ========== Marker 管理 ==========

  /**
   * 添加单个 Marker
   *
   * @param options MarkerOptions 实例
   * @returns Promise<Marker> 创建的 Marker
   * @throws Error 如果 Marker 创建失败
   */
  public async addMarker(options: MarkerOptions): Promise<Marker> {
    try {
      // 确保 MarkerLayerManager 已初始化
      if (!this.markerLayerManager.isInitialized()) {
        this.markerLayerManager.initialize();
      }

      // 获取Icon对象（优先使用复用标识符）
      let icon: Icon | undefined = options.getIcon();
      const reuseIdentifier = options.getReuseIdentifier();

      if (!icon && reuseIdentifier) {
        // 尝试从复用队列获取图标
        const reusedIcon = this.iconManager.dequeueReusableIcon(reuseIdentifier);
        if (reusedIcon) {
          icon = reusedIcon;
        }
      }

      if (!icon) {
        // 如果没有设置图标，加载默认图标
        if (!this.iconManager.iconFactory) {
          throw new Error('[MarkerManager] IconFactory is not initialized');
        }
        icon = await this.iconManager.iconFactory.defaultMarker();
        options.icon(icon);
      }

      // 创建 Marker 对象（getMarker()会将icon.getId()传给NAPI层）
      const marker = options.getMarker();

      // 添加Icon到IconManager（marker已经设置了iconId）
      await this.iconManager.addIconToManager(icon);

      // 添加到 MarkerLayerManager
      const featureId = this.markerLayerManager.addMarker(marker);

      // 设置 ID 和关联
      marker.setId(featureId);
      marker.setMapLibreMap(this.mapLibreMap);
      this.markerMap.set(featureId, marker);

      // 保存Marker -> Icon映射（因为NAPI Marker只存储iconId字符串）
      this.markerIconMap.set(featureId, icon);

      // 保存 InfoWindow 样式配置
      const infoWindowStyle = options.getInfoWindowStyle();
      if (infoWindowStyle) {
        this.markerInfoWindowStyleMap.set(featureId, infoWindowStyle);
      }

      // 创建自定义视图（如果有适配器）
      this.annotationViewManager.createOrUpdateView(marker);

      return marker;
    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to add marker: ${error.message}`);
      throw new Error(`Failed to add marker: ${error.message}`);
    }
  }

  /**
   * 批量添加 Marker
   *
   * @param optionsList MarkerOptions 数组
   * @returns Promise<Marker[]> 创建的 Marker 数组
   * @throws Error 如果批量添加失败
   */
  public async addMarkers(optionsList: MarkerOptions[]): Promise<Marker[]> {
    try {
      // 确保 MarkerLayerManager 已初始化
      if (!this.markerLayerManager.isInitialized()) {
        this.markerLayerManager.initialize();
      }

      // 创建 Marker 对象数组，同时加载icons
      const markers: Marker[] = [];
      const icons: Icon[] = [];

      for (const options of optionsList) {
        // 获取Icon对象（从MarkerOptions）
        let icon = options.getIcon();
        if (!icon) {
          if (!this.iconManager.iconFactory) {
            throw new Error('[MarkerManager] IconFactory is not initialized');
          }
          icon = await this.iconManager.iconFactory.defaultMarker();
          options.icon(icon);
        }

        icons.push(icon);

        const marker = options.getMarker();

        // 添加Icon到IconManager（marker已经设置了iconId）
        await this.iconManager.addIconToManager(icon);

        markers.push(marker);
      }

      // 批量添加到 MarkerLayerManager
      const featureIds = this.markerLayerManager.addMarkers(markers);

      // 设置 ID 并注册
      for (let i = 0; i < markers.length; i++) {
        const marker = markers[i];
        const featureId = featureIds[i];
        const icon = icons[i];
        const options = optionsList[i];

        marker.setId(featureId);
        marker.setMapLibreMap(this.mapLibreMap);
        this.markerMap.set(featureId, marker);

        // 保存Marker -> Icon映射
        this.markerIconMap.set(featureId, icon);

        // 保存 InfoWindow 样式配置
        const infoWindowStyle = options.getInfoWindowStyle();
        if (infoWindowStyle) {
          this.markerInfoWindowStyleMap.set(featureId, infoWindowStyle);
        }
      }

      return markers;
    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to add markers batch: ${error.message}`);
      throw new Error(`Failed to add markers batch: ${error.message}`);
    }
  }

  /**
   * 移除单个 Marker
   *
   * @param marker 要移除的 Marker
   */
  public removeMarker(marker: Marker): void {
    const id = marker.getId();
    if (id === -1) {
      return;
    }

    // 如果正在显示 InfoWindow，先关闭
    if (marker.isInfoWindowShown()) {
      marker.hideInfoWindow();
    }

    // 如果是选中状态，取消选中
    if (marker.isSelected()) {
      this.deselectMarker(marker);
    }

    // 清理 Icon（减少引用计数）
    // 由于NAPI Marker不持有Icon对象，从markerIconMap获取
    const icon = this.markerIconMap.get(id);
    if (icon) {
      this.iconManager.iconCleanup(icon);
      this.markerIconMap.delete(id);
    }

    // 移除 InfoWindow 样式配置
    this.markerInfoWindowStyleMap.delete(id);

    // 移除自定义视图
    this.annotationViewManager.removeView(marker);

    // 从 MarkerLayerManager 移除
    this.markerLayerManager.removeMarker(id);

    // 从管理器移除
    this.markerMap.delete(id);
    marker.setId(-1);

  }

  /**
   * 批量移除 Marker
   *
   * @param markers 要移除的 Marker 数组
   */
  public removeMarkers(markers: Marker[]): void {
    const ids: number[] = [];

    for (const marker of markers) {
      const id = marker.getId();
      if (id !== -1) {
        // 清理状态
        if (marker.isInfoWindowShown()) {
          marker.hideInfoWindow();
        }
        if (marker.isSelected()) {
          this.selectedMarkers.delete(marker);
        }

        // 清理 Icon
        const icon = this.markerIconMap.get(id);
        if (icon) {
          this.iconManager.iconCleanup(icon);
          this.markerIconMap.delete(id);
        }

        // 移除自定义视图
        this.annotationViewManager.removeView(marker);

        ids.push(id);
        this.markerMap.delete(id);
        marker.setId(-1);
      }
    }

    // 批量从 MarkerLayerManager 移除
    if (ids.length > 0) {
      this.markerLayerManager.removeMarkers(ids);
    }

  }

  /**
   * 更新 Marker
   *
   * 更新 Marker 的所有属性到地图显示（位置、图标、透明度、旋转等）
   *
   * @param marker 要更新的 Marker
   */
  public updateMarker(marker: Marker): void {
    try {
      const markerId = marker.getId();
      if (markerId < 0 || !this.markerMap.has(markerId)) {
        console.warn(`[MarkerManager] updateMarker: Marker ${markerId} not found in manager`);
        return;
      }

      // 更新 MarkerLayerManager 中的特征（更新 GeoJSON）
      this.markerLayerManager.updateMarkerById(markerId, marker);

    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to update marker: ${error.message}`);
    }
  }

  /**
   * 更新 Marker 的图标
   *
   * 自动处理旧图标的引用计数和新图标的加载
   *
   * @param marker 要更新的 Marker
   * @param newIcon 新的 Icon 实例
   */
  public async updateMarkerIcon(marker: Marker, newIcon: Icon): Promise<void> {
    try {
      const markerId = marker.getId();
      if (markerId < 0 || !this.markerMap.has(markerId)) {
        throw new Error('Marker not found in manager');
      }

      // 获取旧图标
      const oldIcon = this.markerIconMap.get(markerId) || null;

      // 使用 IconManager 更新图标（自动处理引用计数）
      await this.iconManager.updateMarkerIcon(marker, oldIcon, newIcon);

      // 更新本地映射
      this.markerIconMap.set(markerId, newIcon);

      // 更新 MarkerLayerManager 中的特征
      this.markerLayerManager.updateMarkerById(markerId, marker);

      // 更新自定义视图
      this.annotationViewManager.createOrUpdateView(marker);

    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to update marker icon: ${error.message}`);
      throw new Error(`Failed to update marker icon: ${error.message}`);
    }
  }

  /**
   * 清除所有 Marker
   *
   * 移除地图上所有的 Marker 并释放相关资源。
   *
   * **重要提示**：
   * - 此方法会减少所有 Icon 的引用计数
   * - 当 Icon 的引用计数降为 0 时，Icon 会被自动释放（PixelMap 资源被回收）
   * - **已释放的 Icon 不能被复用**
   * - 清除后如需再次添加相同图标的 Marker，必须创建新的 Icon 实例
   *
   * @example
  * ```typescript
   * // 清除所有 marker
   * markerManager.clear();
   *
   * // 错误用法：复用旧的 Icon
   * const oldIcon = marker.getIcon();
   * const newMarker = new MarkerOptions().position(latLng).icon(oldIcon); // ❌ 错误！
   *
   * // 正确用法：创建新的 Icon
   * const factory = IconFactory.getInstance();
   * const newIcon = await factory.fromResource($r('app.media.marker')); // ✓ 正确
   * const newMarker = new MarkerOptions().position(latLng).icon(newIcon);
   * ```
   */
  public clear(): void {
    // 清理每个marker
    for (const marker of this.markerMap.values()) {
      if (marker.isInfoWindowShown()) {
        marker.hideInfoWindow();
      }

      // Icon cleanup
      // 从markerIconMap获取Icon对象（因为NAPI Marker不持有Icon引用）
      const icon = this.markerIconMap.get(marker.getId());
      if (icon) {
        // iconCleanup使用Icon对象作为key，多个markers共享同一Icon时正确处理
        this.iconManager.iconCleanup(icon);
      }

      marker.setId(-1);
    }

    // 清空 MarkerLayerManager
    this.markerLayerManager.clearMarkers();

    // 清空本地映射
    this.markerMap.clear();
    this.markerIconMap.clear();
    this.selectedMarkers.clear();

  }

  /**
   * 清除所有监听器
   * 
   * 移除所有 Marker 相关的事件监听器，防止内存泄漏
   */
  public clearAllListeners(): void {
    this.onMarkerClickListener = null;
    this.onMarkerLongClickListener = null;
    this.onMarkerDragListener = null;
    this.onInfoWindowClickListener = null;
    this.onMarkerSelectListener = null;
    this.infoWindowAdapter = null;
  }

  // ========== 选中管理 ==========

  /**
   * 选中 Marker
   *
   * @param marker 要选中的 Marker
   * @param showInfoWindow 是否显示 InfoWindow
   */
  public selectMarker(marker: Marker, showInfoWindow: boolean = true): void {
    // 先取消其他选中的 Marker
    this.deselectMarkers();

    // 选中当前 Marker
    marker.setSelected(true);
    this.selectedMarkers.add(marker);

    // 触发选中监听器
    if (this.onMarkerSelectListener) {
      this.onMarkerSelectListener.onMarkerSelect(marker);
    }

    // 显示 InfoWindow
    const title = marker.getTitle();
    const snippet = marker.getSnippet();
    console.info(`[MarkerManager] selectMarker - title: "${title}", snippet: "${snippet}", showInfoWindow: ${showInfoWindow}`);

    if (showInfoWindow && (title || snippet)) {
      console.info(`[MarkerManager] Showing InfoWindow for marker with title: "${title}"`);
      marker.showInfoWindow();
    } else {
      console.warn(`[MarkerManager] InfoWindow not shown - showInfoWindow: ${showInfoWindow}, hasTitle: ${!!title}, hasSnippet: ${!!snippet}`);
    }
  }

  /**
   * 取消选中 Marker
   *
   * @param marker 要取消选中的 Marker
   */
  public deselectMarker(marker: Marker): void {
    if (!this.selectedMarkers.has(marker)) {
      return;
    }

    marker.setSelected(false);
    marker.hideInfoWindow();
    this.selectedMarkers.delete(marker);

    // 触发取消选中监听器
    if (this.onMarkerSelectListener) {
      this.onMarkerSelectListener.onMarkerDeselect(marker);
    }
  }

  /**
   * 取消所有选中的 Marker
   */
  public deselectMarkers(): void {
    for (const marker of this.selectedMarkers) {
      marker.setSelected(false);
      marker.hideInfoWindow();

      // 触发取消选中监听器
      if (this.onMarkerSelectListener) {
        this.onMarkerSelectListener.onMarkerDeselect(marker);
      }
    }
    this.selectedMarkers.clear();
  }

  /**
   * 获取所有选中的 Marker
   *
   * @returns 选中的 Marker 数组
   */
  public getSelectedMarkers(): Marker[] {
    return Array.from(this.selectedMarkers);
  }

  // ========== 查询 ==========

  /**
   * 根据 ID 获取 Marker
   *
   * @param id Marker ID
   * @returns Marker 实例，如果不存在则返回 null
   */
  public getMarker(id: number): Marker | null {
    return this.markerMap.get(id) || null;
  }

  /**
   * 获取所有 Marker
   *
   * @returns Marker 数组
   */
  public getMarkers(): Marker[] {
    return Array.from(this.markerMap.values());
  }

  // ========== 拖拽处理 ==========

  /**
   * 处理拖拽开始
   *
   * @param marker 正在拖拽的 Marker
   */
  public handleDragStart(marker: Marker): void {
    if (!marker.getDraggable()) {
      return;
    }

    marker.setDragState(MarkerDragState.Starting);
    this.draggingMarker = marker;

    // 触发事件
    if (this.onMarkerDragListener) {
      this.onMarkerDragListener.onMarkerDragStart(marker);
    }

    marker.setDragState(MarkerDragState.Dragging);
  }

  /**
   * 处理拖拽中
   *
   * @param marker 正在拖拽的 Marker
   * @param newPosition 新位置
   */
  public handleDrag(marker: Marker, newPosition: LatLng): void {
    if (!marker.getDraggable() || marker.getDragState() !== MarkerDragState.Dragging) {
      return;
    }

    // 更新位置
    marker.setPosition(newPosition);

    // 触发事件
    if (this.onMarkerDragListener) {
      this.onMarkerDragListener.onMarkerDrag(marker);
    }
  }

  /**
   * 处理拖拽结束
   *
   * @param marker 完成拖拽的 Marker
   */
  public handleDragEnd(marker: Marker): void {
    if (!marker.getDraggable() || this.draggingMarker !== marker) {
      return;
    }

    marker.setDragState(MarkerDragState.Ending);

    // 触发事件
    if (this.onMarkerDragListener) {
      this.onMarkerDragListener.onMarkerDragEnd(marker);
    }

    marker.setDragState(MarkerDragState.None);
    this.draggingMarker = null;
  }

  /**
   * 获取正在拖拽的 Marker
   *
   * @returns 正在拖拽的 Marker，如果没有则返回 null
   */
  public getDraggingMarker(): Marker | null {
    return this.draggingMarker;
  }

  // ========== 点击处理 ==========

  /**
   * 处理 Marker 点击事件
   *
   * @param marker 被点击的 Marker
   * @returns true 如果事件被消费
   */
  public handleMarkerClick(marker: Marker): boolean {

    // 触发点击事件
    if (this.onMarkerClickListener) {
      try {
        const consumed = this.onMarkerClickListener.onMarkerClick(marker);
        if (consumed) {
          return true;
        }
      } catch (error) {
        console.error(`[MarkerManager] ❌ Error in onMarkerClickListener: ${error}`);
      }
    } else {
      console.warn(`[MarkerManager] ⚠️ No onMarkerClickListener set`);
    }

    // 默认行为：选中 Marker 并显示 InfoWindow
    this.selectMarker(marker, true);
    return false;
  }

  /**
   * 处理 InfoWindow 点击事件
   *
   * @param marker InfoWindow 所属的 Marker
   */
  public handleInfoWindowClick(marker: Marker): void {
    if (this.onInfoWindowClickListener) {
      this.onInfoWindowClickListener.onInfoWindowClick(marker);
    }
  }

  // ========== 事件监听器设置 ==========

  /**
   * 设置 Marker 点击监听器
   *
   * @param listener 监听器实例
   */
  public setOnMarkerClickListener(listener: OnMarkerClickListener | null): void {
    this.onMarkerClickListener = listener;
  }

  /**
   * 设置 Marker 长按监听器
   *
   * @param listener 监听器实例
   */
  public setOnMarkerLongClickListener(listener: OnMarkerLongClickListener | null): void {
    this.onMarkerLongClickListener = listener;
  }

  /**
   * 设置 Marker 拖拽监听器
   *
   * @param listener 监听器实例
   */
  public setOnMarkerDragListener(listener: OnMarkerDragListener | null): void {
    this.onMarkerDragListener = listener;
  }

  /**
   * 设置 Marker 选中监听器
   *
   * @param listener 监听器实例
   */
  public setOnMarkerSelectListener(listener: OnMarkerSelectListener | null): void {
    this.onMarkerSelectListener = listener;
  }

  /**
   * 获取 Marker 选中监听器
   *
   * @returns 监听器实例
   */
  public getOnMarkerSelectListener(): OnMarkerSelectListener | null {
    return this.onMarkerSelectListener;
  }

  /**
   * 设置 InfoWindow 点击监听器
   *
   * @param listener 监听器实例
   */
  public setOnInfoWindowClickListener(listener: OnInfoWindowClickListener | null): void {
    this.onInfoWindowClickListener = listener;
    this.infoWindowManager.setOnClickListener(listener);
  }

  /**
   * 设置 InfoWindow 关闭监听器
   *
   * @param listener 监听器实例
   */
  public setOnInfoWindowCloseListener(listener: OnInfoWindowCloseListener | null): void {
    this.infoWindowManager.setOnCloseListener(listener);
  }

  /**
   * 获取 InfoWindow 关闭监听器
   *
   * @returns 监听器实例
   */
  public getOnInfoWindowCloseListener(): OnInfoWindowCloseListener | null {
    return this.infoWindowManager.getOnCloseListener();
  }

  /**
   * 设置 InfoWindow 适配器
   *
   * @param adapter 适配器实例
   */
  public setInfoWindowAdapter(adapter: InfoWindowAdapter | null): void {
    this.infoWindowAdapter = adapter;
    this.infoWindowManager.setAdapter(adapter);
  }

  /**
   * 获取 InfoWindow 适配器
   *
   * @returns 适配器实例
   */
  public getInfoWindowAdapter(): InfoWindowAdapter | null {
    return this.infoWindowAdapter;
  }

  /**
   * 设置 AnnotationView 适配器
   *
   * @param adapter 适配器实例
   */
  public setAnnotationViewAdapter(adapter: AnnotationViewAdapter | null): void {
    this.annotationViewManager.setAdapter(adapter);
  }

  /**
   * 获取 AnnotationView 适配器
   *
   * @returns 适配器实例
   */
  public getAnnotationViewAdapter(): AnnotationViewAdapter | null {
    return this.annotationViewManager.getAdapter();
  }

  /**
   * 获取 AnnotationViewManager 实例（供 UI 层使用）
   */
  public getAnnotationViewManager(): AnnotationViewManager {
    return this.annotationViewManager;
  }

  /**
   * 设置 Native MapView（用于坐标转换）
   */
  public setNativeMapView(mapView: object): void {
    this.annotationViewManager.setNativeMapView(mapView as NativeMapView);
  }

  /**
   * 获取 InfoWindowManager 实例（供 UI 层使用）
   */
  public getInfoWindowManager(): InfoWindowManager {
    return this.infoWindowManager;
  }

  /**
   * 获取 Marker 的 InfoWindow 样式配置
   *
   * @param marker Marker 实例
   * @returns InfoWindowStyle 或 undefined
   */
  public getInfoWindowStyle(marker: Marker): InfoWindowStyle | undefined {
    const id = marker.getId();
    return this.markerInfoWindowStyleMap.get(id);
  }

  /**
   * 显示 Marker 的 InfoWindow
   */
  public showInfoWindow(marker: Marker): void {
    try {
      const title = marker.getTitle();
      const snippet = marker.getSnippet();
      console.info(`[MarkerManager] showInfoWindow called for marker - title: "${title}", snippet: "${snippet}"`);
      
      // 获取 Marker 屏幕坐标（逻辑像素，用于 ArkUI InfoWindow 组件定位）
      const pos = marker.getPosition();
      const screenPoint = this.mapLibreMap.pixelForLatLng(pos.latitude, pos.longitude);
      console.info(`[MarkerManager] Marker logical screen position: (${screenPoint.x}, ${screenPoint.y})`);

      // 获取 Marker 图标高度（用于计算 InfoWindow 偏移量）
      // 参考 Android InfoWindow.java 和 iOS positioningRectForCalloutForAnnotationWithTag
      const iconId = marker.getIcon();
      const iconHeightPhysical = this.iconManager.getIconHeight(iconId);
      const pixelRatio = this.mapLibreMap.getNativeMapView().getPixelRatio();
      // Icon 高度是物理像素，需要转换为逻辑像素
      const iconHeightLogical = iconHeightPhysical / pixelRatio;
      console.info(`[MarkerManager] Icon "${iconId}" height: ${iconHeightPhysical}px (physical) = ${iconHeightLogical}px (logical)`);

      // 获取视图尺寸
      const viewWidth: number = this.mapLibreMap.getViewWidth();
      const viewHeight: number = this.mapLibreMap.getViewHeight();
      console.info(`[MarkerManager] View dimensions: ${viewWidth}x${viewHeight}`);

      // 获取 InfoWindow 样式，并设置垂直偏移量（参考 Android/iOS 实现）
      let style = this.getInfoWindowStyle(marker);
      
      // 参考 Android InfoWindow.java:137-143:
      // markerHeightOffset = offsetY
      // y = coordinates.y - view.getMeasuredHeight() + offsetY
      // 
      // 参考 iOS MLNMapView.mm:5745-5792:
      // centerPoint = CGPointMake(CGRectGetMidX(positioningRect), CGRectGetMinY(positioningRect))
      // 即 InfoWindow 定位在 Marker 图标的顶部
      //
      // 因此 offsetY 应该设置为负的图标高度，将 InfoWindow 从地理坐标点向上偏移到图标顶部
      if (!style) {
        // 如果没有自定义样式，创建默认样式
        style = {};
      }
      if (style.offsetY === undefined && iconHeightLogical > 0) {
        style.offsetY = -iconHeightLogical;
        console.info(`[MarkerManager] Setting offsetY to -${iconHeightLogical} (negative icon height for top positioning)`);
      }

      // 显示 InfoWindow（使用逻辑像素坐标）
      console.info(`[MarkerManager] Calling InfoWindowManager.show() with offsetY: ${style.offsetY}`);
      this.infoWindowManager.show(marker, viewWidth, viewHeight, screenPoint, style);
      console.info(`[MarkerManager] InfoWindow shown successfully`);

    } catch (error) {
      console.error(`[MarkerManager] Failed to show InfoWindow: ${error.message}`);
    }
  }

  /**
   * 隐藏 Marker 的 InfoWindow
   */
  public hideInfoWindow(marker: Marker): void {
    this.infoWindowManager.close(marker);
  }

  /**
   * 隐藏所有 InfoWindow
   */
  public hideAllInfoWindows(): void {
    this.infoWindowManager.closeAll();
  }
}

