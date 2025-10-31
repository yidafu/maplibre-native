import { LatLng } from 'maplibre_harmony';
/**
 * 测试工具函数
 * 提供测试页面常用的工具方法
 */
import { promptAction } from '@kit.ArkUI';

/**
 * 显示 Toast 提示
 */
export function showToast(message: string, duration: number = 2000): void {
  promptAction.showToast({
    message: message,
    duration: duration,
    bottom: 100
  });
}

/**
 * 格式化坐标显示
 */
export function formatLatLng(lat: number, lng: number, decimals: number = 6): string {
  return `${lat.toFixed(decimals)}, ${lng.toFixed(decimals)}`;
}

/**
 * 格式化 LatLng 对象显示
 */
export function formatLatLngObject(latLng: LatLng, decimals: number = 6): string {
  return formatLatLng(latLng.latitude, latLng.longitude, decimals);
}

/**
 * 生成随机坐标
 */
export function randomLatLng(
  minLat: number = -85,
  maxLat: number = 85,
  minLng: number = -180,
  maxLng: number = 180
): LatLng {
  const lat = Math.random() * (maxLat - minLat) + minLat;
  const lng = Math.random() * (maxLng - minLng) + minLng;
  return new LatLng(lat, lng);
}

/**
 * 生成随机颜色
 */
export function randomColor(): string {
  const letters = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];
  let color = '#';
  for (let i = 0; i < 6; i++) {
    color += letters[Math.floor(Math.random() * 16)];
  }
  return color;
}

/**
 * 延迟执行
 */
export function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 默认地图样式 URL
 */
export class StyleUrls {
  streets: string = 'https://demotiles.maplibre.org/style.json';
  satellite: string = 'https://api.maptiler.com/maps/hybrid/style.json?key=YOUR_KEY';
  dark: string = 'https://api.maptiler.com/maps/dark/style.json?key=YOUR_KEY';
}

export const DEFAULT_STYLE_URLS = new StyleUrls();

/**
 * 默认测试坐标
 */
export class TestLocations {
  beijing: LatLng = new LatLng(39.9042, 116.4074);
  shanghai: LatLng = new LatLng(31.2304, 121.4737);
  guangzhou: LatLng = new LatLng(23.1291, 113.2644);
  shenzhen: LatLng = new LatLng(22.5431, 114.0579);
  hangzhou: LatLng = new LatLng(30.2741, 120.1551);
  chengdu: LatLng = new LatLng(30.5728, 104.0668);
  xian: LatLng = new LatLng(34.3416, 108.9398);
  wuhan: LatLng = new LatLng(30.5928, 114.3055);
  london: LatLng = new LatLng(51.5074, -0.1278);
  nyc: LatLng = new LatLng(40.7128, -74.0060);
  sf: LatLng = new LatLng(37.7749, -122.4194);
  tokyo: LatLng = new LatLng(35.6762, 139.6503);
}

export const TEST_LOCATIONS = new TestLocations();

/**
 * 加载 GeoJSON 数据（示例）
 */
export async function loadGeoJson(url: string): Promise<object | null> {
  try {
    // TODO: 实现真实的网络请求
    console.warn(`loadGeoJson: stub implementation for ${url}`);
    return null;
  } catch (error) {
    console.error(`Failed to load GeoJSON: ${error}`);
    return null;
  }
}

/**
 * 计算两点间距离（km）
 */
export function calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371; // 地球半径（km）
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

