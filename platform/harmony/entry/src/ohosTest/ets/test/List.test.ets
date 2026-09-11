/**
 * Test suite entry point for entry module ohosTest
 *
 * Aggregates all integration test suites for the entry module.
 */
import abilityTest from './Ability.test';
import mapIntegrationTest from './MapIntegrationTest';
import annotationIntegrationTest from './AnnotationIntegrationTest';
import styleIntegrationTest from './StyleIntegrationTest';
import cameraAnimationTest from './CameraAnimationTest';
import eventSystemTest from './EventSystemTest';
import snapshotTest from './SnapshotTest';
import debugRenderTest from './DebugRenderTest';
import tileLodTest from './TileLodTest';
import projectionTest from './ProjectionTest';
import netStorageTest from './NetStorageTest';
import featureQueryTest from './FeatureQueryTest';

export default function testsuite() {
  abilityTest();
  mapIntegrationTest();
  annotationIntegrationTest();
  styleIntegrationTest();
  cameraAnimationTest();
  eventSystemTest();
  snapshotTest();
  debugRenderTest();
  tileLodTest();
  projectionTest();
  netStorageTest();
  featureQueryTest();
}
