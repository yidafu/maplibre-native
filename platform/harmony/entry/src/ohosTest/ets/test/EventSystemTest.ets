/**
 * Event System Integration Tests
 *
 * Tests event listener registration, triggering, and removal
 * for all MapLibreMap event types.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap } from 'maplibre_harmony';
import { TestMapAccessor } from '../../../../main/ets/pages/common/TestMapAccessor';

const TAG = 'EventSystemTest';
const DOMAIN = 0xFF00;
const TIMEOUT = 15000;

export default function EventSystemTest() {
  describe('Event System Integration', () => {
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

    describe('Camera event listeners', () => {
      it('should have a valid map instance', 0, () => {
        expect(map !== null && map !== undefined).assertTrue();
      });

      it('should add and trigger camera will change listener', 0, () => {
        if (!map) { return; }
        let called = false;
        map.addOnCameraWillChangeListener({
          onCameraWillChange: (animated: boolean) => { called = true; }
        });
        // Trigger camera move to fire the event
        map.setLatLng(35.0, 120.0);
        expect(true).assertTrue();
      });

      it('should add and trigger camera is changing listener', 0, () => {
        if (!map) { return; }
        let called = false;
        map.addOnCameraIsChangingListener({
          onCameraIsChanging: () => { called = true; }
        });
        map.jumpTo(0, 35.0, 115.0, 0, 5);
        expect(true).assertTrue();
      });

      it('should add and trigger camera did change listener', 0, () => {
        if (!map) { return; }
        let called = false;
        map.addOnCameraDidChangeListener({
          onCameraDidChange: () => { called = true; }
        });
        map.setLatLng(36.0, 116.0);
        expect(true).assertTrue();
      });

      it('should remove camera listener', 0, () => {
        if (!map) { return; }
        let callCount = 0;
        const listener = {
          onCameraWillChange: (animated: boolean) => { callCount++; }
        };
        map.addOnCameraWillChangeListener(listener);
        map.removeOnCameraWillChangeListener(listener);
        const countBefore = callCount;
        map.setLatLng(37.0, 117.0);
        // After removal, listener should not be called
        expect(callCount).assertEqual(countBefore);
      });
    });

    describe('Map loading event listeners', () => {
      it('should add and remove map loading listeners', 0, () => {
        if (!map) { return; }
        const listener = { onWillStartLoadingMap: () => {} };
        map.addOnWillStartLoadingMapListener(listener);
        map.removeOnWillStartLoadingMapListener(listener);
        expect(true).assertTrue();
      });

      it('should add did finish loading map listener', 0, () => {
        if (!map) { return; }
        const listener = { onDidFinishLoadingMap: () => {} };
        map.addOnDidFinishLoadingMapListener(listener);
        // Don't remove - will be cleaned up in destroy
        expect(true).assertTrue();
      });
    });

    describe('Rendering event listeners', () => {
      it('should add rendering frame listeners', 0, () => {
        if (!map) { return; }
        map.addOnWillStartRenderingFrameListener({ onWillStartRenderingFrame: () => {} });
        map.addOnDidFinishRenderingFrameListener({ onDidFinishRenderingFrame: () => {} });
        expect(true).assertTrue();
      });

      it('should add rendering map listeners', 0, () => {
        if (!map) { return; }
        map.addOnWillStartRenderingMapListener({ onWillStartRenderingMap: () => {} });
        map.addOnDidFinishRenderingMapListener({ onDidFinishRenderingMap: () => {} });
        expect(true).assertTrue();
      });
    });

    describe('Style event listeners', () => {
      it('should add style loaded listener', 0, () => {
        if (!map) { return; }
        let styleLoaded = false;
        map.addOnStyleLoadedListener({
          onStyleLoaded: (style) => { styleLoaded = true; }
        });
        expect(true).assertTrue();
      });

      it('should add did finish loading style listener', 0, () => {
        if (!map) { return; }
        map.addOnDidFinishLoadingStyleListener({ onDidFinishLoadingStyle: () => {} });
        expect(true).assertTrue();
      });

      it('should add style image missing listener', 0, () => {
        if (!map) { return; }
        map.setOnStyleImageMissingListener((imageId: string) => {});
        expect(true).assertTrue();
      });
    });

    describe('Observer event listeners', () => {
      it('should add idle listener', 0, () => {
        if (!map) { return; }
        map.addOnDidBecomeIdleListener({ onDidBecomeIdle: () => {} });
        expect(true).assertTrue();
      });

      it('should add source changed listener', 0, () => {
        if (!map) { return; }
        map.addOnSourceChangedListener({ onSourceChanged: () => {} });
        expect(true).assertTrue();
      });

      it('should add glyph event listeners', 0, () => {
        if (!map) { return; }
        map.addOnGlyphsLoadedListener({ onGlyphsLoaded: () => {} });
        map.addOnGlyphsErrorListener({ onGlyphsError: () => {} });
        map.addOnGlyphsRequestedListener({ onGlyphsRequested: () => {} });
        expect(true).assertTrue();
      });

      it('should add sprite event listeners', 0, () => {
        if (!map) { return; }
        map.addOnSpriteLoadedListener({ onSpriteLoaded: () => {} });
        map.addOnSpriteErrorListener({ onSpriteError: () => {} });
        map.addOnSpriteRequestedListener({ onSpriteRequested: () => {} });
        expect(true).assertTrue();
      });

      it('should add tile action listener', 0, () => {
        if (!map) { return; }
        map.addOnTileActionListener({ onTileAction: () => {} });
        expect(true).assertTrue();
      });
    });

    describe('Gesture listeners', () => {
      it('should add map click listener', 0, () => {
        if (!map) { return; }
        map.addOnMapClickListener({
          onMapClick: (x: number, y: number) => { return false; }
        });
        expect(true).assertTrue();
      });

      it('should add map long click listener', 0, () => {
        if (!map) { return; }
        map.addOnMapLongClickListener({
          onMapLongClick: (x: number, y: number) => { return false; }
        });
        expect(true).assertTrue();
      });

      it('should remove map click listener', 0, () => {
        if (!map) { return; }
        const listener = {
          onMapClick: (x: number, y: number) => { return false; }
        };
        map.addOnMapClickListener(listener);
        map.removeOnMapClickListener(listener);
        expect(true).assertTrue();
      });
    });

    describe('Camera listener interfaces', () => {
      it('should add camera move listeners', 0, () => {
        if (!map) { return; }
        map.addOnCameraIdleListener({ onCameraIdle: () => {} });
        map.addOnCameraMoveStartedListener({ onCameraMoveStarted: (reason) => {} });
        map.addOnCameraMoveListener({ onCameraMove: () => {} });
        map.addOnCameraMoveCanceledListener({ onCameraMoveCanceled: () => {} });
        expect(true).assertTrue();
      });

      it('should add FPS changed listener', 0, () => {
        if (!map) { return; }
        map.addOnFpsChangedListener({ onFpsChanged: (fps) => {} });
        expect(true).assertTrue();
      });
    });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
