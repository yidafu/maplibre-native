/**
 * CustomLayer 测试页面
 * 
 * 测试 CustomLayer 的基本功能：
 * - 添加自定义图层到地图
 * - 动态修改渲染颜色
 * - 控制可见性
 * - 控制缩放范围
 */
import { router } from '@kit.ArkUI';
import { MapView, MapLibreMap, NativeMapView } from 'maplibre_harmony';
import { CustomLayer, createCustomLayerWithColor } from '@maplibre/harmony/maps/style/layers';
import type { RGBAColor } from '@maplibre/harmony/maps/style/layers';

@Entry
@Component
struct CustomLayerTestPage {
  private mapLibreMap: MapLibreMap | null = null;
  private nativeMapView: NativeMapView | null = null;
  private customLayer: CustomLayer | null = null;

  @State currentColor: RGBAColor = { r: 0.0, g: 1.0, b: 0.0, a: 0.5 };  // 默认绿色半透明
  @State isLayerVisible: boolean = true;
  @State minZoom: number = 0;
  @State maxZoom: number = 24;
  @State layerAdded: boolean = false;

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 16 })

        Text('CustomLayer 测试')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位，保持标题居中
        Button('').visibility(Visibility.Hidden).margin({ right: 16 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#f5f5f5')

      // 地图区域
      MapView({
        onMapReady: (map: MapLibreMap) => {
          this.mapLibreMap = map;
          this.nativeMapView = map.getNativeMapView();
          this.initMap();
        }
      })
        .width('100%')
        .layoutWeight(1)

      // 控制面板
      Column() {
        Text('CustomLayer 控制').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 8 })

        // 添加/移除图层
        Row() {
          Button(this.layerAdded ? '移除图层' : '添加图层')
            .onClick(() => {
              if (this.layerAdded) {
                this.removeCustomLayer();
              } else {
                this.addCustomLayer();
              }
            })
            .width('48%')

          Button('重新添加')
            .onClick(() => {
              if (!this.nativeMapView) {
                return;
              }
              this.removeCustomLayer();
              const onMapRendered = (fully: boolean): void => {
                this.nativeMapView?.removeOnDidFinishRenderingMapListener(onMapRendered);
                this.addCustomLayer();
              };
              this.nativeMapView.addOnDidFinishRenderingMapListener(onMapRendered);
              this.mapLibreMap?.triggerRepaint();
            })
            .width('48%')
            .enabled(this.layerAdded)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 12 })

        Divider().margin({ bottom: 12 })

        // 颜色控制
        Text(`颜色控制 (R:${this.currentColor.r.toFixed(2)} G:${this.currentColor.g.toFixed(2)} B:${this.currentColor.b.toFixed(2)} A:${this.currentColor.a.toFixed(2)})`)
          .fontSize(14)
          .margin({ bottom: 8 })

        Row() {
          Button('红色')
            .onClick(() => {
              this.currentColor = { r: 1.0, g: 0.0, b: 0.0, a: 0.5 };
              this.updateColor();
            })
            .width('23%')
            .backgroundColor('#ff0000')

          Button('绿色')
            .onClick(() => {
              this.currentColor = { r: 0.0, g: 1.0, b: 0.0, a: 0.5 };
              this.updateColor();
            })
            .width('23%')
            .backgroundColor('#00ff00')

          Button('蓝色')
            .onClick(() => {
              this.currentColor = { r: 0.0, g: 0.0, b: 1.0, a: 0.5 };
              this.updateColor();
            })
            .width('23%')
            .backgroundColor('#0000ff')

          Button('黄色')
            .onClick(() => {
              this.currentColor = { r: 1.0, g: 1.0, b: 0.0, a: 0.5 };
              this.updateColor();
            })
            .width('23%')
            .backgroundColor('#ffff00')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 12 })

        Divider().margin({ bottom: 12 })

        // 可见性控制
        Row() {
          Text('可见性:')
            .fontSize(14)
            .width(80)

          Toggle({ type: ToggleType.Switch, isOn: this.isLayerVisible })
            .onChange((isOn: boolean) => {
              this.isLayerVisible = isOn;
              this.updateVisibility();
            })
            .enabled(this.layerAdded)
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 缩放范围控制
        Row() {
          Column() {
            Text(`最小缩放: ${this.minZoom}`)
              .fontSize(14)

            Slider({
              value: this.minZoom,
              min: 0,
              max: 24,
              step: 1
            })
              .onChange((value: number) => {
                this.minZoom = value;
                this.updateZoomRange();
              })
              .width('100%')
              .enabled(this.layerAdded)
          }
          .width('48%')

          Column() {
            Text(`最大缩放: ${this.maxZoom}`)
              .fontSize(14)

            Slider({
              value: this.maxZoom,
              min: 0,
              max: 24,
              step: 1
            })
              .onChange((value: number) => {
                this.maxZoom = value;
                this.updateZoomRange();
              })
              .width('100%')
              .enabled(this.layerAdded)
          }
          .width('48%')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 12 })

        Divider().margin({ bottom: 12 })

        // 测试信息
        Text('说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 4 })

        Text('CustomLayer 使用 OpenGL ES 3.0 渲染一个填充整个视口的彩色矩形。')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ bottom: 4 })

        Text('可以通过按钮动态修改颜色，通过开关控制可见性，通过滑块调整缩放范围。')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#ffffff')
      .borderRadius(8)
      .margin({ top: 8, left: 8, right: 8, bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f0f0f0')
  }

  /**
   * 初始化地图
   */
  private initMap(): void {
    if (!this.mapLibreMap) {
      return;
    }

    try {
      // 设置地图样式
      this.mapLibreMap.setStyleUrl('https://demotiles.maplibre.org/style.json');

      // 等待样式加载完成后添加图层
      this.mapLibreMap.setOnStyleLoadedListener({
        onStyleLoaded: () => {
          console.info('[CustomLayerTestPage] Style loaded, ready to add custom layer');
        }
      });

      console.info('[CustomLayerTestPage] Map initialized successfully');
    } catch (error) {
      console.error('[CustomLayerTestPage] Failed to initialize map:', error);
    }
  }

  /**
   * 添加自定义图层
   */
  private addCustomLayer(): void {
    if (!this.mapLibreMap) {
      console.warn('[CustomLayerTestPage] Map not ready');
      return;
    }

    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        console.warn('[CustomLayerTestPage] Style not loaded');
        return;
      }

      // 创建自定义图层
      this.customLayer = new CustomLayer('custom-layer');
      
      // 设置初始颜色
      this.customLayer.setColor(
        this.currentColor.r,
        this.currentColor.g,
        this.currentColor.b,
        this.currentColor.a
      );

      // 设置缩放范围
      this.customLayer.setMinZoom(this.minZoom);
      this.customLayer.setMaxZoom(this.maxZoom);

      // 添加图层（添加到所有图层之下，这样不会遮挡地图）
      // 如果要添加到特定图层下方，可以使用 addLayerBelow
      style.addLayer(this.customLayer.getNative());

      this.layerAdded = true;
      console.info('[CustomLayerTestPage] CustomLayer added successfully');
    } catch (error) {
      console.error('[CustomLayerTestPage] Failed to add custom layer:', error);
    }
  }

  /**
   * 移除自定义图层
   */
  private removeCustomLayer(): void {
    if (!this.mapLibreMap || !this.customLayer) {
      return;
    }

    try {
      const style = this.mapLibreMap.getStyle();
      if (style) {
        style.removeLayer('custom-layer');
        this.customLayer = null;
        this.layerAdded = false;
        console.info('[CustomLayerTestPage] CustomLayer removed successfully');
      }
    } catch (error) {
      console.error('[CustomLayerTestPage] Failed to remove custom layer:', error);
    }
  }

  /**
   * 更新颜色
   */
  private updateColor(): void {
    if (!this.customLayer || !this.layerAdded) {
      return;
    }

    try {
      this.customLayer.setColor(
        this.currentColor.r,
        this.currentColor.g,
        this.currentColor.b,
        this.currentColor.a
      );
      
      // 触发重绘
      if (this.mapLibreMap) {
        this.mapLibreMap.triggerRepaint();
      }

      console.info('[CustomLayerTestPage] Color updated:', this.currentColor);
    } catch (error) {
      console.error('[CustomLayerTestPage] Failed to update color:', error);
    }
  }

  /**
   * 更新可见性
   */
  private updateVisibility(): void {
    if (!this.customLayer || !this.layerAdded) {
      return;
    }

    try {
      this.customLayer.setVisibility(this.isLayerVisible ? 'visible' : 'none');
      console.info('[CustomLayerTestPage] Visibility updated:', this.isLayerVisible);
    } catch (error) {
      console.error('[CustomLayerTestPage] Failed to update visibility:', error);
    }
  }

  /**
   * 更新缩放范围
   */
  private updateZoomRange(): void {
    if (!this.customLayer || !this.layerAdded) {
      return;
    }

    try {
      this.customLayer.setMinZoom(this.minZoom);
      this.customLayer.setMaxZoom(this.maxZoom);
      console.info('[CustomLayerTestPage] Zoom range updated: %d - %d', this.minZoom, this.maxZoom);
    } catch (error) {
      console.error('[CustomLayerTestPage] Failed to update zoom range:', error);
    }
  }

  /**
   * 页面即将显示
   */
  onPageShow(): void {
    console.info('[CustomLayerTestPage] Page shown');
  }

  /**
   * 页面即将隐藏
   */
  onPageHide(): void {
    console.info('[CustomLayerTestPage] Page hidden');
  }
}

