import { ImageSource, LatLng, LatLngBounds, MapLibreMap, MapView, RasterLayer } from 'maplibre_harmony';
/**
 * Animated Image Source Test Page
 * 动画图像源测试
 * 参考 Android: AnimatedImageSourceActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct AnimatedImageSourceTestPage {
  private mapController: MapLibreMap | null = null;
  private imageIndex: number = 0;
  private animationTimer: number | null = null;
  @State private isAnimating: boolean = false;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Animated Image Source',
        description: '动画图像源',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')

    .height('100%')
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 12);
        this.addImageSource(map);
      }
    })
  }

  private addImageSource(map: MapLibreMap): void {
    try {
      // 定义图像覆盖的地理边界
      const bounds = new LatLngBounds(
        new LatLng(39.8, 116.3),
        new LatLng(40.0, 116.5)
      );
      
      const source = new ImageSource('image-source');
      source.setUrl('https://via.placeholder.com/512');
      source.setCoordinates([
        [bounds.getSouthWest().longitude, bounds.getNorthEast().latitude],
        [bounds.getNorthEast().longitude, bounds.getNorthEast().latitude],
        [bounds.getNorthEast().longitude, bounds.getSouthWest().latitude],
        [bounds.getSouthWest().longitude, bounds.getSouthWest().latitude]
      ]);
      map.addSource(source);
      
      const layer = new RasterLayer('image-layer', 'image-source');
      layer.setRasterOpacity(0.7);
      map.addLayer(layer);
      
      showToast('图像源已添加');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
  }
  
  @Builder
  buildActionButtons() {
    Button(this.isAnimating ? '停止动画' : '开始动画')
      .onClick(() => {
        if (this.isAnimating) {
          this.stopAnimation();
        } else {
          this.startAnimation();
        }
      })
  }
  
  private startAnimation(): void {
    this.isAnimating = true;
    this.animationTimer = setInterval(() => {
      // TODO: 更新图像源的图片
      this.imageIndex = (this.imageIndex + 1) % 10;
    }, 100);
    showToast('动画已开始');
  }
  
  private stopAnimation(): void {
    if (this.animationTimer !== null) {
      clearInterval(this.animationTimer);
      this.animationTimer = null;
    }
    // this.isUpdating = false;  // 属性不存在，注释掉
    showToast('动画已停止');
  }
  
  aboutToDisappear() {
    this.stopAnimation();
  }
}

