/**
 * GeoJSON type exports.
 *
 * Every GeoJSON type is defined as an interface because the C++ layer returns plain JS objects.
 * Types are exported with an `I` prefix to avoid conflicts with classes in other modules (for example, annotations.Polygon).
 */

// Primitive geometry types exported with I-prefix
export { Point as IPoint } from './Point';

export { LineString as ILineString } from './LineString';

export { Polygon as IPolygon } from './Polygon';

// Multi* geometry types exported with I-prefix
export { MultiPoint as IMultiPoint } from './MultiPoint';

export { MultiLineString as IMultiLineString } from './MultiLineString';

export { MultiPolygon as IMultiPolygon } from './MultiPolygon';

// GeometryCollection exported with I-prefix
export { GeometryCollection as IGeometryCollection } from './GeometryCollection';

// Feature types exported with I-prefix
export { Feature as IFeature } from './Feature';

export { FeatureCollection as IFeatureCollection } from './FeatureCollection';

// Geometry union and helper types
export {
  Geometry, Position, Position2D, Position3D, GeoJSONObject
} from './Geometry';

