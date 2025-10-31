/**
 * LineLayer - 封装类
 */
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class LineLayer {
  private nativeInstance: maplibre.LineLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.LineLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.LineLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid LineLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): LineLayer {
    return new LineLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.LineLayer): LineLayer {
    return new LineLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.LineLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): LineLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): LineLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): LineLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setFilter(filter: Object[]): LineLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }
}
