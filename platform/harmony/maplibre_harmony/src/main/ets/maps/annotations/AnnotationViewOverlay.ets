import maplibre from 'libmaplibre_native.so';
import { AnnotationView, CenterOffset } from './AnnotationView';
import { AnnotationViewData } from './AnnotationViewManager';
import { LatLng } from '../geometry/LatLng';

type Marker = maplibre.Marker;

/**
 * AnnotationViewOverlay - AnnotationView 渲染层
 * 
 * 作为覆盖层在地图上方渲染所有的 AnnotationView
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
 *     onAnnotationSelect: (marker) => { ... },
 *     onAnnotationDrag: (marker, x, y) => { ... }
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
  
  /**
   * 构建单个 AnnotationView
   */
  @Builder
  buildAnnotationView(viewData: AnnotationViewData) {
    AnnotationView({
      marker: viewData.marker,
      reuseIdentifier: viewData.reuseIdentifier,
      screenX: viewData.screenX,
      screenY: viewData.screenY,
      centerOffset: { dx: 0, dy: 0 }, // 从 viewData 获取
      anchorU: viewData.anchorU,
      anchorV: viewData.anchorV,
      visible: viewData.visible,
      mapBearing: this.mapBearing,
      mapPitch: this.mapPitch,
      screenHeight: this.screenHeight,
      customContentBuilder: viewData.customView ? () => {
        // TODO: 渲染自定义内容
        // 当前 HarmonyOS SDK 暂不支持动态组件内容
      } : undefined,
      onSelect: (marker: Marker) => {
        console.info('[AnnotationViewOverlay] Annotation selected:', marker.getId());
        if (this.onAnnotationSelect) {
          this.onAnnotationSelect(marker);
        }
      },
      onDeselect: (marker: Marker) => {
        console.info('[AnnotationViewOverlay] Annotation deselected:', marker.getId());
        if (this.onAnnotationDeselect) {
          this.onAnnotationDeselect(marker);
        }
      },
      onDragStart: (marker: Marker) => {
        console.info('[AnnotationViewOverlay] Drag start:', marker.getId());
        if (this.onAnnotationDragStart) {
          this.onAnnotationDragStart(marker);
        }
      },
      onDrag: (marker: Marker, screenX: number, screenY: number) => {
        if (this.onAnnotationDrag) {
          this.onAnnotationDrag(marker, screenX, screenY);
        }
      },
      onDragEnd: (marker: Marker, screenX: number, screenY: number) => {
        console.info('[AnnotationViewOverlay] Drag end:', marker.getId());
        if (this.onAnnotationDragEnd) {
          this.onAnnotationDragEnd(marker, screenX, screenY);
        }
      }
    })
  }
  
  build() {
    Stack() {
      // 渲染所有可见的 AnnotationView
      ForEach(
        this.visibleAnnotationViews,
        (viewData: AnnotationViewData) => {
          this.buildAnnotationView(viewData)
        },
        (viewData: AnnotationViewData) => {
          // 使用 marker ID 作为唯一键
          return `annotation-${viewData.marker.getId()}`;
        }
      )
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None) // 不拦截事件，允许穿透到地图
  }
}


