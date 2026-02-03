import { CenterOffset, LatLng, MapLibreMap, MapView } from 'maplibre_harmony';
import {
  ViewAnnotationAddOptions,
  ViewAnnotationManager,
  ViewAnnotationUpdateOptions
} from 'maplibre_harmony/src/main/ets/maps/annotations/ViewAnnotationManager';
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, formatLatLngObject } from '../common/TestUtils';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import promptAction from '@ohos.promptAction';

const MAX_RANDOM_OFFSET = 0.015;
const BADGE_WIDTH = 184;
const BADGE_HEIGHT = 112;
const BADGE_OFFSET_Y = -32;
const CARD_WIDTH = 240;
const CARD_HEIGHT = 168;
const CARD_OFFSET_Y = -72;
const ANCHOR_ALIGNMENT_U = 0.5;
const ANCHOR_ALIGNMENT_V = 1.0;

type AnnotationKind = 'badge' | 'card';

interface ViewAnnotationRecord {
  id: number;
  type: AnnotationKind;
  anchor: LatLng;
  width: number;
  height: number;
  anchorU: number;
  anchorV: number;
  centerOffset: CenterOffset;
  draggable: boolean;
  scalesWithViewingDistance: boolean;
  rotatesWithCamera: boolean;
  visible: boolean;
  title: string;
  subtitle?: string;
  description?: string;
  highlightColor?: string;
  zIndex: number;
}

@Entry
@Component
struct AnnotationViewReuseTestPage {
  @State statusMessage: string = '等待地图加载...';
  @State reuseStats: string[] = [];
  @State annotationCount: number = 0;
  @State dragEnabled: boolean = true;
  @State scaleEnabled: boolean = true;
  @State rotateEnabled: boolean = true;

  private mapLibreMap: MapLibreMap | null = null;
  private viewAnnotationManager: ViewAnnotationManager | null = null;
  private batchIndex: number = 1;
  private annotations: Map<number, ViewAnnotationRecord> = new Map();

  aboutToDisappear() {
    hilog.info(DOMAIN, 'AnnotationViewReuse', 'About to disappear, cleaning map');
    this.clearAllAnnotations(false);
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
      this.mapLibreMap = null;
    }
    if (this.viewAnnotationManager) {
      this.viewAnnotationManager.clear();
      this.viewAnnotationManager = null;
    }
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'View Annotation · Reuse & Drag',
        description: '使用 addViewAnnotation API 演示多视图复用、拖拽与批量管理',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildControlPanel()
      })
        .width('100%')
        .height('100%');
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private buildMapContent() {
    Stack() {
      MapView({
        styleUrl: DEFAULT_STYLE_URLS.bright,
        initialLatitude: TEST_LOCATIONS.shanghai.latitude,
        initialLongitude: TEST_LOCATIONS.shanghai.longitude,
        initialZoom: 12,
        initialBearing: 0,
        initialPitch: 20,
        onMapReady: this.onMapReady
      })
        .width('100%')
        .height('100%');
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private buildControlPanel() {
    Column({ space: 12 }) {
      Text('操作面板')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%');

      Row({ space: 12 }) {
        Button('添加徽章视图')
          .type(ButtonType.Capsule)
          .onClick(() => this.addSingleAnnotation('badge'));
        Button('添加卡片视图')
          .type(ButtonType.Capsule)
          .onClick(() => this.addSingleAnnotation('card'));
      };

      Row({ space: 12 }) {
        Button('批量添加 ×5')
          .type(ButtonType.Capsule)
          .onClick(() => this.addBatchAnnotations(5));
        Button('清空全部')
          .type(ButtonType.Capsule)
          .onClick(() => this.clearAllAnnotations());
      };

      Divider();

      Column({ space: 8 }) {
        Row({ space: 12 }) {
          Text('启用拖拽').fontSize(14).width('40%');
          Toggle({ type: ToggleType.Switch, isOn: this.dragEnabled })
            .onChange((isOn: boolean) => {
              this.dragEnabled = isOn;
              this.applyGlobalOptions();
              this.updateStatus(this.dragEnabled ? '✅ 已启用拖拽' : '⛔ 已禁用拖拽');
            });
        };

        Row({ space: 12 }) {
          Text('距离缩放').fontSize(14).width('40%');
          Toggle({ type: ToggleType.Switch, isOn: this.scaleEnabled })
            .onChange((isOn: boolean) => {
              this.scaleEnabled = isOn;
              this.applyGlobalOptions();
              this.updateStatus(this.scaleEnabled ? '✅ 已启用距离缩放' : '⛔ 已禁用距离缩放');
            });
        };

        Row({ space: 12 }) {
          Text('跟随旋转').fontSize(14).width('40%');
          Toggle({ type: ToggleType.Switch, isOn: this.rotateEnabled })
            .onChange((isOn: boolean) => {
              this.rotateEnabled = isOn;
              this.applyGlobalOptions();
              this.updateStatus(this.rotateEnabled ? '✅ 已启用跟随旋转' : '⛔ 已禁用跟随旋转');
            });
        };
      };

      Divider();

      Text(`视图数量: ${this.annotationCount}`)
        .fontSize(14)
        .width('100%');

      if (this.reuseStats.length > 0) {
        Column({ space: 4 }) {
          Text('类型统计:')
            .fontSize(13)
            .fontWeight(FontWeight.Medium);

          ForEach(this.reuseStats, (line: string) => {
            Text(line)
              .fontSize(12)
              .width('100%');
          }, (line: string) => line);
        };
      } else {
        Text('类型统计: 暂无数据')
          .fontSize(12)
          .width('100%');
      }

      Divider();

      Text(`状态: ${this.statusMessage}`)
        .fontSize(12)
        .width('100%');
    }
    .width('100%');
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapLibreMap = map;
    this.viewAnnotationManager = map.getViewAnnotationManager();

    if (this.viewAnnotationManager) {
      this.viewAnnotationManager.clear();
    }
    this.annotations.clear();
    this.batchIndex = 1;
    this.updateStatistics();

    map.jumpTo(0, TEST_LOCATIONS.shanghai.latitude, TEST_LOCATIONS.shanghai.longitude, 0, 13);
    this.addBatchAnnotations(2);
    this.updateStatus('✅ ViewAnnotation 场景准备完成');
  };

  private addSingleAnnotation(type: AnnotationKind): void {
    const manager = this.viewAnnotationManager;
    if (!manager) {
      this.updateStatus('⚠️ ViewAnnotationManager 未初始化');
      return;
    }

    const index = this.batchIndex++;
    const anchor = this.generateRandomPosition(TEST_LOCATIONS.shanghai);
    const isCard = type === 'card';
    const width = isCard ? CARD_WIDTH : BADGE_WIDTH;
    const height = isCard ? CARD_HEIGHT : BADGE_HEIGHT;
    const offsetY = isCard ? CARD_OFFSET_Y : BADGE_OFFSET_Y;
    const zIndex = isCard ? 18 : 12;

    const centerOffset: CenterOffset = { dx: 0, dy: offsetY };

    const record: ViewAnnotationRecord = {
      id: -1,
      type,
      anchor,
      width,
      height,
      anchorU: ANCHOR_ALIGNMENT_U,
      anchorV: ANCHOR_ALIGNMENT_V,
      centerOffset,
      draggable: this.dragEnabled,
      scalesWithViewingDistance: this.scaleEnabled,
      rotatesWithCamera: this.rotateEnabled,
      visible: true,
      title: isCard ? `卡片视图 #${index}` : `徽章视图 #${index}`,
      subtitle: isCard ? '拖拽查看复用效果' : undefined,
      description: isCard ? '提供按钮交互示例' : '轻量级徽章示例',
      highlightColor: isCard ? '#FFB300' : undefined,
      zIndex
    };

    const options = this.buildAddOptions(record);

    try {
      const id = manager.addViewAnnotation(options);
      if (id <= 0) {
        this.updateStatus('❌ 添加失败: 原生返回无效标识符');
        hilog.error(DOMAIN, 'AnnotationViewReuse', `addViewAnnotation returned invalid id: ${id}`);
        return;
      }

      record.id = id;
      this.annotations.set(id, record);
      this.updateStatistics();
      this.updateStatus(`✅ 已添加 ${isCard ? '卡片' : '徽章'} 视图 #${id}`);
    } catch (error) {
      const reason = error instanceof Error ? error.message : JSON.stringify(error);
      this.updateStatus(`❌ 添加失败: ${reason}`);
      hilog.error(DOMAIN, 'AnnotationViewReuse', `addSingleAnnotation failed: ${reason}`);
    }
  }

  private addBatchAnnotations(count: number): void {
    for (let i = 0; i < count; i++) {
      const type: AnnotationKind = i % 2 === 0 ? 'badge' : 'card';
      this.addSingleAnnotation(type);
    }

    promptAction.showToast({
      message: `已批量添加 ${count} 个视图`,
      duration: 2000
    });
  }

  private clearAllAnnotations(showToast: boolean = true): void {
    if (this.viewAnnotationManager) {
      this.annotations.forEach((record) => {
        try {
          this.viewAnnotationManager!.removeViewAnnotation(record.id);
        } catch (error) {
          const reason = error instanceof Error ? error.message : JSON.stringify(error);
          hilog.warn(DOMAIN, 'AnnotationViewReuse', `removeViewAnnotation failed: ${reason}`);
        }
      });
      this.viewAnnotationManager.clear();
    }

    this.annotations.clear();
    this.updateStatistics();
    this.updateStatus('🧹 已清空全部视图');

    if (showToast) {
      promptAction.showToast({
        message: '已清空全部视图',
        duration: 2000
      });
    }
  }

  private applyGlobalOptions(): void {
    this.annotations.forEach((record) => {
      record.draggable = this.dragEnabled;
      record.scalesWithViewingDistance = this.scaleEnabled;
      record.rotatesWithCamera = this.rotateEnabled;
      this.updateNativeAnnotation(record);
    });
  }

  private updateStatistics(): void {
    const total = this.annotations.size;
    let badgeCount = 0;
    let cardCount = 0;

    this.annotations.forEach((record) => {
      if (record.type === 'badge') {
        badgeCount++;
      } else {
        cardCount++;
      }
    });

    this.annotationCount = total;
    this.reuseStats = total > 0 ? [`徽章视图: ${badgeCount}`, `卡片视图: ${cardCount}`] : [];
  }

  private updateNativeAnnotation(record: ViewAnnotationRecord): void {
    const manager = this.viewAnnotationManager;
    if (!manager) {
      return;
    }

    try {
      const updated = manager.updateViewAnnotation(record.id, this.buildUpdateOptions(record));
      if (!updated) {
        hilog.warn(DOMAIN, 'AnnotationViewReuse', `updateViewAnnotation returned false for id=${record.id}`);
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(DOMAIN, 'AnnotationViewReuse', `updateNativeAnnotation failed: ${reason}`);
    }
  }

  private buildAddOptions(record: ViewAnnotationRecord): ViewAnnotationAddOptions {
    return {
      anchor: record.anchor,
      width: record.width,
      height: record.height,
      centerOffset: record.centerOffset,
      visible: record.visible,
      allowOverlap: true,
      draggable: record.draggable,
      scalesWithViewingDistance: record.scalesWithViewingDistance,
      rotatesWithCamera: record.rotatesWithCamera,
      anchorU: record.anchorU,
      anchorV: record.anchorV,
      zIndex: record.zIndex,
      // builder: record.type === 'badge'
      //   ? () => this.renderBadgeContent(record)
      //   : () => this.renderCardContent(record)
    };
  }

  private buildUpdateOptions(record: ViewAnnotationRecord): ViewAnnotationUpdateOptions {
    return {
      anchor: record.anchor,
      width: record.width,
      height: record.height,
      centerOffset: record.centerOffset,
      visible: record.visible,
      allowOverlap: true,
      draggable: record.draggable,
      scalesWithViewingDistance: record.scalesWithViewingDistance,
      rotatesWithCamera: record.rotatesWithCamera,
      anchorU: record.anchorU,
      anchorV: record.anchorV,
      zIndex: record.zIndex
    };
  }

  private focusOnAnnotation(id: number): void {
    if (!this.mapLibreMap) {
      return;
    }

    const record = this.annotations.get(id);
    if (!record) {
      this.updateStatus('⚠️ 目标视图不存在');
      return;
    }

    const anchor = record.anchor;
    this.mapLibreMap.easeTo(anchor.latitude, anchor.longitude, 0, this.mapLibreMap.getZoom(), 600);
    this.updateStatus(`📌 已定位到视图 #${id}`);
  }

  private removeAnnotationById(id: number): void {
    const manager = this.viewAnnotationManager;
    if (!manager) {
      return;
    }

    const record = this.annotations.get(id);
    if (!record) {
      return;
    }

    try {
      const removed = manager.removeViewAnnotation(id);
      if (!removed) {
        hilog.warn(DOMAIN, 'AnnotationViewReuse', `removeViewAnnotation returned false for id=${id}`);
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(DOMAIN, 'AnnotationViewReuse', `removeAnnotationById failed: ${reason}`);
    }

    this.annotations.delete(id);
    this.updateStatistics();
    this.updateStatus(`🗑️ 已移除视图 #${id}`);
  }

  private updateStatus(message: string): void {
    this.statusMessage = message;
  }

  @Builder
  private renderBadgeContent(record: ViewAnnotationRecord): void {
    Column({ space: 6 }) {
      Text(record.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White);

      Text(`位置: ${formatLatLngObject(record.anchor, 4)}`)
        .fontSize(11)
        .fontColor('rgba(255,255,255,0.9)');

      Text(`ID: ${record.id}`)
        .fontSize(10)
        .fontColor('rgba(255,255,255,0.8)');
    }
    .padding(12)
    .backgroundColor('rgba(30, 136, 229, 0.95)')
    .borderRadius(12)
    .shadow({
      radius: 6,
      color: 'rgba(0, 0, 0, 0.35)',
      offsetX: 0,
      offsetY: 2
    });
  }

  @Builder
  private renderCardContent(record: ViewAnnotationRecord): void {
    Column({ space: 10 }) {
      Text(record.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black);

      Text(`位置: ${formatLatLngObject(record.anchor, 4)}`)
        .fontSize(12)
        .fontColor('rgba(0,0,0,0.75)');

      if (record.description) {
        Text(record.description)
          .fontSize(12)
          .fontColor('rgba(0,0,0,0.65)');
      }

      Row({ space: 12 }) {
        Button('居中查看')
          .type(ButtonType.Capsule)
          .fontSize(12)
          .onClick(() => this.focusOnAnnotation(record.id));

        Button('移除')
          .type(ButtonType.Capsule)
          .fontSize(12)
          .onClick(() => this.removeAnnotationById(record.id));
      };
    }
    .padding(16)
    .backgroundColor('rgba(250, 250, 250, 0.95)')
    .borderRadius(16)
    .shadow({
      radius: 10,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: 4
    });
  }

  private generateRandomPosition(center: LatLng): LatLng {
    const latOffset = (Math.random() - 0.5) * 2 * MAX_RANDOM_OFFSET;
    const lngOffset = (Math.random() - 0.5) * 2 * MAX_RANDOM_OFFSET;
    return new LatLng(center.latitude + latOffset, center.longitude + lngOffset);
  }
}


