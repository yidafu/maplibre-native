/**
 * BackgroundLayer - 封装类
 */
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class BackgroundLayer {
  private nativeInstance: maplibre.BackgroundLayer;

  constructor(idOrMarker: string | InternalMarker, nativeOrNothing?: maplibre.BackgroundLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.BackgroundLayer(idOrMarker);
    } else {
      throw new Error('Invalid BackgroundLayer constructor arguments');
    }
  }

  static create(id: string): BackgroundLayer {
    return new BackgroundLayer(id);
  }

  static fromNative(nativeInstance: maplibre.BackgroundLayer): BackgroundLayer {
    return new BackgroundLayer(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.BackgroundLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setVisibility(visibility: 'visible' | 'none'): BackgroundLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): BackgroundLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): BackgroundLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setBackgroundColor(color: string | Object): BackgroundLayer {
    this.nativeInstance.setBackgroundColor(color);
    return this;
  }

  setBackgroundOpacity(opacity: number | Object): BackgroundLayer {
    this.nativeInstance.setBackgroundOpacity(opacity);
    return this;
  }

  setBackgroundPattern(pattern: string | Object): BackgroundLayer {
    this.nativeInstance.setBackgroundPattern(pattern);
    return this;
  }
}
