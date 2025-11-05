/**
 * Declarative Components - 声明式组件统一导出
 * 
 * 提供类似 Jetpack Compose / SwiftUI 风格的声明式 API
 * 用于构建地图应用的 UI 组件
 * 
 * @example
 * ```typescript
 * import { MapView, MarkerComponent, GeoJsonSourceComponent, SymbolLayerComponent } from 'maplibre_harmony';
 * 
 * @Entry
 * @Component
 * struct MapPage {
 *   build() {
 *     MapView({
 *       styleUrl: DEFAULT_STYLE_URLS.streets,
 *       initialLatitude: 39.9,
 *       initialLongitude: 116.4,
 *       initialZoom: 10
 *     }) {
 *       MarkerComponent({
 *         position: { latitude: 39.9, longitude: 116.4 },
 *         title: 'My Marker'
 *       })
 *       
 *       GeoJsonSourceComponent({
 *         id: 'my-source',
 *         geojson: geojsonData
 *       }) {
 *         SymbolLayerComponent({
 *           id: 'my-layer',
 *           iconImage: 'marker-icon',
 *           iconSize: 1.5
 *         })
 *       }
 *     }
 *   }
 * }
 * ```
 * 
 * @packageDocumentation
 */

// 导出 Marker 组件
export { MarkerComponent } from './MarkerComponent';
export type { MarkerComponentParams } from './MarkerComponent';

// 导出 Source 组件
export { GeoJsonSourceComponent } from './sources/GeoJsonSourceComponent';
export type { GeoJsonSourceComponentParams } from './sources/GeoJsonSourceComponent';

// 导出 Layer 组件
export { SymbolLayerComponent } from './layers/SymbolLayerComponent';
export { LineLayerComponent } from './layers/LineLayerComponent';
export { FillLayerComponent } from './layers/FillLayerComponent';
export { CircleLayerComponent } from './layers/CircleLayerComponent';

