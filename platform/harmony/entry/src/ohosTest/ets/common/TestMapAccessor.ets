/**
 * TestMapAccessor - MapLibreMap holder for automated tests.
 *
 * The map instance is published by AutomationTestPage through AppStorage
 * (key: automationTestMap — must match the page). AppStorage is
 * process-scoped, which is what makes the value visible here: this file is
 * compiled into the entry_test module, so a plain static singleton would be
 * a DIFFERENT instance from the entry module's TestMapAccessor and would
 * never observe the page's registration.
 *
 * clear() is intentionally a no-op: the map's lifecycle is owned by
 * AutomationTestPage (destroyed in aboutToDisappear, which runs when the
 * suite navigates back). Destroying it here would kill a page that is
 * still on screen.
 */
import { MapLibreMap } from 'maplibre-harmony';

export const AUTOMATION_TEST_MAP_KEY = 'automationTestMap';

export class TestMapAccessor {
  /**
   * Get the registered MapLibreMap instance (null until the page publishes one).
   */
  static getMapInstance(): MapLibreMap | null {
    const map = AppStorage.get<MapLibreMap>(AUTOMATION_TEST_MAP_KEY);
    return map === undefined ? null : map;
  }

  /**
   * Check if a map instance is available.
   */
  static isMapReady(): boolean {
    return TestMapAccessor.getMapInstance() !== null;
  }

  /**
   * Kept for source compatibility with the suites' afterAll blocks.
   * Lifecycle is owned by AutomationTestPage — nothing to do here.
   */
  static clear(): void {
  }
}
