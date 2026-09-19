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
 * Spec entry for one icon SymbolLayer (background / foreground / bearing).
 */
interface IconLayerSpec {
  /** Style layer id. */
  layerId: string;
  /** Style image name added by loadLocationIcons(). */
  iconName: string;
  /** Fixed icon size. */
  iconSize: number;
}

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

      // Add the three icon layers (white circle background, blue dot
      // foreground, blue arrow bearing indicator). Each addLayer() places the
      // layer above the previous one, so the array order is bottom-to-top.
      // By default the bearing arrow sits on top (bearingOnTop = true); when
      // the option is disabled the bearing icon moves to the bottom of the
      // icon stack, mirroring the Android bearingOnTop behavior.
      const backgroundSpec: IconLayerSpec = {
        layerId: LocationComponentConstants.BACKGROUND_LAYER,
        iconName: LocationComponentConstants.BACKGROUND_ICON,
        iconSize: 0.5 // Largest (white circle)
      };
      const foregroundSpec: IconLayerSpec = {
        layerId: LocationComponentConstants.FOREGROUND_LAYER,
        iconName: LocationComponentConstants.FOREGROUND_ICON,
        iconSize: 0.35 // Smaller than the background
      };
      const bearingSpec: IconLayerSpec = {
        layerId: LocationComponentConstants.BEARING_LAYER,
        iconName: LocationComponentConstants.BEARING_ICON,
        iconSize: 0.4 // Arrow size
      };
      const iconLayers: IconLayerSpec[] = this.options.bearingOnTop
        ? [backgroundSpec, foregroundSpec, bearingSpec]
        : [bearingSpec, backgroundSpec, foregroundSpec];
      for (const spec of iconLayers) {
        const iconLayer = new SymbolLayer(spec.layerId, LocationComponentConstants.LOCATION_SOURCE);
        iconLayer.setIconImage(spec.iconName);
        iconLayer.setIconSize(spec.iconSize);
        iconLayer.setIconAllowOverlap(true);
        iconLayer.setIconIgnorePlacement(true);
        this.style.addLayer(iconLayer);
      }

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
   * Toggle a symbol layer's visibility (no-op when the layer is absent or of
   * an unexpected type).
   */
  private setSymbolVisible(layerId: string, visible: boolean): void {
    if (!this.style) {
      return;
    }

    const layer = this.style.getLayer(layerId);
    if (layer && layer instanceof SymbolLayer) {
      layer.setVisibility(visible ? 'visible' : 'none');
    }
  }

  /**
   * Toggle the accuracy circle layer's visibility (no-op when absent).
   */
  private setAccuracyVisible(visible: boolean): void {
    if (!this.style) {
      return;
    }

    const accuracyLayer = this.style.getLayer(LocationComponentConstants.ACCURACY_LAYER);
    if (accuracyLayer && accuracyLayer instanceof CircleLayer) {
      accuracyLayer.setVisibility(visible ? 'visible' : 'none');
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
      if (this.renderMode === RenderMode.NORMAL) {
        // Normal mode: show foreground and background only
        this.setSymbolVisible(LocationComponentConstants.FOREGROUND_LAYER, true);
        this.setSymbolVisible(LocationComponentConstants.BACKGROUND_LAYER, true);
        this.setSymbolVisible(LocationComponentConstants.BEARING_LAYER, false);
      } else if (this.renderMode === RenderMode.COMPASS || this.renderMode === RenderMode.GPS) {
        // Compass/GPS mode: show all layers including the bearing arrow
        this.setSymbolVisible(LocationComponentConstants.FOREGROUND_LAYER, true);
        this.setSymbolVisible(LocationComponentConstants.BACKGROUND_LAYER, true);
        this.setSymbolVisible(LocationComponentConstants.BEARING_LAYER, true);
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationLayerController.TAG, `Failed to update icon styles: ${err}`);
    }
  }

  /**
   * Apply styling options.
   */
  applyStyle(options: LocationComponentOptions): void {
    // Layer order is fixed when the layers are added; a bearingOnTop change
    // requires rebuilding the stack (mirrors the Android positionManager
    // update() -> remove/add cycle).
    const needsRestack = this.layersAdded && this.options.bearingOnTop !== options.bearingOnTop;
    this.options = options;
    if (needsRestack) {
      this.removeLayers();
      this.addLayers();
      if (this.isHidden) {
        // The recreated layers start visible; re-apply the hidden state
        // directly (hide() early-returns while isHidden is already true).
        this.setAccuracyVisible(false);
        this.setSymbolVisible(LocationComponentConstants.BACKGROUND_LAYER, false);
        this.setSymbolVisible(LocationComponentConstants.FOREGROUND_LAYER, false);
        this.setSymbolVisible(LocationComponentConstants.BEARING_LAYER, false);
      }
    }
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
      this.setAccuracyVisible(true);

      // Make background and foreground layers visible
      this.setSymbolVisible(LocationComponentConstants.BACKGROUND_LAYER, true);
      this.setSymbolVisible(LocationComponentConstants.FOREGROUND_LAYER, true);

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
      this.setAccuracyVisible(false);

      // Hide background layer
      this.setSymbolVisible(LocationComponentConstants.BACKGROUND_LAYER, false);

      // Hide foreground layer
      this.setSymbolVisible(LocationComponentConstants.FOREGROUND_LAYER, false);

      // Hide bearing layer
      this.setSymbolVisible(LocationComponentConstants.BEARING_LAYER, false);

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

