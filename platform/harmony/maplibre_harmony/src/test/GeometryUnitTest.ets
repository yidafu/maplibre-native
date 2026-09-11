/**
 * Geometry Unit Tests
 *
 * Tests for pure ArkTS geometry classes:
 * LatLng, LatLngBounds, PixelCoordinate, Rect, ProjectedMeters
 *
 * These tests have NO NAPI dependency and can run as local unit tests.
 */
import { describe, it, expect } from '@ohos/hypium';
import { LatLng, LatLngBounds, PixelCoordinate, Rect, ProjectedMeters } from '../main/ets/maps';
import { ILatLng } from '../main/ets/maps/types/NativeTypes';

export default function GeometryUnitTest() {
  // ==================== LatLng ====================
  describe('LatLng', () => {
    it('should create with lat/lng and expose getters', 0, () => {
      const latLng = new LatLng(39.9, 116.4);
      expect(latLng.latitude).assertClose(39.9, 0.0001);
      expect(latLng.longitude).assertClose(116.4, 0.0001);
    });

    it('static create should return identical instance', 0, () => {
      const latLng = LatLng.create(30.0, 120.0);
      expect(latLng.latitude).assertEqual(30.0);
      expect(latLng.longitude).assertEqual(120.0);
    });

    it('should handle zero values', 0, () => {
      const latLng = new LatLng(0, 0);
      expect(latLng.latitude).assertEqual(0);
      expect(latLng.longitude).assertEqual(0);
    });

    it('should convert to object via toObject()', 0, () => {
      const latLng = new LatLng(39.9, 116.4);
      const obj = latLng.toObject();
      expect(obj.latitude).assertClose(39.9, 0.0001);
      expect(obj.longitude).assertClose(116.4, 0.0001);
    });

    it('fromNative should create from interface', 0, () => {
      const native: ILatLng = { latitude: 40.0, longitude: -74.0 };
      const latLng = LatLng.fromNative(native);
      expect(latLng.latitude).assertEqual(40.0);
      expect(latLng.longitude).assertEqual(-74.0);
    });

    it('isValid should return true for valid coordinates', 0, () => {
      expect(new LatLng(45, 90).isValid()).assertTrue();
      expect(new LatLng(-45, -90).isValid()).assertTrue();
      expect(new LatLng(0, 0).isValid()).assertTrue();
      expect(new LatLng(90, 180).isValid()).assertTrue();
      expect(new LatLng(-90, -180).isValid()).assertTrue();
    });

    it('isValid should return false for out-of-range coordinates', 0, () => {
      expect(new LatLng(91, 0).isValid()).assertFalse();
      expect(new LatLng(-91, 0).isValid()).assertFalse();
      expect(new LatLng(0, 181).isValid()).assertFalse();
      expect(new LatLng(0, -181).isValid()).assertFalse();
    });

    it('equals should handle exact match', 0, () => {
      const a = new LatLng(39.9, 116.4);
      const b = new LatLng(39.9, 116.4);
      expect(a.equals(b)).assertTrue();
    });

    it('equals should handle mismatch', 0, () => {
      const a = new LatLng(39.9, 116.4);
      const b = new LatLng(40.0, 116.4);
      expect(a.equals(b)).assertFalse();
    });

    it('distanceTo should compute Haversine distance', 0, () => {
      // Beijing to Shanghai ~1060 km
      const beijing = new LatLng(39.9, 116.4);
      const shanghai = new LatLng(31.2, 121.5);
      const distance = beijing.distanceTo(shanghai);
      // Expect around 1060 km (within 5% tolerance)
      expect(distance).assertClose(1060000, 50000);
    });

    it('distanceTo same point should be zero', 0, () => {
      const a = new LatLng(39.9, 116.4);
      expect(a.distanceTo(a)).assertEqual(0);
    });

    it('toString should return formatted string', 0, () => {
      const latLng = new LatLng(39.9, 116.4);
      expect(latLng.toString()).assertEqual('LatLng(39.9, 116.4)');
    });
  });

  // ==================== LatLngBounds ====================
  describe('LatLngBounds', () => {
    it('should create with four numeric arguments', 0, () => {
      const bounds = new LatLngBounds(40.0, 117.0, 30.0, 110.0);
      expect(bounds.north).assertEqual(40.0);
      expect(bounds.east).assertEqual(117.0);
      expect(bounds.south).assertEqual(30.0);
      expect(bounds.west).assertEqual(110.0);
    });

    it('should create with two LatLng objects', 0, () => {
      const sw = new LatLng(30.0, 110.0);
      const ne = new LatLng(40.0, 117.0);
      const bounds = new LatLngBounds(sw, ne);
      expect(bounds.north).assertEqual(40.0);
      expect(bounds.east).assertEqual(117.0);
      expect(bounds.south).assertEqual(30.0);
      expect(bounds.west).assertEqual(110.0);
    });

    it('fromLatLngs should validate northeast >= southwest', 0, () => {
      const sw = new LatLng(30.0, 110.0);
      const ne = new LatLng(40.0, 117.0);
      const bounds = LatLngBounds.fromLatLngs(ne, sw);
      expect(bounds.north).assertEqual(40.0);
      expect(bounds.east).assertEqual(117.0);
    });

    it('fromLatLngs should throw on invalid args', 0, () => {
      const sw = new LatLng(50.0, 110.0); // south > north
      const ne = new LatLng(40.0, 117.0);
      expect(() => {
        LatLngBounds.fromLatLngs(ne, sw);
      }).assertThrowError(Error);
    });

    it('fromLatLngArray should compute bounds correctly', 0, () => {
      const points = [
        new LatLng(35.0, 115.0),
        new LatLng(40.0, 110.0),
        new LatLng(30.0, 117.0)
      ];
      const bounds = LatLngBounds.fromLatLngArray(points);
      expect(bounds.north).assertEqual(40.0);
      expect(bounds.east).assertEqual(117.0);
      expect(bounds.south).assertEqual(30.0);
      expect(bounds.west).assertEqual(110.0);
    });

    it('fromLatLngArray should throw on empty array', 0, () => {
      expect(() => {
        LatLngBounds.fromLatLngArray([]);
      }).assertThrowError(Error);
    });

    it('getCenter should return midpoint', 0, () => {
      const bounds = new LatLngBounds(40.0, 117.0, 30.0, 110.0);
      const center = bounds.getCenter();
      expect(center.latitude).assertEqual(35.0);
      expect(center.longitude).assertEqual(113.5);
    });

    it('contains should detect interior point', 0, () => {
      const bounds = new LatLngBounds(40.0, 117.0, 30.0, 110.0);
      expect(bounds.contains(new LatLng(35.0, 114.0))).assertTrue();
      expect(bounds.contains(new LatLng(30.0, 110.0))).assertTrue(); // on border
      expect(bounds.contains(new LatLng(40.0, 117.0))).assertTrue(); // on border
    });

    it('contains should reject exterior point', 0, () => {
      const bounds = new LatLngBounds(40.0, 117.0, 30.0, 110.0);
      expect(bounds.contains(new LatLng(50.0, 114.0))).assertFalse(); // north of bounds
      expect(bounds.contains(new LatLng(35.0, 120.0))).assertFalse(); // east of bounds
    });

    it('intersects should detect overlap', 0, () => {
      const a = new LatLngBounds(40.0, 117.0, 30.0, 110.0);
      const b = new LatLngBounds(35.0, 115.0, 25.0, 105.0);
      expect(a.intersects(b)).assertTrue();
    });

    it('intersects should reject non-overlapping bounds', 0, () => {
      const a = new LatLngBounds(40.0, 117.0, 30.0, 110.0);
      const b = new LatLngBounds(50.0, 120.0, 45.0, 118.0);
      expect(a.intersects(b)).assertFalse();
    });

    it('extend should expand bounds to include point', 0, () => {
      const bounds = new LatLngBounds(40.0, 117.0, 30.0, 110.0);
      const extended = bounds.extend(new LatLng(45.0, 120.0));
      expect(extended.north).assertEqual(45.0);
      expect(extended.east).assertEqual(120.0);
      // Original unchanged
      expect(bounds.north).assertEqual(40.0);
    });

    it('isValid should validate bounds', 0, () => {
      expect(new LatLngBounds(40.0, 117.0, 30.0, 110.0).isValid()).assertTrue();
      expect(new LatLngBounds(30.0, 117.0, 40.0, 110.0).isValid()).assertFalse(); // south > north
    });

    it('toString should return formatted string', 0, () => {
      const bounds = new LatLngBounds(40.0, 117.0, 30.0, 110.0);
      expect(bounds.toString()).assertEqual('LatLngBounds(40, 117, 30, 110)');
    });
  });

  // ==================== PixelCoordinate / Point ====================
  describe('PixelCoordinate', () => {
    it('should create with x/y defaults', 0, () => {
      const pt = new PixelCoordinate();
      expect(pt.x).assertEqual(0);
      expect(pt.y).assertEqual(0);
    });

    it('should create with specific coordinates', 0, () => {
      const pt = new PixelCoordinate(100, 200);
      expect(pt.x).assertEqual(100);
      expect(pt.y).assertEqual(200);
    });

    it('static create should match constructor', 0, () => {
      const pt = PixelCoordinate.create(50, 75);
      expect(pt.x).assertEqual(50);
      expect(pt.y).assertEqual(75);
    });

    it('fromObject should create from interface', 0, () => {
      const pt = PixelCoordinate.fromObject({ x: 10, y: 20 });
      expect(pt.x).assertEqual(10);
      expect(pt.y).assertEqual(20);
    });

    it('toObject should return plain object', 0, () => {
      const pt = new PixelCoordinate(100, 200);
      const obj = pt.toObject();
      expect(obj.x).assertEqual(100);
      expect(obj.y).assertEqual(200);
    });

    it('fromLogicalPixels should apply pixel ratio', 0, () => {
      const physical = PixelCoordinate.fromLogicalPixels(100, 200, 2.0);
      expect(physical.x).assertEqual(200);
      expect(physical.y).assertEqual(400);
    });

    it('toPhysicalPixels should apply pixel ratio', 0, () => {
      const pt = new PixelCoordinate(100, 200);
      const physical = pt.toPhysicalPixels(2.0);
      expect(physical.x).assertEqual(200);
      expect(physical.y).assertEqual(400);
    });

    it('distanceTo should compute Euclidean distance', 0, () => {
      const a = new PixelCoordinate(0, 0);
      const b = new PixelCoordinate(3, 4);
      expect(a.distanceTo(b)).assertEqual(5);
    });

    it('midpoint should return correct center', 0, () => {
      const a = new PixelCoordinate(0, 0);
      const b = new PixelCoordinate(100, 200);
      const mid = a.midpoint(b);
      expect(mid.x).assertEqual(50);
      expect(mid.y).assertEqual(100);
    });
  });

  // ==================== Rect ====================
  describe('Rect', () => {
    it('should create with default zero values', 0, () => {
      const rect = new Rect();
      expect(rect.left).assertEqual(0);
      expect(rect.top).assertEqual(0);
      expect(rect.right).assertEqual(0);
      expect(rect.bottom).assertEqual(0);
    });

    it('should create with specific values', 0, () => {
      const rect = new Rect(10, 20, 100, 200);
      expect(rect.left).assertEqual(10);
      expect(rect.top).assertEqual(20);
      expect(rect.right).assertEqual(100);
      expect(rect.bottom).assertEqual(200);
    });

    it('fromXYWH should compute right/bottom', 0, () => {
      const rect = Rect.fromXYWH(10, 20, 100, 200);
      expect(rect.left).assertEqual(10);
      expect(rect.top).assertEqual(20);
      expect(rect.right).assertEqual(110);
      expect(rect.bottom).assertEqual(220);
    });

    it('getWidth and getHeight should return correct dimensions', 0, () => {
      const rect = new Rect(10, 20, 110, 220);
      expect(rect.getWidth()).assertEqual(100);
      expect(rect.getHeight()).assertEqual(200);
    });

    it('getCenter should return midpoint', 0, () => {
      const rect = new Rect(0, 0, 100, 200);
      const center = rect.getCenter();
      expect(center.x).assertEqual(50);
      expect(center.y).assertEqual(100);
    });

    it('containsPoint should detect interior', 0, () => {
      const rect = new Rect(10, 20, 100, 200);
      const p = new PixelCoordinate(50, 100);
      expect(rect.containsPoint(p)).assertTrue();
      // Edge cases
      expect(rect.containsPoint(new PixelCoordinate(10, 20))).assertTrue(); // on border
      expect(rect.containsPoint(new PixelCoordinate(100, 200))).assertTrue(); // on border
    });

    it('containsPoint should reject exterior', 0, () => {
      const rect = new Rect(10, 20, 100, 200);
      expect(rect.containsPoint(new PixelCoordinate(5, 50))).assertFalse();
      expect(rect.containsPoint(new PixelCoordinate(50, 300))).assertFalse();
    });

    it('intersects should detect overlap', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(50, 50, 150, 150);
      expect(a.intersects(b)).assertTrue();
    });

    it('intersects should reject non-overlapping', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(200, 200, 300, 300);
      expect(a.intersects(b)).assertFalse();
    });

    it('intersection should compute overlap area', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(50, 50, 150, 150);
      const i = a.intersection(b);
      expect(i !== null).assertTrue();
      if (i !== null) {
        expect(i.left).assertEqual(50);
        expect(i.top).assertEqual(50);
        expect(i.right).assertEqual(100);
        expect(i.bottom).assertEqual(100);
      }
    });

    it('intersection should return null for no overlap', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(200, 200, 300, 300);
      expect(a.intersection(b)).assertNull();
    });

    it('union should combine both rects', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(50, 50, 150, 150);
      const u = a.union(b);
      expect(u.left).assertEqual(0);
      expect(u.top).assertEqual(0);
      expect(u.right).assertEqual(150);
      expect(u.bottom).assertEqual(150);
    });

    it('isEmpty should detect zero-area rect', 0, () => {
      expect(new Rect(0, 0, 100, 100).isEmpty()).assertFalse();
      expect(new Rect(0, 0, 0, 0).isEmpty()).assertTrue();
      expect(new Rect(10, 10, 10, 20).isEmpty()).assertTrue(); // zero width
    });

    it('getArea should return correct area', 0, () => {
      expect(new Rect(0, 0, 100, 200).getArea()).assertEqual(20000);
      expect(new Rect(0, 0, 0, 0).getArea()).assertEqual(0);
    });
  });

  // ==================== ProjectedMeters ====================
  describe('ProjectedMeters', () => {
    it('should create with default zero values', 0, () => {
      const pm = new ProjectedMeters();
      expect(pm.northing).assertEqual(0);
      expect(pm.easting).assertEqual(0);
    });

    it('should create with specific values', 0, () => {
      const pm = new ProjectedMeters(1000, 2000);
      expect(pm.northing).assertEqual(1000);
      expect(pm.easting).assertEqual(2000);
    });

    it('static create should match constructor', 0, () => {
      const pm = ProjectedMeters.create(500, 800);
      expect(pm.northing).assertEqual(500);
      expect(pm.easting).assertEqual(800);
    });

    it('fromObject should create from interface', 0, () => {
      const pm = ProjectedMeters.fromObject({ northing: 100, easting: 200 });
      expect(pm.northing).assertEqual(100);
      expect(pm.easting).assertEqual(200);
    });

    it('toObject should return plain object', 0, () => {
      const pm = new ProjectedMeters(1000, 2000);
      const obj = pm.toObject();
      expect(obj.northing).assertEqual(1000);
      expect(obj.easting).assertEqual(2000);
    });

    it('distanceTo should compute Euclidean distance', 0, () => {
      const a = new ProjectedMeters(0, 0);
      const b = new ProjectedMeters(3000, 4000);
      expect(a.distanceTo(b)).assertEqual(5000);
    });
  });
}
