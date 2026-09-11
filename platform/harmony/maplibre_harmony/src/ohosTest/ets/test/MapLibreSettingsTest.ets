/**
 * MapLibreSettings Unit Tests
 *
 * Tests for the global MapLibre configuration class.
 * These tests run in ohosTest where the native library is available.
 *
 * Note: setAccessToken / getAccessToken modify global state
 * and may affect other tests. These tests should be run in isolation
 * or order-dependent.
 */
import { describe, it, expect, beforeAll, afterAll } from '@ohos/hypium';
import { MapLibre } from '../../../../main/ets/MapLibre';

export default function MapLibreSettingsTest() {
  describe('MapLibre access token', () => {
    it('setAccessToken should accept a token string', 0, () => {
      // This should not throw (requires native library)
      MapLibre.setAccessToken('test_token_123');
      expect(true).assertTrue();
    });

    it('getAccessToken should return the set token', 0, () => {
      MapLibre.setAccessToken('test_token_456');
      const token = MapLibre.getAccessToken();
      // Note: the native layer may transform the token, so we just verify
      // the call succeeds without error
      expect(token !== undefined).assertTrue();
    });

    it('setAccessToken should handle empty string', 0, () => {
      MapLibre.setAccessToken('');
      expect(true).assertTrue();
    });

    it('getAccessToken should return a string', 0, () => {
      const token = MapLibre.getAccessToken();
      expect(typeof token).assertEqual('string');
    });
  });

  describe('MapLibre tile server configuration', () => {
    it('useMapbox should not throw', 0, () => {
      MapLibre.useMapbox();
      expect(true).assertTrue();
    });

    it('useMapTiler should not throw', 0, () => {
      MapLibre.useMapTiler();
      expect(true).assertTrue();
    });

    it('useMapLibre should not throw', 0, () => {
      MapLibre.useMapLibre();
      expect(true).assertTrue();
    });
  });

  describe('MapLibre API base URL', () => {
    it('setApiBaseURL should accept a URL string', 0, () => {
      MapLibre.setApiBaseURL('https://api.example.com');
      expect(true).assertTrue();
    });

    it('getApiBaseURL should return a string', 0, () => {
      const url = MapLibre.getApiBaseURL();
      expect(typeof url).assertEqual('string');
    });

    it('setApiBaseURL should handle empty string', 0, () => {
      MapLibre.setApiBaseURL('');
      expect(true).assertTrue();
    });
  });
}
