/**
 * Upstream Source API Integration Tests
 *
 * On-device verification for three APIs ported from upstream (Android/iOS):
 * 1. Source-level feature state sugar (GeoJsonSource/VectorSource,
 *    mirroring Android GeoJsonSource/VectorSource wrappers)
 * 2. GeoJsonSource.setOverrideSynchronousUpdate (upstream #4366)
 * 3. LocationComponent bearingOnTop layer-stack option (upstream #4408)
 *
 * Uses the shared AutomationTestPage map via TestMapAccessor.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { ensureAppFront, ensureAutomationPage, sleep } from '../common/UiTestHelpers';
import { Driver } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  MapLibreMap, GeoJsonSource, VectorSource, Layer, CircleLayer,
  LocationComponent, LocationComponentOptions,
  LocationComponentConstants
} from 'maplibre-harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';

const TAG = 'SourceApiIntegrationTest';
const DOMAIN = 0xFF00;
const MAP_LOAD_TIMEOUT = 15000;

/**
 * Feature-state payload type. The ohosTest compile cannot resolve the
 * `JSONValue` type from 'libmaplibre.so' (module types are only wired into the
 * main module build), so tests build states from this compatible union.
 */
type FeatureStateValue = string | number | boolean;

/** Index of a layer id inside an ordered layer list, or -1. */
function layerIndex(layers: Layer[], id: string): number {
  for (let i = 0; i < layers.length; i++) {
    if (layers[i].getId() === id) {
      return i;
    }
  }
  return -1;
}

export default function SourceApiIntegrationTest() {
  describe('Upstream Source APIs Integration', () => {
    let map: MapLibreMap | null = null;
    let locationReady = false;

    beforeAll(async () => {
      const driver = Driver.create();
      await ensureAppFront(driver);
      hilog.info(DOMAIN, TAG, 'Starting upstream source API tests');

      await ensureAutomationPage(driver);

      const startTime = Date.now();
      while (Date.now() - startTime < MAP_LOAD_TIMEOUT) {
        if (TestMapAccessor.isMapReady()) {
          map = TestMapAccessor.getMapInstance();
          if (map) {
            break;
          }
        }
        await sleep(200);
      }
      if (!map) {
        hilog.error(DOMAIN, TAG, 'Failed to acquire MapLibreMap instance');
      }
    });

    afterAll(async () => {
      TestMapAccessor.clear();
    });

    // ==================== Feature state: detached sources ====================
    describe('feature state detached', () => {
      it('geojson sugar returns false/undefined before addSource', 0, () => {
        if (!map) { return; }
        const src = new GeoJsonSource('fs-detached-geojson');
        const state: Record<string, FeatureStateValue> = { 'selected': true };
        expect(src.setFeatureState('f1', state)).assertFalse();
        expect(src.getFeatureState('f1')).assertUndefined();
        expect(src.removeFeatureState('f1')).assertFalse();
        expect(src.removeFeatureState()).assertFalse();
        expect(src.resetFeatureStates()).assertFalse();
      });

      it('vector sugar returns false/undefined before addSource', 0, () => {
        if (!map) { return; }
        const src = new VectorSource('fs-detached-vector');
        const state: Record<string, FeatureStateValue> = { 'open': true };
        expect(src.setFeatureState('roads', 'f1', state)).assertFalse();
        expect(src.getFeatureState('roads', 'f1')).assertUndefined();
        expect(src.removeFeatureState('roads', 'f1')).assertFalse();
        expect(src.resetFeatureStates('roads')).assertFalse();
      });
    });

    // ==================== Feature state: GeoJsonSource bound ====================
    describe('feature state geojson', () => {
      const GEOJSON = '{"type":"FeatureCollection","features":[{"type":"Feature",'
        + '"id":"fs-feature-1","geometry":{"type":"Point","coordinates":[0,0]},'
        + '"properties":{"name":"probe"}}]}';

      it('setFeatureState round-trips through the map', 0, async () => {
        if (!map) { return; }
        const src = new GeoJsonSource('fs-geojson-src');
        src.setGeoJson(GEOJSON);
        map.addSource(src);
        // Attach a layer so the render source is enabled: without a
        // referencing layer prepare() never runs and removes/resets are
        // never coalesced (upstream core behavior, matches Android).
        const circle = new CircleLayer('fs-geojson-circle', 'fs-geojson-src');
        map.getStyle()?.addLayer(circle);
        // RenderOrchestrator creates the render source on the next frame;
        // feature state dispatch is a no-op before that.
        await sleep(600);

        const state: Record<string, FeatureStateValue> = { 'selected': true, 'priority': 7 };
        expect(src.setFeatureState('fs-feature-1', state)).assertTrue();

        const got = src.getFeatureState('fs-feature-1');
        expect(got !== undefined && got !== null).assertTrue();
        if (got) {
          let selOk = false;
          const sel = got['selected'];
          if (typeof sel === 'boolean') {
            selOk = sel as boolean;
          }
          expect(selOk).assertTrue();
        }
      });

      it('removeFeatureState clears a single key', 0, async () => {
        if (!map) { return; }
        const src = map.getSource('fs-geojson-src');
        expect(src instanceof GeoJsonSource).assertTrue();
        if (!(src instanceof GeoJsonSource)) { return; }

        expect(src.removeFeatureState('fs-feature-1', 'selected')).assertTrue();
        // removeState is coalesced into the current state on the next prepare tick
        await sleep(600);
        const got = src.getFeatureState('fs-feature-1');
        // priority may survive; selected must be gone
        if (got) {
          expect(got['selected']).assertUndefined();
        }
      });

      it('resetFeatureStates clears everything', 0, async () => {
        if (!map) { return; }
        const src = map.getSource('fs-geojson-src');
        if (!(src instanceof GeoJsonSource)) { return; }

        const state: Record<string, FeatureStateValue> = { 'again': true };
        expect(src.setFeatureState('fs-feature-1', state)).assertTrue();
        expect(src.resetFeatureStates()).assertTrue();
        await sleep(600);

        const got = src.getFeatureState('fs-feature-1');
        if (got) {
          expect(got['again']).assertUndefined();
        }
      });

      it('removeSource unbinds the feature state host', 0, () => {
        if (!map) { return; }
        const src = map.getSource('fs-geojson-src');
        expect(src !== null && src !== undefined).assertTrue();
        if (!src) { return; }
        // Detach the layer first; a source still referenced by layers
        // cannot be removed.
        map.getStyle()?.removeLayer('fs-geojson-circle');
        expect(map.removeSource(src)).assertTrue();
        if (src instanceof GeoJsonSource) {
          // Host cleared: sugar falls back to detached behavior
          const state: Record<string, FeatureStateValue> = { 'x': 1 };
          expect(src.setFeatureState('fs-feature-1', state)).assertFalse();
          expect(src.getFeatureState('fs-feature-1')).assertUndefined();
        }
      });
    });

    // ==================== Feature state: VectorSource bound ====================
    describe('feature state vector', () => {
      it('bound vector source dispatches without tiles loaded', 0, () => {
        if (!map) { return; }
        const src = new VectorSource('fs-vector-src');
        src.setUrl('https://example.invalid/tiles.json');
        map.addSource(src);

        // No layers reference the source, so no tiles load; dispatch itself
        // must succeed (Android returns true regardless of feature presence).
        const state: Record<string, FeatureStateValue> = { 'open': true };
        expect(src.setFeatureState('buildings', 'fs-1', state)).assertTrue();
        // Feature absent from any loaded tile -> no state returned.
        expect(src.getFeatureState('buildings', 'fs-1')).assertUndefined();
        expect(src.removeFeatureState('buildings', 'fs-1')).assertTrue();
        expect(src.removeFeatureState('buildings')).assertTrue();
        expect(src.resetFeatureStates('buildings')).assertTrue();

        expect(map.removeSource(src)).assertTrue();
      });
    });

    // ==================== setOverrideSynchronousUpdate ====================
    describe('setOverrideSynchronousUpdate', () => {
      it('chainable and throwable-free on detached source', 0, () => {
        const src = new GeoJsonSource('sync-src');
        const ret = src.setOverrideSynchronousUpdate(true);
        expect(ret === src).assertTrue();
        expect(src.setOverrideSynchronousUpdate(false) === src).assertTrue();
      });

      it('callable after the source is added and source stays usable', 0, async () => {
        if (!map) { return; }
        const src = new GeoJsonSource('sync-src-bound');
        src.setGeoJson('{"type":"FeatureCollection","features":[{"type":"Feature",'
          + '"id":"sync-1","geometry":{"type":"Point","coordinates":[0,0]},'
          + '"properties":{}}]}');
        map.addSource(src);

        src.setOverrideSynchronousUpdate(true);
        // Source still functional after the override flips
        expect(src.getFeatureState('sync-1')).assertUndefined();
        const state: Record<string, FeatureStateValue> = { 'n': 1 };
        expect(src.setFeatureState('sync-1', state)).assertTrue();

        map.removeSource(src);
      });
    });

    // ==================== LocationComponent bearingOnTop ====================
    describe('location bearingOnTop stack', () => {
      let component: LocationComponent | undefined = undefined;

      it('activate with default options stacks bearing on top', 0, async () => {
        if (!map) { return; }
        component = map.getLocationComponent();
        await component.activateLocationComponent(new LocationComponentOptions());
        locationReady = true;

        const layers = map.getStyle()?.getLayers() ?? [];
        const fg = layerIndex(layers, LocationComponentConstants.FOREGROUND_LAYER);
        const bearing = layerIndex(layers, LocationComponentConstants.BEARING_LAYER);
        hilog.info(DOMAIN, TAG, `layer order (default): fg=${fg} bearing=${bearing} of ${layers.length}`);
        expect(fg >= 0 && bearing >= 0).assertTrue();
        // bearingOnTop=true (default): bearing above foreground
        expect(bearing > fg).assertTrue();
      });

      it('applyStyle with bearingOnTop=false restacks bearing to the bottom', 0, () => {
        if (!map || !locationReady || !component) { return; }
        const opts = component.getLocationComponentOptions().toBuilder()
          .setBearingOnTop(false)
          .build();
        component.applyStyle(opts);
        expect(component.getLocationComponentOptions().bearingOnTop).assertFalse();

        const layers = map.getStyle()?.getLayers() ?? [];
        const bg = layerIndex(layers, LocationComponentConstants.BACKGROUND_LAYER);
        const fg = layerIndex(layers, LocationComponentConstants.FOREGROUND_LAYER);
        const bearing = layerIndex(layers, LocationComponentConstants.BEARING_LAYER);
        hilog.info(DOMAIN, TAG, `layer order (bottom): bearing=${bearing} bg=${bg} fg=${fg}`);
        expect(bearing >= 0 && bg >= 0 && fg >= 0).assertTrue();
        // bearingOnTop=false: bearing below background below foreground
        expect(bearing < bg && bg < fg).assertTrue();
      });

      it('flipping back to true restacks bearing on top again', 0, () => {
        if (!map || !locationReady || !component) { return; }
        const opts = component.getLocationComponentOptions().toBuilder()
          .setBearingOnTop(true)
          .build();
        component.applyStyle(opts);
        expect(component.getLocationComponentOptions().bearingOnTop).assertTrue();

        const layers = map.getStyle()?.getLayers() ?? [];
        const bg = layerIndex(layers, LocationComponentConstants.BACKGROUND_LAYER);
        const fg = layerIndex(layers, LocationComponentConstants.FOREGROUND_LAYER);
        const bearing = layerIndex(layers, LocationComponentConstants.BEARING_LAYER);
        // bearingOnTop=true: background < foreground < bearing
        expect(bg < fg && fg < bearing).assertTrue();
      });

      it('all location layers and source survive restacking', 0, () => {
        if (!map || !locationReady) { return; }
        const style = map.getStyle();
        expect(style !== null && style !== undefined).assertTrue();
        if (!style) { return; }
        expect(style.getLayer(LocationComponentConstants.ACCURACY_LAYER) !== null).assertTrue();
        expect(style.getLayer(LocationComponentConstants.BACKGROUND_LAYER) !== null).assertTrue();
        expect(style.getLayer(LocationComponentConstants.FOREGROUND_LAYER) !== null).assertTrue();
        expect(style.getLayer(LocationComponentConstants.BEARING_LAYER) !== null).assertTrue();
        expect(style.getSource(LocationComponentConstants.LOCATION_SOURCE) !== null).assertTrue();
      });
    });
  });
}
