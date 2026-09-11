/**
 * AutomationTestPage - Bridge for ohosTest integration test suites.
 *
 * This page holds a MapView that is exposed via TestMapAccessor,
 * allowing the hypium-based ohosTest suites to interact with the
 * native map instance for automated testing.
 */
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';

@Entry
@Component
struct AutomationTestPage {
  private mapController: MapLibreMap | null = null;

  aboutToDisappear() {
    TestMapAccessor.clear();
    this.mapController?.destroy();
    this.mapController = null;
  }

  onPageShow() {
    console.info('[AutomationTestPage] onPageShow');
  }

  onPageHide() {
    TestMapAccessor.clear();
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    TestMapAccessor.setMapInstance(map);
    console.info('[AutomationTestPage] Map ready');
  };

  build() {
    Column() {
      MapView({
        onMapReady: this.onMapReady,
      })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
