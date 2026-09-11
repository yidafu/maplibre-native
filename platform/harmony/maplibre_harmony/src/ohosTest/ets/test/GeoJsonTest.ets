/**
 * GeoJSON Factory Unit Tests
 *
 * Tests for the pure-ArkTS GeoJSON factory methods:
 * GeoJson.point, GeoJson.lineString, GeoJson.polygon,
 * GeoJson.feature, GeoJson.featureCollection, and related helpers.
 */
import { describe, it, expect } from '@ohos/hypium';

// GeoJson is exported from maplibre_harmony (maps/index.ets)
import { GeoJson } from '../../../../main/ets/maps/geojson';
import type {
  IPoint, ILineString, IPolygon, IFeature, IFeatureCollection
} from '../../../../main/ets/maps/geojson/types';

export default function GeoJsonTest() {
  // ==================== Point ====================
  describe('GeoJson.point', () => {
    it('should create a Point geometry', 0, () => {
      const pt = GeoJson.point([116.4, 39.9]);
      expect(pt.type).assertEqual('Point');
      expect(pt.coordinates[0]).assertClose(116.4, 0.0001);
      expect(pt.coordinates[1]).assertClose(39.9, 0.0001);
    });

    it('should handle altitude', 0, () => {
      const pt = GeoJson.point([116.4, 39.9, 100]);
      expect(pt.coordinates.length).assertEqual(3);
      expect(pt.coordinates[2]).assertEqual(100);
    });

    it('should handle negative coordinates', 0, () => {
      const pt = GeoJson.point([-74.0, 40.7]);
      expect(pt.coordinates[0]).assertEqual(-74.0);
      expect(pt.coordinates[1]).assertEqual(40.7);
    });

    it('should handle zero coordinates', 0, () => {
      const pt = GeoJson.point([0, 0]);
      expect(pt.coordinates[0]).assertEqual(0);
      expect(pt.coordinates[1]).assertEqual(0);
    });
  });

  // ==================== LineString ====================
  describe('GeoJson.lineString', () => {
    it('should create a LineString geometry', 0, () => {
      const line = GeoJson.lineString([[116.4, 39.9], [121.5, 31.2]]);
      expect(line.type).assertEqual('LineString');
      expect(line.coordinates.length).assertEqual(2);
    });

    it('should handle single-point line', 0, () => {
      const line = GeoJson.lineString([[116.4, 39.9]]);
      expect(line.coordinates.length).assertEqual(1);
    });

    it('should handle multi-segment line', 0, () => {
      const coords = [[0, 0], [1, 1], [2, 2], [3, 3]];
      const line = GeoJson.lineString(coords);
      expect(line.coordinates.length).assertEqual(4);
    });
  });

  // ==================== Polygon ====================
  describe('GeoJson.polygon', () => {
    it('should create a Polygon geometry', 0, () => {
      const poly = GeoJson.polygon([[
        [116.3, 39.8], [116.5, 39.8], [116.5, 40.0], [116.3, 40.0], [116.3, 39.8]
      ]]);
      expect(poly.type).assertEqual('Polygon');
      expect(poly.coordinates.length).assertEqual(1);
      expect(poly.coordinates[0].length).assertEqual(5);
    });

    it('should handle polygon with holes', 0, () => {
      const poly = GeoJson.polygon([
        [[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]],
        [[2, 2], [8, 2], [8, 8], [2, 8], [2, 2]]
      ]);
      expect(poly.coordinates.length).assertEqual(2);
    });
  });

  // ==================== MultiPoint ====================
  describe('GeoJson.multiPoint', () => {
    it('should create a MultiPoint geometry', 0, () => {
      const mp = GeoJson.multiPoint([[116.4, 39.9], [121.5, 31.2], [113.3, 23.1]]);
      expect(mp.type).assertEqual('MultiPoint');
      expect(mp.coordinates.length).assertEqual(3);
    });
  });

  // ==================== MultiLineString ====================
  describe('GeoJson.multiLineString', () => {
    it('should create a MultiLineString geometry', 0, () => {
      const mls = GeoJson.multiLineString([
        [[116.4, 39.9], [121.5, 31.2]],
        [[113.3, 23.1], [114.1, 22.5]]
      ]);
      expect(mls.type).assertEqual('MultiLineString');
      expect(mls.coordinates.length).assertEqual(2);
    });
  });

  // ==================== MultiPolygon ====================
  describe('GeoJson.multiPolygon', () => {
    it('should create a MultiPolygon geometry', 0, () => {
      const mp = GeoJson.multiPolygon([
        [[[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]],
        [[[2, 2], [3, 2], [3, 3], [2, 3], [2, 2]]]
      ]);
      expect(mp.type).assertEqual('MultiPolygon');
      expect(mp.coordinates.length).assertEqual(2);
    });
  });

  // ==================== Feature ====================
  describe('GeoJson.feature', () => {
    it('should create a Feature with geometry and properties', 0, () => {
      const pt = GeoJson.point([116.4, 39.9]);
      const feature = GeoJson.feature(pt, { name: 'Beijing', population: 21540000 });
      expect(feature.type).assertEqual('Feature');
      expect(feature.geometry.type).assertEqual('Point');
      expect(feature.properties!['name']).assertEqual('Beijing');
    });

    it('should create a Feature with null properties', 0, () => {
      const pt = GeoJson.point([0, 0]);
      const feature = GeoJson.feature(pt);
      expect(feature.type).assertEqual('Feature');
      expect(feature.properties).assertNull();
    });
  });

  // ==================== FeatureCollection ====================
  describe('GeoJson.featureCollection', () => {
    it('should create a FeatureCollection', 0, () => {
      const pt = GeoJson.pointFeature([116.4, 39.9], { name: 'Beijing' });
      const line = GeoJson.lineStringFeature([[116.4, 39.9], [121.5, 31.2]]);
      const fc = GeoJson.featureCollection([pt, line]);
      expect(fc.type).assertEqual('FeatureCollection');
      expect(fc.features.length).assertEqual(2);
    });

    it('should handle empty feature array', 0, () => {
      const fc = GeoJson.featureCollection([]);
      expect(fc.features.length).assertEqual(0);
    });
  });

  // ==================== Convenience Factory Methods ====================
  describe('GeoJson convenience factories', () => {
    it('pointFeature should create Point Feature', 0, () => {
      const f = GeoJson.pointFeature([116.4, 39.9]);
      expect(f.type).assertEqual('Feature');
      expect(f.geometry.type).assertEqual('Point');
    });

    it('pointFeature with properties should include properties', 0, () => {
      const f = GeoJson.pointFeature([116.4, 39.9], { name: 'Beijing' });
      expect(f.properties!['name']).assertEqual('Beijing');
    });

    it('lineStringFeature should create LineString Feature', 0, () => {
      const f = GeoJson.lineStringFeature([[116.4, 39.9], [121.5, 31.2]]);
      expect(f.type).assertEqual('Feature');
      expect(f.geometry.type).assertEqual('LineString');
    });

    it('polygonFeature should create Polygon Feature', 0, () => {
      const f = GeoJson.polygonFeature([[
        [0, 0], [1, 0], [1, 1], [0, 1], [0, 0]
      ]]);
      expect(f.type).assertEqual('Feature');
      expect(f.geometry.type).assertEqual('Polygon');
    });

    it('geometryCollection should create a geometry collection', 0, () => {
      const pt = GeoJson.point([0, 0]);
      const line = GeoJson.lineString([[1, 1], [2, 2]]);
      const gc = GeoJson.geometryCollection([pt, line]);
      expect(gc.type).assertEqual('GeometryCollection');
      expect(gc.geometries.length).assertEqual(2);
    });
  });

  // ==================== GeoJSON Structure Compliance ====================
  describe('GeoJSON structure compliance', () => {
    it('point should be serializable to JSON', 0, () => {
      const pt = GeoJson.point([116.4, 39.9]);
      const json = JSON.stringify(pt);
      const parsed = JSON.parse(json);
      expect(parsed.type).assertEqual('Point');
      expect(parsed.coordinates[0]).assertClose(116.4, 0.0001);
    });

    it('feature should be serializable to JSON', 0, () => {
      const f = GeoJson.pointFeature([116.4, 39.9], { name: 'Beijing' });
      const json = JSON.stringify(f);
      const parsed = JSON.parse(json);
      expect(parsed.type).assertEqual('Feature');
      expect(parsed.properties.name).assertEqual('Beijing');
    });

    it('featureCollection should be serializable to JSON', 0, () => {
      const fc = GeoJson.featureCollection([
        GeoJson.pointFeature([0, 0]),
        GeoJson.pointFeature([1, 1])
      ]);
      const json = JSON.stringify(fc);
      const parsed = JSON.parse(json);
      expect(parsed.features.length).assertEqual(2);
    });
  });
}
