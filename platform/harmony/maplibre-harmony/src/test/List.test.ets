/**
 * Test suite entry point for Layer 1: Pure ArkTS Unit Tests
 *
 * Aggregates all pure ArkTS unit tests that have NO NAPI dependency.
 * These tests can run as local unit tests without a real device.
 */
import geometryUnitTest from './GeometryUnitTest';
import styleModelUnitTest from './StyleModelUnitTest';
import uiModelUnitTest from './UiModelUnitTest';
import constantsUnitTest from './ConstantsUnitTest';

export default function testsuite() {
  geometryUnitTest();
  styleModelUnitTest();
  uiModelUnitTest();
  constantsUnitTest();
}
