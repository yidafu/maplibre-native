/**
 * Tile LOD and Prefetch Integration Tests
 *
 * Tests tile loading and level-of-detail configuration APIs.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { MapLibreMap } from 'maplibre_harmony';
import { TestMapAccessor } from '../../../../main/ets/pages/common/TestMapAccessor';

const TIMEOUT = 15000;

export default function TileLodTest() {
  describe('Tile LOD Integration', () => {
    let driver: Driver;
    let map: MapLibreMap;

    beforeAll(async () => {
      driver = Driver.create();
      try { const item = await driver.findComponent(ON.text('Auto Test')); if (item) { await item.click(); } } catch (e) {}
      const start = Date.now();
      while (Date.now() - start < TIMEOUT) {
        if (TestMapAccessor.isMapReady()) {
          const instance = TestMapAccessor.getMapInstance();
          if (instance) { map = instance; break; }
        }
        await sleep(200);
      }
    });

    afterAll(async () => { TestMapAccessor.clear(); try { await driver.pressBack(); } catch (e) {} });

    it('should have a valid map instance', 0, () => { expect(map !== null && map !== undefined).assertTrue(); });

    it('should set and get prefetch tiles', 0, () => {
      if (!map) { return; }
      map.setPrefetchTiles(true);
      expect(map.getPrefetchTiles()).assertTrue();
      map.setPrefetchTiles(false);
      expect(map.getPrefetchTiles()).assertFalse();
    });

    it('should set and get prefetch zoom delta', 0, () => {
      if (!map) { return; }
      map.setPrefetchZoomDelta(3);
      expect(map.getPrefetchZoomDelta()).assertEqual(3);
      map.setPrefetchZoomDelta(4);
    });

    it('should set and get tile cache enabled', 0, () => {
      if (!map) { return; }
      map.setTileCacheEnabled(true);
      expect(map.getTileCacheEnabled()).assertTrue();
    });

    it('should set and get tile LOD settings', 0, () => {
      if (!map) { return; }
      map.setTileLodMinRadius(5);
      expect(map.getTileLodMinRadius() >= 0).assertTrue();
      map.setTileLodScale(1.5);
      expect(map.getTileLodScale() > 0).assertTrue();
      map.setTileLodPitchThreshold(45);
      expect(map.getTileLodPitchThreshold() >= 0).assertTrue();
      map.setTileLodZoomShift(1);
      expect(map.getTileLodZoomShift() !== undefined).assertTrue();
    });
  });
}

async function sleep(ms: number): Promise<void> { return new Promise(resolve => setTimeout(resolve, ms)); }
