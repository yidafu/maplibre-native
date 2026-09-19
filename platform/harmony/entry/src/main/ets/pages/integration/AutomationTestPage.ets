/**
 * AutomationTestPage - Bridge for ohosTest integration test suites.
 *
 * Pure-UI automation bridge:
 * - The camera readout Text (id: automation_camera_text) publishes the live
 *   camera state so UiTest suites can assert pan/zoom gestures through
 *   getText() without needing the MapLibreMap object (the ohosTest module
 *   compiles its own copy of shared singletons, so passing objects between
 *   the entry page and test suites does not work).
 * - The anchor Text behind the map lets suites verify this page opened
 *   (the page has no TestPageLayout title bar).
 * - TestMapAccessor is still set for the API-level suites.
 */
import { MapView, MapLibreMap, OnCameraIdleListener } from 'maplibre-harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';

class CameraIdleTextRefresher implements OnCameraIdleListener {
  private refresh: () => void;

  constructor(refresh: () => void) {
    this.refresh = refresh;
  }

  onCameraIdle(): void {
    this.refresh();
  }
}

@Entry
@Component
struct AutomationTestPage {
  private mapController: MapLibreMap | null = null;
  @State private cameraInfo: string = 'cam|waiting';

  aboutToDisappear() {
    TestMapAccessor.clear();
    AppStorage.delete('automationTestMap');
    this.mapController?.destroy();
    this.mapController = null;
  }

  onPageShow() {
    console.info('[AutomationTestPage] onPageShow');
  }

  onPageHide() {
    TestMapAccessor.clear();
    AppStorage.delete('automationTestMap');
  }

  private refreshCamera = (): void => {
    const map = this.mapController;
    if (map === null) {
      return;
    }
    const pos = map.getLatLng();
    const zoom = map.getZoom();
    this.cameraInfo = 'cam|' + pos.latitude.toFixed(4) + '|' + pos.longitude.toFixed(4) + '|' + zoom.toFixed(2);
  };

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    TestMapAccessor.setMapInstance(map);
    // Publish for the ohosTest suites: AppStorage is process-scoped, the
    // only channel that crosses the entry/entry_test module boundary.
    // Key must match AUTOMATION_TEST_MAP_KEY in the test module.
    AppStorage.setOrCreate('automationTestMap', map);
    // OnCameraIsChangingListener is a plain () => void function type.
    map.addOnCameraIsChangingListener((): void => {
      this.refreshCamera();
    });
    map.addOnCameraIdleListener(new CameraIdleTextRefresher(this.refreshCamera));
    this.refreshCamera();
    console.info('[AutomationTestPage] Map ready');
  };

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        // UiTest anchor behind the map — verifies the page actually opened.
        Text('AUTOMATION_PAGE_ANCHOR')
          .fontSize(1)
          .fontColor(Color.Transparent)

        MapView({
          onMapReady: this.onMapReady,
        })
          .width('100%')
          .height('100%')

        // Camera readout consumed by UiTest suites via getText().
        // HitTestMode.None keeps it from ever eating map gestures.
        Text(this.cameraInfo)
          .id('automation_camera_text')
          .fontSize(12)
          .fontColor('#333333')
          .padding(4)
          .backgroundColor('rgba(255,255,255,0.85)')
          .borderRadius(4)
          .margin({ top: 8, left: 8 })
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
