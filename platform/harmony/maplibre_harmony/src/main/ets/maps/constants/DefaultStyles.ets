/**
 * DefaultStyles - 默认样式 URL 常量
 *
 * 提供常用的 MapLibre 样式 URL
 * 迁移自 Android TestStyles.kt
 */

/**
 * DefaultStyleUrls - 默认样式 URL 接口
 */
export interface DefaultStyleUrls {
  // 原有样式
  bright: string;
  osm: string;
  dark: string;
  light: string;
  streets: string;
  satellite: string;

  // 从 Android TestStyles 迁移的样式
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
 * DEFAULT_STYLE_URLS - 默认样式 URL 对象
 *
 * 包含常用的样式 URL,可直接用于 MapView 或 MapLibreMap
 */
export const DEFAULT_STYLE_URLS: DefaultStyleUrls = {
  /**
   * OpenStreetMap Bright 样式
   */
  bright: 'https://tiles.openfreemap.org/styles/bright',

  /**
   * OpenStreetMap 基础样式
   */
  osm: 'https://demotiles.maplibre.org/style.json',

  /**
   * 深色样式
   */
  dark: 'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json',

  /**
   * 浅色样式
   */
  light: 'https://tiles.stadiamaps.com/styles/alidade_smooth.json',

  /**
   * 街道样式
   */
  streets: 'https://demotiles.maplibre.org/style.json',

  /**
   * 卫星样式
   */
  satellite: 'https://api.maptiler.com/maps/hybrid/style.json?key=get_your_own_OpIi9ZULNHzrESv6T2vL',

  // ========== 从 Android TestStyles.kt 迁移的样式 ==========

  /**
   * Demo Tiles 样式
   */
  demotiles: 'https://demotiles.maplibre.org/style.json',

  /**
   * Americana 样式
   */
  americana: 'https://americanamap.org/style.json',

  /**
   * OpenFreeMap Liberty 样式
   */
  openfreeMapLiberty: 'https://tiles.openfreemap.org/styles/liberty',

  /**
   * OpenFreeMap Bright 样式
   */
  openfreeMapBright: 'https://tiles.openfreemap.org/styles/bright',

  /**
   * AWS Open Data Standard Light 样式
   */
  awsOpenData: 'https://maps.geo.us-east-2.amazonaws.com/maps/v0/maps/OpenDataStyle/style-descriptor?key=v1.public.eyJqdGkiOiI1NjY5ZTU4My0yNWQwLTQ5MjctODhkMS03OGUxOTY4Y2RhMzgifR_7GLT66TNRXhZJ4KyJ-GK1TPYD9DaWuc5o6YyVmlikVwMaLvEs_iqkCIydspe_vjmgUVsIQstkGoInXV_nd5CcmqRMMa-_wb66SxDdbeRDvmmkpy2Ow_LX9GJDgL2bbiCws0wupJPFDwWCWFLwpK9ICmzGvNcrPbX5uczOQL0N8V9iUvziA52a1WWkZucIf6MUViFRf3XoFkyAT15Ll0NDypAzY63Bnj8_zS8bOaCvJaQqcXM9lrbTusy8Ftq8cEbbK5aMFapXRjug7qcrzUiQ5sr0g23qdMvnKJQFfo7JuQn8vwAksxrQm6A0ByceEXSfyaBoVpFcTzEclxUomhY.NjAyMWJkZWUtMGMyOS00NmRkLThjZTMtODEyOTkzZTUyMTBi',

  /**
   * Protomaps Light 样式
   */
  protomapsLight: 'https://api.protomaps.com/styles/v2/light.json?key=e761cc7daedf832a',

  /**
   * Protomaps Dark 样式
   */
  protomapsDark: 'https://api.protomaps.com/styles/v2/dark.json?key=e761cc7daedf832a',

  /**
   * Protomaps Grayscale 样式
   */
  protomapsGrayscale: 'https://api.protomaps.com/styles/v2/grayscale.json?key=e761cc7daedf832a',

  /**
   * Protomaps White 样式
   */
  protomapsWhite: 'https://api.protomaps.com/styles/v2/white.json?key=e761cc7daedf832a',

  /**
   * Protomaps Black 样式
   */
  protomapsBlack: 'https://api.protomaps.com/styles/v2/black.json?key=e761cc7daedf832a',

};

