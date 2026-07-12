/**
 * MapLibre Native for HarmonyOS - layers index.
 * Central export for layer type definitions.
 */

import { BackgroundLayer } from './BackgroundLayer';
import { CircleLayer } from './CircleLayer';
import { CustomLayer } from './CustomLayer';
import { FillExtrusionLayer } from './FillExtrusionLayer';
import { FillLayer } from './FillLayer';
import { HeatmapLayer } from './HeatmapLayer';
import { HillshadeLayer } from './HillshadeLayer';
import { ColorReliefLayer } from './ColorReliefLayer';
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

export { ColorReliefLayer } from './ColorReliefLayer';

export { FillExtrusionLayer } from './FillExtrusionLayer';

export { CustomLayer } from './CustomLayer';

/**
 * Layer - union of all layer types.
 * Used to preserve type safety in the Style API.
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
    | ColorReliefLayer
    | FillExtrusionLayer
    | CustomLayer;

