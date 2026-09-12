/**
 * MapLibre Native for HarmonyOS - type definitions.
 * Entry point module.
 *
 * Re-exports every type definition to provide a unified access surface.
 */

// ========== Core components ==========

/**
 * LatLng - latitude/longitude interface.
 * Note: implemented in the ETS layer; exported here for compatibility.
 */
export { LatLng } from './NativeMapView';

/**
 * NativeMapView - primary map view class.
 * Offers rendering, camera control, and layer management.
 */
export * from './NativeMapView';

/**
 * Marker - map marker point.
 * Represents a point annotation implemented in the C++ NAPI layer.
 */
export { Marker, MarkerOptions } from './Marker';

/**
 * Polygon - polygon annotation.
 * Represents polygon overlays implemented in C++ NAPI.
 */
export { Polygon } from './annotations/Polygon';

/**
 * Polyline - polyline annotation.
 * Represents polylines implemented in C++ NAPI.
 */
export { Polyline } from './annotations/Polyline';

/**
 * Icon - icon class.
 * Represents marker icons with bitmap data and metadata provided by C++ NAPI.
 */
export { Icon } from './Icon';

/**
 * IconFactory - icon factory (static factory methods).
 * Supplies zero-copy, high-performance icon creation backed by C++ NAPI.
 */
export { IconFactory } from './IconFactory';

/**
 * Style - style management class (NAPI object).
 * Provides an object-oriented API for style manipulation.
 *
 * StyleBuilder - style builder.
 * Uses the builder pattern to assemble map styles.
 */
export { Style, StyleBuilder } from './Style';

/**
 * Light - style lighting controller.
 */
export { Light } from './light/Light';

// ========== GeoJSON types (NAPI classes) ==========

/**
 * GeoJSON types.
 * All geometries and feature variants are implemented in the C++ NAPI layer.
 */
export * from './geojson';

// ========== Property value types ==========

/**
 * Expression type definitions.
 * Includes ExpressionLiteral, ExpressionValue, and all concrete expression types
 * (ComparisonExpression, LogicalExpression, MathExpression, etc.).
 */
export * from './ExpressionTypes';

/**
 * Layer property value types.
 * Includes PropertyValue (concrete value or expression literal).
 */
export * from './LayerPropertyTypes';

// ========== Sources (NAPI classes) ==========

/**
 * All source types and unions.
 * Includes GeoJsonSource, VectorSource, RasterSource, RasterDemSource, ImageSource,
 * plus the Source union and related option interfaces.
 */
export * from './sources';

/**
 * Image - style image class (NAPI object).
 * Adds custom images to map styles.
 */
export { Image, ImageOptions } from './images/Image';

// ========== Layers ==========

/**
 * All layer types and unions.
 * Includes FillLayer, LineLayer, CircleLayer, SymbolLayer, BackgroundLayer,
 *       RasterLayer, HeatmapLayer, HillshadeLayer, FillExtrusionLayer,
 *       ColorReliefLayer, LocationIndicatorLayer and the Layer union.
 */
export * from './layers';

// ========== Offline maps ==========

/**
 * OfflineManager - offline map manager.
 * OfflineRegion - offline region.
 * Provides download, management, and usage of offline maps.
 */
export * from './offline';

// ========== Common types ==========

/**
 * CommonTypes - shared type definitions.
 * LightSpecification - lighting configuration.
 * TransitionOptions - transition options.
 * MapSnapshotterObserver - snapshot observer.
 * JSONValue/JSONObject - JSON helper types.
 */
export * from './CommonTypes';

// ========== Network configuration ==========

/**
 * Set custom HTTP headers, replacing all existing ones.
 * @param headers Header key-value pairs.
 */
export function setCustomHttpHeaders(headers: Record<string, string>): void;

/**
 * Add a single custom HTTP header.
 * @param key Header name.
 * @param value Header value.
 */
export function addCustomHttpHeader(key: string, value: string): void;

/**
 * Remove a specific custom HTTP header.
 * @param key Header name.
 * @returns True when the header is removed.
 */
export function removeCustomHttpHeader(key: string): boolean;

/**
 * Clear all custom HTTP headers.
 */
export function clearCustomHttpHeaders(): void;

/**
 * Get all custom HTTP headers.
 * @returns Header key-value pairs.
 */
export function getCustomHttpHeaders(): Record<string, string>;

/**
 * Set the resource URL transform callback.
 * @param callback URL transform function.
 */
export function setResourceTransformCallback(callback: (kind: number, url: string) => string): void;

/**
 * Clear the resource URL transform callback.
 */
export function clearResourceTransformCallback(): void;

/**
 * Determine whether a URL transform callback is set.
 * @returns True if a callback is registered.
 */
export function hasResourceTransformCallback(): boolean;

// ========== Global configuration ==========

/**
 * Set the access token (used for Mapbox, MapTiler, etc.).
 * @param token API key or access token.
 */
export function setAccessToken(token: string): void;

/**
 * Get the current access token.
 * @returns Active API key or access token.
 */
export function getAccessToken(): string;

/**
 * Use the Mapbox tile server configuration.
 * Enables URLs with the mapbox:// scheme.
 */
export function useMapboxConfiguration(): void;

/**
 * Use the MapTiler tile server configuration.
 * Enables URLs with the maptiler:// scheme.
 */
export function useMapTilerConfiguration(): void;

/**
 * Use the MapLibre default tile server configuration (open, token-free).
 * Enables URLs with the maplibre:// scheme.
 */
export function useMapLibreConfiguration(): void;

/**
 * Set a custom API base URL.
 * @param url Base URL (for example, https://api.example.com).
 */
export function setApiBaseURL(url: string): void;

/**
 * Get the current API base URL.
 * @returns Active base URL.
 */
export function getApiBaseURL(): string;
