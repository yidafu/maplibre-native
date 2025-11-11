import { TestPageLayout } from '../common/TestPageLayout';
import { formatLatLng, formatLatLngObject, DEFAULT_STYLE_URLS } from '../common/TestUtils';
import { MapView, MapLibreMap, NativeMapView, Projection, LatLng, PixelCoordinate, OnMapClickListener } from 'maplibre_harmony';

@Entry
@Component
struct ProjectionConversionTestPage {
  private mapController: MapLibreMap | null = null;
  private nativeMapView: NativeMapView | null = null;
  private projection: Projection | null = null;

  @State private pixelRatio: number = 1.0;
  @State private lastLogicalX: number = 0;
  @State private lastLogicalY: number = 0;
  @State private lastPhysicalX: number = 0;
  @State private lastPhysicalY: number = 0;
  @State private lastLatLngProjection: LatLng | null = null;
  @State private lastLatLngMap: LatLng | null = null;
  @State private lastLatLngNative: LatLng | null = null;
  @State private conversionLogs: string[] = [];

  build() {
    Column() {
      TestPageLayout({
        title: 'Projection Conversion',
        description: '验证 Projection 与 MapLibreMap 坐标转换的一致性',
        showActionBar: true,
        mapContent: () => this.buildMapContent(),
        controlPanel: () => this.buildControlPanel(),
        actionButtons: () => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildMapContent(): void {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: (map: MapLibreMap) => {
        this.onMapReady(map);
      }
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  private buildControlPanel(): void {
    Column() {
      Text(`像素比: ${this.pixelRatio.toFixed(3)}x`).fontSize(14).fontWeight(FontWeight.Medium)

      Text(`最近点击 (逻辑): (${this.lastLogicalX.toFixed(2)}, ${this.lastLogicalY.toFixed(2)})`)
        .fontSize(12).fontColor('#555555').margin({ top: 8 })
      Text(`最近点击 (物理): (${this.lastPhysicalX.toFixed(2)}, ${this.lastPhysicalY.toFixed(2)})`)
        .fontSize(12).fontColor('#555555').margin({ top: 4 })

      Text('最近一次转换结果').fontSize(13).fontWeight(FontWeight.Bold).margin({ top: 12 })
      if (this.lastLatLngProjection) {
        Text(`Projection: ${formatLatLngObject(this.lastLatLngProjection, 6)}`).fontSize(12)
      }
      if (this.lastLatLngMap) {
        Text(`MapLibreMap.latLngForPixel: ${formatLatLngObject(this.lastLatLngMap, 6)}`).fontSize(12)
      }
      if (this.lastLatLngNative) {
        Text(`NativeMapView.latLngForPixel: ${formatLatLngObject(this.lastLatLngNative, 6)}`).fontSize(12)
      }

      Divider().margin({ top: 12, bottom: 12 })

      Text('转换日志').fontSize(13).fontWeight(FontWeight.Bold)
      Column() {
        ForEach(this.conversionLogs, (log: string, index: number) => {
          Text(log)
            .fontSize(11)
            .fontFamily('monospace')
            .width('100%')
            .backgroundColor(index % 2 === 0 ? '#FAFAFA' : '#FFFFFF')
            .padding({ top: 2, bottom: 2 })
        })
      }
      .width('100%')
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      .padding({ left: 6, right: 6, top: 6, bottom: 6 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 2 })
  }

  @Builder
  private buildActionButtons(): void {
    Column() {
      Button('转换地图中心坐标')
        .margin({ bottom: 8 })
        .onClick(() => {
          this.convertCurrentCenter();
        })

      Button('批量转换可视区四角')
        .margin({ bottom: 8 })
        .onClick(() => {
          this.convertVisibleRegionCorners();
        })

      Button('清除日志')
        .onClick(() => {
          this.conversionLogs = [];
        })
    }
    .width('100%')
  }

  private onMapReady(map: MapLibreMap): void {
    this.mapController = map;
    this.nativeMapView = map.getNativeMapView();
    this.projection = map.getProjection();
    this.pixelRatio = this.readPixelRatio();

    class MapClickListenerImpl implements OnMapClickListener {
      private page: ProjectionConversionTestPage;

      constructor(page: ProjectionConversionTestPage) {
        this.page = page;
      }

      onMapClick(x: number, y: number): boolean {
        this.page.handleTap(x, y);
        return true;
      }
    }

    map.addOnMapClickListener(new MapClickListenerImpl(this));

    this.appendLog('🚀 Map ready，Projection 测试初始化完成');
  }

  private handleTap(x: number, y: number): void {
    this.convertLogicalPoint(x, y, '🖱️ Tap');
  }

  private convertCurrentCenter(): void {
    if (!this.mapController || !this.nativeMapView || !this.projection) {
      this.appendLog('⚠️ 地图未就绪，无法转换中心点');
      return;
    }

    try {
      const center = this.mapController.getLatLng();
      const logicalPixel = this.mapController.pixelForLatLng(center.latitude, center.longitude);
      const pixelRatio = this.readPixelRatio();
      const physicalPixel = this.nativeMapView.pixelForLatLng(center.latitude, center.longitude);
      const projectionPixel = this.projection.toScreenLocation(center);

      this.appendLog(`🎯 中心点: ${formatLatLng(center.latitude, center.longitude, 6)} | logical=(${logicalPixel.x.toFixed(2)}, ${logicalPixel.y.toFixed(2)}) | projection=(${projectionPixel.x.toFixed(2)}, ${projectionPixel.y.toFixed(2)}) | native=(${physicalPixel.x.toFixed(2)}, ${physicalPixel.y.toFixed(2)}) | ratio=${pixelRatio.toFixed(3)}x`);
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      this.appendLog(`❌ 转换中心点失败: ${reason}`);
    }
  }

  private convertVisibleRegionCorners(): void {
    if (!this.mapController || !this.projection) {
      this.appendLog('⚠️ 地图未就绪，无法获取可视区域');
      return;
    }

    try {
      const visibleRegion = this.projection.getVisibleRegion();
      const corners: Array<[string, LatLng]> = [
        ['TopLeft', visibleRegion.topLeft],
        ['TopRight', visibleRegion.topRight],
        ['BottomLeft', visibleRegion.bottomLeft],
        ['BottomRight', visibleRegion.bottomRight]
      ];

      const pixelRatio = this.readPixelRatio();

      for (let i = 0; i < corners.length; i++) {
        const item = corners[i];
        const label = item[0];
        const cornerLatLng = item[1];

        const logical = this.projection.toScreenLocation(cornerLatLng);
        if (!logical || !this.mapController || !this.nativeMapView) {
          continue;
        }
        const mapLogical = this.mapController.pixelForLatLng(cornerLatLng.latitude, cornerLatLng.longitude);
        const nativePhysical = this.nativeMapView.pixelForLatLng(cornerLatLng.latitude, cornerLatLng.longitude);
        this.appendLog(`${label}: ${formatLatLngObject(cornerLatLng, 6)} | projection=(${logical.x.toFixed(1)}, ${logical.y.toFixed(1)}) | map=(${mapLogical.x.toFixed(1)}, ${mapLogical.y.toFixed(1)}) | native phys=(${nativePhysical.x.toFixed(1)}, ${nativePhysical.y.toFixed(1)}) | ratio=${pixelRatio.toFixed(3)}x`);
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      this.appendLog(`❌ 转换可视区域失败: ${reason}`);
    }
  }

  private calculateMismatch(a: LatLng, b: LatLng): number {
    return a.distanceTo(b);
  }

  private appendLog(message: string): void {
    const next = [message, ...this.conversionLogs];
    const MAX_LOG = 40;
    this.conversionLogs = next.length > MAX_LOG ? next.slice(0, MAX_LOG) : next;
  }

  private readPixelRatio(): number {
    if (!this.mapController) {
      return 1;
    }
    try {
      const ratioCandidate = this.mapController.getPixelRatio?.();
      if (typeof ratioCandidate === 'number' && Number.isFinite(ratioCandidate) && ratioCandidate > 0) {
        return ratioCandidate;
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      this.appendLog(`⚠️ 获取像素比失败: ${reason}`);
    }
    if (this.nativeMapView) {
      try {
        const candidate = this.nativeMapView.getPixelRatio?.();
        if (typeof candidate === 'number' && Number.isFinite(candidate) && candidate > 0) {
          return candidate;
        }
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        this.appendLog(`⚠️ 从 NativeMapView 获取像素比失败: ${reason}`);
      }
    }
    return 1;
  }

  private convertLogicalPoint(x: number, y: number, label: string): void {
    if (!this.mapController || !this.nativeMapView || !this.projection) {
      this.appendLog('⚠️ 地图未就绪，无法进行坐标转换');
      return;
    }

    const pixelRatio = this.readPixelRatio();
    const physicalX = x * pixelRatio;
    const physicalY = y * pixelRatio;

    this.lastLogicalX = x;
    this.lastLogicalY = y;
    this.lastPhysicalX = physicalX;
    this.lastPhysicalY = physicalY;

    try {
      const projLatLng = this.projection.fromScreenLocation(PixelCoordinate.create(x, y));
      const mapLatLng = this.mapController.latLngForPixel(x, y);
      const nativeLatLng = LatLng.fromNative(this.nativeMapView.latLngForPixel(physicalX, physicalY));

      this.lastLatLngProjection = projLatLng;
      this.lastLatLngMap = mapLatLng;
      this.lastLatLngNative = nativeLatLng;

      const mismatchProjection = this.calculateMismatch(mapLatLng, projLatLng);
      const mismatchNative = this.calculateMismatch(mapLatLng, nativeLatLng);

      this.appendLog(`${label} (${x.toFixed(1)}, ${y.toFixed(1)}) -> map=${formatLatLngObject(mapLatLng, 6)} | projection Δ=${mismatchProjection.toFixed(2)}m | native Δ=${mismatchNative.toFixed(2)}m`);
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      this.appendLog(`❌ 坐标转换失败: ${reason}`);
    }
  }
}
