/**
 * New API Features Test Page
 * 新增 API 功能测试页面
 * 
 * 测试内容：
 * 1. SymbolLayer 新增的 11 个方法
 * 2. FillExtrusionLayer 的 setFillExtrusionVerticalGradient
 * 3. 所有图层的 setSourceLayer 方法（矢量瓦片）
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  GeoJson,
  GeoJsonSource,
  MapLibreMap,
  MapView,
  SymbolLayer,
  FillExtrusionLayer,
  VectorSource
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';
import type { JSONValue } from 'libmaplibre.so';
import image from '@ohos.multimedia.image';
import { common } from '@kit.AbilityKit';

// 定义城市数据接口
interface CityData {
  name: string;
  lng: number;
  lat: number;
}

@Entry
@Component
struct NewAPIFeaturesTestPage {
  private mapController: MapLibreMap | null = null;
  @State private testMode: 'symbol' | 'extrusion' | 'vector' = 'symbol';
  @State private verticalGradient: boolean = true;

  build() {
    Column() {
      TestPageLayout({
        title: 'New API Features',
        description: '新增 API 功能测试',
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
      initialLatitude: 35,
      initialLongitude: 112,
      initialZoom: 4,
      onMapReady: async (map: MapLibreMap) => {
        this.mapController = map;
        console.info('✨ 地图已就绪，添加测试图层...');
        await this.initializeTestLayers();
      }
    })
  }

  @Builder
  buildActionButtons() {
    Column({ space: 8 }) {
      Text('测试模式选择')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })

      Row({ space: 8 }) {
        Button(`Symbol 新方法${this.testMode === 'symbol' ? ' ✓' : ''}`)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.switchTestMode('symbol'))
          .backgroundColor(this.testMode === 'symbol' ? '#007DFF' : '#cccccc')

        Button(`3D 渐变${this.testMode === 'extrusion' ? ' ✓' : ''}`)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.switchTestMode('extrusion'))
          .backgroundColor(this.testMode === 'extrusion' ? '#007DFF' : '#cccccc')

        Button(`矢量瓦片${this.testMode === 'vector' ? ' ✓' : ''}`)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.switchTestMode('vector'))
          .backgroundColor(this.testMode === 'vector' ? '#007DFF' : '#cccccc')
      }

      if (this.testMode === 'symbol') {
        this.buildSymbolTests()
      } else if (this.testMode === 'extrusion') {
        this.buildExtrusionTests()
      } else {
        this.buildVectorTileTests()
      }
    }
    .width('100%')
  }

  @Builder
  buildSymbolTests() {
    Column({ space: 8 }) {
      Text('符号布局属性（新增）')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Row({ space: 8 }) {
        Button('符号放置')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.testSymbolPlacement())

        Button('符号间距')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.testSymbolSpacing())
      }

      Button('符号避免边缘')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.testSymbolAvoidEdges())

      Text('图标属性（新增）')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Button('图标平移')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.testIconTranslate())

      Text('文本布局属性（新增）')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Row({ space: 8 }) {
        Button('文本字母间距')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.testTextLetterSpacing())

        Button('文本对齐')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.testTextJustify())
      }

      Row({ space: 8 }) {
        Button('文本旋转')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.testTextRotate())

        Button('文本转换')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.testTextTransform())
      }

      Button('文本行高')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.testTextLineHeight())

      Text('文本绘制属性（新增）')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Row({ space: 8 }) {
        Button('文本光晕模糊')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.testTextHaloBlur())

        Button('文本平移')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.testTextTranslate())
      }

      Button('测试所有新方法')
        .fontSize(14)
        .width('100%')
        .backgroundColor('#4CAF50')
        .onClick(() => this.testAllSymbolMethods())
    }
  }

  @Builder
  buildExtrusionTests() {
    Column({ space: 8 }) {
      Text('3D 渐变效果（新增）')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Button(`垂直渐变: ${this.verticalGradient ? '开启' : '关闭'}`)
        .fontSize(14)
        .width('100%')
        .onClick(() => this.toggleVerticalGradient())

      Button('使用表达式控制')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.testVerticalGradientExpression())

      Text('其他测试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Button('调整俯仰角查看效果')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.adjustPitch())
    }
  }

  @Builder
  buildVectorTileTests() {
    Column({ space: 8 }) {
      Text('矢量瓦片源测试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Text('测试 setSourceLayer() 方法')
        .fontSize(14)
        .width('100%')
        .fontColor('#666666')

      Button('添加矢量瓦片图层')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.addVectorTileLayer())

      Button('切换数据源图层')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.switchSourceLayer())

      Text('说明：矢量瓦片包含多个图层，\nsetSourceLayer 指定使用哪个图层的数据')
        .fontSize(12)
        .width('100%')
        .fontColor('#999999')
        .margin({ top: 8 })
    }
  }

  /**
   * 初始化测试图层
   */
  private async initializeTestLayers(): Promise<void> {
    if (!this.mapController) return;

    try {
      await this.loadMarkerIcon();
      await this.addSymbolTestLayer();
      await this.addExtrusionTestLayer();
      showToast('测试图层已就绪');
    } catch (error) {
      console.error('初始化测试图层失败:', error);
      showToast(`初始化失败: ${error}`);
    }
  }

  /**
   * 加载测试图标
   */
  private async loadMarkerIcon(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const resourceMgr = context.resourceManager;

      const imageBuffer = await resourceMgr.getRawFileContent('marker_0.png');
      const imageSource = image.createImageSource(imageBuffer.buffer);
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      imageSource.release();

      const imageInfo = await pixelMap.getImageInfo();
      const width = imageInfo.size.width;
      const height = imageInfo.size.height;

      const pixelBytes = new ArrayBuffer(width * height * 4);
      await pixelMap.readPixelsToBuffer(pixelBytes);

      const style = this.mapController!.getStyle();
      if (style) {
        style.addImage('test-marker', pixelBytes, width, height, false);
      }

      pixelMap.release();
    } catch (error) {
      console.error('加载图标失败:', error);
    }
  }

  /**
   * 添加符号图层测试
   */
  private async addSymbolTestLayer(): Promise<void> {
    if (!this.mapController) return;

    const cities: CityData[] = [
      { name: '北京', lng: 116.4, lat: 39.9 },
      { name: '上海', lng: 121.5, lat: 31.2 },
      { name: '广州', lng: 113.3, lat: 23.1 },
      { name: '深圳', lng: 114.1, lat: 22.5 },
      { name: '成都', lng: 104.1, lat: 30.7 }
    ];

    const features = cities.map(city => {
      const props: Record<string, JSONValue> = {
        'title': city.name,
        'icon': 'test-marker'
      };
      return GeoJson.pointFeature([city.lng, city.lat], props);
    });

    const geojson = GeoJson.featureCollection(features);
    const source = new GeoJsonSource('symbol-test-source');
    source.setGeoJson(geojson);

    const layer = new SymbolLayer('symbol-test-layer', 'symbol-test-source');
    layer.setTextField(['get', 'title']);
    layer.setIconImage(['get', 'icon']);
    layer.setTextSize(16);
    layer.setTextColor('#000000');
    layer.setTextHaloColor('#FFFFFF');
    layer.setTextHaloWidth(2);
    layer.setTextAnchor('top');
    layer.setTextOffset([0, -1.5]);
    layer.setIconAnchor('bottom');

    this.mapController.addSource(source);
    this.mapController.addLayer(layer);

    console.info('✅ 符号测试图层已添加');
  }

  /**
   * 添加 3D 拉伸测试图层
   */
  private async addExtrusionTestLayer(): Promise<void> {
    if (!this.mapController) return;

    const props1: Record<string, JSONValue> = { 'height': 100, 'gradient': true };
    const props2: Record<string, JSONValue> = { 'height': 150, 'gradient': false };

    const geojson = GeoJson.featureCollection([
      GeoJson.polygonFeature([[
        [116.39, 39.89],
        [116.40, 39.89],
        [116.40, 39.90],
        [116.39, 39.90],
        [116.39, 39.89]
      ]], props1),
      GeoJson.polygonFeature([[
        [116.40, 39.90],
        [116.41, 39.90],
        [116.41, 39.91],
        [116.40, 39.91],
        [116.40, 39.90]
      ]], props2)
    ]);

    const source = new GeoJsonSource('extrusion-test-source');
    source.setGeoJson(geojson);

    const layer = new FillExtrusionLayer('extrusion-test-layer', 'extrusion-test-source');
    layer.setFillExtrusionColor('#2196F3');
    layer.setFillExtrusionOpacity(0.8);
    layer.setFillExtrusionHeight(['get', 'height']);
    layer.setFillExtrusionBase(0);
    // ✅ 测试新增的 setFillExtrusionVerticalGradient 方法
    layer.setFillExtrusionVerticalGradient(true);

    this.mapController.addSource(source);
    this.mapController.addLayer(layer);

    console.info('✅ 3D 拉伸测试图层已添加（垂直渐变已启用）');
  }

  /**
   * 切换测试模式
   */
  private async switchTestMode(mode: 'symbol' | 'extrusion' | 'vector'): Promise<void> {
    this.testMode = mode;

    if (!this.mapController) return;

    if (mode === 'symbol') {
      this.mapController.jumpTo(0, 35, 112, 0, 4);
    } else if (mode === 'extrusion') {
      this.mapController.jumpTo(0, 39.9, 116.4, 45, 16);
    } else {
      this.mapController.jumpTo(0, 12, 2177, 0, 12);
    }

    showToast(`切换到${mode === 'symbol' ? '符号' : mode === 'extrusion' ? '3D' : '矢量瓦片'}测试`);
  }

  // ==================== SymbolLayer 新方法测试 ====================

  /**
   * 测试 setSymbolPlacement
   */
  private testSymbolPlacement(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const placements = ['point', 'line', 'line-center'];
    const current = Math.floor(Math.random() * placements.length);
    layer.setSymbolPlacement(placements[current]);
    showToast(`✅ 符号放置: ${placements[current]}`);
  }

  /**
   * 测试 setSymbolSpacing
   */
  private testSymbolSpacing(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const spacing = 100 + Math.random() * 300; // 100-400
    layer.setSymbolSpacing(spacing);
    showToast(`✅ 符号间距: ${spacing.toFixed(0)}px`);
  }

  /**
   * 测试 setSymbolAvoidEdges
   */
  private testSymbolAvoidEdges(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const avoid = Math.random() > 0.5;
    layer.setSymbolAvoidEdges(avoid);
    showToast(`✅ 符号避免边缘: ${avoid ? '是' : '否'}`);
  }

  /**
   * 测试 setIconTranslate
   */
  private testIconTranslate(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const x = Math.random() * 20 - 10;
    const y = Math.random() * 20 - 10;
    layer.setIconTranslate([x, y]);
    showToast(`✅ 图标平移: [${x.toFixed(1)}, ${y.toFixed(1)}]`);
  }

  /**
   * 测试 setTextLetterSpacing
   */
  private testTextLetterSpacing(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const spacing = Math.random() * 0.5; // 0-0.5
    layer.setTextLetterSpacing(spacing);
    showToast(`✅ 文本字母间距: ${spacing.toFixed(2)}`);
  }

  /**
   * 测试 setTextJustify
   */
  private testTextJustify(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const justifies = ['auto', 'left', 'center', 'right'];
    const current = Math.floor(Math.random() * justifies.length);
    layer.setTextJustify(justifies[current]);
    showToast(`✅ 文本对齐: ${justifies[current]}`);
  }

  /**
   * 测试 setTextRotate
   */
  private testTextRotate(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const angle = Math.random() * 360;
    layer.setTextRotate(angle);
    showToast(`✅ 文本旋转: ${angle.toFixed(0)}°`);
  }

  /**
   * 测试 setTextTransform
   */
  private testTextTransform(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const transforms = ['none', 'uppercase', 'lowercase'];
    const current = Math.floor(Math.random() * transforms.length);
    layer.setTextTransform(transforms[current]);
    showToast(`✅ 文本转换: ${transforms[current]}`);
  }

  /**
   * 测试 setTextLineHeight
   */
  private testTextLineHeight(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const height = 1.0 + Math.random() * 0.5; // 1.0-1.5
    layer.setTextLineHeight(height);
    showToast(`✅ 文本行高: ${height.toFixed(2)}em`);
  }

  /**
   * 测试 setTextHaloBlur
   */
  private testTextHaloBlur(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const blur = Math.random() * 3; // 0-3
    layer.setTextHaloBlur(blur);
    showToast(`✅ 文本光晕模糊: ${blur.toFixed(1)}px`);
  }

  /**
   * 测试 setTextTranslate
   */
  private testTextTranslate(): void {
    const layer = this.mapController?.getLayer('symbol-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('未找到测试图层');
      return;
    }

    const x = Math.random() * 20 - 10;
    const y = Math.random() * 20 - 10;
    layer.setTextTranslate([x, y]);
    showToast(`✅ 文本平移: [${x.toFixed(1)}, ${y.toFixed(1)}]`);
  }

  /**
   * 测试所有新增的符号方法
   */
  private testAllSymbolMethods(): void {
    showToast('开始测试所有新方法...');

    setTimeout(() => this.testSymbolPlacement(), 100);
    setTimeout(() => this.testSymbolSpacing(), 500);
    setTimeout(() => this.testSymbolAvoidEdges(), 1000);
    setTimeout(() => this.testIconTranslate(), 1500);
    setTimeout(() => this.testTextLetterSpacing(), 2000);
    setTimeout(() => this.testTextJustify(), 2500);
    setTimeout(() => this.testTextRotate(), 3000);
    setTimeout(() => this.testTextTransform(), 3500);
    setTimeout(() => this.testTextLineHeight(), 4000);
    setTimeout(() => this.testTextHaloBlur(), 4500);
    setTimeout(() => this.testTextTranslate(), 5000);
    setTimeout(() => showToast('✅ 所有新方法测试完成！'), 5500);
  }

  // ==================== FillExtrusionLayer 新方法测试 ====================

  /**
   * 切换垂直渐变
   */
  private toggleVerticalGradient(): void {
    const layer = this.mapController?.getLayer('extrusion-test-layer');
    if (!layer || !(layer instanceof FillExtrusionLayer)) {
      showToast('未找到3D图层');
      return;
    }

    this.verticalGradient = !this.verticalGradient;
    layer.setFillExtrusionVerticalGradient(this.verticalGradient);
    showToast(`✅ 垂直渐变: ${this.verticalGradient ? '开启' : '关闭'}`);
  }

  /**
   * 使用表达式控制垂直渐变
   */
  private testVerticalGradientExpression(): void {
    const layer = this.mapController?.getLayer('extrusion-test-layer');
    if (!layer || !(layer instanceof FillExtrusionLayer)) {
      showToast('未找到3D图层');
      return;
    }

    // 使用数据驱动的表达式
    layer.setFillExtrusionVerticalGradient(['get', 'gradient']);
    showToast('✅ 使用表达式控制渐变');
  }

  /**
   * 调整俯仰角
   */
  private adjustPitch(): void {
    if (!this.mapController) return;

    const pitch = this.mapController.getPitch();
    const newPitch = pitch < 45 ? 60 : 30;
    this.mapController.setPitch(newPitch, 500);
    showToast(`俯仰角: ${newPitch}°`);
  }

  // ==================== 矢量瓦片测试 ====================

  /**
   * 添加矢量瓦片图层
   */
  private addVectorTileLayer(): void {
    if (!this.mapController) return;

    try {
      // 使用 OpenMapTiles demo tiles
      const vectorSource = new VectorSource('openmaptiles');
      vectorSource.setUrl('https://demotiles.maplibre.org/tiles-omt/{z}/{x}/{y}.pbf');

      this.mapController.addSource(vectorSource);

      // 创建一个线图层显示道路
      const layer = new SymbolLayer('vector-test-layer', 'openmaptiles');
      // ✅ 测试 setSourceLayer 方法
      layer.setSourceLayer('transportation');
      layer.setTextField(['get', 'name:latin']);
      layer.setTextSize(12);
      layer.setTextColor('#FF0000');

      this.mapController.addLayer(layer);

      this.mapController.jumpTo(0, 12, 2177, 0, 12);
      showToast('✅ 矢量瓦片图层已添加（transportation 图层）');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
  }

  /**
   * 切换数据源图层
   */
  private switchSourceLayer(): void {
    const layer = this.mapController?.getLayer('vector-test-layer');
    if (!layer || !(layer instanceof SymbolLayer)) {
      showToast('请先添加矢量瓦片图层');
      return;
    }

    const sourceLayers = ['transportation', 'place', 'poi', 'water_name'];
    const current = Math.floor(Math.random() * sourceLayers.length);
    const newSourceLayer = sourceLayers[current];

    // ✅ 测试运行时切换 sourceLayer
    layer.setSourceLayer(newSourceLayer);
    showToast(`✅ 切换到数据源图层: ${newSourceLayer}`);
  }
}

