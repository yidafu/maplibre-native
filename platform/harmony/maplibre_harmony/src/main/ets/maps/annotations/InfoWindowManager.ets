import maplibre from 'libmaplibre.so';
import { InfoWindow, InfoWindowPosition } from './InfoWindow';
import { InfoWindowAdapter } from './InfoWindowAdapter';
import { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from '../listeners/OnInfoWindowCloseListener';
import { OnInfoWindowLongClickListener } from '../listeners/OnInfoWindowLongClickListener';
import { Point } from '../geometry/Point';

type Marker = maplibre.Marker;

/**
 * InfoWindowManager - 信息窗口管理器
 * 
 * 管理所有 InfoWindow 的显示和隐藏
 * 
 * 参考:
 * - Android: InfoWindowManager.java
 */
export class InfoWindowManager {
  private infoWindows: Map<number, InfoWindow> = new Map();
  private adapter: InfoWindowAdapter | null = null;
  private onClickListener: OnInfoWindowClickListener | null = null;
  private onLongClickListener: OnInfoWindowLongClickListener | null = null;
  private onCloseListener: OnInfoWindowCloseListener | null = null;
  private allowConcurrentMultiple: boolean = false;
  
  // UI 回调 - 用于通知外部显示/隐藏/更新 UI
  private onShowUICallback?: (marker: Marker, position: InfoWindowPosition) => void;
  private onHideUICallback?: (marker: Marker) => void;
  private onUpdateUICallback?: (marker: Marker, position: InfoWindowPosition) => void;
  
  /**
   * 设置 UI 显示回调
   */
  setOnShowUICallback(callback: (marker: Marker, position: InfoWindowPosition) => void): void {
    this.onShowUICallback = callback;
  }
  
  /**
   * 设置 UI 隐藏回调
   */
  setOnHideUICallback(callback: (marker: Marker) => void): void {
    this.onHideUICallback = callback;
  }
  
  /**
   * 设置 UI 更新回调
   */
  setOnUpdateUICallback(callback: (marker: Marker, position: InfoWindowPosition) => void): void {
    this.onUpdateUICallback = callback;
  }
  
  /**
   * 设置 InfoWindowAdapter
   */
  setAdapter(adapter: InfoWindowAdapter | null): void {
    this.adapter = adapter;
  }
  
  /**
   * 获取 InfoWindowAdapter
   */
  getAdapter(): InfoWindowAdapter | null {
    return this.adapter;
  }
  
  /**
   * 设置点击监听器
   */
  setOnClickListener(listener: OnInfoWindowClickListener | null): void {
    this.onClickListener = listener;
  }
  
  /**
   * 获取点击监听器
   */
  getOnClickListener(): OnInfoWindowClickListener | null {
    return this.onClickListener;
  }
  
  /**
   * 设置长按监听器
   */
  setOnLongClickListener(listener: OnInfoWindowLongClickListener | null): void {
    this.onLongClickListener = listener;
  }
  
  /**
   * 获取长按监听器
   */
  getOnLongClickListener(): OnInfoWindowLongClickListener | null {
    return this.onLongClickListener;
  }
  
  /**
   * 设置关闭监听器
   */
  setOnCloseListener(listener: OnInfoWindowCloseListener | null): void {
    this.onCloseListener = listener;
  }
  
  /**
   * 获取关闭监听器
   */
  getOnCloseListener(): OnInfoWindowCloseListener | null {
    return this.onCloseListener;
  }
  
  /**
   * 设置是否允许多个 InfoWindow 同时显示
   */
  setAllowConcurrentMultiple(allow: boolean): void {
    this.allowConcurrentMultiple = allow;
  }
  
  /**
   * 是否允许多个 InfoWindow 同时显示
   */
  isAllowConcurrentMultiple(): boolean {
    return this.allowConcurrentMultiple;
  }
  
  /**
   * 显示 Marker 的 InfoWindow
   * @param marker Marker 实例
   * @param screenWidth 屏幕宽度
   * @param screenHeight 屏幕高度
   * @param markerScreenPosition Marker 的屏幕坐标
   */
  show(marker: Marker, screenWidth: number, screenHeight: number, markerScreenPosition: Point): InfoWindow | null {
    // 如果不允许多个，先关闭已有的
    if (!this.allowConcurrentMultiple) {
      this.closeAll();
    }
    
    // 检查是否有内容可显示
    if (!this.isValidForMarker(marker)) {
      console.warn('[InfoWindowManager] Marker has no title or snippet, cannot show InfoWindow');
      return null;
    }
    
    // 创建或获取 InfoWindow
    const markerId = marker.getId();
    let infoWindow = this.infoWindows.get(markerId);
    
    if (!infoWindow) {
      infoWindow = new InfoWindow(marker);
      
      // 设置回调
      infoWindow.setOnShowCallback((m: Marker, pos: InfoWindowPosition) => {
        if (this.onShowUICallback) {
          this.onShowUICallback(m, pos);
        }
      });
      
      infoWindow.setOnCloseCallback((m: Marker) => {
        if (this.onHideUICallback) {
          this.onHideUICallback(m);
        }
        if (this.onCloseListener) {
          this.onCloseListener.onInfoWindowClose(m);
        }
      });
      
      infoWindow.setOnUpdateCallback((m: Marker, pos: InfoWindowPosition) => {
        if (this.onUpdateUICallback) {
          this.onUpdateUICallback(m, pos);
        }
      });
      
      this.infoWindows.set(markerId, infoWindow);
    }
    
    // 显示
    infoWindow.show(screenWidth, screenHeight, markerScreenPosition);
    
    console.info('[InfoWindowManager] Showing InfoWindow for marker:', markerId);
    
    return infoWindow;
  }
  
  /**
   * 关闭指定 Marker 的 InfoWindow
   */
  close(marker: Marker): void {
    const infoWindow = this.infoWindows.get(marker.getId());
    if (infoWindow && infoWindow.isShown()) {
      infoWindow.close();
      console.info('[InfoWindowManager] Closed InfoWindow for marker:', marker.getId());
    }
  }
  
  /**
   * 关闭所有 InfoWindow
   */
  closeAll(): void {
    let closedCount = 0;
    this.infoWindows.forEach(infoWindow => {
      if (infoWindow.isShown()) {
        infoWindow.close();
        closedCount++;
      }
    });
    
    if (closedCount > 0) {
      console.info('[InfoWindowManager] Closed', closedCount, 'InfoWindows');
    }
  }
  
  /**
   * 检查 Marker 是否有有效的 InfoWindow 内容
   */
  isValidForMarker(marker: Marker): boolean {
    const title = marker.getTitle();
    const snippet = marker.getSnippet();
    const hasTitle = title ? title.length > 0 : false;
    const hasSnippet = snippet ? snippet.length > 0 : false;
    return hasTitle || hasSnippet;
  }
  
  /**
   * 获取指定 Marker 的 InfoWindow
   */
  get(marker: Marker): InfoWindow | null {
    return this.infoWindows.get(marker.getId()) || null;
  }
  
  /**
   * 更新所有显示中的 InfoWindow 位置
   * @param screenWidth 屏幕宽度
   * @param screenHeight 屏幕高度
   * @param getMarkerScreenPosition 获取 Marker 屏幕坐标的函数
   */
  updatePositions(
    screenWidth: number,
    screenHeight: number,
    getMarkerScreenPosition: (marker: Marker) => Point
  ): void {
    this.infoWindows.forEach(infoWindow => {
      if (infoWindow.isShown()) {
        const marker = infoWindow.getMarker();
        const markerPos = getMarkerScreenPosition(marker);
        infoWindow.update(screenWidth, screenHeight, markerPos);
      }
    });
  }
  
  /**
   * 触发 InfoWindow 点击事件
   */
  triggerClick(marker: Marker): boolean {
    if (this.onClickListener) {
      this.onClickListener.onInfoWindowClick(marker);
      return true;
    }
    return false;
  }
  
  /**
   * 触发 InfoWindow 长按事件
   */
  triggerLongClick(marker: Marker): boolean {
    if (this.onLongClickListener) {
      this.onLongClickListener.onInfoWindowLongClick(marker);
      return true;
    }
    return false;
  }
  
  /**
   * 获取所有显示中的 InfoWindow
   */
  getVisibleInfoWindows(): InfoWindow[] {
    const visible: InfoWindow[] = [];
    this.infoWindows.forEach(infoWindow => {
      if (infoWindow.isShown()) {
        visible.push(infoWindow);
      }
    });
    return visible;
  }
}

