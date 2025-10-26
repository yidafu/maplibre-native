/**
 * MapLibre Native for HarmonyOS - Type Definitions
 * 主入口文件
 * 
 * 此文件重新导出所有类型定义，提供统一的访问入口
 */

// ========== 核心组件 ==========

/**
 * NativeMapView - 地图视图主类
 * 提供地图渲染、相机控制、图层管理等核心功能
 */
export * from './NativeMapView';

/**
 * Style - 样式管理 API
 * 提供地图样式、数据源、图层、图像、光照和过渡效果的管理功能
 */
export { Style } from './Style';

// ========== 数据源 (Sources) ==========

/**
 * GeoJsonSource - GeoJSON 数据源
 * 支持点、线、面等矢量要素，支持聚类
 */
export * as GeoJsonSource from './sources/GeoJsonSource';

/**
 * VectorSource - 矢量瓦片数据源
 * 用于加载 Mapbox Vector Tiles (MVT) 格式的数据
 */
export * as VectorSource from './sources/VectorSource';

/**
 * RasterSource - 栅格瓦片数据源
 * 用于加载栅格瓦片图像
 */
export * as RasterSource from './sources/RasterSource';

/**
 * RasterDemSource - 栅格 DEM 数据源
 * 用于加载数字高程模型数据
 */
export * as RasterDemSource from './sources/RasterDemSource';

/**
 * ImageSource - 图像数据源
 * 用于在指定的地理坐标范围内显示单张图像
 */
export * as ImageSource from './sources/ImageSource';

// ========== 图层 (Layers) ==========

/**
 * FillLayer - 填充图层
 * 用于渲染多边形填充
 */
export * as FillLayer from './layers/FillLayer';

/**
 * LineLayer - 线图层
 * 用于渲染线要素
 */
export * as LineLayer from './layers/LineLayer';

/**
 * CircleLayer - 圆形图层
 * 用于渲染圆形点要素
 */
export * as CircleLayer from './layers/CircleLayer';

/**
 * SymbolLayer - 符号图层
 * 用于渲染图标和文本标注
 */
export * as SymbolLayer from './layers/SymbolLayer';

/**
 * RasterLayer - 栅格图层
 * 用于渲染栅格瓦片数据
 */
export * as RasterLayer from './layers/RasterLayer';

/**
 * BackgroundLayer - 背景图层
 * 用于渲染地图背景
 */
export * as BackgroundLayer from './layers/BackgroundLayer';

/**
 * HeatmapLayer - 热力图层
 * 用于渲染密度热力图
 */
export * as HeatmapLayer from './layers/HeatmapLayer';

/**
 * HillshadeLayer - 山体阴影图层
 * 用于渲染地形阴影效果
 */
export * as HillshadeLayer from './layers/HillshadeLayer';

/**
 * FillExtrusionLayer - 3D 填充拉伸图层
 * 用于渲染 3D 建筑物等拉伸效果
 */
export * as FillExtrusionLayer from './layers/FillExtrusionLayer';
