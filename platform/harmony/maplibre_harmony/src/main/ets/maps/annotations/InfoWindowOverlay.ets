import maplibre from 'libmaplibre_native.so';
import { InfoWindowComponent, InfoWindowPosition, InfoWindowStyle } from './InfoWindow';
import { InfoWindowManager } from './InfoWindowManager';

// 使用 NAPI Marker 类型
type Marker = maplibre.Marker;

/**
 * InfoWindow 状态数据
 */
export interface InfoWindowState {
  marker: Marker;
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
  
  /**
   * InfoWindow 列表变化时的回调
   */
  onInfoWindowsChanged() {
    console.info(`[InfoWindowOverlay] Visible InfoWindows changed: ${this.visibleInfoWindows.length}`);
  }
  
  build() {
    Stack() {
      // 渲染所有可见的 InfoWindow
      ForEach(
        this.visibleInfoWindows,
        (infoWindowState: InfoWindowState) => {
          InfoWindowComponent({
            marker: infoWindowState.marker,
            arrowOffsetX: infoWindowState.position.arrowOffsetX,
            customStyle: infoWindowState.style,
            onWindowClick: () => {
              console.info('[InfoWindowOverlay] InfoWindow clicked:', infoWindowState.marker.getId());
              if (this.onInfoWindowClick) {
                this.onInfoWindowClick(infoWindowState.marker);
              }
            },
            onLongClick: () => {
              console.info('[InfoWindowOverlay] InfoWindow long clicked:', infoWindowState.marker.getId());
              if (this.onInfoWindowLongClick) {
                this.onInfoWindowLongClick(infoWindowState.marker);
              }
            },
            onClose: () => {
              console.info('[InfoWindowOverlay] InfoWindow close requested:', infoWindowState.marker.getId());
              if (this.onInfoWindowClose) {
                this.onInfoWindowClose(infoWindowState.marker);
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


