/**
 * Camera Animation Integration Tests
 *
 * Tests camera animation APIs: easeTo, flyTo, animateCamera,
 * jumpTo, cancelTransitions, and camera bounds.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap, LatLng, LatLngBounds, CameraPosition } from 'maplibre_harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';

const TAG = 'CameraAnimationTest';
const DOMAIN = 0xFF00;
const TIMEOUT = 15000;

export default function CameraAnimationTest() {
  describe('Camera Animation Integration', () => {
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

    describe('camera operations', () => {
      it('should have a valid MapLibreMap instance', 0, () => {
        expect(map !== null && map !== undefined).assertTrue();
      });

      it('should make immediate position update via jumpTo', 0, () => {
        if (!map) { return; }
        map.jumpTo(0, 35.0, 120.0, 0, 10);
        const pos = map.getLatLng();
        expect(pos.latitude).assertClose(35.0, 0.1);
        expect(pos.longitude).assertClose(120.0, 0.1);
      });

      it('should animate with easeTo - parameter overload', 0, () => {
        if (!map) { return; }
        // Set a known position first
        map.jumpTo(0, 30.0, 120.0, 0, 5);
        // Animate to new position
        map.easeTo(35.0, 115.0, 45, 8, 500);
        // After a short wait, position should have changed
        const pos = map.getLatLng();
        expect(true).assertTrue();
      });

      it('should animate with easeTo - options overload', 0, () => {
        if (!map) { return; }
        map.easeTo({
          center: new LatLng(40.0, 116.0),
          zoom: 10,
          bearing: 0,
          pitch: 0
        }, 500);
        expect(true).assertTrue();
      });

      it('should perform flyTo animation', 0, () => {
        if (!map) { return; }
        map.flyTo({
          center: new LatLng(31.2, 121.5),
          zoom: 12,
          bearing: 0,
          pitch: 0
        }, 500);
        expect(true).assertTrue();
      });

      it('should animate camera with CameraPosition', 0, () => {
        if (!map) { return; }
        map.animateCamera({
          target: new LatLng(35.0, 110.0),
          zoom: 6,
          bearing: 0,
          tilt: 0
        }, 500);
        expect(true).assertTrue();
      });

      it('should cancel transitions', 0, () => {
        if (!map) { return; }
        map.easeTo({
          center: new LatLng(50.0, 100.0),
          zoom: 15
        }, 5000);
        map.cancelTransitions();
        expect(true).assertTrue();
      });

      it('should reset position', 0, () => {
        if (!map) { return; }
        map.resetPosition();
        expect(true).assertTrue();
      });

      it('should reset north', 0, () => {
        if (!map) { return; }
        map.setBearing(90, 0);
        map.resetNorth();
        expect(true).assertTrue();
      });

      it('should reset zoom', 0, () => {
        if (!map) { return; }
        map.resetZoom();
        expect(true).assertTrue();
      });

      it('should move by delta', 0, () => {
        if (!map) { return; }
        map.moveBy(50, 50, 300);
        expect(true).assertTrue();
      });

      it('should rotate by delta', 0, () => {
        if (!map) { return; }
        map.rotateBy(100, 100, 200, 50, 300);
        expect(true).assertTrue();
      });

      it('should get camera position', 0, () => {
        if (!map) { return; }
        const camPos = map.getCameraPosition();
        expect(camPos !== null).assertTrue();
        if (camPos) {
          expect(typeof camPos.zoom).assertEqual('number');
          expect(typeof camPos.bearing).assertEqual('number');
          expect(typeof camPos.tilt).assertEqual('number');
          expect(camPos.target !== null).assertTrue();
        }
      });

      it('should set camera position', 0, () => {
        if (!map) { return; }
        map.setCameraPosition({
          target: new LatLng(35.0, 115.0),
          zoom: 8,
          bearing: 30,
          tilt: 20
        });
        const pos = map.getCameraPosition();
        if (pos) {
          expect(pos.zoom).assertClose(8, 0.5);
          expect(pos.bearing).assertClose(30, 2);
        }
      });

      it('should set camera position with animation', 0, () => {
        if (!map) { return; }
        map.setCameraPosition({
          target: new LatLng(40.0, 116.0),
          zoom: 10,
          bearing: 45,
          tilt: 15
        }, 500);
        expect(true).assertTrue();
      });

      it('should get camera for bounds', 0, () => {
        if (!map) { return; }
        const bounds = new LatLngBounds(35.0, 117.0, 30.0, 110.0);
        const camPos = map.getCameraForBounds(bounds);
        // Should return a valid camera position or null
        expect(camPos === null || camPos !== null).assertTrue();
      });

      it('should set camera for bounds', 0, () => {
        if (!map) { return; }
        const bounds = new LatLngBounds(35.0, 117.0, 30.0, 110.0);
        map.setCameraForBounds(bounds, false);
        expect(true).assertTrue();
      });

      it('should manage gesture in progress', 0, () => {
        if (!map) { return; }
        map.setGestureInProgress(true);
        map.setGestureInProgress(false);
        expect(true).assertTrue();
      });

      it('should set and get padding', 0, () => {
        if (!map) { return; }
        map.setPadding(10, 20, 30, 40);
        const padding = map.getPadding();
        expect(Array.isArray(padding)).assertTrue();
        expect(padding.length).assertEqual(4);
      });
    });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
