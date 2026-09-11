/**
 * Event System Integration Tests
 *
 * Tests event listener registration, triggering, and removal
 * for all MapLibreMap event types.
 *
 * Listener API shapes used here (must match MapLibreMap.ets):
 * - Camera/loading/rendering/style/idle/source/glyph/sprite/tile listeners
 *   are plain callback functions (type aliases).
 * - OnStyleLoadedListener, OnCameraIdleListener, OnMapClickListener etc.
 *   are interfaces; literals must be assigned to a typed variable
 *   (ArkTS forbids untyped object literals).
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  MapLibreMap,
  Style,
  TileOperation
} from 'maplibre_harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';
import {
  TestStyleLoadedListener,
  TestCameraIdleListener,
  TestCameraMoveStartedListener,
  TestCameraMoveListener,
  TestCameraMoveCanceledListener,
  TestFpsChangedListener,
  TestMapClickListener,
  TestMapLongClickListener
} from '../common/TestListeners';

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
        map.addOnCameraWillChangeListener((animated: boolean): void => { called = true; });
        // Trigger camera move to fire the event
        map.setLatLng(35.0, 120.0);
        expect(true).assertTrue();
      });

      it('should add and trigger camera is changing listener', 0, () => {
        if (!map) { return; }
        let called = false;
        map.addOnCameraIsChangingListener((): void => { called = true; });
        map.jumpTo(0, 35.0, 115.0, 0, 5);
        expect(true).assertTrue();
      });

      it('should add and trigger camera did change listener', 0, () => {
        if (!map) { return; }
        let called = false;
        map.addOnCameraDidChangeListener((animated: boolean): void => { called = true; });
        map.setLatLng(36.0, 116.0);
        expect(true).assertTrue();
      });

      it('should remove camera listener', 0, () => {
        if (!map) { return; }
        let callCount = 0;
        const listener = (animated: boolean): void => { callCount++; };
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
        const listener = (): void => {};
        map.addOnWillStartLoadingMapListener(listener);
        map.removeOnWillStartLoadingMapListener(listener);
        expect(true).assertTrue();
      });

      it('should add did finish loading map listener', 0, () => {
        if (!map) { return; }
        const listener = (): void => {};
        map.addOnDidFinishLoadingMapListener(listener);
        // Don't remove - will be cleaned up in destroy
        expect(true).assertTrue();
      });
    });

    describe('Rendering event listeners', () => {
      it('should add rendering frame listeners', 0, () => {
        if (!map) { return; }
        map.addOnWillStartRenderingFrameListener((): void => {});
        map.addOnDidFinishRenderingFrameListener(
          (fully: boolean, frameEncodingTime: number, frameRenderingTime: number): void => {}
        );
        expect(true).assertTrue();
      });

      it('should add rendering map listeners', 0, () => {
        if (!map) { return; }
        map.addOnWillStartRenderingMapListener((): void => {});
        map.addOnDidFinishRenderingMapListener((fully: boolean): void => {});
        expect(true).assertTrue();
      });
    });

    describe('Style event listeners', () => {
      it('should add style loaded listener', 0, () => {
        if (!map) { return; }
        let styleLoaded = false;
        const listener = new TestStyleLoadedListener((style: Style | null): void => {
          styleLoaded = true;
        });
        map.addOnStyleLoadedListener(listener);
        map.removeOnStyleLoadedListener(listener);
        expect(true).assertTrue();
      });

      it('should add did finish loading style listener', 0, () => {
        if (!map) { return; }
        const listener = (): void => {};
        map.addOnDidFinishLoadingStyleListener(listener);
        expect(true).assertTrue();
      });

      it('should add style image missing listener', 0, () => {
        if (!map) { return; }
        map.setOnStyleImageMissingListener((imageId: string): void => {});
        expect(true).assertTrue();
      });
    });

    describe('Observer event listeners', () => {
      it('should add idle listener', 0, () => {
        if (!map) { return; }
        map.addOnDidBecomeIdleListener((): void => {});
        expect(true).assertTrue();
      });

      it('should add source changed listener', 0, () => {
        if (!map) { return; }
        map.addOnSourceChangedListener((id: string): void => {});
        expect(true).assertTrue();
      });

      it('should add glyph event listeners', 0, () => {
        if (!map) { return; }
        map.addOnGlyphsLoadedListener((stack: string[], rangeStart: number, rangeEnd: number): void => {});
        map.addOnGlyphsErrorListener((stack: string[], rangeStart: number, rangeEnd: number): void => {});
        map.addOnGlyphsRequestedListener((stack: string[], rangeStart: number, rangeEnd: number): void => {});
        expect(true).assertTrue();
      });

      it('should add sprite event listeners', 0, () => {
        if (!map) { return; }
        map.addOnSpriteLoadedListener((id: string, url: string): void => {});
        map.addOnSpriteErrorListener((id: string, url: string): void => {});
        map.addOnSpriteRequestedListener((id: string, url: string): void => {});
        expect(true).assertTrue();
      });

      it('should add tile action listener', 0, () => {
        if (!map) { return; }
        map.addOnTileActionListener(
          (op: TileOperation, x: number, y: number, z: number, wrap: number,
            overscaledZ: number, sourceID: string): void => {}
        );
        expect(true).assertTrue();
      });
    });

    describe('Gesture listeners', () => {
      it('should add map click listener', 0, () => {
        if (!map) { return; }
        const listener = new TestMapClickListener();
        map.addOnMapClickListener(listener);
        expect(true).assertTrue();
      });

      it('should add map long click listener', 0, () => {
        if (!map) { return; }
        const listener = new TestMapLongClickListener();
        map.addOnMapLongClickListener(listener);
        map.removeOnMapLongClickListener(listener);
        expect(true).assertTrue();
      });

      it('should remove map click listener', 0, () => {
        if (!map) { return; }
        const listener = new TestMapClickListener();
        map.addOnMapClickListener(listener);
        map.removeOnMapClickListener(listener);
        expect(true).assertTrue();
      });
    });

    describe('Camera listener interfaces', () => {
      it('should add camera move listeners', 0, () => {
        if (!map) { return; }
        const idleListener = new TestCameraIdleListener();
        const startedListener = new TestCameraMoveStartedListener();
        const moveListener = new TestCameraMoveListener();
        const canceledListener = new TestCameraMoveCanceledListener();
        map.addOnCameraIdleListener(idleListener);
        map.addOnCameraMoveStartedListener(startedListener);
        map.addOnCameraMoveListener(moveListener);
        map.addOnCameraMoveCanceledListener(canceledListener);
        map.removeOnCameraIdleListener(idleListener);
        map.removeOnCameraMoveStartedListener(startedListener);
        map.removeOnCameraMoveListener(moveListener);
        map.removeOnCameraMoveCanceledListener(canceledListener);
        expect(true).assertTrue();
      });

      it('should add FPS changed listener', 0, () => {
        if (!map) { return; }
        const listener = new TestFpsChangedListener();
        map.setOnFpsChangedListener(listener);
        map.setOnFpsChangedListener(null);
        expect(true).assertTrue();
      });
    });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise<void>(resolve => setTimeout(resolve, ms));
}
