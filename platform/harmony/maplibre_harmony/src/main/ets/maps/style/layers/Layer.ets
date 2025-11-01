/**
 * Layer - 图层类型定义
 * 
 * 图层由 NAPI 层提供，此文件仅提供辅助类型定义
 */

// Layer 类型由 NAPI 提供，通过 maplibre.XXXLayer 访问
// 定义 Layer 类型别名用于类型标注
export type Layer = Object;

/**
 * LayerFilter - 图层过滤器类型
 * 
 * MapLibre表达式数组，用于过滤要素
 * @example
 * ["==", ["get", "type"], "restaurant"]
 * ["all", [">=", ["get", "price"], 10], ["<", ["get", "price"], 100]]
 */
export type LayerFilter = Object[] | null;

/**
 * LayerLayout - 图层布局属性类型
 * 
 * 布局属性控制图层的几何位置和可见性
 */
export type LayerLayout = Record<string, Object>;

/**
 * LayerPaint - 图层绘制属性类型
 * 
 * 绘制属性控制图层的视觉样式
 */
export type LayerPaint = Record<string, Object>;

/**
 * LayerMetadata - 图层元数据类型
 * 
 * 用于存储图层的自定义元数据
 */
export type LayerMetadata = Record<string, Object> | null;

/**
 * LayerOptions - 图层选项接口
 * 
 * 用于构建图层的配置选项
 */
export interface LayerOptions {
  /** 图层 ID */
  id: string;
  /** 图层类型: 'fill', 'line', 'symbol', 'circle', 'heatmap', 'fill-extrusion', 'raster', 'hillshade', 'background' */
  type: string;
  /** 数据源 ID */
  source: string;
  /** 源图层名称 (矢量瓦片) */
  sourceLayer?: string;
  /** 最小缩放级别 */
  minZoom?: number;
  /** 最大缩放级别 */
  maxZoom?: number;
  /** 过滤器表达式 */
  filter?: LayerFilter;
  /** 布局属性 */
  layout?: LayerLayout;
  /** 绘制属性 */
  paint?: LayerPaint;
  /** 元数据 */
  metadata?: LayerMetadata;
}
