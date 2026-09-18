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
 * Flatten a CameraPosition into the plain object expected by the NAPI layer.
 * Module-level helper: the same conversion previously existed verbatim in the
 * MapSnapshotter constructor and setCameraPosition().
 *
 * @param position Camera position to flatten.
 * @returns NAPI CameraPositionLike plain object.
 */
function cameraPositionToNative(position: CameraPosition): CameraPositionLike {
  const cameraData: CameraPositionLike = {
    target: {
      latitude: position.target.latitude,
      longitude: position.target.longitude
    },
    zoom: position.zoom,
    bearing: position.bearing,
    tilt: position.tilt
  };
  return cameraData;
}

/**
 * Flatten a LatLngBounds into the plain object expected by the NAPI layer.
 * Module-level helper: the same conversion previously existed verbatim in the
 * MapSnapshotter constructor and setRegion().
 *
 * @param bounds Bounds to flatten.
 * @returns NAPI LatLngBoundsLike plain object.
 */
function latLngBoundsToNative(bounds: LatLngBounds): LatLngBoundsLike {
  const regionData: LatLngBoundsLike = {
    north: bounds.north,
    south: bounds.south,
    east: bounds.east,
    west: bounds.west
  };
  return regionData;
}

/**
 * Create a PixelMap from raw snapshot pixel data.
 *
 * Shared by MapSnapshotter (offline snapshotter results) and MapLibreMap
 * (MapViewSnapshotPayload snapshots); previously duplicated in both files.
 *
 * @param data Raw RGBA (premultiplied) pixel buffer.
 * @param width Image width in pixels.
 * @param height Image height in pixels.
 * @returns Promise resolving to the created PixelMap.
 */
export function pixelMapFromSnapshotData(data: ArrayBuffer, width: number, height: number): Promise<image.PixelMap> {
  return new Promise((resolve, reject) => {
    try {
      const imageInfo: image.ImageInfo = {
        size: { width: width, height: height },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        alphaType: image.AlphaType.PREMUL,
        density: 160,
        stride: width * 4,
        mimeType: 'image/png',
        isHdr: false
      };

      image.createPixelMap(data, imageInfo, (err, pixelMap) => {
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
 *     hilog.error(DOMAIN, 'MapSnapshotter', '%{public}s', `Snapshot failed: ${error}`);
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
   * Guarded native snapshotter call helper.
   *
   * Collapses the recurring
   * `if (!this.nativeSnapshotter) { warn; return }`
   * `try { this.nativeSnapshotter.X() } catch { error; return|throw }`
   * boilerplate.
   *
   * @param label Call-site identifier used for logging.
   * @param fallback Value returned when the snapshotter is missing or the
   *                 operation throws without `errorPrefix`.
   * @param op Operation to run against the native snapshotter.
   * @param errorPrefix When provided, a caught error is rethrown as
   *                    `new Error(\`${errorPrefix}: ${error}\`)` (mirrors the
   *                    previous throwing setters); when omitted the fallback
   *                    is returned instead.
   * @returns Operation result, or `fallback`.
   */
  private withSnapshotter<T>(label: string, fallback: T, op: (snapshotter: MapSnapshotterNAPI) => T, errorPrefix?: string): T {
    if (!this.nativeSnapshotter) {
      hilog.warn(DOMAIN, 'MapSnapshotter', `${label}: Native snapshotter not initialized`);
      return fallback;
    }
    try {
      return op(this.nativeSnapshotter);
    } catch (error) {
      hilog.error(DOMAIN, 'MapSnapshotter', `${label} failed: ${error}`);
      if (errorPrefix !== undefined) {
        throw new Error(`${errorPrefix}: ${error}`);
      }
      return fallback;
    }
  }

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
        napiOptions.camera = cameraPositionToNative(options.cameraPosition);
      }

      // If a region is provided, convert it to a plain object
      if (options.region) {
        napiOptions.region = latLngBoundsToNative(options.region);
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
    this.withSnapshotter<void>('cancel', undefined, (snapshotter) => {
      this.cancelled = true;
      snapshotter.cancel();
    });
  }

  /**
   * Set the style URL.
   */
  public setStyleUrl(styleUrl: string): void {
    this.withSnapshotter<void>('setStyleUrl', undefined, (snapshotter) => {
      snapshotter.setStyleUrl(styleUrl);
      this.options.styleUrl = styleUrl;
      hilog.info(DOMAIN, 'MapSnapshotter', `Style URL set: ${styleUrl}`);
    }, 'Failed to set style URL');
  }

  /**
   * Set the style JSON.
   */
  public setStyleJson(styleJson: string): void {
    this.withSnapshotter<void>('setStyleJson', undefined, (snapshotter) => {
      snapshotter.setStyleJson(styleJson);
      this.options.styleJson = styleJson;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Style JSON set');
    }, 'Failed to set style JSON');
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
    this.withSnapshotter<void>('setCameraPosition', undefined, (snapshotter) => {
      // Convert CameraPosition to a plain object before passing to native code.
      snapshotter.setCameraPosition(cameraPositionToNative(cameraPosition));
      this.options.cameraPosition = cameraPosition;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Camera position set');
    }, 'Failed to set camera position');
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
    this.withSnapshotter<void>('setRegion', undefined, (snapshotter) => {
      // Convert LatLngBounds to a plain object.
      snapshotter.setRegion(latLngBoundsToNative(region));
      this.options.region = region;
      hilog.info(DOMAIN, 'MapSnapshotter', 'Region set');
    }, 'Failed to set region');
  }

  /**
   * Set the snapshot dimensions.
   */
  public setSize(width: number, height: number): void {
    this.withSnapshotter<void>('setSize', undefined, (snapshotter) => {
      snapshotter.setSize(width, height);
      this.options.size = { width, height };
      hilog.info(DOMAIN, 'MapSnapshotter', `Size set: ${width}x${height}`);
    }, 'Failed to set size');
  }

  /**
   * Configure the observer.
   * @param observer Observer instance; pass null to clear it.
   */
  public setObserver(observer: NativeMapSnapshotterObserver | null): void {
    this.withSnapshotter<void>('setObserver', undefined, (snapshotter) => {
      // Assigned before the native call: on failure the field stays set,
      // mirroring the previous implementation.
      this.observer = observer;
      snapshotter.setObserver(observer);
      hilog.info(DOMAIN, 'MapSnapshotter', observer ? 'Observer set' : 'Observer cleared');
    }, 'Failed to set observer');
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
    return this.withSnapshotter<Layer | null>('getLayer', null, (snapshotter) => {
      return snapshotter.getLayer(layerId) || null;
    });
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
    return this.withSnapshotter<Source | null>('getSource', null, (snapshotter) => {
      return snapshotter.getSource(sourceId) || null;
    });
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
   *     hilog.info(DOMAIN, 'Missing image:', '%{public}s', imageName);
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
    this.withSnapshotter<void>('addImage', undefined, (snapshotter) => {
      snapshotter.addImage(name, imageData, widthOrSdf, height, pixelRatioOrSdf, sdf);
      hilog.info(DOMAIN, 'MapSnapshotter', `Image added: ${name}`);
    }, 'Failed to add image');
  }

  /**
   * Create a PixelMap from the native result.
   *
   * Delegates to the shared pixelMapFromSnapshotData() helper (also used by
   * MapLibreMap.snapshot()).
   *
   * @param result Native result object.
   * @returns Promise resolving to a PixelMap.
   */
  private createPixelMapFromNativeResult(result: SnapshotResultNAPI): Promise<image.PixelMap> {
    return pixelMapFromSnapshotData(result.data, result.width, result.height);
  }
}

