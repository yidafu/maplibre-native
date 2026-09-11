/**
 * Projection Integration Tests
 *
 * Tests coordinate projection and conversion APIs.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { MapLibreMap, LatLng, ProjectedMeters } from 'maplibre_harmony';
import { TestMapAccessor } from '../../../../main/ets/pages/common/TestMapAccessor';

const TIMEOUT = 15000;

export default function ProjectionTest() {
  describe('Projection Integration', () => {
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

    it('should convert latLng to pixel (physical)', 0, () => {
      if (!map) { return; }
      const pixel = map.pixelForLatLngPhysical(39.9, 116.4);
      expect(typeof pixel.x).assertEqual('number');
      expect(typeof pixel.y).assertEqual('number');
      expect(Number.isFinite(pixel.x)).assertTrue();
    });

    it('should convert latLng to pixel (logical)', 0, () => {
      if (!map) { return; }
      const pixel = map.pixelForLatLng(39.9, 116.4);
      expect(typeof pixel.x).assertEqual('number');
      expect(typeof pixel.y).assertEqual('number');
      expect(Number.isFinite(pixel.x)).assertTrue();
    });

    it('should convert pixel to latLng (physical)', 0, () => {
      if (!map) { return; }
      const center = map.getLatLng();
      const pixel = map.pixelForLatLngPhysical(center.latitude, center.longitude);
      const latLng = map.latLngForPixelPhysical(pixel.x, pixel.y);
      expect(latLng.latitude).assertClose(center.latitude, 0.1);
      expect(latLng.longitude).assertClose(center.longitude, 0.1);
    });

    it('should convert pixel to latLng (logical)', 0, () => {
      if (!map) { return; }
      const center = map.getLatLng();
      const pixel = map.pixelForLatLng(center.latitude, center.longitude);
      const latLng = map.latLngForPixel(pixel.x, pixel.y);
      expect(latLng.latitude).assertClose(center.latitude, 0.1);
      expect(latLng.longitude).assertClose(center.longitude, 0.1);
    });

    it('should convert latLng to projected meters', 0, () => {
      if (!map) { return; }
      const meters = map.projectedMetersForLatLng(39.9, 116.4);
      expect(typeof meters.northing).assertEqual('number');
      expect(typeof meters.easting).assertEqual('number');
    });

    it('should convert projected meters to latLng', 0, () => {
      if (!map) { return; }
      const meters = map.projectedMetersForLatLng(39.9, 116.4);
      const latLng = map.latLngForProjectedMeters(meters.northing, meters.easting);
      expect(latLng.latitude).assertClose(39.9, 0.1);
      expect(latLng.longitude).assertClose(116.4, 0.1);
    });

    it('should get meters per pixel at latitude', 0, () => {
      if (!map) { return; }
      const mpp = map.getMetersPerPixelAtLatitude(39.9);
      expect(mpp > 0).assertTrue();
    });

    it('should get meters per pixel with zoom parameter', 0, () => {
      if (!map) { return; }
      const mpp = map.getMetersPerPixelAtLatitude(39.9, 10);
      expect(mpp > 0).assertTrue();
    });

    it('should batch convert pixels for latLngs', 0, () => {
      if (!map) { return; }
      const input: number[] = [39.9, 116.4, 31.2, 121.5];
      const output: number[] = [];
      map.pixelsForLatLngs(input, output);
      expect(output.length > 0).assertTrue();
    });

    it('should batch convert latLngs for pixels', 0, () => {
      if (!map) { return; }
      const center = map.getLatLng();
      const pixel = map.pixelForLatLng(center.latitude, center.longitude);
      const input: number[] = [pixel.x, pixel.y];
      const output: number[] = [];
      map.latLngsForPixels(input, output);
      expect(output.length > 0).assertTrue();
    });
  });
}

async function sleep(ms: number): Promise<void> { return new Promise(resolve => setTimeout(resolve, ms)); }
