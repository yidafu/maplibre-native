/**
 * MarkerLayerManager - GeoJSON + SymbolLayer based marker manager.
 *
 * Inspired by the Android Annotation Plugin and iOS best practices.
 * Implements advanced marker behavior using a GeoJSON source plus data-driven SymbolLayer styling.
 *
 * Architecture:
 * - Create an internal GeoJSON source (`marker-source`).
 * - Create a SymbolLayer (`marker-layer`) leveraging data-driven styling.
 * - Represent each marker as a GeoJSON feature whose properties contain all attributes.
 * - Support rotation, alpha, z-index, anchor, draggable, and other advanced options.
 */

import { MapLibreMap } from '../MapLibreMap';
import { LatLng } from '../geometry/LatLng';
import { GeoJsonSource } from '../style/sources/GeoJsonSource';
import { GeoJsonOptions } from '../style/sources/GeoJsonOptions';
import { SymbolLayer } from '../style/layers/SymbolLayer';
import { Expression } from '../style/expressions/Expression';
import { IconFactory } from './IconFactory';

import { Marker } from './Marker';
import { IconManager } from './IconManager';

/**
 * MarkerGeometry - interface for marker geometry.
 */
interface MarkerGeometry {
  type: 'Point';
  coordinates: [number, number]; // [longitude, latitude]
}

/**
 * MarkerProperties - interface for marker properties.
 */
interface MarkerProperties {
  // Basic attributes
  icon: string;
  title?: string;
  snippet?: string;

  // Advanced attributes
  rotation: number; // Rotation angle
  alpha: number; // Opacity 0-1
  zIndex: number; // Rendering order
  anchorU: number; // Anchor U (0-1)
  anchorV: number; // Anchor V (0-1)
  draggable: boolean; // Whether marker is draggable
  visible: boolean; // Whether marker is visible

  // Internal use
  __markerId: number; // Unique marker identifier
}

/**
 * MarkerFeature - GeoJSON representation of a marker.
 */
interface MarkerFeature {
  type: 'Feature';
  id: string | number;
  geometry: MarkerGeometry;
  properties: MarkerProperties;
}

/**
 * MarkerFeatureCollection - collection of marker features.
 */
interface MarkerFeatureCollection {
  type: 'FeatureCollection';
  features: MarkerFeature[];
}

/**
 * MarkerLayerManager - GeoJSON-backed marker manager.
 */
export class MarkerLayerManager {
  private static readonly SOURCE_ID = 'maplibre-marker-source';
  private static readonly LAYER_ID = 'maplibre-marker-layer';
  private mapLibreMap: MapLibreMap;
  private source: GeoJsonSource | null = null;
  private layer: SymbolLayer | null = null;
  private markers: Map<number, Marker> = new Map();
  private features: Map<number, MarkerFeature> = new Map();
  private nextFeatureId: number = 1;
  private initialized: boolean = false;
  // Update debounce (avoid excessive updates causing ANR)
  private updateTimerId: number | null = null;
  private readonly UPDATE_DEBOUNCE_MS = 16; // ~60 fps; responsive without excessive updates

  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
  }

  /**
   * Check whether the manager has been initialized.
   */
  public isInitialized(): boolean {
    return this.initialized;
  }

  /**
   * Initialize the marker layer (create source and layer).
   */
  public initialize(): void {
    if (this.initialized && this.source && this.layer) {
      console.warn('[MarkerLayerManager] Already initialized with valid source/layer');
      return;
    }

    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        throw new Error('Style not loaded');
      }

      // Remove existing source/layer from the style if they already exist
      try {
        // Attempt to remove any existing layer/source without pre-checking
        // If they do not exist, the catch block will handle it
        style.removeLayer(MarkerLayerManager.LAYER_ID);
        style.removeSource(MarkerLayerManager.SOURCE_ID);
        console.warn('[MarkerLayerManager] Removed existing source/layer before re-initialization');
      } catch (e) {
        // Ignore missing-element errors during removal; this is expected
      }

      // Create an empty GeoJSON source
      const emptyFeatureCollection: MarkerFeatureCollection = {
        type: 'FeatureCollection',
        features: []
      };

      // Instantiate the GeoJsonSource (NAPI-backed)
      this.source = new GeoJsonSource(MarkerLayerManager.SOURCE_ID, {
        cluster: false,
        tolerance: 0.375,
        buffer: 128
      });

      // Seed initial data (cast to plain object)
      this.source.setGeoJsonSync(emptyFeatureCollection as Object);

      // Add the source to the style (Style will call getNative() on the wrapper)
      style.addSource(this.source);

      // Re-fetch the source from the style to ensure we hold the style-owned instance
      // Uses the __type property for matching (supported after the NAPI fix)
      const sourceFromStyle = style.getSource(MarkerLayerManager.SOURCE_ID) as GeoJsonSource | null;
      if (sourceFromStyle) {
        this.source = sourceFromStyle;
      } else {
        console.warn('[MarkerLayerManager] Warning: failed to get source from style; using original reference');
      }

      // Create a SymbolLayer configured for data-driven styling
      const tempLayer = new SymbolLayer(
        MarkerLayerManager.LAYER_ID,
        MarkerLayerManager.SOURCE_ID
      );

      // Configure layer properties (data-driven)
      this.configureLayer(tempLayer);

      // Add the layer to the style (Style will call getNative() on the wrapper)
      style.addLayer(tempLayer);

      // Re-fetch the layer from the style to ensure we reference the style-owned instance
      // Uses the __type property for matching (supported after the NAPI fix)
      const layerFromStyle = style.getLayer(MarkerLayerManager.LAYER_ID) as SymbolLayer | null;
      if (layerFromStyle) {
        this.layer = layerFromStyle;
      } else {
        console.warn('[MarkerLayerManager] Warning: failed to get layer from style; using original reference');
        this.layer = tempLayer;
      }

      this.initialized = true;
    } catch (error) {
      console.error(`[MarkerLayerManager] Failed to initialize: ${error}`);
      this.initialized = false;
      this.source = null;
      this.layer = null;
      throw new Error(String(error));
    }
  }

  /**
   * Configure data-driven styling on the SymbolLayer.
   */
  private configureLayer(layer: SymbolLayer): void {

    // ========== Icon layout properties ==========

    // Icon image: retrieve dynamically from feature properties so each marker can define its own icon
    const iconImageExpr = Expression.get("icon").toArray() as import("libmaplibre.so").ExpressionLiteral;
    layer.setIconImage(iconImageExpr);

    // Icon size: default 1.0
    layer.setIconSize(1.0);

    // Icon rotation: pull from feature properties to support per-marker rotation
    const iconRotateExpr = Expression.get("rotation").toArray() as import("libmaplibre.so").ExpressionLiteral;
    layer.setIconRotate(iconRotateExpr);

    // Icon anchor: bottom (center bottom) by default
    layer.setIconAnchor('bottom');

    // Allow icon overlap to keep all markers visible
    layer.setIconAllowOverlap(true);

    // ========== Icon rendering properties ==========

    // Icon opacity: combine `visible` and `alpha`
    // When visible is false, opacity becomes 0; otherwise it uses the alpha value
    layer.setIconOpacity(
      Expression.caseExpression(
        Expression.eq(Expression.get("visible"), Expression.literal(false)),
        Expression.literal(0), // Opacity = 0 when not visible
        Expression.get("alpha")  // Otherwise use the alpha value
      ).toArray() as import("libmaplibre.so").ExpressionLiteral
    );

  }

  /**
   * Add a marker.
   *
   * @param marker Marker instance.
   * @param skipUpdate Skip the source update (used during batch adds, default false).
   * @returns Feature ID.
   */
  public addMarker(marker: Marker, skipUpdate: boolean = false): number {
    // Ensure initialization and source/layer availability
    if (!this.initialized || !this.source || !this.layer) {
      console.warn('[MarkerLayerManager] Re-initializing due to missing source/layer');
      this.initialized = false; // Reset flag to force re-initialization
      this.initialize();
    }

    const featureId = this.nextFeatureId++;
    const feature = this.markerToFeature(marker, featureId);

    this.features.set(featureId, feature);
    this.markers.set(featureId, marker);

    // Update the GeoJSON source (caller may skip during batch operations)
    if (!skipUpdate) {
      this.updateSource();
    }

    return featureId;
  }

  /**
   * Add markers in batch.
   *
   * **Performance note**: updates the GeoJSON source once to avoid repeated serialization/parsing.
   */
  public addMarkers(markers: Marker[]): number[] {
    // Ensure initialization and source/layer availability
    if (!this.initialized || !this.source || !this.layer) {
      console.warn('[MarkerLayerManager] Re-initializing due to missing source/layer');
      this.initialized = false; // Reset flag to force re-initialization
      this.initialize();
    }

    const ids: number[] = [];

    for (const marker of markers) {
      const featureId = this.nextFeatureId++;
      const feature = this.markerToFeature(marker, featureId);

      this.features.set(featureId, feature);
      this.markers.set(featureId, marker);
      ids.push(featureId);
    }

    // Perform a single source update (batch optimization)
    this.forceUpdateSource();

    return ids;
  }

  /**
   * Force the source to update immediately (skips debounce).
   * Useful after batch operations that requested `skipUpdate`.
   */
  public forceUpdateSource(): void {
    // Clear any pending debounce timer
    if (this.updateTimerId !== null) {
      clearTimeout(this.updateTimerId);
      this.updateTimerId = null;
    }
    // Perform the update right away
    this.performUpdate();
  }

  /**
   * Update a marker (by marker instance).
   *
   * Keeps the visual state in sync, e.g. during drag operations.
   * Mirrors Android `symbolsSource.setGeoJson(symbolsCollection)`.
   *
   * @param marker Marker instance with a valid ID.
   */
  public updateMarker(marker: Marker): void {
    const featureId = marker.getId();
    if (featureId === 0 || !this.features.has(featureId)) {
      console.error(`[MarkerLayerManager] Marker not found: id=${featureId}`);
      return;
    }

    // Refresh the feature and marker
    const feature = this.markerToFeature(marker, featureId);
    this.features.set(featureId, feature);
    this.markers.set(featureId, marker);

    // During drag operations we want immediate feedback; skip debounce
    // Similar to Android: symbolsSource.setGeoJson(symbolsCollection) for instant effect
    this.forceUpdateSource();
  }

  /**
   * Update a marker by featureId (backward compatibility).
   */
  public updateMarkerById(featureId: number, marker: Marker): void {
    if (!this.features.has(featureId)) {
      console.error(`Marker feature ${featureId} not found`);
      return;
    }

    const feature = this.markerToFeature(marker, featureId);
    this.features.set(featureId, feature);
    this.markers.set(featureId, marker);

    this.updateSource();
  }

  /**
   * Remove a marker.
   *
   * @param featureId Feature ID.
   * @param skipUpdate Skip updating the source (used during batch removals, default false).
   */
  public removeMarker(featureId: number, skipUpdate: boolean = false): void {
    this.features.delete(featureId);
    this.markers.delete(featureId);

    if (!skipUpdate) {
      this.updateSource();
    }
  }

  /**
   * Remove markers in batch.
   */
  public removeMarkers(featureIds: number[]): void {
    // Skip updates to avoid redundant refreshes
    for (const id of featureIds) {
      this.removeMarker(id, true); // skipUpdate = true
    }

    // Apply immediately for batch deletions; skip debounce
    this.forceUpdateSource();
  }

  /**
   * Remove all markers.
   */
  public clearMarkers(): void {
    this.features.clear();
    this.markers.clear();

    // Clear operation should take effect immediately; skip debounce
    this.forceUpdateSource();
  }

  /**
   * Convert a marker to a GeoJSON feature.
   */
  private markerToFeature(marker: Marker, featureId: number): MarkerFeature {
    const position = marker.getPosition();
    // Resolve icon ID; fall back to the default icon for empty/falsy values
    let icon = marker.getIcon();
    if (!icon || icon.trim() === '') {
      icon = IconFactory.DEFAULT_MARKER_ICON_ID;
    }
    const title = marker.getTitle();
    const snippet = marker.getSnippet();

    // Collect advanced properties
    const rotation = marker.getRotation();
    const alpha = marker.getAlpha();
    const zIndex = marker.getZIndex();
    const anchor = marker.getAnchor();
    const draggable = marker.getDraggable();
    const visible = marker.getVisible();

    const geometry: MarkerGeometry = {
      type: 'Point',
      coordinates: [position.longitude, position.latitude]
    };

    const properties: MarkerProperties = {
      icon: icon,
      title: title,
      snippet: snippet,
      rotation: rotation,
      alpha: alpha,
      zIndex: zIndex,
      anchorU: anchor.u,
      anchorV: anchor.v,
      draggable: draggable,
      visible: visible,
      __markerId: featureId
    };

    const feature: MarkerFeature = {
      type: 'Feature',
      id: featureId,
      geometry: geometry,
      properties: properties
    };

    return feature;
  }

  /**
   * Update the GeoJSON source data (with debounce).
   *
   * **Performance safeguards**:
   * 1. **Debounce**: merge multiple requests within 16 ms into one to avoid spamming updates.
   * 2. **Async dispatch**: defer via `setTimeout` to the next macrotask to exit the current event loop.
   * 3. **Object transfer**: pass the FeatureCollection object directly (no JSON serialization cost).
   *
   * Note: exposed as `public` so external callers (e.g. `MarkerManager` after style reload) can invoke it.
   */
  public updateSource(): void {
    // Clear any existing timer (debounce consolidates multiple calls)
    if (this.updateTimerId !== null) {
      clearTimeout(this.updateTimerId);
    }

    // Schedule the next update
    this.updateTimerId = setTimeout(() => {
      this.updateTimerId = null;
      this.performUpdate();
    }, this.UPDATE_DEBOUNCE_MS);
  }

  /**
   * Perform the actual source update (internal helper).
   */
  private performUpdate(): void {
    if (!this.source) {
      console.error('[MarkerLayerManager] Source not initialized, resetting initialized flag');
      this.initialized = false;
      return;
    }

    const featureCollection: MarkerFeatureCollection = {
      type: 'FeatureCollection',
      features: Array.from(this.features.values())
    };

    const featureCount = featureCollection.features.length;

    // Log the first feature for debugging purposes
    if (featureCount > 0) {
      const firstFeature = featureCollection.features[0];

      // Warn when using the default icon
      if (firstFeature.properties.icon === IconFactory.DEFAULT_MARKER_ICON_ID) {
        console.warn(`[MarkerLayerManager] Warning: using default icon ID ${IconFactory.DEFAULT_MARKER_ICON_ID}. Ensure it is loaded in the style.`);
      }
    }

    // Schedule on the next macrotask (`setTimeout(0)`) to leave the current event loop
    setTimeout(() => {
      try {
        const updateStartTime = Date.now();

        // Pass the FeatureCollection object directly (NAPI converts it; no JSON serialization needed)
        this.source!.setGeoJson(featureCollection);

        // Trigger map repaint
        const nativeMapView = this.mapLibreMap.getNativeMapView();
        if (nativeMapView) {
          nativeMapView.triggerRepaint();
        }

        const updateTime = Date.now() - updateStartTime;
      } catch (error) {
        console.error(`[MarkerLayerManager] Failed to update source: ${error}`);
      }
    }, 0);
  }

  /**
   * Get all tracked markers.
   */
  public getAllMarkers(): Marker[] {
    return Array.from(this.markers.values());
  }

  /**
   * Get the marker count.
   */
  public getMarkerCount(): number {
    return this.markers.size;
  }

  /**
   * Get the marker layer ID.
   *
   * @returns Layer ID string.
   */
  public getLayerId(): string {
    return MarkerLayerManager.LAYER_ID;
  }

  /**
   * Get the marker source ID.
   *
   * @returns Source ID string.
   */
  public getSourceId(): string {
    return MarkerLayerManager.SOURCE_ID;
  }

  /**
   * Destroy the manager and release resources.
   */
  public destroy(): void {
    if (!this.initialized) {
      return;
    }

    try {
      const style = this.mapLibreMap.getStyle();
      if (style) {
        // Remove layer and source
        if (this.layer) {
          style.removeLayer(MarkerLayerManager.LAYER_ID);
        }
        if (this.source) {
          style.removeSource(MarkerLayerManager.SOURCE_ID);
        }
      }

      this.markers.clear();
      this.features.clear();
      this.initialized = false;
    } catch (error) {
      console.error(`Failed to destroy MarkerLayerManager: ${error}`);
    }
  }
}

