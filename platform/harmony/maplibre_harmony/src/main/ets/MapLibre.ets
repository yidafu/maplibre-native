import maplibre from 'libmaplibre.so';

/**
 * MapLibre 全局配置类
 * 
 * 在应用启动时调用配置方法，所有地图实例自动使用全局配置。
 * 
 * @example
 * ```typescript
 * // 在 EntryAbility.ets 的 onCreate 中配置
 * import { MapLibre } from '@ohos/maplibre';
 * 
 * export default class EntryAbility extends UIAbility {
 *   onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
 *     // 配置使用 Mapbox 服务
 *     MapLibre.useMapbox();
 *     MapLibre.setAccessToken('your_mapbox_access_token');
 *     
 *     // 或者使用 MapTiler
 *     // MapLibre.useMapTiler();
 *     // MapLibre.setAccessToken('your_maptiler_api_key');
 *   }
 * }
 * 
 * // 然后在地图中使用 mapbox:// URL
 * const options = new MapLibreMapOptions();
 * options.styleUrl = 'mapbox://styles/mapbox/streets-v11';
 * ```
 */
export class MapLibre {
  /**
   * 设置 Access Token（用于 Mapbox、MapTiler 等服务）
   * 
   * @param token API Key / Access Token
   * 
   * @example
   * ```typescript
   * MapLibre.setAccessToken('pk.eyJ1IjoieW91cnVzZXJuYW1lIiwiYSI6InlvdXJ0b2tlbiJ9');
   * ```
   */
  static setAccessToken(token: string): void {
    maplibre.setAccessToken(token);
  }
  
  /**
   * 获取当前配置的 Access Token
   * 
   * @returns 当前的 API Key / Access Token，如果未设置则返回空字符串
   */
  static getAccessToken(): string {
    return maplibre.getAccessToken();
  }
  
  /**
   * 使用 Mapbox 瓦片服务器配置
   * 
   * 配置后支持使用 mapbox:// 协议的 URL：
   * - 样式：mapbox://styles/mapbox/streets-v11
   * - 数据源：mapbox://mapbox.mapbox-terrain-dem-v1
   * 
   * 需要配合 setAccessToken() 使用。
   * 
   * @example
   * ```typescript
   * MapLibre.useMapbox();
   * MapLibre.setAccessToken('your_mapbox_token');
   * ```
   */
  static useMapbox(): void {
    maplibre.useMapboxConfiguration();
  }
  
  /**
   * 使用 MapTiler 瓦片服务器配置
   * 
   * 配置后支持使用 maptiler:// 协议的 URL：
   * - 样式：maptiler://maps/streets
   * - 数据源：maptiler://sources/outdoor
   * 
   * 需要配合 setAccessToken() 使用。
   * 
   * @example
   * ```typescript
   * MapLibre.useMapTiler();
   * MapLibre.setAccessToken('your_maptiler_key');
   * ```
   */
  static useMapTiler(): void {
    maplibre.useMapTilerConfiguration();
  }
  
  /**
   * 使用 MapLibre 默认瓦片服务器配置（开源，无需 token）
   * 
   * 这是默认配置，使用 MapLibre 官方提供的演示瓦片服务。
   * 支持使用 maplibre:// 协议的 URL。
   * 
   * 注意：演示服务可能有速率限制，不建议在生产环境使用。
   * 
   * @example
   * ```typescript
   * MapLibre.useMapLibre(); // 使用开源服务
   * // 无需设置 token
   * ```
   */
  static useMapLibre(): void {
    maplibre.useMapLibreConfiguration();
  }
  
  /**
   * 设置自定义 API Base URL
   * 
   * 用于配置自建瓦片服务器或其他第三方服务。
   * 
   * @param url 基础 URL（如 https://api.example.com）
   * 
   * @example
   * ```typescript
   * MapLibre.setApiBaseURL('https://tiles.example.com');
   * ```
   */
  static setApiBaseURL(url: string): void {
    maplibre.setApiBaseURL(url);
  }
  
  /**
   * 获取当前 API Base URL
   * 
   * @returns 当前配置的基础 URL
   */
  static getApiBaseURL(): string {
    return maplibre.getApiBaseURL();
  }
}

