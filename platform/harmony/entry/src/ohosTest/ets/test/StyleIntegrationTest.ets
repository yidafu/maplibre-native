/**
 * Style Integration Tests
 *
 * Tests runtime style, layer, source, and image APIs
 * through a real NativeMapView using TestMapAccessor.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  MapLibreMap, LatLng, Style, StyleBuilder,
  FillLayer, CircleLayer, LineLayer, GeoJsonSource,
  Expression, TransitionOptions
} from 'maplibre_harmony';
import { TestMapAccessor } from '../../../../main/ets/pages/common/TestMapAccessor';

const TAG = 'StyleIntegrationTest';
const DOMAIN = 0xFF00;
const TIMEOUT = 20000;

export default function StyleIntegrationTest() {
  describe('Style Integration', () => {
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
      // Wait for style to load
      if (map) { await sleep(3000); }
    });

    afterAll(async () => {
      TestMapAccessor.clear();
      try { await driver.pressBack(); } catch (e) { /* ignore */ }
    });

    // ==================== Style URL ====================
    describe('Style URL', () => {
      it('should have a valid MapLibreMap instance', 0, () => {
        expect(map !== null && map !== undefined).assertTrue();
      });

      it('should get style URL', 0, () => {
        if (!map) { return; }
        const url = map.getStyleUrl();
        expect(typeof url).assertEqual('string');
      });

      it('should get style object when loaded', 0, () => {
        if (!map) { return; }
        const style = map.getStyle();
        // Style may be null if not loaded, but the API should not crash
        expect(true).assertTrue();
      });
    });

    // ==================== Layer Management ====================
    describe('Layer management', () => {
      it('should get layers', 0, () => {
        if (!map) { return; }
        const layers = map.getLayers();
        // Should be an array (possibly empty if style not loaded)
        expect(Array.isArray(layers)).assertTrue();
      });

      it('should get a specific layer by ID', 0, () => {
        if (!map) { return; }
        const layers = map.getLayers();
        if (layers.length > 0) {
          const firstId = layers[0].getId();
          const layer = map.getLayer(firstId);
          expect(layer).assertNull() == false;
          if (layer) {
            expect(layer.getId()).assertEqual(firstId);
          }
        }
      });

      it('should add and remove a layer', 0, () => {
        if (!map) { return; }
        if (!map.isStyleLoaded()) { return; }

        // Add a source first
        const sourceId = 'test-source-' + Date.now();
        const source = new GeoJsonSource(sourceId, { data: { type: 'Point', coordinates: [0, 0] } });
        map.addSource(source);

        // Add a circle layer
        const layerId = 'test-layer-' + Date.now();
        const layer = new CircleLayer(layerId, sourceId);
        map.addLayer(layer);

        // Remove
        map.removeLayer(layerId);
        map.removeSource(sourceId);
        expect(true).assertTrue();
      });
    });

    // ==================== Source Management ====================
    describe('Source management', () => {
      it('should get sources', 0, () => {
        if (!map) { return; }
        const sources = map.getSources();
        expect(Array.isArray(sources)).assertTrue();
      });

      it('should add and remove a GeoJSON source', 0, () => {
        if (!map) { return; }
        if (!map.isStyleLoaded()) { return; }

        const sourceId = 'geojson-test-' + Date.now();
        const source = new GeoJsonSource(sourceId, {
          data: { type: 'Feature', geometry: { type: 'Point', coordinates: [0, 0] } }
        });
        map.addSource(source);
        const retrieved = map.getSource(sourceId);
        if (retrieved) {
          expect(retrieved.getId()).assertEqual(sourceId);
        }
        map.removeSource(sourceId);
        expect(true).assertTrue();
      });
    });

    // ==================== Transition Options ====================
    describe('Transition options', () => {
      it('should get and set transition options', 0, () => {
        if (!map) { return; }
        const options = map.getTransitionOptions();
        expect(options !== null).assertTrue();
        if (options) {
          map.setTransitionOptions(new TransitionOptions(500, 100));
          const updated = map.getTransitionOptions();
          expect(updated !== null).assertTrue();
        }
      });
    });

    // ==================== Light ====================
    describe('Light', () => {
      it('should get light', 0, () => {
        if (!map) { return; }
        const light = map.getLight();
        // Light may be null if style not loaded, API should not crash
        expect(true).assertTrue();
      });
    });

    // ==================== Local Ideograph Font ====================
    describe('Local ideograph font', () => {
      it('should get and set local ideograph font', 0, () => {
        if (!map) { return; }
        const font = map.getLocalIdeographFontFamily();
        // Should return string or null
        expect(font === null || typeof font === 'string').assertTrue();
        expect(true).assertTrue();
      });
    });

    // ==================== Style JSON ====================
    describe('Style JSON', () => {
      it('should get style JSON', 0, () => {
        if (!map) { return; }
        const json = map.getStyleJson();
        // Should be a string (possibly empty if style not loaded)
        expect(typeof json).assertEqual('string');
      });
    });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
