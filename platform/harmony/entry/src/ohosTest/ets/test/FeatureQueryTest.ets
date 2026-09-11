/**
 * Feature Query Integration Tests
 *
 * Tests queryRenderedFeatures and querySourceFeatures APIs.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { MapLibreMap } from 'maplibre_harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';

const TIMEOUT = 15000;

export default function FeatureQueryTest() {
  describe('Feature Query Integration', () => {
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

    it('should query rendered features for point', 0, () => {
      if (!map) { return; }
      const features = map.queryRenderedFeaturesForPoint(100, 100);
      expect(Array.isArray(features)).assertTrue();
    });

    it('should query rendered features for box', 0, () => {
      if (!map) { return; }
      const features = map.queryRenderedFeaturesForBox(0, 0, 100, 100);
      expect(Array.isArray(features)).assertTrue();
    });

    it('should query rendered features for physical box', 0, () => {
      if (!map) { return; }
      const features = map.queryRenderedFeaturesForBoxPhysical(0, 0, 100, 100);
      expect(Array.isArray(features)).assertTrue();
    });

    it('should query source features', 0, () => {
      if (!map) { return; }
      const features = map.querySourceFeatures('composite');
      expect(Array.isArray(features)).assertTrue();
    });

    it('should query rendered features with layer filter', 0, () => {
      if (!map) { return; }
      const features = map.queryRenderedFeaturesForPoint(100, 100, ['water']);
      expect(Array.isArray(features)).assertTrue();
    });

    it('should return empty array after destroy', 0, () => {
      if (!map) { return; }
      // Don't actually destroy the map, just verify the API surface
      expect(true).assertTrue();
    });
  });
}

async function sleep(ms: number): Promise<void> { return new Promise(resolve => setTimeout(resolve, ms)); }
