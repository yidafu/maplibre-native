import maplibre from 'libmaplibre.so';
import { AnnotationView, CenterOffset } from './AnnotationView';
import { AnnotationViewData } from './AnnotationViewManager';
import { LatLng } from '../geometry/LatLng';

import { Marker } from './Marker';

/**
 * AnnotationViewOverlay - AnnotationView 渲染层
 *
 * 作为覆盖层在地图上方渲染所有的 AnnotationView
 *
 * 参考:
 * - iOS: MLNMapView 的 annotationContainerView
 * - Android: 自定义 ViewGroup 覆盖层
 *
 * 特性：
 * - 支持自定义视图内容
 * - Z-index 排序（选中和拖拽的视图在最上层）
 * - 事件穿透（允许点击地图）
 * - 动画效果
 *
 * 使用方式：
 * ```typescript
 * Stack() {
 *   // 地图层
 *   XComponent(...)
 *
 *   // AnnotationView 层
 *   AnnotationViewOverlay({
 *     visibleAnnotationViews: $visibleAnnotationViews,
 *     mapBearing: this.mapBearing,
 *     mapPitch: this.mapPitch,
 *     onAnnotationSelect: (marker) => { ... }
 *   })
 * }
 * ```
 */
@Component
export struct AnnotationViewOverlay {
  @Link visibleAnnotationViews: AnnotationViewData[];
  // 地图状态（用于高级特性）
  @Prop mapBearing: number = 0;
  @Prop mapPitch: number = 0;
  @Prop screenWidth: number = 0;
  @Prop screenHeight: number = 0;
  // 事件回调
  onAnnotationSelect?: (marker: Marker) => void;
  onAnnotationDeselect?: (marker: Marker) => void;
  onAnnotationDragStart?: (marker: Marker) => void;
  onAnnotationDrag?: (marker: Marker, screenX: number, screenY: number) => void;
  onAnnotationDragEnd?: (marker: Marker, screenX: number, screenY: number) => void;
  // 自定义视图构建器工厂（由外部提供）
  customViewBuilderFactory?: (marker: Marker) => (() => void) | null;

  /**
   * 构建单个 AnnotationView
   *
   * 为每个 AnnotationViewData 创建对应的 AnnotationView 组件
   */
  @Builder
  buildAnnotationView(viewData: AnnotationViewData) {
    // 🔒 修复 ObservedObject 错误：检查 marker 是否为 null
    if (viewData.marker !== null) {
      AnnotationView({
        marker: viewData.marker,
        reuseIdentifier: viewData.reuseIdentifier,
        screenX: viewData.screenX,
        screenY: viewData.screenY,
        centerOffset: viewData.centerOffset,
        anchorU: viewData.anchorU,
        anchorV: viewData.anchorV,
        visible: viewData.visible,
        mapBearing: this.mapBearing,
        mapPitch: this.mapPitch,
        screenHeight: this.screenHeight,
        customContentBuilder: this.resolveCustomContentBuilder(viewData),
        isDraggable: viewData.draggable,
        scalesWithViewingDistance: viewData.scalesWithViewingDistance,
        rotatesToMatchCamera: viewData.rotatesToMatchCamera,
        isEnabled: viewData.enabled,
        selected: viewData.selected,
        viewAlpha: viewData.alpha,
        baseZIndex: viewData.zIndex,
        preferredWidth: viewData.preferredWidth,
        preferredHeight: viewData.preferredHeight,
        nativeScale: viewData.nativeScale ?? 1,
        nativeRotation: viewData.nativeRotation ?? 0,
        nativeOpacity: viewData.nativeOpacity ?? 1,
        reuseVersion: viewData.reuseVersion ?? 0,
        onSelect: (marker: Marker) => {
          if (this.onAnnotationSelect) {
            this.onAnnotationSelect(marker);
          }
        },
        onDeselect: (marker: Marker) => {
          if (this.onAnnotationDeselect) {
            this.onAnnotationDeselect(marker);
          }
        },
        onMarkerDragStart: (marker: Marker) => {
          if (this.onAnnotationDragStart) {
            this.onAnnotationDragStart(marker);
          }
        },
        onDrag: (marker: Marker, screenX: number, screenY: number) => {
          if (this.onAnnotationDrag) {
            this.onAnnotationDrag(marker, screenX, screenY);
          }
        },
        onMarkerDragEnd: (marker: Marker, screenX: number, screenY: number) => {
          if (this.onAnnotationDragEnd) {
            this.onAnnotationDragEnd(marker, screenX, screenY);
          }
        }
      })
    }
  }

  private resolveCustomContentBuilder(viewData: AnnotationViewData): (() => void) | undefined {
    if (viewData.customBuilder) {
      return viewData.customBuilder;
    }
    if (viewData.marker !== null && this.customViewBuilderFactory) {
      return this.customViewBuilderFactory(viewData.marker) ?? undefined;
    }
    return undefined;
  }

  /**
   * 排序 AnnotationView（Z-index 优化）
   *
   * 选中的和拖拽的视图应该在最上层
   *
   * @param viewDataArray 视图数据数组
   * @returns 排序后的数组
   */
  private sortAnnotationViews(viewDataArray: AnnotationViewData[]): AnnotationViewData[] {
    return viewDataArray.slice().sort((a, b) => {
      // 简单排序：后添加的在上方（默认行为）
      // ForEach 和 zIndex 会自动处理层级
      return 0;
    });
  }

  build() {
    Stack() {
        ForEach(
          this.visibleAnnotationViews,
          (viewData: AnnotationViewData) => {
            Stack() {
              this.buildAnnotationView(viewData)
            }
              .hitTestBehavior(HitTestMode.Transparent);
          },
          (viewData: AnnotationViewData) => {
            return `annotation-view-${viewData.marker?.getId() ?? 0}`;
          }
        )
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(this.visibleAnnotationViews.length > 0 ? HitTestMode.Transparent : HitTestMode.None)
  }
}

/**
 * 辅助函数：包装 Builder 以支持动态参数
 *
 * 用于将带参数的 Builder 包装成 AnnotationView 可以使用的形式
 *
 * @param builder Builder 函数
 * @param params 参数对象
 * @returns 包装后的无参 Builder 函数
 */
export function wrapBuilderWithParams<T>(builder: (params: T) => void, params: T): () => void {
  return () => {
    builder(params);
  };
}

