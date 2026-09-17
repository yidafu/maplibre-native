/**
 * Test suite entry point for Layer 2: NAPI Integration Tests
 *
 * Aggregates all ohosTest integration tests.
 * Some tests require the native library and/or real NativeMapView.
 */
import abilityTest from './Ability.test';
import cameraChangeDispatcherTest from './CameraChangeDispatcherTest';
import geoJsonTest from './GeoJsonTest';
import mapLibreSettingsTest from './MapLibreSettingsTest';
import networkConfigTest from './NetworkConfigTest';

export default function testsuite() {
  abilityTest();
  cameraChangeDispatcherTest();
  geoJsonTest();
  mapLibreSettingsTest();
  networkConfigTest();
}
