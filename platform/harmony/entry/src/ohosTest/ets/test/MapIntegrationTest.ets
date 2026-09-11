/**
 * MapLibreMap Integration Tests
 *
 * Tests the MapLibreMap API through a real NativeMapView.
 * These tests require a device/emulator with the native library.
 *
 * Test flow:
 * 1. Navigate to MapAutomationTestPage (via UiTest)
 * 2. Wait for TestMapAccessor to provide a MapLibreMap instance
 * 3. Call API methods and verify results
 * 4. Navigate back between tests
 */
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap, LatLng, CameraPosition } from 'maplibre_harmony';
// Import TestMapAccessor from the main app module
import { TestMapAccessor } from '../../../../main/ets/pages/common/TestMapAccessor';

const TAG = 'MapIntegrationTest';
const DOMAIN = 0xFF00;
const NAVIGATION_TIMEOUT = 15000;
const MAP_LOAD_TIMEOUT = 15000;
const ANIMATION_TIMEOUT = 3000;

export default function MapIntegrationTest() {
  describe('MapLibreMap API Integration', () => {
    let driver: Driver;
    let map: MapLibreMap;

    beforeAll(async () => {
      driver = Driver.create();
      hilog.info(DOMAIN, TAG, 'Starting MapLibreMap integration tests');

      // Step 1: Navigate to the Auto Test page from Index
      // Find the "Auto Test" text item and click it
      try {
        const autoTestItem = await driver.findComponent(ON.text('Auto Test'));
        if (autoTestItem) {
          await autoTestItem.click();
          hilog.info(DOMAIN, TAG, 'Clicked Auto Test in navigation');
        }
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Auto Test navigation failed (may already be on page): ' + error);
      }

      // Step 2: Wait for the map to be ready
      const startTime = Date.now();
      while (Date.now() - startTime < MAP_LOAD_TIMEOUT) {
        if (TestMapAccessor.isMapReady()) {
          const instance = TestMapAccessor.getMapInstance();
          if (instance) {
            map = instance;
            hilog.info(DOMAIN, TAG, 'Map instance acquired via TestMapAccessor');
            break;
          }
        }
        await sleep(200);
      }

      // Ensure the map was loaded
      if (!map) {
        hilog.error(DOMAIN, TAG, 'Failed to acquire MapLibreMap instance within timeout');
      }
    });

    afterAll(async () => {
      // Navigate back to Index page
      try {
        TestMapAccessor.clear();
        // Try to go back using system back
        await driver.pressBack();
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Cleanup error: ' + error);
      }
    });

    // ==================== Lifecycle ====================
    describe('lifecycle', () => {
      it('should have a valid MapLibreMap instance', 0, () => {
        expect(map !== null && map !== undefined).assertTrue();
      });

      it('should report map as not destroyed', 0, () => {
        if (map) {
          expect(map.isDestroyed()).assertFalse();
        }
      });
    });

    // ==================== Position & Zoom ====================
    describe('position and zoom', () => {
      it('should set and get camera position', 0, () => {
        if (!map) { return; }
        map.setLatLng(39.9, 116.4);
        const pos = map.getLatLng();
        expect(pos.latitude).assertClose(39.9, 0.01);
        expect(pos.longitude).assertClose(116.4, 0.01);
      });

      it('should set and get zoom level', 0, () => {
        if (!map) { return; }
        map.setZoom(10);
        const zoom = map.getZoom();
        expect(zoom).assertClose(10, 0.1);
      });

      it('should set and get bearing', 0, () => {
        if (!map) { return; }
        map.setBearing(45, 0);
        const bearing = map.getBearing();
        expect(bearing).assertClose(45, 1);
      });

      it('should set and get pitch', 0, () => {
        if (!map) { return; }
        map.setPitch(30, 0);
        const pitch = map.getPitch();
        expect(pitch).assertClose(30, 1);
      });

      it('should get camera state in one call', 0, () => {
        if (!map) { return; }
        map.setLatLng(35.0, 120.0);
        map.setZoom(8);
        map.setBearing(90, 0);
        map.setPitch(20, 0);

        const state = map.getCameraState();
        expect(state !== null).assertTrue();
        if (state) {
          expect(typeof state.latitude).assertEqual('number');
          expect(typeof state.longitude).assertEqual('number');
          expect(typeof state.zoom).assertEqual('number');
          expect(typeof state.bearing).assertEqual('number');
          expect(typeof state.pitch).assertEqual('number');
        }
      });
    });

    // ==================== Bounds ====================
    describe('bounds', () => {
      it('should get min/max zoom', 0, () => {
        if (!map) { return; }
        const minZoom = map.getMinZoom();
        const maxZoom = map.getMaxZoom();
        expect(typeof minZoom).assertEqual('number');
        expect(typeof maxZoom).assertEqual('number');
        expect(minZoom <= maxZoom).assertTrue();
      });

      it('should get min/max pitch', 0, () => {
        if (!map) { return; }
        const minPitch = map.getMinPitch();
        const maxPitch = map.getMaxPitch();
        expect(typeof minPitch).assertEqual('number');
        expect(typeof maxPitch).assertEqual('number');
        expect(minPitch <= maxPitch).assertTrue();
      });
    });

    // ==================== Projection ====================
    describe('projection', () => {
      it('should convert coordinate to pixel', 0, () => {
        if (!map) { return; }
        const latLng = map.getLatLng();
        const pixel = map.pixelForLatLng(latLng.latitude, latLng.longitude);
        expect(typeof pixel.x).assertEqual('number');
        expect(typeof pixel.y).assertEqual('number');
      });

      it('should convert pixel to coordinate', 0, () => {
        if (!map) { return; }
        const center = map.getLatLng();
        const pixel = map.pixelForLatLng(center.latitude, center.longitude);
        const latLng = map.latLngForPixel(pixel.x, pixel.y);
        expect(latLng.latitude).assertClose(center.latitude, 0.1);
        expect(latLng.longitude).assertClose(center.longitude, 0.1);
      });
    });

    // ==================== Style ====================
    describe('style', () => {
      it('should get style URL', 0, () => {
        if (!map) { return; }
        const url = map.getStyleUrl();
        expect(typeof url).assertEqual('string');
      });

      it('should report style loaded', 0, () => {
        if (!map) { return; }
        // isStyleLoaded may be true or false depending on timing
        const loaded = map.isStyleLoaded();
        expect(typeof loaded).assertEqual('boolean');
      });
    });

    // ==================== Meters per pixel ====================
    describe('meters per pixel', () => {
      it('should calculate meters per pixel', 0, () => {
        if (!map) { return; }
        const latLng = map.getLatLng();
        const mpp = map.getMetersPerPixelAtLatitude(latLng.latitude);
        expect(typeof mpp).assertEqual('number');
        expect(mpp > 0).assertTrue();
      });
    });

    // ==================== Memory & Debug ====================
    describe('memory and debug', () => {
      it('onLowMemory should not crash', 0, () => {
        if (!map) { return; }
        map.onLowMemory();
        expect(true).assertTrue();
      });
    });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
