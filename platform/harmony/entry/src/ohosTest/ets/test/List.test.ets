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
import sourceApiIntegrationTest from './SourceApiIntegrationTest';
import indexUiTest from './IndexUiTest';
import mapGestureUiTest from './MapGestureUiTest';
import pageSmokeUiTest from './PageSmokeUiTest';

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
  sourceApiIntegrationTest();
  // UiTest-driven suites (pure UI, no direct API access). Run last so the
  // API suites that assume a fresh Index start are not disturbed.
  indexUiTest();
  mapGestureUiTest();
  pageSmokeUiTest();
}
