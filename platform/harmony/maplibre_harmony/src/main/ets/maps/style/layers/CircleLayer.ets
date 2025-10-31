/**
 * CircleLayer - 封装类
 */
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class CircleLayer {
  private nativeInstance: maplibre.CircleLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.CircleLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.CircleLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid CircleLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): CircleLayer {
    return new CircleLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.CircleLayer): CircleLayer {
    return new CircleLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.CircleLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): CircleLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): CircleLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): CircleLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setFilter(filter: Object[]): CircleLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }
}
