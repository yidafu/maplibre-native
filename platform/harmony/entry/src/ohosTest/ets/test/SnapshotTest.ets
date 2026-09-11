/**
 * Snapshot Integration Tests
 *
 * Tests map snapshot APIs through a real NativeMapView.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap, MapSnapshotter, SnapshotOptions, SnapshotOptionsBuilder, CameraPosition, LatLng } from 'maplibre_harmony';
import { TestMapAccessor } from '../../../../main/ets/pages/common/TestMapAccessor';

const TAG = 'SnapshotTest';
const DOMAIN = 0xFF00;
const TIMEOUT = 15000;

export default function SnapshotTest() {
  describe('Snapshot Integration', () => {
    let driver: Driver;
    let map: MapLibreMap;

    beforeAll(async () => {
      driver = Driver.create();
      try {
        const item = await driver.findComponent(ON.text('Auto Test'));
        if (item) { await item.click(); }
      } catch (e) { /* ignore */ }
      const start = Date.now();
      while (Date.now() - start < TIMEOUT) {
        if (TestMapAccessor.isMapReady()) {
          const instance = TestMapAccessor.getMapInstance();
          if (instance) { map = instance; break; }
        }
        await sleep(200);
      }
    });

    afterAll(async () => {
      TestMapAccessor.clear();
      try { await driver.pressBack(); } catch (e) { /* ignore */ }
    });

    describe('MapView snapshot', () => {
      it('should have a valid MapLibreMap instance', 0, () => {
        expect(map !== null && map !== undefined).assertTrue();
      });

      it('should schedule snapshot without crash', 0, () => {
        if (!map) { return; }
        map.scheduleSnapshot();
        expect(true).assertTrue();
      });

      it('should return snapshot promise', 0, () => {
        if (!map) { return; }
        const promise = map.snapshot();
        expect(promise !== null).assertTrue();
        expect(promise instanceof Promise).assertTrue();
      });
    });

    describe('MapSnapshotter', () => {
      it('should create MapSnapshotter with options', 0, () => {
        const snapshotter = new MapSnapshotter(
          new SnapshotOptionsBuilder()
            .withSize(256, 256)
            .withLatLng(new LatLng(39.9, 116.4))
            .withZoom(10)
            .build()
        );
        expect(snapshotter !== null).assertTrue();
      });

      it('should get and set style URL on snapshotter', 0, () => {
        const options = new SnapshotOptionsBuilder()
          .withSize(256, 256)
          .withLatLng(new LatLng(39.9, 116.4))
          .withZoom(10)
          .build();
        const snapshotter = new MapSnapshotter(options);
        snapshotter.setStyleUrl('https://demotiles.maplibre.org/style.json');
        const url = snapshotter.getStyleUrl();
        expect(url.length > 0).assertTrue();
      });

      it('should cancel snapshot without crash', 0, () => {
        const options = new SnapshotOptionsBuilder()
          .withSize(256, 256)
          .withLatLng(new LatLng(39.9, 116.4))
          .withZoom(10)
          .build();
        const snapshotter = new MapSnapshotter(options);
        snapshotter.cancel();
        expect(true).assertTrue();
      });
    });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms);
}
