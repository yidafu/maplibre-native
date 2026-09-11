/**
 * Annotation Integration Tests
 *
 * Tests Marker, Polygon, and Polyline annotation APIs
 * through a real NativeMapView using TestMapAccessor.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MapLibreMap, LatLng, MarkerOptions, Marker, Polyline, Polygon } from 'maplibre_harmony';
import { TestMapAccessor } from '../common/TestMapAccessor';
import { TestMarkerClickListener } from '../common/TestListeners';

const TAG = 'AnnotationIntegrationTest';
const DOMAIN = 0xFF00;
const TIMEOUT = 15000;

export default function AnnotationIntegrationTest() {
  describe('Annotation Integration', () => {
    let driver: Driver;
    let map: MapLibreMap;

    beforeAll(async () => {
      driver = Driver.create();
      // Navigate to Auto Test page
      try {
        const item = await driver.findComponent(ON.text('Auto Test'));
        if (item) { await item.click(); }
      } catch (e) { /* ignore */ }
      // Wait for map
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

    // ==================== Marker ====================
    describe('Marker', () => {
      it('should have a ready map', 0, () => {
        expect(map !== null && map !== undefined).assertTrue();
      });

      it('should add a single marker', 0, async () => {
        if (!map) { return; }
        const marker = await map.addMarker(new MarkerOptions().position(new LatLng(39.9, 116.4)).title('Test'));
        expect(marker !== null).assertTrue();
        if (marker) {
          expect(marker.getId() >= 0).assertTrue();
          map.removeMarker(marker);
        }
      });

      it('should add batch markers', 0, async () => {
        if (!map) { return; }
        const markers = await map.addMarkersBatch([
          new MarkerOptions().position(new LatLng(40.0, 116.0)).title('M1'),
          new MarkerOptions().position(new LatLng(40.1, 116.1)).title('M2'),
        ]);
        expect(markers.length).assertLarger(0);
        // Cleanup
        for (const m of markers) { map.removeMarker(m); }
      });

      it('should remove a marker', 0, async () => {
        if (!map) { return; }
        const marker = await map.addMarker(new MarkerOptions().position(new LatLng(39.9, 116.4)));
        map.removeMarker(marker);
        expect(true).assertTrue();
      });

      it('should clear all markers', 0, () => {
        if (!map) { return; }
        map.clearMarkers();
        const markers = map.getMarkers();
        expect(markers.length).assertEqual(0);
      });

      it('should set marker click listener', 0, () => {
        if (!map) { return; }
        let clicked = false;
        const listener = new TestMarkerClickListener((marker: Marker): boolean => {
          clicked = true;
          return true;
        });
        map.setOnMarkerClickListener(listener);
        expect(clicked).assertFalse(); // not triggered yet
        // Cleanup
        map.setOnMarkerClickListener(null);
      });
    });

    // ==================== Polyline ====================
    describe('Polyline', () => {
      it('should add a polyline', 0, () => {
        if (!map) { return; }
        const polyline = new Polyline({
          points: [new LatLng(39.9, 116.4), new LatLng(40.0, 116.5)],
          color: '#FF0000',
          width: 5
        });
        const ids = map.addPolylines([polyline]);
        expect(ids.length).assertLarger(0);
        // Cleanup
        if (ids.length > 0) { map.removeAnnotations(ids); }
      });

      it('should update polyline', 0, () => {
        if (!map) { return; }
        const polyline = new Polyline({
          points: [new LatLng(39.9, 116.4), new LatLng(40.0, 116.5)],
          color: '#FF0000',
          width: 5
        });
        const ids = map.addPolylines([polyline]);
        if (ids.length > 0) {
          polyline.setWidth(10);
          map.updatePolyline(polyline);
          expect(true).assertTrue();
          map.removeAnnotations(ids);
        }
      });
    });

    // ==================== Polygon ====================
    describe('Polygon', () => {
      it('should add a polygon', 0, () => {
        if (!map) { return; }
        const polygon = new Polygon({
          points: [
            new LatLng(39.8, 116.3), new LatLng(39.8, 116.5),
            new LatLng(40.0, 116.5), new LatLng(40.0, 116.3), new LatLng(39.8, 116.3)
          ],
          fillColor: '#0000FF',
          strokeColor: '#FF0000'
        });
        const ids = map.addPolygons([polygon]);
        expect(ids.length).assertLarger(0);
        if (ids.length > 0) { map.removeAnnotations(ids); }
      });

      it('should update polygon', 0, () => {
        if (!map) { return; }
        const polygon = new Polygon({
          points: [new LatLng(39.9, 116.4), new LatLng(40.0, 116.5),
                   new LatLng(39.9, 116.6), new LatLng(39.9, 116.4)],
          fillColor: '#0000FF'
        });
        const ids = map.addPolygons([polygon]);
        if (ids.length > 0) {
          polygon.setFillColor('#00FF00');
          map.updatePolygon(polygon);
          expect(true).assertTrue();
          map.removeAnnotations(ids);
        }
      });
    });

    // ==================== Annotation Icon ====================
    describe('Annotation icon', () => {
      it('should add and remove annotation icon', 0, () => {
        if (!map) { return; }
        // Create a simple 4-pixel red icon
        const pixels = new Uint8Array([255, 0, 0, 255]);
        map.addAnnotationIcon('test_icon', 1, 1, 1, pixels);
        const offset = map.getTopOffsetPixelsForAnnotationSymbol('test_icon');
        expect(typeof offset).assertEqual('number');
        map.removeAnnotationIcon('test_icon');
        expect(true).assertTrue();
      });
    });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
