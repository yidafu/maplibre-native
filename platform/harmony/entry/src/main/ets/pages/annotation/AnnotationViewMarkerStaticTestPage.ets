import { LatLng, MapLibreMap, MapView } from 'maplibre_harmony';
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

const RANDOM_OFFSET = 0.01;
const CARD_WIDTH = 240;
const CARD_HEIGHT = 140;
const CARD_CENTER_OFFSET_Y = -56;
const ANCHOR_ALIGNMENT_U = 0.5;
const ANCHOR_ALIGNMENT_V = 1.0;

@Entry
@Component
struct AnnotationViewMarkerStaticTestPage {
  @State statusMessage: string = '等待地图加载...';
  @State dragEnabled: boolean = true;
  @State scaleEnabled: boolean = false;
  @State rotateEnabled: boolean = false;
  @State annotationSelected: boolean = false;

  private mapLibreMap: MapLibreMap | null = null;
  private viewAnnotationManager: ViewAnnotationManager | null = null;
  private annotationId: number = -1;
  private currentAnchor: LatLng = TEST_LOCATIONS.beijing;
  private viewVisible: boolean = true;

  aboutToDisappear() {
    hilog.info(DOMAIN, 'AnnotationViewBasic', 'aboutToDisappear');
    try {
      if (this.viewAnnotationManager && this.annotationId > 0) {
        this.viewAnnotationManager.removeViewAnnotation(this.annotationId);
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(DOMAIN, 'AnnotationViewBasic', `removeViewAnnotation failed: ${reason}`);
    }

    this.annotationId = -1;

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
        title: 'View Annotation · Native API',
        description: '使用 addViewAnnotation API 演示创建、更新与移动视图',
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
        initialLatitude: TEST_LOCATIONS.beijing.latitude,
        initialLongitude: TEST_LOCATIONS.beijing.longitude,
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
        Button('创建 / 更新 ViewAnnotation')
          .type(ButtonType.Capsule)
          .onClick(() => this.createOrUpdateAnnotation());

        Button('随机移动视图')
          .type(ButtonType.Capsule)
          .onClick(() => this.moveAnnotation());
      };

      Row({ space: 12 }) {
        Button(this.annotationSelected ? '取消选中' : '选中视图')
          .type(ButtonType.Capsule)
          .onClick(() => this.toggleSelection());

        Button('移除视图')
          .type(ButtonType.Capsule)
          .onClick(() => this.removeAnnotation());
      };

      Divider();

      Column({ space: 8 }) {
        Row({ space: 12 }) {
          Text('启用拖拽').fontSize(14).width('40%');
          Toggle({ type: ToggleType.Switch, isOn: this.dragEnabled })
            .onChange((isOn: boolean) => {
              this.dragEnabled = isOn;
              this.applyAnnotationOptions();
              this.updateStatus(this.dragEnabled ? '✅ 已启用拖拽' : '⛔ 已禁用拖拽');
            });
        };

        Row({ space: 12 }) {
          Text('距离缩放').fontSize(14).width('40%');
          Toggle({ type: ToggleType.Switch, isOn: this.scaleEnabled })
            .onChange((isOn: boolean) => {
              this.scaleEnabled = isOn;
              this.applyAnnotationOptions();
              this.updateStatus(this.scaleEnabled ? '✅ 已启用距离缩放' : '⛔ 已禁用距离缩放');
            });
        };

        Row({ space: 12 }) {
          Text('跟随地图旋转').fontSize(14).width('40%');
          Toggle({ type: ToggleType.Switch, isOn: this.rotateEnabled })
            .onChange((isOn: boolean) => {
              this.rotateEnabled = isOn;
              this.applyAnnotationOptions();
              this.updateStatus(this.rotateEnabled ? '✅ 已启用跟随旋转' : '⛔ 已禁用跟随旋转');
            });
        };
      };

      Divider();

      Text(`状态: ${this.statusMessage}`)
        .fontSize(12)
        .width('100%');

      if (this.annotationId > 0) {
        Text(`当前坐标: ${formatLatLngObject(this.currentAnchor, 4)}`)
          .fontSize(12)
          .width('100%');
      }
    }
    .width('100%');
  }

  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    hilog.info(DOMAIN, 'AnnotationViewBasic', 'Map ready');
    this.mapLibreMap = map;
    this.viewAnnotationManager = map.getViewAnnotationManager();
    if (this.viewAnnotationManager) {
      this.viewAnnotationManager.clear();
    }
    this.annotationId = -1;

    this.focusInitialCamera(map);
    this.createOrUpdateAnnotation();
  };

  private createOrUpdateAnnotation(): void {
    const manager = this.viewAnnotationManager;
    if (!manager) {
      return;
    }

    try {
      if (this.annotationId < 0) {
        const id = manager.addViewAnnotation(this.buildAddOptions(this.currentAnchor));
        if (id > 0) {
          this.annotationId = id;
          this.updateStatus('✅ ViewAnnotation 已创建');
          promptAction.showToast({
            message: 'ViewAnnotation 已创建',
            duration: 1500
          });
        } else {
          this.updateStatus('❌ 创建失败: 无效的标识符');
          hilog.error(DOMAIN, 'AnnotationViewBasic', `addViewAnnotation returned invalid id: ${id}`);
        }
      } else {
        const updated = manager.updateViewAnnotation(this.annotationId, this.buildUpdateOptions(this.currentAnchor));
        if (updated) {
          this.updateStatus('✅ ViewAnnotation 已更新');
        } else {
          this.updateStatus('⚠️ 更新失败: 原生层拒绝更新');
          hilog.warn(DOMAIN, 'AnnotationViewBasic', 'updateViewAnnotation returned false');
        }
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : JSON.stringify(error);
      this.updateStatus(`❌ 操作失败: ${reason}`);
      hilog.error(DOMAIN, 'AnnotationViewBasic', `createOrUpdateAnnotation failed: ${reason}`);
    }

    manager.refreshRenderStates();
  }

  private buildAddOptions(anchor: LatLng): ViewAnnotationAddOptions {
    return {
      anchor,
      width: CARD_WIDTH,
      height: CARD_HEIGHT,
      centerOffset: { dx: 0, dy: CARD_CENTER_OFFSET_Y },
      visible: this.viewVisible,
      allowOverlap: true,
      draggable: this.dragEnabled,
      scalesWithViewingDistance: this.scaleEnabled,
      rotatesWithCamera: this.rotateEnabled,
      anchorU: ANCHOR_ALIGNMENT_U,
      anchorV: ANCHOR_ALIGNMENT_V,
      zIndex: 10,
      builder: () => this.renderAnnotationContent()
    };
  }

  private buildUpdateOptions(anchor: LatLng): ViewAnnotationUpdateOptions {
    return {
      anchor,
      width: CARD_WIDTH,
      height: CARD_HEIGHT,
      centerOffset: { dx: 0, dy: CARD_CENTER_OFFSET_Y },
      visible: this.viewVisible,
      allowOverlap: true,
      draggable: this.dragEnabled,
      scalesWithViewingDistance: this.scaleEnabled,
      rotatesWithCamera: this.rotateEnabled,
      anchorU: ANCHOR_ALIGNMENT_U,
      anchorV: ANCHOR_ALIGNMENT_V,
      zIndex: 10
    };
  }

  private applyAnnotationOptions(): void {
    if (this.annotationId < 0 || !this.viewAnnotationManager) {
      return;
    }

    try {
      const updated = this.viewAnnotationManager.updateViewAnnotation(this.annotationId, this.buildUpdateOptions(this.currentAnchor));
      if (!updated) {
        hilog.warn(DOMAIN, 'AnnotationViewBasic', 'applyAnnotationOptions: updateViewAnnotation returned false');
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(DOMAIN, 'AnnotationViewBasic', `applyAnnotationOptions failed: ${reason}`);
    }

    this.viewAnnotationManager.refreshRenderStates();
  }

  private moveAnnotation(): void {
    if (this.annotationId < 0 || !this.mapLibreMap || !this.viewAnnotationManager) {
      return;
    }

    const target = this.generateRandomPosition(this.currentAnchor);
    this.currentAnchor = target;

    try {
      const updated = this.viewAnnotationManager.updateViewAnnotation(this.annotationId, this.buildUpdateOptions(target));
      if (!updated) {
        hilog.warn(DOMAIN, 'AnnotationViewBasic', 'moveAnnotation: updateViewAnnotation returned false');
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(DOMAIN, 'AnnotationViewBasic', `moveAnnotation failed: ${reason}`);
    }

    this.mapLibreMap.easeTo(
      target.latitude,
      target.longitude,
      this.mapLibreMap.getBearing(),
      this.mapLibreMap.getZoom(),
      600
    );

    this.updateStatus(`🚶 已移动到 ${formatLatLngObject(target, 4)}`);
    this.viewAnnotationManager.refreshRenderStates();
  }

  private toggleSelection(): void {
    this.annotationSelected = !this.annotationSelected;
    this.updateStatus(this.annotationSelected ? '✅ 视图已选中' : '⭕ 视图未选中');
    this.viewAnnotationManager?.refreshRenderStates();
  }

  private removeAnnotation(): void {
    if (this.annotationId < 0 || !this.viewAnnotationManager) {
      return;
    }

    try {
      const removed = this.viewAnnotationManager.removeViewAnnotation(this.annotationId);
      if (removed) {
        this.updateStatus('🗑️ 已移除 ViewAnnotation');
      } else {
        this.updateStatus('⚠️ 移除失败: 未找到目标视图');
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(DOMAIN, 'AnnotationViewBasic', `removeViewAnnotation failed: ${reason}`);
    }

    this.annotationId = -1;
    this.viewAnnotationManager.refreshRenderStates();
  }

  private focusInitialCamera(map: MapLibreMap): void {
    const target = TEST_LOCATIONS.beijing;
    map.jumpTo(0, target.latitude, target.longitude, 0, 12.5);
  }

  private updateStatus(message: string): void {
    this.statusMessage = message;
  }

  @Builder
  private renderAnnotationContent(): void {
    Column({ space: 10 }) {
      Text('ViewAnnotation Demo')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width('100%');

      Text(`坐标: ${formatLatLngObject(this.currentAnchor, 4)}`)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.9)')
        .width('100%');

      Text(this.annotationSelected ? '选中状态: ✅' : '选中状态: ❌')
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.9)')
        .width('100%');

      Row({ space: 12 }) {
        Button('刷新内容')
          .type(ButtonType.Capsule)
          .fontSize(12)
          .onClick(() => {
            this.viewAnnotationManager?.refreshRenderStates();
            promptAction.showToast({
              message: '已刷新视图内容',
              duration: 1200
            });
          });

        Button('提示')
          .type(ButtonType.Capsule)
          .fontSize(12)
          .onClick(() => {
            promptAction.showToast({
              message: '来自 ViewAnnotation 的事件',
              duration: 1500
            });
          });
      };
    }
    .padding(16)
    .backgroundColor('rgba(30, 136, 229, 0.92)')
    .borderRadius(16)
    .shadow({
      radius: 10,
      color: 'rgba(0, 0, 0, 0.4)',
      offsetX: 0,
      offsetY: 4
    });
  }

  private generateRandomPosition(center: LatLng): LatLng {
    const latOffset = (Math.random() - 0.5) * 2 * RANDOM_OFFSET;
    const lngOffset = (Math.random() - 0.5) * 2 * RANDOM_OFFSET;
    return new LatLng(center.latitude + latOffset, center.longitude + lngOffset);
  }

}




