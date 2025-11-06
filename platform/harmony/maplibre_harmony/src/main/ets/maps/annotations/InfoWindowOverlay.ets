import maplibre from 'libmaplibre.so';
import { InfoWindowComponent, InfoWindowPosition, InfoWindowStyle } from './InfoWindow';
import { InfoWindowManager } from './InfoWindowManager';
import { Marker } from './Marker';

/**
 * InfoWindow 状态数据
 */
export interface InfoWindowState {
  marker: Marker; // 保留引用用于回调
  // 以下是用于渲染的数据（避免 @Prop 传递 NAPI 对象的问题）
  markerId: number;
  markerTitle: string;
  markerSnippet: string;
  position: InfoWindowPosition;
  style?: InfoWindowStyle;
  key: string; // 用于 ForEach 的唯一键
}

/**
 * InfoWindowOverlay - InfoWindow 渲染层
 *
 * 作为覆盖层在地图上方渲染所有的 InfoWindow
 *
 * 使用方式：
 * ```typescript
 * Stack() {
 *   // 地图层
 *   XComponent(...)
 *
 *   // InfoWindow 层
 *   InfoWindowOverlay({ manager: this.infoWindowManager })
 * }
 * ```
 */
@Component
export struct InfoWindowOverlay {
  @Link @Watch('onInfoWindowsChanged') visibleInfoWindows: InfoWindowState[];
  // 事件回调
  onInfoWindowClick?: (marker: Marker) => void;
  onInfoWindowLongClick?: (marker: Marker) => void;
  onInfoWindowClose?: (marker: Marker) => void;
  onInfoWindowSizeChanged?: (marker: Marker, width: number, height: number) => void;

  /**
   * InfoWindow 列表变化时的回调
   */
  onInfoWindowsChanged() {
    console.info(`[InfoWindowOverlay] visibleInfoWindows changed, count: ${this.visibleInfoWindows.length}`);
  }

  build() {
    Stack() {
      // 渲染所有可见的 InfoWindow
      ForEach(
        this.visibleInfoWindows,
        (infoWindowState: InfoWindowState) => {
          InfoWindowComponent({
            markerId: infoWindowState.markerId,
            markerTitle: infoWindowState.markerTitle,
            markerSnippet: infoWindowState.markerSnippet,
            arrowOffsetX: infoWindowState.position.arrowOffsetX,
            customStyle: infoWindowState.style,
            onWindowClick: () => {
              if (this.onInfoWindowClick) {
                this.onInfoWindowClick(infoWindowState.marker);
              }
            },
            onLongClick: () => {
              if (this.onInfoWindowLongClick) {
                this.onInfoWindowLongClick(infoWindowState.marker);
              }
            },
            onClose: () => {
              if (this.onInfoWindowClose) {
                this.onInfoWindowClose(infoWindowState.marker);
              }
            },
            onSizeChanged: (width: number, height: number) => {
              if (this.onInfoWindowSizeChanged) {
                this.onInfoWindowSizeChanged(infoWindowState.marker, width, height);
              }
            }
          })
            .position({
              x: infoWindowState.position.x,
              y: infoWindowState.position.y
            })
        },
        (infoWindowState: InfoWindowState) => infoWindowState.key
      )
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None) // 不拦截事件，允许穿透到地图
  }
}

