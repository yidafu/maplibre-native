/**
 * TestMapAccessor - global MapLibreMap holder for automated tests.
 *
 * Stores the last created MapLibreMap instance so that ohosTest
 * integration tests can access and test the map API directly.
 *
 * This is used by MapAutomationTestPage and consumed by ohosTest files.
 */
import { MapLibreMap } from 'maplibre_harmony';

export class TestMapAccessor {
  private static mapInstance: MapLibreMap | null = null;
  private static mapReady: boolean = false;

  /**
   * Register a MapLibreMap instance for test access.
   * Called from onMapReady callback in test pages.
   */
  static setMapInstance(map: MapLibreMap): void {
    TestMapAccessor.mapInstance = map;
    TestMapAccessor.mapReady = true;
    console.info('[TestMapAccessor] Map instance registered');
  }

  /**
   * Get the registered MapLibreMap instance.
   * Returns null if no map has been registered.
   */
  static getMapInstance(): MapLibreMap | null {
    return TestMapAccessor.mapInstance;
  }

  /**
   * Check if a map instance is available.
   */
  static isMapReady(): boolean {
    return TestMapAccessor.mapReady && TestMapAccessor.mapInstance !== null;
  }

  /**
   * Clear the registered instance (for cleanup between tests).
   */
  static clear(): void {
    if (TestMapAccessor.mapInstance) {
      TestMapAccessor.mapInstance.destroy();
      TestMapAccessor.mapInstance = null;
    }
    TestMapAccessor.mapReady = false;
  }
}
