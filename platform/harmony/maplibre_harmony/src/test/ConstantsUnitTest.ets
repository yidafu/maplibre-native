/**
 * Constants Unit Tests
 *
 * Tests for the MapLibre HarmonyOS constants:
 * DEFAULT_STYLE_URLS, SDK version, HiLogConstants
 */
import { describe, it, expect } from '@ohos/hypium';
import { DEFAULT_STYLE_URLS } from '../main/ets/maps/constants/DefaultStyles';
import { DOMAIN } from '../main/ets/constants/HiLogConstants';

export default function ConstantsUnitTest() {
  // ==================== DEFAULT_STYLE_URLS ====================
  describe('DEFAULT_STYLE_URLS', () => {
    it('should provide all legacy style URLs', 0, () => {
      expect(DEFAULT_STYLE_URLS.bright !== undefined && DEFAULT_STYLE_URLS.bright.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.osm !== undefined && DEFAULT_STYLE_URLS.osm.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.dark !== undefined && DEFAULT_STYLE_URLS.dark.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.light !== undefined && DEFAULT_STYLE_URLS.light.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.streets !== undefined && DEFAULT_STYLE_URLS.streets.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.satellite !== undefined && DEFAULT_STYLE_URLS.satellite.length > 0).assertTrue();
    });

    it('should provide migrated Android test style URLs', 0, () => {
      expect(DEFAULT_STYLE_URLS.demotiles !== undefined && DEFAULT_STYLE_URLS.demotiles.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.americana !== undefined && DEFAULT_STYLE_URLS.americana.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.openfreeMapLiberty !== undefined && DEFAULT_STYLE_URLS.openfreeMapLiberty.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.openfreeMapBright !== undefined && DEFAULT_STYLE_URLS.openfreeMapBright.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.awsOpenData !== undefined && DEFAULT_STYLE_URLS.awsOpenData.length > 0).assertTrue();
    });

    it('should provide Protomaps style URLs', 0, () => {
      expect(DEFAULT_STYLE_URLS.protomapsLight !== undefined && DEFAULT_STYLE_URLS.protomapsLight.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.protomapsDark !== undefined && DEFAULT_STYLE_URLS.protomapsDark.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.protomapsGrayscale !== undefined && DEFAULT_STYLE_URLS.protomapsGrayscale.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.protomapsWhite !== undefined && DEFAULT_STYLE_URLS.protomapsWhite.length > 0).assertTrue();
      expect(DEFAULT_STYLE_URLS.protomapsBlack !== undefined && DEFAULT_STYLE_URLS.protomapsBlack.length > 0).assertTrue();
    });

    it('all URL values should be strings', 0, () => {
      const urlValues: string[] = [
        DEFAULT_STYLE_URLS.bright,
        DEFAULT_STYLE_URLS.osm,
        DEFAULT_STYLE_URLS.dark,
        DEFAULT_STYLE_URLS.light,
        DEFAULT_STYLE_URLS.streets,
        DEFAULT_STYLE_URLS.satellite,
        DEFAULT_STYLE_URLS.demotiles,
        DEFAULT_STYLE_URLS.americana,
        DEFAULT_STYLE_URLS.openfreeMapLiberty,
        DEFAULT_STYLE_URLS.openfreeMapBright,
        DEFAULT_STYLE_URLS.awsOpenData,
        DEFAULT_STYLE_URLS.protomapsLight,
        DEFAULT_STYLE_URLS.protomapsDark,
        DEFAULT_STYLE_URLS.protomapsGrayscale,
        DEFAULT_STYLE_URLS.protomapsWhite,
        DEFAULT_STYLE_URLS.protomapsBlack,
      ];
      for (let i = 0; i < urlValues.length; i++) {
        expect(typeof urlValues[i]).assertEqual('string');
        expect(urlValues[i].length).assertLarger(0);
      }
    });

    it('should start with https://', 0, () => {
      expect(DEFAULT_STYLE_URLS.streets.substring(0, 8)).assertEqual('https://');
      expect(DEFAULT_STYLE_URLS.demotiles.substring(0, 8)).assertEqual('https://');
    });
  });

  // ==================== HiLogConstants ====================
  describe('HiLogConstants', () => {
    it('DOMAIN should be a number', 0, () => {
      expect(typeof DOMAIN).assertEqual('number');
    });

    it('DOMAIN should be 0x0000', 0, () => {
      expect(DOMAIN).assertEqual(0x0000);
    });
  });
}
