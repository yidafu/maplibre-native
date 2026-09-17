/**
 * UI Model Unit Tests
 *
 * Tests for pure ArkTS UI model classes and enums:
 * UiSettings, MapDebugOptions, enums, MapLibreMapOptions,
 * MarkerOptions, FocalPoint, CameraMoveReason
 */
import { describe, it, expect } from '@ohos/hypium';
import { UiSettings, FocalPoint } from '../main/ets/maps/UiSettings';
import { MapDebugOptions } from '../main/ets/maps/types/MapDebugOptions';
import {
  OrnamentPosition, RenderingRefreshMode, TileOperation,
  UserTrackingMode,
  createMargins, createUniformMargins, mergeMargins, Margins
} from '../main/ets/maps/types/NativeTypes';
import { CompassVisibility } from '../main/ets/maps/widgets/CompassVisibility';
import { MapLibreMapOptions } from '../main/ets/maps/MapLibreMapOptions';
import { MarkerOptions } from '../main/ets/maps/annotations/MarkerOptions';
import { CameraMoveReason } from '../main/ets/maps/camera/CameraMoveReason';
import { LatLng } from '../main/ets/maps/geometry/LatLng';

export default function UiModelUnitTest() {
  // ==================== UiSettings - Gesture Settings ====================
  describe('UiSettings gestures', () => {
    it('should have all gestures enabled by default', 0, () => {
      const settings = new UiSettings();
      expect(settings.isScrollGesturesEnabled()).assertTrue();
      expect(settings.isZoomGesturesEnabled()).assertTrue();
      expect(settings.isRotateGesturesEnabled()).assertTrue();
      expect(settings.isTiltGesturesEnabled()).assertTrue();
      expect(settings.isDoubleTapGesturesEnabled()).assertTrue();
      expect(settings.isQuickZoomGesturesEnabled()).assertTrue();
    });

    it('should toggle scroll gesture', 0, () => {
      const settings = new UiSettings();
      settings.setScrollGesturesEnabled(false);
      expect(settings.isScrollGesturesEnabled()).assertFalse();
      settings.setScrollGesturesEnabled(true);
      expect(settings.isScrollGesturesEnabled()).assertTrue();
    });

    it('should toggle zoom gesture', 0, () => {
      const settings = new UiSettings();
      settings.setZoomGesturesEnabled(false);
      expect(settings.isZoomGesturesEnabled()).assertFalse();
    });

    it('should toggle rotate gesture', 0, () => {
      const settings = new UiSettings();
      settings.setRotateGesturesEnabled(false);
      expect(settings.isRotateGesturesEnabled()).assertFalse();
    });

    it('should toggle tilt gesture', 0, () => {
      const settings = new UiSettings();
      settings.setTiltGesturesEnabled(false);
      expect(settings.isTiltGesturesEnabled()).assertFalse();
    });

    it('should toggle double-tap gesture', 0, () => {
      const settings = new UiSettings();
      settings.setDoubleTapGesturesEnabled(false);
      expect(settings.isDoubleTapGesturesEnabled()).assertFalse();
    });

    it('should toggle quick-zoom gesture', 0, () => {
      const settings = new UiSettings();
      settings.setQuickZoomGesturesEnabled(false);
      expect(settings.isQuickZoomGesturesEnabled()).assertFalse();
    });

    it('should toggle horizontal scroll gesture', 0, () => {
      const settings = new UiSettings();
      expect(settings.isHorizontalScrollGesturesEnabled()).assertTrue();
      settings.setHorizontalScrollGesturesEnabled(false);
      expect(settings.isHorizontalScrollGesturesEnabled()).assertFalse();
    });

    it('setAllGesturesEnabled should toggle all', 0, () => {
      const settings = new UiSettings();
      settings.setAllGesturesEnabled(false);
      expect(settings.isScrollGesturesEnabled()).assertFalse();
      expect(settings.isZoomGesturesEnabled()).assertFalse();
      expect(settings.isRotateGesturesEnabled()).assertFalse();
      expect(settings.isTiltGesturesEnabled()).assertFalse();
    });

    it('should return this from setters for chaining', 0, () => {
      const settings = new UiSettings();
      const result = settings.setScrollGesturesEnabled(false).setZoomGesturesEnabled(false);
      expect(result === settings).assertTrue();
    });

    it('should manage focal point', 0, () => {
      const settings = new UiSettings();
      expect(settings.getFocalPoint()).assertNull();
      const fp = new FocalPoint(100, 200);
      settings.setFocalPoint(fp);
      const retrieved = settings.getFocalPoint();
      expect(retrieved !== null).assertTrue();
      if (retrieved !== null) {
        expect(retrieved.x).assertEqual(100);
        expect(retrieved.y).assertEqual(200);
      }
    });

    it('should clear focal point', 0, () => {
      const settings = new UiSettings();
      settings.setFocalPoint(new FocalPoint(100, 200));
      settings.setFocalPoint(null);
      expect(settings.getFocalPoint()).assertNull();
    });
  });

  // ==================== UiSettings - Compass ====================
  describe('UiSettings compass', () => {
    it('should be enabled by default', 0, () => {
      const settings = new UiSettings();
      expect(settings.isCompassEnabled()).assertTrue();
    });

    it('should toggle compass', 0, () => {
      const settings = new UiSettings();
      settings.setCompassEnabled(false);
      expect(settings.isCompassEnabled()).assertFalse();
    });

    it('should set and get compass visibility', 0, () => {
      const settings = new UiSettings();
      expect(settings.getCompassVisibility()).assertEqual(CompassVisibility.Adaptive);
      settings.setCompassVisibility(CompassVisibility.Visible);
      expect(settings.getCompassVisibility()).assertEqual(CompassVisibility.Visible);
    });

    it('should manage compass fade when facing north', 0, () => {
      const settings = new UiSettings();
      expect(settings.isCompassFadeWhenFacingNorth()).assertTrue();
      settings.setCompassFadeFacingNorth(false);
      expect(settings.isCompassFadeWhenFacingNorth()).assertFalse();
    });

    it('should manage compass margins', 0, () => {
      const settings = new UiSettings();
      settings.setCompassMargins(10, 20, 30, 40);
      const margins = settings.getCompassMargins();
      expect(margins.left).assertEqual(10);
      expect(margins.top).assertEqual(20);
      expect(margins.right).assertEqual(30);
      expect(margins.bottom).assertEqual(40);
    });

    it('should manage individual compass margin getters', 0, () => {
      const settings = new UiSettings();
      settings.setCompassMargins(5, 10, 15, 20);
      expect(settings.getCompassMarginLeft()).assertEqual(5);
      expect(settings.getCompassMarginTop()).assertEqual(10);
      expect(settings.getCompassMarginRight()).assertEqual(15);
      expect(settings.getCompassMarginBottom()).assertEqual(20);
    });
  });

  // ==================== UiSettings - Logo ====================
  describe('UiSettings logo', () => {
    it('should be enabled by default', 0, () => {
      const settings = new UiSettings();
      expect(settings.isLogoEnabled()).assertTrue();
    });

    it('should toggle logo', 0, () => {
      const settings = new UiSettings();
      settings.setLogoEnabled(false);
      expect(settings.isLogoEnabled()).assertFalse();
    });
  });

  // ==================== UiSettings - ScaleBar ====================
  describe('UiSettings scalebar', () => {
    it('should be enabled by default', 0, () => {
      const settings = new UiSettings();
      expect(settings.isScaleBarEnabled()).assertTrue();
    });

    it('should toggle scalebar', 0, () => {
      const settings = new UiSettings();
      settings.setScaleBarEnabled(false);
      expect(settings.isScaleBarEnabled()).assertFalse();
    });
  });

  // ==================== UiSettings - Attribution ====================
  describe('UiSettings attribution', () => {
    it('should be enabled by default', 0, () => {
      const settings = new UiSettings();
      expect(settings.isAttributionEnabled()).assertTrue();
    });

    it('should toggle attribution', 0, () => {
      const settings = new UiSettings();
      settings.setAttributionEnabled(false);
      expect(settings.isAttributionEnabled()).assertFalse();
    });
  });

  // ==================== UiSettings - Inertial Animation ====================
  describe('UiSettings velocity animation', () => {
    it('should be enabled by default', 0, () => {
      const settings = new UiSettings();
      expect(settings.isFlingVelocityAnimationEnabled()).assertTrue();
      expect(settings.isScaleVelocityAnimationEnabled()).assertTrue();
      expect(settings.isRotateVelocityAnimationEnabled()).assertTrue();
    });

    it('should toggle fling animation', 0, () => {
      const settings = new UiSettings();
      settings.setFlingVelocityAnimationEnabled(false);
      expect(settings.isFlingVelocityAnimationEnabled()).assertFalse();
    });

    it('should manage deceleration rate', 0, () => {
      const settings = new UiSettings();
      settings.setDecelerationRate(2.5);
      expect(settings.getDecelerationRate()).assertEqual(2.5);
    });

    it('should manage fling threshold', 0, () => {
      const settings = new UiSettings();
      settings.setFlingThreshold(150);
      expect(settings.getFlingThreshold()).assertEqual(150);
    });
  });

  // ==================== UiSettings - Pitch ====================
  describe('UiSettings pitch/tilt', () => {
    it('should have default pitch limits', 0, () => {
      const settings = new UiSettings();
      expect(settings.getMinPitch()).assertEqual(0);
      expect(settings.getMaxPitch()).assertEqual(60);
    });

    it('should set pitch limits', 0, () => {
      const settings = new UiSettings();
      settings.setMinPitch(10);
      settings.setMaxPitch(45);
      expect(settings.getMinPitch()).assertEqual(10);
      expect(settings.getMaxPitch()).assertEqual(45);
    });

    it('should manage tilt sensitivity', 0, () => {
      const settings = new UiSettings();
      settings.setTiltSensitivity(0.5);
      expect(settings.getTiltSensitivity()).assertEqual(0.5);
    });
  });

  // ==================== UiSettings - Zoom Rate ====================
  describe('UiSettings zoom rate', () => {
    it('should manage zoom rate', 0, () => {
      const settings = new UiSettings();
      settings.setZoomRate(2.0);
      expect(settings.getZoomRate()).assertEqual(2.0);
    });

    it('should manage rotation rate', 0, () => {
      const settings = new UiSettings();
      settings.setRotationRate(45);
      expect(settings.getRotationRate()).assertEqual(45);
    });
  });

  // ==================== MapDebugOptions ====================
  describe('MapDebugOptions', () => {
    it('should have correct bit-flag values', 0, () => {
      expect(MapDebugOptions.NoDebug).assertEqual(0);
      expect(MapDebugOptions.TileBoundaries).assertEqual(2);
      expect(MapDebugOptions.TileInfo).assertEqual(4);
      expect(MapDebugOptions.Timestamps).assertEqual(8);
      expect(MapDebugOptions.CollisionBoxes).assertEqual(16);
    });

    it('should support bitwise OR combination', 0, () => {
      const combined = MapDebugOptions.TileBoundaries | MapDebugOptions.CollisionBoxes;
      expect(combined & MapDebugOptions.TileBoundaries).assertEqual(MapDebugOptions.TileBoundaries);
      expect(combined & MapDebugOptions.CollisionBoxes).assertEqual(MapDebugOptions.CollisionBoxes);
      expect(combined & MapDebugOptions.Timestamps).assertEqual(0);
    });
  });

  // ==================== Enums from NativeTypes ====================
  describe('OrnamentPosition', () => {
    it('should have correct values', 0, () => {
      expect(OrnamentPosition.TopLeft).assertEqual(0);
      expect(OrnamentPosition.TopRight).assertEqual(1);
      expect(OrnamentPosition.BottomLeft).assertEqual(2);
      expect(OrnamentPosition.BottomRight).assertEqual(3);
    });
  });

  describe('RenderingRefreshMode', () => {
    it('should have correct values', 0, () => {
      expect(RenderingRefreshMode.CONTINUOUS).assertEqual(0);
      expect(RenderingRefreshMode.WHEN_DIRTY).assertEqual(1);
    });
  });

  describe('TileOperation', () => {
    it('should have correct values', 0, () => {
      expect(TileOperation.Added).assertEqual(0);
      expect(TileOperation.Updated).assertEqual(1);
      expect(TileOperation.Removed).assertEqual(2);
    });
  });

  describe('UserTrackingMode', () => {
    it('should have correct values', 0, () => {
      expect(UserTrackingMode.None).assertEqual(0);
      expect(UserTrackingMode.Follow).assertEqual(1);
      expect(UserTrackingMode.FollowWithHeading).assertEqual(2);
      expect(UserTrackingMode.FollowWithCourse).assertEqual(3);
    });
  });

  // ==================== CameraMoveReason (separate enum) ====================
  describe('CameraMoveReason (camera/)', () => {
    it('should have correct values', 0, () => {
      expect(CameraMoveReason.UNKNOWN).assertEqual(0);
      expect(CameraMoveReason.GESTURE).assertEqual(1);
      expect(CameraMoveReason.API_ANIMATION).assertEqual(2);
      expect(CameraMoveReason.DEVELOPER_ANIMATION).assertEqual(3);
      expect(CameraMoveReason.ANIMATION_CANCELLED).assertEqual(4);
    });
  });

  // ==================== CompassVisibility ====================
  describe('CompassVisibility', () => {
    it('should have correct values', 0, () => {
      expect(CompassVisibility.Adaptive).assertEqual(0);
      expect(CompassVisibility.Visible).assertEqual(1);
      expect(CompassVisibility.Hidden).assertEqual(2);
    });
  });

  // ==================== MapLibreMapOptions ====================
  describe('MapLibreMapOptions', () => {
    it('should have correct default values', 0, () => {
      const options = new MapLibreMapOptions();
      expect(options.minZoom).assertEqual(0);
      expect(options.maxZoom).assertEqual(22);
      expect(options.minPitch).assertEqual(0);
      expect(options.maxPitch).assertEqual(60);
      expect(options.pixelRatio).assertEqual(1.0);
      expect(options.styleUrl).assertEqual('');
      expect(options.debug).assertFalse();
      expect(options.attributionEnabled).assertTrue();
      expect(options.logoEnabled).assertTrue();
      expect(options.compassEnabled).assertTrue();
      expect(options.scaleBarEnabled).assertTrue();
      expect(options.scrollEnabled).assertTrue();
      expect(options.zoomEnabled).assertTrue();
      expect(options.rotateEnabled).assertTrue();
      expect(options.tiltEnabled).assertTrue();
      expect(options.prefetchTiles).assertTrue();
      expect(options.prefetchZoomDelta).assertEqual(4);
      expect(options.tileCacheEnabled).assertTrue();
      expect(options.tileLodMinRadius).assertEqual(0);
      expect(options.tileLodScale).assertEqual(1.0);
      expect(options.localIdeographFontFamily).assertEqual('HarmonyOS_Sans');
      expect(options.localIdeographEnabled).assertTrue();
    });

    it('should accept partial configuration', 0, () => {
      const partialOpts: Partial<MapLibreMapOptions> = {
        minZoom: 5,
        maxZoom: 18,
        debug: true
      };
      const options = new MapLibreMapOptions(partialOpts);
      expect(options.minZoom).assertEqual(5);
      expect(options.maxZoom).assertEqual(18);
      expect(options.debug).assertTrue();
      expect(options.pixelRatio).assertEqual(1.0); // default preserved
    });

    it('should override tile options from partial', 0, () => {
      const partialOpts: Partial<MapLibreMapOptions> = {
        prefetchTiles: false,
        prefetchZoomDelta: 2,
        tileCacheEnabled: false
      };
      const options = new MapLibreMapOptions(partialOpts);
      expect(options.prefetchTiles).assertFalse();
      expect(options.prefetchZoomDelta).assertEqual(2);
      expect(options.tileCacheEnabled).assertFalse();
    });

    it('should handle gesture options from config', 0, () => {
      const partialOpts: Partial<MapLibreMapOptions> = {
        scrollEnabled: false,
        zoomEnabled: false,
        rotateEnabled: false
      };
      const options = new MapLibreMapOptions(partialOpts);
      expect(options.scrollEnabled).assertFalse();
      expect(options.zoomEnabled).assertFalse();
      expect(options.rotateEnabled).assertFalse();
    });

    it('should handle tile LOD options', 0, () => {
      const partialOpts: Partial<MapLibreMapOptions> = {
        tileLodMinRadius: 10,
        tileLodScale: 2.0,
        tileLodPitchThreshold: 30,
        tileLodZoomShift: 1
      };
      const options = new MapLibreMapOptions(partialOpts);
      expect(options.tileLodMinRadius).assertEqual(10);
      expect(options.tileLodScale).assertEqual(2.0);
      expect(options.tileLodPitchThreshold).assertEqual(30);
      expect(options.tileLodZoomShift).assertEqual(1);
    });

    it('should handle style options', 0, () => {
      const partialOpts: Partial<MapLibreMapOptions> = {
        styleUrl: 'https://example.com/style.json',
        styleJson: '{"version": 8, "sources": {}}'
      };
      const options = new MapLibreMapOptions(partialOpts);
      expect(options.styleUrl).assertEqual('https://example.com/style.json');
      expect(options.styleJson).assertEqual('{"version": 8, "sources": {}}');
    });
  });



  // ==================== MarkerOptions ====================
  describe('MarkerOptions', () => {
    it('should set optional properties', 0, () => {
      const options = new MarkerOptions()
        .position(new LatLng(40.0, -74.0))
        .draggable(true)
        .alpha(0.8)
        .rotation(45)
        .zIndex(10);

      expect(options.isDraggable()).assertTrue();
      expect(options.getAlpha()).assertEqual(0.8);
      expect(options.getRotation()).assertEqual(45);
      expect(options.getZIndex()).assertEqual(10);
    });

    it('should have correct defaults', 0, () => {
      const options = new MarkerOptions();
      expect(options.isDraggable()).assertFalse();
      expect(options.isVisible()).assertTrue();
      expect(options.getAlpha()).assertEqual(1.0);
      expect(options.getRotation()).assertEqual(0);
      expect(options.getZIndex()).assertEqual(0);
    });

    it('should chain all builder methods', 0, () => {
      const options = new MarkerOptions();
      const result = options
        .position(new LatLng(30, 120))
        .title('Title')
        .snippet('Snippet')
        .draggable(true)
        .visible(false);
      expect(result === options).assertTrue();
    });

    it('getMarker should throw when position not set', 0, () => {
      const options = new MarkerOptions();
      expect(() => { options.getMarker(); }).assertThrowError(Error);
    });
  });

  // ==================== FocalPoint ====================
  describe('FocalPoint', () => {
    it('should create with x/y', 0, () => {
      const fp = new FocalPoint(100, 200);
      expect(fp.x).assertEqual(100);
      expect(fp.y).assertEqual(200);
    });
  });

  // ==================== Margins Helpers ====================
  describe('createMargins', () => {
    it('should create from array', 0, () => {
      const margins = createMargins([10, 20, 30, 40]);
      expect(margins.left).assertEqual(10);
      expect(margins.top).assertEqual(20);
      expect(margins.right).assertEqual(30);
      expect(margins.bottom).assertEqual(40);
    });

    it('should default missing values to 0', 0, () => {
      const margins = createMargins([5]);
      expect(margins.left).assertEqual(5);
      expect(margins.top).assertEqual(0);
      expect(margins.right).assertEqual(0);
      expect(margins.bottom).assertEqual(0);
    });
  });

  describe('createUniformMargins', () => {
    it('should create uniform margins', 0, () => {
      const margins = createUniformMargins(15);
      expect(margins.left).assertEqual(15);
      expect(margins.top).assertEqual(15);
      expect(margins.right).assertEqual(15);
      expect(margins.bottom).assertEqual(15);
    });
  });

  describe('mergeMargins', () => {
    it('should merge two margin objects', 0, () => {
      const base: Margins = { top: 10, left: 10, bottom: 10, right: 10 };
      const override: Partial<Margins> = { top: 20, left: undefined };
      const merged = mergeMargins(base, override);
      expect(merged.top).assertEqual(20);
      expect(merged.left).assertEqual(10);
      expect(merged.bottom).assertEqual(10);
      expect(merged.right).assertEqual(10);
    });
  });
}
