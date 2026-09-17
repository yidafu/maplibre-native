import { LocationComponentOptions } from './LocationComponentOptions';
import { LocationComponentConstants } from './LocationComponentConstants';
import { RenderMode } from './modes/RenderMode';
import { OnRenderModeChangedListener } from './listeners/OnRenderModeChangedListener';
import { LatLng } from '../geometry/LatLng';
import { IFeature } from '../geojson';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import { Style } from '../style';
import { GeoJsonSource } from '../style/sources/GeoJsonSource';
import { CircleLayer } from '../style/layers/CircleLayer';
import { SymbolLayer } from '../style/layers/SymbolLayer';
import resourceManager from '@ohos.resourceManager';
import common from '@ohos.app.ability.common';
import image from '@ohos.multimedia.image';

/**
 * Location layer controller.
 * Manages map layers related to user location.
 */
export class LocationLayerController {
  private static readonly TAG: string = 'LocationLayerController';
  private style?: Style;
  private options: LocationComponentOptions;
  private renderMode: number = RenderMode.NORMAL;
  private renderModeChangedListener?: OnRenderModeChangedListener;
  // Location data
  private currentLocation?: LatLng;
  private bearing: number = 0;
  private accuracy: number = 0;
  private isStale: boolean = false;
  // Layer state
  private layersAdded: boolean = false;
  private isHidden: boolean = true;

  constructor(options: LocationComponentOptions, renderModeChangedListener?: OnRenderModeChangedListener) {
    this.options = options;
    this.renderModeChangedListener = renderModeChangedListener;
  }

  /**
   * Initialize the controller.
   */
  async initializeComponents(style: Style): Promise<void> {
    this.style = style;

    // Load location icons
    await this.loadLocationIcons();

    // Add layers
    this.addLayers();

    // Hide layers initially if required
    if (this.isHidden) {
      this.hide();
    }
  }

  /**
   * Load location icons into the style.
   */
  private async loadLocationIcons(): Promise<void> {
    if (!this.style) {
      return;
    }

    try {
      // Obtain the ResourceManager
      const context = getContext() as common.UIAbilityContext;
      const resMgr = context.resourceManager;

      // Load foreground icon
      await this.loadIcon(resMgr, 'maplibre_location_icon_foreground.png', LocationComponentConstants.FOREGROUND_ICON);
      
      // Load background icon
      await this.loadIcon(resMgr, 'maplibre_location_icon_background.png', LocationComponentConstants.BACKGROUND_ICON);
      
      // Load bearing icon
      await this.loadIcon(resMgr, 'maplibre_location_icon_bearing.png', LocationComponentConstants.BEARING_ICON);

      hilog.info(DOMAIN, LocationLayerController.TAG, 'Location icons loaded successfully');
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to load location icons: ${err}`);
    }
  }

  /**
   * Load a single icon.
   */
  private async loadIcon(resMgr: resourceManager.ResourceManager, fileName: string, iconName: string): Promise<void> {
    try {
      // Load binary data from the rawfile directory
      const uint8Array = await resMgr.getRawFileContent(fileName);
      hilog.info(DOMAIN, LocationLayerController.TAG, `Loading icon: ${fileName}, size: ${uint8Array.byteLength} bytes`);

      // Create an ImageSource
      const imageSource = image.createImageSource(uint8Array.buffer);
      if (!imageSource) {
        throw new Error('Failed to create ImageSource');
      }

      // Decode to a PixelMap
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });

      // Retrieve image metadata
      const imageInfo = await pixelMap.getImageInfo();
      const width = imageInfo.size.width;
      const height = imageInfo.size.height;
      hilog.info(DOMAIN, LocationLayerController.TAG, `Icon ${iconName}: ${width}x${height}`);

      // Read RGBA pixel data
      const pixelBytes = new ArrayBuffer(width * height * 4);
      await pixelMap.readPixelsToBuffer(pixelBytes);

      // Add the icon to the style
      if (this.style) {
        this.style.addImage(iconName, pixelBytes, width, height, false);
        hilog.info(DOMAIN, LocationLayerController.TAG, `Icon ${iconName} added to style successfully`);
      }

      // Release intermediate resources
      imageSource.release();
      pixelMap.release();
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to load icon ${fileName}: ${err}`);
      throw new Error(`Failed to load icon ${fileName}: ${err}`);
    }
  }

  /**
   * Add layers to the map.
   */
  private addLayers(): void {
    if (!this.style || this.layersAdded) {
      return;
    }

    try {
      // Create the data source
      const sourceFeature: IFeature = {
        type: 'Feature',
        geometry: { type: 'Point', coordinates: [0, 0] },
        properties: {}
      };

      const geoJsonSource = new GeoJsonSource(
        LocationComponentConstants.LOCATION_SOURCE
      );
      geoJsonSource.setGeoJson(JSON.stringify(sourceFeature));
      this.style.addSource(geoJsonSource);

      // Add accuracy circle layer
      const accuracyLayer = new CircleLayer(
        LocationComponentConstants.ACCURACY_LAYER,
        LocationComponentConstants.LOCATION_SOURCE
      );
      this.style.addLayer(accuracyLayer);

      // Add background icon layer (white circle, largest)
      const backgroundLayer = new SymbolLayer(
        LocationComponentConstants.BACKGROUND_LAYER,
        LocationComponentConstants.LOCATION_SOURCE
      );
      backgroundLayer.setIconImage(LocationComponentConstants.BACKGROUND_ICON);
      backgroundLayer.setIconSize(0.5);  // Adjust icon size
      backgroundLayer.setIconAllowOverlap(true);
      backgroundLayer.setIconIgnorePlacement(true);
      this.style.addLayer(backgroundLayer);

      // Add foreground icon layer (blue dot, medium)
      const foregroundLayer = new SymbolLayer(
        LocationComponentConstants.FOREGROUND_LAYER,
        LocationComponentConstants.LOCATION_SOURCE
      );
      foregroundLayer.setIconImage(LocationComponentConstants.FOREGROUND_ICON);
      foregroundLayer.setIconSize(0.35);  // Smaller than the background
      foregroundLayer.setIconAllowOverlap(true);
      foregroundLayer.setIconIgnorePlacement(true);
      this.style.addLayer(foregroundLayer);

      // Add bearing icon layer (blue arrow)
      const bearingLayer = new SymbolLayer(
        LocationComponentConstants.BEARING_LAYER,
        LocationComponentConstants.LOCATION_SOURCE
      );
      bearingLayer.setIconImage(LocationComponentConstants.BEARING_ICON);
      bearingLayer.setIconSize(0.4);  // Arrow size
      bearingLayer.setIconAllowOverlap(true);
      bearingLayer.setIconIgnorePlacement(true);
      this.style.addLayer(bearingLayer);

      this.layersAdded = true;

      // Apply initial styling
      this.styleAccuracy();
      this.updateIconStyles();

    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to add layers: ${err}`);
    }
  }

  /**
   * Remove layers from the map.
   */
  removeLayers(): void {
    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      this.style.removeLayer(LocationComponentConstants.BEARING_LAYER);
      this.style.removeLayer(LocationComponentConstants.FOREGROUND_LAYER);
      this.style.removeLayer(LocationComponentConstants.BACKGROUND_LAYER);
      this.style.removeLayer(LocationComponentConstants.ACCURACY_LAYER);
      this.style.removeSource(LocationComponentConstants.LOCATION_SOURCE);

      this.layersAdded = false;
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to remove layers: ${err}`);
    }
  }

  /**
   * Update location data.
   */
  updateLocation(location: LatLng, bearing: number, accuracy: number): void {
    this.currentLocation = location;
    this.bearing = bearing;
    this.accuracy = accuracy;

    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      // Update source coordinates
      const sourceFeature: IFeature = {
        type: 'Feature',
        geometry: { type: 'Point', coordinates: [location.longitude, location.latitude] },
        properties: {}
      };

      const source = this.style.getSource(LocationComponentConstants.LOCATION_SOURCE);
      if (source && source instanceof GeoJsonSource) {
        source.setGeoJson(JSON.stringify(sourceFeature));
      }

      // Update accuracy circle
      this.updateAccuracyRadius(accuracy);

      // Update bearing indicator
      this.updateBearing(bearing);

    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to update location: ${err}`);
    }
  }

  /**
   * Update the accuracy circle radius.
   */
  private updateAccuracyRadius(accuracy: number): void {
    if (!this.style) {
      return;
    }

    try {
      const layer = this.style.getLayer(LocationComponentConstants.ACCURACY_LAYER);
      if (layer && layer instanceof CircleLayer) {
        // Determine circle radius based on accuracy (zoom/latitude adjustments omitted for brevity)
        // Production code should calculate using latitude and zoom level
        const radiusInPixels = Math.max(accuracy / 2, 10);
        // layer.setProperties({ 'circle-radius': radiusInPixels });
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to update accuracy radius: ${err}`);
    }
  }

  /**
   * Update the bearing angle.
   */
  private updateBearing(bearing: number): void {
    if (!this.style) {
      return;
    }

    try {
      const layer = this.style.getLayer(LocationComponentConstants.BEARING_LAYER);
      if (layer && layer instanceof SymbolLayer && this.renderMode !== RenderMode.NORMAL) {
        layer.setIconRotate(bearing);
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to update bearing: ${err}`);
    }
  }

  /**
   * Set the render mode.
   */
  setRenderMode(mode: number): void {
    if (!RenderMode.isValid(mode)) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Invalid render mode: ${mode}`);
      return;
    }

    if (this.renderMode === mode) {
      return;
    }

    this.renderMode = mode;
    this.updateIconStyles();

    if (this.renderModeChangedListener) {
      this.renderModeChangedListener.onRenderModeChanged(mode);
    }
  }

  /**
   * Update icon styling.
   */
  private updateIconStyles(): void {
    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      // Toggle layers based on render mode
      const foregroundLayer = this.style.getLayer(LocationComponentConstants.FOREGROUND_LAYER);
      const backgroundLayer = this.style.getLayer(LocationComponentConstants.BACKGROUND_LAYER);
      const bearingLayer = this.style.getLayer(LocationComponentConstants.BEARING_LAYER);

      if (this.renderMode === RenderMode.NORMAL) {
        // Normal mode: show foreground and background only
        if (foregroundLayer && foregroundLayer instanceof SymbolLayer) foregroundLayer.setVisibility('visible');
        if (backgroundLayer && backgroundLayer instanceof SymbolLayer) backgroundLayer.setVisibility('visible');
        if (bearingLayer && bearingLayer instanceof SymbolLayer) bearingLayer.setVisibility('none');
      } else if (this.renderMode === RenderMode.COMPASS || this.renderMode === RenderMode.GPS) {
        // Compass/GPS mode: show all layers including the bearing arrow
        if (foregroundLayer && foregroundLayer instanceof SymbolLayer) foregroundLayer.setVisibility('visible');
        if (backgroundLayer && backgroundLayer instanceof SymbolLayer) backgroundLayer.setVisibility('visible');
        if (bearingLayer && bearingLayer instanceof SymbolLayer) bearingLayer.setVisibility('visible');
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to update icon styles: ${err}`);
    }
  }

  /**
   * Apply styling options.
   */
  applyStyle(options: LocationComponentOptions): void {
    this.options = options;
    this.styleAccuracy();
    this.updateIconStyles();
  }

  /**
   * Configure accuracy circle styling.
   */
  private styleAccuracy(): void {
    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      const layer = this.style.getLayer(LocationComponentConstants.ACCURACY_LAYER);
      if (layer && layer instanceof CircleLayer) {
        // layer.setProperties({
        //   'circle-color': this.options.accuracyColor,
        //   'circle-opacity': this.options.accuracyAlpha
        // });
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to style accuracy: ${err}`);
    }
  }

  /**
   * Update stale-state visuals.
   */
  setStale(isStale: boolean): void {
    if (this.isStale === isStale) {
      return;
    }

    this.isStale = isStale;

    // Switch to stale-state icons
    this.updateIconStyles();
  }

  /**
   * Show location layers.
   */
  show(): void {
    if (!this.isHidden) {
      return;
    }

    this.isHidden = false;

    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      // Make accuracy layer visible
      const accuracyLayer = this.style.getLayer(LocationComponentConstants.ACCURACY_LAYER);
      if (accuracyLayer && accuracyLayer instanceof CircleLayer) {
        accuracyLayer.setVisibility('visible');
      }

      // Make background layer visible
      const backgroundLayer = this.style.getLayer(LocationComponentConstants.BACKGROUND_LAYER);
      if (backgroundLayer && backgroundLayer instanceof SymbolLayer) {
        backgroundLayer.setVisibility('visible');
      }

      // Make foreground layer visible
      const foregroundLayer = this.style.getLayer(LocationComponentConstants.FOREGROUND_LAYER);
      if (foregroundLayer && foregroundLayer instanceof SymbolLayer) {
        foregroundLayer.setVisibility('visible');
      }

      // Bearing layer visibility is handled in updateIconStyles()
      this.updateIconStyles();

    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to show layers: ${err}`);
    }
  }

  /**
   * Hide location layers.
   */
  hide(): void {
    if (this.isHidden) {
      return;
    }

    this.isHidden = true;

    if (!this.style || !this.layersAdded) {
      return;
    }

    try {
      // Hide accuracy layer
      const accuracyLayer = this.style.getLayer(LocationComponentConstants.ACCURACY_LAYER);
      if (accuracyLayer && accuracyLayer instanceof CircleLayer) {
        accuracyLayer.setVisibility('none');
      }

      // Hide background layer
      const backgroundLayer = this.style.getLayer(LocationComponentConstants.BACKGROUND_LAYER);
      if (backgroundLayer && backgroundLayer instanceof SymbolLayer) {
        backgroundLayer.setVisibility('none');
      }

      // Hide foreground layer
      const foregroundLayer = this.style.getLayer(LocationComponentConstants.FOREGROUND_LAYER);
      if (foregroundLayer && foregroundLayer instanceof SymbolLayer) {
        foregroundLayer.setVisibility('none');
      }

      // Hide bearing layer
      const bearingLayer = this.style.getLayer(LocationComponentConstants.BEARING_LAYER);
      if (bearingLayer && bearingLayer instanceof SymbolLayer) {
        bearingLayer.setVisibility('none');
      }

    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to hide layers: ${err}`);
    }
  }

  /**
   * Get the current render mode.
   */
  getRenderMode(): number {
    return this.renderMode;
  }

  /**
   * Get the current location.
   */
  getCurrentLocation(): LatLng | undefined {
    return this.currentLocation;
  }
}

