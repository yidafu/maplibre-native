/**
 * MapSnapshotter - map snapshot generator.
 *
 * Renders the map off-thread and produces pixel map snapshots.
 * Mirrors Android `MapSnapshotter` and iOS `MLNMapSnapshotter`.
 */

import maplibre, {
  MapSnapshotterNAPI,
  SnapshotOptionsNAPI,
  SnapshotResultNAPI
} from 'libmaplibre.so';
import type {
  Layer,
  Source,
  Icon,
  Image,
  CameraPositionLike,
  LatLngBoundsLike,
  MapSnapshotterObserver as NativeMapSnapshotterObserver
} from 'libmaplibre.so';
import image from '@ohos.multimedia.image';
import { SnapshotOptions } from './SnapshotOptions';
import { MapSnapshot } from './MapSnapshot';
import { CameraPosition } from '../camera/CameraPosition';
import { LatLngBounds } from '../geometry/LatLngBounds';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

export type { MapSnapshotterObserver } from 'libmaplibre.so';

/**
 * Snapshot completion callback.
 */
export interface SnapshotReadyCallback {
  /**
   * Called when snapshot generation completes.
   *
   * @param snapshot Snapshot result.
   */
  onSnapshotReady(snapshot: MapSnapshot): void;
}

/**
 * Error callback for snapshot generation.
 */
export interface SnapshotErrorHandler {
  /**
   * Invoked when an error occurs.
   *
   * @param error Error message.
   */
  onError(error: string): void;
}

/**
 * Snapshotter class.
 *
 * Usage example:
 * ```typescript
 * // 1. Prepare options
 * const options: SnapshotOptions = {
 *   size: { width: 1080, height: 1920 },
 *   pixelRatio: 3.0,
 *   styleUrl: 'https://demotiles.maplibre.org/style.json',
 *   cameraPosition: {
 *     target: createLatLng(30.27, 120.15),
 *     zoom: 12,
 *     bearing: 0,
 *     tilt: 0
 *   },
 *   showLogo: true
 * };
 *
 * // 2. Create snapshotter
 * const snapshotter = new MapSnapshotter(options);
 *
 * // 3. Start generating the snapshot
 * snapshotter.start({
 *   onSnapshotReady: (snapshot) => {
 *     const pixelMap = snapshot.getImage();
 *     // Use pixelMap
 *   }
 * }, {
 *   onError: (error) => {
 *     console.error(`Snapshot failed: ${error}`);
 *   }
 * });
 * ```
 */
export class MapSnapshotter {
  private nativeSnapshotter: MapSnapshotterNAPI | null = null;
  private options: SnapshotOptions;
  private cancelled: boolean = false;
  private observer: NativeMapSnapshotterObserver | null = null;

  /**
   * Constructor.
   *
   * @param options Snapshot options.
   */
  constructor(options: SnapshotOptions) {
    this.options = options;

    try {
      // Prepare NAPI options
      const napiOptions: SnapshotOptionsNAPI = {
        width: options.size.width,
        height: options.size.height,
        pixelRatio: options.pixelRatio || 1.0,
        styleUrl: options.styleUrl,
        styleJson: options.styleJson,
        showLogo: options.showLogo !== false,
        localFontFamily: options.localFontFamily || ''
      };

      // If a camera position is provided, convert it to a plain object
      if (options.cameraPosition) {
        const cameraData: CameraPositionLike = {
          target: {
            latitude: options.cameraPosition.target.latitude,
            longitude: options.cameraPosition.target.longitude
          },
          zoom: options.cameraPosition.zoom,
          bearing: options.cameraPosition.bearing,
          tilt: options.cameraPosition.tilt
        };
        napiOptions.camera = cameraData;
      }

      // If a region is provided, convert it to a plain object
      if (options.region) {
        const regionData: LatLngBoundsLike = {
          north: options.region.north,
          south: options.region.south,
          east: options.region.east,
          west: options.region.west
        };
        napiOptions.region = regionData;
      }

      // Instantiate the native snapshotter
      this.nativeSnapshotter = maplibre.createMapSnapshotter(napiOptions);

    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to create snapshotter: ${error}`);
      throw new Error(`Failed to create snapshotter: ${error}`);
    }
  }

  /**
   * Start generating the snapshot.
   *
   * @param callback Completion callback.
   * @param errorHandler Optional error handler.
   */
  public start(
    callback: SnapshotReadyCallback,
    errorHandler?: SnapshotErrorHandler
  ): void {
    if (!this.nativeSnapshotter) {
      const error = 'Snapshotter not initialized';
      hilog.error(DOMAIN, 'MapSnapshotter', error);
      if (errorHandler) {
        errorHandler.onError(error);
      }
      return;
    }

    if (this.cancelled) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Snapshotter was cancelled');
      return;
    }

    try {
      // Wrap the callback to accommodate the single-argument ThreadSafeCallback contract.
      // Native layer passes a single value:
      // - On error: an error string.
      // - On success: a result object.
      this.nativeSnapshotter.start((param: string | SnapshotResultNAPI | null) => {
        // Determine parameter type.
        if (typeof param === 'string') {
          // Error: param is an error message string.
          hilog.error(DOMAIN, 'MapSnapshotter', `Snapshot error: ${param}`);
          if (errorHandler) {
            errorHandler.onError(param);
          }
          return;
        }

        const result = param as SnapshotResultNAPI | null;
        if (!result) {
          const errorMsg = 'No result returned from native snapshotter';
          hilog.error(DOMAIN, 'MapSnapshotter', errorMsg);
          if (errorHandler) {
            errorHandler.onError(errorMsg);
          }
          return;
        }

        // Create a PixelMap from the native result.
        this.createPixelMapFromNativeResult(result)
          .then(pixelMap => {
            // Construct MapSnapshot, preserving the native object for coordinate conversions.
            const snapshot = new MapSnapshot(
              pixelMap,
              result.width,
              result.height,
              result.attributions || [],
              this.options.showLogo !== false,
              result  // Pass native snapshot object
            );

            callback.onSnapshotReady(snapshot);
          })
          .catch((err: Error) => {
            hilog.error(DOMAIN, 'MapSnapshotter', `Failed to create PixelMap: ${err}`);
            if (errorHandler) {
              errorHandler.onError(`Failed to create PixelMap: ${err}`);
            }
          });
      });

    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Start failed: ${error}`);
      if (errorHandler) {
        errorHandler.onError(`${error}`);
      }
    }
  }

  /**
   * Cancel snapshot generation.
   */
  public cancel(): void {
    if (!this.nativeSnapshotter) {
      return;
    }

    this.cancelled = true;

    try {
      this.nativeSnapshotter.cancel();
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Cancel failed: ${error}`);
    }
  }

  /**
   * Set the style URL.
   */
  public setStyleUrl(styleUrl: string): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      this.nativeSnapshotter.setStyleUrl(styleUrl);
      this.options.styleUrl = styleUrl;
      hilog.info(DOMAIN, 'MapSnapshotter', `Style URL set: ${styleUrl}`);
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set style URL: ${error}`);
      throw new Error(`Failed to set style URL: ${error}`);
    }
  }

  /**
   * Set the style JSON.
   */
  public setStyleJson(styleJson: string): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      this.nativeSnapshotter.setStyleJson(styleJson);
      this.options.styleJson = styleJson;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Style JSON set');
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set style JSON: ${error}`);
      throw new Error(`Failed to set style JSON: ${error}`);
    }
  }

  /**
   * Get the current style URL.
   */
  public getStyleUrl(): string {
    return this.options.styleUrl;
  }

  /**
   * Configure the camera position.
   */
  public setCameraPosition(cameraPosition: CameraPosition): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      // Convert CameraPosition to a plain object before passing to native code.
      const cameraData: CameraPositionLike = {
        target: {
          latitude: cameraPosition.target.latitude,
          longitude: cameraPosition.target.longitude
        },
        zoom: cameraPosition.zoom,
        bearing: cameraPosition.bearing,
        tilt: cameraPosition.tilt
      };
      this.nativeSnapshotter.setCameraPosition(cameraData);
      this.options.cameraPosition = cameraPosition;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Camera position set');
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set camera position: ${error}`);
      throw new Error(`Failed to set camera position: ${error}`);
    }
  }

  /**
   * Retrieve the configured camera position.
   */
  public getCameraPosition(): CameraPosition | undefined {
    return this.options.cameraPosition;
  }

  /**
   * Configure the geographic region.
   */
  public setRegion(region: LatLngBounds): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      // Convert LatLngBounds to a plain object.
      const regionData: LatLngBoundsLike = {
        north: region.north,
        south: region.south,
        east: region.east,
        west: region.west
      };
      this.nativeSnapshotter.setRegion(regionData);
      this.options.region = region;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Region set');
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set region: ${error}`);
      throw new Error(`Failed to set region: ${error}`);
    }
  }

  /**
   * Set the snapshot dimensions.
   */
  public setSize(width: number, height: number): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      this.nativeSnapshotter.setSize(width, height);
      this.options.size = { width, height };
      hilog.info(DOMAIN, 'MapSnapshotter', `Size set: ${width}x${height}`);
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set size: ${error}`);
      throw new Error(`Failed to set size: ${error}`);
    }
  }

  /**
   * Configure the observer.
   * @param observer Observer instance; pass null to clear it.
   */
  public setObserver(observer: NativeMapSnapshotterObserver | null): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    this.observer = observer;

    try {
      if (observer) {
        this.nativeSnapshotter.setObserver(observer);
        hilog.info(DOMAIN, 'MapSnapshotter', 'Observer set');
      } else {
        this.nativeSnapshotter.setObserver(null);
        hilog.info(DOMAIN, 'MapSnapshotter', 'Observer cleared');
      }
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to set observer: ${error}`);
      throw new Error(`Failed to set observer: ${error}`);
    }
  }

  /**
   * Retrieve the configured region.
   */
  public getRegion(): LatLngBounds | undefined {
    return this.options.region;
  }

  /**
   * Get a layer (available once the style finishes loading).
   *
   * Mirrors Android `MapSnapshotter.getLayer(String)`.
   *
   * @param layerId Layer identifier.
   * @returns Layer instance, or null when missing.
   */
  public getLayer(layerId: string): Layer | null {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return null;
    }

    try {
      return this.nativeSnapshotter.getLayer(layerId) || null;
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to get layer: ${error}`);
      return null;
    }
  }

  /**
   * Get a source (available once the style finishes loading).
   *
   * Mirrors Android `MapSnapshotter.getSource(String)`.
   *
   * @param sourceId Source identifier.
   * @returns Source instance, or null when missing.
   */
  public getSource(sourceId: string): Source | null {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return null;
    }

    try {
      return this.nativeSnapshotter.getSource(sourceId) || null;
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to get source: ${error}`);
      return null;
    }
  }

  /**
   * Add an image to the snapshot style.
   *
   * Mirrors Android `MapSnapshotter.addImage(String, Bitmap, boolean)`.
   *
   * Should be invoked before `start()` or inside `onDidFinishLoadingStyle` /
   * `onStyleImageMissing`, while the snapshot style is not being rendered.
   *
   * Supported forms:
   * - `addImage(name, icon, sdf?)` — an Icon created by `IconFactory`; the
   *   image dimensions and pixel scale are taken from the icon.
   * - `addImage(name, image, sdf?)` — a style `Image` object.
   * - `addImage(name, buffer, width, height, pixelRatio?, sdf?)` — raw RGBA
   *   (premultiplied) pixels; `buffer.byteLength` must equal
   *   `width * height * 4`.
   *
   * @param name Image identifier.
   * @param imageData Icon, Image object, or raw RGBA pixel data.
   * @param widthOrSdf Width in pixels (raw form) or SDF flag (object form).
   * @param height Height in pixels (raw form only).
   * @param pixelRatioOrSdf Pixel ratio (raw form) or SDF flag (object form).
   * @param sdf Whether the image is an SDF (Signed Distance Field) sprite
   *            (raw form only).
   *
   * @example
   * ```typescript
   * // Icon created by IconFactory (recommended).
   * const icon = maplibre.IconFactory.fromRawfile(context.resourceManager, 'marker.png');
   * snapshotter.addImage('custom-marker', icon);
   *
   * // Raw pixel data.
   * snapshotter.addImage('sprite', rgbaBuffer, width, height, 2.0, false);
   *
   * snapshotter.setObserver({
   *   onDidFinishLoadingStyle: () => {
   *     snapshotter.start({ onSnapshotReady: (snapshot) => { ... } });
   *   },
   *   onStyleImageMissing: (imageName) => {
   *     console.log('Missing image:', imageName);
   *   }
   * });
   * ```
   */
  public addImage(
    name: string,
    imageData: ArrayBuffer | Uint8Array | Icon | Image,
    widthOrSdf?: number | boolean,
    height?: number,
    pixelRatioOrSdf?: number | boolean,
    sdf?: boolean
  ): void {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', 'Native snapshotter not initialized');
      return;
    }

    try {
      this.nativeSnapshotter.addImage(name, imageData, widthOrSdf, height, pixelRatioOrSdf, sdf);
      hilog.info(DOMAIN, 'MapSnapshotter', `Image added: ${name}`);
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `Failed to add image: ${error}`);
      throw new Error(`Failed to add image: ${error}`);
    }
  }

  /**
   * Create a PixelMap from the native result.
   *
   * @param result Native result object.
   * @returns Promise resolving to a PixelMap.
   */
  private async createPixelMapFromNativeResult(result: SnapshotResultNAPI): Promise<image.PixelMap> {
    return new Promise((resolve, reject) => {
      try {
        const imageInfo: image.ImageInfo = {
          size: { height: result.height, width: result.width },
          pixelFormat: image.PixelMapFormat.RGBA_8888,
          alphaType: image.AlphaType.PREMUL,
          density: 160,
          stride: result.width * 4,
          mimeType: 'image/png',
          isHdr: false
        };

        // Create PixelMap from the ArrayBuffer.
        image.createPixelMap(result.data, imageInfo, (err, pixelMap) => {
          if (err) {
            reject(err);
          } else {
            resolve(pixelMap);
          }
        });
      } catch (error) {
        reject(error);
      }
    });
  }
}

