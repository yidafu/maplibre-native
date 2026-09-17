/**
 * DefaultStyles - default style URL constants.
 *
 * Provides commonly used MapLibre style URLs.
 * Migrated from Android TestStyles.kt.
 */

/**
 * DefaultStyleUrls - default style URL interface.
 */
export interface DefaultStyleUrls {
  // Legacy styles.
  bright: string;
  osm: string;
  dark: string;
  light: string;
  streets: string;
  satellite: string;

  // Styles migrated from Android TestStyles.
  demotiles: string;
  americana: string;
  openfreeMapLiberty: string;
  openfreeMapBright: string;
  awsOpenData: string;
  protomapsLight: string;
  protomapsDark: string;
  protomapsGrayscale: string;
  protomapsWhite: string;
  protomapsBlack: string;
}

/**
 * DEFAULT_STYLE_URLS - default style URL collection.
 *
 * Contains commonly used style URLs ready for MapView or MapLibreMap.
 */
export const DEFAULT_STYLE_URLS: DefaultStyleUrls = {
  /**
   * OpenStreetMap Bright style.
   */
  bright: 'https://tiles.openfreemap.org/styles/bright',

  /**
   * OpenStreetMap base style.
   */
  osm: 'https://demotiles.maplibre.org/style.json',

  /**
   * Dark style.
   */
  dark: 'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json',

  /**
   * Light style.
   */
  light: 'https://tiles.stadiamaps.com/styles/alidade_smooth.json',

  /**
   * Streets style.
   */
  streets: 'https://demotiles.maplibre.org/style.json',

  /**
   * Satellite style.
   */
  satellite: 'https://api.maptiler.com/maps/hybrid/style.json?key=get_your_own_OpIi9ZULNHzrESv6T2vL',

  // ========== Styles migrated from Android TestStyles.kt ==========

  /**
   * Demo Tiles style.
   */
  demotiles: 'https://demotiles.maplibre.org/style.json',

  /**
   * Americana style.
   */
  americana: 'https://americanamap.org/style.json',

  /**
   * OpenFreeMap Liberty style.
   */
  openfreeMapLiberty: 'https://tiles.openfreemap.org/styles/liberty',

  /**
   * OpenFreeMap Bright style.
   */
  openfreeMapBright: 'https://tiles.openfreemap.org/styles/bright',

  /**
   * AWS Open Data Standard Light style.
   */
  awsOpenData: 'https://maps.geo.us-east-2.amazonaws.com/maps/v0/maps/OpenDataStyle/style-descriptor?key=v1.public.eyJqdGkiOiI1NjY5ZTU4My0yNWQwLTQ5MjctODhkMS03OGUxOTY4Y2RhMzgifR_7GLT66TNRXhZJ4KyJ-GK1TPYD9DaWuc5o6YyVmlikVwMaLvEs_iqkCIydspe_vjmgUVsIQstkGoInXV_nd5CcmqRMMa-_wb66SxDdbeRDvmmkpy2Ow_LX9GJDgL2bbiCws0wupJPFDwWCWFLwpK9ICmzGvNcrPbX5uczOQL0N8V9iUvziA52a1WWkZucIf6MUViFRf3XoFkyAT15Ll0NDypAzY63Bnj8_zS8bOaCvJaQqcXM9lrbTusy8Ftq8cEbbK5aMFapXRjug7qcrzUiQ5sr0g23qdMvnKJQFfo7JuQn8vwAksxrQm6A0ByceEXSfyaBoVpFcTzEclxUomhY.NjAyMWJkZWUtMGMyOS00NmRkLThjZTMtODEyOTkzZTUyMTBi',

  /**
   * Protomaps Light style.
   */
  protomapsLight: 'https://api.protomaps.com/styles/v2/light.json?key=e761cc7daedf832a',

  /**
   * Protomaps Dark style.
   */
  protomapsDark: 'https://api.protomaps.com/styles/v2/dark.json?key=e761cc7daedf832a',

  /**
   * Protomaps Grayscale style.
   */
  protomapsGrayscale: 'https://api.protomaps.com/styles/v2/grayscale.json?key=e761cc7daedf832a',

  /**
   * Protomaps White style.
   */
  protomapsWhite: 'https://api.protomaps.com/styles/v2/white.json?key=e761cc7daedf832a',

  /**
   * Protomaps Black style.
   */
  protomapsBlack: 'https://api.protomaps.com/styles/v2/black.json?key=e761cc7daedf832a',

};

