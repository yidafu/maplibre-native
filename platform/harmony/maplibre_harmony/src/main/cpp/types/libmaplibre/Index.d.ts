/**
 * MapLibre Native for HarmonyOS - Type Definitions
 * 主入口文件
 *
 * 此文件重新导出所有类型定义，提供统一的访问入口
 */

// ========== 核心组件 ==========

/**
 * LatLng - 经纬度坐标接口
 * 注意：已改为 ETS 层实现，这里仅作为类型定义导出
 */
export { LatLng } from './NativeMapView';

/**
 * NativeMapView - 地图视图主类
 * 提供地图渲染、相机控制、图层管理等核心功能
 */
export * from './NativeMapView';

/**
 * Marker - 地图标记点
 * 表示地图上的一个点标注，由 C++ NAPI 层实现
 */
export { Marker, MarkerOptions } from './Marker';

/**
 * Polygon - 多边形标注
 * 表示地图上的多边形标注，由 C++ NAPI 层实现
 */
export { Polygon } from './annotations/Polygon';

/**
 * Polyline - 折线标注
 * 表示地图上的折线标注，由 C++ NAPI 层实现
 */
export { Polyline } from './annotations/Polyline';

/**
 * Icon - 图标类
 * 表示地图标注的图标，由 C++ NAPI 层实现
 * 包含图标的位图数据和元信息
 */
export { Icon } from './Icon';

/**
 * IconFactory - 图标工厂类（静态工厂方法）
 * 提供零复制的高性能图标创建方法，由 C++ NAPI 层实现
 */
export { IconFactory } from './IconFactory';

/**
 * Style - 样式管理类 (NAPI 对象)
 * 提供面向对象的样式管理接口
 *
 * StyleBuilder - 样式构建器
 * 使用 Builder 模式构建地图样式
 */
export { Style, StyleBuilder } from './Style';

// ========== GeoJSON 类型 (NAPI 类) ==========

/**
 * GeoJSON 类型
 * 所有 GeoJSON 几何体和特征类型都由 C++ NAPI 层实现
 */
export * from './geojson';

// ========== 属性值类型 ==========

/**
 * Expression 类型定义
 * 包含：ExpressionLiteral、ExpressionValue 以及所有具体的表达式类型
 * （ComparisonExpression、LogicalExpression、MathExpression 等）
 */
export * from './ExpressionTypes';

/**
 * Layer 属性值类型
 * 包含：PropertyValue、ColorValue、NumberValue、StringValue、BooleanValue
 */
export * from './LayerPropertyTypes';

// ========== 数据源 (Sources) - NAPI 类 ==========

/**
 * 所有数据源类型和联合类型
 * 包含：GeoJsonSource、VectorSource、RasterSource、RasterDemSource、ImageSource
 * 以及联合类型 Source 和对应的 Options 接口
 */
export * from './sources';

/**
 * Image - 样式图像类（NAPI 对象）
 * 用于在地图样式中添加自定义图片资源
 */
export { Image, ImageOptions } from './images/Image';

// ========== 图层 (Layers) ==========

/**
 * 所有图层类型和联合类型
 * 包含：FillLayer、LineLayer、CircleLayer、SymbolLayer、BackgroundLayer、
 *       RasterLayer、HeatmapLayer、HillshadeLayer、FillExtrusionLayer
 * 以及联合类型 Layer
 */
export * from './layers';

// ========== 离线地图 (Offline) ==========

/**
 * OfflineManager - 离线地图管理器
 * OfflineRegion - 离线区域
 * 离线地图下载、管理和使用功能
 */
export * from './offline';
