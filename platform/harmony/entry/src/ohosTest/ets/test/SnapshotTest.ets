/**
 * Snapshot Integration Tests
 *
 * Tests map snapshot APIs through a real NativeMapView.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  MapLibreMap,
  MapSnapshotter,
  SnapshotOptions,
  SnapshotOptionsBuilder
} from 'maplibre_harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';

const TAG = 'SnapshotTest';
const DOMAIN = 0xFF00;
const TIMEOUT = 15000;
const STYLE_TIMEOUT = 10000;

/**
 * Minimal offline style: a background layer and an inline GeoJSON source,
 * so the snapshotter can finish loading without network access.
 * (Written as a raw string: ArkTS forbids untyped object literals.)
 */
const TEST_STYLE_JSON: string =
  '{"version":8,"name":"Snapshot Test Style",' +
  '"sources":{"test-geojson":{"type":"geojson","data":{"type":"FeatureCollection","features":[]}}},' +
  '"layers":[{"id":"test-background","type":"background","paint":{"background-color":"#ff0000"}}]}';

function createStyledSnapshotter(): MapSnapshotter {
  const options: SnapshotOptions = new SnapshotOptionsBuilder(256, 256)
    .withStyleJson(TEST_STYLE_JSON)
    .withPixelRatio(2.0)
    .build();
  return new MapSnapshotter(options);
}

/**
 * Poll until the snapshotter style finishes loading (detected via layer
 * retrieval), so subsequent style operations are deterministic.
 */
async function awaitStyleLoaded(snapshotter: MapSnapshotter): Promise<boolean> {
  const start = Date.now();
  while (Date.now() - start < STYLE_TIMEOUT) {
    if (snapshotter.getLayer('test-background') !== null) {
      return true;
    }
    await sleep(200);
  }
  return false;
}

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
          new SnapshotOptionsBuilder(256, 256)
            .withStyleUrl('https://demotiles.maplibre.org/style.json')
            .build()
        );
        expect(snapshotter !== null).assertTrue();
        snapshotter.cancel();
      });

      it('should get and set style URL on snapshotter', 0, () => {
        const snapshotter = new MapSnapshotter(
          new SnapshotOptionsBuilder(256, 256)
            .withStyleUrl('https://demotiles.maplibre.org/style.json')
            .build()
        );
        snapshotter.setStyleUrl('https://demotiles.maplibre.org/style.json');
        const url = snapshotter.getStyleUrl();
        expect(url.length > 0).assertTrue();
        snapshotter.cancel();
      });

      it('should cancel snapshot without crash', 0, () => {
        const snapshotter = new MapSnapshotter(
          new SnapshotOptionsBuilder(256, 256)
            .withStyleUrl('https://demotiles.maplibre.org/style.json')
            .build()
        );
        snapshotter.cancel();
        expect(true).assertTrue();
      });
    });

    describe('MapSnapshotter style operations', () => {
      it('should retrieve layer and source from snapshot style', 0, async () => {
        const snapshotter = createStyledSnapshotter();
        const loaded = await awaitStyleLoaded(snapshotter);
        hilog.info(DOMAIN, TAG, `Style loaded: ${loaded}`);
        expect(loaded).assertTrue();
        expect(snapshotter.getLayer('test-background') !== null).assertTrue();
        expect(snapshotter.getSource('test-geojson') !== null).assertTrue();
        expect(snapshotter.getLayer('missing-layer') === null).assertTrue();
        expect(snapshotter.getSource('missing-source') === null).assertTrue();
        snapshotter.cancel();
      });

      it('should add image from raw pixel buffer', 0, async () => {
        const snapshotter = createStyledSnapshotter();
        expect(await awaitStyleLoaded(snapshotter)).assertTrue();

        const width = 2;
        const height = 2;
        const buffer = new ArrayBuffer(width * height * 4);
        const pixels = new Uint8Array(buffer);
        for (let i = 0; i < pixels.length; i++) {
          pixels[i] = 255;
        }

        let added = true;
        try {
          snapshotter.addImage('test-image', buffer, width, height, 1.0, false);
        } catch (e) {
          hilog.error(DOMAIN, TAG, `addImage failed: ${e}`);
          added = false;
        }
        expect(added).assertTrue();
        snapshotter.cancel();
      });

      it('should reject raw buffer with mismatched size', 0, async () => {
        const snapshotter = createStyledSnapshotter();
        expect(await awaitStyleLoaded(snapshotter)).assertTrue();

        const buffer = new ArrayBuffer(4); // too small for a 2x2 RGBA image
        let threw = false;
        try {
          snapshotter.addImage('bad-image', buffer, 2, 2, 1.0, false);
        } catch (e) {
          threw = true;
        }
        expect(threw).assertTrue();
        snapshotter.cancel();
      });
    });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise<void>(resolve => setTimeout(resolve, ms));
}
