/**
 * MapLibre Native for HarmonyOS - Layers Index
 * 图层类型定义统一导出
 */

import { BackgroundLayer } from './BackgroundLayer';
import { CircleLayer } from './CircleLayer';
import { CustomLayer } from './CustomLayer';
import { FillExtrusionLayer } from './FillExtrusionLayer';
import { FillLayer } from './FillLayer';
import { HeatmapLayer } from './HeatmapLayer';
import { HillshadeLayer } from './HillshadeLayer';
import { LineLayer } from './LineLayer';
import { RasterLayer } from './RasterLayer';
import { SymbolLayer } from './SymbolLayer';

export { FillLayer } from './FillLayer';

export { LineLayer } from './LineLayer';

export { CircleLayer } from './CircleLayer';

export { SymbolLayer } from './SymbolLayer';

export { BackgroundLayer } from './BackgroundLayer';

export { RasterLayer } from './RasterLayer';

export { HeatmapLayer } from './HeatmapLayer';

export { HillshadeLayer } from './HillshadeLayer';

export { FillExtrusionLayer } from './FillExtrusionLayer';

export { CustomLayer } from './CustomLayer';

/**
 * Layer - 所有图层类型的联合类型
 * 用于 Style API 中的类型安全
 */
export type Layer =
  | FillLayer
    | LineLayer
    | CircleLayer
    | SymbolLayer
    | BackgroundLayer
    | RasterLayer
    | HeatmapLayer
    | HillshadeLayer
    | FillExtrusionLayer
    | CustomLayer;

