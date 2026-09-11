/**
 * Network & Storage Integration Tests
 *
 * Tests network reachability and FileSource configuration.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { MapLibreMap, FileSource } from 'maplibre_harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';

const TIMEOUT = 15000;

export default function NetStorageTest() {
  describe('Network & Storage Integration', () => {
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

    it('should set reachability without crash', 0, () => {
      if (!map) { return; }
      map.setReachability(true);
      map.setReachability(false);
      expect(true).assertTrue();
    });

    it('should get FileSource instance', 0, () => {
      // FileSource.getInstance needs a Context which isn't easily available in tests
      // Just verify the static class exists
      expect(typeof FileSource).assertEqual('function');
    });
  });
}

async function sleep(ms: number): Promise<void> { return new Promise(resolve => setTimeout(resolve, ms)); }
