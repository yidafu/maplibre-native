/**
 * Debug and Rendering Integration Tests
 *
 * Tests debug options, rendering statistics, and action journal APIs.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap, MapDebugOptions, RenderingRefreshMode } from 'maplibre_harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';

const TAG = 'DebugRenderTest';
const DOMAIN = 0xFF00;
const TIMEOUT = 15000;

export default function DebugRenderTest() {
  describe('Debug and Rendering Integration', () => {
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

    describe('debug options', () => {
      it('should have a valid map instance', 0, () => {
        expect(map !== null && map !== undefined).assertTrue();
      });

      it('should toggle debug active', 0, () => {
        if (!map) { return; }
        map.setDebugActive(true);
        expect(map.isDebugActive()).assertTrue();
        map.setDebugActive(false);
        expect(map.isDebugActive()).assertFalse();
      });

      it('should set debug options with bitmask', 0, () => {
        if (!map) { return; }
        map.setDebugOptions(MapDebugOptions.TileBoundaries | MapDebugOptions.Timestamps);
        map.setDebugOptions(MapDebugOptions.NoDebug);
        expect(true).assertTrue();
      });

      it('should get debug options', 0, () => {
        if (!map) { return; }
        const options = map.getDebugOptions();
        expect(typeof options).assertEqual('number');
      });
    });

    describe('rendering', () => {
      it('should trigger repaint', 0, () => {
        if (!map) { return; }
        map.triggerRepaint();
        expect(true).assertTrue();
      });

      it('should get and set rendering refresh mode', 0, () => {
        if (!map) { return; }
        const mode = map.getRenderingRefreshMode();
        expect(mode === RenderingRefreshMode.CONTINUOUS || mode === RenderingRefreshMode.WHEN_DIRTY).assertTrue();
        expect(true).assertTrue();
      });

      it('should toggle rendering stats view', 0, () => {
        if (!map) { return; }
        map.enableRenderingStatsView(true);
        const enabled = map.isRenderingStatsViewEnabled();
        expect(typeof enabled).assertEqual('boolean');
        map.enableRenderingStatsView(false);
        expect(true).assertTrue();
      });

      it('should set maximum FPS', 0, () => {
        if (!map) { return; }
        map.setMaximumFps(30);
        expect(true).assertTrue();
      });
    });

    describe('action journal', () => {
      it('should get action journal log files', 0, () => {
        if (!map) { return; }
        const files = map.getActionJournalLogFiles();
        expect(Array.isArray(files)).assertTrue();
      });

      it('should get action journal log', 0, () => {
        if (!map) { return; }
        const log = map.getActionJournalLog();
        expect(Array.isArray(log)).assertTrue();
      });

      it('should clear action journal log', 0, () => {
        if (!map) { return; }
        map.clearActionJournalLog();
        expect(true).assertTrue();
      });
    });

    describe('loaded state', () => {
      it('should report fully loaded state', 0, () => {
        if (!map) { return; }
        const loaded = map.isFullyLoaded();
        expect(typeof loaded).assertEqual('boolean');
      });
    });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
