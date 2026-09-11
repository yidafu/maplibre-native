/**
 * VideoSource - video-backed content source
 *
 * Mirrors the historic iOS MGLVideoSource: a video source is an image source
 * whose content is continuously refreshed from a video player. There is no
 * video source in the native core, so this class composes:
 *
 *   AVPlayer → ImageReceiver (surface) → JPEG frames → PixelMap (RGBA)
 *     → native Image → VideoSource.updateImage()
 *
 * The player and frame sampling run on the ArkTS side; the native layer only
 * receives fully decoded frames. Frame updates are throttled with
 * `frameIntervalMs` because decoding every delivered frame on the JS thread
 * is wasteful for map display purposes.
 *
 * Requires device verification (video decoding depends on the media stack).
 */

import media from '@ohos.multimedia.media';
import image from '@ohos.multimedia.image';
import { BusinessError } from '@ohos.base';
import maplibre from 'libmaplibre.so';
import { Image } from '../images/Image';

/**
 * Internal marker used to identify the fromNative factory
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * VideoSource options
 */
export interface VideoSourceOptions {
  /** Four corner coordinates [[lng, lat] x 4], clockwise from top-left */
  coordinates?: number[][];
  /** Video URL (file://, http(s)://, or fd://) passed to the AVPlayer */
  url?: string;
  /** Video frame width used for the frame receiver (must match the stream) */
  width?: number;
  /** Video frame height used for the frame receiver (must match the stream) */
  height?: number;
  /** Minimum delay between pushed frames in ms (default 100 ≈ 10 fps) */
  frameIntervalMs?: number;
  /** Whether playback loops (default false) */
  loop?: boolean;
}

/**
 * VideoSource implementation
 */
export class VideoSource {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'VideoSource';
  private nativeInstance: maplibre.VideoSource;

  private avPlayer: media.AVPlayer | null = null;
  private imageReceiver: image.ImageReceiver | null = null;
  private frameName: string = '';
  private frameIntervalMs: number = 100;
  private lastFrameTime: number = 0;
  private receivingFrames: boolean = false;
  private loop: boolean = false;

  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: VideoSourceOptions |
    maplibre.VideoSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      this.nativeInstance = optionsOrNative as maplibre.VideoSource;
    } else if (typeof idOrMarker === 'string') {
      const options = (optionsOrNative ?? {}) as VideoSourceOptions;
      this.frameName = `video-frame-${idOrMarker}`;
      this.frameIntervalMs = options.frameIntervalMs ?? 100;
      this.loop = options.loop ?? false;

      if (options.coordinates) {
        this.nativeInstance = new maplibre.VideoSource(idOrMarker, options.coordinates);
      } else {
        this.nativeInstance = new maplibre.VideoSource(idOrMarker);
      }
    } else {
      throw new Error('Invalid VideoSource constructor arguments');
    }
  }

  /**
   * Create a VideoSource
   * @param id Source identifier
   * @param options Optional configuration
   */
  static create(id: string, options?: VideoSourceOptions): VideoSource {
    return new VideoSource(id, options);
  }

  /**
   * Create from a native instance (internal use)
   * @param nativeInstance Native VideoSource instance
   */
  static fromNative(nativeInstance: maplibre.VideoSource): VideoSource {
    return new VideoSource(InternalMarker.INSTANCE, nativeInstance);
  }

  /**
   * Get the underlying native instance
   */
  getNative(): maplibre.VideoSource {
    return this.nativeInstance;
  }

  /**
   * Get the source identifier
   */
  getId(): string {
    return this.nativeInstance.getId();
  }

  /**
   * Set the four corner coordinates [[lng, lat] x 4]
   */
  setCoordinates(coordinates: number[][]): VideoSource {
    this.nativeInstance.setCoordinates(coordinates);
    return this;
  }

  /**
   * Get the four corner coordinates
   */
  getCoordinates(): number[][] {
    return this.nativeInstance.getCoordinates() as number[][];
  }

  /**
   * Push a static image into the source (e.g. a poster frame)
   */
  setImage(image: Image): VideoSource {
    this.nativeInstance.updateImage(image.getNative());
    return this;
  }

  // ==================== Video playback ====================

  /**
   * Attach and start a video player for the given URL.
   *
   * Sets up an AVPlayer rendering into an offscreen ImageReceiver and begins
   * pushing decoded frames into the map source.
   *
   * @param url Video URL (file://, http(s)://, or fd://)
   * @param width Video frame width (must match the stream)
   * @param height Video frame height (must match the stream)
   */
  async attachVideo(url: string, width: number, height: number): Promise<void> {
    await this.releaseVideo();

    // Offscreen receiver the AVPlayer renders into
    const receiver = image.createImageReceiver(width, height, image.ImageFormat.JPEG, 8);
    const surfaceId = await receiver.getReceivingSurfaceId();

    const player = await media.createAVPlayer();
    player.url = url;
    player.loop = this.loop;

    player.on('stateChange', (state: string) => {
      // surfaceId must be assigned in the initialized state
      if (state === 'initialized') {
        player.surfaceId = surfaceId;
        player.prepare().then(() => {
          return player.play();
        }).catch((err: BusinessError) => {
          console.error(`[VideoSource] prepare/play failed: ${JSON.stringify(err)}`);
        });
      }
    });

    player.on('error', (err: BusinessError) => {
      console.error(`[VideoSource] player error: ${JSON.stringify(err)}`);
    });

    receiver.on('imageArrival', () => {
      this.onImageArrival(receiver);
    });

    this.avPlayer = player;
    this.imageReceiver = receiver;
    this.receivingFrames = true;
  }

  /**
   * Start playback
   */
  async play(): Promise<void> {
    if (this.avPlayer) {
      await this.avPlayer.play();
    }
  }

  /**
   * Pause playback (no new frames arrive while paused)
   */
  async pause(): Promise<void> {
    if (this.avPlayer) {
      await this.avPlayer.pause();
    }
  }

  /**
   * Seek to a position
   * @param seconds Position in seconds
   */
  async seekTo(seconds: number): Promise<void> {
    if (this.avPlayer) {
      await this.avPlayer.seek(Math.round(seconds * 1000), media.SeekMode.SEEK_PREV_SYNC);
    }
  }

  /**
   * Release the player and stop frame sampling
   */
  async releaseVideo(): Promise<void> {
    this.receivingFrames = false;
    if (this.imageReceiver) {
      this.imageReceiver.release().catch((err: BusinessError) => {
        console.error(`[VideoSource] receiver release failed: ${JSON.stringify(err)}`);
      });
      this.imageReceiver = null;
    }
    if (this.avPlayer) {
      const player = this.avPlayer;
      this.avPlayer = null;
      try {
        await player.release();
      } catch (err) {
        // Player may already be released
      }
    }
  }

  /**
   * Throttled frame arrival handler: latest JPEG frame → RGBA → native update
   */
  private onImageArrival(receiver: image.ImageReceiver): void {
    if (!this.receivingFrames) {
      return;
    }

    const now = Date.now();
    if (now - this.lastFrameTime < this.frameIntervalMs) {
      // Throttle: skip this frame
      return;
    }
    this.lastFrameTime = now;

    receiver.readLatestImage((err: BusinessError, img: image.Image) => {
      if (err || !img || !this.receivingFrames) {
        return;
      }
      img.getComponent(image.ComponentType.JPEG).then((component: image.Component) => {
        if (!component || !component.byteBuffer || !this.receivingFrames) {
          this.releaseImage(img);
          return;
        }
        const jpegBytes = new Uint8Array(component.byteBuffer);
        return this.decodeAndPush(jpegBytes).then(() => {
          this.releaseImage(img);
        });
      }).catch((componentErr: BusinessError) => {
        console.error(`[VideoSource] frame read failed: ${JSON.stringify(componentErr)}`);
        this.releaseImage(img);
      });
    });
  }

  private releaseImage(img: image.Image): void {
    img.release().catch(() => {});
  }

  /**
   * Decode JPEG bytes into an RGBA buffer and push them to the native source
   */
  private async decodeAndPush(jpegBytes: Uint8Array): Promise<void> {
    const imageSource = image.createImageSource(jpegBytes);
    try {
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      try {
        const info = await pixelMap.getImageInfo();
        const bufferSize = info.size.width * info.size.height * 4;
        const buffer = new ArrayBuffer(bufferSize);
        await pixelMap.readPixelsToBuffer(buffer);

        const frame = new Image({
          name: this.frameName,
          width: info.size.width,
          height: info.size.height,
          data: new Uint8Array(buffer)
        });
        this.nativeInstance.updateImage(frame.getNative());
      } finally {
        pixelMap.release().catch(() => {});
      }
    } catch (err) {
      console.error(`[VideoSource] frame decode failed: ${JSON.stringify(err)}`);
    } finally {
      imageSource.release().catch(() => {});
    }
  }
}
