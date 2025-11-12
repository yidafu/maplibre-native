/**
 * MapLibre Native for HarmonyOS - sources index.
 * Central export for source type definitions.
 */

import { GeoJsonSource } from './GeoJsonSource';
import { ImageSource } from './ImageSource';
import { RasterDemSource } from './RasterDemSource';
import { RasterSource } from './RasterSource';
import { VectorSource } from './VectorSource';

export { GeoJsonSource, GeoJsonOptions } from './GeoJsonSource';

export { VectorSource, VectorSourceOptions } from './VectorSource';

export { RasterSource, RasterSourceOptions } from './RasterSource';

export { RasterDemSource, RasterDemSourceOptions } from './RasterDemSource';

export { ImageSource } from './ImageSource';

/**
 * Source - union of all source types used by the Style API.
 */
export type Source =
  | GeoJsonSource
    | VectorSource
    | RasterSource
    | RasterDemSource
    | ImageSource;

