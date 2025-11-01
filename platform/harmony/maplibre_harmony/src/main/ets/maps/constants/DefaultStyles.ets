/**
 * DefaultStyles - 默认样式 URL 常量
 * 
 * 提供常用的 MapLibre 样式 URL
 */

/**
 * DefaultStyleUrls - 默认样式 URL 接口
 */
export interface DefaultStyleUrls {
  bright: string;
  osm: string;
  dark: string;
  light: string;
  streets: string;
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
  bright: 'https://demotiles.maplibre.org/style.json',
  
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
  streets: 'https://demotiles.maplibre.org/style.json'
};

