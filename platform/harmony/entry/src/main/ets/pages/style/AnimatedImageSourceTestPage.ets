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
  private scroller: Scroller = new Scroller();
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
      initialZoom: 5,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 6);
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
        [bounds.getSouthwest().longitude, bounds.getNortheast().latitude],
        [bounds.getNortheast().longitude, bounds.getNortheast().latitude],
        [bounds.getNortheast().longitude, bounds.getSouthwest().latitude],
        [bounds.getSouthwest().longitude, bounds.getSouthwest().latitude]
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
    Scroll(this.scroller) {
      Column({ space: 8 }) {
        Button(this.isAnimating ? '停止动画' : '开始动画')
          .width('100%')
          .onClick(() => {
            if (this.isAnimating) {
              this.stopAnimation();
            } else {
              this.startAnimation();
            }
          })
      }
      .width('100%')
      .padding(8)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
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

