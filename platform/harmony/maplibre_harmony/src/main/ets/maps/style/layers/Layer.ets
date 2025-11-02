/**
 * Layer - 图层类型定义
 * 
 * 图层由 NAPI 层提供，此文件仅提供辅助类型定义
 */

import { FillLayer } from './FillLayer';
import { LineLayer } from './LineLayer';
import { SymbolLayer } from './SymbolLayer';
import { CircleLayer } from './CircleLayer';
import { HeatmapLayer } from './HeatmapLayer';
import { FillExtrusionLayer } from './FillExtrusionLayer';
import { RasterLayer } from './RasterLayer';
import { HillshadeLayer } from './HillshadeLayer';
import { BackgroundLayer } from './BackgroundLayer';
import type { FilterExpression } from './Expression';
import type {
  BackgroundLayout,
  FillLayout,
  LineLayout,
  SymbolLayout,
  CircleLayout,
  HeatmapLayout,
  FillExtrusionLayout,
  RasterLayout,
  HillshadeLayout
} from './LayerLayout';
import type {
  BackgroundPaint,
  FillPaint,
  LinePaint,
  SymbolPaint,
  CirclePaint,
  HeatmapPaint,
  FillExtrusionPaint,
  RasterPaint,
  HillshadePaint
} from './LayerPaint';
import { CustomLayer } from '..';

// Layer 类型是所有具体图层类型的联合类型
export type Layer = 
  | FillLayer 
  | LineLayer 
  | SymbolLayer 
  | CircleLayer 
  | HeatmapLayer 
  | FillExtrusionLayer 
  | RasterLayer 
  | HillshadeLayer 
  | BackgroundLayer
  | CustomLayer;

/**
 * LayerFilter - 图层过滤器类型
 * 
 * MapLibre 表达式数组，用于过滤要素
 * 
 * @see https://maplibre.org/maplibre-style-spec/layers/#filter
 * @example
 * ["==", ["get", "type"], "restaurant"]
 * ["all", [">=", ["get", "price"], 10], ["<", ["get", "price"], 100]]
 * ["in", "class", ["literal", ["motorway", "trunk"]]]
 */
export type LayerFilter = FilterExpression | null;

/**
 * LayerLayout - 图层布局属性类型
 * 
 * 布局属性控制图层的几何位置和可见性
 * 每种图层类型都有特定的布局属性集
 * 
 * @see https://maplibre.org/maplibre-style-spec/layers/#layout
 */
export type LayerLayout = 
  | BackgroundLayout 
  | FillLayout 
  | LineLayout 
  | SymbolLayout 
  | CircleLayout 
  | HeatmapLayout 
  | FillExtrusionLayout 
  | RasterLayout 
  | HillshadeLayout;

/**
 * LayerPaint - 图层绘制属性类型
 * 
 * 绘制属性控制图层的视觉样式
 * 每种图层类型都有特定的绘制属性集
 * 
 * @see https://maplibre.org/maplibre-style-spec/layers/#paint
 */
export type LayerPaint = 
  | BackgroundPaint 
  | FillPaint 
  | LinePaint 
  | SymbolPaint 
  | CirclePaint 
  | HeatmapPaint 
  | FillExtrusionPaint 
  | RasterPaint 
  | HillshadePaint;

/**
 * LayerMetadata - 图层元数据类型
 * 
 * 用于存储图层的自定义元数据
 * 这是用户自定义的任意数据，不受 MapLibre 规范限制
 * 
 * @see https://maplibre.org/maplibre-style-spec/layers/#metadata
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
