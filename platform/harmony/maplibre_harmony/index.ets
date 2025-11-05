/**
 * MapLibre Native for HarmonyOS
 * 
 * 提供完整的矢量地图渲染和交互功能，支持：
 * - 丰富的地图样式和自定义图层
 * - 流畅的手势交互和动画
 * - 标注（Marker、Polygon、Polyline）管理
 * - 离线地图和数据缓存
 * - 位置跟踪和定位服务
 * 
 * **快速开始**：
 * 1. 创建地图视图组件 `MapView`
 * 2. 配置地图选项 `MapLibreMapOptions`
 * 3. 添加标注和图层
 * 4. 监听地图事件
 * 
 * @example
 * ```typescript
 * import { MapView, MapLibreMap, DEFAULT_STYLE_URLS } from '@ohos/maplibre';
 * 
 * @Entry
 * @Component
 * struct MapPage {
 *   private map: MapLibreMap | null = null;
 * 
 *   build() {
 *     Column() {
 *       MapView({
 *         styleUrl: DEFAULT_STYLE_URLS.streets,
 *         onMapReady: (map: MapLibreMap) => {
 *           this.map = map;
 *           map.setLatLng(39.9, 116.4);
 *           map.setZoom(12);
 *         }
 *       })
 *     }
 *   }
 * 
 *   aboutToDisappear() {
 *     this.map?.destroy();
 *   }
 * }
 * ```
 * 
 * @module @ohos/maplibre
 * @packageDocumentation
 */

// 导出所有公共 API
export * from './src/main/ets/maps/index';

// 导出常用辅助类型
export type {
  ILatLng,
  RectangleLiteral,
  Size,
  Padding,
  Margins,
  CameraOptionsLiteral
} from './src/main/ets/maps/types/NativeTypes';

// ========== 声明式组件 (Declarative API) ==========
// 由于 ArkTS 限制（属性名冲突、不支持 @Watch 等），声明式 API 暂时不可用
// 请使用命令式 API（MapLibreMap.addMarker, Style.addLayer 等）
// 参考文档: docs/DECLARATIVE_API_LIMITATIONS.md


